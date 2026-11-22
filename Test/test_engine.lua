-- 전투 엔진 핵심의 단위 테스트.
-- 실행: lua5.1 Test/test_engine.lua   (저장소 최상위에서)

package.path = "./?.lua;" .. package.path
local T = require("Test.t")
local WIH = require("Test.engine").load()

local Stats, Sheet, Unit, Battle, Skills, Rng = WIH.Stats, WIH.Sheet, WIH.Unit, WIH.Battle, WIH.Skills, WIH.Rng
local FLAT, INC, MORE = Stats.FLAT, Stats.INC, Stats.MORE
local TICK = WIH.TICK

-- 시험용 유닛 -----------------------------------------------------------

local function hero(over)
    local base = { MaxHp = 1000, AttackDamage = 100, AttackSpeed = 100, CriticalChance = 0, CriticalDamage = 1500,
        MovementSpeed = 800, CastSpeed = 100 }
    local spec = { name = "영웅", team = 1, kind = "hero", base = base, melee = true, range = 150, rank = 1, x = 0 }
    for k, v in pairs(over or {}) do
        if k == "base" then
            for s, val in pairs(v) do base[s] = val end
        else
            spec[k] = v
        end
    end
    return Unit.new(spec)
end

-- 공격하지 않고 서 있기만 하는 대상
local function dummy(hp, x, over)
    local spec = { name = "허수아비", team = 2, kind = "monster",
        base = { MaxHp = hp or 1e9, AttackDamage = 0, AttackSpeed = 100, MovementSpeed = 0, CriticalDamage = 1000 },
        range = 0, x = x or 100, rank = 1 }
    for k, v in pairs(over or {}) do
        if k == "base" then
            for s, val in pairs(v) do spec.base[s] = val end
        else
            spec[k] = v
        end
    end
    return Unit.new(spec)
end

local function attacker(ad, x, over)
    local spec = { name = "공격자", team = 2, kind = "monster",
        base = { MaxHp = 1e9, AttackDamage = ad, AttackSpeed = 100, MovementSpeed = 0, CriticalDamage = 1000 },
        melee = true, range = 200, x = x or 100, rank = 1 }
    for k, v in pairs(over or {}) do
        if k == "base" then
            for s, val in pairs(v) do spec.base[s] = val end
        else
            spec[k] = v
        end
    end
    return Unit.new(spec)
end

local function battle(opts)
    return Battle.new(opts or { seed = 7 })
end

-- 난수 -------------------------------------------------------------------

T.case("난수: 같은 시드는 같은 수열", function()
    local a, b = Rng.new(123), Rng.new(123)
    for _ = 1, 1000 do T.eq(a:next(), b:next()) end
    local c = Rng.new(124)
    local same = 0
    a = Rng.new(123)
    for _ = 1, 100 do if a:next() == c:next() then same = same + 1 end end
    T.ok(same < 5, "다른 시드인데 수열이 같음")
end)

T.case("난수: 범위와 분포", function()
    local r = Rng.new(99)
    local sum, n = 0, 200000
    for _ = 1, n do
        local f = r:float()
        T.ok(f >= 0 and f < 1, "float 범위 벗어남")
        sum = sum + f
    end
    T.near(sum / n, 0.5, 0.005, "평균")
    local counts = { 0, 0, 0 }
    for _ = 1, 60000 do
        local i = r:weighted({ 1, 2, 3 })
        counts[i] = counts[i] + 1
    end
    T.near(counts[1] / 60000, 1 / 6, 0.01)
    T.near(counts[3] / 60000, 3 / 6, 0.01)
    for _ = 1, 1000 do
        local v = r:int(3, 7)
        T.ok(v >= 3 and v <= 7 and v == math.floor(v))
    end
    T.eq(r:chance(0), false)
    T.eq(r:chance(1), true)
end)

-- 능력치 합산 ------------------------------------------------------------

T.case("합산식: (기본 + Flat) × (1 + Increased) × More", function()
    local u = hero()
    Sheet.add(u.static, "AttackDamage", FLAT, 50)       -- 150
    Sheet.add(u.static, "AttackDamage", INC, 200)       -- +20%
    Sheet.add(u.static, "AttackDamage", INC, 300)       -- +30% → 합 50%
    Sheet.add(u.static, "AttackDamage", MORE, 100)      -- ×1.1
    Sheet.add(u.static, "AttackDamage", MORE, 200)      -- ×1.2
    u:invalidate()
    T.near(u:get("AttackDamage"), 150 * 1.5 * 1.1 * 1.2, 1e-9)
end)

