-- 스킬 데이터: 마법사, 흑마법사, 드루이드, 땜장이. 표기 규칙은 Skills_Warrior_Paladin_Hunter.lua 와 같다.

local _, WIH = ...
local Stats = WIH.module("Stats")
local SkillData = WIH.module("SkillData")

local F, I, M = Stats.FLAT, Stats.INC, Stats.MORE
local skill = SkillData.add
local MANY = { enemies = 3, orBoss = true }

------------------------------------------------------------------------
-- 비전 마법사
------------------------------------------------------------------------
skill { id = "arcane_missiles", name = "신비한 화살", icon = "Spell_Nature_StarFall",
    act = { type = "cd", cd = 5 }, target = "nearest", range = 950,
    desc = "화살 5발을 연달아 쏘아 각각 번개 피해 {1}%.",
    effects = { { type = "damage", elem = "Lightning", proj = true, coef = { 75, 6 }, hits = 5, noMultistrike = true } } }
skill { id = "arcane_explosion", name = "신비한 폭발", icon = "Spell_Nature_WispSplode",
    act = { type = "cd", cd = 8 }, target = "cluster", range = 950, clusterRadius = 300,
    desc = "적이 가장 많이 모인 곳에 번개 피해 {1}%.",
    effects = { { type = "damage", elem = "Lightning", coef = { 220, 18 }, area = { r = 300, at = "target" } } } }
skill { id = "arcane_intellect", name = "신비한 지능", icon = "Spell_Holy_MagicalSentry",
    act = { type = "aura" },
    desc = "주변 아군의 치명타 확률이 {1}% 증가한다(곱 방식).",
    effects = { { type = "aura", who = "allies", radius = 1200, mods = { { "CriticalChance", I, { 200, 30 } } } } } }
skill { id = "arcane_mana_shield", name = "마나 보호막", icon = "Spell_Shadow_DetectLesserInvisibility",
    act = { type = "cd", cd = 18 }, target = "self", cond = { hpBelow = 0.7 },
    desc = "자신에게 최대 체력의 {1}%만큼 피해를 흡수하는 보호막을 8초 동안 씌운다.",
    effects = { { type = "shield", who = "self", pct = { 20, 3 }, dur = 8 } } }
skill { id = "arcane_presence_of_mind", name = "정신 집중", icon = "Spell_Nature_EnchantArmor",
    act = { type = "cd", cd = { values = { 20, 19, 18, 17, 16, 15, 14, 13, 12, 11 } } }, target = "self", cond = { enemies = 1 },
    desc = "남은 재사용 시간이 가장 긴 자신의 다른 스킬 하나를 즉시 준비한다. 이 스킬의 재사용 시간은 {1}초다.",
    effects = { { type = "refresh" } } }
skill { id = "arcane_power", name = "신비한 마법 강화", icon = "Spell_Nature_Lightning",
    act = { type = "cd", cd = 25 }, target = "self", cond = MANY,
    desc = "8초 동안 주는 피해가 {1}% 증가한다(곱 방식).",
    effects = { { type = "buff", who = "self", dur = 8, mods = { { "DamageDealt", M, { 300, 30 } } } } } }

------------------------------------------------------------------------
-- 화염 마법사
------------------------------------------------------------------------
skill { id = "fire_fireball", name = "화염구", icon = "Spell_Fire_FlameBolt",
    act = { type = "cd", cd = 6 }, target = "nearest", range = 950,
    desc = "화염구를 던져 착탄 지점 주변의 적에게 화염 피해 {1}%.",
    effects = { { type = "damage", elem = "Fire", proj = true, coef = { 270, 25 }, area = { r = 200, at = "target" } } } }
skill { id = "fire_scorch", name = "불태우기", icon = "Spell_Fire_SoulBurn",
    act = { type = "count", n = 4 }, target = "nearest", range = 950,
    desc = "화염 피해 {1}%를 주고, 대상이 6초 동안 화염 피해를 {2}% 더 받는다(최대 3중첩).",
    effects = { { type = "damage", elem = "Fire", coef = { 160, 13 } },
        { type = "debuff", id = "scorch", dur = 6, maxStacks = 3, mods = { { "TakenFire", F, { 50, 5 } } } } } }
skill { id = "fire_flamestrike", name = "화염 폭풍", icon = "Spell_Fire_SelfDestruct",
    act = { type = "cd", cd = 12 }, target = "cluster", range = 1000, clusterRadius = 300, cond = { enemies = 2, orBoss = true },
    desc = "적이 가장 많이 모인 곳을 6초 동안 불태워 안의 적에게 초당 화염 피해 {1}%.",
    effects = { { type = "zone", r = 300, dur = 6, every = 1, at = "target",
        enemy = { { type = "damage", elem = "Fire", coef = { 60, 5 }, aoe = true } } } } }
skill { id = "fire_blast_wave", name = "화염 작렬", icon = "Spell_Holy_Excorcism_02",
    act = { type = "cd", cd = 10 }, target = "nearest", range = 950,
    desc = "대상 주변의 모든 적에게 화염 피해 {1}%를 주고 냉각시킨다.",
    effects = { { type = "damage", elem = "Fire", coef = { 250, 20 }, area = { r = 350, at = "target" },
        apply = { { type = "status", status = "Chill" } } } } }
