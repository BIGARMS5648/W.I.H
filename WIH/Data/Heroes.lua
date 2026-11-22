-- 영웅 30명의 정의: 기본 능력치, 무기 종류, 패시브 트리, 스킬 목록.
-- 구조는 원작 영웅과 같다(액티브 6 + 패시브 16). 내용은 이 프로젝트의 독자 설계다(docs/design/02-heroes.md).
-- 기본 능력치의 단위는 Data/Stats.lua 와 같다(공격속도 ÷100, 치명타 ÷1000 등).

local _, WIH = ...
local Stats = WIH.module("Stats")
local Heroes = WIH.module("Heroes")

local F, I = Stats.FLAT, Stats.INC

-- 패시브 노드: {능력치, 연산, 포인트당 값, 최대 레벨}
local function N(stat, kind, per, max) return { stat = stat, kind = kind, per = per, max = max } end

-- 자주 쓰는 노드
local AD1, AD2 = function(m) return N("AttackDamage", F, 1, m) end, function(m) return N("AttackDamage", F, 2, m) end
local AD5 = function(m) return N("AttackDamage", F, 5, m) end
local HP = function(v, m) return N("MaxHp", F, v, m) end
local HPP = function(m) return N("MaxHp", I, 50, m) end
local ARM = function(v, m) return N("Armor", F, v, m) end
local REGEN = function(v, m) return N("HpRegenPerSec", F, v * 100, m) end
local BLOCK = function(m) return N("BlockChance", F, 30, m) end
local DODGE = function(m) return N("DodgeChance", F, 30, m) end
local EDODGE = function(m) return N("ElementalDodgeChance", F, 30, m) end
local KILL = function(v, m) return N("AddHpPerKill", F, v, m) end
local HIT = function(v, m) return N("AddHpPerHit", F, v, m) end
local LEECH = function(m) return N("HpLeech", F, 5, m) end
local ELEM = function(e, v, m) return N(e .. "DamagePercent", F, v, m) end
local CDR = function(v, m) return N("CooldownReduction", F, v * 10, m) end
local ABS = function(m) return N("DamageAbsorption", F, 5, m) end
local RES = function(v, m) return N("AllElementalResistance", F, v, m) end
local AS = function(v, m) return N("AttackSpeed", I, v * 10, m) end
local CAST = function(m) return N("CastSpeed", I, 70, m) end
local DR = function(m) return N("DamageReduction", F, 20, m) end
local AOE = function(m) return N("AreaOfEffect", I, 30, m) end
local CRITC = function(m) return N("CriticalChance", I, 200, m) end
local CRITF = function(m) return N("CriticalChance", F, 3, m) end
local CRITD = function(v, m) return N("CriticalDamage", F, v * 10, m) end
local MELEE = function(m) return N("IncreaseMeleeDamage", I, 150, m) end
local PROJ = function(m) return N("IncreaseProjectileDamage", I, 150, m) end
local AOED = function(m) return N("IncreaseAreaOfEffectDamage", I, 150, m) end
local SUMMON = function(m) return N("IncreaseSummonDamage", I, 150, m) end
local MSF = function(m) return N("MovementSpeed", F, 20, m) end
local MSP = function(m) return N("MovementSpeed", I, 30, m) end
local DUR = function(m) return N("SkillDurationIncrease", I, 80, m) end
local HEAL = function(m) return N("SkillHealIncrease", I, 70, m) end

-- 패시브 템플릿. 16칸: 티어 0, 0, 10, 10, 20, 20, …, 70, 70 순서. 최대 레벨은 원작 구조(3·8 / 8·5 또는 8·3 / 이후 10·10).
local function tank()
    return { AD1(3), HP(15, 8), ARM(10, 8), REGEN(1, 5), BLOCK(10), KILL(3, 10), HPP(10), ELEM("Physical", 150, 10),
        CDR(2, 10), REGEN(2, 10), BLOCK(10), ABS(10), RES(5, 10), AS(4, 10), DR(10), HP(30, 10) }
