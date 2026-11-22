-- 영웅의 겉모습: 종족·성별과, 낀 장비에 따라 입히는 옷과 무기.
-- 이 게임의 장비는 독자 아이템이라 겉모습이 없다. 그래서 장비의 (종류, 아이템 레벨대)에 클라이언트에 들어 있는 실제 아이템의
-- 겉모습을 대응시킨다. 등급에 따른 겉모습 차이는 두지 않는다.
--   · 투구 → 머리. 갑옷 → 가슴·어깨·다리(한 벌). 장갑 → 손. 신발 → 발. 주무기·보조무기(방패, 보조 무기) → 손에 든 것.
--   · 장신구와 그 밖의 보조무기(화살통, 보주, 고서 등)는 겉모습에 나타나지 않는다.
--   · 갑옷을 끼지 않았으면 기본 옷을 입는다(맨몸으로 두지 않는다).
-- 아이템 번호는 오리지널의 것을 기억에 의존해 적었다. 틀린 번호는 다른 옷이 보이거나 아무것도 보이지 않는다.
-- 부위가 잘못 적힌 것은 클라이언트에 아이템 정보를 물어 바로잡는다(물을 수 있을 때). 게임 내 확인이 필요하다.

local _, WIH = ...
local Heroes = WIH.module("Heroes")
local Items = WIH.module("Items")
local Models = WIH.module("Models")
local Looks = WIH.module("Looks")

-- 종족 번호: 1 인간, 2 오크, 3 드워프, 4 나이트 엘프, 5 언데드, 6 타우렌, 7 노움, 8 트롤, 9 고블린, 10 블러드 엘프, 11 드레나이
-- [영웅] = { {얼라이언스 종족, 성별}, {호드 종족, 성별} }. 성별: 0 남, 1 여 [독자]
Looks.RACE = {
    war_arms = { { 1, 0 }, { 2, 0 } }, war_fury = { { 1, 1 }, { 8, 0 } }, war_prot = { { 3, 0 }, { 6, 0 } },
    pal_holy = { { 1, 1 }, { 10, 1 } }, pal_prot = { { 3, 0 }, { 10, 0 } }, pal_ret = { { 1, 0 }, { 6, 0 } },
    hun_bm = { { 4, 1 }, { 2, 1 } }, hun_mm = { { 3, 0 }, { 8, 1 } }, hun_sv = { { 4, 0 }, { 6, 1 } },
    rog_assa = { { 1, 1 }, { 5, 0 } }, rog_combat = { { 7, 0 }, { 2, 0 } }, rog_sub = { { 4, 1 }, { 8, 0 } },
    pri_disc = { { 1, 0 }, { 5, 1 } }, pri_holy = { { 1, 1 }, { 8, 1 } }, pri_shadow = { { 3, 1 }, { 5, 0 } },
    sha_ele = { { 11, 0 }, { 2, 0 } }, sha_enh = { { 3, 0 }, { 6, 0 } }, sha_resto = { { 11, 1 }, { 8, 1 } },
    mag_arcane = { { 7, 1 }, { 5, 1 } }, mag_fire = { { 1, 0 }, { 8, 0 } }, mag_frost = { { 1, 1 }, { 10, 1 } },
    wlk_aff = { { 1, 1 }, { 5, 1 } }, wlk_demo = { { 7, 0 }, { 2, 1 } }, wlk_destro = { { 1, 0 }, { 5, 0 } },
    dru_balance = { { 4, 1 }, { 6, 1 } }, dru_feral = { { 4, 0 }, { 6, 0 } }, dru_resto = { { 4, 1 }, { 6, 1 } },
    tin_armor = { { 7, 0 }, { 9, 0 } }, tin_destroy = { { 7, 1 }, { 9, 1 } }, tin_medic = { { 3, 1 }, { 9, 0 } },
}