skill { id = "fire_combustion", name = "발화", icon = "Spell_Fire_SealOfFire",
    act = { type = "cd", cd = 25 }, target = "self", cond = MANY,
    desc = "8초 동안 치명타 확률이 {1}% 증가한다(곱 방식).",
    effects = { { type = "buff", who = "self", dur = 8, mods = { { "CriticalChance", I, { 800, 80 } } } } } }
skill { id = "fire_pyroblast", name = "불덩이 작렬", icon = "Spell_Fire_Fireball02",
    act = { type = "cd", cd = 18 }, target = "highestHpEnemy", range = 1100,
    desc = "체력이 가장 많은 적에게 화염 피해 {1}%를 주고 점화시킨다.",
    effects = { { type = "damage", elem = "Fire", proj = true, coef = { 550, 45 } }, { type = "status", status = "Ignite" } } }

------------------------------------------------------------------------
-- 냉기 마법사
------------------------------------------------------------------------
skill { id = "frost_frostbolt", name = "얼음 화살", icon = "Spell_Frost_FrostBolt02",
    act = { type = "cd", cd = 5 }, target = "nearest", range = 950,
    desc = "냉기 피해 {1}%를 주고 냉각시킨다.",
    effects = { { type = "damage", elem = "Cold", proj = true, coef = { 230, 16 } }, { type = "status", status = "Chill" } } }
skill { id = "frost_cone_of_cold", name = "얼음 회오리", icon = "Spell_Frost_Glacier",
    act = { type = "cd", cd = 8 }, target = "nearest", range = 600,
    desc = "대상 주변의 모든 적에게 냉기 피해 {1}%를 주고 냉각시킨다.",
    effects = { { type = "damage", elem = "Cold", coef = { 180, 14 }, area = { r = 350, at = "target" },
        apply = { { type = "status", status = "Chill" } } } } }
skill { id = "frost_nova", name = "서리 회오리", icon = "Spell_Frost_FrostNova",
    act = { type = "cd", cd = 14 }, target = "nearest", range = 900,
    desc = "가장 가까운 적 주변의 모든 적에게 냉기 피해 {1}%를 주고 빙결시킨다.",
    effects = { { type = "damage", elem = "Cold", coef = { 120, 10 }, area = { r = 300, at = "target" },
        apply = { { type = "status", status = "Freeze" } } } } }
skill { id = "frost_ice_barrier", name = "얼음 보호막", icon = "Spell_Ice_Lament",
    act = { type = "cd", cd = 20 }, target = "self", cond = { hpBelow = 0.8 },
    desc = "자신에게 최대 체력의 {1}%만큼 피해를 흡수하는 보호막을 10초 동안 씌운다. 그동안 자신을 근접 공격한 적은 냉각된다.",
    effects = { { type = "shield", who = "self", pct = { 20, 3 }, dur = 10 },
        { type = "buff", who = "self", dur = 10, onHitStatus = "Chill" } } }
skill { id = "frost_blizzard", name = "눈보라", icon = "Spell_Frost_IceStorm",
    act = { type = "cd", cd = 22 }, target = "cluster", range = 1100, clusterRadius = 350, cond = { enemies = 2, orBoss = true },
    desc = "적이 가장 많이 모인 곳에 5초 동안 눈보라를 일으켜 초당 냉기 피해 {1}%를 주고 냉각시킨다.",
    effects = { { type = "zone", r = 350, dur = 5, every = 1, at = "target",
        enemy = { { type = "damage", elem = "Cold", coef = { 60, 12 }, aoe = true }, { type = "status", status = "Chill" } } } } }
skill { id = "frost_shatter", name = "동파", icon = "Spell_Frost_FrostShock",
    act = { type = "aura" },
    desc = "냉각되거나 빙결된 적에게 치명타 확률이 {1}% 증가하고(곱 방식) 치명타 피해가 {2}%p 증가한다.",
    effects = { { type = "aura", who = "self",
        cond = { statusAny = { "Chill", "Freeze" }, critMult = { 50, 10 }, critDmg = { 20, 2 } } } } }

------------------------------------------------------------------------
-- 고통 흑마법사
------------------------------------------------------------------------
skill { id = "aff_corruption", name = "부패", icon = "Spell_Shadow_AbominationExplosion",
    act = { type = "count", n = 3 }, target = "nearest", range = 950,
    desc = "12초 동안 초당 암흑 피해 {1}%.",
    effects = { { type = "dot", elem = "Chaos", coef = { 30, 2.5 }, dur = 12 } } }
skill { id = "aff_curse_of_agony", name = "고통의 저주", icon = "Spell_Shadow_CurseOfSargeras",
    act = { type = "cd", cd = 8 }, target = "highestHpEnemy", range = 950,
    desc = "체력이 가장 많은 적에게 12초 동안 초당 암흑 피해 {1}%.",
    effects = { { type = "dot", elem = "Chaos", coef = { 55, 4.5 }, dur = 12 } } }
