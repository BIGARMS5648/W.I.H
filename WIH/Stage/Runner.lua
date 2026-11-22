-- 스테이지 진행기: 웨이브 → … → 보스 → 클리어 또는 실패. 처치 보상을 계산해 이벤트로 알린다.
-- 구조(웨이브 수, 웨이브당 몬스터 수)는 원작 표 그대로다.
-- 몬스터의 세기와 보상은 원작의 그 스테이지 값에 맞춘다 [원작 수치 / 독자 배치]:
--   · 일반 몬스터: 이 던전의 몬스터 구성(가중치 포함)의 평균 체력·초당 피해·골드·경험치가
--     원작 그 스테이지의 평균(Tables.STAGES[키].mob)과 같아지도록 배율을 건다. 몬스터끼리의 상대적 차이는 유지된다.
--   · 보스: 이 던전의 보스들(클리어마다 차례로 등장)의 평균 체력·초당 피해가 원작 그 스테이지 보스의 최종값
--     (bossFinal)과 같아지도록 배율을 건다. 보상은 원작 값 그대로다. 보스 패턴의 피해는 그 위에 더해진다 [독자].

local _, WIH = ...
local Tables = WIH.module("Tables")
local Unit = WIH.module("Unit")
local Battle = WIH.module("Battle")
local Skills = WIH.module("Skills")
local Level = WIH.module("Level")
local Monsters = WIH.module("Monsters")
local Dungeons = WIH.module("Dungeons")
local Raids = WIH.module("Raids")
local HeroBuild = WIH.module("HeroBuild")
local Runner = WIH.module("Runner")

local R = {}
R.__index = R

local WAVE_GAP = 700        -- [독자] 새 웨이브가 선두 영웅 앞쪽에 나타나는 거리
local MOB_SPACING = 45      -- [독자] 웨이브 안 몬스터 사이 간격
local BOSS_GAP = 800
local TRAVEL_PAUSE = 0.6    -- [독자] 웨이브를 정리한 뒤 다음 웨이브가 나타나기까지의 시간
-- 시간 제한 [독자]: 이길 수도 질 수도 없는 싸움에서 방치 진행이 멈추지 않도록, 넘기면 실패로 친다(다음 행동은 실패와 같다).
Runner.BOSS_TIME = 180       -- 스테이지 보스 한 마리
Runner.RAID_BOSS_TIME = 300  -- 레이드 보스 한 마리
Runner.STAGE_TIME = 1800     -- 스테이지 전체

-- opts:
--   difficulty(1~4), section(구간 키), seed
--   party = { {heroId, form, passivePoints, skills = {{id, level}, ...}, gear, level, exp}, ... } (편성 순서)
--   account(계정 공통 시트), bossIndex(이번에 나올 보스의 순번), tuning = {hp, atk}(5인 보정 계수), onEvent
--   raidKey(레이드 스테이지의 키): 주면 그 레이드를 진행한다. 보스를 차례로 상대하며 wave가 보스 순번이 된다.
--   stageKey: 주면 그 스테이지(원정 등)를 진행한다. 스테이지 표에 section(몬스터 구성)이 들어 있다.
function Runner.new(opts)
    local key = opts.stageKey or opts.raidKey or Dungeons.stageKey(opts.difficulty or 1, opts.section)
    local stage = Tables.STAGES[key]
    local raid, section
    if stage and stage.actBoss then
        raid = stage.raid or Raids.byAct[math.floor(key % 1000 / 100)]
        if not raid then error("레이드 데이터가 없음: " .. tostring(key)) end
    else
        section = stage and stage.section or Dungeons.sections[opts.section]
        if not stage or not section then error("알 수 없는 스테이지: " .. tostring(key)) end
    end
    local difficulty = stage.difficulty or (raid and math.floor(key / 1000)) or (opts.difficulty or 1)
    local r = setmetatable({
        key = key, stage = stage, section = section, raid = raid, difficulty = difficulty,
        party = opts.party, account = opts.account, tuning = opts.tuning or { hp = 1, atk = 1 },
        bossIndex = opts.bossIndex or 1,
        wave = 0, waves = raid and #raid.bosses or (stage.waves - (opts.waveReduction or 0)), phase = "start", timer = 0,
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
            gear = p.gear, account = opts.account, rank = rank, x = -(rank - 1) * 20, uniques = p.uniques })
        u.state = p
        r.heroes[rank] = u
        r.totals.exp[rank] = 0
    end
    WIH.Uniques.installParty(r.battle, r.heroes)
    return r
