-- 큐브: 합성, 연금술, 제작, 장식·세공·각인, 제거, 기원. 수치는 원작 표(Data/CubeTable.lua)다.
-- 강화(+N)·옵션 재추첨·분해는 원작에 없으므로 없다.
-- 저장 형태: state.cube = { level, exp, unlocked = { ["종류:단계"] = true } }
--   장비에 붙인 능력치: 인벤토리 항목 entry.added = { { kind = "DECORATION"|"ENGRAVING"|"INSCRIPTION", stat, mod, value, tier }, ... }

local _, WIH = ...
local Items = WIH.module("Items")
local Materials = WIH.module("Materials")
local CubeTable = WIH.module("CubeTable")
local Inventory = WIH.module("Inventory")
local Chests = WIH.module("Chests")
local Cube = WIH.module("Cube")

Cube.MAX_LEVEL = 100
Cube.SLOTS = 9
Cube.LEVEL_GAP = 21          -- [원작 1.02.00] 큐브 레벨보다 21레벨 넘게 높은 장비는 연금술에 쓸 수 없다
Cube.KINDS = { "SYNTHESIS", "ALCHEMY", "CRAFTING", "DECORATION", "ENGRAVING", "INSCRIPTION", "EXTRACTION", "OFFERING" }
Cube.NAMES = { SYNTHESIS = "합성", ALCHEMY = "연금술", CRAFTING = "제작", DECORATION = "장식", ENGRAVING = "세공",
    INSCRIPTION = "각인", EXTRACTION = "제거", OFFERING = "기원" }
Cube.SLOT_FIELD = { DECORATION = "decor", ENGRAVING = "engrave", INSCRIPTION = "inscribe" }
local GEAR_GROUP = { MAIN = "WEAPON", SUB = "WEAPON", HELMET = "ARMOR", ARMOR = "ARMOR", GLOVES = "ARMOR", BOOTS = "ARMOR",
    AMULET = "ACCESSORY", EARRING = "ACCESSORY", RING = "ACCESSORY", BRACER = "ACCESSORY" }
Cube.GEAR_GROUP = GEAR_GROUP
local LEVELS = WIH.ItemTable.LEVELS

local function fail(reason) return false, reason end

-- 레시피 목록: Cube.recipes[번호] = { kind, tier, level, cost, material, fee, table }
Cube.recipes = {}
for i, r in ipairs(CubeTable.SUB) do
    Cube.recipes[i] = { kind = r[1], tier = r[2], level = r[3], cost = r[4], material = r[5], fee = r[6], table = r[7] }