T.case("단위: 공격속도 ÷100, 퍼밀 ÷1000, 저항 그대로", function()
    local u = hero({ base = { AttackSpeed = 80, CriticalChance = 25, CriticalDamage = 1400, FireResistance = 30,
        HpRegenPerSec = 200, DamageAbsorption = 5 } })
    Sheet.add(u.static, "AttackSpeed", FLAT, 40)
    u:invalidate()
    T.near(u:get("AttackSpeed"), 1.20, 1e-9)
    T.near(u:get("CriticalChance"), 0.025, 1e-9)
    T.near(u:get("CriticalDamage"), 1.4, 1e-9)
    T.near(u:get("FireResistance"), 30, 1e-9)
    T.near(u:get("HpRegenPerSec"), 2, 1e-9)
    T.near(u:get("DamageAbsorption"), 0.5, 1e-9)
    T.near(u:get("IncreaseMeleeDamage"), 1, 1e-9, "배율형 능력치의 기본값")
    T.near(u:get("CastSpeed"), 1, 1e-9)
end)

T.case("상한: 치명타 100%, 재사용 감소 75%, 피해 감소 75%, 회피·막기 75%", function()
    local u = hero({ base = { CriticalChance = 1500, CooldownReduction = 900, DamageReduction = 900,
        DodgeChance = 900, BlockChance = 900 } })
    T.near(u:get("CriticalChance"), 1.0)
    T.near(u:get("CooldownReduction"), 0.75)
    T.near(u:get("DamageReduction"), 0.75)
    T.near(u:get("DodgeChance"), 0.75)
    T.near(u:get("BlockChance"), 0.75)
    Sheet.add(u.static, "MaxDodgeChance", FLAT, 100)
    u:invalidate()
    T.near(u:get("DodgeChance"), 0.85, 1e-9, "최대 회피 능력치로 상한 상향")
end)

T.case("정의되지 않은 능력치는 오류", function()
    local s = Sheet.new()
    local ok = pcall(Sheet.add, s, "NoSuchStat", FLAT, 1)
    T.eq(ok, false)
end)

-- 주는 피해 --------------------------------------------------------------

T.case("주는 피해: 공격력 × 계수 × 속성 % × 전달 방식 × 치명타", function()
    local b = battle()
    local u = b:addUnit(hero({ base = { FireDamagePercent = 500, IncreaseProjectileDamage = 1000 } }))
    Sheet.add(u.static, "IncreaseProjectileDamage", INC, 200)
    Sheet.add(u.static, "IncreaseAreaOfEffectDamage", INC, 500)
    u:invalidate()
    local d = b:addUnit(dummy())
    T.near(b:hit(u, d, { coef = 2.5, elem = "Fire", canCrit = false }), 100 * 2.5 * 1.5, 1e-6)
    T.near(b:hit(u, d, { coef = 2.5, elem = "Fire", proj = true, canCrit = false }), 100 * 2.5 * 1.5 * 1.2, 1e-6)
    T.near(b:hit(u, d, { coef = 2.5, elem = "Fire", proj = true, aoe = true, canCrit = false }),
        100 * 2.5 * 1.5 * 1.2 * 1.5, 1e-6, "전달 방식 둘은 서로 곱한다")
    T.near(b:hit(u, d, { coef = 1, elem = "Physical", forceCrit = true }), 100 * 1.5, 1e-6, "치명타 피해 150%")
    T.near(b:hit(u, d, { coef = 1, elem = "Physical", mult = 2, canCrit = false }), 200, 1e-6)
end)

T.case("치명타 확률이 실제 빈도와 맞는다", function()
    local b = battle({ seed = 11 })
    local u = b:addUnit(hero({ base = { CriticalChance = 300 } }))
    local d = b:addUnit(dummy())
    local crits, n = 0, 20000
    for _ = 1, n do
        if b:hit(u, d, { coef = 1 }) > 100.5 then crits = crits + 1 end
    end
    T.near(crits / n, 0.30, 0.012)
end)

T.case("추가 피해와 받는 피해 증가", function()
    local b = battle()
    local u = b:addUnit(hero({ base = { DamageAddition = 10, FireDamageAddition = 5 } }))
    local d = b:addUnit(dummy())
    T.near(b:hit(u, d, { coef = 1, elem = "Fire", canCrit = false }), 115, 1e-6)
    b:applyStatus(u, d, "Ignite")
    T.near(b:hit(u, d, { coef = 1, elem = "Fire", canCrit = false }), 115 * 1.2, 1e-6, "점화: 화염 피해 20% 더 받음")
    T.near(b:hit(u, d, { coef = 1, elem = "Cold", canCrit = false }), 110, 1e-6, "다른 속성에는 적용 안 됨")
    b:applyStatus(u, d, "Stun")
    T.near(b:hit(u, d, { coef = 1, elem = "Fire", canCrit = false }), 115 * 1.3, 1e-6, "기절 10% + 점화 20%는 합산")
end)