end

function R:emit(ev, a, b, c, d, e, f, g)
    for i = 1, #self.listeners do self.listeners[i](ev, a, b, c, d, e, f, g) end
end

-- 몬스터 정의와 스테이지 레벨로 전투 유닛을 만든다. bossMult = 스테이지 보스 배율(퍼밀 4개) 또는 nil
-- 구간의 몬스터 구성에서 가중 평균(기본값 기준)을 구한다. 한 번 계산해 구간 표에 넣어 둔다.
local function sectionMeans(section)
    if section.means then return section.means end
    local w, hp, dps, gold, exp = 0, 0, 0, 0, 0
    for _, m in ipairs(section.mobs) do
        local def = Monsters.defs[m.id]
        w = w + m.weight
        hp = hp + def.hp * m.weight
        dps = dps + def.atk * def.as / 100 * m.weight
        gold = gold + def.gold * m.weight
        exp = exp + def.exp * m.weight
    end
    local bn, bhp, bdps = #section.bosses, 0, 0
    for _, id in ipairs(section.bosses) do
        local def = Monsters.defs[id]
        bhp = bhp + def.hp
        bdps = bdps + def.atk * def.as / 100
    end
    section.means = { hp = hp / w, dps = dps / w, gold = gold / w, exp = exp / w, bossHp = bhp / bn, bossDps = bdps / bn }
    return section.means
end
Runner.sectionMeans = sectionMeans

-- 원정의 강도 강화 [원작]: 체력·공격력·이동속도에 (1 + 퍼밀 ÷ 1000)을 곱한다 [추정: 곱연산]
local function boost(stage)
    local b = stage.boost
    if not b then return 1, 1, 1 end
    return 1 + b[1] / 1000, 1 + b[2] / 1000, 1 + b[3] / 1000
end

-- 일반 몬스터 한 종의 실제 수치: 원작 스테이지 평균 × (이 몬스터의 기본값 ÷ 구간 평균)
function Runner.mobValues(stage, section, def)
    local mean, target = sectionMeans(section), stage.mob
    local hpM, atkM, msM = boost(stage)
    return {
        hp = target.hp * def.hp / mean.hp * hpM,
        atk = target.dps * (def.atk * def.as / 100) / mean.dps / (def.as / 100) * atkM,
        gold = target.gold * def.gold / mean.gold,
        exp = target.exp * def.exp / mean.exp,
        msMult = msM,
    }
end

-- 보스의 실제 수치: 원작 스테이지 보스의 최종값 × (이 보스의 기본값 ÷ 구간 보스 평균). 보상은 원작 값 그대로.
function Runner.bossValues(stage, section, def)
    local mean, target = sectionMeans(section), stage.bossFinal
    local hpM, atkM, msM = boost(stage)
    return {
        hp = target.hp * def.hp / mean.bossHp * hpM,
        atk = target.dps * (def.atk * def.as / 100) / mean.bossDps / (def.as / 100) * atkM,
        gold = target.gold, exp = target.exp, msMult = msM,
    }
end

-- 보스 패턴 보정 [독자]: 원작의 보스는 기본 공격만 한다. 이 프로젝트의 보스 패턴 피해가 원작 수치에 그대로 더해지지 않도록,
-- "기본 공격 + 패턴"의 피해가 "기본 공격만"의 피해와 같아지게 보스의 공격력을 줄인다.
-- 재는 방법: 가만히 서 있는 허수아비 5개를 상대로 40초 동안 준 피해의 합을 비교한다. 기준은 "물리 기본 공격만"이고(원작 액트 보스),
-- 허수아비는 물리 피해를 절반 막고 원소 피해는 그대로 받는다(방어도가 있는 영웅의 대표값 [독자]). 그래서 원소 보스는 더 많이 줄어든다.
-- 보스(와 쓰는 패턴 수)마다 한 번만 재고 기억한다. 비율은 PATTERN_FLOOR~1로 묶는다.
Runner.PATTERN_WINDOW = 40
Runner.PATTERN_FLOOR = 0.08
local patternCache = {}