end
local function meleeHeavy()
    return { AD2(3), HP(15, 8), AOE(8), KILL(5, 3), ELEM("Physical", 150, 10), LEECH(10), AD2(10), HP(20, 10),
        CRITD(10, 10), ELEM("Physical", 150, 10), MELEE(10), AOE(10), HP(30, 10), MSP(10), MELEE(10), DUR(10) }
end
local function meleeFast()
    return { AD1(3), AS(4, 8), CRITC(8), CRITD(13, 3), DODGE(10), MELEE(10), ELEM("Physical", 150, 10), AS(5, 10),
        LEECH(10), MSF(10), DODGE(10), CRITD(10, 10), MELEE(10), HP(20, 10), AS(6, 10), CRITF(10) }
end
local function rangedFast()
    return { AD1(3), AS(4, 8), CRITC(8), CRITD(13, 3), DODGE(10), PROJ(10), DODGE(10), AS(5, 10),
        EDODGE(10), MSF(10), DODGE(10), LEECH(10), AOED(10), PROJ(10), DODGE(10), AS(6, 10) }
end
local function rangedHeavy(a, b)
    return { AD2(3), CRITC(8), CRITD(10, 8), DODGE(3), ELEM(a, 150, 10), ELEM(b, 150, 10), CDR(1, 10), HP(15, 10),
        ELEM("Physical", 150, 10), CRITF(10), AD5(10), AOE(10), ELEM(a, 150, 10), CRITD(15, 10), AS(6, 10), HIT(3, 10) }
end
local function caster(a, b)
    return { AD2(3), CDR(1, 8), AOE(8), CRITC(3), ELEM(a, 100, 10), ELEM(b, 100, 10), ELEM(a, 100, 10), HP(10, 10),
        CDR(2, 10), AD2(10), CAST(10), CRITD(20, 10), RES(3, 10), AOE(10), CRITF(10), CDR(2, 10) }
end
local function healer()
    return { AD1(3), HP(15, 8), ARM(10, 8), ABS(3), CDR(2, 10), HEAL(10), HP(15, 10), ABS(10),
        CAST(10), REGEN(2, 10), HEAL(10), RES(4, 10), CDR(2, 10), ARM(50, 10), AOE(10), CAST(10) }
end
local function summoner(a)
    return { AD2(3), CDR(1, 8), SUMMON(8), CRITC(3), SUMMON(10), ELEM(a, 100, 10), DUR(10), HP(10, 10),
        CDR(2, 10), AD2(10), SUMMON(10), CAST(10), RES(3, 10), DUR(10), SUMMON(10), CDR(2, 10) }
end

-- 템플릿의 일부 칸을 바꾼다. swaps = { [칸 번호] = 노드 }
local function with(nodes, swaps)
    for index, node in pairs(swaps) do nodes[index] = node end
    return nodes
end

local TIERS = { 0, 0, 10, 10, 20, 20, 30, 30, 40, 40, 50, 50, 60, 60, 70, 70 }
Heroes.PASSIVE_TIERS = TIERS
Heroes.ACTIVE_TIERS = { 0, 0, 10, 20, 30, 40 }
Heroes.ACTIVE_MAX_BY_POINTS = 5   -- [원작] 포인트로는 Lv5까지. Lv6~10은 "모든 스킬 레벨"로만

-- 직업
Heroes.CLASSES = {
    WARRIOR = "전사", PALADIN = "성기사", HUNTER = "사냥꾼", ROGUE = "도적", PRIEST = "사제",
    SHAMAN = "주술사", MAGE = "마법사", WARLOCK = "흑마법사", DRUID = "드루이드", TINKER = "땜장이",
}
Heroes.CLASS_ORDER = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "SHAMAN", "MAGE", "WARLOCK", "DRUID", "TINKER" }
Heroes.ROLES = { tank = "탱커", healer = "힐러", melee = "근접 딜러", ranged = "원거리 딜러", summoner = "소환 딜러" }

local list = {}
Heroes.list = list
Heroes.byId = {}

