-- 인벤토리와 장비: 보관, 장착과 해제, 칸 구매, 연금술(골드로 바꾸기), 장비 능력치 시트.
-- 인벤토리는 계정 공용이다. 가득 차면 새로 얻은 아이템은 임시 보관함으로 간다(원작의 우편함 역할). [원작 구조]
-- 저장 형태: state.inventory = { items = { {id = 아이템 ID, lock = true?}, ... }, bought = 산 칸 수 }
--            state.mail = { {id = ...}, ... }, state.heroes[영웅].gear = { MAIN = {id = ...}, ... }

local _, WIH = ...
local Stats = WIH.module("Stats")
local Sheet = WIH.module("Sheet")
local Heroes = WIH.module("Heroes")
local Items = WIH.module("Items")
local Inventory = WIH.module("Inventory")

Inventory.FREE_SLOTS = 20       -- [원작]
Inventory.MAX_BOUGHT = 240      -- [원작] 인벤토리 260칸 중 무료 20칸을 뺀 나머지
Inventory.MAIL_LIMIT = 100      -- [독자] 임시 보관함의 한도. 넘으면 가장 오래된 것부터 골드로 바뀐다

-- 칸 구매 비용 [원작]: {그 번호 미만의 칸(0부터 셈), 비용}
local SLOT_COSTS = {
    { 20, 0 }, { 23, 50 }, { 27, 100 }, { 30, 200 }, { 34, 500 }, { 41, 1000 }, { 48, 5000 }, { 55, 10000 }, { 62, 20000 },
    { 69, 40000 }, { 76, 80000 }, { 83, 160000 }, { 90, 320000 }, { 97, 640000 }, { 104, 1280000 }, { 111, 2560000 },
    { 118, 5120000 }, { 260, 10240000 },
}

local function fail(reason) return false, reason end

-- 저장 데이터에 필요한 표가 없으면 만든다.
function Inventory.ensure(state)
    if type(state.inventory) ~= "table" then state.inventory = { items = {}, bought = 0 } end
    if type(state.inventory.items) ~= "table" then state.inventory.items = {} end
    if type(state.inventory.bought) ~= "number" then state.inventory.bought = 0 end
    if type(state.mail) ~= "table" then state.mail = {} end
    for _, h in pairs(state.heroes) do
        if type(h.gear) ~= "table" then h.gear = {} end
    end
    return state.inventory
end

function Inventory.capacity(state)
    local runeSlots = WIH.Runes and WIH.Runes.total(state, "MaxInventorySlot") or 0
    return Inventory.FREE_SLOTS + (state.inventory.bought or 0) + runeSlots
end

function Inventory.count(state) return #state.inventory.items end
function Inventory.free(state) return Inventory.capacity(state) - #state.inventory.items end

-- 다음에 살 칸의 비용. 더 살 수 없으면 nil.
function Inventory.nextSlotCost(state)
    local bought = state.inventory.bought or 0
    if bought >= Inventory.MAX_BOUGHT then return nil end
    local index = Inventory.FREE_SLOTS + bought        -- 0부터 센 칸 번호
    for _, row in ipairs(SLOT_COSTS) do
        if index < row[1] then return row[2] end
    end
    return nil
end

function Inventory.buySlot(state)
    local cost = Inventory.nextSlotCost(state)
    if not cost then return fail("더 살 수 있는 칸이 없습니다.") end
    if state.gold < cost then return fail("골드가 부족합니다.") end
    state.gold = state.gold - cost
    state.inventory.bought = state.inventory.bought + 1
    Inventory.claimMail(state)
    return true
end

-- 연금술로 얻는 골드 [원작]: 등급 기본 골드 × 레벨 계수 × 종류 계수 × (1 + 룬의 연금술 골드 %)
function Inventory.alchemyValue(state, item)
    local curve = Items.TYPES[item.type].curve
    local gold = Items.GRADES[item.grade].gold * Items.ALCHEMY_LEVEL[item.level] / 1000 * Items.ALCHEMY_CURVE[curve] / 1000
    local bonus = state and WIH.Runes and WIH.Runes.total(state, "CubeAlchemyGoldPercent") or 0
    return math.floor(gold * (1 + bonus / 1000) + 0.5)
