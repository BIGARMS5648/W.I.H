-- 보물상자: 드롭, 획득 허용량, 보관, 개봉. 아이템은 모두 상자에서 나온다. [원작]
-- 저장 형태: state.chests[종류] = { list = { 표 번호, ... }, allowance = 허용량, auto = 자동 개봉까지 흐른 시간(초) }
-- 종류: normal(일반 몬스터가 주는 일반 상자), stage(스테이지 보스가 주는 스테이지 상자), raid(레이드를 클리어하면 받는 상자)

local _, WIH = ...
local Tables = WIH.module("Tables")
local Heroes = WIH.module("Heroes")
local Items = WIH.module("Items")
local ChestTable = WIH.module("ChestTable")
local Materials = WIH.module("Materials")
local Inventory = WIH.module("Inventory")
local Chests = WIH.module("Chests")

Chests.KINDS = { "normal", "stage", "raid" }
Chests.NAMES = { normal = "일반 상자", stage = "스테이지 상자", raid = "레이드 상자" }
Chests.BASE_CAP = 5             -- [추정] 룬이 없을 때의 보관 한도
Chests.ALLOWANCE_CAP = 2        -- [독자] 허용량의 누적 한도. 원작의 한도는 확인되지 않았다
Chests.START_ALLOWANCE = 1      -- [독자] 새 게임은 허용량 1에서 시작한다

-- 종류별 룬 스탯과 스테이지 표의 열 이름
local RUNE = {
    normal = { cap = "MaxAmountNormalChest", chance = "DropChanceNormalChestPercent", auto = "UnlockAutoOpenNormalChest",
        reduce = "ReduceAutoOpenNormalChestTime", rate = "chest", table = "normal", cool = "cool" },
    stage = { cap = "MaxAmountStageBossChest", chance = "DropChanceStageBossChestPercent", auto = "UnlockAutoOpenStageBossChest",
        reduce = "ReduceAutoOpenStageBossChestTime", rate = "bossChest", table = "boss", cool = "bossCool" },
    -- 레이드 상자는 확률이나 허용량이 아니라 입장 재료로 제한된다. 클리어하면 반드시 하나를 받는다. [원작]
    raid = { cap = "MaxAmountActBossChest", auto = "UnlockAutoOpenActBossChest", reduce = "ReduceAutoOpenActBossChestTime" },
}

local function runeTotal(state, stat)
    return WIH.Runes and WIH.Runes.total(state, stat) or 0
end

function Chests.ensure(state)
    if type(state.chests) ~= "table" then state.chests = {} end
    for _, kind in ipairs(Chests.KINDS) do
        local c = state.chests[kind]
        if type(c) ~= "table" then
            c = { list = {}, allowance = Chests.START_ALLOWANCE, auto = 0 }
            state.chests[kind] = c
        end
        if type(c.list) ~= "table" then c.list = {} end
        if type(c.allowance) ~= "number" or c.allowance ~= c.allowance then c.allowance = Chests.START_ALLOWANCE end
        if type(c.auto) ~= "number" or c.auto ~= c.auto then c.auto = 0 end
    end
    if type(state.materials) ~= "table" then state.materials = {} end
    return state.chests
end

function Chests.cap(state, kind)
    return Chests.BASE_CAP + runeTotal(state, RUNE[kind].cap)
end

function Chests.count(state, kind) return #state.chests[kind].list end

-- 상자 드롭 확률(0~1): 스테이지의 확률 × (1 + 룬의 드롭 확률 %) [원작 수치 / 추정: 곱연산]
function Chests.dropChance(state, kind, stageKey)
    local stage = Tables.STAGES[stageKey]
    local rate = stage and RUNE[kind].rate and stage[RUNE[kind].rate]
    if not rate then return 0 end
    local p = rate / 1000 * (1 + runeTotal(state, RUNE[kind].chance) / 1000)
    return p > 1 and 1 or p
end

-- 자동 개봉까지의 시간(초). 룬으로 해금하지 않았으면 nil.
function Chests.autoOpenTime(state, kind)
    local base = runeTotal(state, RUNE[kind].auto)
    if base <= 0 then return nil end
    local t = base - runeTotal(state, RUNE[kind].reduce)
    return t < 1 and 1 or t
