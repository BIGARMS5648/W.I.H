-- 몬스터 정의의 틀: 기본형, 보스 패턴 묶음, 등록 함수.
-- 기본 능력치는 원작 몬스터 표의 범위(체력 15~320, 공격력 8~25, 공격속도 0.4~1.5)를 따른다 [원작 범위 / 독자 배치].
-- 여기의 값은 몬스터끼리의 상대적 세기다. 실제 수치는 진행기가 원작의 그 스테이지 평균값에 맞춰 정한다(Stage/Runner.lua).

local _, WIH = ...
local Stats = WIH.module("Stats")
local Monsters = WIH.module("Monsters")

local F, I, M = Stats.FLAT, Stats.INC, Stats.MORE

Monsters.defs = {}

-- 기본형: {체력, 공격력, 공격속도(×100), 이동속도, 사거리, 골드, 경험치}
local ARCHETYPES = {
    grunt   = { 65, 14, 80, 185, 150, 15, 15 },    -- 보통 근접
    soldier = { 95, 16, 75, 165, 170, 20, 20 },    -- 단단한 근접
    brute   = { 185, 17, 65, 120, 250, 35, 35 },   -- 느리고 강한 근접
    tank    = { 260, 17, 80, 80, 150, 30, 30 },    -- 체력이 많은 근접
    fast    = { 45, 10, 110, 280, 170, 15, 15 },   -- 빠르고 약한 근접
    swarm   = { 15, 10, 90, 500, 200, 10, 5 },     -- 떼로 몰려오는 약한 적
    stalker = { 55, 18, 115, 165, 150, 15, 15 },   -- 공격이 빠른 근접
    berserk = { 75, 17, 150, 500, 150, 25, 25 },   -- 돌진형
    caster  = { 30, 11, 70, 135, 800, 20, 20 },    -- 원거리 주문
    archer  = { 35, 15, 80, 150, 900, 10, 13 },    -- 원거리 물리
    boss    = { 185, 17, 80, 150, 250, 35, 35 },   -- 스테이지 보스의 바탕(스테이지의 보스 배율이 곱해진다)
}
Monsters.ARCHETYPES = ARCHETYPES

local function make(id, name, archetype, opts, isBoss)
    assert(not Monsters.defs[id], "몬스터 ID 중복: " .. id)
    local a = ARCHETYPES[archetype]
    assert(a, "알 수 없는 기본형: " .. tostring(archetype))
    opts = opts or {}
    local range = opts.range or a[5]
    local def = {
        id = id, name = name, archetype = archetype, isBoss = isBoss or false,
        hp = opts.hp or a[1], atk = opts.atk or a[2], as = opts.as or a[3], ms = opts.ms or a[4],
        range = range, melee = range <= 300, gold = opts.gold or a[6], exp = opts.exp or a[7],
        elem = opts.elem or "Physical", area = opts.area, npc = opts.npc, display = opts.display,
        skills = opts.skills,
    }
    if def.skills then
        for i, s in ipairs(def.skills) do s.id = id .. "_s" .. i end
    end
    Monsters.defs[id] = def
    return def
end

function Monsters.mob(id, name, archetype, opts) return make(id, name, archetype, opts, false) end
function Monsters.boss(id, name, opts) return make(id, name, "boss", opts, true) end

------------------------------------------------------------------------
-- 보스 패턴. 계수는 보스 공격력 대비 %. 설명문은 스테이지 화면의 보스 정보에 쓴다.
------------------------------------------------------------------------
local P = {}
Monsters.P = P

local ELEM = Stats.ELEMENT_NAMES
local TARGET_TEXT = { nearest = "선두의 영웅", random = "무작위 영웅", farthest = "맨 뒤의 영웅", lowestHpEnemy = "체력 비율이 가장 낮은 영웅" }

-- 선두 강타
function P.smash(name, coef, cd, elem)
    elem = elem or "Physical"
    return { name = name, act = { type = "cd", cd = cd }, target = "nearest", range = 350,
        desc = string.format("%d초마다 선두의 영웅에게 %s 피해 %d%%.", cd, ELEM[elem], coef),
        effects = { { type = "damage", elem = elem, melee = true, coef = coef, noMultistrike = true } } }
end

