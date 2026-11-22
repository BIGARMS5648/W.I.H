-- 큐브 화면: 왼쪽 레시피 목록(해금), 오른쪽 작업 영역. 규칙은 Inventory/Cube.lua가 판단한다.

local _, WIH = ...
local UI = WIH.module("UI")
local App = WIH.module("App")
local Game = WIH.module("Game")
local Items = WIH.module("Items")
local Inventory = WIH.module("Inventory")
local Materials = WIH.module("Materials")
local Cube = WIH.module("Cube")
local CubeTable = WIH.module("CubeTable")

local C = UI.C
local LIST_W = 214
local PAGES = { "SYNTHESIS", "CRAFTING", "DECORATION", "ENGRAVING", "INSCRIPTION", "EXTRACTION", "OFFERING", "ALCHEMY" }
local PAGE_TEXT = {
    SYNTHESIS = "같은 등급·같은 분류 9개를 넣으면 무작위 1개가 나옵니다. 전설 이하는 반드시 등급이 오르고, 불멸부터는 실패하면 같은 등급이 나옵니다. 등급이 떨어지거나 사라지는 일은 없습니다.",
    CRAFTING = "부위와 단계를 고르고 재료를 넣으면 그 부위의 무작위 장비가 나옵니다. 일반 등급은 나오지 않습니다.",
    DECORATION = "희귀 이상 장비의 장식 칸에 보석을 넣어 능력치 한 줄을 붙입니다.",
    ENGRAVING = "불멸 이상 장비의 세공 칸에 재료를 넣어 두 후보 중 하나를 붙입니다.",
    INSCRIPTION = "아르카나 이상 장비의 각인 칸에 두루마리를 넣어 여러 후보 중 하나를 붙입니다.",
    EXTRACTION = "붙인 능력치 한 줄을 골드를 내고 지웁니다. 넣은 재료는 돌아오지 않습니다.",
    OFFERING = "공물 주화와 수수료를 바쳐 무작위 아이템을 얻습니다.",
    ALCHEMY = "재료를 골드로 바꿉니다. 장비의 연금술은 가방 화면의 '팔기'입니다.",
}
local GRADE_TEXT = function(g) return Items.GRADES[g].name end

local function note(ok, why, good)
    if not ok then WIH.Main.notice(why, C.bad) elseif good then WIH.Main.notice(good, C.good) end
end

local function resultText(r)
    if not r then return "" end
    local text = WIH.Chests.resultText(r)
    if r.ups and r.ups > 0 then text = text .. "  ·  큐브 레벨 " .. App.state.cube.level end
    return text
end