end

-- 아이템을 얻는다. 인벤토리에 자리가 있으면 거기로, 없으면 임시 보관함으로 간다.
-- 돌려주는 값: "inventory" 또는 "mail", 만들어진 보관 항목
function Inventory.add(state, itemId)
    local item = Items.byId[itemId]
    if not item then return nil, "없는 아이템입니다." end
    local entry = { id = itemId }
    if Inventory.free(state) > 0 then
        table.insert(state.inventory.items, entry)
        return "inventory", entry
    end
    table.insert(state.mail, entry)
    -- 한도를 넘으면 가장 오래된 것을 골드로 바꾼다(잃어버리지는 않는다).
    while #state.mail > Inventory.MAIL_LIMIT do
        local old = table.remove(state.mail, 1)
        local oldItem = Items.byId[old.id]
        if oldItem then WIH.Game.addGold(state, Inventory.alchemyValue(state, oldItem)) end
    end
    return "mail", entry
end

-- 임시 보관함의 아이템을 자리가 나는 만큼 인벤토리로 옮긴다. 옮긴 수를 돌려준다.
function Inventory.claimMail(state)
    local moved = 0
    while #state.mail > 0 and Inventory.free(state) > 0 do
        table.insert(state.inventory.items, table.remove(state.mail, 1))
        moved = moved + 1
    end
    return moved
end

-- 인벤토리의 index번째 아이템을 영웅에게 장착한다. 끼고 있던 것은 그 자리로 돌아온다.
function Inventory.equip(state, heroId, index)
    local h = state.heroes[heroId]
    local entry = state.inventory.items[index]
    if not h then return fail("해금하지 않은 영웅입니다.") end
    if not entry then return fail("아이템이 없습니다.") end
    local item = Items.byId[entry.id]
    if not item then return fail("없는 아이템입니다.") end
    if not Items.usableBy(item, heroId) then
        return fail(Heroes.byId[heroId].name .. "은(는) " .. Items.TYPES[item.type].name .. "을(를) 쓸 수 없습니다.")
    end
    local old = h.gear[item.slot]
    h.gear[item.slot] = entry
    if old then
        state.inventory.items[index] = old
    else
        table.remove(state.inventory.items, index)
        Inventory.claimMail(state)
    end
    return true
end

function Inventory.unequip(state, heroId, slot)
    local h = state.heroes[heroId]
    if not h or not h.gear[slot] then return fail("그 칸에 장비가 없습니다.") end
    if Inventory.free(state) < 1 then return fail("인벤토리에 빈칸이 없습니다.") end
    table.insert(state.inventory.items, h.gear[slot])
    h.gear[slot] = nil
    return true
end

function Inventory.setLock(state, index, locked)
    local entry = state.inventory.items[index]
    if not entry then return fail("아이템이 없습니다.") end
    entry.lock = locked and true or nil
    return true
end

-- 연금술: 인벤토리의 아이템들을 골드로 바꾼다. indexes = 인벤토리 번호 목록. 잠근 아이템은 건너뛴다.
-- 돌려주는 값: 얻은 골드, 바꾼 개수
function Inventory.alchemy(state, indexes)
    local picked = {}
    for _, index in ipairs(indexes) do picked[index] = true end
    local gold, count = 0, 0
    for index = #state.inventory.items, 1, -1 do
        local entry = state.inventory.items[index]
        if picked[index] and not entry.lock then
            local item = Items.byId[entry.id]
            if item then gold = gold + Inventory.alchemyValue(state, item) end
            table.remove(state.inventory.items, index)
            count = count + 1
        end
    end
    if gold > 0 then WIH.Game.addGold(state, gold) end
    Inventory.claimMail(state)
    return gold, count
end

