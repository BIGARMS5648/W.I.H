-- 아이템 표: 곡선(원작 수치)과 종류 정의를 합쳐 이 프로젝트의 장비 전부를 만든다.
-- 장비는 (종류, 아이템 레벨, 등급, 변형)마다 하나이고 능력치가 고정이다. 드롭할 때 굴리지 않는다. [원작]
-- 아이템 ID = 종류 번호 × 1,000,000 + 레벨 × 1,000 + 등급 × 10 + 변형. 저장 데이터에는 이 ID가 들어간다.

local _, WIH = ...
local Stats = WIH.module("Stats")
local Heroes = WIH.module("Heroes")
local ItemTable = WIH.module("ItemTable")
local Items = WIH.module("Items")

Items.byId = {}
Items.byType = {}          -- [종류][레벨][등급] = { 아이템, ... }(변형 순)
Items.count = 0

local function makeId(typeIndex, level, grade, variant)
    return typeIndex * 1000000 + level * 1000 + grade * 10 + variant
end
Items.makeId = makeId

for _, typeId in ipairs(Items.TYPE_ORDER) do
    local t = Items.TYPES[typeId]
    local rows = ItemTable.curves[t.curve]
    local baseDef = ItemTable.BASE[t.curve]
    assert(rows and baseDef, "곡선이 없음: " .. tostring(t.curve))
    Items.byType[typeId] = {}
    for _, row in ipairs(rows) do
        local level, grade, variant = row[1], row[2], row[3]
        local mods = {}
        -- 기본 능력치
        for i, b in ipairs(baseDef) do
            local stat, kind, value = b[1], b[2], row[3 + i]
            if i == 1 and t.baseOverride then
                stat, kind = t.baseOverride[1], t.baseOverride[2]
                value = math.floor(value * t.baseOverride[3] + 0.5)
            end
            mods[#mods + 1] = { stat, kind, value, base = true }
        end
        -- 고정 능력치
        for i = 6, #row, 3 do
            mods[#mods + 1] = { row[i], row[i + 1], row[i + 2] }
        end
        local item = {
            id = makeId(t.index, level, grade, variant), type = typeId, slot = t.slot, level = level, grade = grade,
            variant = variant, mods = mods, icon = t.icon,
        }
        assert(not Items.byId[item.id], "아이템 ID 중복: " .. item.id)
        Items.byId[item.id] = item
        local byLevel = Items.byType[typeId]
        byLevel[level] = byLevel[level] or {}
        byLevel[level][grade] = byLevel[level][grade] or {}
        byLevel[level][grade][variant] = item
        Items.count = Items.count + 1
    end
end

function Items.get(id) return Items.byId[id] end

function Items.find(typeId, level, grade, variant)
    local a = Items.byType[typeId]
    a = a and a[level]
    a = a and a[grade]
    return a and a[variant or 1] or nil
end

function Items.name(item)
    return (Items.TIER_NAMES[item.level] or "") .. " " .. Items.TYPES[item.type].name
end

function Items.gradeName(item) return Items.GRADES[item.grade].name end

-- 그 영웅이 낄 수 있는지: 주무기·보조무기는 종류가 맞아야 하고, 나머지는 누구나 낀다. [원작]
function Items.usableBy(item, heroId)
    local hero = Heroes.byId[heroId]
    if not hero then return false end
    if item.slot == "MAIN" then return hero.main == item.type end
    if item.slot == "SUB" then return hero.sub == item.type end
    return true
end

-- 수정치 한 줄의 표기(툴팁용). 전투가 쓰는 것과 같은 표에서 만든다.
function Items.modText(mod)
    local stat, kind, raw = mod[1], mod[2], mod[3]
    local d = Stats.defs[stat]
    local label = d and d.label or stat
    local function num(v)
        if math.abs(v - math.floor(v + 0.5)) < 1e-6 then return tostring(math.floor(v + 0.5)) end
        return (string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", ""))
    end
    if kind == Stats.FLAT then
        local v, unit = raw, ""
        if d.scale == 1000 then v, unit = raw / 10, "%"
        elseif d.scale == 100 then v = raw / 100
        elseif d.scale == 10 then v = raw / 10 end
        return label .. " +" .. num(v) .. unit
    end
    return label .. " +" .. num(raw / 10) .. "% " .. (kind == Stats.INC and "증가" or "곱")
end

return Items
