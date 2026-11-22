-- 연속 진행: 현재 스테이지를 돌리고, 처치 보상을 바로 적용하고, 클리어·실패 뒤 다음에 할 스테이지를 정한다.
-- 화면이 없어도 동작한다. 화면은 onEvent로 전달되는 이벤트만 본다.

local _, WIH = ...
local Tables = WIH.module("Tables")
local Level = WIH.module("Level")
local Game = WIH.module("Game")
local Dungeons = WIH.module("Dungeons")
local Runner = WIH.module("Runner")
local Session = WIH.module("Session")

local S = {}
S.__index = S

local TICK = WIH.TICK
local BETWEEN_STAGES = 1.0      -- [독자] 스테이지 사이의 준비 시간(초)
local MAX_BACKLOG = 30          -- 한 번에 따라잡는 시간의 상한(초). 넘는 분량은 버린다

-- 자동으로 열린 상자의 결과를 알린다.
local function makeLootHandler(self)
    return function(kind, result) self:emit("loot", kind, result) end
end

-- opts: seed, tuning = {hp, atk}, onEvent(함수)
function Session.new(state, opts)
    opts = opts or {}
    local s = setmetatable({
        state = state, seed = opts.seed or 1, tuning = opts.tuning, listeners = {},
        acc = 0, wait = 0, runs = 0, runner = nil,
    }, S)
    if opts.onEvent then s.listeners[1] = opts.onEvent end
    s.lootRng = WIH.Rng.new((opts.seed or 1) + 4242)       -- 상자 드롭과 개봉용. 전투의 난수와 섞이지 않게 따로 둔다
    s.onLoot = makeLootHandler(s)
    WIH.Inventory.ensure(state)
    WIH.Chests.ensure(state)
    WIH.Pets.ensure(state)
    return s
end

function S:emit(ev, a, b, c, d, e, f, g)
    for i = 1, #self.listeners do self.listeners[i](ev, a, b, c, d, e, f, g) end
end