-- 직업이 입는 방어구 계열 [독자: 땜장이는 가죽]
Looks.ARMOR_CLASS = {
    WARRIOR = "PLATE", PALADIN = "PLATE", HUNTER = "MAIL", SHAMAN = "MAIL", ROGUE = "LEATHER", DRUID = "LEATHER", TINKER = "LEATHER",
    PRIEST = "CLOTH", MAGE = "CLOTH", WARLOCK = "CLOTH",
}

-- 아이템 레벨 → 겉모습 단계(1~6)
Looks.TIER = { [1] = 1, [5] = 1, [10] = 1, [15] = 2, [20] = 2, [30] = 3, [40] = 3, [50] = 4, [65] = 5, [80] = 6, [90] = 6 }
Looks.TIER_NAMES = { "레벨 1~10", "레벨 15~20", "레벨 30~40", "레벨 50", "레벨 65", "레벨 80~90" }

-- 낮은 단계(1, 2)는 방어구 계열별 공용 옷. 한 벌 = { head, shoulder, chest, legs, hands, feet }
local GENERIC = {
    CLOTH = {
        { chest = 2121, legs = 2120, hands = 2119, feet = 2117 },
        { chest = 6238, shoulder = 4314, legs = 4316, hands = 4307, feet = 2569 },
    },
    LEATHER = {
        { chest = 2127, legs = 2126, hands = 2125, feet = 2123 },
        { chest = 2317, shoulder = 4252, legs = 5961, hands = 4248, feet = 2315 },
    },
    MAIL = {
        { chest = 1737, legs = 1735, hands = 1734, feet = 1731 },
        { head = 3836, shoulder = 3840, chest = 3844, legs = 3842, hands = 3485, feet = 3484 },
    },
}
GENERIC.PLATE = GENERIC.MAIL

-- 높은 단계(3~6)는 직업별 옷
local CLASS_SETS = {
    WARRIOR = {
        { head = 16731, shoulder = 16733, chest = 16730, legs = 16732, hands = 16737, feet = 16734 },
        { head = 16866, shoulder = 16868, chest = 16865, legs = 16867, hands = 16863, feet = 16862 },
        { head = 16963, shoulder = 16961, chest = 16966, legs = 16962, hands = 16964, feet = 16965 },
        { head = 22418, shoulder = 22419, chest = 22416, legs = 22417, hands = 22421, feet = 22420 },
    },
    PALADIN = {
        { head = 16727, shoulder = 16729, chest = 16726, legs = 16728, hands = 16724, feet = 16725 },
        { head = 16854, shoulder = 16856, chest = 16853, legs = 16855, hands = 16860, feet = 16859 },
        { head = 16955, shoulder = 16953, chest = 16958, legs = 16954, hands = 16956, feet = 16957 },
        { head = 22428, shoulder = 22429, chest = 22425, legs = 22427, hands = 22426, feet = 22430 },
    },
    HUNTER = {
        { head = 16677, shoulder = 16679, chest = 16674, legs = 16678, hands = 16676, feet = 16675 },
        { head = 16846, shoulder = 16848, chest = 16845, legs = 16847, hands = 16852, feet = 16849 },
        { head = 16939, shoulder = 16937, chest = 16942, legs = 16938, hands = 16940, feet = 16941 },
        { head = 22438, shoulder = 22439, chest = 22436, legs = 22437, hands = 22441, feet = 22440 },
    },
    ROGUE = {
        { head = 16707, shoulder = 16708, chest = 16721, legs = 16709, hands = 16712, feet = 16711 },
        { head = 16821, shoulder = 16823, chest = 16820, legs = 16822, hands = 16826, feet = 16824 },
        { head = 16908, shoulder = 16832, chest = 16905, legs = 16909, hands = 16907, feet = 16906 },
        { head = 22478, shoulder = 22479, chest = 22476, legs = 22477, hands = 22481, feet = 22480 },
    },
    PRIEST = {
        { head = 16693, shoulder = 16695, chest = 16690, legs = 16694, hands = 16692, feet = 16691 },
        { head = 16813, shoulder = 16816, chest = 16815, legs = 16814, hands = 16812, feet = 16811 },
        { head = 16921, shoulder = 16924, chest = 16923, legs = 16922, hands = 16920, feet = 16919 },
        { head = 22514, shoulder = 22515, chest = 22512, legs = 22513, hands = 22517, feet = 22516 },
    },
    SHAMAN = {
        { head = 16667, shoulder = 16669, chest = 16666, legs = 16668, hands = 16672, feet = 16670 },
        { head = 16842, shoulder = 16844, chest = 16841, legs = 16843, hands = 16839, feet = 16837 },
        { head = 16947, shoulder = 16945, chest = 16950, legs = 16946, hands = 16948, feet = 16949 },
        { head = 22466, shoulder = 22467, chest = 22464, legs = 22465, hands = 22469, feet = 22468 },
    },
    MAGE = {
        { head = 16686, shoulder = 16689, chest = 16688, legs = 16687, hands = 16684, feet = 16682 },
        { head = 16795, shoulder = 16797, chest = 16798, legs = 16796, hands = 16801, feet = 16800 },
        { head = 16914, shoulder = 16917, chest = 16916, legs = 16915, hands = 16913, feet = 16912 },
        { head = 22498, shoulder = 22499, chest = 22496, legs = 22497, hands = 22501, feet = 22500 },
    },
    WARLOCK = {
        { head = 16698, shoulder = 16701, chest = 16700, legs = 16704, hands = 16705, feet = 16699 },
        { head = 16808, shoulder = 16807, chest = 16809, legs = 16810, hands = 16805, feet = 16803 },
        { head = 16929, shoulder = 16932, chest = 16931, legs = 16930, hands = 16928, feet = 16927 },
        { head = 22506, shoulder = 22507, chest = 22504, legs = 22505, hands = 22509, feet = 22508 },
    },
    DRUID = {
        { head = 16720, shoulder = 16718, chest = 16706, legs = 16719, hands = 16717, feet = 16715 },
        { head = 16834, shoulder = 16836, chest = 16833, legs = 16835, hands = 16831, feet = 16829 },
        { head = 16900, shoulder = 16902, chest = 16897, legs = 16901, hands = 16899, feet = 16898 },
        { head = 22490, shoulder = 22491, chest = 22488, legs = 22489, hands = 22493, feet = 22492 },
    },
}
CLASS_SETS.TINKER = CLASS_SETS.ROGUE       -- 땜장이 전용 옷은 오리지널에 없으므로 가죽 한 벌을 빌린다 [독자]