skill { id = "aff_felhunter", name = "지옥사냥개", icon = "Spell_Shadow_SummonFelHunter",
    act = { type = "aura" },
    desc = "지옥사냥개가 함께 싸운다. 1초마다 암흑 피해 {1}%. 체력은 자신의 최대 체력과 같고, 죽으면 20초 뒤 다시 부른다.",
    effects = { { type = "summon", permanent = true, respawn = 20,
        unit = { name = "지옥사냥개", kind = "follower", hpPct = 100, interval = 1.0, coef = { 70, 6 }, elem = "Chaos",
            melee = true, range = 130, moveSpeed = 950, model = "felhunter" } } } }
skill { id = "aff_drain_life", name = "생명력 흡수", icon = "Spell_Shadow_LifeDrain02",
    act = { type = "cd", cd = 10 }, target = "nearest", range = 950,
    desc = "3초 동안 정신을 집중해 대상에게 초당 암흑 피해 {1}%를 주고 준 피해의 절반만큼 회복한다.",
    effects = { { type = "channel", dur = 3, every = 1, effects = {
        { type = "damage", elem = "Chaos", coef = { 100, 8 }, leech = 0.5, noMultistrike = true } } } } }
skill { id = "aff_curse_of_shadow", name = "어둠의 저주", icon = "Spell_Shadow_CurseOfAchimonde",
    act = { type = "cd", cd = 15 }, target = "nearest", range = 950,
    desc = "대상 주변의 적이 8초 동안 암흑 피해를 {1}% 더 받는다.",
    effects = { { type = "debuff", who = "enemies", radius = 300, id = "curse_of_shadow", dur = 8,
        mods = { { "TakenChaos", F, { 150, 15 } } } } } }
skill { id = "aff_siphon_life", name = "생명력 착취", icon = "Spell_Shadow_Requiem",
    act = { type = "aura" },
    desc = "자신의 지속 피해가 준 피해의 {1}%만큼 회복한다. 지속 피해가 평균 {2}% 더 강해진다.",
    effects = { { type = "aura", who = "self", leech = { pct = { 4, 0.4 }, dotOnly = true }, dotDouble = { 10, 1 } } } }

------------------------------------------------------------------------
-- 악마 흑마법사
------------------------------------------------------------------------
skill { id = "demo_voidwalker", name = "보이드워커", icon = "Spell_Shadow_SummonVoidWalker",
    act = { type = "aura" },
    desc = "보이드워커가 자신의 바로 앞에 서서 싸운다. 1.5초마다 암흑 피해 {1}%. 체력은 자신의 최대 체력의 300%이고, 죽으면 20초 뒤 다시 부른다.",
    effects = { { type = "summon", permanent = true, respawn = 20,
        unit = { name = "보이드워커", kind = "follower", hpPct = 300, interval = 1.5, coef = { 60, 5 }, elem = "Chaos",
            melee = true, range = 130, moveSpeed = 900, model = "voidwalker" } } } }
skill { id = "demo_shadow_bolt", name = "어둠의 화살", icon = "Spell_Shadow_ShadowBolt",
    act = { type = "cd", cd = 6 }, target = "nearest", range = 950,
    desc = "암흑 피해 {1}%.",
    effects = { { type = "damage", elem = "Chaos", proj = true, coef = { 300, 24 } } } }
skill { id = "demo_succubus", name = "서큐버스", icon = "Spell_Shadow_SummonSuccubus",
    act = { type = "aura" },
    desc = "서큐버스가 함께 싸운다. 1초마다 암흑 피해 {1}%. 체력은 자신의 최대 체력의 80%이고, 죽으면 20초 뒤 다시 부른다.",
    effects = { { type = "summon", permanent = true, respawn = 20,
        unit = { name = "서큐버스", kind = "follower", hpPct = 80, interval = 1.0, coef = { 110, 9 }, elem = "Chaos",
            melee = true, range = 130, moveSpeed = 1000, model = "succubus" } } } }
skill { id = "demo_empowerment", name = "악마 강화", icon = "Spell_Shadow_PsychicScream",
    act = { type = "cd", cd = 20 }, target = "self", cond = { summons = 1 },
    desc = "8초 동안 자신의 악마 전체의 피해가 {1}% 증가하고 공격속도가 30% 증가한다.",
    effects = { { type = "buff", who = "summons", dur = 8,
        mods = { { "DamageDealt", M, { 600, 60 } }, { "AttackSpeed", M, 300 } } } } }
skill { id = "demo_soul_link", name = "영혼의 고리", icon = "Spell_Shadow_GatherShadows",
    act = { type = "aura" },
    desc = "자신이 받는 피해의 {1}%를 살아 있는 악마가 대신 받는다. 자신이 주는 피해가 {2}% 증가한다.",
    effects = { { type = "aura", who = "self", redirect = { mode = "toSummon", pct = { 25, 2 } },
        mods = { { "DamageDealt", M, { 80, 10 } } } } } }