function S:addListener(fn)
    self.listeners[#self.listeners + 1] = fn
    return fn
end

function S:removeListener(fn)
    for i = #self.listeners, 1, -1 do
        if self.listeners[i] == fn then table.remove(self.listeners, i) end
    end
end

-- 화면이 전투 장면을 보고 있는 동안만 켠다.
function S:watchBattle(on)
    self.relayBattle = on and true or false
    if self.runner then self.runner.relayBattle = self.relayBattle end
end

-- 현재 선택된 스테이지를 새로 시작한다. 편성이나 스킬을 바꾼 뒤에도 이것을 부른다.
function S:startStage()
    local state = self.state
    local key = Game.currentStageKey(state)
    local raidKey = state.stage.raidKey
    if raidKey and not (Tables.STAGES[raidKey] and Tables.STAGES[raidKey].actBoss) then
        raidKey, state.stage.raidKey = nil, nil
    end
    self.inRaid = raidKey ~= nil
    if raidKey then key = raidKey end
    self.runs = self.runs + 1
    -- 계정 공통 수정치: 룬(+ 시험용으로 밖에서 넣은 시트)
    local account, totals = WIH.Runes.sheet(state)
    if self.account then WIH.Sheet.merge(account, self.account) end
    self.runeTotals = totals
    self.runner = Runner.new({
        difficulty = state.stage.difficulty, section = state.stage.section, raidKey = raidKey,
        waveReduction = totals.WaveCountReduction or 0,
        seed = self.seed + self.runs * 7919, party = Game.buildParty(state), account = account,
        bossIndex = state.stage.bossIndex[key] or 1, tuning = self.tuning,
        onEvent = function(ev, a, b, c, d, e, f, g) self:onRunnerEvent(ev, a, b, c, d, e, f, g) end,
    })
    self.runner.relayBattle = self.relayBattle
    self.stageKey = key
    self.wait = 0
    self:emit("stageStart", key, self.runner)
    return self.runner
end

function S:onRunnerEvent(ev, a, b, c, d, e, f, g)
    local state = self.state
    if ev == "kill" then
        local reward = b
        state.stats.kills = state.stats.kills + 1
        if a.isBoss then state.stats.bossKills = state.stats.bossKills + 1 end
        local kind = self.inRaid and (a.isBoss and "raid" or "normal") or (a.isBoss and "boss" or "normal")
        local totals = self.runeTotals or {}
        Game.addGold(state, WIH.Runes.goldFor(totals, reward.gold, kind))
        local extraExp = WIH.Runes.extraExpFor(totals, kind)
        local runner = self.runner
        local stageLevel = runner.stage.level
        for rank, u in ipairs(runner.heroes) do
            if u.alive then
                local heroId = u.heroId      -- 스테이지 도중에 편성을 바꿔도 싸우고 있는 영웅이 받는다
                local h = state.heroes[heroId]
                if h then
                    -- (기본 + 고정 추가) × 경험치 획득 % × 레벨 차 페널티 [독자: 적용 순서는 원작에서 확인되지 않음]
                    local gain = (reward.exp + extraExp + u:get("AdditionalExp")) * u:get("IncreaseExpAmount")
                        * Level.expPenalty(h.level, stageLevel)
                    local ups = Game.addExp(state, heroId, gain)
                    if ups > 0 then self:emit("levelUp", heroId, h.level) end
                end
            end
        end
        self:emit("kill", a, reward)
        if a.def and a.def.id then WIH.Pets.onKill(state, a.def.id) end
        -- 상자: 확률, 획득 허용량, 보관 한도를 통과하면 하나를 받는다.
        if not self.inRaid then
            local chestKind = a.isBoss and "stage" or "normal"
            if WIH.Chests.tryDrop(state, chestKind, self.stageKey, self.lootRng) then
                self:emit("chest", chestKind)
            end
        end
    elseif ev == "clear" then
        Game.markCleared(state, self.stageKey)
        self:emit("clear", self.stageKey, self.runner and self.runner.totals)
        self:checkPets()
        if self.inRaid then
            self:afterRaidClear()
            return
        end
        if state.stage.cleared[self.stageKey] == 1 then
            local given = WIH.Chests.firstClearReward(state, self.stageKey)
            if given and #given > 0 then self:emit("firstClear", given) end
            -- 각 액트의 9번 스테이지를 처음 클리어하면 그 난이도의 레이드 입장 재료 1개 [원작]
            if self.stageKey % 100 == WIH.Raids.TOKEN_STAGE then
                local token = WIH.Raids.TOKEN[math.floor(self.stageKey / 1000)]
                state.materials[token] = (state.materials[token] or 0) + 1
                self:emit("token", token)
            end
        end
        self:chooseAfterClear()
    elseif ev == "fail" then
        state.stats.fails = state.stats.fails + 1
        self:emit("fail", self.stageKey)
        self:checkPets()
        if self.inRaid then
            -- 레이드 실패: 입장 재료는 쓰이지 않는다. 하던 던전으로 돌아간다. [추정: 원작은 클리어했을 때만 소모]
            state.stage.raidKey = nil
            self.wait = BETWEEN_STAGES
            return
        end
        self:chooseAfterFail()
    else
        self:emit(ev, a, b, c, d, e, f, g)
    end
end

-- 펫의 조건을 확인한다(스테이지가 끝날 때마다).
function S:checkPets()
    local got = WIH.Pets.check(self.state)
    if got then
        for _, pet in ipairs(got) do self:emit("pet", pet) end
    end
end

-- 레이드 클리어: 입장 재료 1개를 쓰고 레이드 상자를 받는다. 처음 클리어했으면 반복 설정과 상관없이 다음 스테이지로 넘어간다. [원작 1.3.0]
function S:afterRaidClear()
    local state = self.state
    local key = self.stageKey
    local difficulty = math.floor(key / 1000)
    local token = WIH.Raids.TOKEN[difficulty]
    state.materials[token] = math.max(0, (state.materials[token] or 0) - 1)
    local how, result = WIH.Chests.giveRaid(state, key, self.lootRng)
    self:emit("raidClear", key, how, result)
    state.stage.raidKey = nil
    self.wait = BETWEEN_STAGES
    if state.stage.cleared[key] == 1 then
        local nextKey = Tables.STAGES[key].next
        if nextKey and Dungeons.sections[nextKey % 1000] then
            Game.selectStage(state, math.floor(nextKey / 1000), nextKey % 1000)
        end
    end
end

-- 클리어 뒤: 반복 모드면 같은 스테이지, 아니면 다음 던전 스테이지로. 다음이 레이드면 같은 스테이지에 머문다.
function S:chooseAfterClear()
    local state = self.state
    self.wait = BETWEEN_STAGES
    if state.settings.repeatMode or not state.settings.autoAdvance then return end
    local nextKey = Tables.STAGES[self.stageKey].next
    if not nextKey then return end
    local nextStage = Tables.STAGES[nextKey]
    if nextStage.actBoss then
        self:emit("raidUnlocked", nextKey)
        return
    end
    local difficulty = math.floor(nextKey / 1000)
    local section = nextKey % 1000
    if Dungeons.sections[section] then
        Game.selectStage(state, difficulty, section)
    end
end

-- 실패 뒤: 자동 재시도가 켜져 있으면 같은 스테이지, 꺼져 있으면 이전 던전 스테이지로 내려간다. [추정: 원작 가이드]
function S:chooseAfterFail()
    local state = self.state
    self.wait = BETWEEN_STAGES
    if state.settings.autoRetry then return end
    local key = Game.previousStage(self.stageKey)
    while key and Tables.STAGES[key].actBoss do key = Game.previousStage(key) end
    if key then
        state.stage.difficulty, state.stage.section = math.floor(key / 1000), key % 1000
    end
end

-- 실제 시간 dt초만큼 진행한다. maxTicks는 한 번의 호출에서 돌릴 틱 수의 상한(프레임 예산).
-- 돌린 틱 수를 돌려준다.
function S:advance(dt, maxTicks)
    self.acc = self.acc + dt
    if self.acc > MAX_BACKLOG then self.acc = MAX_BACKLOG end
    local done = 0
    maxTicks = maxTicks or 40
    while self.acc >= TICK - 1e-9 and done < maxTicks do     -- 부동소수점 누적 오차 허용
        self.acc = self.acc - TICK
        if self.acc < 0 then self.acc = 0 end
        done = done + 1
        self.state.stats.playSeconds = self.state.stats.playSeconds + TICK
        self.chestAcc = (self.chestAcc or 0) + TICK
        if self.chestAcc >= 1 then       -- 상자의 허용량 충전과 자동 개봉은 1초 단위로 본다
            WIH.Chests.tick(self.state, self.chestAcc, Game.currentStageKey(self.state), self.lootRng, self.onLoot)
            self.chestAcc = 0
        end
        if self.wait > 0 then
            self.wait = self.wait - TICK
            if self.wait <= 0 then self.runner = nil end
        else
            if not self.runner or self.runner.result then self:startStage() end
            self.runner:step()
        end
    end
    return done
end

return Session
