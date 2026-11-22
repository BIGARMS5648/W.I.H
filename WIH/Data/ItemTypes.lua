-- 장비의 등급, 칸, 종류. 수치는 Data/ItemTable.lua(원작 표)의 곡선에서 온다.
-- 종류가 어느 곡선을 쓰는지와, 원작에 없는 기본 능력치를 가진 보조무기의 대응은 이 프로젝트의 설계다 [독자].

local _, WIH = ...
local Stats = WIH.module("Stats")
local Items = WIH.module("Items")

local F, I = Stats.FLAT, Stats.INC

-- 등급 [원작: 10단계와 등급별 칸 수, 연금 기본 골드]. 색은 이 프로젝트가 정했다 [독자].
-- fixed = 고정 능력치 줄 수, decor/engrave/inscribe = 큐브로 붙이는 칸 수, gold = 연금 기본 골드
Items.GRADES = {
    { id = "COMMON", name = "일반", fixed = 0, decor = 0, engrave = 0, inscribe = 0, gold = 10, color = { 0.66, 0.67, 0.70 } },
    { id = "UNCOMMON", name = "고급", fixed = 1, decor = 0, engrave = 0, inscribe = 0, gold = 30, color = { 0.47, 0.72, 0.50 } },
    { id = "RARE", name = "희귀", fixed = 1, decor = 1, engrave = 0, inscribe = 0, gold = 90, color = { 0.42, 0.60, 0.86 } },
    { id = "LEGENDARY", name = "전설", fixed = 2, decor = 2, engrave = 0, inscribe = 0, gold = 270, color = { 0.66, 0.50, 0.86 } },
    { id = "IMMORTAL", name = "불멸", fixed = 2, decor = 2, engrave = 1, inscribe = 0, gold = 810, color = { 0.88, 0.62, 0.34 } },
    { id = "ARCANA", name = "아르카나", fixed = 3, decor = 2, engrave = 1, inscribe = 1, gold = 2592, color = { 0.86, 0.42, 0.40 } },
    { id = "BEYOND", name = "초월", fixed = 3, decor = 2, engrave = 2, inscribe = 1, gold = 8294, color = { 0.40, 0.76, 0.74 } },
    { id = "CELESTIAL", name = "천상", fixed = 3, decor = 2, engrave = 2, inscribe = 2, gold = 29029, color = { 0.56, 0.78, 0.94 } },
    { id = "DIVINE", name = "신성", fixed = 3, decor = 2, engrave = 2, inscribe = 2, gold = 101602, color = { 0.92, 0.82, 0.50 } },
    { id = "COSMIC", name = "우주", fixed = 3, decor = 2, engrave = 2, inscribe = 2, gold = 355607, color = { 0.92, 0.66, 0.84 } },
}

-- 칸 [원작: 영웅당 10칸]
Items.SLOTS = { "MAIN", "SUB", "HELMET", "ARMOR", "GLOVES", "BOOTS", "AMULET", "EARRING", "RING", "BRACER" }
Items.SLOT_NAMES = {
    MAIN = "주무기", SUB = "보조무기", HELMET = "투구", ARMOR = "갑옷", GLOVES = "장갑", BOOTS = "신발",
    AMULET = "목걸이", EARRING = "귀걸이", RING = "반지", BRACER = "팔찌",
}