-- 갑옷·신발을 끼지 않았을 때의 기본 옷
local BASE_CLOTHES = {
    CLOTH = { chest = 56, feet = 55 }, LEATHER = { chest = 49, legs = 48, feet = 47 },
    MAIL = { chest = 38, legs = 39, feet = 40 }, PLATE = { chest = 38, legs = 39, feet = 40 },
}

-- 무기의 겉모습: [종류] = 단계 1~6의 아이템 번호
Looks.WEAPONS = {
    SWORD = { 25, 5191, 12940, 17103, 19352, 23054 },
    GREATSWORD = { 2754, 6975, 12592, 17076, 19364, 22691 },
    AXE = { 37, 811, 13015, 17068, 19363, 21242 },
    MACE = { 36, 936, 11684, 17105, 19360, 23056 },
    DAGGER = { 2092, 1935, 14555, 17071, 19346, 22802 },
    BOW = { 2504, 2825, 18680, 17069, 19350, 22811 },
    CROSSBOW = { 15807, 15808, 13040, 18738, 19361, 22812 },
    GUN = { 2508, 4369, 15995, 17072, 19853, 22810 },
    STAFF = { 35, 5201, 943, 18842, 19356, 22589 },
    WAND = { 5069, 5347, 11289, 17077, 19861, 22820 },
    TOOL = { 6219, 6219, 10498, 10498, 6219, 10498 },
    -- 보조무기 가운데 손에 드는 것
    SHIELD = { 2362, 6223, 12602, 17066, 19349, 22818 },
    OFFHAND = { 2092, 1935, 12939, 18832, 19351, 23577 },
}
Looks.OFFHAND_WEAPON = { OFFHAND = true }       -- 왼손에 드는 무기(오른손 무기와 구분해서 입힌다)

