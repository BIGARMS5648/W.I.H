-- 재료의 이름과 아이콘 [독자]. 원작의 이름을 옮기지 않고 WoW 오리지널 분위기로 새로 지었다.
-- 이름은 재료 번호의 분류·등급·순번으로 정한다(번호 체계: 분류 + 등급 + 순번).

local _, WIH = ...
local Materials = WIH.module("Materials")

local CRAFT = {      -- [등급] = { 1번, 2번, 3번, 4번 }
    { "가벼운 목재", "거친 돌", "얇은 가죽", "구리 광석" },
    { "청동 주괴", "철 주괴" },
    { "은 주괴", "금 주괴" },
    { "별가루 주괴", "공허 철" },
    { "피돌", "천둥돌" },
    { "혼돈의 파편", "비전 광석" },
    { "검은무쇠 주괴", "진은 광석" },
    { "달빛석", "햇빛석" },
    { "미스릴 광석", "천상 주괴" },
    { "아다만타이트 광석", "영겁의 주괴" },
}
local GEM_QUALITY = { "흠 있는", "작은", "평범한", "빛나는", "완벽한", "찬란한", "고대의", "천상의", "신성한", "영원의" }
local GEMS = { "루비", "사파이어", "황수정", "에메랄드", "자수정" }
local PART_QUALITY = { "낡은", "질긴", "날카로운", "정예의", "고대의", "타락한", "용의", "티탄의", "신성한", "태초의" }
local PARTS = { "가죽 조각", "뼛조각", "점액", "송곳니", "거미줄" }
local GRADE_WORD = { "일반", "고급", "희귀", "전설", "불멸", "아르카나", "초월", "천상", "신성", "우주" }
local COIN = { "동전", "은화", "금화", "백금화", "정화", "비전 주화", "초월 주화", "천상 주화", "신성 주화", "영원의 주화" }
local DIFF = { "일반", "악몽", "지옥", "고통" }

local ICON = {
    CRAFTING = "INV_Ingot_03", DECORATION = "INV_Misc_Gem_Ruby_02", ENGRAVING = "INV_Misc_MonsterScales_08",
    INSCRIPTION = "INV_Scroll_05", SOULSTONE = "INV_Misc_Token_ArgentDawn3", OFFERING = "INV_Misc_Coin_17",
    ETC = "INV_Misc_Food_19", EVENTTICKET = "INV_Misc_Ticket_Tarot_Madness",
}
local GEM_ICON = { "INV_Misc_Gem_Ruby_02", "INV_Misc_Gem_Sapphire_02", "INV_Misc_Gem_Topaz_02", "INV_Misc_Gem_Emerald_02", "INV_Misc_Gem_Amethyst_02" }

local function nameOf(id, def)
    local grade, n = def.grade, id % 1000
    local k = def.kind
    if k == "CRAFTING" then
        local list = CRAFT[grade]
        return list and list[n] or ("제작 재료 " .. GRADE_WORD[grade]), n <= 1 and "INV_TradeskillItem_01" or "INV_Ingot_03"
    elseif k == "DECORATION" then
        local gem = GEMS[(n - 1) % #GEMS + 1]
        return GEM_QUALITY[grade] .. " " .. gem, GEM_ICON[(n - 1) % #GEMS + 1]
    elseif k == "ENGRAVING" then
        return PART_QUALITY[grade] .. " " .. PARTS[(n - 1) % #PARTS + 1], "INV_Misc_MonsterScales_08"
    elseif k == "INSCRIPTION" then
        return GRADE_WORD[grade] .. " 각인 두루마리", "INV_Scroll_05"
    elseif k == "SOULSTONE" then
        local d = id % 10
        if math.floor(id / 100) == 1901 then return "오염된 용사의 증표 (" .. DIFF[d] .. ")", "INV_Misc_Token_ScarletCrusade" end
        return "용사의 증표 (" .. DIFF[d] .. ")", "INV_Misc_Token_ArgentDawn3"
    elseif k == "OFFERING" then
        local family = math.floor(id / 1000)
        if family == 160 and n <= 10 then return "공물 " .. COIN[grade], "INV_Misc_Coin_17" end
        if family == 160 then return GRADE_WORD[grade] .. " 호박 사탕", "INV_Misc_Food_30" end
        if family == 161 then return "오염된 유물함 (" .. GRADE_WORD[grade] .. ")", "INV_Box_02" end
        if family == 162 then return "오염된 유물 (" .. GRADE_WORD[grade] .. ")", "INV_Misc_Gem_Variety_02" end
    elseif k == "ETC" then
        return "역병 열매 (" .. GRADE_WORD[grade] .. ")", "INV_Misc_Food_19"
    elseif k == "EVENTTICKET" then
        return "행사 입장권 (" .. DIFF[(id % 10) + 1] .. ")", ICON.EVENTTICKET
    end
    return "재료 " .. id, ICON[k] or "INV_Misc_QuestionMark"
end

for id, def in pairs(Materials.defs) do
    def.name, def.icon = nameOf(id, def)
end

function Materials.name(id)
    local def = Materials.defs[id]
    return def and def.name or "알 수 없는 재료"
end

return Materials
