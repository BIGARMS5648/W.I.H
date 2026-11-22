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
    f.count:SetPoint("TOPRIGHT", -12, -16)

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
    return f
end

-- 화면을 열 때만 순서를 다시 정한다. 진행 중에 오는 갱신(클리어, 상자 등)은 순서를 건드리지 않는다.
local function onShow(f)
    if App.state then rebuild(f) end
end

local function refresh(f)
    if not App.state then return end
    if not f.items then rebuild(f) end
    paint(f)
    f.summaryScroll:setHeight((f.summary:GetStringHeight() or 200) + 10)
end

-- 골드는 전투 중에 계속 늘어난다. 순서는 건드리지 않고 살 수 있는지만 다시 칠한다.
local function update(f, elapsed)
    f.acc = f.acc + elapsed
    if f.acc < 0.5 then return end
    f.acc = 0
    local s = App.state
    if s and math.floor(s.gold) ~= f.lastGold then paint(f) end
    f.summaryScroll:setHeight((f.summary:GetStringHeight() or 200) + 10)
end

UI.screens.runes = { label = "성장", order = 6, create = create, refresh = refresh, update = update, paint = paint, onShow = onShow }