-- 한 벌의 부위를 클라이언트의 아이템 정보로 바로잡는다(물을 수 있을 때만). 한 번 바로잡은 벌은 다시 묻지 않는다.
local SLOT_OF = {
    INVTYPE_HEAD = "head", INVTYPE_SHOULDER = "shoulder", INVTYPE_CHEST = "chest", INVTYPE_ROBE = "chest",
    INVTYPE_LEGS = "legs", INVTYPE_HAND = "hands", INVTYPE_FEET = "feet",
}
local function instantInfo(itemId)
    local fn = (C_Item and C_Item.GetItemInfoInstant) or GetItemInfoInstant
    if not fn then return nil end
    local ok, _, _, _, equipLoc = pcall(fn, itemId)
    return ok and equipLoc or nil
end
local function corrected(set)
    if set.checked then return set end
    set.checked = true
    local fixed, any = {}, false
    for slot, itemId in pairs(set) do
        if type(itemId) == "number" then
            local real = SLOT_OF[instantInfo(itemId) or ""]
            if real then any = true end
            fixed[real or slot] = itemId
        end
    end
    if any then
        for _, slot in ipairs({ "head", "shoulder", "chest", "legs", "hands", "feet" }) do set[slot] = fixed[slot] end
    end
    return set
end

-- 그 직업의 그 단계 옷 한 벌
function Looks.set(class, tier)
    local set
    if tier <= 2 then set = GENERIC[Looks.ARMOR_CLASS[class]][tier] else set = CLASS_SETS[class][tier - 2] end
    return corrected(set)
end

-- 영웅의 겉모습. 돌려주는 값: { race, sex, items = {아이템 번호…}, offhand = 왼손 무기 번호, key = 달라졌는지 비교할 문자열 }
-- 야성 드루이드처럼 형태가 있는 영웅은 nil(형태의 생물 모델을 쓴다).
function Looks.forHero(state, heroId)
    local hero, h = Heroes.byId[heroId], state.heroes[heroId]
    if not hero or not Looks.RACE[heroId] then return nil end
    local form = hero.forms and (h and h.form or hero.defaultForm) or nil
    if form and Models.FORMS[form] then return nil end
    local pair = Looks.RACE[heroId][state.faction == "Horde" and 2 or 1]
    local armorClass = Looks.ARMOR_CLASS[hero.class]
    local base = BASE_CLOTHES[armorClass]
    local gear = h and h.gear or {}
    local function tierOf(slot)
        local entry = gear[slot]
        local item = entry and Items.byId[entry.id]
        return item and Looks.TIER[item.level] or nil, item
    end
    local items = {}
    local function add(itemId) if itemId then items[#items + 1] = itemId end end
    local t = tierOf("ARMOR")
    if t then
        local set = Looks.set(hero.class, t)
        add(set.chest); add(set.shoulder); add(set.legs)
    else
        add(base.chest); add(base.legs)
    end
    t = tierOf("HELMET"); if t then add(Looks.set(hero.class, t).head) end
    t = tierOf("GLOVES"); if t then add(Looks.set(hero.class, t).hands) end
    t = tierOf("BOOTS")
    if t then add(Looks.set(hero.class, t).feet) else add(base.feet) end
    local item
    t, item = tierOf("MAIN")
    if t and Looks.WEAPONS[item.type] then add(Looks.WEAPONS[item.type][t]) end
    local offhand
    t, item = tierOf("SUB")
    if t and Looks.WEAPONS[item.type] then
        if Looks.OFFHAND_WEAPON[item.type] then offhand = Looks.WEAPONS[item.type][t] else add(Looks.WEAPONS[item.type][t]) end
    end
    return { race = pair[1], sex = pair[2], items = items, offhand = offhand,
        key = pair[1] .. ":" .. pair[2] .. ":" .. table.concat(items, ",") .. ":" .. tostring(offhand) }
end

return Looks