-- base 인자 순서: 체력, 방어도, 공격력, 공격속도(×100), 치명타(퍼밀), 치명타 피해(퍼밀), 이동속도
local function hero(id, class, name, role, main, sub, hp, armor, ad, as, crit, critDmg, ms, range, elem, passives, skills)
    local h = {
        id = id, class = class, name = name, role = role, main = main, sub = sub,
        base = { MaxHp = hp, Armor = armor, AttackDamage = ad, AttackSpeed = as, CriticalChance = crit,
            CriticalDamage = critDmg, MovementSpeed = ms, CastSpeed = 100 },
        melee = range <= 200, range = range, basicElem = elem, passives = passives, skills = skills,
    }
    list[#list + 1] = h
    Heroes.byId[id] = h
    return h
end

-- 전사
hero("war_arms", "WARRIOR", "무기 전사", "melee", "GREATSWORD", "THROWN", 115, 40, 2, 55, 25, 1800, 900, 150, "Physical",
    meleeHeavy(),
    { "arms_mortal_strike", "arms_charge", "arms_rend", "arms_sweeping", "arms_overpower", "arms_execute" })
hero("war_fury", "WARRIOR", "분노 전사", "melee", "AXE", "OFFHAND", 110, 35, 1, 75, 30, 1600, 900, 130, "Physical",
    with(meleeFast(), { [5] = KILL(3, 10), [11] = ELEM("Physical", 150, 10) }),
    { "fury_bloodthirst", "fury_whirlwind", "fury_flurry", "fury_cleave", "fury_death_wish", "fury_recklessness" })
hero("war_prot", "WARRIOR", "방어 전사", "tank", "SWORD", "SHIELD", 130, 45, 2, 80, 25, 1400, 950, 140, "Physical",
    tank(),
    { "wprot_shield_slam", "wprot_thunder_clap", "wprot_shield_block", "wprot_intervene", "wprot_shield_wall", "wprot_last_stand" })

-- 성기사
hero("pal_holy", "PALADIN", "신성 성기사", "healer", "MACE", "LIBRAM", 95, 30, 1, 80, 20, 1400, 770, 170, "Physical",
    with(healer(), { [10] = BLOCK(10) }),
    { "hpal_holy_light", "hpal_devotion_aura", "hpal_flash_of_light", "hpal_blessing_protection", "hpal_holy_shock", "hpal_redemption" })
hero("pal_prot", "PALADIN", "보호 성기사", "tank", "SWORD", "SHIELD", 125, 42, 2, 80, 25, 1400, 900, 140, "Physical",
    with(tank(), { [8] = ELEM("Lightning", 150, 10) }),
    { "ppal_judgement", "ppal_consecration", "ppal_holy_shield", "ppal_retribution_aura", "ppal_divine_protection", "ppal_sacrifice" })
hero("pal_ret", "PALADIN", "징벌 성기사", "melee", "GREATSWORD", "LIBRAM", 110, 40, 2, 55, 30, 1700, 880, 150, "Physical",
    with(meleeHeavy(), { [10] = ELEM("Lightning", 150, 10), [12] = CDR(2, 10) }),
    { "ret_crusader_strike", "ret_judgement", "ret_seal_of_command", "ret_blessing_of_might", "ret_hammer_of_wrath", "ret_holy_wrath" })

-- 사냥꾼
hero("hun_bm", "HUNTER", "야수 사냥꾼", "summoner", "GUN", "AMMO", 70, 15, 2, 55, 40, 1500, 850, 1000, "Physical",
    with(summoner("Physical"), { [12] = AS(6, 10) }),
    { "bm_pet", "bm_kill_command", "bm_multi_shot", "bm_bestial_wrath", "bm_serpent_sting", "bm_frenzy" })
hero("hun_mm", "HUNTER", "사격 사냥꾼", "ranged", "BOW", "QUIVER", 60, 8, 1, 100, 40, 1500, 850, 1100, "Physical",
    rangedFast(),
    { "mm_rapid_shots", "mm_aimed_shot", "mm_volley", "mm_rapid_fire", "mm_trueshot_aura", "mm_piercing_arrow" })
hero("hun_sv", "HUNTER", "생존 사냥꾼", "ranged", "CROSSBOW", "QUIVER", 70, 15, 2, 55, 45, 1550, 850, 1000, "Physical",
    rangedHeavy("Fire", "Chaos"),
    { "sv_explosive_trap", "sv_venom_bolt", "sv_freezing_trap", "sv_wyvern_sting", "sv_expose_weakness", "sv_shock_bolt" })

-- 도적
hero("rog_assa", "ROGUE", "암살 도적", "melee", "DAGGER", "OFFHAND", 85, 22, 1, 85, 50, 1700, 950, 120, "Physical",
    with(meleeFast(), { [7] = ELEM("Chaos", 150, 10), [14] = CRITD(10, 10) }),
    { "assa_poisoned_blade", "assa_eviscerate", "assa_cold_blood", "assa_envenom", "assa_rupture", "assa_fan_of_knives" })
hero("rog_combat", "ROGUE", "전투 도적", "melee", "SWORD", "OFFHAND", 95, 28, 1, 80, 40, 1600, 950, 130, "Physical",
    meleeFast(),
    { "combat_sinister_strike", "combat_slice_and_dice", "combat_blade_flurry", "combat_eviscerate", "combat_riposte", "combat_adrenaline_rush" })
hero("rog_sub", "ROGUE", "잠행 도적", "melee", "DAGGER", "THROWN", 80, 20, 1, 80, 50, 1750, 1000, 120, "Physical",
    with(meleeFast(), { [9] = CRITD(10, 10) }),
    { "sub_ambush", "sub_hemorrhage", "sub_evasion", "sub_vanish", "sub_kidney_shot", "sub_premeditation" })

-- 사제
hero("pri_disc", "PRIEST", "수양 사제", "healer", "WAND", "TOME", 55, 6, 1, 70, 30, 1500, 770, 900, "Lightning",
    healer(),
    { "disc_shield", "disc_flash_heal", "disc_fortitude", "disc_power_infusion", "disc_divine_spirit", "disc_resurrection" })
hero("pri_holy", "PRIEST", "신성 사제", "healer", "WAND", "TOME", 55, 6, 1, 70, 30, 1500, 770, 900, "Lightning",
    healer(),
    { "hpri_greater_heal", "hpri_renew", "hpri_prayer_of_healing", "hpri_lightwell", "hpri_holy_fire", "hpri_resurrection" })
hero("pri_shadow", "PRIEST", "암흑 사제", "ranged", "WAND", "TOME", 55, 6, 2, 50, 50, 1600, 770, 900, "Chaos",
    with(caster("Chaos", "Lightning"), { [14] = LEECH(10) }),
    { "shadow_word_pain", "shadow_mind_blast", "shadow_mind_flay", "shadow_vampiric_embrace", "shadow_shadowform", "shadow_psychic_scream" })

-- 주술사
hero("sha_ele", "SHAMAN", "정기 주술사", "ranged", "MACE", "TOTEM", 65, 15, 2, 50, 50, 1650, 770, 900, "Lightning",
    with(caster("Lightning", "Fire"), { [14] = DUR(10) }),
    { "ele_chain_lightning", "ele_flame_shock", "ele_searing_totem", "ele_earth_shock", "ele_mastery", "ele_magma_totem" })
hero("sha_enh", "SHAMAN", "고양 주술사", "melee", "AXE", "TOTEM", 100, 32, 1, 75, 35, 1600, 900, 130, "Physical",
    with(meleeFast(), { [7] = ELEM("Lightning", 150, 10), [11] = DUR(10) }),
    { "enh_stormstrike", "enh_windfury_weapon", "enh_earth_shock", "enh_strength_totem", "enh_lightning_shield", "enh_windfury_totem" })
hero("sha_resto", "SHAMAN", "복원 주술사", "healer", "MACE", "TOTEM", 70, 18, 1, 70, 30, 1500, 770, 850, "Lightning",
    with(healer(), { [15] = DUR(10) }),
    { "resto_healing_wave", "resto_healing_totem", "resto_chain_heal", "resto_cleansing_totem", "resto_natures_swiftness", "resto_ancestral_spirit" })

-- 마법사
hero("mag_arcane", "MAGE", "비전 마법사", "ranged", "STAFF", "ORB", 50, 5, 2, 50, 50, 1650, 770, 900, "Lightning",
    with(caster("Lightning", "Lightning"), { [6] = CAST(10) }),
    { "arcane_missiles", "arcane_explosion", "arcane_intellect", "arcane_mana_shield", "arcane_presence_of_mind", "arcane_power" })
hero("mag_fire", "MAGE", "화염 마법사", "ranged", "STAFF", "ORB", 50, 5, 2, 50, 50, 1650, 770, 900, "Fire",
    with(caster("Fire", "Fire"), { [6] = AOED(10) }),
    { "fire_fireball", "fire_scorch", "fire_flamestrike", "fire_blast_wave", "fire_combustion", "fire_pyroblast" })
hero("mag_frost", "MAGE", "냉기 마법사", "ranged", "STAFF", "ORB", 50, 5, 2, 50, 50, 1650, 770, 900, "Cold",
    with(caster("Cold", "Cold"), { [6] = DUR(10) }),
    { "frost_frostbolt", "frost_cone_of_cold", "frost_nova", "frost_ice_barrier", "frost_blizzard", "frost_shatter" })

-- 흑마법사
hero("wlk_aff", "WARLOCK", "고통 흑마법사", "ranged", "STAFF", "GRIMOIRE", 55, 6, 2, 50, 45, 1600, 770, 900, "Chaos",
    with(caster("Chaos", "Chaos"), { [6] = DUR(10) }),
    { "aff_corruption", "aff_curse_of_agony", "aff_felhunter", "aff_drain_life", "aff_curse_of_shadow", "aff_siphon_life" })
hero("wlk_demo", "WARLOCK", "악마 흑마법사", "summoner", "WAND", "GRIMOIRE", 60, 8, 2, 50, 45, 1600, 770, 900, "Chaos",
    summoner("Chaos"),
    { "demo_voidwalker", "demo_shadow_bolt", "demo_succubus", "demo_empowerment", "demo_soul_link", "demo_infernal" })
hero("wlk_destro", "WARLOCK", "파괴 흑마법사", "ranged", "STAFF", "GRIMOIRE", 55, 6, 2, 50, 50, 1650, 770, 900, "Chaos",
    caster("Fire", "Chaos"),
    { "destro_immolate", "destro_imp", "destro_conflagrate", "destro_rain_of_fire", "destro_shadowburn", "destro_soul_fire" })

-- 드루이드
hero("dru_balance", "DRUID", "조화 드루이드", "ranged", "STAFF", "IDOL", 60, 10, 2, 50, 50, 1650, 800, 900, "Lightning",
    caster("Lightning", "Chaos"),
    { "bal_moonfire", "bal_starfire", "bal_insect_swarm", "bal_entangling_roots", "bal_hurricane", "bal_moonkin_form" })
local feral = hero("dru_feral", "DRUID", "야성 드루이드", "tank", "MACE", "IDOL", 140, 35, 2, 80, 30, 1400, 950, 130, "Physical",
    { AD1(3), HP(15, 8), ARM(10, 8), REGEN(1, 5), DODGE(10), MELEE(10), HPP(10), ELEM("Physical", 150, 10),
        LEECH(10), MSF(10), DODGE(10), ABS(10), MELEE(10), HP(20, 10), DR(10), HP(30, 10) },
    { "feral_maul_claw", "feral_swipe_rake", "feral_regen_fury", "feral_roar_bite", "feral_mark_of_the_wild", "feral_survival_instincts" })
-- 야성 드루이드는 편성 화면에서 고른 형태에 따라 역할과 기본 능력치가 달라진다.
feral.forms = {
    bear = { name = "곰", role = "tank",
        base = { MaxHp = 140, Armor = 35, AttackDamage = 2, AttackSpeed = 80, CriticalChance = 30, CriticalDamage = 1400,
            MovementSpeed = 950, CastSpeed = 100 }, range = 130 },
    cat = { name = "표범", role = "melee",
        base = { MaxHp = 90, Armor = 25, AttackDamage = 1, AttackSpeed = 90, CriticalChance = 45, CriticalDamage = 1600,
            MovementSpeed = 1000, CastSpeed = 100 }, range = 120 },
}
feral.defaultForm = "bear"
hero("dru_resto", "DRUID", "회복 드루이드", "healer", "STAFF", "IDOL", 60, 10, 1, 70, 30, 1500, 800, 900, "Lightning",
    with(healer(), { [4] = DUR(5), [8] = DUR(10) }),
    { "rdru_rejuvenation", "rdru_healing_touch", "rdru_regrowth", "rdru_swiftmend", "rdru_tranquility", "rdru_rebirth" })

-- 땜장이
hero("tin_armor", "TINKER", "기갑 땜장이", "tank", "TOOL", "POWER_CORE", 120, 40, 2, 70, 25, 1400, 850, 150, "Physical",
    with(tank(), { [5] = ABS(10), [11] = ARM(50, 10) }),
    { "armor_suit", "armor_hydraulic_slam", "armor_emergency_repair", "armor_steel_barrier", "armor_interceptor", "armor_overload" })
hero("tin_destroy", "TINKER", "섬멸 땜장이", "summoner", "TOOL", "TURRET_PART", 65, 12, 2, 60, 40, 1500, 800, 950, "Physical",
    with(summoner("Fire"), { [12] = DUR(10) }),
    { "destroy_autocannon", "destroy_bomb", "destroy_flame_turret", "destroy_battle_robot", "destroy_focus_fire", "destroy_overcharge" })
hero("tin_medic", "TINKER", "치료 땜장이", "healer", "TOOL", "DRONE_MODULE", 65, 12, 1, 70, 30, 1500, 800, 900, "Physical",
    with(healer(), { [12] = DUR(10) }),
    { "medic_drone", "medic_nano", "medic_station", "medic_wave", "medic_life_support", "medic_revive_protocol" })

-- 무기 종류 [독자: 원작의 종류별 규칙을 따라 확장]
Heroes.MAIN_WEAPONS = {
    SWORD = { name = "한손검", speed = 40 }, GREATSWORD = { name = "양손검", speed = 35 }, AXE = { name = "도끼", speed = 45 },
    MACE = { name = "둔기", speed = 30 }, DAGGER = { name = "단검", speed = 50 }, BOW = { name = "활", speed = 50 },
    CROSSBOW = { name = "석궁", speed = 35 }, GUN = { name = "총", speed = 35 }, STAFF = { name = "지팡이", speed = 25 },
    WAND = { name = "마법봉", speed = 30 }, TOOL = { name = "기계 공구", speed = 30 },
}
Heroes.SUB_WEAPONS = {
    SHIELD = { name = "방패", stat = "BlockChance", kind = F }, OFFHAND = { name = "보조 무기", stat = "AttackDamage", kind = I },
    THROWN = { name = "투척 무기", stat = "CriticalDamage", kind = F }, QUIVER = { name = "화살통", stat = "AttackSpeed", kind = I },
    AMMO = { name = "탄환 주머니", stat = "CriticalDamage", kind = F }, ORB = { name = "마법 보주", stat = "CooldownReduction", kind = F },
    TOME = { name = "고서", stat = "MaxHp", kind = F }, GRIMOIRE = { name = "흑마법서", stat = "IncreaseSummonDamage", kind = I },
    LIBRAM = { name = "성물", stat = "CooldownReduction", kind = F }, TOTEM = { name = "토템", stat = "SkillDurationIncrease", kind = I },
    IDOL = { name = "우상", stat = "MaxHp", kind = F }, POWER_CORE = { name = "동력 장치", stat = "DamageAbsorption", kind = F },
    TURRET_PART = { name = "포탑 부품", stat = "IncreaseSummonDamage", kind = I },
    DRONE_MODULE = { name = "드론 모듈", stat = "SkillHealIncrease", kind = I },
}

-- 주무기 공격속도 가산의 등급 배율 [원작의 등급 비율]: 고급~불멸 1, 아르카나 1.3, 초월 1.7, 천상 2.2, 신성 2.8, 우주 3.6
Heroes.WEAPON_SPEED_GRADE = { 1, 1, 1, 1, 1, 1.3, 1.7, 2.2, 2.8, 3.6 }

-- 누적 포인트로 트리의 각 티어가 열렸는지
function Heroes.tierUnlocked(tier, spentPoints)
    return spentPoints >= tier
end

return Heroes