-- 휩쓸기: 기본 공격 n회마다 대상 주변을 함께 친다
function P.cleave(name, coef, n, elem)
    elem = elem or "Physical"
    return { name = name, act = { type = "count", n = n }, target = "nearest", range = 350,
        desc = string.format("기본 공격 %d회마다 선두 주변의 영웅 모두에게 %s 피해 %d%%.", n, ELEM[elem], coef),
        effects = { { type = "damage", elem = elem, melee = true, coef = coef, area = { r = 220, at = "target" } } } }
end

-- 전원 광역
function P.nova(name, elem, coef, cd)
    return { name = name, act = { type = "cd", cd = cd }, target = "nearest", range = 3000,
        desc = string.format("%d초마다 모든 영웅에게 %s 피해 %d%%.", cd, ELEM[elem], coef),
        effects = { { type = "damage", elem = elem, coef = coef, area = { r = 3000, at = "self" } } } }
end

-- 원거리 저격: rule = "random" | "farthest" | "lowestHpEnemy" | "nearest"
function P.bolt(name, elem, coef, cd, rule)
    rule = rule or "random"
    return { name = name, act = { type = "cd", cd = cd }, target = rule, range = 2000,
        desc = string.format("%d초마다 %s에게 %s 피해 %d%%.", cd, TARGET_TEXT[rule], ELEM[elem], coef),
        effects = { { type = "damage", elem = elem, proj = true, coef = coef, noMultistrike = true } } }
end

-- 지속 피해 부여
function P.dot(name, elem, coefPerSec, dur, cd, rule)
    rule = rule or "random"
    return { name = name, act = { type = "cd", cd = cd }, target = rule, range = 2000,
        desc = string.format("%d초마다 %s에게 %d초 동안 초당 %s 피해 %d%%.", cd, TARGET_TEXT[rule], dur, ELEM[elem], coefPerSec),
        effects = { { type = "dot", elem = elem, coef = coefPerSec, dur = dur } } }
end

-- 상태 이상. areaR가 있으면 선두 주변, 없으면 대상 하나
local STATUS_TEXT = { Chill = "냉각", Freeze = "빙결", Ignite = "점화", Shock = "감전", Bleed = "출혈", Stun = "기절" }
function P.status(name, status, cd, coef, areaR, elem, rule)
    elem = elem or "Physical"
    rule = rule or "nearest"
    local dmg = { type = "damage", elem = elem, coef = coef or 100, noMultistrike = true,
        apply = { { type = "status", status = status } } }
    if areaR then dmg.area = { r = areaR, at = "target" } end
    return { name = name, act = { type = "cd", cd = cd }, target = rule, range = 2000,
        desc = string.format("%d초마다 %s%s에게 %s 피해 %d%%를 주고 %s 상태로 만든다.", cd, TARGET_TEXT[rule],
            areaR and " 주변" or "", ELEM[elem], coef or 100, STATUS_TEXT[status]),
        effects = { dmg } }
end