end
-- 합성·제작 Lv90 단계 [독자: 원작 1.2.0 추가분은 해금 조건·확률이 확인되지 않았다]
Cube.recipes[#Cube.recipes + 1] = { kind = "SYNTHESIS", tier = 9, level = 80, cost = 15000 }
Cube.recipes[#Cube.recipes + 1] = { kind = "CRAFTING", tier = 9, level = 90, cost = 50000 }
local function keyOf(r) return r.kind .. ":" .. tostring(r.tier or r.material or 0) end
Cube.keyOf = keyOf

-- 결과 표 찾기: [분류][등급][레벨] (원작 표는 단계마다 처음 나오는 레벨에 한 번씩 적혀 있다)
local dropIndex = {}
for kind, tiers in pairs(CubeTable.SYNTH_DROP) do
    dropIndex[kind] = {}
    for _, grades in pairs(tiers) do
        for grade, levels in pairs(grades) do
            dropIndex[kind][grade] = dropIndex[kind][grade] or {}
            for level, id in pairs(levels) do dropIndex[kind][grade][level] = dropIndex[kind][grade][level] or id end
        end
    end
end
-- Lv90 결과 표 [독자]: Lv80의 표에서 레벨만 90으로 바꾼 것
local function lift(id)
    local out = {}
    for i, e in ipairs(CubeTable.tables[id]) do out[i] = e[2] == "MAT" and e or { e[1], e[2], 90, e[4] } end
    CubeTable.tables[#CubeTable.tables + 1] = out
    return #CubeTable.tables
end
for _, kind in ipairs({ "Gear", "Accessory" }) do
    for grade, levels in pairs(dropIndex[kind]) do
        if levels[80] and not levels[90] then levels[90] = lift(levels[80]) end
    end
end
for _, part in ipairs({ "MAIN", "SUB", "HELMET", "ARMOR", "GLOVES", "BOOTS", "ACC" }) do
    local t8 = CubeTable.CRAFT[part][8]
    CubeTable.CRAFT[part][9] = { mats = t8.mats, table = lift(t8.table) }
end
-- 합성 9단계: 8단계와 같은 모양으로 결과 레벨 80~90 [독자]
for _, kind in ipairs({ "Gear", "Accessory" }) do
    local t8 = CubeTable.SYNTH[kind][8]
    local t9 = {}
    for grade, rows in pairs(t8) do
        t9[grade] = { { 65, 80, 90, 300, 100, 0, 0 }, { 75, 80, 90, 200, 200, 0, 0 }, { 85, 80, 90, 100, 300, 0, 0 } }
    end
    CubeTable.SYNTH[kind][9] = t9
end

function Cube.ensure(state)
    if type(state.cube) ~= "table" then state.cube = {} end
    local c = state.cube
    if type(c.level) ~= "number" or c.level < 1 then c.level = 1 end
    if type(c.exp) ~= "number" or c.exp ~= c.exp or c.exp < 0 then c.exp = 0 end
    if type(c.unlocked) ~= "table" then c.unlocked = {} end
    -- 처음부터 열려 있는 것: 합성 1단계 [원작], 연금술 [독자: 원작은 큐브 Lv1·10골드. 가방의 '팔기'가 연금술이므로 처음부터 연다]
    c.unlocked["SYNTHESIS:1"] = true
    c.unlocked["ALCHEMY:0"] = true
    return c
end

function Cube.unlocked(state, recipe) return state.cube.unlocked[keyOf(recipe)] == true end

-- 레시피 해금: 큐브 레벨과 1회 비용 [원작]. 기원은 한 번 열면 모든 주화가 열린다.
function Cube.unlock(state, recipe)
    if Cube.unlocked(state, recipe) then return fail("이미 열린 레시피입니다.") end
    if state.cube.level < recipe.level then return fail("큐브 레벨 " .. recipe.level .. "이 되어야 열 수 있습니다.") end
    if state.gold < recipe.cost then return fail("골드가 부족합니다.") end
    state.gold = state.gold - recipe.cost
    if recipe.kind == "OFFERING" then
        for _, r in ipairs(Cube.recipes) do if r.kind == "OFFERING" then state.cube.unlocked[keyOf(r)] = true end end
    else
        state.cube.unlocked[keyOf(recipe)] = true
    end
    return true
end

function Cube.find(kind, tier)
    for _, r in ipairs(Cube.recipes) do
        if r.kind == kind and (tier == nil or r.tier == tier) then return r end
    end
end

------------------------------------------------------------------------
-- 큐브 경험치 [원작 식: 조사 보고서 03 2.4절]
------------------------------------------------------------------------

-- 큐브 레벨과 아이템 레벨이 가까울수록 1에 가깝다 [추정: 팬 사이트가 복원한 식]
function Cube.levelMatch(c, t)
    local below = t <= c
    local r, i, a = below and 2 or 5, below and 5 or 6, below and 0.5 or 0.4
    local o = math.log(c + 1)
    local s = math.floor((o / 10 + 1) * r)
    local k = math.floor((o / 10 + 1) * i)
    local d = math.abs(c - t)
    if d <= s then return 1 end
    local u = d - s - k
    if u <= 0 then
        local x = (d - s) / k
        return 1 - (1 - a) * x * x
    end
    return a * (0.01 / a) ^ (u / math.max(c / 3, 3))
end

function Cube.itemExp(state, item)
    local curve = Items.TYPES[item.type].curve
    local base = math.floor(CubeTable.GRADE_EXP[item.grade] * CubeTable.EXP_LEVEL[item.level] / 1000 * Items.ALCHEMY_CURVE[curve] / 1000)
    local bonus = WIH.Runes.total(state, "CubeExpPercent")
    return base * Cube.levelMatch(state.cube.level, item.level) * (1 + bonus / 1000)
end

function Cube.materialExp(state, id)
    local def = Materials.defs[id]
    return CubeTable.GRADE_EXP[def.grade] * 12 * (1 + WIH.Runes.total(state, "CubeExpPercent") / 1000)
end

-- 경험치를 더하고 오른 레벨 수를 돌려준다.
function Cube.addExp(state, amount)
    local c = state.cube
    c.exp = c.exp + amount
    local ups = 0
    while c.level < Cube.MAX_LEVEL and c.exp >= CubeTable.LEVEL_EXP[c.level] do
        c.exp = c.exp - CubeTable.LEVEL_EXP[c.level]
        c.level = c.level + 1
        ups = ups + 1
    end
    if c.level >= Cube.MAX_LEVEL then c.exp = 0 end
    return ups
end

function Cube.expToNext(state) return CubeTable.LEVEL_EXP[state.cube.level] end

------------------------------------------------------------------------
-- 연금술: 가방의 팔기. 골드와 큐브 경험치를 준다.
------------------------------------------------------------------------

function Cube.canAlchemize(state, item)
    return item.level <= state.cube.level + Cube.LEVEL_GAP
end

function Cube.alchemy(state, indexes)
    local picked, exp = {}, 0
    for _, index in ipairs(indexes) do
        local entry = state.inventory.items[index]
        local item = entry and Items.byId[entry.id]
        if item and not entry.lock and Cube.canAlchemize(state, item) then
            picked[#picked + 1] = index
            exp = exp + Cube.itemExp(state, item)
        end
    end
    local gold, n = Inventory.alchemy(state, picked)
    local ups = n > 0 and Cube.addExp(state, exp) or 0
    return gold, n, ups, #indexes - #picked
end

------------------------------------------------------------------------
-- 부식: 연금술처럼 아이템을 넣되 골드 대신 원정 보급품을 얻는다 [원작 규칙 1.2.0]
--   수치 [추정: 조사 보고서 03 9절의 관찰값과 역산]. 장비 = 등급 기본값 × 부위 계수(연금술과 같은 계수), 레벨은 반영하지 않는다.
--   재료 1개 = 등급 값. 역병 열매는 재료 값의 5배 [독자]. 큐브 레벨 + 21을 넘는 아이템은 넣을 수 없다 [원작].
--   보급품이 가득 차면 거기서 멈추고 남은 아이템은 쓰지 않는다 [독자]. 큐브 경험치는 연금술과 같게 준다 [추정].
--   열리는 조건: 원정이 하나라도 열렸을 때 [독자: 원작의 해금 조건 미확인]
------------------------------------------------------------------------

Cube.NAMES.CORROSION = "부식"
Cube.CORRODE_GEAR = { 2, 2, 3, 4, 6, 8, 12, 16, 24, 32 }
Cube.CORRODE_MAT = { 2, 3, 4, 6, 8, 12, 16, 24, 32, 48 }
Cube.FRUIT_MULT = 5

function Cube.corrosionUnlocked(state)
    for d = 2, 4 do
        if WIH.Expeditions.unlocked(state, d) then return true end
    end
    return false
end

function Cube.corrodeValue(item)
    local curve = Items.TYPES[item.type].curve
    return math.max(1, math.floor(Cube.CORRODE_GEAR[item.grade] * Items.ALCHEMY_CURVE[curve] / 1000 + 0.5))
end

function Cube.corrodeMaterialValue(id)
    local def = Materials.defs[id]
    if not def or def.kind == "SOULSTONE" then return nil end
    local v = Cube.CORRODE_MAT[def.grade]
    if def.kind == "ETC" then v = v * Cube.FRUIT_MULT end
    return v
end

local function supplyRoom(state)
    return WIH.Expeditions.SUPPLY_MAX - state.supply
end

-- 장비 부식. 돌려주는 값: 얻은 보급품, 쓴 개수, 오른 큐브 레벨 수
function Cube.corrode(state, indexes)
    if not Cube.corrosionUnlocked(state) then return fail("원정이 열리면 쓸 수 있습니다.") end
    if supplyRoom(state) < 1 then return fail("원정 보급품이 가득 찼습니다.") end
    local order = {}
    for _, index in ipairs(indexes) do order[#order + 1] = index end
    table.sort(order, function(a, b) return a > b end)
    local gained, used, exp = 0, 0, 0
    for _, index in ipairs(order) do
        if supplyRoom(state) < 1 then break end
        local entry = state.inventory.items[index]
        local item = entry and Items.byId[entry.id]
        if item and not entry.lock and Cube.canAlchemize(state, item) then
            local v = Cube.corrodeValue(item)
            local add = math.min(v, supplyRoom(state))
            state.supply = state.supply + add
            gained = gained + add
            exp = exp + Cube.itemExp(state, item)
            table.remove(state.inventory.items, index)
            used = used + 1
        end
    end
    if used == 0 then return fail("넣을 수 있는 장비가 없습니다(잠금, 레벨 제한).") end
    Inventory.claimMail(state)
    return gained, used, Cube.addExp(state, exp)
end

-- 재료 부식: 보급품이 차는 만큼만 쓴다.
function Cube.corrodeMaterial(state, id, count)
    if not Cube.corrosionUnlocked(state) then return fail("원정이 열리면 쓸 수 있습니다.") end
    local v = Cube.corrodeMaterialValue(id)
    if not v then return fail("부식에 쓸 수 없는 재료입니다.") end
    local have = state.materials[id] or 0
    if have <= 0 then return fail("재료가 없습니다.") end
    if supplyRoom(state) < 1 then return fail("원정 보급품이 가득 찼습니다.") end
    count = math.min(count or have, have, math.ceil(supplyRoom(state) / v))
    local add = math.min(v * count, supplyRoom(state))
    state.supply = state.supply + add
    state.materials[id] = have - count
    if state.materials[id] <= 0 then state.materials[id] = nil end
    return add, count, Cube.addExp(state, Cube.materialExp(state, id) * count)
end

-- 재료를 골드로(연금술) [원작: 재료는 등급 기본 골드 × 12]
function Cube.alchemyMaterial(state, id, count)
    local have = state.materials[id] or 0
    count = math.min(count or have, have)
    if count <= 0 then return fail("재료가 없습니다.") end
    local def = Materials.defs[id]
    local gold = math.floor(Items.GRADES[def.grade].gold * 12 * (1 + WIH.Runes.total(state, "CubeAlchemyGoldPercent") / 1000) * count + 0.5)
    state.materials[id] = have - count
    if state.materials[id] <= 0 then state.materials[id] = nil end
    WIH.Game.addGold(state, gold)
    local ups = Cube.addExp(state, Cube.materialExp(state, id) * count)
    return gold, count, ups
end

------------------------------------------------------------------------
-- 합성: 같은 등급·같은 분류 9개 → 무작위 1개
------------------------------------------------------------------------

local function classOf(item)
    return GEAR_GROUP[item.slot] == "ACCESSORY" and "Accessory" or "Gear"
end
Cube.classOf = classOf

-- 단계와 재료 평균 레벨로 결과 레벨의 분포를 정한다. 돌려주는 값: { {레벨, 가중치}, ... }
function Cube.levelOdds(kind, tier, grade, avgLevel)
    local rows = CubeTable.SYNTH[kind][tier] and CubeTable.SYNTH[kind][tier][grade]
    if not rows then return nil end
    local row
    for _, r in ipairs(rows) do
        if avgLevel >= r[1] then row = r end
    end
    row = row or rows[1]
    local out, k = {}, 0
    for _, lv in ipairs(LEVELS) do
        if lv >= row[2] and lv <= row[3] then
            k = k + 1
            local wgt = row[3 + k] or 0
            if wgt > 0 then out[#out + 1] = { lv, wgt } end
        end
    end
    return out
end

-- 결과 등급의 분포: { {등급, 확률}, ... }
function Cube.gradeOdds(grade)
    local w = CubeTable.SYNTH_GRADE[grade]
    local total = w[1] + w[2] + w[3]
    if total <= 0 then return nil end
    local out = {}
    if w[1] > 0 then out[#out + 1] = { grade, w[1] / total } end
    if w[2] > 0 then out[#out + 1] = { grade + 1, w[2] / total } end
    if w[3] > 0 then out[#out + 1] = { grade + 2, w[3] / total } end
    return out
end

local function pickWeighted(list, rng)
    local total = 0
    for _, e in ipairs(list) do total = total + e[2] end
    local r = rng:float() * total
    for _, e in ipairs(list) do
        r = r - e[2]
        if r < 0 then return e[1] end
    end
    return list[#list][1]
end

-- 장비 합성. indexes = 인벤토리 번호 9개, tier = 쓸 단계
function Cube.synthesize(state, tier, indexes, rng)
    local recipe = Cube.find("SYNTHESIS", tier)
    if not recipe or not Cube.unlocked(state, recipe) then return fail("열리지 않은 합성 단계입니다.") end
    if #indexes ~= Cube.SLOTS then return fail("같은 등급의 장비 9개가 필요합니다.") end
    local grade, kind, levels, seen = nil, nil, 0, {}
    for _, index in ipairs(indexes) do
        local entry = state.inventory.items[index]
        local item = entry and Items.byId[entry.id]
        if not item or seen[index] then return fail("장비를 다시 골라 주세요.") end
        if entry.lock then return fail("잠근 장비는 쓸 수 없습니다.") end
        seen[index] = true
        if grade and item.grade ~= grade then return fail("9개가 모두 같은 등급이어야 합니다.") end
        if kind and classOf(item) ~= kind then return fail("장비와 장신구는 섞을 수 없습니다.") end
        grade, kind = item.grade, classOf(item)
        levels = levels + item.level
    end
    if grade >= #Items.GRADES then return fail("우주 등급은 합성할 수 없습니다.") end
    local avg = levels / Cube.SLOTS
    local lodds = Cube.levelOdds(kind, tier, grade, avg)
    if not lodds or #lodds == 0 then return fail("이 단계에서는 이 등급을 합성할 수 없습니다.") end
    -- 결과 등급과 레벨
    local resultGrade = pickWeighted(Cube.gradeOdds(grade), rng)
    local level = pickWeighted(lodds, rng)
    local tableId
    for g = resultGrade, grade, -1 do                -- 그 레벨에 없는 등급이면 있는 등급까지 내린다
        tableId = dropIndex[kind][g] and dropIndex[kind][g][level]
        if tableId then resultGrade = g; break end
    end
    if not tableId then return fail("결과 표가 없습니다.") end
    -- 재료 소모(큐브 경험치)
    local exp = 0
    local consumed = {}
    for _, index in ipairs(indexes) do consumed[#consumed + 1] = index end
    table.sort(consumed, function(a, b) return a > b end)
    for _, index in ipairs(consumed) do
        exp = exp + Cube.itemExp(state, Items.byId[state.inventory.items[index].id])
        table.remove(state.inventory.items, index)
    end
    local result = Chests.rollEntries(state, CubeTable.tables[tableId], rng)
    if result.item then result.where = Inventory.add(state, result.item.id) end
    result.ups = Cube.addExp(state, exp)
    result.success = resultGrade > grade
    return result
end

-- 재료 합성: 같은 등급의 재료 9개(종류는 섞어도 된다) → 한 등급 위의 무작위 재료. ids = { {번호, 수}, ... }
function Cube.synthesizeMaterials(state, ids, rng)
    local recipe = Cube.find("SYNTHESIS", 1)
    if not Cube.unlocked(state, recipe) then return fail("합성이 열리지 않았습니다.") end
    local total, grade = 0, nil
    for _, p in ipairs(ids) do
        local def = Materials.defs[p[1]]
        if not def or (state.materials[p[1]] or 0) < p[2] then return fail("재료가 모자랍니다.") end
        if def.kind == "SOULSTONE" or def.kind == "OFFERING" then return fail("증표와 기원 재료는 합성할 수 없습니다.") end
        if grade and def.grade ~= grade then return fail("같은 등급의 재료만 넣을 수 있습니다.") end
        grade = def.grade
        total = total + p[2]
    end
    if total ~= Cube.SLOTS then return fail("재료 9개가 필요합니다.") end
    local resultGrade = pickWeighted(Cube.gradeOdds(grade), rng)
    local tableId = dropIndex.Material[resultGrade] and dropIndex.Material[resultGrade][0]
    if not tableId then return fail("이 등급의 재료는 합성할 수 없습니다.") end
    local exp = 0
    for _, p in ipairs(ids) do
        state.materials[p[1]] = state.materials[p[1]] - p[2]
        if state.materials[p[1]] <= 0 then state.materials[p[1]] = nil end
        exp = exp + Cube.materialExp(state, p[1]) * p[2]
    end
    local result = Chests.rollEntries(state, CubeTable.tables[tableId], rng)
    if result.material then state.materials[result.material] = (state.materials[result.material] or 0) + 1 end
    result.ups = Cube.addExp(state, exp)
    result.success = resultGrade > grade
    return result
end

------------------------------------------------------------------------
-- 제작: 부위와 단계를 고르고 재료를 넣으면 그 부위의 무작위 장비
------------------------------------------------------------------------

function Cube.craftCost(part, tier)
    local c = CubeTable.CRAFT[part] and CubeTable.CRAFT[part][tier]
    return c and c.mats or nil
end

function Cube.craft(state, part, tier, rng)
    local recipe = Cube.find("CRAFTING", tier)
    if not recipe or not Cube.unlocked(state, recipe) then return fail("열리지 않은 제작 단계입니다.") end
    local c = CubeTable.CRAFT[part] and CubeTable.CRAFT[part][tier]
    if not c then return fail("없는 제작법입니다.") end
    for _, m in ipairs(c.mats) do
        if (state.materials[m[1]] or 0) < m[2] then return fail(Materials.name(m[1]) .. "이(가) 모자랍니다.") end
    end
    local exp = 0
    for _, m in ipairs(c.mats) do
        state.materials[m[1]] = state.materials[m[1]] - m[2]
        if state.materials[m[1]] <= 0 then state.materials[m[1]] = nil end
        exp = exp + Cube.materialExp(state, m[1]) * m[2]
    end
    local result = Chests.rollEntries(state, CubeTable.tables[c.table], rng)
    if result.item then result.where = Inventory.add(state, result.item.id) end
    if result.material then state.materials[result.material] = (state.materials[result.material] or 0) + 1 end
    result.ups = Cube.addExp(state, exp)
    return result
end

------------------------------------------------------------------------
-- 장식·세공·각인과 제거: 빈 칸이 있는 장비 하나 + 재료 하나 → 능력치 한 줄
------------------------------------------------------------------------

function Cube.slots(item, kind)
    return Items.GRADES[item.grade][Cube.SLOT_FIELD[kind]] or 0
end

function Cube.used(entry, kind)
    local n = 0
    for _, a in ipairs(entry.added or {}) do if a.kind == kind then n = n + 1 end end
    return n
end

-- 재료가 이 장비에 붙일 수 있는 후보 능력치
function Cube.candidates(materialId, item)
    local mods = CubeTable.MODS[materialId]
    if not mods then return nil end
    return mods.ALL or mods[GEAR_GROUP[item.slot]]
end

function Cube.attach(state, entry, materialId, rng)
    local item = entry and Items.byId[entry.id]
    local def = Materials.defs[materialId]
    if not item or not def then return fail("장비와 재료를 골라 주세요.") end
    local kind = def.kind
    if not Cube.SLOT_FIELD[kind] then return fail("장식·세공·각인 재료가 아닙니다.") end
    local recipe = Cube.find(kind)
    if not Cube.unlocked(state, recipe) then return fail(Cube.NAMES[kind] .. " 레시피가 열리지 않았습니다.") end
    if (state.materials[materialId] or 0) < 1 then return fail("재료가 없습니다.") end
    if Cube.used(entry, kind) >= Cube.slots(item, kind) then
        return fail(Items.gradeName(item) .. " 등급 장비에는 " .. Cube.NAMES[kind] .. " 칸이 " .. Cube.slots(item, kind) .. "개입니다.")
    end
    local list = Cube.candidates(materialId, item)
    if not list or #list == 0 then return fail("이 재료는 이 장비에 쓸 수 없습니다.") end
    local c = list[rng:int(1, #list)]
    local value = rng:int(c[3], c[4])
    state.materials[materialId] = state.materials[materialId] - 1
    if state.materials[materialId] <= 0 then state.materials[materialId] = nil end
    entry.added = entry.added or {}
    local line = { kind = kind, stat = c[1], mod = c[2], value = value, tier = def.grade }
    table.insert(entry.added, line)
    return line
end

function Cube.extractCost(line)
    return CubeTable.EXTRACT[line.kind][math.max(1, math.min(10, line.tier or 1))]
end

function Cube.extract(state, entry, index)
    local recipe = Cube.find("EXTRACTION")
    if not Cube.unlocked(state, recipe) then return fail("제거 레시피가 열리지 않았습니다.") end
    local line = entry and entry.added and entry.added[index]
    if not line then return fail("지울 능력치를 골라 주세요.") end
    local cost = Cube.extractCost(line)
    if state.gold < cost then return fail("골드가 부족합니다.") end
    state.gold = state.gold - cost
    table.remove(entry.added, index)
    if #entry.added == 0 then entry.added = nil end
    return true, cost
end

------------------------------------------------------------------------
-- 기원: 공물 주화 1개 + 수수료 → 무작위 아이템
------------------------------------------------------------------------

function Cube.offering(state, coinId, rng)
    if WIH.Relics and WIH.Relics.isOfferMaterial(coinId) then
        if not Cube.unlocked(state, Cube.find("OFFERING")) then return fail("기원 레시피가 열리지 않았습니다.") end
        local result, why = WIH.Relics.offerMaterial(state, coinId, rng)
        if not result then return fail(why) end
        result.ups = Cube.addExp(state, Cube.materialExp(state, coinId))
        return result
    end
    local recipe
    for _, r in ipairs(Cube.recipes) do if r.kind == "OFFERING" and r.material == coinId then recipe = r end end
    if not recipe then return fail("기원에 쓸 수 없는 재료입니다.") end
    if not Cube.unlocked(state, recipe) then return fail("기원 레시피가 열리지 않았습니다.") end
    if (state.materials[coinId] or 0) < 1 then return fail("주화가 없습니다.") end
    if state.gold < (recipe.fee or 0) then return fail("골드가 부족합니다.") end
    state.gold = state.gold - (recipe.fee or 0)
    state.materials[coinId] = state.materials[coinId] - 1
    if state.materials[coinId] <= 0 then state.materials[coinId] = nil end
    local result = Chests.rollEntries(state, CubeTable.tables[recipe.table], rng)
    if result.item then result.where = Inventory.add(state, result.item.id) end
    if result.material then state.materials[result.material] = (state.materials[result.material] or 0) + 1 end
    result.ups = Cube.addExp(state, Cube.materialExp(state, coinId))
    return result
end

-- 저장 데이터 검증
function Cube.validate(state)
    Cube.ensure(state)
    local c = state.cube
    c.level = math.max(1, math.min(Cube.MAX_LEVEL, math.floor(c.level)))
    local valid = {}
    for _, r in ipairs(Cube.recipes) do valid[keyOf(r)] = true end
    for k in pairs(c.unlocked) do if not valid[k] then c.unlocked[k] = nil end end
    local function clean(entry)
        if type(entry) ~= "table" or entry.added == nil then return end
        if type(entry.added) ~= "table" then entry.added = nil; return end
        for i = #entry.added, 1, -1 do
            local a = entry.added[i]
            if type(a) ~= "table" or not Cube.SLOT_FIELD[a.kind] or not WIH.Stats.defs[a.stat] or type(a.value) ~= "number" then
                table.remove(entry.added, i)
            end
        end
        if #entry.added == 0 then entry.added = nil end
    end
    for _, e in ipairs(state.inventory.items) do clean(e) end
    for _, e in ipairs(state.mail) do clean(e) end
    for _, h in pairs(state.heroes) do for _, e in pairs(h.gear or {}) do clean(e) end end
end

return Cube
