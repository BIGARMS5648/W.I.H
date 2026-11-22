-- 룬 화면: 골드로 사는 계정 공통 영구 성장.
-- 규칙(선행 조건, 비용, 수치)은 Progression/Runes.lua의 것이고, 이 화면은 목록으로 보여 주기만 한다.

local _, WIH = ...
local UI = WIH.module("UI")
local App = WIH.module("App")
local Runes = WIH.module("Runes")
local RuneData = WIH.module("RuneData")

local C = UI.C
local ROW_H = 40
local FILTERS = { { id = "open", label = "살 수 있는 룬" }, { id = "owned", label = "보유한 룬" }, { id = "all", label = "전체" } }

local nodes = RuneData.nodes
local Pets = WIH.module("Pets")

local function nodeOpen(s, key)
    local node = nodes[key]
    return not node.parent or Runes.level(s, node.parent) >= (node.req or 1)
end

local function passes(s, key, filter)
    local node, level = nodes[key], Runes.level(s, key)
    if filter == "open" then return level < node.max and nodeOpen(s, key) end
    if filter == "owned" then return level > 0 end
    return true
end

-- 목록의 순서를 정한다: 열린 것 → 잠긴 것 → 다 올린 것, 그 안에서는 다음 비용이 싼 순.
local function rebuild(f)
    local s = App.state
    local items = {}
    for key in pairs(nodes) do
        if passes(s, key, f.filter) then items[#items + 1] = key end
    end
    local function rank(key)
        local node, level = nodes[key], Runes.level(s, key)
        if level >= node.max then return 2 end
        return nodeOpen(s, key) and 0 or 1
    end
    local function cost(key)
        local node = nodes[key]
        return node.cost[math.min(node.max, Runes.level(s, key) + 1)]
    end
    table.sort(items, function(a, b)
        local ra, rb = rank(a), rank(b)
        if ra ~= rb then return ra < rb end
        local ca, cb = cost(a), cost(b)
        if ca ~= cb then return ca < cb end
        return a < b
    end)
    f.items = items
    f.inList = {}
    for _, key in ipairs(items) do f.inList[key] = true end
end

local function tooltipFor(key)
    local s = App.state
    local node, level = nodes[key], Runes.level(s, key)
    local lines = {}
    for i = 1, node.max do
        local mark = i <= level and "보유" or (UI.number(node.cost[i]) .. " G")
        lines[#lines + 1] = { string.format("%d레벨  %s  (%s)", i, Runes.valueText(node.stat, node.value[i]), mark), i <= level and C.good or C.sub }
    end
    if node.parent then
        local p = nodes[node.parent]
        local met = Runes.level(s, node.parent) >= (node.req or 1)
        lines[#lines + 1] = { string.format("앞 룬: %s (%d레벨 필요, 현재 %d)", Runes.label(p.stat), node.req or 1, Runes.level(s, node.parent)), met and C.dim or C.bad }
    end
    local kids = Runes.children[key]
    if kids then
        local names = {}
        for _, k in ipairs(kids) do names[#names + 1] = Runes.label(nodes[k].stat) end
        lines[#lines + 1] = { "이 룬이 여는 룬: " .. table.concat(names, ", "), C.dim }
    end
    local why = Runes.INACTIVE[node.stat]
    if why then
        lines[#lines + 1] = { "미적용: " .. why .. " 기능이 아직 구현되지 않아 지금은 효과가 없습니다. 뒤의 룬을 여는 조건으로는 쓰입니다.", C.warn }
    else
        lines[#lines + 1] = { "효과는 다음 스테이지부터 적용됩니다.", C.dim }
    end
    return { title = Runes.label(node.stat), lines = lines }
end

local function getRow(f, n)
    local row = f.rows[n]
    if row then return row end
    row = UI.panel(f.list.content, C.panel, true)
    row:SetHeight(ROW_H - 4)
    row:SetPoint("TOPLEFT", 0, -(n - 1) * ROW_H)
    row:SetPoint("TOPRIGHT", -2, -(n - 1) * ROW_H)
    row.name = UI.text(row, 12, C.text)
    row.name:SetPoint("TOPLEFT", 10, -5)
    row.sub = UI.text(row, 11, C.dim)
    row.sub:SetPoint("BOTTOMLEFT", 10, 5)
    row.buy = UI.button(row, "구매", 56, 24, function(self)
        local ok, why = Runes.buy(App.state, row.key)
        if not ok then
            WIH.Main.notice(why, C.bad)
        else
            -- 순서는 그대로 두고(연속 구매 중에 줄이 움직이지 않게), 새로 열린 룬만 뒤에 붙인다.
            for _, child in ipairs(Runes.children[row.key] or {}) do
                if not f.inList[child] and passes(App.state, child, f.filter) then
                    f.items[#f.items + 1] = child
                    f.inList[child] = true
                end
            end
        end
        UI.screens.runes.paint(f)
    end)
    row.buy:SetPoint("RIGHT", -8, 0)
    row.cost = UI.text(row, 12, C.warn, "RIGHT")
    row.cost:SetPoint("RIGHT", row.buy, "LEFT", -10, 0)
    row.tag = UI.text(row, 10, C.warn, "RIGHT")
    row.tag:SetPoint("RIGHT", row.cost, "LEFT", -12, 0)
    UI.setTooltip(row, function() return tooltipFor(row.key) end)
    f.rows[n] = row
    return row
end

local function summaryText(s)
    local totals = Runes.totals(s)
    local names = {}
    for stat in pairs(totals) do names[#names + 1] = stat end
    table.sort(names, function(a, b) return Runes.label(a) < Runes.label(b) end)
    local lines = {}
    for _, stat in ipairs(names) do
        if totals[stat] ~= 0 then
            local inactive = Runes.INACTIVE[stat]
            lines[#lines + 1] = string.format("%s%s  %s%s", inactive and "|cff6b6e75" or "", Runes.label(stat),
                Runes.valueText(stat, totals[stat]), inactive and " (미적용)|r" or "")
        end
    end
    if #lines == 0 then return "아직 산 룬이 없습니다." end
    return table.concat(lines, "\n")
end

local function paint(f)
    local s = App.state
    if not s then return end
    local unlocked = Runes.treeUnlocked(s)
    f.lock:SetShown(not unlocked)
    f.lock:SetText("영웅 한 명이 레벨 " .. Runes.UNLOCK_HERO_LEVEL .. "이 되면 룬을 살 수 있습니다.")
    for _, b in ipairs(f.filters) do b:setSelected(b.id == f.filter) end
    local items = f.items or {}
    for n, key in ipairs(items) do
        local row = getRow(f, n)
        local node, level = nodes[key], Runes.level(s, key)
        row.key = key
        local maxed = level >= node.max
        local open = nodeOpen(s, key)
        local nextValue = node.value[math.min(node.max, level + 1)]
        row.name:SetText(Runes.label(node.stat) .. "  " .. Runes.valueText(node.stat, nextValue))
        row.name:SetTextColor(UI.rgb((open or level > 0) and C.text or C.dim))
        local sub = "레벨 " .. level .. " / " .. node.max
        if not open then
            sub = sub .. "  ·  앞 룬 필요: " .. Runes.label(nodes[node.parent].stat)
        end
        row.sub:SetText(sub)
        row.tag:SetText(Runes.INACTIVE[node.stat] and "미적용" or "")
        if maxed then
            row.cost:SetText("최대")
            row.cost:SetTextColor(UI.rgb(C.good))
            row.buy:Hide()
        else
            local cost = node.cost[level + 1]
            row.cost:SetText(UI.number(cost) .. " G")
            row.cost:SetTextColor(UI.rgb(s.gold >= cost and C.warn or C.dim))
            row.buy:Show()
            row.buy:setEnabled(unlocked and open and s.gold >= cost)
        end
        row:Show()
    end
    for i = #items + 1, #f.rows do f.rows[i]:Hide() end
    f.list:setHeight(#items * ROW_H)
    f.empty:SetShown(#items == 0)
    f.empty:SetText(f.filter == "owned" and "아직 산 룬이 없습니다." or "지금 살 수 있는 룬이 없습니다.")
    f.summary:SetText(summaryText(s))
    f.count:SetText("전체 " .. f.total .. "개  ·  표시 " .. #items .. "개")
    f.lastGold = math.floor(s.gold)
end

local function create(parent)
    local f = CreateFrame("Frame", nil, parent)
    f.filter = "open"
    f.rows = {}
    f.total = 0
    for _ in pairs(nodes) do f.total = f.total + 1 end

    f.filters = {}
    for i, def in ipairs(FILTERS) do
        local b = UI.button(f, def.label, 104, 24, function()
            f.filter = def.id
            rebuild(f)
            f.list:SetVerticalScroll(0)
            paint(f)
        end)
        b.id = def.id
        b:SetPoint("TOPLEFT", 10 + (i - 1) * 108, -10)
        f.filters[i] = b
    end
    f.count = UI.text(f, 11, C.dim, "RIGHT")
    f.count:SetPoint("TOPRIGHT", -232, -16)
    f.view = "rune"
    f.seg = UI.segment(f, { { "rune", "룬" }, { "pet", "펫" }, { "relic", "유물" } }, 210, function(id)
        f.view = id
        UI.screens.runes.refresh(f)
    end)
    f.seg:SetPoint("TOPRIGHT", -12, -8)

    -- 왼쪽: 합계
    local side = UI.panel(f, C.panel, true)
    side:SetPoint("TOPLEFT", 10, -44)
    side:SetPoint("BOTTOMLEFT", 10, 10)
    side:SetWidth(230)
    local sideTitle = UI.text(side, 12, C.sub)
    sideTitle:SetPoint("TOPLEFT", 10, -10)
    sideTitle:SetText("지금까지의 합계")
    f.summaryScroll = UI.scroll(side)
    f.summaryScroll:SetPoint("TOPLEFT", 10, -32)
    f.summaryScroll:SetPoint("BOTTOMRIGHT", -6, 8)
    f.summary = UI.paragraph(f.summaryScroll.content, 11, C.text)
    f.summary:SetPoint("TOPLEFT", 0, 0)
    f.summary:SetPoint("TOPRIGHT", -4, 0)
    if f.summary.SetSpacing then f.summary:SetSpacing(4) end

    f.lock = UI.text(f, 12, C.warn)
    f.lock:SetPoint("TOPLEFT", side, "TOPRIGHT", 14, 0)
    f.list = UI.scroll(f)
    f.list:SetPoint("TOPLEFT", side, "TOPRIGHT", 12, -22)
    f.list:SetPoint("BOTTOMRIGHT", -10, 10)
    f.empty = UI.text(f, 12, C.dim)
    f.empty:SetPoint("TOPLEFT", f.list, "TOPLEFT", 4, -8)
    f.acc = 0
    UI.screens.runes.createPets(f)
    if UI.screens.runes.createRelics then UI.screens.runes.createRelics(f) end
    return f
end

-- 화면을 열 때만 순서를 다시 정한다. 진행 중에 오는 갱신(클리어, 상자 등)은 순서를 건드리지 않는다.
local function onShow(f)
    if App.state then rebuild(f) end
end

local function refresh(f)
    if not App.state then return end
    f.seg:pick(f.view)
    local rune = f.view == "rune"
    for _, b in ipairs(f.filters) do b:SetShown(rune) end
    f.count:SetShown(rune)
    f.petView:SetShown(f.view == "pet")
    if f.relicView then f.relicView:SetShown(f.view == "relic") end
    if f.view == "pet" then return UI.screens.runes.paintPets(f) end
    if f.view == "relic" and UI.screens.runes.paintRelics then return UI.screens.runes.paintRelics(f) end
    if not f.items then rebuild(f) end
    paint(f)
    f.summaryScroll:setHeight((f.summary:GetStringHeight() or 200) + 10)
end

-- 골드는 전투 중에 계속 늘어난다. 순서는 건드리지 않고 살 수 있는지만 다시 칠한다.
local function update(f, elapsed)
    f.acc = f.acc + elapsed
    if f.acc < 0.5 then return end
    f.acc = 0
    if f.view ~= "rune" then return end
    local s = App.state
    if s and math.floor(s.gold) ~= f.lastGold then paint(f) end
    f.summaryScroll:setHeight((f.summary:GetStringHeight() or 200) + 10)
end

------------------------------------------------------------------------
-- 펫
------------------------------------------------------------------------

local PET_ICON = { bat = "Ability_Hunter_Pet_Bat", scarab = "INV_Misc_AhnQirajTrinket_01", ember = "Spell_Fire_Fire",
    construct = "INV_Misc_Gear_08", wisp = "Spell_Nature_WispSplode", whelp_red = "INV_Misc_Head_Dragon_Red",
    corehound = "Ability_Hunter_Pet_Hyena", whelp_black = "INV_Misc_Head_Dragon_Black", pumpkin = "INV_Misc_Food_59",
    ghostling = "Ability_Rogue_Disguise" }

local function createPets(f)
    local v = UI.panel(f, C.bg)
    v:SetPoint("TOPLEFT", 0, -40)
    v:SetPoint("BOTTOMRIGHT", 0, 0)
    v:SetFrameLevel(f:GetFrameLevel() + 20)
    v:Hide()
    f.petView = v
    v.summary = UI.paragraph(v, 12, C.text)
    v.summary:SetPoint("TOPLEFT", 14, -6)
    v.summary:SetPoint("TOPRIGHT", -14, -6)
    v.rows = {}
    for i, pet in ipairs(Pets.list) do
        local row = UI.panel(v, C.panel, true)
        row:SetSize(452, 76)
        local col, r = (i - 1) % 2, math.floor((i - 1) / 2)
        row:SetPoint("TOPLEFT", 14 + col * 462, -48 - r * 82)
        row.icon = UI.icon(row, 40, PET_ICON[pet.id])
        row.icon:SetPoint("TOPLEFT", 10, -10)
        row.name = UI.text(row, 13, C.text)
        row.name:SetPoint("TOPLEFT", 60, -10)
        row.effect = UI.text(row, 11, C.good)
        row.effect:SetPoint("TOPLEFT", 60, -30)
        row.cond = UI.text(row, 10, C.dim)
        row.cond:SetPoint("TOPLEFT", 60, -48)
        row.bar = UI.bar(row, 200, 3, C.exp)
        row.bar:SetPoint("TOPLEFT", 60, -64)
        row.follow = UI.button(row, "동행", 64, 22, function()
            local s = App.state
            local id = s.pets.follow ~= pet.id and pet.id or nil
            local ok, why = Pets.setFollow(s, id)
            if not ok then WIH.Main.notice(why, C.bad) end
            UI.screens.runes.paintPets(f)
        end)
        row.follow:SetPoint("BOTTOMRIGHT", -10, 10)
        row.follow.tooltip = { title = "동행", lines = { "사냥 띠에서 영웅을 따라다닙니다. 겉모습일 뿐이고, 펫의 효과는 가지고 있기만 하면 모두 적용됩니다." } }
        row.pet = pet
        v.rows[i] = row
    end
end

local function paintPets(f)
    local s = App.state
    local v = f.petView
    local owned, sum = 0, {}
    for _, pet in ipairs(Pets.list) do
        if Pets.owned(s, pet.id) then
            owned = owned + 1
            for stat, val in pairs(pet.mods) do sum[stat] = (sum[stat] or 0) + val end
        end
    end
    local parts = {}
    for _, stat in ipairs({ "IncreaseExpAmount", "IncreaseGoldAmount", "DropChanceNormalChestPercent", "DropChanceStageBossChestPercent" }) do
        if sum[stat] then parts[#parts + 1] = Runes.label(stat) .. " +" .. (sum[stat] / 10) .. "%" end
    end
    v.summary:SetText(string.format("펫 %d / %d   ·   가지고 있는 펫의 효과는 모두 겹쳐서 늘 적용됩니다.\n%s", owned, #Pets.list,
        #parts > 0 and ("|cff6fb07f합계  " .. table.concat(parts, "  ·  ") .. "|r") or "|cff666b74아직 얻은 펫이 없습니다.|r"))
    for _, row in ipairs(v.rows) do
        local pet = row.pet
        local has = Pets.owned(s, pet.id)
        local have, need = Pets.progress(s, pet)
        row.name:SetText(pet.name)
        row.name:SetTextColor(UI.rgb(has and C.text or C.sub))
        row.effect:SetText(Pets.effectText(pet))
        row.effect:SetTextColor(UI.rgb(has and C.good or C.dim))
        row.cond:SetText(has and "얻음" or (Pets.conditionText(pet) .. "   " .. UI.number(have) .. " / " .. UI.number(need)))
        row.bar:set(has and 1 or have / need)
        row.icon.tex:SetDesaturated(not has)
        row.icon:SetAlpha(has and 1 or 0.5)
        row.follow:SetShown(has)
        row.follow:setSelected(s.pets.follow == pet.id)
        row.follow:setText(s.pets.follow == pet.id and "동행 중" or "동행")
    end
end

------------------------------------------------------------------------
-- 유물
--   왼쪽: 장착 칸 2개와 파티 전원에게 적용 중인 합계
--   가운데: 고른 유물함(고정 속성, 공명 조건·효과, 유물 칸). 칸을 누르면 고른 유물을 끼우고, 오른쪽 클릭으로 뺀다.
--   오른쪽: 가진 유물함·유물 목록과 고른 유물의 정보
------------------------------------------------------------------------

local Relics = WIH.module("Relics")
local RELIC_ICON = { RED = "INV_Misc_Gem_Ruby_02", BLUE = "INV_Misc_Gem_Sapphire_02", YELLOW = "INV_Misc_Gem_Topaz_02",
    PURPLE = "INV_Misc_Gem_Amethyst_02", WHITE = "INV_Misc_Gem_Diamond_02" }
local QUIVER_ICON = "INV_Box_02"
local MAX_SOCKETS = 8

local function gradeColor(g) return WIH.Items.GRADES[g].color end
local function gradeName(g) return WIH.Items.GRADES[g].name end
local function colorHex(color)
    local c = Relics.COLOR_RGB[color]
    return string.format("|cff%02x%02x%02x", c[1] * 255, c[2] * 255, c[3] * 255)
end

local function iconOf(item)
    if item.kind == "RELIQUARY" then return QUIVER_ICON end
    return RELIC_ICON[WIH.RelicTable.RELICS[item.id].color]
end

local function relicLine(item)
    local def = WIH.RelicTable.RELICS[item.id]
    return Relics.statText(def.stat, def.kind, item.value)
end

local function relicTooltip(item)
    local lines = { gradeName(item.grade) .. " · " .. Relics.COLOR_NAMES[WIH.RelicTable.RELICS[item.id].color] .. " 칸",
        relicLine(item) }
    if WIH.RelicTable.RELICS[item.id].double then lines[#lines + 1] = "메아리: 공명 조건의 색을 셀 때 2개로 셉니다." end
    lines[#lines + 1] = "조율 " .. UI.number(Relics.attuneCost(item)) .. " G"
    return { title = Relics.name(item), lines = lines }
end

local function relicStatusText(s, q)
    local g = WIH.RelicTable.RELIQUARIES[q.id].grades[q.grade]
    if g[3] then return "|cff666b74미완성 등급이라 공명하지 않습니다.|r" end
    if not Relics.EFFECTS[q.id] then return "|cff666b74공명 효과 없음|r" end
    if Relics.resonating(s, q) then
        if Relics.equippedSlot(s, q.uid) then return "|cff6fb07f공명 중|r" end
        return "|cffc9a45c조건 충족 · 장착하면 발동|r"
    end
    return "|cffd06058조건 미충족|r"
end

local function createRelics(f)
    local v = UI.panel(f, C.bg)
    v:SetPoint("TOPLEFT", 0, -40)
    v:SetPoint("BOTTOMRIGHT", 0, 0)
    v:SetFrameLevel(f:GetFrameLevel() + 20)
    v:Hide()
    f.relicView = v
    v.listKind = "RELIQUARY"

    v.summary = UI.paragraph(v, 12, C.text)
    v.summary:SetPoint("TOPLEFT", 14, -6)
    v.summary:SetPoint("TOPRIGHT", -120, -6)
    v.apply = UI.button(v, "지금 적용", 90, 24, function()
        v.dirty = false
        App.restartStage()
        UI.screens.runes.paintRelics(f)
    end)
    v.apply:SetPoint("TOPRIGHT", -14, -6)
    v.apply.tooltip = { title = "지금 적용", lines = { "현재 스테이지를 처음부터 다시 시작해 바꾼 유물을 바로 적용합니다. 누르지 않으면 다음 스테이지부터 적용됩니다." } }

    -- 왼쪽: 장착 칸
    local left = UI.panel(v, C.panel, true)
    left:SetPoint("TOPLEFT", 14, -44)
    left:SetPoint("BOTTOMLEFT", 14, 10)
    left:SetWidth(250)
    v.equip = {}
    for i = 1, 2 do
        local card = UI.listRow(left, 230, 58, function()
            local s = App.state
            local uid = s.relics.equipped[i]
            if uid then v.quiver = uid end
            v.slotPick = i
            UI.screens.runes.paintRelics(f)
        end)
        card:SetPoint("TOPLEFT", 10, -10 - (i - 1) * 64)
        card.icon = UI.icon(card, 36, QUIVER_ICON)
        card.icon:SetPoint("LEFT", 8, 0)
        card.title = UI.text(card, 10, C.dim)
        card.title:SetPoint("TOPLEFT", 52, -8)
        card.name = UI.text(card, 12, C.text)
        card.name:SetPoint("TOPLEFT", 52, -22)
        card.state = UI.text(card, 10, C.sub)
        card.state:SetPoint("TOPLEFT", 52, -38)
        v.equip[i] = card
    end
    local totalLabel = UI.label(left, "파티 전원에게 적용 중")
    totalLabel:SetPoint("TOPLEFT", 12, -146)
    v.totalScroll = UI.scroll(left)
    v.totalScroll:SetPoint("TOPLEFT", 12, -164)
    v.totalScroll:SetPoint("BOTTOMRIGHT", -6, 8)
    v.totals = UI.paragraph(v.totalScroll.content, 11, C.text)
    v.totals:SetPoint("TOPLEFT", 0, 0)
    v.totals:SetPoint("TOPRIGHT", -4, 0)
    if v.totals.SetSpacing then v.totals:SetSpacing(3) end

    -- 가운데: 고른 유물함
    local mid = UI.panel(v, C.panel, true)
    mid:SetPoint("TOPLEFT", left, "TOPRIGHT", 10, 0)
    mid:SetPoint("BOTTOMLEFT", left, "BOTTOMRIGHT", 10, 0)
    mid:SetWidth(352)
    v.mid = mid
    v.qIcon = UI.icon(mid, 40, QUIVER_ICON)
    v.qIcon:SetPoint("TOPLEFT", 12, -12)
    v.qName = UI.text(mid, 14, C.text)
    v.qName:SetPoint("TOPLEFT", 62, -14)
    v.qGrade = UI.text(mid, 11, C.sub)
    v.qGrade:SetPoint("TOPLEFT", 62, -34)
    v.qStats = UI.paragraph(mid, 11, C.text)
    v.qStats:SetPoint("TOPLEFT", 14, -62)
    v.qStats:SetPoint("TOPRIGHT", -14, -62)
    if v.qStats.SetSpacing then v.qStats:SetSpacing(3) end
    local sockLabel = UI.label(mid, "유물 칸   왼쪽 클릭: 고른 유물 끼우기 · 오른쪽 클릭: 빼기")
    sockLabel:SetPoint("BOTTOMLEFT", 14, 116)
    v.sockets = {}
    for i = 1, MAX_SOCKETS do
        local b = UI.slot(mid, 36)
        b:SetPoint("BOTTOMLEFT", 14 + (i - 1) * 41, 74)
        b.mark = UI.fill(b, C.line, "OVERLAY")
        b.mark:SetPoint("BOTTOMLEFT", 2, 2)
        b.mark:SetPoint("BOTTOMRIGHT", -2, 2)
        b.mark:SetHeight(3)
        b.index = i
        b.onClick = function(self, button)
            local s = App.state
            local q = v.quiver and s.relics.items[v.quiver]
            if not q then return end
            local ok, why = true, nil
            if button == "RightButton" then
                if q.sockets[i] then ok, why = Relics.unsocket(s, q.uid, i) end
            elseif v.pick and s.relics.items[v.pick] and s.relics.items[v.pick].kind == "RELIC" then
                ok, why = Relics.socket(s, q.uid, i, v.pick)
                if ok then v.pick = nil end
            elseif q.sockets[i] then
                v.pick = q.sockets[i]
                v.listKind = "RELIC"
            else
                ok, why = false, "오른쪽 목록에서 끼울 유물을 먼저 고르세요."
            end
            if ok then v.dirty = true end
            if not ok and why then WIH.Main.notice(why, C.bad) end
            App.notify("relics")
            UI.screens.runes.paintRelics(f)
        end
        v.sockets[i] = b
    end
    local function act(fn)
        return function()
            local ok, why = fn(App.state)
            if ok then v.dirty = true end
            if not ok and why then WIH.Main.notice(why, C.bad) end
            App.notify("relics")
            UI.screens.runes.paintRelics(f)
        end
    end
    v.eq1 = UI.button(mid, "칸 1에 장착", 106, 24, act(function(s)
        if Relics.equippedSlot(s, v.quiver) == 1 then return Relics.equip(s, 1, nil) end
        return Relics.equip(s, 1, v.quiver)
    end))
    v.eq1:SetPoint("BOTTOMLEFT", 14, 40)
    v.eq2 = UI.button(mid, "칸 2에 장착", 106, 24, act(function(s)
        if Relics.equippedSlot(s, v.quiver) == 2 then return Relics.equip(s, 2, nil) end
        return Relics.equip(s, 2, v.quiver)
    end))
    v.eq2:SetPoint("LEFT", v.eq1, "RIGHT", 6, 0)
    v.fill = UI.button(mid, "자동 끼우기", 106, 24, act(function(s)
        local n = Relics.autoFill(s, v.quiver)
        if n == 0 then return false, "끼울 수 있는 유물이 없습니다." end
        WIH.Main.notice("유물 " .. n .. "개를 끼웠습니다.", C.good)
        return true
    end))
    v.fill:SetPoint("LEFT", v.eq2, "RIGHT", 6, 0)
    v.fill.tooltip = { title = "자동 끼우기", lines = { "빈 칸에 맞는 색의 유물을 끼웁니다.", "공명 조건에 필요한 색과 등급이 높은 것을 먼저 고릅니다." } }
    v.qAttune = UI.button(mid, "조율", 164, 24, act(function(s)
        local ok, cost = Relics.attune(s, v.quiver, WIH.Rng.new(math.floor((WIH.App.now and WIH.App.now() or 0) * 1000) + s.relics.nextUid))
        if ok then WIH.Main.notice("칸 색을 다시 정했습니다. " .. UI.number(cost) .. " G", C.good) end
        return ok, cost
    end))
    v.qAttune:SetPoint("BOTTOMLEFT", 14, 10)
    v.qAttune.tooltip = { title = "조율", lines = { "유물함의 칸 색을 모두 다시 정합니다.", "새 색과 맞지 않는 유물은 빠집니다.", "할 때마다 비용이 오릅니다(19번까지)." } }
    v.qSell = UI.button(mid, "팔기", 160, 24, act(function(s)
        local ok, gold = Relics.sell(s, v.quiver)
        if ok then v.quiver = nil; WIH.Main.notice("유물함을 팔았습니다. +" .. UI.number(gold) .. " G", C.good) end
        return ok, gold
    end))
    v.qSell:SetPoint("LEFT", v.qAttune, "RIGHT", 6, 0)
    v.qEmpty = UI.paragraph(mid, 12, C.dim)
    v.qEmpty:SetPoint("TOPLEFT", 14, -16)
    v.qEmpty:SetPoint("TOPRIGHT", -14, -16)

    -- 오른쪽: 목록
    local right = UI.panel(v, C.panel, true)
    right:SetPoint("TOPLEFT", mid, "TOPRIGHT", 10, 0)
    right:SetPoint("BOTTOMRIGHT", -14, 10)
    v.kindSeg = UI.segment(right, { { "RELIQUARY", "유물함" }, { "RELIC", "유물" } }, 200, function(id)
        v.listKind = id
        UI.screens.runes.paintRelics(f)
    end)
    v.kindSeg:SetPoint("TOPLEFT", 10, -10)
    v.count = UI.text(right, 10, C.dim, "RIGHT")
    v.count:SetPoint("TOPRIGHT", -10, -16)
    v.list = UI.scroll(right)
    v.list:SetPoint("TOPLEFT", 10, -42)
    v.list:SetPoint("BOTTOMRIGHT", -6, 100)
    v.rows = {}
    v.listEmpty = UI.paragraph(right, 11, C.dim)
    v.listEmpty:SetPoint("TOPLEFT", 12, -48)
    v.listEmpty:SetPoint("TOPRIGHT", -12, -48)
    -- 고른 유물
    v.pInfo = UI.paragraph(right, 11, C.text)
    v.pInfo:SetPoint("BOTTOMLEFT", 12, 40)
    v.pInfo:SetPoint("BOTTOMRIGHT", -12, 40)
    v.pAttune = UI.button(right, "조율", 130, 24, act(function(s)
        local ok, cost = Relics.attune(s, v.pick, WIH.Rng.new(math.floor((WIH.App.now and WIH.App.now() or 0) * 1000) + s.relics.nextUid))
        if ok then WIH.Main.notice("수치를 다시 정했습니다. " .. UI.number(cost) .. " G", C.good) end
        return ok, cost
    end))
    v.pAttune:SetPoint("BOTTOMLEFT", 10, 10)
    v.pAttune.tooltip = { title = "조율", lines = { "유물의 수치를 등급 범위 안에서 다시 정합니다.", "할 때마다 비용이 오릅니다(19번까지)." } }
    v.pSell = UI.button(right, "팔기", 100, 24, act(function(s)
        local ok, gold = Relics.sell(s, v.pick)
        if ok then v.pick = nil; WIH.Main.notice("유물을 팔았습니다. +" .. UI.number(gold) .. " G", C.good) end
        return ok, gold
    end))
    v.pSell:SetPoint("LEFT", v.pAttune, "RIGHT", 6, 0)
end

local function relicRow(v, n)
    local r = v.rows[n]
    if r then return r end
    r = UI.listRow(v.list.content, 286, 34, function(btn)
        local item = btn.item
        if not item then return end
        if item.kind == "RELIQUARY" then v.quiver = item.uid else v.pick = (v.pick ~= item.uid) and item.uid or nil end
        UI.screens.runes.paintRelics(v.owner)
    end)
    r:SetPoint("TOPLEFT", 0, -(n - 1) * 36)
    r.icon = UI.icon(r, 26)
    r.icon:SetPoint("LEFT", 6, 0)
    r.name = UI.text(r, 11, C.text)
    r.name:SetPoint("TOPLEFT", 40, -4)
    r.sub = UI.text(r, 10, C.sub)
    r.sub:SetPoint("TOPLEFT", 40, -19)
    r.right = UI.text(r, 10, C.dim, "RIGHT")
    r.right:SetPoint("TOPRIGHT", -8, -4)
    v.rows[n] = r
    return r
end

local function paintRelics(f)
    local s = App.state
    local v = f.relicView
    v.owner = f
    Relics.ensure(s)
    local r = s.relics
    local slots = Relics.slotCount(s)
    if v.quiver and not r.items[v.quiver] then v.quiver = nil end
    if v.pick and not r.items[v.pick] then v.pick = nil end
    if not v.quiver then v.quiver = r.equipped[1] or r.equipped[2] end
    if not v.quiver then
        local first = Relics.list(s, "RELIQUARY")[1]
        v.quiver = first and first.uid
    end

    -- 위: 안내
    local head
    if slots == 0 then
        head = "|cffc9a45c원정(줄구룹·안퀴라즈)을 한 번 클리어하면 유물함 칸이 열립니다.|r"
    else
        head = string.format("유물함 칸 %d / 2", slots) .. (slots < 2 and "   ·   지옥 원정 강도 10을 클리어하면 2번째 칸이 열립니다." or "")
    end
    v.summary:SetText(head .. "\n|cff666b74오염된 유물함·유물은 원정 상자에서 나오고, 큐브의 기원에서 유물함·유물로 바뀝니다.|r")

    v.apply:setEnabled(v.dirty == true and App.session ~= nil)

    -- 왼쪽: 장착 칸
    for i, card in ipairs(v.equip) do
        local q = r.equipped[i] and r.items[r.equipped[i]]
        card.title:SetText("유물함 칸 " .. i .. (i > slots and "  (잠김)" or ""))
        if q then
            card.name:SetText(Relics.name(q))
            card.name:SetTextColor(UI.rgb(gradeColor(q.grade)))
            card.state:SetText(relicStatusText(s, q))
            card.icon:SetAlpha(1)
        else
            card.name:SetText(i > slots and "—" or "비어 있음")
            card.name:SetTextColor(UI.rgb(C.dim))
            card.state:SetText(i > slots and "" or "오른쪽 목록에서 유물함을 고른 뒤 장착하세요.")
            card.icon:SetAlpha(0.3)
        end
        card:setSelected(q ~= nil and v.quiver == q.uid)
    end
    local lines, effects = Relics.summaryLines(s)
    local text = {}
    for _, l in ipairs(lines) do text[#text + 1] = l end
    if #effects > 0 then
        text[#text + 1] = " "
        text[#text + 1] = "|cff6fb07f발동 중인 공명|r"
        for _, e in ipairs(effects) do text[#text + 1] = "· " .. e end
    end
    if #text == 0 then text[1] = "|cff666b74장착한 유물함이 없습니다.|r" end
    v.totals:SetText(table.concat(text, "\n"))
    v.totalScroll:setHeight((v.totals:GetStringHeight() or 100) + 10)

    -- 가운데: 고른 유물함
    local q = v.quiver and r.items[v.quiver]
    local showQ = q ~= nil
    for _, w in ipairs({ v.qIcon, v.qName, v.qGrade, v.qStats, v.eq1, v.eq2, v.fill, v.qAttune, v.qSell }) do w:SetShown(showQ) end
    v.qEmpty:SetShown(not showQ)
    if not showQ then
        v.qEmpty:SetText("가진 유물함이 없습니다.\n\n원정 상자에서 나오는 '오염된 유물함'을 큐브의 기원에 바치면 유물함을 얻습니다.")
        for _, b in ipairs(v.sockets) do b:Hide() end
    else
        local def = WIH.RelicTable.RELIQUARIES[q.id]
        v.qName:SetText(Relics.name(q))
        v.qName:SetTextColor(UI.rgb(gradeColor(q.grade)))
        local at = Relics.equippedSlot(s, q.uid)
        v.qGrade:SetText(gradeName(q.grade) .. " 유물함" .. (at and ("  ·  칸 " .. at .. "에 장착") or ""))
        local st = { "|cff9aa0a8고정 속성|r" }
        for _, line in ipairs(q.stats) do st[#st + 1] = "  " .. Relics.statText(line[1], line[2], line[3]) end
        st[#st + 1] = " "
        local cond = {}
        local counts = Relics.colorCounts(s, q)
        for _, c in ipairs({ "RED", "BLUE", "YELLOW", "PURPLE" }) do
            if def.cond[c] then cond[#cond + 1] = colorHex(c) .. Relics.COLOR_NAMES[c] .. " " .. (counts[c] or 0) .. "/" .. def.cond[c] .. "|r" end
        end
        st[#st + 1] = "|cff9aa0a8공명 조건|r  " .. table.concat(cond, "  ")
        st[#st + 1] = "  " .. Relics.effectText(q)
        st[#st + 1] = "  " .. relicStatusText(s, q)
        v.qStats:SetText(table.concat(st, "\n"))
        for i, b in ipairs(v.sockets) do
            local color = q.slots[i]
            b:SetShown(color ~= nil)
            if color then
                local relic = q.sockets[i] and r.items[q.sockets[i]]
                local rgb = Relics.COLOR_RGB[color]
                b.mark:SetColorTexture(rgb[1], rgb[2], rgb[3], 1)
                b:setIcon(relic and iconOf(relic) or nil, relic and gradeColor(relic.grade) or rgb)
                b.center:SetText(relic and "" or Relics.COLOR_NAMES[color])
                b.tooltip = relic and relicTooltip(relic) or { title = Relics.COLOR_NAMES[color] .. " 칸", lines = { Relics.COLOR_NAMES[color] .. " 유물이나 하얀 유물을 끼울 수 있습니다." } }
            end
        end
        v.eq1:setEnabled(slots >= 1)
        v.eq1:setText(at == 1 and "칸 1에서 빼기" or "칸 1에 장착")
        v.eq2:setEnabled(slots >= 2)
        v.eq2:setText(at == 2 and "칸 2에서 빼기" or "칸 2에 장착")
        v.fill:setEnabled(#q.slots > 0)
        local cost = Relics.attuneCost(q)
        v.qAttune:setText("조율  " .. UI.number(cost) .. " G")
        v.qAttune:setEnabled(#q.slots > 0 and s.gold >= cost)
        v.qSell:setText("팔기  +" .. UI.number(WIH.Items.GRADES[q.grade].gold * 12) .. " G")
        v.qSell:setEnabled(at == nil)
    end

    -- 오른쪽: 목록
    v.kindSeg:pick(v.listKind)
    local list = Relics.list(s, v.listKind)
    v.count:SetText(#list .. "개")
    for n, item in ipairs(list) do
        local row = relicRow(v, n)
        row.item = item
        row.icon:set(iconOf(item))
        row.name:SetText(Relics.name(item))
        row.name:SetTextColor(UI.rgb(gradeColor(item.grade)))
        if item.kind == "RELIQUARY" then
            local at = Relics.equippedSlot(s, item.uid)
            local used = 0
            for _ in pairs(item.sockets) do used = used + 1 end
            row.sub:SetText(gradeName(item.grade) .. " · 칸 " .. used .. "/" .. #item.slots .. " · " .. Relics.condText(item))
            row.right:SetText(at and ("장착 " .. at) or "")
            row:setSelected(v.quiver == item.uid)
            row.tooltip = { title = Relics.name(item), lines = { Relics.effectText(item), relicStatusText(s, item) } }
        else
            local def = WIH.RelicTable.RELICS[item.id]
            row.sub:SetText(colorHex(def.color) .. Relics.COLOR_NAMES[def.color] .. "|r · " .. relicLine(item))
            row.right:SetText(item.holder and "끼움" or "")
            row:setSelected(v.pick == item.uid)
            row.tooltip = relicTooltip(item)
        end
        row:Show()
    end
    for i = #list + 1, #v.rows do v.rows[i]:Hide() end
    v.list:setHeight(#list * 36)
    v.listEmpty:SetShown(#list == 0)
    v.listEmpty:SetText(v.listKind == "RELIQUARY" and "가진 유물함이 없습니다." or "가진 유물이 없습니다.\n\n원정 상자의 '오염된 유물'을 큐브의 기원에 바치면 유물을 얻습니다.")

    local p = v.pick and r.items[v.pick]
    v.pInfo:SetShown(p ~= nil)
    v.pAttune:SetShown(p ~= nil)
    v.pSell:SetShown(p ~= nil)
    if p then
        local holder = p.holder and r.items[p.holder]
        v.pInfo:SetText("|cff9aa0a8고른 유물|r  " .. Relics.name(p) .. " [" .. gradeName(p.grade) .. "]\n" .. relicLine(p)
            .. (holder and ("\n" .. Relics.name(holder) .. "에 끼워져 있음") or "\n가운데 유물함의 칸을 누르면 끼웁니다."))
        local cost = Relics.attuneCost(p)
        v.pAttune:setText("조율  " .. UI.number(cost) .. " G")
        v.pAttune:setEnabled(s.gold >= cost)
        v.pSell:setText("팔기")
    end
end

UI.screens.runes = { label = "성장", order = 6, create = create, refresh = refresh, update = update, paint = paint, onShow = onShow,
    createPets = createPets, paintPets = paintPets, createRelics = createRelics, paintRelics = paintRelics }