-- 받는 피해 --------------------------------------------------------------

T.case("방어도 공식과 상한(근접 85%, 원거리 75%)", function()
    local b = battle({ seed = 1, stageLevel = 10 })   -- K = 152
    local k = 14 * 10 + 12
    local m = b:addUnit(attacker(200))
    local u = b:addUnit(hero({ base = { Armor = 152 } }))
    local expected = 200 * (1 - 152 * 152 / (152 * 152 + k * (152 + 0.4 * 200)))
    T.near(b:hit(m, u, { coef = 1, canCrit = false }), expected, 1e-6)
    -- 방어도가 매우 높으면 상한
    local tank = b:addUnit(hero({ base = { Armor = 1e6 }, melee = true }))
    T.near(b:hit(m, tank, { coef = 1, canCrit = false }), 200 * 0.15, 1e-6, "근접 상한 85%")
    local ranged = b:addUnit(hero({ base = { Armor = 1e6 }, melee = false }))
    T.near(b:hit(m, ranged, { coef = 1, canCrit = false }), 200 * 0.25, 1e-6, "원거리 상한 75%")
    -- 방어도는 원소 피해에 듣지 않는다
    T.near(b:hit(m, tank, { coef = 1, elem = "Fire", canCrit = false }), 200, 1e-6)
    -- 한 방이 클수록 경감이 줄어든다
    local big = b:addUnit(attacker(20000))
    local r1 = 1 - b:hit(m, u, { coef = 1, canCrit = false }) / 200
    local r2 = 1 - b:hit(big, u, { coef = 1, canCrit = false }) / 20000
    T.ok(r2 < r1, "큰 피해에 방어도 효율이 낮아져야 함")
end)

T.case("저항: 선형, 난이도 페널티, 음수, 상한, 암흑 제외", function()
    local b = battle({ seed = 1, resistPenalty = 40 })
    local m = b:addUnit(attacker(100))
    local u = b:addUnit(hero({ base = { FireResistance = 50, AllElementalResistance = 20, ChaosResistance = 10 } }))
    T.near(b:hit(m, u, { coef = 1, elem = "Fire", canCrit = false }), 100 * (1 - 0.30), 1e-6, "50 + 20 − 40")
    T.near(b:hit(m, u, { coef = 1, elem = "Cold", canCrit = false }), 100 * (1 + 0.20), 1e-6, "0 + 20 − 40 = −20 → 더 받음")
    T.near(b:hit(m, u, { coef = 1, elem = "Chaos", canCrit = false }), 100 * (1 + 0.30), 1e-6, "암흑에는 모든 원소 저항 미적용")
    local r = b:addUnit(hero({ base = { LightningResistance = 200 } }))
    T.near(b:hit(m, r, { coef = 1, elem = "Lightning", canCrit = false }), 100 * 0.25, 1e-6, "상한 75")
    Sheet.add(r.static, "MaxLightningResistance", FLAT, 5)
    r:invalidate()
    T.near(b:hit(m, r, { coef = 1, elem = "Lightning", canCrit = false }), 100 * 0.20, 1e-6, "최대 저항 +5")
    -- 몬스터 쪽에는 페널티가 붙지 않는다
    local d = b:addUnit(dummy(1e9, 100, { base = { FireResistance = 10 } }))
    T.near(b:hit(u, d, { coef = 1, elem = "Fire", canCrit = false }), 100 * 0.9, 1e-6)
end)

T.case("피해 감소 → 흡수 → 최소 1 순서", function()
    local b = battle()
    local m = b:addUnit(attacker(100))
    local u = b:addUnit(hero({ base = { DamageReduction = 200, PhysicalDamageReduction = 100, DamageAbsorption = 50 } }))
    T.near(b:hit(m, u, { coef = 1, canCrit = false }), 100 * 0.8 * 0.9 - 5, 1e-6)
    local w = b:addUnit(attacker(3))
    T.near(b:hit(w, u, { coef = 1, canCrit = false }), 1, 1e-6, "흡수가 피해보다 커도 최소 1")
end)