-- 정렬: 칸 순서 → 종류 → 레벨 높은 순 → 등급 높은 순
function Inventory.sort(state)
    local slotOrder = {}
    for i, slot in ipairs(Items.SLOTS) do slotOrder[slot] = i end
    table.sort(state.inventory.items, function(a, b)
        local ia, ib = Items.byId[a.id], Items.byId[b.id]
        if not ia or not ib then return ia ~= nil end
        if ia.slot ~= ib.slot then return slotOrder[ia.slot] < slotOrder[ib.slot] end
        if ia.type ~= ib.type then return Items.TYPES[ia.type].index < Items.TYPES[ib.type].index end
        if ia.level ~= ib.level then return ia.level > ib.level end
        if ia.grade ~= ib.grade then return ia.grade > ib.grade end
        return ia.id < ib.id
    end)
end

-- 영웅이 낀 장비 전부의 수정치 시트. 전투와 화면이 같은 시트를 쓴다.
function Inventory.gearSheet(state, heroId)
    local sheet = Sheet.new()
    local h = state.heroes[heroId]
    if not h or not h.gear then return sheet end
    for _, slot in ipairs(Items.SLOTS) do
        local entry = h.gear[slot]
        local item = entry and Items.byId[entry.id]
        if item then
            for _, mod in ipairs(item.mods) do Sheet.add(sheet, mod[1], mod[2], mod[3]) end
            for _, a in ipairs(entry.added or {}) do Sheet.add(sheet, a.stat, a.mod, a.value) end
        end
    end
    return sheet
end

-- 아이템 하나를 꼈을 때와 지금의 차이를 볼 수 있게, 그 칸에 낀 아이템을 돌려준다.
function Inventory.equipped(state, heroId, slot)
    local h = state.heroes[heroId]
    local entry = h and h.gear and h.gear[slot]
    return entry and Items.byId[entry.id] or nil, entry
end

-- 저장 데이터 검증: 없는 아이템, 잘못된 칸, 쓸 수 없는 장비를 고친다. 고친 내용을 notes에 적는다.
function Inventory.validate(state, notes)
    Inventory.ensure(state)
    local function note(text) notes[#notes + 1] = text end
    local inv = state.inventory
    inv.bought = math.max(0, math.min(Inventory.MAX_BOUGHT, math.floor(inv.bought)))
    local function cleanList(list, label)
        local removed = 0
        for i = #list, 1, -1 do
            local entry = list[i]
            if type(entry) ~= "table" or not Items.byId[entry.id] then
                table.remove(list, i)
                removed = removed + 1
            end
        end
        if removed > 0 then note(label .. "에서 알 수 없는 아이템 " .. removed .. "개를 지움") end
    end
    -- 배열이 아닌 키가 섞여 있으면 배열로 다시 만든다.
    local function asArray(list)
        local out = {}
        for _, v in pairs(list) do out[#out + 1] = v end
        return out
    end
    if #inv.items ~= (function() local n = 0 for _ in pairs(inv.items) do n = n + 1 end return n end)() then inv.items = asArray(inv.items) end
    if #state.mail ~= (function() local n = 0 for _ in pairs(state.mail) do n = n + 1 end return n end)() then state.mail = asArray(state.mail) end
    cleanList(inv.items, "인벤토리")
    cleanList(state.mail, "임시 보관함")
    for heroId, h in pairs(state.heroes) do
        for slot, entry in pairs(h.gear) do
            local item = type(entry) == "table" and Items.byId[entry.id] or nil
            if not item or item.slot ~= slot or not Items.usableBy(item, heroId) then
                h.gear[slot] = nil
                if item then table.insert(state.mail, entry) end      -- 낄 수 없는 장비는 버리지 않고 돌려준다
                note((Heroes.byId[heroId] and Heroes.byId[heroId].name or heroId) .. ": 잘못 낀 장비를 벗김")
            end
        end
    end
    -- 용량보다 많이 들어 있으면 넘는 것을 임시 보관함으로 옮긴다.
    local cap = Inventory.capacity(state)
    local moved = 0
    while #inv.items > cap do
        table.insert(state.mail, table.remove(inv.items))
        moved = moved + 1
    end
    if moved > 0 then note("인벤토리 용량을 넘는 아이템 " .. moved .. "개를 임시 보관함으로 옮김") end
end

return Inventory
