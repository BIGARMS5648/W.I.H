-- 스테이지 진행기: 웨이브 → … → 보스 → 클리어 또는 실패. 처치 보상을 계산해 이벤트로 알린다.
-- 구조와 수치(웨이브 수, 웨이브당 몬스터 수, 보스 배율, 스테이지 레벨 배율)는 원작 표를 쓴다.

local _, WIH = ...
local Tables = WIH.module("Tables")
local Unit = WIH.module("Unit")
local Battle = WIH.module("Battle")
local Skills = WIH.module("Skills")
local Level = WIH.module("Level")
local Monsters = WIH.module("Monsters")
local Dungeons = WIH.module("Dungeons")
local HeroBuild = WIH.module("HeroBuild")
local Runner = WIH.module("Runner")

local R = {}
R.__index = R

local WAVE_GAP = 700        -- [독자] 새 웨이브가 선두 영웅 앞쪽에 나타나는 거리
local MOB_SPACING = 45      -- [독자] 웨이브 안 몬스터 사이 간격
local BOSS_GAP = 800
local TRAVEL_PAUSE = 0.6    -- [독자] 웨이브를 정리한 뒤 다음 웨이브가 나타나기까지의 시간

-- opts:
--   difficulty(1~4), section(구간 키), seed
--   party = { {heroId, form, passivePoints, skills = {{id, level}, ...}, gear, level, exp}, ... } (편성 순서)
--   account(계정 공통 시트), bossIndex(이번에 나올 보스의 순번), tuning = {hp, atk}(5인 보정 계수), onEvent
function Runner.new(opts)
    local key = Dungeons.stageKey(opts.difficulty or 1, opts.section)
    local stage = Tables.STAGES[key]
    local section = Dungeons.sections[opts.section]
    if not stage or not section then error("알 수 없는 스테이지: " .. tostring(key)) end
    if stage.actBoss then error("레이드 스테이지는 이 진행기가 다루지 않는다: " .. tostring(key)) end
    local r = setmetatable({
        key = key, stage = stage, section = section, difficulty = opts.difficulty or 1,
        party = opts.party, account = opts.account, tuning = opts.tuning or { hp = 1, atk = 1 },
        bossIndex = opts.bossIndex or 1,
        wave = 0, waves = stage.waves - (opts.waveReduction or 0), phase = "start", timer = 0,
        result = nil, listeners = {},
        totals = { gold = 0, exp = {}, kills = 0, bossKills = 0, chestRolls = 0, bossChestRolls = 0 },
    }, R)
    if r.waves < 1 then r.waves = 1 end
    if opts.onEvent then r.listeners[1] = opts.onEvent end
    r.battle = Battle.new({ seed = opts.seed or 1, stageLevel = stage.level,
        resistPenalty = Tables.RESIST_PENALTY[r.difficulty] })
    r.battle.listeners[1] = function(ev, a, b2, c, d, e, f) r:onBattleEvent(ev, a, b2, c, d, e, f) end
    r.heroes = {}
    for rank, p in ipairs(opts.party) do
        local u = HeroBuild.spawn(r.battle, p.heroId, { form = p.form, passivePoints = p.passivePoints, skills = p.skills,
            gear = p.gear, account = opts.account, rank = rank, x = -(rank - 1) * 20 })
        u.state = p
        r.heroes[rank] = u
        r.totals.exp[rank] = 0
    end
    return r
end

function R:emit(ev, a, b, c, d)
    for i = 1, #self.listeners do self.listeners[i](ev, a, b, c, d) end
end

-- 몬스터 정의와 스테이지 레벨로 전투 유닛을 만든다. bossMult = 스테이지 보스 배율(퍼밀 4개) 또는 nil
function Runner.spawnMonster(battle, def, stageLevel, x, bossMult, tuning)
    local hp, atk, gold, exp = Level.monsterValues(def, stageLevel)
    if bossMult then
        hp = hp * bossMult[2] / 1000
        atk = atk * bossMult[1] / 1000
        gold = gold * bossMult[3] / 1000
        exp = exp * bossMult[4] / 1000
    end
    tuning = tuning or { hp = 1, atk = 1 }
    hp, atk = hp * tuning.hp, atk * tuning.atk
    if hp < 1 then hp = 1 end
    local u = Unit.new({
        name = def.name, team = 2, kind = "monster", isBoss = def.isBoss, def = def,
        base = { MaxHp = hp, AttackDamage = atk, AttackSpeed = def.as, MovementSpeed = def.ms, CriticalDamage = 1000,
            CastSpeed = 100 },
        melee = def.melee, range = def.range, x = x, rank = 50,
        basicElem = def.elem, basicDelivery = def.melee and "melee" or "proj", basicArea = def.area,
    })
    u.reward = { gold = gold, exp = exp }
    battle:addUnit(u)
    if def.skills then
        for i = 1, #def.skills do
            local slot = Skills.equip(battle, u, def.skills[i], 1)
            -- 보스의 재사용 스킬은 등장 직후 한꺼번에 쏟아지지 않도록 절반만 충전된 채 시작한다. [독자]
            if slot.cd then slot.charge = slot.cd * 0.5 end
        end
    end
    return u