T.case("회피와 막기의 빈도, 막기는 절반", function()
    local b = battle({ seed = 5 })
    local m = b:addUnit(attacker(100))
    local u = b:addUnit(hero({ base = { DodgeChance = 200, BlockChance = 400, MaxHp = 1e12 } }))
    local dodged, blocked, full, n = 0, 0, 0, 30000
    for _ = 1, n do
        local d = b:hit(m, u, { coef = 1, canCrit = false })
        if d == 0 then dodged = dodged + 1
        elseif math.abs(d - 50) < 1e-6 then blocked = blocked + 1
        elseif math.abs(d - 100) < 1e-6 then full = full + 1
        else error("예상하지 못한 피해: " .. d) end
    end
    T.near(dodged / n, 0.20, 0.01)
    T.near(blocked / n, 0.80 * 0.40, 0.012, "막기는 회피 실패 뒤에 굴린다")
    -- 지속 피해는 회피·막기를 굴리지 않는다
    T.near(b:hit(m, u, { coef = 1, isDot = true }), 100, 1e-6)
    -- 원소 공격은 원소 회피를 쓴다
    local e = b:addUnit(hero({ base = { DodgeChance = 1000, MaxDodgeChance = 1000 } }))
    T.near(b:hit(m, e, { coef = 1, elem = "Fire", canCrit = false }), 100, 1e-6)
    T.near(b:hit(m, e, { coef = 1, canCrit = false }), 0, 1e-6)
end)

T.case("보호막이 체력보다 먼저 깎인다", function()
    local b = battle()
    local m = b:addUnit(attacker(100))
    local u = b:addUnit(hero())
    b:addShield(u, u, 150, 10, "s1")
    b:hit(m, u, { coef = 1, canCrit = false })
    T.near(u.hp, 1000, 1e-6)
    T.near(u:shieldTotal(), 50, 1e-6)
    b:hit(m, u, { coef = 1, canCrit = false })
    T.near(u.hp, 950, 1e-6)
    T.near(u:shieldTotal(), 0, 1e-6)
    b:addShield(u, u, 100, 1, "s2")
    b:run(1.2)
    T.near(u:shieldTotal(), 0, 1e-6, "보호막 시간 만료")
end)

-- 상태 이상 --------------------------------------------------------------

T.case("상태 이상: 지속시간과 재적용 규칙", function()
    local b = battle()
    local u = b:addUnit(hero({ x = -5000 }))
    local d = b:addUnit(dummy())
    b:applyStatus(u, d, "Chill")
    b:run(3)
    b:applyStatus(u, d, "Chill")          -- 시간 초기화
    b:run(3)
    T.ok(d:hasStatus("Chill"), "냉각은 다시 걸면 시간이 초기화되어야 함")
    b:run(1.2)
    T.ok(not d:hasStatus("Chill"))
    b:applyStatus(u, d, "Freeze")
    b:run(1)
    b:applyStatus(u, d, "Freeze")         -- 걸린 동안 무효
    b:run(0.6)
    T.ok(not d:hasStatus("Freeze"), "빙결은 걸린 동안 다시 걸리지 않아야 함")
    local boss = b:addUnit(dummy(1e9, 200, { isBoss = true }))
    b:applyStatus(u, boss, "Stun")
    b:run(1.1)
    T.ok(not boss:hasStatus("Stun"), "보스는 기절 지속이 절반")
end)

T.case("냉각은 공격속도와 이동속도를 30% 줄인다(More)", function()
    local b = battle()
    local u = b:addUnit(hero({ x = -5000 }))
    local d = b:addUnit(dummy(1e9, 100, { base = { AttackSpeed = 200, MovementSpeed = 1000 } }))
    b:applyStatus(u, d, "Chill")
    T.near(d:get("AttackSpeed"), 2.0 * 0.7, 1e-9)
    T.near(d:get("MovementSpeed"), 700, 1e-9)
    b:run(4.1)
    T.near(d:get("AttackSpeed"), 2.0, 1e-9)
end)

T.case("지속 피해: 0.5초마다, 건 쪽 공격력 기준", function()
    local b = battle()
    local u = b:addUnit(hero({ x = -5000 }))
    local d = b:addUnit(dummy(1e6))
    b:applyStatus(u, d, "Bleed")          -- 7초, 틱당 15%
    b:run(7.2)
    -- 14틱 × 100 × 0.15 × (출혈 중 물리 피해 +20%)
    T.near(1e6 - d.hp, 14 * 100 * 0.15 * 1.2, 1e-6)
    T.ok(not d:hasStatus("Bleed"))
end)

