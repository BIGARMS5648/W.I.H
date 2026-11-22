-- 스킬 데이터: 도적, 사제, 주술사. 표기 규칙은 Skills_Warrior_Paladin_Hunter.lua 와 같다.

local _, WIH = ...
local Stats = WIH.module("Stats")
local SkillData = WIH.module("SkillData")

local F, I, M = Stats.FLAT, Stats.INC, Stats.MORE
local skill = SkillData.add
local MANY = { enemies = 3, orBoss = true }

------------------------------------------------------------------------
-- 암살 도적
------------------------------------------------------------------------
skill { id = "assa_poisoned_blade", name = "독칼", icon = "Ability_Rogue_DualWeild",
    act = { type = "count", n = 3 }, target = "nearest",
    desc = "물리 피해 {1}%를 주고 맹독을 1중첩 건다. 맹독은 6초 동안 중첩당 초당 암흑 피해 {2}%를 주며 5중첩까지 쌓인다.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 150, 12 } },
        { type = "dot", id = "deadly_poison", elem = "Chaos", coef = { 20, 2 }, dur = 6, maxStacks = 5 } } }
skill { id = "assa_eviscerate", name = "절개", icon = "Ability_Rogue_Eviscerate",
    act = { type = "count", n = 6 }, target = "nearest",
    desc = "물리 피해 {1}%.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 420, 32 } } } }
skill { id = "assa_cold_blood", name = "냉혈", icon = "Spell_Ice_Lament",
    act = { type = "cd", cd = 15 }, target = "self", cond = { enemies = 1 },
    desc = "다음 타격 스킬이 반드시 치명타로 적중하고 치명타 피해가 {1}%p 증가한다.",
    effects = { { type = "buff", who = "self", dur = 15, nextHit = { count = 1, forceCrit = true, skillOnly = true, critDmg = { 30, 5 } } } } }
skill { id = "assa_envenom", name = "독살", icon = "Ability_Rogue_Disembowel",
    act = { type = "cd", cd = 10 }, target = "nearest", range = 200, cond = { targetStacks = { id = "deadly_poison", n = 3 } },
    desc = "대상에게 걸린 맹독 중첩당 암흑 피해 {1}%. 맹독이 3중첩 이상일 때 쓴다.",
    effects = { { type = "damage", elem = "Chaos", melee = true, coef = { 120, 10 }, perStack = { id = "deadly_poison" },
        noMultistrike = true } } }
skill { id = "assa_rupture", name = "파열", icon = "Ability_Rogue_Rupture",
    act = { type = "count", n = 7 }, target = "nearest",
    desc = "물리 피해 {1}%를 주고 출혈을 건다.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 200, 15 } }, { type = "status", status = "Bleed" } } }
skill { id = "assa_fan_of_knives", name = "독 묻은 칼날 부채", icon = "Ability_Rogue_FanofKnives",
    act = { type = "cd", cd = 12 }, target = "nearest", range = 300, cond = { enemies = 2, orBoss = true },
    desc = "자신 주변의 모든 적에게 물리 피해 {1}%를 주고 맹독을 2중첩 건다(중첩당 초당 암흑 피해 {2}%).",
    effects = { { type = "damage", elem = "Physical", coef = { 220, 18 }, area = { r = 300, at = "self" },
        apply = { { type = "dot", id = "deadly_poison", elem = "Chaos", coef = { 20, 2 }, dur = 6, maxStacks = 5, stacks = 2 } } } } }

------------------------------------------------------------------------
-- 전투 도적
------------------------------------------------------------------------
skill { id = "combat_sinister_strike", name = "사악한 일격", icon = "Spell_Shadow_RitualOfSacrifice",
    act = { type = "count", n = 3 }, target = "nearest",
    desc = "물리 피해 {1}%.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 190, 15 } } } }
skill { id = "combat_slice_and_dice", name = "난도질", icon = "Ability_Rogue_SliceDice",
    act = { type = "aura" },
    desc = "자신의 공격속도가 {1}% 증가한다.",
    effects = { { type = "aura", who = "self", mods = { { "AttackSpeed", I, { 150, 20 } } } } } }
skill { id = "combat_blade_flurry", name = "폭풍의 칼날", icon = "Ability_Warrior_PunishingBlow",
    act = { type = "cd", cd = 20 }, target = "self", cond = { enemies = 2, orBoss = true },
    desc = "8초 동안 공격속도가 20% 증가하고, 기본 공격과 근접 스킬이 옆의 적 1명에게 피해의 {1}%를 추가로 준다.",
    effects = { { type = "buff", who = "self", dur = 8, cleave = { 50, 5 }, mods = { { "AttackSpeed", I, 200 } } } } }
skill { id = "combat_eviscerate", name = "절개", icon = "Ability_Rogue_Eviscerate",
    act = { type = "count", n = 6 }, target = "nearest",
    desc = "물리 피해 {1}%.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 400, 30 } } } }
skill { id = "combat_riposte", name = "반격", icon = "Ability_Warrior_Challange",
    act = { type = "aura" },
    desc = "회피에 성공하면 공격자에게 물리 피해 {1}%.",
    effects = { { type = "aura", who = "self", onDodge = {
        { type = "damage", elem = "Physical", melee = true, coef = { 250, 20 }, noMultistrike = true } } } } }
skill { id = "combat_adrenaline_rush", name = "아드레날린 촉진", icon = "Spell_Shadow_ShadowWordDominate",
    act = { type = "cd", cd = 30 }, target = "self", cond = MANY,
    desc = "8초 동안 스킬 발동에 필요한 기본공격 횟수가 1 줄고 재사용 충전 속도가 {1}% 증가한다.",
    effects = { { type = "buff", who = "self", dur = 8,
        mods = { { "CastSpeed", M, { 500, 50 } }, { "BaseAttackCountReduction", F, 1 } } } } }

------------------------------------------------------------------------
-- 잠행 도적
------------------------------------------------------------------------
skill { id = "sub_ambush", name = "기습", icon = "Ability_Rogue_Ambush",
    act = { type = "cd", cd = 8 }, target = "lowestHpEnemy", range = 1200,
    desc = "체력 비율이 가장 낮은 적의 뒤로 이동해 물리 피해 {1}%.",
    effects = { { type = "dash", behind = true }, { type = "damage", elem = "Physical", melee = true, coef = { 380, 30 } } } }
skill { id = "sub_hemorrhage", name = "과다출혈", icon = "Spell_Shadow_LifeDrain",
    act = { type = "count", n = 4 }, target = "nearest",
    desc = "물리 피해 {1}%를 주고, 대상이 6초 동안 물리 피해를 {2}% 더 받는다.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 220, 18 } },
        { type = "debuff", id = "hemorrhage", dur = 6, mods = { { "TakenPhysical", F, { 100, 10 } } } } } }
skill { id = "sub_evasion", name = "회피", icon = "Spell_Shadow_ShadowWard",
    act = { type = "cd", cd = 22 }, target = "self", cond = { hpBelow = 0.6 },
    desc = "6초 동안 회피가 {1}%p 증가한다.",
    effects = { { type = "buff", who = "self", dur = 6, mods = { { "DodgeChance", F, { 400, 30 } } } } } }
skill { id = "sub_vanish", name = "소멸", icon = "Ability_Vanish",
    act = { type = "cd", cd = 20 }, target = "self", cond = { hpBelow = 0.4, orBoss = true },
    desc = "3초 동안 적의 대상에서 벗어난다. 다음 타격은 반드시 치명타로 적중하고 피해가 {1}% 증가한다.",
    effects = { { type = "buff", who = "self", dur = 3, untargetable = true,
        nextHit = { count = 1, forceCrit = true, mult = { 100, 10 } } } } }
skill { id = "sub_kidney_shot", name = "급소 가격", icon = "Ability_Rogue_KidneyShot",
    act = { type = "count", n = 7 }, target = "nearest",
    desc = "물리 피해 {1}%를 주고 기절시킨다.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 250, 20 } }, { type = "status", status = "Stun" } } }
skill { id = "sub_premeditation", name = "계획된 살인", icon = "Spell_Shadow_Possession",
    act = { type = "aura" },
    desc = "체력이 가득 찬 적에게 치명타 확률이 {1}% 증가하고(곱 방식) 피해가 {2}% 증가한다.",
    effects = { { type = "aura", who = "self", cond = { fullHp = true, critMult = { 100, 10 }, mult = { 20, 3 } } } } }

------------------------------------------------------------------------
-- 수양 사제
------------------------------------------------------------------------
skill { id = "disc_shield", name = "신의 권능: 보호막", icon = "Spell_Holy_PowerWordShield",
    act = { type = "cd", cd = 6 }, target = "lowestHpHero", cond = { targetHpBelow = 0.9 },
    desc = "체력 비율이 가장 낮은 아군에게 최대 체력의 {1}%만큼 피해를 흡수하는 보호막을 10초 동안 씌운다.",
    effects = { { type = "shield", pct = { 12, 2 }, dur = 10 } } }
skill { id = "disc_flash_heal", name = "순간 치유", icon = "Spell_Holy_FlashHeal",
    act = { type = "cd", cd = 8 }, target = "lowestHpHero", cond = { targetHpBelow = 0.8 },
    desc = "체력 비율이 가장 낮은 아군을 최대 체력의 {1}%만큼 회복한다.",
    effects = { { type = "heal", pct = { 10, 2 } } } }
skill { id = "disc_fortitude", name = "신의 권능: 인내", icon = "Spell_Holy_WordFortitude",
    act = { type = "aura" },
    desc = "주변 아군의 최대 체력이 {1}% 증가한다.",
    effects = { { type = "aura", who = "allies", radius = 1200, mods = { { "MaxHp", I, { 100, 15 } } } } } }
skill { id = "disc_power_infusion", name = "마력 주입", icon = "Spell_Holy_PowerInfusion",
    act = { type = "cd", cd = 25 }, target = "highestAdAlly", cond = MANY,
    desc = "화력이 가장 높은 아군의 공격속도를 {1}%, 시전속도를 {2}% 8초 동안 높인다.",
    effects = { { type = "buff", who = "target", dur = 8,
        mods = { { "AttackSpeed", I, { 300, 30 } }, { "CastSpeed", I, { 300, 30 } } } } } }
skill { id = "disc_divine_spirit", name = "천상의 정신", icon = "Spell_Holy_DivineSpirit",
    act = { type = "aura" },
    desc = "주변 아군의 재사용 감소가 {1}% 증가한다.",
    effects = { { type = "aura", who = "allies", radius = 1200, mods = { { "CooldownReduction", F, { 40, 10 } } } } } }
skill { id = "disc_resurrection", name = "부활", icon = "Spell_Holy_Resurrection",
    act = { type = "cd", cd = 45 }, target = "deadAlly",
    desc = "쓰러진 아군 1명을 최대 체력의 {1}%로 부활시킨다.",
    effects = { { type = "revive", pct = { 30, 5 } } } }

------------------------------------------------------------------------
-- 신성 사제
------------------------------------------------------------------------
skill { id = "hpri_greater_heal", name = "상급 치유", icon = "Spell_Holy_GreaterHeal",
    act = { type = "cd", cd = 9 }, target = "lowestHpHero", cond = { targetHpBelow = 0.7 },
    desc = "체력 비율이 가장 낮은 아군을 최대 체력의 {1}%만큼 회복한다.",
    effects = { { type = "heal", pct = { 16, 2.5 } } } }
skill { id = "hpri_renew", name = "소생", icon = "Spell_Holy_Renew",
    act = { type = "count", n = 4 }, target = "lowestHpHero", cond = { targetHpBelow = 0.95 },
    desc = "체력 비율이 가장 낮은 아군을 10초 동안 초당 최대 체력의 {1}%씩 회복한다.",
    effects = { { type = "heal", hot = { dur = 10, pct = { 1.2, 0.2 } } } } }
skill { id = "hpri_prayer_of_healing", name = "치유의 기원", icon = "Spell_Holy_PrayerOfHealing02",
    act = { type = "cd", cd = 14 }, target = "self", cond = { alliesBelow = { n = 2, hp = 0.8 } },
    desc = "아군 전원을 각자 최대 체력의 {1}%만큼 회복한다.",
    effects = { { type = "heal", who = "all", pct = { 8, 1.5 } } } }
skill { id = "hpri_lightwell", name = "빛의 샘", icon = "Spell_Holy_SummonLightwell",
    act = { type = "cd", cd = 17 }, target = "lowestHpHero", cond = { targetHpBelow = 0.85 },
    desc = "체력 비율이 가장 낮은 아군의 발밑에 7.5초 동안 빛의 샘을 만든다. 안의 아군은 초당 {1}의 체력을 회복한다.",
    effects = { { type = "zone", r = 400, dur = 7.5, every = 1, at = "target",
        ally = { { type = "heal", flat = { values = { 30, 40, 52, 66, 82, 100, 120, 142, 166, 192 } } } } } } }
skill { id = "hpri_holy_fire", name = "신성한 불꽃", icon = "Spell_Holy_SearingLight",
    act = { type = "count", n = 6 }, target = "nearest", range = 950,
    desc = "번개 피해 {1}%를 주고 6초 동안 초당 번개 피해 {2}%.",
    effects = { { type = "damage", elem = "Lightning", proj = true, coef = { 300, 24 } },
        { type = "dot", elem = "Lightning", coef = { 30, 2.5 }, dur = 6 } } }
skill { id = "hpri_resurrection", name = "부활", icon = "Spell_Holy_Resurrection",
    act = { type = "cd", cd = 45 }, target = "deadAlly",
    desc = "쓰러진 아군 1명을 최대 체력의 {1}%로 부활시킨다.",
    effects = { { type = "revive", pct = { 30, 5 } } } }

------------------------------------------------------------------------
-- 암흑 사제
------------------------------------------------------------------------
skill { id = "shadow_word_pain", name = "어둠의 권능: 고통", icon = "Spell_Shadow_ShadowWordPain",
    act = { type = "count", n = 3 }, target = "nearest", range = 950,
    desc = "10초 동안 초당 암흑 피해 {1}%.",
    effects = { { type = "dot", elem = "Chaos", coef = { 35, 3 }, dur = 10 } } }
skill { id = "shadow_mind_blast", name = "정신 분열", icon = "Spell_Shadow_UnholyFrenzy",
    act = { type = "cd", cd = 8 }, target = "nearest", range = 950,
    desc = "암흑 피해 {1}%.",
    effects = { { type = "damage", elem = "Chaos", coef = { 380, 30 } } } }
skill { id = "shadow_mind_flay", name = "정신의 채찍", icon = "Spell_Shadow_SiphonMana",
    act = { type = "cd", cd = 6 }, target = "nearest", range = 950,
    desc = "3초 동안 정신을 집중해 대상에게 초당 암흑 피해 {1}%를 주고 냉각시킨다.",
    effects = { { type = "channel", dur = 3, every = 1, effects = {
        { type = "damage", elem = "Chaos", coef = { 110, 9 }, noMultistrike = true }, { type = "status", status = "Chill" } } } } }
skill { id = "shadow_vampiric_embrace", name = "흡혈의 선물", icon = "Spell_Shadow_UnsummonBuilding",
    act = { type = "aura" },
    desc = "자신이 준 암흑 피해의 {1}%만큼 아군 전원이 나눠 회복한다.",
    effects = { { type = "aura", who = "self", leech = { pct = { 3, 0.3 }, party = true, elem = "Chaos" } } } }
skill { id = "shadow_shadowform", name = "어둠의 형상", icon = "Spell_Shadow_Shadowform",
    act = { type = "aura" },
    desc = "암흑 피해가 {1}% 증가하고 받는 물리 피해가 {2}% 감소한다.",
    effects = { { type = "aura", who = "self",
        mods = { { "ChaosDamagePercent", F, { 200, 30 } }, { "PhysicalDamageReduction", F, { 100, 10 } } } } } }
skill { id = "shadow_psychic_scream", name = "영혼의 절규", icon = "Spell_Shadow_PsychicScream",
    act = { type = "cd", cd = 18 }, target = "nearest", range = 400,
    desc = "자신 주변의 모든 적에게 암흑 피해 {1}%를 주고 기절시킨다.",
    effects = { { type = "damage", elem = "Chaos", coef = { 200, 15 }, area = { r = 400, at = "self" },
        apply = { { type = "status", status = "Stun" } } } } }

------------------------------------------------------------------------
-- 정기 주술사
------------------------------------------------------------------------
skill { id = "ele_chain_lightning", name = "연쇄 번개", icon = "Spell_Nature_ChainLightning",
    act = { type = "cd", cd = 7 }, target = "nearest", range = 950,
    desc = "번개 피해 {1}%. 가까운 적 3명까지 튀며, 튈 때마다 피해가 25% 줄어든다.",
    effects = { { type = "damage", elem = "Lightning", proj = true, coef = { 260, 20 }, chain = { n = 3, falloff = 0.25 } } } }
skill { id = "ele_flame_shock", name = "불꽃 충격", icon = "Spell_Fire_FlameShock",
    act = { type = "count", n = 5 }, target = "nearest", range = 950,
    desc = "화염 피해 {1}%를 주고 점화시킨다.",
    effects = { { type = "damage", elem = "Fire", coef = { 240, 18 } }, { type = "status", status = "Ignite" } } }
skill { id = "ele_searing_totem", name = "불타는 토템", icon = "Spell_Fire_SearingTotem",
    act = { type = "cd", cd = 12 }, target = "nearest", range = 1100,
    desc = "10초 동안 유지되는 토템을 세운다. 토템은 0.8초마다 화염 피해 {1}%를 준다.",
    effects = { { type = "summon", unit = { name = "불타는 토템", kind = "turret", hpPct = 40, interval = 0.8,
        coef = { 60, 5 }, elem = "Fire", range = 1000, dur = 10, max = 1, model = "totem" } } } }
skill { id = "ele_earth_shock", name = "대지 충격", icon = "Spell_Nature_EarthShock",
    act = { type = "cd", cd = 9 }, target = "nearest", range = 950,
    desc = "번개 피해 {1}%를 주고 감전시킨다.",
    effects = { { type = "damage", elem = "Lightning", coef = { 300, 24 } }, { type = "status", status = "Shock" } } }
skill { id = "ele_mastery", name = "정기의 숙련", icon = "Spell_Nature_WispHeal",
    act = { type = "cd", cd = 25 }, target = "self", cond = MANY,
    desc = "다음 타격 스킬 {1}회가 반드시 치명타로 적중한다.",
    effects = { { type = "buff", who = "self", dur = 25, nextHit = { count = { 3, 0.34 }, forceCrit = true, skillOnly = true } } } }
skill { id = "ele_magma_totem", name = "용암 토템", icon = "Spell_Fire_SelfDestruct",
    act = { type = "cd", cd = 20 }, target = "nearest", range = 500,
    desc = "10초 동안 유지되는 토템을 세운다. 토템은 1초마다 주변의 모든 적에게 화염 피해 {1}%를 준다.",
    effects = { { type = "summon", unit = { name = "용암 토템", kind = "turret", hpPct = 40, interval = 1.0,
        coef = { 70, 6 }, elem = "Fire", range = 300, area = 300, dur = 10, max = 1, model = "totem" } } } }

------------------------------------------------------------------------
-- 고양 주술사
------------------------------------------------------------------------
skill { id = "enh_stormstrike", name = "폭풍의 일격", icon = "Spell_Holy_SealOfMight",
    act = { type = "count", n = 4 }, target = "nearest",
    desc = "물리 피해 {1}%를 주고 감전시킨다.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 300, 24 } }, { type = "status", status = "Shock" } } }
skill { id = "enh_windfury_weapon", name = "질풍의 무기", icon = "Spell_Nature_Cyclone",
    act = { type = "aura" },
    desc = "기본 공격 시 {1}% 확률로 2회 추가 타격한다.",
    effects = { { type = "aura", who = "self", proc = { chance = { 20, 1 },
        effects = { { type = "damage", elem = "Physical", melee = true, coef = 100, hits = 2, noMultistrike = true } } } } } }
skill { id = "enh_earth_shock", name = "대지 충격", icon = "Spell_Nature_EarthShock",
    act = { type = "cd", cd = 8 }, target = "nearest", range = 600,
    desc = "번개 피해 {1}%를 주고 냉각시킨다.",
    effects = { { type = "damage", elem = "Lightning", coef = { 280, 22 } }, { type = "status", status = "Chill" } } }
skill { id = "enh_strength_totem", name = "대지력 토템", icon = "Spell_Nature_EarthBindTotem",
    act = { type = "cd", cd = 20 }, target = "self", cond = { enemies = 1 },
    desc = "12초 동안 토템 주변 아군의 공격력이 {1}% 증가한다(합 방식).",
    effects = { { type = "aura", who = "allies", radius = 800, dur = 12, mods = { { "AttackDamage", I, { 150, 20 } } } } } }
skill { id = "enh_lightning_shield", name = "번개 보호막", icon = "Spell_Nature_LightningShield",
    act = { type = "cd", cd = 15 }, target = "self", cond = { enemies = 1 },
    desc = "10초 동안 공격을 받으면 공격자에게 번개 피해 {1}%를 준다(최대 6회).",
    effects = { { type = "buff", who = "self", dur = 10, reflect = { elem = "Lightning", coef = { 150, 12 }, max = 6 } } } }
skill { id = "enh_windfury_totem", name = "질풍의 토템", icon = "Spell_Nature_Windfury",
    act = { type = "cd", cd = 25 }, target = "self", cond = MANY,
    desc = "12초 동안 주변의 근접 아군이 기본 공격 시 {1}% 확률로 1회 추가 타격한다.",
    effects = { { type = "buff", who = "allies", radius = 800, meleeOnly = true, dur = 12, id = "windfury_totem",
        proc = { chance = { 15, 1 }, effects = { { type = "damage", melee = true, coef = 100, noMultistrike = true } } } } } }

------------------------------------------------------------------------
-- 복원 주술사
------------------------------------------------------------------------
skill { id = "resto_healing_wave", name = "치유의 물결", icon = "Spell_Nature_MagicImmunity",
    act = { type = "cd", cd = 8 }, target = "lowestHpHero", cond = { targetHpBelow = 0.75 },
    desc = "체력 비율이 가장 낮은 아군을 최대 체력의 {1}%만큼 회복한다.",
    effects = { { type = "heal", pct = { 13, 2 } } } }
skill { id = "resto_healing_totem", name = "치유의 토템", icon = "INV_Spear_04",
    act = { type = "cd", cd = 15 }, target = "lowestHpHero", cond = { targetHpBelow = 0.9 },
    desc = "체력 비율이 가장 낮은 아군의 곁에 10초 동안 토템을 세운다. 주변 아군은 초당 최대 체력의 {1}%를 회복한다.",
    effects = { { type = "zone", r = 400, dur = 10, every = 1, at = "target", ally = { { type = "heal", pct = { 0.8, 0.15 } } } } } }
skill { id = "resto_chain_heal", name = "연쇄 치유", icon = "Spell_Nature_HealingWaveGreater",
    act = { type = "cd", cd = 10 }, target = "self", cond = { alliesBelow = { n = 2, hp = 0.85 } },
    desc = "체력 비율이 낮은 순으로 아군 3명을 최대 체력의 {1}%만큼 회복한다. 넘어갈 때마다 회복량이 25% 줄어든다.",
    effects = { { type = "heal", who = "chain", pct = { 9, 1.5 }, chain = { n = 3, falloff = 0.25 } } } }
skill { id = "resto_cleansing_totem", name = "정화의 토템", icon = "Spell_Nature_PoisonCleansingTotem",
    act = { type = "cd", cd = 20 }, target = "self", cond = { enemies = 1 },
    desc = "10초 동안 토템 주변 아군의 상태 이상을 2초마다 하나씩 지우고 모든 원소 저항을 {1} 높인다.",
    effects = { { type = "zone", r = 800, dur = 10, every = 2, at = "self", ally = { { type = "cleanse", who = "target" } } },
        { type = "aura", who = "allies", radius = 800, dur = 10, mods = { { "AllElementalResistance", F, { 10, 2 } } } } } }
skill { id = "resto_natures_swiftness", name = "자연의 신속함", icon = "Spell_Nature_RavenForm",
    act = { type = "cd", cd = 30 }, target = "lowestHpHero", cond = { targetHpBelow = 0.3 },
    desc = "체력이 30% 이하인 아군을 즉시 최대 체력의 {1}%만큼 회복한다.",
    effects = { { type = "heal", pct = { 25, 3 } } } }
skill { id = "resto_ancestral_spirit", name = "고대의 영혼", icon = "Spell_Nature_Regenerate",
    act = { type = "cd", cd = 45 }, target = "deadAlly",
    desc = "쓰러진 아군 1명을 최대 체력의 {1}%로 부활시킨다.",
    effects = { { type = "revive", pct = { 30, 5 } } } }

return SkillData