local function measureOutput(def, n, physical)
    local b = Battle.new({ seed = 3, stageLevel = 1, autoRevive = false })
    local dummies = {}
    for i = 1, 5 do
        local d = Unit.new({ name = "허수아비", team = 1, kind = "dummy", melee = true, range = 100, x = -(i - 1) * 20, rank = i,
            base = { MaxHp = 1e15, AttackDamage = 0, AttackSpeed = 100, MovementSpeed = 0, CriticalDamage = 1000, CastSpeed = 100,
                PhysicalDamageReduction = 500 } })
        d.custom = function() end
        b:addUnit(d)
        dummies[i] = d
    end
    local boss = Runner.spawnMonster(b, def, { hp = 1e12, atk = 100, gold = 0, exp = 0 }, 200, nil, n, true)
    if physical then boss.basicElem = "Physical" end
    b:run(Runner.PATTERN_WINDOW)
    local total = 0
    for _, d in ipairs(dummies) do total = total + d.stats.taken end
    return total
end

function Runner.patternScale(def, maxSkills)
    local n = math.min(#(def.skills or {}), maxSkills or #(def.skills or {}))
    if n == 0 and (def.elem or "Physical") == "Physical" then return 1 end
    local key = def.id .. ":" .. n
    local k = patternCache[key]
    if k then return k end
    local basic, all = measureOutput(def, 0, true), measureOutput(def, n)
    k = (all > 0 and basic > 0) and basic / all or 1
    if k > 1 then k = 1 elseif k < Runner.PATTERN_FLOOR then k = Runner.PATTERN_FLOOR end
    patternCache[key] = k
    return k
end

-- values = { hp, atk, gold, exp }(이미 스테이지에 맞춰진 실제 수치), tuning = { hp, atk }(5인 보정 계수)
-- maxSkills가 있으면 패턴을 앞에서부터 그 수만큼만 쓴다(레이드 보스의 난이도별 패턴 수).
-- raw가 참이면 패턴 보정을 하지 않는다(보정 값을 잴 때).
function Runner.spawnMonster(battle, def, values, x, tuning, maxSkills, raw)
    tuning = tuning or { hp = 1, atk = 1 }
    local hp, atk = values.hp * tuning.hp, values.atk * tuning.atk
    if not raw and def.isBoss then atk = atk * Runner.patternScale(def, maxSkills) end
    local gold, exp = values.gold, values.exp
    if hp < 1 then hp = 1 end
    local u = Unit.new({
        name = def.name, team = 2, kind = "monster", isBoss = def.isBoss, def = def,
        base = { MaxHp = hp, AttackDamage = atk, AttackSpeed = def.as, MovementSpeed = def.ms * (values.msMult or 1), CriticalDamage = 1000,
            CastSpeed = 100 },
        melee = def.melee, range = def.range, x = x, rank = 50,
        basicElem = def.elem, basicDelivery = def.melee and "melee" or "proj", basicArea = def.area,
    })
    u.reward = { gold = gold, exp = exp }
    battle:addUnit(u)
    if def.skills then
        for i = 1, math.min(#def.skills, maxSkills or #def.skills) do
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
        Runner.spawnMonster(self.battle, def, Runner.mobValues(self.stage, self.section, def), base + (i - 1) * MOB_SPACING, self.tuning)
    end
    self.phase = "wave"
    self:emit("wave", self.wave, self.waves)
end

-- 원정 강도 n에서 나오는 보스의 순번(보스 count명 중) [원작 구조: 강도 20은 마지막 보스]
function Runner.rotationTurn(n, count)
    if n >= 20 then return count end
    return (n - 1) % (count - 1) + 1
end

function R:spawnBoss()
    local ids = self.section.bosses
    local turn = self.bossIndex
    -- 원정: 강도에 따라 보스가 돌아가며 나오고, 강도 20은 마지막 보스다 [원작 구조]
    if self.stage.bossRotation then turn = Runner.rotationTurn(self.stage.bossRotation, #ids) end
    local id = ids[(turn - 1) % #ids + 1]
    local def = Monsters.defs[id]
    self.boss = Runner.spawnMonster(self.battle, def, Runner.bossValues(self.stage, self.section, def), self:frontX() + BOSS_GAP, self.tuning)
    self.bossStart = self.battle.time
    self.phase = "boss"
    self:emit("boss", self.boss)
end

-- 레이드의 다음 보스. 마지막 보스는 원작 액트 보스의 체력, 그 앞의 보스들은 그 일부다.
-- 공격력은 초당 피해가 원작 액트 보스와 같아지게 맞춘다. 골드·경험치는 원작의 총량을 체력 비율대로 나눈다. [원작 총량 / 독자 배분]
function R:spawnRaidBoss()
    self.wave = self.wave + 1
    local def = Monsters.defs[self.raid.bosses[self.wave]]
    local final = self.stage.actBossFinal
    local share = Raids.hpShare(self.wave, self.waves)
    local values = {
        hp = final.hp * share, atk = final.atk * final.as / def.as,
        gold = final.gold * share, exp = final.exp * share,
    }
    self.boss = Runner.spawnMonster(self.battle, def, values, self:frontX() + BOSS_GAP, self.tuning, Raids.skillCount(self.difficulty))
    self.bossStart = self.battle.time
    self.phase = "boss"
    self:emit("boss", self.boss, self.wave, self.waves)
end

-- 레이드 보스 사이의 숨 돌리기 [독자]: 쓰러진 영웅은 체력 RAID_REST로 일어나고, 살아 있는 영웅은 최대 체력의 RAID_REST만큼 회복한다.
-- 재사용 시간과 지속 효과는 그대로 이어진다.
Runner.RAID_REST = 0.5
function R:raidRest()
    local b = self.battle
    for _, u in ipairs(self.heroes) do
        if u.alive then
            b:heal(nil, u, u:get("MaxHp") * Runner.RAID_REST, true)
        else
            b:revive(u, Runner.RAID_REST)
        end
    end
end

-- 전투 이벤트: 몬스터가 죽으면 보상을 계산한다.
function R:onBattleEvent(ev, a, b, c, d, e, f)
    if ev == "death" and a.team == 2 and a.reward then
        local reward = a.reward
        local totals = self.totals
        totals.kills = totals.kills + 1
        totals.gold = totals.gold + reward.gold
        -- 경험치: 살아 있는 영웅 각자가 전액을 받고, 각자의 레벨 차 페널티를 적용한다. [추정]
        for rank, u in ipairs(self.heroes) do
            if u.alive then
                local st = u.state
                local level = (st and st.heroState and st.heroState.level) or (st and st.level) or 1
                local gain = reward.exp * Level.expPenalty(level, self.stage.level) * u:get("IncreaseExpAmount")
                    + u:get("AdditionalExp")
                totals.exp[rank] = totals.exp[rank] + gain
            end
        end
        if a.isBoss then
            totals.bossKills = totals.bossKills + 1
            if self.stage.bossChest and self.battle.rng:chance(self.stage.bossChest / 1000) then totals.bossChestRolls = totals.bossChestRolls + 1 end
        elseif self.raid then
            -- 레이드에서는 일반 상자가 없다.
        else
            if self.battle.rng:chance(self.stage.chest / 1000) then totals.chestRolls = totals.chestRolls + 1 end
        end
        self:emit("kill", a, reward)
    end
    -- 화면이 보고 있을 때만 전투 이벤트를 그대로 전달한다(보지 않을 때의 비용을 없앤다).
    if self.relayBattle then self:emit("battle", ev, a, b, c, d, e, f) end
end

-- 한 틱 진행. 끝났으면 "clear" 또는 "fail"을 돌려준다.
function R:step()
    if self.result then return self.result end
    local b = self.battle
    if self.phase == "start" then
        if self.raid then self:spawnRaidBoss() else self:spawnWave() end
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
    local limit = self.raid and Runner.RAID_BOSS_TIME or Runner.BOSS_TIME
    if (self.phase == "boss" and self.bossStart and b.time - self.bossStart > limit) or b.time > Runner.STAGE_TIME then
        self.result = "fail"
        self.failReason = "time"
        self:emit("fail", self.wave, "time")
        return self.result
    end

    if b:count(2) == 0 then
        if self.phase == "wave" then
            self.phase = "travel"
            self.timer = TRAVEL_PAUSE
        elseif self.phase == "travel" then
            self.timer = self.timer - WIH.TICK
            if self.timer <= 0 then
                if self.raid then self:spawnRaidBoss()
                elseif self.wave < self.waves then self:spawnWave() else self:spawnBoss() end
            end
        elseif self.phase == "boss" then
            if self.raid and self.wave < self.waves then
                self.phase = "travel"            -- 다음 보스로 이동
                self.timer = TRAVEL_PAUSE
                self:raidRest()
            else
                self.result = "clear"
                self:emit("clear", self.totals)
            end
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