end

-- 한 번에 모두 열 수 있는지(룬)
function Chests.canOpenAll(state)
    return runeTotal(state, "OpenOneTypeChestAllAtOnce") > 0 or runeTotal(state, "OpenAllTypeChestAllAtOnce") > 0
end

-- 몬스터를 잡았을 때: 확률, 허용량, 보관 한도를 모두 통과하면 상자 하나를 받는다.
-- 돌려주는 값: 받았으면 true. 못 받았으면 false와 사유("chance" | "allowance" | "full")
function Chests.tryDrop(state, kind, stageKey, rng)
    local info = ChestTable.STAGE[stageKey]
    local tableId = info and RUNE[kind].table and info[RUNE[kind].table]
    if not tableId then return false, "chance" end
    if not rng:chance(Chests.dropChance(state, kind, stageKey)) then return false, "chance" end
    local c = state.chests[kind]
    if c.allowance < 1 then return false, "allowance" end
    if #c.list >= Chests.cap(state, kind) then return false, "full" end       -- 못 받은 상자는 허용량을 쓰지 않는다 [독자]
    c.allowance = c.allowance - 1
    c.list[#c.list + 1] = tableId
    return true
end

-- 레이드 클리어 보상: 레이드 상자 하나를 보관함에 넣는다. 보관함이 가득 차 있으면 그 자리에서 열어 준다(잃지 않게). [독자]
-- 돌려주는 값: 보관했으면 "stored", 바로 열었으면 "opened"와 그 결과
function Chests.giveRaid(state, raidKey, rng)
    local info = ChestTable.STAGE[raidKey]
    local tableId = info and info.raid
    if not tableId then return nil end
    local c = state.chests.raid
    c.list[#c.list + 1] = tableId
    if #c.list > Chests.cap(state, "raid") then
        return "opened", Chests.open(state, "raid", rng)
    end
    return "stored"
end

-- 표에서 보상 하나를 뽑는다. 돌려주는 값: { item = 아이템 } 또는 { material = 번호 }
-- 주무기·보조무기 묶음은 보유한 영웅이 쓰는 종류 가운데서 고르게 뽑는다. [원작의 보유 영웅 조건 / 독자: 묶음 총량 고정]
function Chests.roll(state, tableId, rng)
    local entries = ChestTable.tables[tableId]
    if not entries then return nil end
    local total = 0
    for i = 1, #entries do total = total + entries[i][1] end
    local r = rng:float() * total
    local pick = entries[#entries]
    for i = 1, #entries do
        r = r - entries[i][1]
        if r < 0 then pick = entries[i]; break end
    end
    if pick[2] == "MAT" then return { material = pick[3] } end
    local part, level, grade = pick[2], pick[3], pick[4]
    local typeId = part
    if part == "MAIN" or part == "SUB" then
        local seen, list = {}, {}
        for _, hero in ipairs(Heroes.list) do
            if state.heroes[hero.id] then
                local t = part == "MAIN" and hero.main or hero.sub
                if not seen[t] then seen[t] = true; list[#list + 1] = t end
            end
        end
        table.sort(list, function(a, b) return Items.TYPES[a].index < Items.TYPES[b].index end)
        typeId = list[rng:int(1, #list)]
    end
    local variants = Items.byType[typeId] and Items.byType[typeId][level] and Items.byType[typeId][level][grade]
    if not variants then return nil end
    return { item = variants[rng:int(1, #variants)] }
end

-- 상자 하나를 연다(가장 먼저 받은 것부터). 돌려주는 값: 결과 { item | material, where } 또는 false와 사유
function Chests.open(state, kind, rng)
    local c = state.chests[kind]
    if not c or #c.list == 0 then return false, "열 상자가 없습니다." end
    local tableId = table.remove(c.list, 1)
    local result = Chests.roll(state, tableId, rng)
    if not result then return false, "상자의 내용물 표가 없습니다." end
    if result.item then
        result.where = Inventory.add(state, result.item.id)
    else
        state.materials[result.material] = (state.materials[result.material] or 0) + 1
    end
    state.stats.chestsOpened = (state.stats.chestsOpened or 0) + 1
    return result
end

-- 시간 경과: 허용량을 충전하고, 자동 개봉이 해금돼 있으면 때가 된 상자를 연다.
-- onLoot(kind, result)는 자동으로 열린 상자마다 불린다.
function Chests.tick(state, dt, stageKey, rng, onLoot)
    local info = ChestTable.STAGE[stageKey]
    for _, kind in ipairs(Chests.KINDS) do
        local c = state.chests[kind]
        local minutes = info and RUNE[kind].cool and info[RUNE[kind].cool]
        if minutes and c.allowance < Chests.ALLOWANCE_CAP then
            c.allowance = c.allowance + dt / (minutes * 60)
            if c.allowance > Chests.ALLOWANCE_CAP then c.allowance = Chests.ALLOWANCE_CAP end
        end
        local autoTime = Chests.autoOpenTime(state, kind)
        if autoTime and #c.list > 0 then
            c.auto = c.auto + dt
            if c.auto >= autoTime then
                c.auto = 0
                local result = Chests.open(state, kind, rng)
                if result and onLoot then onLoot(kind, result) end
            end
        else
            c.auto = 0
        end
    end
end

-- 첫 클리어 보상 [원작]: 일반 1-1을 처음 클리어하면 편성한 영웅이 쓰는 일반 등급 레벨 1 주무기를 받는다.
-- (원작은 고른 직업의 무기가 든 상자를 준다. 여기서는 바로 인벤토리에 넣는다.)
function Chests.firstClearReward(state, stageKey)
    if stageKey ~= 1101 then return nil end
    local given, seen = {}, {}
    for _, heroId in ipairs(state.party) do
        local hero = Heroes.byId[heroId]
        if hero and not seen[hero.main] then
            seen[hero.main] = true
            local item = Items.find(hero.main, 1, 1, 1)
            if item then
                Inventory.add(state, item.id)
                given[#given + 1] = item
            end
        end
    end
    return given
end

-- 재료의 표기(큐브를 만들기 전까지의 임시 표기: 분류와 등급)
local MATERIAL_KIND = {
    CRAFTING = "제작 재료", DECORATION = "장식 재료", ENGRAVING = "세공 재료", INSCRIPTION = "각인 재료",
    SOULSTONE = "영혼석", OFFERING = "기원 주화", ETC = "기타 재료", EVENTTICKET = "행사 입장권",
}
function Chests.materialName(id)
    local def = Materials.defs[id]
    if not def then return "알 수 없는 재료" end
    return (MATERIAL_KIND[def.kind] or def.kind) .. " (" .. Items.GRADES[def.grade].name .. ")"
end

-- 상자를 연 결과의 한 줄 표기
function Chests.resultText(result)
    if not result then return "" end
    if result.item then
        local where = result.where == "mail" and " (가방이 가득 차 임시 보관함으로)" or ""
        return Items.name(result.item) .. " [" .. Items.gradeName(result.item) .. "]" .. where
    end
    return Chests.materialName(result.material)
end

-- 저장 데이터 검증
function Chests.validate(state, notes)
    Chests.ensure(state)
    for _, kind in ipairs(Chests.KINDS) do
        local c = state.chests[kind]
        local clean = {}
        for _, tableId in pairs(c.list) do
            if ChestTable.tables[tableId] then clean[#clean + 1] = tableId end
        end
        if #clean ~= #c.list then notes[#notes + 1] = Chests.NAMES[kind] .. " 보관함의 잘못된 기록을 지움" end
        c.list = clean
        if c.allowance < 0 then c.allowance = 0 elseif c.allowance > Chests.ALLOWANCE_CAP then c.allowance = Chests.ALLOWANCE_CAP end
        if c.auto < 0 then c.auto = 0 end
    end
    for id, n in pairs(state.materials) do
        if not Materials.defs[id] or type(n) ~= "number" or n ~= n or n < 0 then state.materials[id] = nil end
    end
end

return Chests