skill { id = "demo_infernal", name = "지옥불정령", icon = "Spell_Shadow_SummonInfernal",
    act = { type = "cd", cd = 40 }, target = "cluster", range = 1000, clusterRadius = 300, cond = MANY,
    desc = "지옥불정령이 적 한가운데 떨어져 주변에 화염 피해 {1}%를 준다. 12초 동안 남아 1.5초마다 주변에 화염 피해 {2}%를 준다.",
    effects = { { type = "damage", elem = "Fire", coef = { 400, 30 }, area = { r = 300, at = "target" } },
        { type = "summon", atTarget = true,
            unit = { name = "지옥불정령", kind = "follower", hpPct = 200, interval = 1.5, coef = { 120, 10 }, elem = "Fire",
                melee = true, range = 200, area = 250, dur = 12, max = 1, moveSpeed = 800, model = "infernal" } } } }

------------------------------------------------------------------------
-- 파괴 흑마법사
------------------------------------------------------------------------
skill { id = "destro_immolate", name = "제물", icon = "Spell_Fire_Immolation",
    act = { type = "count", n = 5 }, target = "nearest", range = 950,
    desc = "화염 피해 {1}%를 주고 점화시킨다.",
    effects = { { type = "damage", elem = "Fire", coef = { 200, 16 } }, { type = "status", status = "Ignite" } } }
skill { id = "destro_imp", name = "임프", icon = "Spell_Shadow_SummonImp",
    act = { type = "aura" },
    desc = "임프가 뒤에서 화염구를 던진다. 1.2초마다 화염 피해 {1}%. 체력은 자신의 최대 체력의 60%이고, 죽으면 20초 뒤 다시 부른다.",
    effects = { { type = "summon", permanent = true, respawn = 20,
        unit = { name = "임프", kind = "follower", hpPct = 60, interval = 1.2, coef = { 80, 7 }, elem = "Fire",
            melee = false, range = 850, moveSpeed = 850, behind = true, model = "imp" } } } }
skill { id = "destro_conflagrate", name = "점화 폭발", icon = "Spell_Fire_Fireball",
    act = { type = "cd", cd = 10 }, target = "nearest", range = 950,
    desc = "화염 피해 {1}%. 대상이 점화 상태면 피해가 50% 증가한다.",
    effects = { { type = "damage", elem = "Fire", coef = { 420, 32 }, bonusIf = { status = "Ignite", mult = 1.5 } } } }
skill { id = "destro_rain_of_fire", name = "불의 비", icon = "Spell_Shadow_RainOfFire",
    act = { type = "cd", cd = 14 }, target = "cluster", range = 1000, clusterRadius = 300, cond = { enemies = 2, orBoss = true },
    desc = "적이 가장 많이 모인 곳에 6초 동안 불의 비를 내려 초당 화염 피해 {1}%.",
    effects = { { type = "zone", r = 300, dur = 6, every = 1, at = "target",
        enemy = { { type = "damage", elem = "Fire", coef = { 65, 5 }, aoe = true } } } } }
skill { id = "destro_shadowburn", name = "어둠의 연소", icon = "Spell_Shadow_ScourgeBuild",
    act = { type = "cd", cd = 12 }, target = "lowestHpEnemy", range = 950,
    desc = "체력 비율이 가장 낮은 적에게 암흑 피해 {1}%. 이 스킬로 적을 처치하면 즉시 다시 준비된다.",
    effects = { { type = "damage", elem = "Chaos", coef = { 380, 30 }, resetOnKill = true } } }
skill { id = "destro_soul_fire", name = "영혼의 불꽃", icon = "Spell_Fire_Fireball02",
    act = { type = "cd", cd = 18 }, target = "highestHpEnemy", range = 1100,
    desc = "체력이 가장 많은 적에게 화염 피해 {1}%.",
    effects = { { type = "damage", elem = "Fire", proj = true, coef = { 600, 48 } } } }

------------------------------------------------------------------------
-- 조화 드루이드
------------------------------------------------------------------------
skill { id = "bal_moonfire", name = "달빛 섬광", icon = "Spell_Nature_StarFall",
    act = { type = "count", n = 4 }, target = "nearest", range = 950,
    desc = "번개 피해 {1}%를 주고 9초 동안 초당 번개 피해 {2}%.",
    effects = { { type = "damage", elem = "Lightning", coef = { 180, 14 } },
        { type = "dot", elem = "Lightning", coef = { 30, 2.5 }, dur = 9 } } }
skill { id = "bal_starfire", name = "별빛 화살", icon = "Spell_Arcane_StarFire",
    act = { type = "cd", cd = 8 }, target = "nearest", range = 950,
    desc = "번개 피해 {1}%.",
    effects = { { type = "damage", elem = "Lightning", proj = true, coef = { 400, 32 } } } }