T.case("빙결·기절 중에는 행동하지 못한다", function()
    local b = battle()
    local u = b:addUnit(hero())
    local m = b:addUnit(attacker(10, 100))
    b:run(2)
    local before = u.hp
    T.ok(before < 1000, "공격자가 공격했어야 함")
    b:applyStatus(u, m, "Stun")
    b:run(1.9)
    T.near(u.hp, before, 1e-6, "기절 중에는 공격하지 못함")
end)

-- 스킬 -------------------------------------------------------------------

local strike = { id = "t_strike", name = "시험 강타", act = { type = "count", n = 4 }, target = "nearest",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 500, 40 } } } }
local blast = { id = "t_blast", name = "시험 폭발", act = { type = "cd", cd = 6 }, target = "nearest", range = 900,
    effects = { { type = "damage", elem = "Fire", coef = { 300, 25 }, area = { r = 200, at = "target" } } } }

T.case("N타 스킬: 기본 공격 4회마다 발동", function()
    local b = battle()
    local u = b:addUnit(hero())
    local d = b:addUnit(dummy())
    Skills.equip(b, u, strike, 1)
    local casts, attacks = 0, 0
    b.listeners[1] = function(ev, a)
        if ev == "cast" then casts = casts + 1 elseif ev == "attack" and a == u then attacks = attacks + 1 end
    end
    b:run(20)
    T.eq(attacks, 20)
    T.eq(casts, 5)
    T.near(1e9 - d.hp, 20 * 100 + 5 * 500, 1e-3)
end)

T.case("기본공격 횟수 요구 감소", function()
    local b = battle()
    local u = b:addUnit(hero({ base = { BaseAttackCountReduction = 2 } }))
    b:addUnit(dummy())
    Skills.equip(b, u, strike, 1)
    local casts = 0
    b.listeners[1] = function(ev) if ev == "cast" then casts = casts + 1 end end
    b:run(20)
    T.eq(casts, 10)
end)

T.case("재사용 스킬: 재사용 감소와 시전속도가 충전을 앞당긴다", function()
    local function count(base, seconds)
        local b = battle()
        base.MovementSpeed = 0
        local u = b:addUnit(hero({ base = base, range = 1, melee = false }))
        b:addUnit(dummy(1e9, 500))
        Skills.equip(b, u, blast, 1)
        local casts = 0
        b.listeners[1] = function(ev) if ev == "cast" then casts = casts + 1 end end
        b:run(seconds)
        return casts
    end
    T.eq(count({}, 60), 10, "6초 재사용: 시작 시 준비 + 6초마다 (0, 6, …, 54)")
    T.eq(count({ CooldownReduction = 500 }, 60), 20, "재사용 감소 50%")
    T.eq(count({ CastSpeed = 200 }, 60), 20, "시전속도 2배")
    T.eq(count({ CooldownReduction = 900 }, 60), 40, "재사용 감소 상한 75%")
end)

T.case("광역 스킬은 반경 안의 적만 맞힌다. 범위 능력치가 반경을 넓힌다", function()
    local b = battle()
    local u = b:addUnit(hero({ range = 1, melee = false, base = { MovementSpeed = 0 } }))
    local d1 = b:addUnit(dummy(1e6, 500))
    local d2 = b:addUnit(dummy(1e6, 650))
    local d3 = b:addUnit(dummy(1e6, 760))
    Skills.equip(b, u, blast, 1)
    b:run(1)
    T.near(1e6 - d1.hp, 300, 1e-6)
    T.near(1e6 - d2.hp, 300, 1e-6)
    T.near(1e6 - d3.hp, 0, 1e-6, "반경 200 밖")
    local b2 = battle()
    local u2 = b2:addUnit(hero({ range = 1, melee = false, base = { MovementSpeed = 0 } }))
    Sheet.add(u2.static, "AreaOfEffect", INC, 500)
    u2:invalidate()
    b2:addUnit(dummy(1e6, 500))
    local far = b2:addUnit(dummy(1e6, 760))
    Skills.equip(b2, u2, blast, 1)
    b2:run(1)
    T.near(1e6 - far.hp, 300, 1e-6, "범위 +50%면 반경 300")
end)

