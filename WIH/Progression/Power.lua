-- 전투력 표시 [독자]: 영웅의 예상 초당 피해, 초당 회복, 유효 체력, 그리고 이 셋을 합친 종합 전투력.
-- 화면이 따로 계산하지 않도록 여기서 엔진을 그대로 써서 구한다.
--   초당 피해 = 표준 허수아비 전투(적 1, 30초)를 엔진으로 돌려 준 피해 ÷ 시간. 소환물이 준 피해도 주인의 것으로 센다.
--   초당 회복 = 같은 전투에서 아군 허수아비(이 영웅과 최대 체력이 같고 늘 절반)에게 실제로 들어간 회복 + 건 보호막 ÷ 시간
--   유효 체력 = 현재 스테이지의 보스 기본 공격(물리) 한 방을 기준으로, 쓰러질 때까지 받아낼 수 있는 원래 피해의 총량.
--              회피·막기는 기대값으로, 방어도·피해 감소·피해 흡수는 전투와 같은 식으로 넣는다.
--   종합 전투력 = 초당 피해 × 10 + 초당 회복 × 10 + 유효 체력 × 0.25
-- 결과는 영웅의 상태(레벨, 스킬, 장비, 룬, 스테이지 레벨)가 바뀔 때만 다시 계산한다.

local _, WIH = ...
local Tables = WIH.module("Tables")
local Unit = WIH.module("Unit")
local Battle = WIH.module("Battle")
local HeroBuild = WIH.module("HeroBuild")
local Game = WIH.module("Game")
local Power = WIH.module("Power")

Power.SECONDS = 30
Power.WEIGHT_DPS, Power.WEIGHT_HPS, Power.WEIGHT_EHP = 10, 10, 0.25

local cache = {}

-- 기준 타격: 현재 스테이지 보스의 기본 공격 한 방(원작 값). 레이드 자리면 액트 보스의 공격력.
function Power.referenceHit(stageKey)
    local stage = Tables.STAGES[stageKey]
    if not stage then return 1 end
    if stage.actBossFinal then return math.max(1, stage.actBossFinal.atk) end
    return math.max(1, stage.bossFinal.dps / 0.8)
end

-- 유효 체력: 유닛의 능력치와 기준 타격으로 구한다(난수 없음).
function Power.effectiveHp(u, stageLevel, hit)
    local function after(d)
        d = d * (1 - Battle.armorReduction(u:get("Armor"), d, stageLevel, u.melee))
        d = d * (1 - u:get("DamageReduction"))
        d = d - u:get("DamageAbsorption")
        return d < 1 and 1 or d
    end
    local dodge, block = u:get("DodgeChance"), u:get("BlockChance")
    local expected = (1 - dodge) * ((1 - block) * after(hit) + block * after(hit * (1 - (u.blockReduce or 0.5))))
    if expected <= 0 then return math.huge end
    return u:get("MaxHp") * hit / expected
end

local function signature(state, heroId, stageKey)
    local h = state.heroes[heroId]
    local parts = { heroId, h.level, h.form or "", stageKey, state.unlocks.skillSlots or 0 }
    for i, id in ipairs(h.bar) do parts[#parts + 1] = id .. ":" .. (h.active[id] or 0) end
    for index = 1, 16 do parts[#parts + 1] = h.passive[index] or 0 end
    for _, slot in ipairs(WIH.Items.SLOTS) do
        local entry = h.gear and h.gear[slot]
        parts[#parts + 1] = entry and entry.id or 0
    end
    local runes = 0
    for key, level in pairs(state.runes or {}) do runes = runes + key * level end
    parts[#parts + 1] = runes
    return table.concat(parts, ",")
end

-- 돌려주는 값: { dps, hps, ehp, power }
function Power.measure(state, heroId, stageKey)
    stageKey = stageKey or Game.currentStageKey(state)
    local stage = Tables.STAGES[stageKey]
    local entry = Game.heroEntry(state, heroId)
    local account = WIH.Runes.sheet(state)
    local b = Battle.new({ seed = 77, stageLevel = stage.level, resistPenalty = Tables.RESIST_PENALTY[math.floor(stageKey / 1000)] })
    local u = HeroBuild.spawn(b, heroId, { form = entry.form, passivePoints = entry.passivePoints, skills = entry.skills,
        gear = entry.gear, account = account, rank = 1, x = 0 })
    -- 적 허수아비: 때리지 않고 죽지 않는다.
    b:addUnit(Unit.new({ name = "허수아비", team = 2, kind = "monster", isBoss = true,
        base = { MaxHp = 1e12, AttackSpeed = 0, MovementSpeed = 0, CriticalDamage = 1000 },
        range = 0, x = math.min(u.range, 600) * 0.8 }))
    -- 아군 허수아비: 체력이 절반이라 회복이 실제로 들어간다.
    -- 아군 허수아비: 이 영웅과 최대 체력이 같고, 늘 체력이 절반이다(회복이 넘치지 않고 실제로 들어간다).
    -- 영웅만 고르는 회복 스킬도 고를 수 있게 종류를 영웅으로 둔다.
    local ally = Unit.new({ name = "아군 허수아비", team = 1, kind = "hero",
        base = { MaxHp = u:get("MaxHp"), AttackSpeed = 0, MovementSpeed = 0, CriticalDamage = 1000 }, range = 0, rank = 9, x = -40 })
    b:addUnit(ally)
    local half = ally:get("MaxHp") * 0.5
    for _ = 1, math.floor(Power.SECONDS / WIH.TICK + 0.5) do
        ally.hp = half
        b:step()
    end
    local dps = u.stats.dealt / Power.SECONDS
    local hps = (u.stats.healed + u.stats.shielded) / Power.SECONDS
    local ehp = Power.effectiveHp(u, stage.level, Power.referenceHit(stageKey))
    return {
        dps = dps, hps = hps, ehp = ehp,
        power = dps * Power.WEIGHT_DPS + hps * Power.WEIGHT_HPS + ehp * Power.WEIGHT_EHP,
    }
end

-- 저장해 둔 결과를 쓰고, 상태가 바뀌었을 때만 다시 계산한다.
function Power.get(state, heroId, stageKey)
    stageKey = stageKey or Game.currentStageKey(state)
    local sig = signature(state, heroId, stageKey)
    local hit = cache[heroId]
    if hit and hit.sig == sig then return hit.result end
    local result = Power.measure(state, heroId, stageKey)
    cache[heroId] = { sig = sig, result = result }
    return result
end

function Power.clear() cache = {} end

return Power