skill { id = "bal_insect_swarm", name = "곤충 떼", icon = "Spell_Nature_InsectSwarm",
    act = { type = "cd", cd = 10 }, target = "highestHpEnemy", range = 950,
    desc = "체력이 가장 많은 적에게 12초 동안 초당 암흑 피해 {1}%를 주고, 그동안 대상이 주는 피해를 {2}% 낮춘다.",
    effects = { { type = "dot", elem = "Chaos", coef = { 40, 3 }, dur = 12 },
        { type = "debuff", id = "insect_swarm", dur = 12, mods = { { "DamageDealt", M, { -80, -5 } } } } } }
skill { id = "bal_entangling_roots", name = "휘감는 뿌리", icon = "Spell_Nature_StrangleVines",
    act = { type = "cd", cd = 12 }, target = "highestHpEnemy", range = 950,
    desc = "체력이 가장 많은 적에게 번개 피해 {1}%를 주고 빙결시킨다.",
    effects = { { type = "damage", elem = "Lightning", coef = { 150, 12 } }, { type = "status", status = "Freeze" } } }
skill { id = "bal_hurricane", name = "허리케인", icon = "Spell_Nature_Cyclone",
    act = { type = "cd", cd = 18 }, target = "cluster", range = 1000, clusterRadius = 350, cond = { enemies = 2, orBoss = true },
    desc = "적이 가장 많이 모인 곳에 6초 동안 폭풍을 일으켜 초당 번개 피해 {1}%를 주고 냉각시킨다.",
    effects = { { type = "zone", r = 350, dur = 6, every = 1, at = "target",
        enemy = { { type = "damage", elem = "Lightning", coef = { 55, 5 }, aoe = true }, { type = "status", status = "Chill" } } } } }
skill { id = "bal_moonkin_form", name = "달빛야수 형상", icon = "Spell_Nature_ForceOfNature",
    act = { type = "aura" },
    desc = "주변 아군의 치명타 확률이 {1}% 증가한다(곱 방식). 자신의 방어도가 100% 증가하고 번개 피해가 {2}% 증가한다.",
    effects = { { type = "aura", who = "allies", radius = 1200, mods = { { "CriticalChance", I, { 200, 30 } } } },
        { type = "aura", who = "self", mods = { { "LightningDamagePercent", F, { 100, 15 } }, { "Armor", I, 1000 } } } } }

------------------------------------------------------------------------
-- 야성 드루이드: 형태(곰 / 표범)에 따라 같은 칸의 스킬이 다르게 작동한다.
------------------------------------------------------------------------
skill { id = "feral_maul_claw", forms = {
    bear = { name = "후려치기", icon = "Ability_Druid_Maul", act = { type = "count", n = 5 }, target = "nearest",
        desc = "물리 피해 {1}%를 주고 4초 동안 대상의 공격력을 10% 낮춘다.",
        effects = { { type = "damage", elem = "Physical", melee = true, coef = { 260, 20 } },
            { type = "debuff", id = "maul", dur = 4, mods = { { "AttackDamage", M, -100 } } } } },
    cat = { name = "갈퀴 발톱", icon = "Ability_Druid_Rake", act = { type = "count", n = 3 }, target = "nearest",
        desc = "물리 피해 {1}%.",
        effects = { { type = "damage", elem = "Physical", melee = true, coef = { 180, 14 } } } },
} }
skill { id = "feral_swipe_rake", forms = {
    bear = { name = "휘둘러치기", icon = "INV_Misc_MonsterClaw_03", act = { type = "cd", cd = 7 }, target = "nearest", range = 250,
        desc = "자신 주변의 모든 적에게 물리 피해 {1}%.",
        effects = { { type = "damage", elem = "Physical", melee = true, coef = { 170, 14 }, area = { r = 250, at = "self" } } } },
    cat = { name = "갈퀴 찢기", icon = "Ability_Druid_Disembowel", act = { type = "count", n = 5 }, target = "nearest",
        desc = "물리 피해 {1}%를 주고 출혈을 건다.",
        effects = { { type = "damage", elem = "Physical", melee = true, coef = { 150, 12 } }, { type = "status", status = "Bleed" } } },
} }
skill { id = "feral_regen_fury", forms = {
    bear = { name = "광포한 재생", icon = "Ability_BullRush", act = { type = "cd", cd = 20 }, target = "self", cond = { hpBelow = 0.6 },
        desc = "6초 동안 초당 최대 체력의 {1}%를 회복한다.",
        effects = { { type = "heal", who = "self", hot = { dur = 6, pct = { 3, 0.4 } } } } },
    cat = { name = "호랑이의 분노", icon = "Ability_Mount_JungleTiger", act = { type = "cd", cd = 18 }, target = "self", cond = { enemies = 1 },
        desc = "6초 동안 공격력이 {1}% 증가한다(합 방식).",
        effects = { { type = "buff", who = "self", dur = 6, mods = { { "AttackDamage", I, { 300, 40 } } } } } },
} }
skill { id = "feral_roar_bite", forms = {
    bear = { name = "사기의 포효", icon = "Ability_Druid_DemoralizingRoar", act = { type = "cd", cd = 15 }, target = "nearest", range = 400,
        desc = "자신 주변 적의 공격력을 8초 동안 {1}% 낮춘다.",
        effects = { { type = "debuff", who = "enemies", at = "self", radius = 400, id = "demo_roar", dur = 8,
            mods = { { "AttackDamage", M, { -150, -15 } } } } } },
    cat = { name = "흉포한 이빨", icon = "Ability_Druid_FerociousBite", act = { type = "count", n = 8 }, target = "nearest",
        desc = "물리 피해 {1}%. 대상이 출혈 중이면 피해가 30% 증가한다.",
        effects = { { type = "damage", elem = "Physical", melee = true, coef = { 480, 38 }, bonusIf = { status = "Bleed", mult = 1.3 } } } },
} }
skill { id = "feral_mark_of_the_wild", name = "야생의 징표", icon = "Spell_Nature_Regeneration",
    act = { type = "aura" },
    desc = "주변 아군의 방어도가 {1}% 증가하고 모든 원소 저항이 {2} 증가한다.",
    effects = { { type = "aura", who = "allies", radius = 1200,
        mods = { { "Armor", I, { 100, 15 } }, { "AllElementalResistance", F, { 5, 1 } } } } } }