T.case("스킬 레벨: 1 → 10에서 피해가 단조 증가하고 데이터의 계수와 일치한다", function()
    local prev = 0
    for level = 1, 10 do
        local b = battle()
        local u = b:addUnit(hero({ base = { MovementSpeed = 0 }, range = 1, melee = false }))
        local d = b:addUnit(dummy(1e9, 500))
        Skills.equip(b, u, blast, level)
        b:run(0.5)
        local dealt = 1e9 - d.hp
        T.near(dealt, 100 * WIH.scaled(blast.effects[1].coef, level) / 100, 1e-6, "레벨 " .. level)
        T.ok(dealt > prev, "레벨 " .. level .. "에서 증가하지 않음")
        prev = dealt
    end
    -- 모든 스킬 레벨 +N은 10에서 멈춘다
    local b = battle()
    local u = b:addUnit(hero({ base = { MovementSpeed = 0, AddAllSkillLevel = 7 }, range = 1, melee = false }))
    local d = b:addUnit(dummy(1e9, 500))
    Skills.equip(b, u, blast, 5)
    b:run(0.5)
    T.near(1e9 - d.hp, 100 * WIH.scaled(blast.effects[1].coef, 10) / 100, 1e-6)
end)

T.case("사용 조건이 맞지 않으면 스킬을 아낀다", function()
    local heal = { id = "t_heal", name = "시험 치유", act = { type = "cd", cd = 5 }, target = "lowestHpHero",
        cond = { targetHpBelow = 0.8 }, effects = { { type = "heal", pct = { 10, 2 } } } }
    local b = battle()
    local h = b:addUnit(hero({ x = -5000 }))
    Skills.equip(b, h, heal, 1)
    local casts = 0
    b.listeners[1] = function(ev) if ev == "cast" then casts = casts + 1 end end
    b:run(10)
    T.eq(casts, 0, "체력이 가득한데 치유를 씀")
    h.hp = 500
    b:run(0.2)
    T.eq(casts, 1)
    T.near(h.hp, 600, 1e-6, "최대 체력의 10%")
end)

T.case("치유: 회복량 증가, 지속 회복, 연쇄 감쇠", function()
    local b = battle()
    local h = b:addUnit(hero({ x = -5000, base = { SkillHealIncrease = 1500 } }))
    h.hp = 100
    Skills.runEffects(b, h, { { type = "heal", pct = 10 } }, 1, { target = h })
    T.near(h.hp, 100 + 1000 * 0.10 * 1.5, 1e-6)
    Skills.runEffects(b, h, { { type = "heal", who = "self", hot = { dur = 4, pct = 2 } } }, 1, { target = h, slot = { def = { id = "x" } } })
    b:run(4.2)
    T.near(h.hp, 250 + 8 * 1000 * 0.02 * 0.5 * 1.5, 1e-6, "0.5초마다 8번")
    local a = b:addUnit(hero({ x = -5000, rank = 2 }))
    local c = b:addUnit(hero({ x = -5000, rank = 3 }))
    h.hp, a.hp, c.hp = 100, 200, 300
    Skills.runEffects(b, a, { { type = "heal", who = "chain", pct = 10, chain = { n = 3, falloff = 0.25 } } }, 1, {})
    T.near(h.hp, 100 + 100, 1e-6)
    T.near(a.hp, 200 + 75, 1e-6)
    T.near(c.hp, 300 + 56.25, 1e-6)
end)

T.case("버프: 지속시간, 공격 횟수 제한, 지속시간 증가", function()
    local b = battle()
    local u = b:addUnit(hero())
    b:addUnit(dummy())
    Skills.runEffects(b, u, { { type = "buff", who = "self", dur = 2, mods = { { "AttackDamage", MORE, { 400, 40 } } } } }, 3, {})
    T.near(u:get("AttackDamage"), 100 * 1.48, 1e-9, "레벨 3: 400 + 40 × 2")
    b:run(2.1)
    T.near(u:get("AttackDamage"), 100, 1e-9)
    Skills.runEffects(b, u, { { type = "buff", who = "self", attacks = { 3, 1 }, mods = { { "AttackSpeed", INC, 500 } } } }, 2, {})
    T.near(u:get("AttackSpeed"), 1.5, 1e-9)
    local attacks = 0
    b.listeners[1] = function(ev, a) if ev == "attack" and a == u then attacks = attacks + 1 end end
    b:run(3.0)
    -- 공격속도 1.5로 4번(레벨 2: 3 + 1) 친 뒤 원래 속도로 돌아간다
    T.near(u:get("AttackSpeed"), 1.0, 1e-9)
    T.ok(attacks >= 4)
    local d = b:addUnit(hero({ rank = 2, base = { SkillDurationIncrease = 1500 } }))
    Skills.runEffects(b, d, { { type = "buff", who = "self", dur = 2, mods = { { "Armor", FLAT, 10 } } } }, 1, {})
    b:run(2.5)
    T.near(d:get("Armor"), 10, 1e-9, "지속시간 +50%면 3초")
    b:run(0.6)
    T.near(d:get("Armor"), 0, 1e-9)
end)