-- 체력 비율 격노(한 번)
function P.enrage(name, hpBelow, atkMore, asMore)
    local mods = { { "AttackDamage", M, atkMore * 10 } }
    if asMore then mods[#mods + 1] = { "AttackSpeed", M, asMore * 10 } end
    return { name = name, act = { type = "cd", cd = 1 }, target = "self", once = true, cond = { hpBelow = hpBelow },
        desc = string.format("체력이 %d%% 이하가 되면 공격력이 %d%%%s 증가한다.", hpBelow * 100, atkMore,
            asMore and string.format(", 공격속도가 %d%%", asMore) or ""),
        effects = { { type = "buff", who = "self", dur = 3600, mods = mods } } }
end

-- 주기적 광분
function P.frenzy(name, cd, dur, asMore)
    return { name = name, act = { type = "cd", cd = cd }, target = "self",
        desc = string.format("%d초마다 %d초 동안 공격속도가 %d%% 증가한다.", cd, dur, asMore),
        effects = { { type = "buff", who = "self", dur = dur, mods = { { "AttackSpeed", M, asMore * 10 } } } } }
end

-- 부하 소환
function P.adds(name, cd, count, unitName, hpPct, coef, interval, ranged)
    local effects = {}
    for i = 1, count do
        effects[i] = { type = "summon", unit = { name = unitName, kind = "follower", hpPct = hpPct, interval = interval or 1.2,
            coef = coef, melee = not ranged, range = ranged and 800 or 150, max = count, moveSpeed = 250 } }
    end
    return { name = name, act = { type = "cd", cd = cd }, target = "self",
        desc = string.format("%d초마다 %s %d마리를 부른다.", cd, unitName, count),
        effects = effects }
end

-- 자가 회복
function P.heal(name, pct, cd, hpBelow)
    return { name = name, act = { type = "cd", cd = cd }, target = "self", cond = { hpBelow = hpBelow or 0.7 },
        desc = string.format("체력이 %d%% 이하일 때 %d초마다 최대 체력의 %d%%를 회복한다.", (hpBelow or 0.7) * 100, cd, pct),
        effects = { { type = "heal", who = "self", pct = pct } } }
end

-- 피해 감소 상태
function P.guard(name, cd, dur, dr)
    return { name = name, act = { type = "cd", cd = cd }, target = "self",
        desc = string.format("%d초마다 %d초 동안 받는 피해가 %d%% 감소한다.", cd, dur, dr),
        effects = { { type = "buff", who = "self", dur = dur, mods = { { "DamageReduction", F, dr * 10 } } } } }
end

-- 회복 방해
function P.wound(name, cd, dur, pct, coef)
    return { name = name, act = { type = "cd", cd = cd }, target = "nearest", range = 350,
        desc = string.format("%d초마다 선두의 영웅에게 물리 피해 %d%%를 주고 %d초 동안 받는 회복을 %d%% 줄인다.", cd, coef or 150, dur, pct),
        effects = { { type = "damage", melee = true, coef = coef or 150, noMultistrike = true },
            { type = "debuff", dur = dur, id = "wound", mods = { { "HealingTaken", M, -pct * 10 } } } } }
end

-- 지면 영역
function P.zone(name, elem, coefPerSec, r, dur, cd, rule)
    rule = rule or "random"
    return { name = name, act = { type = "cd", cd = cd }, target = rule, range = 2000,
        desc = string.format("%d초마다 %s의 발밑에 %d초 동안 영역을 만들어 안의 영웅에게 초당 %s 피해 %d%%.", cd, TARGET_TEXT[rule], dur, ELEM[elem], coefPerSec),
        effects = { { type = "zone", r = r, dur = dur, every = 1, at = "target", persist = true,
            enemy = { { type = "damage", elem = elem, coef = coefPerSec, aoe = true } } } } }
end

-- 생명력 흡수
function P.drain(name, elem, coef, cd, rule)
    rule = rule or "random"
    return { name = name, act = { type = "cd", cd = cd }, target = rule, range = 2000,
        desc = string.format("%d초마다 %s에게 %s 피해 %d%%를 주고 준 피해만큼 회복한다.", cd, TARGET_TEXT[rule], ELEM[elem], coef),
        effects = { { type = "damage", elem = elem, coef = coef, leech = 1.0, noMultistrike = true } } }
end

-- 약화: 영웅의 공격력 감소
function P.weaken(name, cd, dur, pct)
    return { name = name, act = { type = "cd", cd = cd }, target = "nearest", range = 3000,
        desc = string.format("%d초마다 %d초 동안 모든 영웅의 공격력을 %d%% 낮춘다.", cd, dur, pct),
        effects = { { type = "debuff", who = "enemies", at = "self", radius = 3000, dur = dur, id = "weaken",
            mods = { { "AttackDamage", M, -pct * 10 } } } } }
end

-- 저주: 받는 피해 증가
function P.curse(name, cd, dur, pct, elem)
    local stat = elem and ("Taken" .. elem) or "TakenAll"
    return { name = name, act = { type = "cd", cd = cd }, target = "nearest", range = 3000,
        desc = string.format("%d초마다 %d초 동안 모든 영웅이 %s 피해를 %d%% 더 받는다.", cd, dur, elem and ELEM[elem] or "모든", pct),
        effects = { { type = "debuff", who = "enemies", at = "self", radius = 3000, dur = dur, id = "curse",
            mods = { { stat, F, pct * 10 } } } } }
end

return Monsters