skill { id = "feral_survival_instincts", forms = {
    bear = { name = "생존 본능", icon = "Ability_Druid_TigersRoar", act = { type = "cd", cd = 40 }, target = "self", cond = { hpBelow = 0.4 },
        desc = "8초 동안 최대 체력이 {1}% 증가하고 최대 체력의 {2}%를 회복한다.",
        effects = { { type = "buff", who = "self", dur = 8, mods = { { "MaxHp", M, { 300, 30 } } } },
            { type = "heal", who = "self", pct = { 23, 1.7 } } } },
    cat = { name = "생존 본능", icon = "Ability_Druid_TigersRoar", act = { type = "cd", cd = 40 }, target = "self", cond = { hpBelow = 0.35 },
        desc = "6초 동안 곰으로 변신해 받는 피해가 {1}% 감소한다.",
        effects = { { type = "buff", who = "self", dur = 6, mods = { { "DamageReduction", F, { 400, 20 } } } } } },
} }

------------------------------------------------------------------------
-- 회복 드루이드
------------------------------------------------------------------------
skill { id = "rdru_rejuvenation", name = "회복", icon = "Spell_Nature_Rejuvenation",
    act = { type = "count", n = 3 }, target = "lowestHpHero",
    targetFilter = function(_, u, o) return o:findEffect("hot:rdru_rejuvenation", u) == nil end,
    desc = "이 효과가 없는 아군 중 체력 비율이 가장 낮은 1명을 12초 동안 초당 최대 체력의 {1}%씩 회복한다.",
    effects = { { type = "heal", hot = { dur = 12, pct = { 1.0, 0.15 } } } } }
skill { id = "rdru_healing_touch", name = "치유의 손길", icon = "Spell_Nature_HealingTouch",
    act = { type = "cd", cd = 9 }, target = "lowestHpHero", cond = { targetHpBelow = 0.65 },
    desc = "체력 비율이 가장 낮은 아군을 최대 체력의 {1}%만큼 회복한다.",
    effects = { { type = "heal", pct = { 15, 2.5 } } } }
skill { id = "rdru_regrowth", name = "재생", icon = "Spell_Nature_ResistNature",
    act = { type = "cd", cd = 7 }, target = "lowestHpHero", cond = { targetHpBelow = 0.85 },
    desc = "체력 비율이 가장 낮은 아군을 즉시 최대 체력의 {1}%만큼 회복하고 9초 동안 초당 {2}%씩 더 회복한다.",
    effects = { { type = "heal", pct = { 6, 1 }, hot = { dur = 9, pct = { 0.8, 0.1 } } } } }
skill { id = "rdru_swiftmend", name = "신속한 치유", icon = "INV_Relics_IdolofRejuvenation",
    act = { type = "cd", cd = 12 }, target = "lowestHpHero", cond = { targetHpBelow = 0.6 },
    targetFilter = function(_, u, o)
        return o:findEffect("hot:rdru_rejuvenation", u) ~= nil or o:findEffect("hot:rdru_regrowth", u) ~= nil
    end,
    desc = "지속 회복이 걸린 아군 중 체력 비율이 가장 낮은 1명을 즉시 최대 체력의 {1}%만큼 회복한다.",
    effects = { { type = "heal", pct = { 12, 2 } } } }
skill { id = "rdru_tranquility", name = "평온", icon = "Spell_Nature_Tranquility",
    act = { type = "cd", cd = 30 }, target = "self", cond = { avgHpBelow = 0.6 },
    desc = "5초 동안 정신을 집중해 아군 전원을 초당 최대 체력의 {1}%씩 회복한다.",
    effects = { { type = "channel", dur = 5, every = 1, ally = { { type = "heal", who = "all", pct = { 3, 0.4 } } } } } }
skill { id = "rdru_rebirth", name = "환생", icon = "Spell_Nature_Reincarnation",
    act = { type = "cd", cd = 45 }, target = "deadAlly",
    desc = "쓰러진 아군 1명을 최대 체력의 {1}%로 부활시킨다.",
    effects = { { type = "revive", pct = { 30, 5 } } } }