T.case("오라: 반경 안의 아군에게만, 주인이 죽으면 사라진다", function()
    local aura = { id = "t_aura", name = "시험 오라", act = { type = "aura" },
        effects = { { type = "aura", who = "allies", radius = 500, mods = { { "AttackDamage", MORE, { 200, 30 } } } } } }
    local b = battle()
    local owner = b:addUnit(hero({ x = 0 }))
    local near = b:addUnit(hero({ x = -300, rank = 2 }))
    local far = b:addUnit(hero({ x = -800, rank = 3 }))
    Skills.equip(b, owner, aura, 1)
    b:run(0.2)
    T.near(owner:get("AttackDamage"), 120, 1e-9)
    T.near(near:get("AttackDamage"), 120, 1e-9)
    T.near(far:get("AttackDamage"), 100, 1e-9)
    b:kill(nil, owner)
    b:run(0.2)
    T.near(near:get("AttackDamage"), 100, 1e-9)
end)

T.case("대신 받기: 반경 안 아군의 피해 일부를 탱커가 자기 방어로 받는다", function()
    local guard = { id = "t_guard", name = "시험 수호", act = { type = "aura" },
        effects = { { type = "aura", radius = 600, redirect = { mode = "allies", pct = { 15, 1.5 } } } } }
    local b = battle({ seed = 1, stageLevel = 1 })
    local tank = b:addUnit(hero({ x = 0, base = { DamageReduction = 500 } }))
    local ally = b:addUnit(hero({ x = -200, rank = 2 }))
    local m = b:addUnit(attacker(100, 5000))
    Skills.equip(b, tank, guard, 1)
    b:run(0.1)
    b:hit(m, ally, { coef = 1, canCrit = false })
    T.near(ally.hp, 1000 - 85, 1e-6)
    T.near(tank.hp, 1000 - 15 * 0.5, 1e-6, "넘겨받은 15에 탱커의 피해 감소 50% 적용")
    -- 탱커 자신이 맞는 피해는 넘기지 않는다
    b:hit(m, tank, { coef = 1, canCrit = false })
    T.near(tank.hp, 1000 - 7.5 - 50, 1e-6)
end)

T.case("부활과 빈사 회피", function()
    local b = battle()
    local u = b:addUnit(hero())
    local m = b:addUnit(attacker(5000, 5000))
    local save = { id = "t_save", name = "시험 버티기", act = { type = "aura" },
        effects = { { type = "aura", who = "self", lethal = { pct = { 30, 10 } } } } }
    Skills.equip(b, u, save, 2)
    b:hit(m, u, { coef = 1, canCrit = false })
    T.ok(u.alive, "빈사 회피가 작동해야 함")
    T.near(u.hp, 400, 1e-6, "레벨 2: 최대 체력의 40%")
    b:hit(m, u, { coef = 1, canCrit = false })
    T.ok(not u.alive, "스테이지당 1회만")
    b:run(14.5)
    T.ok(not u.alive)
    b:run(1)
    T.ok(u.alive, "15초 뒤 자동 부활")
    T.near(u.hp, 500, 30, "최대 체력의 50%")
    b:kill(m, u)
    local priest = b:addUnit(hero({ rank = 2, x = -100 }))
    Skills.runEffects(b, priest, { { type = "revive", pct = { 30, 5 } } }, 3, { target = u })
    T.ok(u.alive)
    T.near(u.hp, 400, 1e-6, "레벨 3: 40%")
end)

T.case("소환물: 주인의 공격력으로 치고, 수명이 끝나면 사라지고, 최대 개수를 지킨다", function()
    local turret = { id = "t_turret", name = "시험 포탑", act = { type = "cd", cd = 2 }, target = "nearest", range = 1200,
        effects = { { type = "summon", unit = { name = "포탑", kind = "turret", hpPct = 60, interval = 0.5, coef = { 50, 5 },
            range = 1000, dur = 3, max = 2 } } } }
    local b = battle()
    local u = b:addUnit(hero({ base = { AttackDamage = 200, AttackSpeed = 1, IncreaseSummonDamage = 1500 }, range = 1, melee = false }))
    local d = b:addUnit(dummy(1e9, 800))
    Skills.equip(b, u, turret, 1)
    b:run(0.1)
    local n = 0
    for _, o in ipairs(b.units) do if o.kind == "summon" then n = n + 1 end end
    T.eq(n, 1)
    b:run(1.0)
    -- 포탑: 0.5초마다 200 × 50% × 소환 피해 1.5 = 150
    local dealt = 1e9 - d.hp
    T.ok(dealt >= 150 * 2 and dealt <= 150 * 3 + 1, "포탑 피해: " .. dealt)
    b:run(8)
    n = 0
    for _, o in ipairs(b.units) do if o.kind == "summon" then n = n + 1 end end
    T.ok(n <= 2, "최대 2기")
    T.ok(n >= 1)
end)