end

function R:frontX()
    local x
    for i = 1, #self.heroes do
        local u = self.heroes[i]
        if u.alive and (not x or u.x > x) then x = u.x end
    end
    return x or 0
end

function R:spawnWave()
    self.wave = self.wave + 1
    local weights = {}
    for i, m in ipairs(self.section.mobs) do weights[i] = m.weight end
    local base = self:frontX() + WAVE_GAP
    for i = 1, self.stage.perWave do
        local pick = self.battle.rng:weighted(weights)
        local def = Monsters.defs[self.section.mobs[pick].id]
        Runner.spawnMonster(self.battle, def, self.stage.level, base + (i - 1) * MOB_SPACING, nil, self.tuning)
    end
    self.phase = "wave"
    self:emit("wave", self.wave, self.waves)
end

function R:spawnBoss()
    local ids = self.section.bosses
    local id = ids[(self.bossIndex - 1) % #ids + 1]
    local def = Monsters.defs[id]
    self.boss = Runner.spawnMonster(self.battle, def, self.stage.level, self:frontX() + BOSS_GAP, self.stage.boss, self.tuning)
    self.phase = "boss"
    self:emit("boss", self.boss)
end

-- 전투 이벤트: 몬스터가 죽으면 보상을 계산한다.
function R:onBattleEvent(ev, a, b)
    if ev == "death" and a.team == 2 and a.reward then
        local reward = a.reward
        local totals = self.totals
        totals.kills = totals.kills + 1
        totals.gold = totals.gold + reward.gold
        -- 경험치: 살아 있는 영웅 각자가 전액을 받고, 각자의 레벨 차 페널티를 적용한다. [추정]
        for rank, u in ipairs(self.heroes) do
            if u.alive then
                local level = (u.state and u.state.level) or 1
                local gain = reward.exp * Level.expPenalty(level, self.stage.level) * u:get("IncreaseExpAmount")
                    + u:get("AdditionalExp")
                totals.exp[rank] = totals.exp[rank] + gain
            end
        end
        if a.isBoss then
            totals.bossKills = totals.bossKills + 1
            if self.battle.rng:chance(self.stage.bossChest / 1000) then totals.bossChestRolls = totals.bossChestRolls + 1 end
        else
            if self.battle.rng:chance(self.stage.chest / 1000) then totals.chestRolls = totals.chestRolls + 1 end
        end
        self:emit("kill", a, reward)
    end
    -- 화면과 기록용으로 전투 이벤트를 그대로 전달한다.
    if #self.listeners > 0 then self:emit("battle", ev, a, b) end
end

-- 한 틱 진행. 끝났으면 "clear" 또는 "fail"을 돌려준다.
function R:step()
    if self.result then return self.result end
    local b = self.battle
    if self.phase == "start" then
        self:spawnWave()
    end
    b:step()

    -- 전멸 판정: 살아 있는 영웅이 없으면 실패. [원작: 전멸 = 스테이지 실패]
    local alive = 0
    for i = 1, #self.heroes do
        if self.heroes[i].alive then alive = alive + 1 end
    end
    if alive == 0 then
        self.result = "fail"
        self:emit("fail", self.wave)
        return self.result
    end

    if b:count(2) == 0 then
        if self.phase == "wave" then
            self.phase = "travel"
            self.timer = TRAVEL_PAUSE
        elseif self.phase == "travel" then
            self.timer = self.timer - WIH.TICK
            if self.timer <= 0 then
                if self.wave < self.waves then self:spawnWave() else self:spawnBoss() end
            end
        elseif self.phase == "boss" then
            self.result = "clear"
            self:emit("clear", self.totals)
        end
    end
    return self.result
end

-- 끝날 때까지(또는 제한 시간까지) 진행한다. 결과와 걸린 시간을 돌려준다.
function R:run(maxSeconds)
    local limit = math.floor((maxSeconds or 3600) / WIH.TICK)
    for _ = 1, limit do
        local res = self:step()
        if res then return res, self.battle.time end
    end
    return "timeout", self.battle.time
end

return Runner