------------------------------------------------------------------------
-- 기갑 땜장이
------------------------------------------------------------------------
skill { id = "armor_suit", name = "기계 슈트", icon = "INV_Gizmo_02",
    act = { type = "aura" },
    desc = "기계 슈트에 탑승한다. 슈트의 내구도는 최대 체력의 {1}%이고 받는 피해를 먼저 흡수한다. 탑승 중 방어도가 30% 증가한다. 내구도가 0이 되면 슈트가 파손되어 20초 뒤 다시 탑승한다.",
    effects = { { type = "aura", who = "self", special = "suit", pct = { 40, 4 }, remount = 20,
        mods = { { "Armor", I, 300 } } } } }
skill { id = "armor_hydraulic_slam", name = "유압 충격", icon = "INV_Gauntlets_31",
    act = { type = "count", n = 5 }, target = "nearest",
    desc = "대상 주변의 모든 적에게 물리 피해 {1}%를 주고 냉각시킨다.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 220, 18 }, area = { r = 250, at = "target" },
        apply = { { type = "status", status = "Chill" } } } } }
skill { id = "armor_emergency_repair", name = "긴급 수리", icon = "INV_Misc_Wrench_01",
    act = { type = "cd", cd = 15 }, target = "self",
    cond = { custom = function(_, u) return u.suit == nil or u.suit.amount <= u.suit.maxAmount * 0.6 end },
    desc = "슈트의 내구도를 {1}% 복구한다. 슈트가 파손된 상태면 즉시 다시 탑승한다(내구도 50%).",
    effects = { { type = "special", name = "suitRepair", pct = { 30, 3 }, remountRatio = 0.5 } } }
skill { id = "armor_steel_barrier", name = "강철 방벽", icon = "INV_Shield_10",
    act = { type = "cd", cd = 20 }, target = "self", cond = { enemies = 1 },
    desc = "자신의 발밑에 10초 동안 방벽을 편다. 안의 아군이 받는 타격마다 피해 {1}을 흡수한다.",
    effects = { { type = "zone", r = 300, dur = 10, every = 1, at = "self", absorb = { 50, 15 } } } }
skill { id = "armor_interceptor", name = "요격 장치", icon = "INV_Misc_EngGizmos_17",
    act = { type = "aura" },
    desc = "주변 아군이 받는 원거리 공격 피해의 {1}%를 슈트가 대신 받는다.",
    effects = { { type = "aura", radius = 800, redirect = { mode = "ranged", pct = { 30, 3 } } } } }
skill { id = "armor_overload", name = "과부하 방어 시스템", icon = "Spell_Nature_LightningOverload",
    act = { type = "cd", cd = 40 }, target = "self",
    cond = { custom = function(_, u) return u.suit == nil or u:hpRatio() <= 0.5 end },
    desc = "6초 동안 피해 감소가 {1}% 증가하고, 공격을 받으면 공격자에게 번개 피해 {2}%를 준다.",
    effects = { { type = "buff", who = "self", dur = 6, mods = { { "DamageReduction", F, { 300, 20 } } },
        reflect = { elem = "Lightning", coef = { 100, 10 } } } } }

------------------------------------------------------------------------
-- 섬멸 땜장이
------------------------------------------------------------------------
skill { id = "destroy_autocannon", name = "자동기관포", icon = "INV_Weapon_Rifle_07",
    act = { type = "cd", cd = 10 }, target = "nearest", range = 1200,
    desc = "12초 동안 유지되는 포탑을 설치한다(최대 2기). 포탑은 0.5초마다 물리 피해 {1}%를 준다. 포탑의 체력은 자신의 최대 체력의 60%다.",
    effects = { { type = "summon", unit = { name = "자동기관포", kind = "turret", hpPct = 60, interval = 0.5,
        coef = { 55, 5 }, elem = "Physical", range = 1000, dur = 12, max = 2, model = "turret" } } } }
skill { id = "destroy_bomb", name = "폭탄 투척", icon = "INV_Misc_Bomb_05",
    act = { type = "count", n = 5 }, target = "nearest", range = 1000,
    desc = "대상 주변의 모든 적에게 화염 피해 {1}%. 자신의 포탑과 로봇도 각자 가장 가까운 적에게 폭탄({2}%의 절반 위력)을 던진다.",
    effects = { { type = "damage", elem = "Fire", coef = { 260, 20 }, area = { r = 250, at = "target" } },
        { type = "special", name = "bombEcho", coef = { 260, 20 }, pct = 0.5, r = 250, elem = "Fire" } } }
skill { id = "destroy_flame_turret", name = "화염 포탑", icon = "INV_Misc_EngGizmos_03",
    act = { type = "cd", cd = 14 }, target = "nearest", range = 500,
    desc = "12초 동안 유지되는 화염 포탑을 설치한다. 1.5초마다 주변의 모든 적에게 화염 피해 {1}%를 주고 점화시킨다.",
    effects = { { type = "summon", unit = { name = "화염 포탑", kind = "turret", hpPct = 60, interval = 1.5,
        coef = { 110, 9 }, elem = "Fire", range = 350, area = 300, status = "Ignite", dur = 12, max = 1, model = "flameturret" } } } }
