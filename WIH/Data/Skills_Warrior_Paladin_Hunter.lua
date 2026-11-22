-- 스킬 데이터: 전사, 성기사, 사냥꾼.
-- act   : {type = "count", n} 기본공격 n회마다 / {type = "cd", cd} 재사용 초 / {type = "aura"} 상시
-- 값    : 숫자 또는 {레벨 1 값, 레벨당 증가}. 피해 계수는 공격력의 %, 치유·보호막은 대상 최대 체력의 %
-- 수정치: {능력치, 연산, 값}. Increased와 More는 퍼밀(1000 = 100%)
-- 효과 종류와 인자는 Combat/Skills.lua 를 본다.

local _, WIH = ...
local Stats = WIH.module("Stats")
local SkillData = WIH.module("SkillData")

local F, I, M = Stats.FLAT, Stats.INC, Stats.MORE
SkillData.defs = SkillData.defs or {}
local defs = SkillData.defs

local function skill(def)
    assert(not defs[def.id], "스킬 ID 중복: " .. tostring(def.id))
    defs[def.id] = def
end
SkillData.add = skill

local MANY = { enemies = 3, orBoss = true }   -- 보스가 있거나 적이 3명 이상일 때

------------------------------------------------------------------------
-- 무기 전사
------------------------------------------------------------------------
skill { id = "arms_mortal_strike", name = "필사의 일격", icon = "Ability_Warrior_SavageBlow",
    act = { type = "count", n = 4 }, target = "nearest",
    desc = "물리 피해 {1}%.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 560, 40 } } } }
skill { id = "arms_charge", name = "돌진", icon = "Ability_Warrior_Charge",
    act = { type = "cd", cd = 8 }, target = "nearest", range = 900,
    desc = "대상에게 돌진해 물리 피해 {1}%를 주고 기절시킨다.",
    effects = { { type = "dash" }, { type = "damage", elem = "Physical", melee = true, coef = { 300, 25 } },
        { type = "status", status = "Stun" } } }
skill { id = "arms_rend", name = "분쇄", icon = "Ability_Gouge",
    act = { type = "count", n = 5 }, target = "nearest",
    desc = "물리 피해 {1}%를 주고 출혈을 건다.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 150, 15 } }, { type = "status", status = "Bleed" } } }
skill { id = "arms_sweeping", name = "휩쓸기 일격", icon = "Ability_Rogue_SliceDice",
    act = { type = "cd", cd = 20 }, target = "self", cond = { enemies = 2 },
    desc = "8초 동안 기본 공격과 근접 스킬이 대상 옆의 적 1명에게 피해의 {1}%를 추가로 준다.",
    effects = { { type = "buff", who = "self", dur = 8, cleave = { 60, 5 } } } }
skill { id = "arms_overpower", name = "제압", icon = "Ability_MeleeDamage",
    act = { type = "count", n = 7 }, target = "nearest",
    desc = "물리 피해 {1}%. 반드시 치명타로 적중한다.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 450, 35 }, forceCrit = true } } }
skill { id = "arms_execute", name = "마무리 일격", icon = "INV_Sword_48",
    act = { type = "cd", cd = 10 }, target = "lowestHpEnemy", range = 300, cond = { targetHpBelow = 0.5 },
    desc = "체력 비율이 가장 낮은 적에게 물리 피해 {1}%. 대상이 잃은 체력 비율만큼 피해가 늘어 최대 2배가 된다.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 400, 30 }, execute = 1.0 } } }

------------------------------------------------------------------------
-- 분노 전사
------------------------------------------------------------------------
skill { id = "fury_bloodthirst", name = "피의 갈증", icon = "Spell_Nature_BloodLust",
    act = { type = "count", n = 4 }, target = "nearest",
    desc = "물리 피해 {1}%를 주고 준 피해의 20%만큼 회복한다.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 280, 22 }, leech = 0.2 } } }
skill { id = "fury_whirlwind", name = "소용돌이", icon = "Ability_Whirlwind",
    act = { type = "cd", cd = 7 }, target = "nearest", range = 250,
    desc = "자신 주변의 모든 적에게 물리 피해 {1}%.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 240, 20 }, area = { r = 250, at = "self" } } } }
skill { id = "fury_flurry", name = "질풍", icon = "Ability_GhoulFrenzy",
    act = { type = "cd", cd = 14 }, target = "self", cond = { enemies = 1 },
    desc = "다음 기본 공격 {1}회 동안 공격속도가 50% 증가한다.",
    effects = { { type = "buff", who = "self", attacks = { 4, 1 }, mods = { { "AttackSpeed", I, 500 } } } } }
skill { id = "fury_cleave", name = "회전베기", icon = "Ability_Warrior_Cleave",
    act = { type = "count", n = 6 }, target = "nearest",
    desc = "대상과 그 옆의 적 1명에게 물리 피해 {1}%.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 330, 25 }, adjacent = { n = 1, pct = 1 } } } }
skill { id = "fury_death_wish", name = "죽음의 소원", icon = "Spell_Shadow_DeathPact",
    act = { type = "cd", cd = 25 }, target = "self", cond = MANY,
    desc = "8초 동안 공격력이 {1}% 증가하지만 받는 피해도 10% 늘어난다.",
    effects = { { type = "buff", who = "self", dur = 8,
        mods = { { "AttackDamage", M, { 400, 40 } }, { "TakenAll", F, 100 } } } } }
skill { id = "fury_recklessness", name = "무모한 희생", icon = "Ability_CriticalStrike",
    act = { type = "cd", cd = 30 }, target = "self", cond = MANY,
    desc = "7초 동안 치명타 확률이 {1}% 증가한다(곱 방식).",
    effects = { { type = "buff", who = "self", dur = 7, mods = { { "CriticalChance", I, { 600, 60 } } } } } }

------------------------------------------------------------------------
-- 방어 전사
------------------------------------------------------------------------
skill { id = "wprot_shield_slam", name = "방패 밀쳐내기", icon = "INV_Shield_05",
    act = { type = "count", n = 5 }, target = "nearest",
    desc = "물리 피해 {1}%를 주고 4초 동안 대상의 공격력을 15% 낮춘다.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 260, 20 } },
        { type = "debuff", dur = 4, mods = { { "AttackDamage", M, -150 } } } } }
skill { id = "wprot_thunder_clap", name = "천둥벼락", icon = "Spell_Nature_ThunderClap",
    act = { type = "cd", cd = 8 }, target = "nearest", range = 250,
    desc = "자신 주변의 모든 적에게 물리 피해 {1}%를 주고 냉각시킨다.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 180, 15 }, area = { r = 250, at = "self" },
        apply = { { type = "status", status = "Chill" } } } } }
skill { id = "wprot_shield_block", name = "방패 올리기", icon = "Ability_Defend",
    act = { type = "cd", cd = 12 }, target = "self", cond = { enemies = 1 },
    desc = "6초 동안 막기 확률이 {1}%p 증가한다.",
    effects = { { type = "buff", who = "self", dur = 6, mods = { { "BlockChance", F, { 250, 25 } } } } } }
skill { id = "wprot_intervene", name = "가로막기", icon = "Ability_Warrior_DefensiveStance",
    act = { type = "aura" },
    desc = "주변 아군이 받는 피해의 {1}%를 대신 받는다. 대신 받은 피해에는 자신의 방어가 적용된다.",
    effects = { { type = "aura", radius = 600, redirect = { mode = "allies", pct = { 15, 1.5 } } } } }
skill { id = "wprot_shield_wall", name = "방패의 벽", icon = "Ability_Warrior_ShieldWall",
    act = { type = "cd", cd = 40 }, target = "self", cond = { hpBelow = 0.5 },
    desc = "8초 동안 피해 감소가 {1}% 증가한다.",
    effects = { { type = "buff", who = "self", dur = 8, mods = { { "DamageReduction", F, { 300, 20 } } } } } }
skill { id = "wprot_last_stand", name = "최후의 저항", icon = "Spell_Holy_AshesToAshes",
    act = { type = "aura" },
    desc = "죽을 피해를 받으면 최대 체력의 {1}%로 버틴다. 스테이지당 1회.",
    effects = { { type = "aura", who = "self", lethal = { pct = { 30, 10 } } } } }

------------------------------------------------------------------------
-- 신성 성기사
------------------------------------------------------------------------
skill { id = "hpal_holy_light", name = "성스러운 빛", icon = "Spell_Holy_HolyBolt",
    act = { type = "cd", cd = 7 }, target = "lowestHpHero", cond = { targetHpBelow = 0.85 },
    desc = "체력 비율이 가장 낮은 아군을 최대 체력의 {1}%만큼 회복한다.",
    effects = { { type = "heal", pct = { 12, 2 } } } }
skill { id = "hpal_devotion_aura", name = "헌신의 오라", icon = "Spell_Holy_DevotionAura",
    act = { type = "aura" },
    desc = "주변 아군의 방어도가 {1}% 증가한다.",
    effects = { { type = "aura", who = "allies", radius = 1200, includeSummons = true, mods = { { "Armor", I, { 200, 30 } } } } } }
skill { id = "hpal_flash_of_light", name = "빛의 섬광", icon = "Spell_Holy_FlashHeal",
    act = { type = "count", n = 4 }, target = "lowestHpHero",
    desc = "체력 비율이 가장 낮은 아군을 최대 체력의 {1}%만큼 회복한다.",
    effects = { { type = "heal", pct = { 4, 0.6 } } } }
skill { id = "hpal_blessing_protection", name = "보호의 축복", icon = "Spell_Holy_SealOfProtection",
    act = { type = "cd", cd = 25 }, target = "lowestHpHero", cond = { targetHpBelow = 0.4 },
    desc = "체력 비율이 가장 낮은 아군의 피해 감소를 5초 동안 {1}% 높인다.",
    effects = { { type = "buff", who = "target", dur = 5, mods = { { "DamageReduction", F, { 400, 30 } } } } } }
skill { id = "hpal_holy_shock", name = "신성 충격", icon = "Spell_Holy_SearingLight",
    act = { type = "cd", cd = 10 }, target = "nearest", range = 600,
    desc = "번개 피해 {1}%.",
    effects = { { type = "damage", elem = "Lightning", coef = { 320, 25 } } } }
skill { id = "hpal_redemption", name = "구원", icon = "Spell_Holy_Resurrection",
    act = { type = "cd", cd = 45 }, target = "deadAlly",
    desc = "쓰러진 아군 1명을 최대 체력의 {1}%로 부활시킨다.",
    effects = { { type = "revive", pct = { 30, 5 } } } }

------------------------------------------------------------------------
-- 보호 성기사
------------------------------------------------------------------------
skill { id = "ppal_judgement", name = "정의의 망치", icon = "Spell_Holy_SealOfMight",
    act = { type = "count", n = 5 }, target = "nearest",
    desc = "번개 피해 {1}%.",
    effects = { { type = "damage", elem = "Lightning", melee = true, coef = { 250, 20 } } } }
skill { id = "ppal_consecration", name = "신성화", icon = "Spell_Holy_InnerFire",
    act = { type = "cd", cd = 10 }, target = "nearest", range = 300,
    desc = "자신의 발밑을 8초 동안 신성하게 만들어 안의 적에게 초당 번개 피해 {1}%.",
    effects = { { type = "zone", r = 300, dur = 8, every = 1, at = "self",
        enemy = { { type = "damage", elem = "Lightning", coef = { 45, 4 }, aoe = true } } } } }
skill { id = "ppal_holy_shield", name = "신성한 방패", icon = "Spell_Holy_BlessingOfProtection",
    act = { type = "cd", cd = 12 }, target = "self", cond = { enemies = 1 },
    desc = "8초 동안 막기 확률이 {1}%p 증가하고, 막을 때마다 공격자에게 번개 피해 {2}%.",
    effects = { { type = "buff", who = "self", dur = 8, mods = { { "BlockChance", F, { 200, 20 } } },
        reflect = { on = "block", elem = "Lightning", coef = { 120, 10 } } } } }
skill { id = "ppal_retribution_aura", name = "응징의 오라", icon = "Spell_Holy_AuraOfLight",
    act = { type = "aura" },
    desc = "주변 아군을 근접 공격한 적에게 번개 피해 {1}%를 되돌려 준다.",
    effects = { { type = "aura", radius = 600, reflect = { allies = true, meleeOnly = true, elem = "Lightning", coef = { 40, 4 } } } } }
skill { id = "ppal_divine_protection", name = "신의 가호", icon = "Spell_Holy_Restoration",
    act = { type = "cd", cd = 40 }, target = "self", cond = { hpBelow = 0.5 },
    desc = "6초 동안 피해 감소가 {1}% 증가한다.",
    effects = { { type = "buff", who = "self", dur = 6, mods = { { "DamageReduction", F, { 350, 20 } } } } } }
skill { id = "ppal_sacrifice", name = "희생의 축복", icon = "Spell_Holy_SealOfSacrifice",
    act = { type = "aura" },
    desc = "체력 비율이 가장 낮은 아군 1명이 받는 피해의 {1}%를 대신 받는다.",
    effects = { { type = "aura", radius = 1200, redirect = { mode = "lowest", pct = { 25, 2 } } } } }

------------------------------------------------------------------------
-- 징벌 성기사
------------------------------------------------------------------------
skill { id = "ret_crusader_strike", name = "성전사의 일격", icon = "Spell_Holy_CrusaderStrike",
    act = { type = "count", n = 4 }, target = "nearest",
    desc = "물리 피해 {1}%.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 500, 38 } } } }
skill { id = "ret_judgement", name = "심판", icon = "Spell_Holy_RighteousFury",
    act = { type = "cd", cd = 8 }, target = "nearest", range = 600,
    desc = "번개 피해 {1}%.",
    effects = { { type = "damage", elem = "Lightning", coef = { 320, 25 } } } }
skill { id = "ret_seal_of_command", name = "지휘의 문장", icon = "Ability_Warrior_InnerRage",
    act = { type = "aura" },
    desc = "기본 공격 시 25% 확률로 번개 피해 {1}%를 추가로 준다.",
    effects = { { type = "aura", who = "self", proc = { chance = 25,
        effects = { { type = "damage", elem = "Lightning", melee = true, coef = { 180, 15 }, noMultistrike = true } } } } } }
skill { id = "ret_blessing_of_might", name = "힘의 축복", icon = "Spell_Holy_FistOfJustice",
    act = { type = "aura" },
    desc = "주변 아군의 공격력이 {1}% 증가한다(곱 방식).",
    effects = { { type = "aura", who = "allies", radius = 1200, mods = { { "AttackDamage", M, { 250, 40 } } } } } }
skill { id = "ret_hammer_of_wrath", name = "천벌의 망치", icon = "Ability_ThunderClap",
    act = { type = "cd", cd = 12 }, target = "lowestHpEnemy", range = 900,
    desc = "체력 비율이 가장 낮은 적에게 번개 피해 {1}%. 대상의 체력이 35% 이하면 2배.",
    effects = { { type = "damage", elem = "Lightning", proj = true, coef = { 420, 32 }, bonusIf = { hpBelow = 0.35, mult = 2 } } } }
skill { id = "ret_holy_wrath", name = "신성한 격노", icon = "Spell_Holy_Excorcism",
    act = { type = "cd", cd = 18 }, target = "nearest", range = 400, cond = { enemies = 2, orBoss = true },
    desc = "대상 주변의 모든 적에게 번개 피해 {1}%.",
    effects = { { type = "damage", elem = "Lightning", coef = { 480, 38 }, area = { r = 350, at = "target" } } } }

------------------------------------------------------------------------
-- 야수 사냥꾼
------------------------------------------------------------------------
skill { id = "bm_pet", name = "야수 동료", icon = "Ability_Hunter_BeastCall",
    act = { type = "aura" },
    desc = "야수 1마리가 함께 싸운다. 1.2초마다 물리 피해 {1}%. 야수의 체력은 자신의 최대 체력의 150%이고, 죽으면 20초 뒤 다시 부른다.",
    effects = { { type = "summon", permanent = true, respawn = 20,
        unit = { name = "야수", kind = "follower", hpPct = 150, interval = 1.2, coef = { 90, 8 }, melee = true, range = 130,
            moveSpeed = 1000, model = "beast" } } } }
skill { id = "bm_kill_command", name = "살상 명령", icon = "Ability_Hunter_KillCommand",
    act = { type = "count", n = 5 }, target = "nearest", range = 1200,
    desc = "야수가 자신의 대상에게 물리 피해 {1}%.",
    effects = { { type = "damage", elem = "Physical", melee = true, coef = { 380, 30 }, summonHit = "bm_pet" } } }
skill { id = "bm_multi_shot", name = "일제 사격", icon = "Ability_UpgradeMoonGlaive",
    act = { type = "cd", cd = 8 }, target = "nearest", range = 1000,
    desc = "서로 다른 적 3명에게 각각 물리 피해 {1}%. 적이 모자라면 남는 화살은 주 대상에게 간다.",
    effects = { { type = "damage", elem = "Physical", proj = true, coef = { 150, 12 }, spread = 3 } } }
skill { id = "bm_bestial_wrath", name = "야수의 격노", icon = "Ability_Druid_FerociousBite",
    act = { type = "cd", cd = 25 }, target = "self", cond = { summons = 1 },
    desc = "8초 동안 야수의 피해가 {1}% 증가하고 야수가 행동 불가에 걸리지 않는다.",
    effects = { { type = "buff", who = "summons", dur = 8, ccImmune = true, mods = { { "DamageDealt", M, { 800, 80 } } } } } }
skill { id = "bm_serpent_sting", name = "독사 쐐기", icon = "Ability_Hunter_Quickshot",
    act = { type = "count", n = 6 }, target = "nearest", range = 1000,
    desc = "8초 동안 초당 암흑 피해 {1}%.",
    effects = { { type = "dot", elem = "Chaos", coef = { 45, 4 }, dur = 8 } } }
skill { id = "bm_frenzy", name = "광기", icon = "INV_Misc_MonsterClaw_03",
    act = { type = "aura" },
    desc = "야수의 공격속도가 {1}% 증가한다.",
    effects = { { type = "aura", who = "summons", mods = { { "AttackSpeed", M, { 300, 30 } } } } } }

------------------------------------------------------------------------
-- 사격 사냥꾼
------------------------------------------------------------------------
skill { id = "mm_rapid_shots", name = "연발 사격", icon = "Ability_Marksmanship",
    act = { type = "count", n = 5 }, target = "nearest", range = 1150,
    desc = "화살 3발을 쏘아 각각 물리 피해 {1}%.",
    effects = { { type = "damage", elem = "Physical", proj = true, coef = { 132, 12 }, hits = 3 } } }
skill { id = "mm_aimed_shot", name = "조준 사격", icon = "INV_Spear_07",
    act = { type = "cd", cd = 7 }, target = "highestHpEnemy", range = 1300,
    desc = "체력이 가장 많은 적에게 물리 피해 {1}%.",
    effects = { { type = "damage", elem = "Physical", proj = true, coef = { 420, 32 } } } }
skill { id = "mm_volley", name = "화살비", icon = "Ability_Marksmanship",
    act = { type = "cd", cd = 10 }, target = "cluster", range = 1300, clusterRadius = 300,
    desc = "적이 가장 많이 모인 곳에 화살을 퍼부어 물리 피해 {1}%.",
    effects = { { type = "damage", elem = "Physical", coef = { 215, 26 }, area = { r = 300, at = "target" } } } }
skill { id = "mm_rapid_fire", name = "속사", icon = "Ability_Hunter_RunningShot",
    act = { type = "cd", cd = 21 }, target = "self", cond = { enemies = 1 },
    desc = "7초 동안 공격속도가 {1}% 증가한다.",
    effects = { { type = "buff", who = "self", dur = 7, mods = { { "AttackSpeed", I, { 500, 100 } } } } } }
skill { id = "mm_trueshot_aura", name = "정조준 오라", icon = "Ability_TrueShot",
    act = { type = "aura" },
    desc = "주변 아군의 공격력이 {1}% 증가한다(합 방식).",
    effects = { { type = "aura", who = "allies", radius = 1200, mods = { { "AttackDamage", I, { 150, 20 } } } } } }
skill { id = "mm_piercing_arrow", name = "꿰뚫는 화살", icon = "Ability_PierceDamage",
    act = { type = "count", n = 9 }, target = "nearest", range = 1200,
    desc = "일직선 위의 모든 적을 꿰뚫어 물리 피해 {1}%.",
    effects = { { type = "damage", elem = "Physical", proj = true, coef = { 300, 22 }, line = true, noMultistrike = true } } }

------------------------------------------------------------------------
-- 생존 사냥꾼
------------------------------------------------------------------------
skill { id = "sv_explosive_trap", name = "폭발의 덫", icon = "Spell_Fire_SelfDestruct",
    act = { type = "cd", cd = 6 }, target = "nearest", range = 1200,
    desc = "적의 진로에 덫을 놓는다(최대 2개). 닿으면 주변에 화염 피해 {1}%를 주고 점화시킨다.",
    effects = { { type = "trap", r = 250, max = 2, effects = {
        { type = "damage", elem = "Fire", coef = { 380, 30 }, area = { r = 250, at = "target" },
            apply = { { type = "status", status = "Ignite" } } } } } } }
skill { id = "sv_venom_bolt", name = "맹독 볼트", icon = "Ability_Hunter_AimedShot",
    act = { type = "count", n = 5 }, target = "nearest", range = 1100,
    desc = "물리 피해 {1}%를 주고 6초 동안 초당 암흑 피해 {2}%.",
    effects = { { type = "damage", elem = "Physical", proj = true, coef = { 300, 24 } },
        { type = "dot", elem = "Chaos", coef = { 40, 3 }, dur = 6 } } }
skill { id = "sv_freezing_trap", name = "얼음의 덫", icon = "Spell_Frost_ChainsOfIce",
    act = { type = "cd", cd = 14 }, target = "nearest", range = 1200,
    desc = "적의 진로에 덫을 놓는다. 닿으면 주변에 냉기 피해 {1}%를 주고 빙결시킨다.",
    effects = { { type = "trap", r = 250, max = 1, effects = {
        { type = "damage", elem = "Cold", coef = { 200, 15 }, area = { r = 250, at = "target" },
            apply = { { type = "status", status = "Freeze" } } } } } } }
skill { id = "sv_wyvern_sting", name = "비룡 쐐기", icon = "INV_Spear_02",
    act = { type = "cd", cd = 12 }, target = "highestHpEnemy", range = 1100,
    desc = "체력이 가장 많은 적에게 암흑 피해 {1}%를 주고 기절시킨다.",
    effects = { { type = "damage", elem = "Chaos", proj = true, coef = { 250, 20 } }, { type = "status", status = "Stun" } } }
skill { id = "sv_expose_weakness", name = "약점 노출", icon = "Ability_Rogue_FindWeakness",
    act = { type = "aura" },
    desc = "자신의 치명타에 맞은 적이 6초 동안 물리 피해를 {1}% 더 받는다.",
    effects = { { type = "aura", who = "self", onCrit = {
        { type = "debuff", id = "expose_weakness", dur = 6, mods = { { "TakenPhysical", F, { 100, 10 } } } } } } } }
skill { id = "sv_shock_bolt", name = "감전 볼트", icon = "Spell_Nature_LightningBolt",
    act = { type = "count", n = 8 }, target = "nearest", range = 1100,
    desc = "번개 피해 {1}%를 주고 감전시킨다. 박힌 볼트가 4초 동안 주변에 초당 번개 피해 60%를 준다.",
    effects = { { type = "damage", elem = "Lightning", proj = true, coef = { 380, 55 } },
        { type = "status", status = "Shock" },
        { type = "zone", r = 200, dur = 4, every = 1, at = "target",
            enemy = { { type = "damage", elem = "Lightning", coef = 60, aoe = true } } } } }

return SkillData
