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

-- opts: seed, tuning = {hp, atk}, onEvent(함수)
function Session.new(state, opts)
    opts = opts or {}
    local s = setmetatable({
        state = state, seed = opts.seed or 1, tuning = opts.tuning, listeners = {},
        acc = 0, wait = 0, runs = 0, runner = nil,
    }, S)
    if opts.onEvent then s.listeners[1] = opts.onEvent end
    return s
end

function S:emit(ev, a, b, c, d)
    for i = 1, #self.listeners do self.listeners[i](ev, a, b, c, d) end
end

-- 현재 선택된 스테이지를 새로 시작한다. 편성이나 스킬을 바꾼 뒤에도 이것을 부른다.
function S:startStage()
    local state = self.state
    local key = Game.currentStageKey(state)
    self.runs = self.runs + 1
    self.runner = Runner.new({
        difficulty = state.stage.difficulty, section = state.stage.section,
        seed = self.seed + self.runs * 7919, party = Game.buildParty(state), account = self.account,
        bossIndex = state.stage.bossIndex[key] or 1, tuning = self.tuning,
        onEvent = function(ev, a, b, c) self:onRunnerEvent(ev, a, b, c) end,
    })
    self.stageKey = key
    self.wait = 0
    self:emit("stageStart", key, self.runner)
    return self.runner
end

function S:onRunnerEvent(ev, a, b, c)
    local state = self.state
    if ev == "kill" then
        local reward = b
        state.stats.kills = state.stats.kills + 1
        if a.isBoss then state.stats.bossKills = state.stats.bossKills + 1 end
        Game.addGold(state, reward.gold)
        local runner = self.runner
        local stageLevel = runner.stage.level
        for rank, u in ipairs(runner.heroes) do
            if u.alive then
                local heroId = state.party[rank]
                local h = state.heroes[heroId]
                if h then
                    local gain = reward.exp * Level.expPenalty(h.level, stageLevel) * u:get("IncreaseExpAmount")
                        + u:get("AdditionalExp")
                    local ups = Game.addExp(state, heroId, gain)
                    if ups > 0 then self:emit("levelUp", heroId, h.level) end
                end
            end
        end
        self:emit("kill", a, reward)
    elseif ev == "clear" then
        Game.markCleared(state, self.stageKey)
        self:emit("clear", self.stageKey, self.runner and self.runner.totals)
        self:chooseAfterClear()
    elseif ev == "fail" then
        state.stats.fails = state.stats.fails + 1
        self:emit("fail", self.stageKey)
        self:chooseAfterFail()
    else
        self:emit(ev, a, b, c)
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