skill { id = "destroy_battle_robot", name = "전투 로봇", icon = "INV_Gizmo_08",
    act = { type = "cd", cd = 20 }, target = "nearest", range = 1200,
    desc = "15초 동안 싸우는 전투 로봇을 출격시킨다. 1초마다 물리 피해 {1}%. 로봇의 체력은 자신의 최대 체력의 150%다.",
    effects = { { type = "summon", unit = { name = "전투 로봇", kind = "follower", hpPct = 150, interval = 1.0,
        coef = { 130, 10 }, elem = "Physical", melee = true, range = 130, dur = 15, max = 1, moveSpeed = 950, model = "robot" } } } }
skill { id = "destroy_focus_fire", name = "집중 사격 명령", icon = "Ability_Hunter_SniperShot",
    act = { type = "cd", cd = 12 }, target = "highestHpEnemy", range = 1200, cond = { summons = 2, orBoss = true },
    desc = "6초 동안 자신의 모든 포탑과 로봇이 체력이 가장 많은 적을 공격하고 주는 피해가 {1}% 증가한다.",
    effects = { { type = "buff", who = "summons", dur = 6, focus = true, mods = { { "DamageDealt", M, { 400, 40 } } } } } }
skill { id = "destroy_overcharge", name = "과충전 명령", icon = "Spell_Nature_LightningOverload",
    act = { type = "cd", cd = 18 }, target = "self", cond = { summons = 2 },
    desc = "6초 동안 자신의 모든 포탑과 로봇의 공격속도가 {1}% 증가하고 남은 지속시간이 3초 늘어난다.",
    effects = { { type = "buff", who = "summons", dur = 6, extend = 3, mods = { { "AttackSpeed", M, { 600, 60 } } } } } }

------------------------------------------------------------------------
-- 치료 땜장이
------------------------------------------------------------------------
skill { id = "medic_drone", name = "응급 치료 드론", icon = "INV_Gizmo_GoblinBoomBox_01",
    act = { type = "aura" },
    desc = "치료 드론 1기가 따라다닌다. 2초마다 체력이 90% 이하인 아군 중 비율이 가장 낮은 1명을 최대 체력의 {1}%만큼 회복한다. 대상의 체력이 35% 이하면 1초마다 작동한다.",
    effects = { { type = "aura", who = "self", special = "drone", pct = { 3, 0.5 }, every = 2, fastEvery = 1,
        below = 0.9, fastBelow = 0.35 } } }
skill { id = "medic_nano", name = "재생 나노 장치", icon = "INV_Misc_EngGizmos_20",
    act = { type = "count", n = 4 }, target = "lowestHpHero", cond = { targetHpBelow = 0.95 },
    desc = "체력 비율이 가장 낮은 아군을 8초 동안 초당 최대 체력의 {1}%씩 회복한다.",
    effects = { { type = "heal", hot = { dur = 8, pct = { 1.0, 0.15 } } } } }
skill { id = "medic_station", name = "자동 의료 기지", icon = "INV_Misc_EngGizmos_15",
    act = { type = "cd", cd = 18 }, target = "lowestHpHero", cond = { targetHpBelow = 0.8 },
    desc = "체력 비율이 가장 낮은 아군의 곁에 8초 동안 의료 기지를 세운다. 주변 아군은 초당 최대 체력의 {1}%를 회복한다.",
    effects = { { type = "zone", r = 400, dur = 8, every = 1, at = "target", ally = { { type = "heal", pct = { 2, 0.3 } } } } } }
skill { id = "medic_wave", name = "광역 치유 파동", icon = "Spell_Holy_HolyNova",
    act = { type = "cd", cd = 14 }, target = "self", cond = { alliesBelow = { n = 2, hp = 0.8 } },
    desc = "아군 전원을 각자 최대 체력의 {1}%만큼 회복한다.",
    effects = { { type = "heal", who = "all", pct = { 7, 1.2 } } } }
skill { id = "medic_life_support", name = "생명 유지 시스템", icon = "INV_Misc_EngGizmos_27",
    act = { type = "aura" },
    desc = "아군이 죽을 피해를 받으면 체력 1로 버티고 3초 동안 최대 체력의 {1}%만큼 보호막을 얻는다. 아군마다 스테이지당 1회.",
    effects = { { type = "aura", who = "self", lethal = { party = true, shieldPct = { 15, 2 }, shieldDur = 3 } } } }
skill { id = "medic_revive_protocol", name = "긴급 소생 프로토콜", icon = "Spell_Holy_Resurrection",
    act = { type = "cd", cd = 50 }, target = "deadAlly",
    desc = "쓰러진 아군 전원을 최대 체력의 {1}%로 부활시킨다.",
    effects = { { type = "revive", all = true, pct = { 20, 4 } } } }

return SkillData