T.case("지면 영역과 덫", function()
    local b = battle()
    local u = b:addUnit(hero({ x = 0, base = { MovementSpeed = 0 }, range = 1, melee = false }))
    local d = b:addUnit(dummy(1e6, 300))
    Skills.runEffects(b, u, { { type = "zone", r = 100, dur = 3, every = 1, at = "target",
        enemy = { { type = "damage", elem = "Fire", coef = 50 } } } }, 1, { target = d, slot = { def = { id = "z", name = "z" } } })
    b:run(3.5)
    T.near(1e6 - d.hp, 3 * 50, 1e-6, "1초마다 3번")
    local slot = { def = { id = "tr", name = "덫" } }
    local walker = b:addUnit(dummy(1e6, 2000, { base = { MovementSpeed = 800 }, range = 10 }))
    Skills.runEffects(b, u, { { type = "trap", r = 200, max = 2, effects = {
        { type = "damage", elem = "Fire", coef = 300, area = { r = 200, at = "target" } },
        { type = "status", status = "Ignite" } } } }, 1, { target = walker, slot = slot })
    b:run(6)
    T.ok(1e6 - walker.hp >= 300, "덫이 터졌어야 함")
end)

-- 편성과 대상 선정 --------------------------------------------------------

T.case("몬스터는 가장 가까운 영웅을 치고, 거리가 비슷하면 편성 순서가 앞인 쪽을 친다", function()
    local b = battle()
    local tank = b:addUnit(hero({ x = 0, rank = 1 }))
    local dps = b:addUnit(hero({ x = 0, rank = 2 }))
    local back = b:addUnit(hero({ x = -600, rank = 3, range = 900, melee = false }))
    b:addUnit(attacker(10, 150))
    b:run(5)
    T.ok(tank.hp < 1000, "선두가 맞아야 함")
    T.near(dps.hp, 1000, 1e-6, "같은 자리의 2번은 맞지 않음")
    T.near(back.hp, 1000, 1e-6)
    b:kill(nil, tank)
    b:run(3)
    T.ok(dps.hp < 1000, "선두가 죽으면 다음 순서가 맞음")
end)

T.case("뒤 순서의 영웅은 앞 순서의 영웅을 앞질러 가지 못한다", function()
    local b = battle()
    local slow = b:addUnit(hero({ x = 0, rank = 1, base = { MovementSpeed = 400 } }))
    local fast = b:addUnit(hero({ x = -100, rank = 2, base = { MovementSpeed = 1200 } }))
    b:addUnit(dummy(1e9, 3000))
    for _ = 1, 200 do
        b:step()
        T.ok(fast.x <= slow.x + 1e-9, "앞질러 감")
    end
    T.ok(slow.x > 0, "선두가 전진해야 함")
end)

-- 재현성 -----------------------------------------------------------------

T.case("같은 시드의 전투는 결과가 같다", function()
    local function run(seed)
        local b = battle({ seed = seed })
        local log = {}
        b.listeners[1] = function(ev, a, c, d) if ev == "damage" then log[#log + 1] = string.format("%.6f", d) end end
        local u = b:addUnit(hero({ base = { CriticalChance = 300, DodgeChance = 200 } }))
        Skills.equip(b, u, strike, 3)
        Skills.equip(b, u, blast, 2)
        b:addUnit(attacker(30, 150, { base = { MaxHp = 5000, CriticalChance = 200, CriticalDamage = 2000 } }))
        b:addUnit(attacker(20, 180, { base = { MaxHp = 5000 } }))
        b:run(40)
        return table.concat(log, ",")
    end
    local a, b2, c = run(42), run(42), run(43)
    T.eq(a, b2, "같은 시드인데 결과가 다름")
    T.ok(a ~= c, "다른 시드인데 결과가 같음")
    T.ok(#a > 100)
end)

if not T.report("test_engine") then os.exit(1) end