-- 종류. index는 아이템 ID에 들어가므로 한 번 정하면 바꾸지 않는다(뒤에 덧붙이기만 한다).
-- curve = 수치를 가져올 곡선, base = 곡선의 기본 능력치를 다른 능력치로 바꿔 쓸 때 {능력치, 연산, 값 배율}
local TYPES = {
    -- 주무기 [원작 6종의 곡선을 공격속도가 같은 것끼리 대응]
    { "SWORD", "MAIN", "한손검", "SWORD", "INV_Sword_04" },
    { "GREATSWORD", "MAIN", "양손검", "CROSSBOW", "INV_Sword_39" },
    { "AXE", "MAIN", "도끼", "AXE", "INV_Axe_09" },
    { "MACE", "MAIN", "둔기", "SCEPTER", "INV_Mace_01" },
    { "DAGGER", "MAIN", "단검", "BOW", "INV_Weapon_ShortBlade_05" },
    { "BOW", "MAIN", "활", "BOW", "INV_Weapon_Bow_07" },
    { "CROSSBOW", "MAIN", "석궁", "CROSSBOW", "INV_Weapon_Crossbow_04" },
    { "GUN", "MAIN", "총", "CROSSBOW", "INV_Weapon_Rifle_01" },
    { "STAFF", "MAIN", "지팡이", "STAFF", "INV_Staff_08" },
    { "WAND", "MAIN", "마법봉", "SCEPTER", "INV_Wand_01" },
    { "TOOL", "MAIN", "기계 공구", "SCEPTER", "INV_Gizmo_02" },
    -- 보조무기
    { "SHIELD", "SUB", "방패", "SHIELD", "INV_Shield_04" },
    { "OFFHAND", "SUB", "보조 무기", "HATCHET", "INV_Weapon_ShortBlade_01" },
    { "THROWN", "SUB", "투척 무기", "BOLT", "INV_ThrowingKnife_02" },
    { "QUIVER", "SUB", "화살통", "ARROW", "INV_Misc_Quiver_03" },
    { "AMMO", "SUB", "탄환 주머니", "BOLT", "INV_Misc_AmmoBox_01" },
    { "ORB", "SUB", "마법 보주", "ORB", "INV_Misc_Orb_01" },
    { "TOME", "SUB", "고서", "TOME", "INV_Misc_Book_09" },
    { "GRIMOIRE", "SUB", "흑마법서", "HATCHET", "INV_Misc_Book_06", { "IncreaseSummonDamage", I, 1 } },
    { "LIBRAM", "SUB", "성물", "ORB", "INV_Relics_LibramofHope" },
    { "TOTEM", "SUB", "토템", "ARROW", "INV_Relics_TotemofRage", { "SkillDurationIncrease", I, 1 } },
    { "IDOL", "SUB", "우상", "TOME", "INV_Relics_IdolofFerocity" },
    { "POWER_CORE", "SUB", "동력 장치", "TOME", "INV_Battery_02", { "DamageAbsorption", F, 0.5 } },
    { "TURRET_PART", "SUB", "포탑 부품", "HATCHET", "INV_Gizmo_03", { "IncreaseSummonDamage", I, 1 } },
    { "DRONE_MODULE", "SUB", "드론 모듈", "ARROW", "INV_Gizmo_01", { "SkillHealIncrease", I, 1 } },
    -- 방어구와 장신구 [원작 그대로]
    { "HELMET", "HELMET", "투구", "HELMET", "INV_Helmet_03" },
    { "ARMOR", "ARMOR", "갑옷", "ARMOR", "INV_Chest_Chain_05" },
    { "GLOVES", "GLOVES", "장갑", "GLOVES", "INV_Gauntlets_04" },
    { "BOOTS", "BOOTS", "신발", "BOOTS", "INV_Boots_05" },
    { "AMULET", "AMULET", "목걸이", "AMULET", "INV_Jewelry_Necklace_07" },
    { "EARRING", "EARRING", "귀걸이", "EARING", "INV_Jewelry_Ring_15" },
    { "RING", "RING", "반지", "RING", "INV_Jewelry_Ring_03" },
    { "BRACER", "BRACER", "팔찌", "BRACER", "INV_Bracer_07" },
}

Items.TYPES, Items.TYPE_ORDER = {}, {}
for index, t in ipairs(TYPES) do
    local def = { id = t[1], index = index, slot = t[2], name = t[3], curve = t[4], icon = t[5], baseOverride = t[6] }
    Items.TYPES[def.id] = def
    Items.TYPE_ORDER[index] = def.id
end

-- 연금술(아이템을 골드로) [원작]: 골드 = 등급 기본 골드 × 레벨 계수 × 종류 계수. 계수는 퍼밀.
Items.ALCHEMY_LEVEL = {
    [1] = 1000, [5] = 5000, [10] = 25000, [15] = 88000, [20] = 220000, [30] = 388000, [40] = 519000, [50] = 668000,
    [65] = 906000, [80] = 1120000, [90] = 1227000,
}
Items.ALCHEMY_CURVE = {
    SWORD = 1000, AXE = 1000, BOW = 1000, CROSSBOW = 1000, SCEPTER = 1000, STAFF = 1000,
    ARROW = 2000, ORB = 2000, SHIELD = 2000, BOLT = 2000, HATCHET = 2000, TOME = 2000,
    ARMOR = 1000, HELMET = 800, GLOVES = 750, BOOTS = 700, AMULET = 4000, EARING = 3000, RING = 3000, BRACER = 3000,
}

-- 아이템 레벨대의 이름 앞말 [독자]. 이름 = 앞말 + 종류 이름(예: "용병의 한손검"). 등급은 색과 표기로 구분한다.
Items.TIER_NAMES = {
    [1] = "낡은", [5] = "수습생의", [10] = "용병의", [15] = "정예병의", [20] = "기사단의", [30] = "용사의",
    [40] = "수호자의", [50] = "정복자의", [65] = "용군단의", [80] = "고대의", [90] = "티탄의",
}

return Items