-- 인벤토리와 낀 장비를 한 목록으로: { entry, item, where = "inventory"|"영웅 이름", index }
local function allGear(s)
    local list = {}
    for i, entry in ipairs(s.inventory.items) do
        local item = Items.byId[entry.id]
        if item then list[#list + 1] = { entry = entry, item = item, index = i } end
    end
    for _, heroId in ipairs(s.party) do
        local h = s.heroes[heroId]
        for _, slot in ipairs(Items.SLOTS) do
            local entry = h.gear[slot]
            local item = entry and Items.byId[entry.id]
            if item then list[#list + 1] = { entry = entry, item = item, hero = WIH.Heroes.byId[heroId].name } end
        end
    end
    return list
end

------------------------------------------------------------------------
-- 공용 부품
------------------------------------------------------------------------

local function rowList(f, parent, width, height, onClick)
    local sf = UI.scroll(parent)
    sf.rows = {}
    function sf:row(n)
        local r = self.rows[n]
        if r then return r end
        r = UI.listRow(self.content, width, height, function(btn, button) onClick(btn, button) end)
        r:SetPoint("TOPLEFT", 0, -(n - 1) * (height + 2))
        r.icon = UI.icon(r, height - 8)
        r.icon:SetPoint("LEFT", 6, 0)
        r.name = UI.text(r, 12, C.text)
        r.name:SetPoint("LEFT", height + 4, 0)
        r.right = UI.text(r, 11, C.sub, "RIGHT")
        r.right:SetPoint("RIGHT", -8, 0)
        self.rows[n] = r
        return r
    end
    function sf:finish(n)
        for i = n + 1, #self.rows do self.rows[i]:Hide() end
        self:setHeight(n * (height + 2))
    end
    return sf
end

------------------------------------------------------------------------
-- 만들기
------------------------------------------------------------------------

local function create(parent)
    local f = CreateFrame("Frame", nil, parent)
    f.page = "SYNTHESIS"
    f.picked = {}            -- 합성에 고른 인벤토리 번호
    f.tier, f.class, f.grade = 1, "Gear", 1
    f.part, f.craftTier = "MAIN", 1

    -- 왼쪽: 큐브 레벨과 레시피
    f.levelText = UI.text(f, 14, C.text)
    f.levelText:SetPoint("TOPLEFT", 14, -14)
    f.expBar = UI.bar(f, LIST_W - 28, 3, C.exp)
    f.expBar:SetPoint("TOPLEFT", 14, -38)
    f.expText = UI.text(f, 10, C.dim)
    f.expText:SetPoint("TOPLEFT", 14, -46)
    f.recipes = {}
    for i, kind in ipairs(PAGES) do
        local r = UI.listRow(f, LIST_W - 20, 34, function()
            f.page = kind
            f.selectedEntry, f.selectedMat, f.selectedLine = nil, nil, nil
            UI.screens.cube.refresh(f)
        end)
        r:SetPoint("TOPLEFT", 10, -64 - (i - 1) * 36)
        r.name = UI.text(r, 12, C.text)
        r.name:SetPoint("LEFT", 10, 0)
        r.name:SetText(Cube.NAMES[kind])
        r.right = UI.text(r, 10, C.dim, "RIGHT")
        r.right:SetPoint("RIGHT", -8, 0)
        r.kind = kind
        f.recipes[i] = r
    end
    local line = UI.fill(f, C.line, "ARTWORK")
    line:SetPoint("TOPLEFT", LIST_W, 0)
    line:SetPoint("BOTTOMLEFT", LIST_W, 0)
    line:SetWidth(1)

    -- 오른쪽 위: 제목, 설명, 해금 버튼
    local X = LIST_W + 16
    f.title = UI.text(f, 16, C.text)
    f.title:SetPoint("TOPLEFT", X, -14)
    f.desc = UI.paragraph(f, 11, C.sub)
    f.desc:SetPoint("TOPLEFT", X, -38)
    f.desc:SetPoint("TOPRIGHT", -14, -38)
    f.unlock = UI.button(f, "", 180, 26, function()
        note(Cube.unlock(App.state, f.unlockRecipe))
        UI.screens.cube.refresh(f)
    end)
    f.unlock:SetPoint("TOPRIGHT", -14, -10)

    -- 작업 영역(쪽마다 다른 부품을 보이고 숨긴다)
    local area = CreateFrame("Frame", nil, f)
    area:SetPoint("TOPLEFT", X, -74)
    area:SetPoint("BOTTOMRIGHT", -14, 44)
    f.area = area

    -- 선택 칩 줄 두 개(단계·분류·등급·부위)
    f.chipRows = {}
    for r = 1, 3 do
        f.chipRows[r] = { chips = {}, label = UI.label(area, "") }
        f.chipRows[r].label:SetPoint("TOPLEFT", 0, -(r - 1) * 28 - 5)
    end

    -- 합성: 9칸
    f.slots = {}
    for i = 1, Cube.SLOTS do
        local b = UI.slot(area, 40)
        b:SetPoint("TOPLEFT", 64 + (i - 1) * 45, -92)
        b.onClick = function()
            if f.picked[i] then table.remove(f.picked, i); UI.screens.cube.refresh(f) end
        end
        f.slots[i] = b
    end
    f.auto = UI.button(area, "자동 채우기", 92, 26, function()
        UI.screens.cube.autofill(f)
        UI.screens.cube.refresh(f)
    end)
    f.auto:SetPoint("TOPLEFT", 64 + 9 * 45 + 6, -98)
    f.auto.tooltip = { title = "자동 채우기", lines = { "고른 등급·분류의 장비 가운데 잠그지 않은 것을 레벨이 낮은 것부터 9개 넣습니다. 낀 장비는 넣지 않습니다." } }
    f.odds = UI.paragraph(area, 12, C.sub)
    f.odds:SetPoint("TOPLEFT", 64, -142)
    f.odds:SetPoint("TOPRIGHT", 0, -142)
    if f.odds.SetSpacing then f.odds:SetSpacing(4) end

    -- 목록 두 개(대상, 재료)
    f.leftList = rowList(f, area, 300, 30, function(btn, button) UI.screens.cube.pickLeft(f, btn, button) end)
    f.leftList:SetPoint("TOPLEFT", 0, -22)
    f.leftList:SetSize(300, 300)
    f.leftLabel = UI.label(area, "")
    f.leftLabel:SetPoint("TOPLEFT", 0, -4)
    f.rightList = rowList(f, area, 300, 30, function(btn, button) UI.screens.cube.pickRight(f, btn, button) end)
    f.rightList:SetPoint("TOPLEFT", 318, -22)
    f.rightList:SetSize(300, 300)
    f.rightLabel = UI.label(area, "")
    f.rightLabel:SetPoint("TOPLEFT", 318, -4)

    -- 아래: 실행 버튼과 결과
    f.go = UI.button(f, "", 140, 30, function() UI.screens.cube.run(f) end)
    f.go:SetPoint("BOTTOMRIGHT", -14, 10)
    f.result = UI.text(f, 12, C.text)
    f.result:SetPoint("BOTTOMLEFT", X, 18)
    f.result:SetPoint("RIGHT", f.go, "LEFT", -12, 0)
    return f
end

------------------------------------------------------------------------
-- 칩 줄
------------------------------------------------------------------------

local function chipRow(f, r, label, items, current, onPick)
    local row = f.chipRows[r]
    row.label:SetText(label)
    row.label:Show()
    local x = 64
    for i, it in ipairs(items) do
        local b = row.chips[i]
        if not b then
            b = UI.chip(f.area, "", function(self) self.onPick(self.value) end)
            row.chips[i] = b
        end
        b.value, b.onPick = it[1], onPick
        b:setText(it[2])
        b:SetWidth((b.label:GetStringWidth() or 30) + 18)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", x, -(r - 1) * 28)
        b:setSelected(it[1] == current)
        b:setEnabled(it[3] ~= false)
        b:Show()
        x = x + b:GetWidth() + 4
    end
    for i = #items + 1, #row.chips do row.chips[i]:Hide() end
end

local function hideChipRow(f, r)
    f.chipRows[r].label:Hide()
    for _, b in ipairs(f.chipRows[r].chips) do b:Hide() end
end

------------------------------------------------------------------------
-- 쪽별 그리기
------------------------------------------------------------------------

local function oddsText(list, fmt)
    local parts = {}
    for _, e in ipairs(list) do parts[#parts + 1] = fmt(e[1]) .. " " .. string.format("%.1f%%", e[2] * 100) end
    return table.concat(parts, "   ")
end

local function synthesisCandidates(f, s)
    local out = {}
    if f.class == "Material" then return out end
    for i, entry in ipairs(s.inventory.items) do
        local item = Items.byId[entry.id]
        if item and not entry.lock and item.grade == f.grade and Cube.classOf(item) == f.class then
            out[#out + 1] = { index = i, item = item }
        end
    end
    table.sort(out, function(a, b)
        if a.item.level ~= b.item.level then return a.item.level < b.item.level end
        return a.index < b.index
    end)
    return out
end

local function materialStock(s, grade)
    local out = {}
    for id, n in pairs(s.materials) do
        local def = Materials.defs[id]
        if def and def.grade == grade and def.kind ~= "SOULSTONE" and def.kind ~= "OFFERING" then out[#out + 1] = { id, n } end
    end
    table.sort(out, function(a, b) return a[1] < b[1] end)
    return out
end

local function paintSynthesis(f, s)
    local tiers = {}
    for t = 1, 9 do
        local r = Cube.find("SYNTHESIS", t)
        tiers[#tiers + 1] = { t, t .. "단계", Cube.unlocked(s, r) }
    end
    chipRow(f, 1, "단계", tiers, f.tier, function(v) f.tier = v; f.picked = {}; UI.screens.cube.refresh(f) end)
    chipRow(f, 2, "분류", { { "Gear", "장비" }, { "Accessory", "장신구" }, { "Material", "재료" } }, f.class,
        function(v) f.class = v; f.picked = {}; UI.screens.cube.refresh(f) end)
    local grades = {}
    for g = 1, 9 do grades[#grades + 1] = { g, GRADE_TEXT(g) } end
    chipRow(f, 3, "등급", grades, f.grade, function(v) f.grade = v; f.picked = {}; UI.screens.cube.refresh(f) end)
    for i, b in ipairs(f.slots) do b:Show() end
    f.auto:Show()
    f.odds:Show()
    local lines = {}
    if f.class == "Material" then
        local stock, total = materialStock(s, f.grade), 0
        for _, p in ipairs(stock) do total = total + p[2] end
        f.matPick = {}
        local need = Cube.SLOTS
        for _, p in ipairs(stock) do
            local take = math.min(p[2], need)
            if take > 0 then f.matPick[#f.matPick + 1] = { p[1], take }; need = need - take end
        end
        local k = 0
        for _, p in ipairs(f.matPick) do
            for _ = 1, p[2] do
                k = k + 1
                f.slots[k]:setIcon(Materials.defs[p[1]].icon, Items.GRADES[f.grade].color)
                f.slots[k].tooltip = { title = Materials.name(p[1]) }
            end
        end
        for i = k + 1, Cube.SLOTS do f.slots[i]:setIcon(nil, C.line); f.slots[i].tooltip = nil end
        lines[#lines + 1] = string.format("가진 %s 등급 재료 %d개  ·  종류는 섞어도 됩니다(증표·기원 재료 제외)", GRADE_TEXT(f.grade), total)
        f.ready = k == Cube.SLOTS
        f.auto:Hide()
    else
        local levels = 0
        for i, b in ipairs(f.slots) do
            local index = f.picked[i]
            local entry = index and s.inventory.items[index]
            local item = entry and Items.byId[entry.id]
            if item then
                b:setIcon(item.icon, Items.GRADES[item.grade].color)
                b.corner:SetText(tostring(item.level))
                b.tooltip = UI.itemTip(item, entry)
                levels = levels + item.level
            else
                b:setIcon(nil, C.line); b.corner:SetText(""); b.tooltip = nil
            end
        end
        local n = #f.picked
        f.ready = n == Cube.SLOTS
        if n > 0 then
            local avg = levels / n
            local lodds = Cube.levelOdds(f.class, f.tier, f.grade, avg)
            if lodds and #lodds > 0 then
                local total = 0
                for _, e in ipairs(lodds) do total = total + e[2] end
                local norm = {}
                for _, e in ipairs(lodds) do norm[#norm + 1] = { e[1], e[2] / total } end
                lines[#lines + 1] = string.format("평균 레벨 %.1f  ·  결과 레벨  ", avg) .. oddsText(norm, function(v) return "Lv" .. v end)
            else
                lines[#lines + 1] = "|cffcf5f58이 단계에서는 이 등급을 합성할 수 없습니다.|r"
                f.ready = false
            end
        else
            lines[#lines + 1] = "자동 채우기를 누르거나 가방에서 같은 등급 장비를 모아 오세요. 넣은 칸을 누르면 뺍니다."
        end
    end
    local godds = Cube.gradeOdds(f.grade)
    if godds then lines[#lines + 1] = "결과 등급  " .. oddsText(godds, GRADE_TEXT) end
    f.odds:SetText(table.concat(lines, "\n"))
    f.go:setText("합성")
    f.go:setEnabled(f.ready and Cube.unlocked(s, Cube.find("SYNTHESIS", f.tier)))
end

local CRAFT_PARTS = { { "MAIN", "주무기" }, { "SUB", "보조무기" }, { "HELMET", "투구" }, { "ARMOR", "갑옷" }, { "GLOVES", "장갑" },
    { "BOOTS", "신발" }, { "ACC", "장신구" } }
local CRAFT_LEVELS = { "1~10", "10~20", "20~30", "30~40", "40~50", "50~65", "65~80", "80", "90" }

local function craftOdds(tableId)
    local grades, levels, total = {}, {}, 0
    for _, e in ipairs(CubeTable.tables[tableId]) do
        if e[2] ~= "MAT" then
            grades[e[4]] = (grades[e[4]] or 0) + e[1]
            levels[e[3]] = (levels[e[3]] or 0) + e[1]
            total = total + e[1]
        end
    end
    local g, l = {}, {}
    for k, v in pairs(grades) do g[#g + 1] = { k, v / total } end
    for k, v in pairs(levels) do l[#l + 1] = { k, v / total } end
    table.sort(g, function(a, b) return a[1] < b[1] end)
    table.sort(l, function(a, b) return a[1] < b[1] end)
    return g, l
end

local function paintCrafting(f, s)
    local tiers = {}
    for t = 1, 9 do tiers[#tiers + 1] = { t, "Lv" .. CRAFT_LEVELS[t], Cube.unlocked(s, Cube.find("CRAFTING", t)) } end
    chipRow(f, 1, "단계", tiers, f.craftTier, function(v) f.craftTier = v; UI.screens.cube.refresh(f) end)
    chipRow(f, 2, "부위", CRAFT_PARTS, f.part, function(v) f.part = v; UI.screens.cube.refresh(f) end)
    hideChipRow(f, 3)
    f.odds:Show()
    local mats = Cube.craftCost(f.part, f.craftTier) or {}
    local lines, ok = {}, true
    for i, m in ipairs(mats) do
        local have = s.materials[m[1]] or 0
        if have < m[2] then ok = false end
        lines[#lines + 1] = string.format("%s%s  %d / %d|r", have >= m[2] and "|cffe8e9ec" or "|cffcf5f58", Materials.name(m[1]), have, m[2])
        local b = f.slots[i]
        b:Show()
        b:setIcon(Materials.defs[m[1]].icon, Items.GRADES[Materials.defs[m[1]].grade].color)
        b.corner:SetText(tostring(m[2]))
        b.tooltip = { title = Materials.name(m[1]), lines = { "가진 수 " .. have } }
    end
    for i = #mats + 1, Cube.SLOTS do f.slots[i]:Hide() end
    local c = CubeTable.CRAFT[f.part][f.craftTier]
    local g, l = craftOdds(c.table)
    lines[#lines + 1] = "결과 등급  " .. oddsText(g, GRADE_TEXT)
    lines[#lines + 1] = "결과 레벨  " .. oddsText(l, function(v) return "Lv" .. v end)
    f.odds:SetText(table.concat(lines, "\n"))
    f.ready = ok
    f.go:setText("제작")
    f.go:setEnabled(ok and Cube.unlocked(s, Cube.find("CRAFTING", f.craftTier)))
end

local function paintAttach(f, s, kind)
    hideChipRow(f, 1); hideChipRow(f, 2); hideChipRow(f, 3)
    f.leftList:Show(); f.rightList:Show(); f.leftLabel:Show(); f.rightLabel:Show(); f.odds:Show()
    f.leftLabel:SetText("장비(빈 " .. Cube.NAMES[kind] .. " 칸이 있는 것)")
    f.rightLabel:SetText("재료")
    local n = 0
    f.leftItems = {}
    for _, g in ipairs(allGear(s)) do
        local slots = Cube.slots(g.item, kind)
        if slots > 0 then
            n = n + 1
            local r = f.leftList:row(n)
            r.data = g
            r.icon:set(g.item.icon)
            UI.setBorderColor(r.icon, Items.GRADES[g.item.grade].color)
            r.name:SetText(Items.name(g.item))
            r.name:SetTextColor(UI.rgb(Items.GRADES[g.item.grade].color))
            r.right:SetText((g.hero and (g.hero .. " · ") or "") .. Cube.used(g.entry, kind) .. "/" .. slots)
            r:setSelected(f.selectedEntry == g.entry)
            r.tooltip = UI.itemTip(g.item, g.entry)
            r:Show()
        end
    end
    f.leftList:finish(n)
    local m = 0
    local ids = {}
    for id, count in pairs(s.materials) do
        if Materials.defs[id] and Materials.defs[id].kind == kind and count > 0 then ids[#ids + 1] = id end
    end
    table.sort(ids)
    for _, id in ipairs(ids) do
        m = m + 1
        local r = f.rightList:row(m)
        r.data = id
        r.icon:set(Materials.defs[id].icon)
        r.name:SetText(Materials.name(id))
        r.name:SetTextColor(UI.rgb(Items.GRADES[Materials.defs[id].grade].color))
        r.right:SetText("× " .. s.materials[id])
        r:setSelected(f.selectedMat == id)
        r.tooltip = nil
        r:Show()
    end
    f.rightList:finish(m)
    local lines = {}
    if f.selectedEntry and f.selectedMat then
        local list = Cube.candidates(f.selectedMat, Items.byId[f.selectedEntry.id]) or {}
        for _, c in ipairs(list) do
            lines[#lines + 1] = "후보  " .. Items.modText({ c[1], c[2], c[3] }) .. " ~ " .. Items.modText({ c[1], c[2], c[4] }):gsub("^[^+]*", "")
        end
        if #list > 1 then lines[#lines + 1] = "|cff666b74" .. #list .. "개 가운데 하나가 같은 확률로 붙습니다.|r" end
    else
        lines[#lines + 1] = n == 0 and ("빈 " .. Cube.NAMES[kind] .. " 칸이 있는 장비가 없습니다.") or "장비와 재료를 하나씩 고르세요."
    end
    f.odds:ClearAllPoints()
    f.odds:SetPoint("TOPLEFT", 0, -330)
    f.odds:SetPoint("TOPRIGHT", 0, -330)
    f.odds:SetText(table.concat(lines, "\n"))
    f.go:setText(Cube.NAMES[kind])
    f.go:setEnabled(f.selectedEntry ~= nil and f.selectedMat ~= nil and Cube.unlocked(s, Cube.find(kind)))
end

local function paintExtraction(f, s)
    hideChipRow(f, 1); hideChipRow(f, 2); hideChipRow(f, 3)
    f.leftList:Show(); f.rightList:Show(); f.leftLabel:Show(); f.rightLabel:Show()
    f.leftLabel:SetText("능력치를 붙인 장비")
    f.rightLabel:SetText("붙인 능력치")
    local n = 0
    for _, g in ipairs(allGear(s)) do
        if g.entry.added and #g.entry.added > 0 then
            n = n + 1
            local r = f.leftList:row(n)
            r.data = g
            r.icon:set(g.item.icon)
            r.name:SetText(Items.name(g.item))
            r.name:SetTextColor(UI.rgb(Items.GRADES[g.item.grade].color))
            r.right:SetText((g.hero and (g.hero .. " · ") or "") .. #g.entry.added .. "줄")
            r:setSelected(f.selectedEntry == g.entry)
            r.tooltip = UI.itemTip(g.item, g.entry)
            r:Show()
        end
    end
    f.leftList:finish(n)
    local m = 0
    if f.selectedEntry and f.selectedEntry.added then
        for i, a in ipairs(f.selectedEntry.added) do
            m = m + 1
            local r = f.rightList:row(m)
            r.data = i
            r.icon:set(nil)
            r.icon.tex:SetTexture(nil)
            r.name:SetText(Cube.NAMES[a.kind] .. "  " .. Items.modText({ a.stat, a.mod, a.value }))
            r.name:SetTextColor(UI.rgb(C.text))
            r.right:SetText(UI.number(Cube.extractCost(a)) .. " G")
            r:setSelected(f.selectedLine == i)
            r.tooltip = nil
            r:Show()
        end
    end
    f.rightList:finish(m)
    f.odds:Hide()
    f.go:setText("제거")
    f.go:setEnabled(f.selectedEntry ~= nil and f.selectedLine ~= nil and Cube.unlocked(s, Cube.find("EXTRACTION")))
end

local function paintMaterialList(f, s, filter, label, right)
    hideChipRow(f, 1); hideChipRow(f, 2); hideChipRow(f, 3)
    f.leftList:Show(); f.leftLabel:Show()
    f.leftLabel:SetText(label)
    local ids = {}
    for id, count in pairs(s.materials) do
        if Materials.defs[id] and count > 0 and filter(id, Materials.defs[id]) then ids[#ids + 1] = id end
    end
    table.sort(ids)
    for n, id in ipairs(ids) do
        local r = f.leftList:row(n)
        r.data = id
        r.icon:set(Materials.defs[id].icon)
        r.name:SetText(Materials.name(id) .. "  × " .. s.materials[id])
        r.name:SetTextColor(UI.rgb(Items.GRADES[Materials.defs[id].grade].color))
        r.right:SetText(right(id))
        r:setSelected(f.selectedMat == id)
        r.tooltip = nil
        r:Show()
    end
    f.leftList:finish(#ids)
    return #ids
end

local function paintOffering(f, s)
    local fees = {}
    for _, r in ipairs(Cube.recipes) do if r.kind == "OFFERING" then fees[r.material] = r.fee end end
    local n = paintMaterialList(f, s, function(id) return fees[id] ~= nil end, "공물 주화", function(id) return "수수료 " .. UI.number(fees[id]) .. " G" end)
    f.odds:Show()
    f.odds:ClearAllPoints()
    f.odds:SetPoint("TOPLEFT", 318, -22)
    f.odds:SetPoint("TOPRIGHT", 0, -22)
    local lines = {}
    if f.selectedMat then
        for _, r in ipairs(Cube.recipes) do
            if r.material == f.selectedMat then
                local g, l = craftOdds(r.table)
                lines[#lines + 1] = "장비 등급  " .. oddsText(g, GRADE_TEXT)
                lines[#lines + 1] = "장비 레벨  " .. oddsText(l, function(v) return "Lv" .. v end)
                local mat = 0
                for _, e in ipairs(CubeTable.tables[r.table]) do if e[2] == "MAT" then mat = mat + e[1] end end
                lines[#lines + 1] = string.format("재료가 나올 확률 %.1f%%", mat / 10000)
            end
        end
    else
        lines[#lines + 1] = n == 0 and "공물 주화가 없습니다. 상자와 기원에서 나옵니다." or "주화를 고르세요."
    end
    f.odds:SetText(table.concat(lines, "\n"))
    f.go:setText("기원")
    f.go:setEnabled(f.selectedMat ~= nil and s.gold >= (fees[f.selectedMat] or 0) and Cube.unlocked(s, Cube.find("OFFERING")))
end

local function paintAlchemy(f, s)
    paintMaterialList(f, s, function(_, def) return def.kind ~= "SOULSTONE" end, "재료",
        function(id) return UI.number(Items.GRADES[Materials.defs[id].grade].gold * 12) .. " G씩" end)
    f.odds:Hide()
    f.go:setText(f.selectedMat and ("모두 팔기") or "팔기")
    f.go:setEnabled(f.selectedMat ~= nil)
end

------------------------------------------------------------------------
-- 동작
------------------------------------------------------------------------

local function autofill(f)
    local s = App.state
    f.picked = {}
    for _, c in ipairs(synthesisCandidates(f, s)) do
        if #f.picked < Cube.SLOTS then f.picked[#f.picked + 1] = c.index end
    end
    if #f.picked < Cube.SLOTS then
        WIH.Main.notice(GRADE_TEXT(f.grade) .. " 등급 " .. (f.class == "Gear" and "장비" or "장신구") .. "가 " .. #f.picked .. "개뿐입니다(9개 필요).", C.warn)
    end
end

local function pickLeft(f, btn)
    if f.page == "OFFERING" or f.page == "ALCHEMY" then f.selectedMat = btn.data
    else f.selectedEntry = btn.data.entry; f.selectedLine = nil end
    UI.screens.cube.refresh(f)
end

local function pickRight(f, btn)
    if f.page == "EXTRACTION" then f.selectedLine = btn.data else f.selectedMat = btn.data end
    UI.screens.cube.refresh(f)
end

local function run(f)
    local s = App.state
    local rng = App.session and App.session.lootRng or WIH.Rng.new(1)
    local r, why
    if f.page == "SYNTHESIS" then
        if f.class == "Material" then r, why = Cube.synthesizeMaterials(s, f.matPick or {}, rng)
        else r, why = Cube.synthesize(s, f.tier, f.picked, rng) end
        f.picked = {}
        if r then f.result:SetText((r.success and "|cff6fb07f성공|r  " or "|cff9da2aa같은 등급|r  ") .. resultText(r)) end
    elseif f.page == "CRAFTING" then
        r, why = Cube.craft(s, f.part, f.craftTier, rng)
        if r then f.result:SetText("제작  " .. resultText(r)) end
    elseif f.page == "DECORATION" or f.page == "ENGRAVING" or f.page == "INSCRIPTION" then
        r, why = Cube.attach(s, f.selectedEntry, f.selectedMat, rng)
        if r then f.result:SetText(Cube.NAMES[f.page] .. "  " .. Items.modText({ r.stat, r.mod, r.value })) end
        if s.materials[f.selectedMat or 0] == nil then f.selectedMat = nil end
    elseif f.page == "EXTRACTION" then
        local cost
        r, cost = Cube.extract(s, f.selectedEntry, f.selectedLine)
        if not r then why = cost else f.result:SetText("제거  " .. UI.number(cost) .. " G") end
        f.selectedLine = nil
    elseif f.page == "OFFERING" then
        r, why = Cube.offering(s, f.selectedMat, rng)
        if r then f.result:SetText("기원  " .. resultText(r)) end
        if s.materials[f.selectedMat or 0] == nil then f.selectedMat = nil end
    elseif f.page == "ALCHEMY" then
        local gold, count = Cube.alchemyMaterial(s, f.selectedMat)
        r, why = gold, count
        if gold then f.result:SetText(Materials.name(f.selectedMat) .. " " .. count .. "개  +" .. UI.number(gold) .. " G"); f.selectedMat = nil end
    end
    if not r then WIH.Main.notice(why, C.bad) end
    App.notify("cube")
    UI.screens.cube.refresh(f)
end

------------------------------------------------------------------------
-- 그리기
------------------------------------------------------------------------

local function refresh(f)
    local s = App.state
    if not s then return end
    local c = s.cube
    f.levelText:SetText("큐브 레벨 " .. c.level)
    local need = Cube.expToNext(s)
    f.expBar:set(need and c.exp / need or 1)
    f.expText:SetText(need and (UI.number(c.exp) .. " / " .. UI.number(need)) or "최대 레벨")
    for _, r in ipairs(f.recipes) do
        local recipe = Cube.find(r.kind, (r.kind == "SYNTHESIS" or r.kind == "CRAFTING") and 1 or nil)
        local open = Cube.unlocked(s, recipe)
        r:setSelected(r.kind == f.page)
        r.right:SetText(open and "" or ("Lv" .. recipe.level))
        r.name:SetTextColor(UI.rgb(open and C.text or C.dim))
    end
    f.title:SetText(Cube.NAMES[f.page])
    f.desc:SetText(PAGE_TEXT[f.page])
    -- 해금 버튼: 이 쪽의 다음 레시피(단계가 있으면 고른 단계)
    local tier = f.page == "SYNTHESIS" and f.tier or (f.page == "CRAFTING" and f.craftTier or nil)
    local recipe = Cube.find(f.page, tier)
    f.unlockRecipe = recipe
    local locked = recipe and not Cube.unlocked(s, recipe)
    f.unlock:SetShown(locked and true or false)
    if locked then
        f.unlock:setText(string.format("열기  큐브 Lv%d · %s G", recipe.level, UI.number(recipe.cost)))
        f.unlock:setEnabled(c.level >= recipe.level and s.gold >= recipe.cost)
    end
    -- 부품 초기화
    for _, b in ipairs(f.slots) do b:Hide() end
    f.auto:Hide(); f.odds:Hide()
    f.leftList:Hide(); f.rightList:Hide(); f.leftLabel:Hide(); f.rightLabel:Hide()
    f.odds:ClearAllPoints()
    f.odds:SetPoint("TOPLEFT", 64, -142)
    f.odds:SetPoint("TOPRIGHT", 0, -142)
    if f.page == "SYNTHESIS" then paintSynthesis(f, s)
    elseif f.page == "CRAFTING" then paintCrafting(f, s)
    elseif f.page == "EXTRACTION" then paintExtraction(f, s)
    elseif f.page == "OFFERING" then paintOffering(f, s)
    elseif f.page == "ALCHEMY" then paintAlchemy(f, s)
    else paintAttach(f, s, f.page) end
end

UI.screens.cube = { label = "큐브", order = 5, create = create, refresh = refresh,
    autofill = autofill, pickLeft = pickLeft, pickRight = pickRight, run = run }
