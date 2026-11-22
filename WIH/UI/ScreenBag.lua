-- 가방 화면: 영웅의 장비 10칸, 인벤토리, 상자 보관함.
-- 규칙은 Inventory/와 Chests의 함수가 판단한다. 이 화면은 보여 주고 그 함수를 부르기만 한다.

local _, WIH = ...
local UI = WIH.module("UI")
local App = WIH.module("App")
local Game = WIH.module("Game")
local Heroes = WIH.module("Heroes")
local Items = WIH.module("Items")
local Inventory = WIH.module("Inventory")
local Chests = WIH.module("Chests")
local ChestTable = WIH.module("ChestTable")

local C = UI.C
local CELL, COLS = 38, 9
local BULK_GRADE = 2        -- "일반·고급 모두 팔기"의 등급 상한

local function gradeColor(item) return Items.GRADES[item.grade].color end

-- 아이템 툴팁의 내용. compareTo가 있으면 지금 낀 것과의 비교를 덧붙인다.
function UI.itemTip(item, entry, compareTo)
    local lines = {}
    lines[#lines + 1] = { Items.gradeName(item) .. "  ·  " .. Items.SLOT_NAMES[item.slot] .. "  ·  아이템 레벨 " .. item.level, gradeColor(item) }
    for _, mod in ipairs(item.mods) do
        lines[#lines + 1] = { Items.modText(mod), mod.base and C.text or C.sub }
    end
    if item.slot == "MAIN" or item.slot == "SUB" then
        local users = {}
        for _, hero in ipairs(Heroes.list) do
            if (item.slot == "MAIN" and hero.main or hero.sub) == item.type then users[#users + 1] = hero.name end
        end
        lines[#lines + 1] = { "사용: " .. table.concat(users, ", "), C.dim }
    end
    if compareTo and compareTo ~= item then
        lines[#lines + 1] = { "지금 낀 것: " .. Items.name(compareTo) .. " (" .. Items.gradeName(compareTo) .. ", 레벨 " .. compareTo.level .. ")", C.dim }
    end
    if App.state then lines[#lines + 1] = { "연금술 " .. UI.number(Inventory.alchemyValue(App.state, item)) .. " G", C.warn } end
    if entry and entry.lock then lines[#lines + 1] = { "잠금: 팔리지 않습니다.", C.dim } end
    return { title = Items.name(item), lines = lines }
end

local function selectedHero(f)
    local s = App.state
    if not f.heroId or not s.heroes[f.heroId] then f.heroId = s.party[1] end
    return f.heroId
end

local function note(ok, why)
    if not ok and why then WIH.Main.notice(why, C.bad) end
end

local function lootText(result)
    if result.item then
        local where = result.where == "mail" and " (가방이 가득 차 임시 보관함으로)" or ""
        return Items.name(result.item) .. " [" .. Items.gradeName(result.item) .. "]" .. where
    end
    return Chests.materialName(result.material)
end
UI.lootText = lootText

local function create(parent)
    local f = CreateFrame("Frame", nil, parent)
    f.selected = nil        -- 고른 인벤토리 번호

    -- 왼쪽: 보유 영웅
    f.heroList = UI.scroll(f)
    f.heroList:SetPoint("TOPLEFT", 10, -10)
    f.heroList:SetPoint("BOTTOMLEFT", 10, 96)
    f.heroList:SetWidth(132)
    f.heroRows = {}

    -- 가운데: 장비 10칸
    local eq = UI.panel(f, C.panel, true)
    eq:SetPoint("TOPLEFT", f.heroList, "TOPRIGHT", 10, 0)
    eq:SetSize(292, 10 * 34 + 44)
    f.eqTitle = UI.text(eq, 13, C.text)
    f.eqTitle:SetPoint("TOPLEFT", 10, -10)
    f.eqSub = UI.text(eq, 11, C.sub)
    f.eqSub:SetPoint("TOPLEFT", 10, -28)
    f.slots = {}
    for i, slot in ipairs(Items.SLOTS) do
        local row = CreateFrame("Frame", nil, eq)
        row:SetSize(272, 30)
        row:SetPoint("TOPLEFT", 10, -44 - (i - 1) * 34)
        row.label = UI.text(row, 11, C.dim)
        row.label:SetPoint("LEFT", 0, 0)
        row.label:SetWidth(52)
        row.label:SetText(Items.SLOT_NAMES[slot])
        row.icon = UI.icon(row, 28)
        row.icon:SetPoint("LEFT", 54, 0)
        row.name = UI.text(row, 12, C.text)
        row.name:SetPoint("LEFT", row.icon, "RIGHT", 8, 0)
        row.name:SetPoint("RIGHT", -50, 0)
        row.off = UI.button(row, "해제", 44, 22, function()
            note(Inventory.unequip(App.state, selectedHero(f), slot))
            f.dirty = true
            UI.screens.bag.refresh(f)
        end)
        row.off:SetPoint("RIGHT", 0, 0)
        UI.setTooltip(row, function()
            local item, entry = Inventory.equipped(App.state, selectedHero(f), slot)
            if not item then return { title = Items.SLOT_NAMES[slot], lines = { "비어 있습니다." } } end
            return UI.itemTip(item, entry)
        end)
        f.slots[slot] = row
    end
    f.apply = UI.button(f, "지금 적용", 90, 24, function()
        f.dirty = false
        App.restartStage()
        UI.screens.bag.refresh(f)
    end)
    f.apply:SetPoint("TOPLEFT", eq, "BOTTOMLEFT", 0, -8)
    f.apply.tooltip = { title = "지금 적용", lines = { "현재 스테이지를 처음부터 다시 시작해 바꾼 장비를 바로 적용합니다. 누르지 않으면 다음 스테이지부터 적용됩니다." } }
    f.applyHint = UI.text(f, 11, C.dim)
    f.applyHint:SetPoint("LEFT", f.apply, "RIGHT", 10, 0)

    -- 오른쪽: 인벤토리
    f.bagTitle = UI.text(f, 13, C.text)
    f.bagTitle:SetPoint("TOPLEFT", 456, -12)
    f.sort = UI.button(f, "정렬", 46, 22, function()
        Inventory.sort(App.state)
        f.selected = nil
        UI.screens.bag.refresh(f)
    end)
    f.sort:SetPoint("TOPRIGHT", -10, -8)
    f.buy = UI.button(f, "", 110, 22, function()
        note(Inventory.buySlot(App.state))
        UI.screens.bag.refresh(f)
    end)
    f.buy:SetPoint("RIGHT", f.sort, "LEFT", -6, 0)
    f.bulk = UI.button(f, "일반·고급 팔기", 100, 22, function()
        local s = App.state
        local list = {}
        for i, entry in ipairs(s.inventory.items) do
            local item = Items.byId[entry.id]
            if item and item.grade <= BULK_GRADE then list[#list + 1] = i end
        end
        local gold, n = Inventory.alchemy(s, list)
        f.selected = nil
        WIH.Main.notice(n > 0 and (n .. "개를 팔아 " .. UI.number(gold) .. " G를 얻었습니다.") or "팔 것이 없습니다.", C.sub)
        UI.screens.bag.refresh(f)
    end)
    f.bulk:SetPoint("RIGHT", f.buy, "LEFT", -6, 0)
    f.bulk.tooltip = { title = "일반·고급 팔기", lines = { "가방에 있는 일반·고급 등급 장비를 모두 연금술로 골드로 바꿉니다. 잠근 것과 낀 것은 팔리지 않습니다." } }

    f.grid = UI.scroll(f)
    -- 위치는 창 기준 좌표로 적는다(영웅 목록 10 + 132, 장비 칸 10 + 292, 간격 12 → 왼쪽 456).
    f.grid:SetPoint("TOPLEFT", 456, -46)
    f.grid:SetPoint("TOPRIGHT", -10, -46)
    f.grid:SetHeight(4 * (CELL + 4) + 2)
    f.cells = {}

    -- 고른 아이템의 상세
    local d = UI.panel(f, C.panel, true)
    d:SetPoint("TOPLEFT", 456, -46 - (4 * (CELL + 4) + 2) - 8)
    d:SetPoint("BOTTOMRIGHT", -10, 96)
    f.detail = d
    f.dIcon = UI.icon(d, 34)
    f.dIcon:SetPoint("TOPLEFT", 10, -10)
    f.dName = UI.text(d, 13, C.text)
    f.dName:SetPoint("TOPLEFT", f.dIcon, "TOPRIGHT", 10, 0)
    f.dMeta = UI.text(d, 11, C.sub)
    f.dMeta:SetPoint("TOPLEFT", f.dName, "BOTTOMLEFT", 0, -5)
    f.dBody = UI.paragraph(d, 11, C.sub)
    f.dBody:SetPoint("TOPLEFT", 10, -52)
    f.dBody:SetPoint("TOPRIGHT", -10, -52)
    f.dEmpty = UI.text(d, 12, C.dim)
    f.dEmpty:SetPoint("TOPLEFT", 12, -14)
    f.dEmpty:SetText("가방의 아이템을 누르면 여기에 내용이 나옵니다.")
    f.dEquip = UI.button(d, "장착", 70, 24, function()
        note(Inventory.equip(App.state, selectedHero(f), f.selected))
        f.dirty = true
        f.selected = nil
        UI.screens.bag.refresh(f)
    end)
    f.dEquip:SetPoint("BOTTOMLEFT", 10, 10)
    f.dLock = UI.button(d, "잠금", 70, 24, function()
        local entry = App.state.inventory.items[f.selected]
        if entry then Inventory.setLock(App.state, f.selected, not entry.lock) end
        UI.screens.bag.refresh(f)
    end)
    f.dLock:SetPoint("LEFT", f.dEquip, "RIGHT", 6, 0)
    f.dSell = UI.button(d, "", 130, 24, function()
        local gold, n = Inventory.alchemy(App.state, { f.selected })
        if n == 0 then WIH.Main.notice("잠근 아이템은 팔 수 없습니다.", C.bad) end
        f.selected = nil
        UI.screens.bag.refresh(f)
    end)
    f.dSell:SetPoint("LEFT", f.dLock, "RIGHT", 6, 0)

    -- 아래: 상자 보관함
    local chest = UI.panel(f, C.panel, true)
    chest:SetPoint("BOTTOMLEFT", 10, 10)
    chest:SetPoint("BOTTOMRIGHT", -10, 10)
    chest:SetHeight(78)
    f.chestRows = {}
    for i, kind in ipairs(Chests.KINDS) do
        local row = CreateFrame("Frame", nil, chest)
        row:SetSize(264, 24)
        row:SetPoint("TOPLEFT", 10 + (i - 1) * 272, -6)
        row.text = UI.text(row, 12, C.text)
        row.text:SetPoint("LEFT", 0, 0)
        row.open = UI.button(row, "열기", 48, 22, function()
            local result, why = Chests.open(App.state, kind, App.session.lootRng)
            if not result then
                WIH.Main.notice(why, C.bad)
            else
                WIH.Main.notice(Chests.NAMES[kind] .. ": " .. lootText(result), C.good)
            end
            UI.screens.bag.refresh(f)
        end)
        row.open:SetPoint("LEFT", 132, 0)
        row.all = UI.button(row, "모두 열기", 70, 22, function()
            local s = App.state
            if not Chests.canOpenAll(s) then return WIH.Main.notice("모두 열기는 룬으로 해금합니다.", C.bad) end
            local n, last = 0, nil
            while Chests.count(s, kind) > 0 do
                local result = Chests.open(s, kind, App.session.lootRng)
                if not result then break end
                n, last = n + 1, result
            end
            if n > 0 then WIH.Main.notice(Chests.NAMES[kind] .. " " .. n .. "개를 열었습니다. 마지막: " .. lootText(last), C.good) end
            UI.screens.bag.refresh(f)
        end)
        row.all:SetPoint("LEFT", row.open, "RIGHT", 6, 0)
        row.all.tooltip = { title = "모두 열기", lines = { "보관함의 이 종류 상자를 한 번에 엽니다. 룬에서 해금합니다." } }
        row.timer = UI.text(row, 11, C.dim)
        row.timer:SetPoint("TOPLEFT", 0, -26)
        f.chestRows[kind] = row
    end
    f.extra = UI.text(chest, 11, C.sub)
    f.extra:SetPoint("BOTTOMLEFT", 10, 8)
    f.claim = UI.button(chest, "임시 보관함에서 꺼내기", 150, 22, function()
        local n = Inventory.claimMail(App.state)
        WIH.Main.notice(n > 0 and (n .. "개를 가방으로 옮겼습니다.") or "가방에 빈칸이 없습니다.", n > 0 and C.good or C.bad)
        UI.screens.bag.refresh(f)
    end)
    f.claim:SetPoint("BOTTOMRIGHT", -10, 4)
    f.acc = 0
    return f
end

local function heroRow(f, n)
    local row = f.heroRows[n]
    if row then return row end
    row = UI.button(f.heroList.content, "", 126, 24, function(self)
        f.heroId = self.heroId
        UI.screens.bag.refresh(f)
    end)
    row:SetPoint("TOPLEFT", 0, -(n - 1) * 26)
    row.label:ClearAllPoints()
    row.label:SetPoint("LEFT", 8, 0)
    row.label:SetJustifyH("LEFT")
    f.heroRows[n] = row
    return row
end

local function cell(f, n)
    local c = f.cells[n]
    if c then return c end
    c = CreateFrame("Button", nil, f.grid.content)
    c:SetSize(CELL, CELL)
    local col, rowIndex = (n - 1) % COLS, math.floor((n - 1) / COLS)
    c:SetPoint("TOPLEFT", col * (CELL + 4), -rowIndex * (CELL + 4))
    c.bg = UI.fill(c, C.raised)
    c.bg:SetAllPoints()
    c.tex = c:CreateTexture(nil, "ARTWORK")
    c.tex:SetPoint("TOPLEFT", 2, -2)
    c.tex:SetPoint("BOTTOMRIGHT", -2, 2)
    c.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    UI.border(c)
    c.level = UI.text(c, 10, C.text, "RIGHT")
    c.level:SetPoint("BOTTOMRIGHT", -3, 3)
    c.lock = UI.text(c, 10, C.warn)
    c.lock:SetPoint("TOPLEFT", 3, -3)
    c:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    c:SetScript("OnClick", function(self, button)
        local s = App.state
        local entry = s.inventory.items[n]
        if not entry then return end
        if button == "RightButton" then
            -- 오른쪽 클릭: 고른 영웅에게 바로 장착
            local ok, why = Inventory.equip(s, selectedHero(f), n)
            note(ok, why)
            if ok then f.dirty = true; f.selected = nil end
        else
            f.selected = (f.selected ~= n) and n or nil
        end
        UI.screens.bag.refresh(f)
    end)
    c:SetScript("OnEnter", function(self)
        local s = App.state
        local entry = s and s.inventory.items[n]
        local item = entry and Items.byId[entry.id]
        if item then UI.showTooltip(self, UI.itemTip(item, entry, Inventory.equipped(s, selectedHero(f), item.slot))) end
    end)
    c:SetScript("OnLeave", UI.hideTooltip)
    f.cells[n] = c
    return c
end

local function timerText(s, kind)
    if kind == "raid" then return "레이드를 클리어하면 받습니다" end
    local c = s.chests[kind]
    if c.allowance >= 1 then return "상자를 받을 수 있습니다" end
    local info = ChestTable.STAGE[Game.currentStageKey(s)]
    local minutes = info and (kind == "normal" and info.cool or info.bossCool) or 0
    local left = (1 - c.allowance) * minutes * 60
    return string.format("다음 상자를 받을 수 있을 때까지 %d:%02d", math.floor(left / 60), math.floor(left % 60))
end

local function paintChests(f)
    local s = App.state
    for _, kind in ipairs(Chests.KINDS) do
        local row = f.chestRows[kind]
        local n, cap = Chests.count(s, kind), Chests.cap(s, kind)
        row.text:SetText(string.format("%s  %d / %d", Chests.NAMES[kind], n, cap))
        row.text:SetTextColor(UI.rgb(n >= cap and C.warn or C.text))
        row.open:setEnabled(n > 0)
        row.all:setEnabled(n > 0 and Chests.canOpenAll(s))
        local auto = Chests.autoOpenTime(s, kind)
        local t = timerText(s, kind)
        if auto and n > 0 then t = t .. string.format("  ·  자동 개봉까지 %d초", math.max(0, math.ceil(auto - s.chests[kind].auto))) end
        row.timer:SetText(t)
    end
    local mats = 0
    for _, count in pairs(s.materials) do mats = mats + count end
    local tokens = {}
    for d = 1, 4 do
        local n = Game.raidTokens(s, d)
        if n > 0 then tokens[#tokens + 1] = WIH.Tables.DIFFICULTY_NAMES[d] .. " " .. n end
    end
    f.extra:SetText(string.format("임시 보관함 %d개  ·  재료 %d개(큐브가 들어오면 쓰입니다)  ·  %s %s", #s.mail, mats, WIH.Raids.TOKEN_NAME,
        #tokens > 0 and table.concat(tokens, ", ") or "없음"))
    f.claim:SetShown(#s.mail > 0)
end

local function refresh(f)
    local s = App.state
    if not s then return end
    local heroId = selectedHero(f)
    local hero = Heroes.byId[heroId]

    -- 영웅 목록: 편성한 영웅을 위에
    local order, inParty = {}, {}
    for _, id in ipairs(s.party) do order[#order + 1] = id; inParty[id] = true end
    for _, h in ipairs(Heroes.list) do
        if s.heroes[h.id] and not inParty[h.id] then order[#order + 1] = h.id end
    end
    for n, id in ipairs(order) do
        local row = heroRow(f, n)
        row.heroId = id
        row:setText(Heroes.byId[id].name)
        row.label:SetTextColor(UI.rgb(inParty[id] and C.text or C.sub))
        row:setSelected(id == heroId)
        row:Show()
    end
    for i = #order + 1, #f.heroRows do f.heroRows[i]:Hide() end
    f.heroList:setHeight(#order * 26)

    f.eqTitle:SetText(hero.name .. "의 장비")
    f.eqSub:SetText("주무기 " .. Items.TYPES[hero.main].name .. "  ·  보조무기 " .. Items.TYPES[hero.sub].name)
    for slot, row in pairs(f.slots) do
        local item = Inventory.equipped(s, heroId, slot)
        if item then
            row.icon.tex:SetTexture(UI.iconPath(item.icon))
            row.icon:SetAlpha(1)
            UI.setBorderColor(row.icon, gradeColor(item))
            row.name:SetText(Items.name(item))
            row.name:SetTextColor(UI.rgb(gradeColor(item)))
        else
            row.icon.tex:SetTexture(nil)
            row.icon:SetAlpha(0.5)
            UI.setBorderColor(row.icon, C.line)
            row.name:SetText("비어 있음")
            row.name:SetTextColor(UI.rgb(C.dim))
        end
        row.off:SetShown(item ~= nil)
    end
    f.applyHint:SetText(f.dirty and "바꾼 장비는 다음 스테이지부터 적용됩니다." or "")

    -- 인벤토리
    local cap, count = Inventory.capacity(s), Inventory.count(s)
    f.bagTitle:SetText(string.format("가방  %d / %d", count, cap))
    f.bagTitle:SetTextColor(UI.rgb(count >= cap and C.warn or C.text))
    local cost = Inventory.nextSlotCost(s)
    f.buy:setText(cost and ("칸 구매 " .. UI.number(cost) .. " G") or "칸 최대")
    f.buy:setEnabled(cost ~= nil and s.gold >= cost)
    if f.selected and not s.inventory.items[f.selected] then f.selected = nil end
    for n = 1, cap do
        local c = cell(f, n)
        local entry = s.inventory.items[n]
        local item = entry and Items.byId[entry.id]
        if item then
            c.tex:SetTexture(UI.iconPath(item.icon))
            c.tex:Show()
            c.level:SetText(tostring(item.level))
            c.lock:SetText(entry.lock and "잠" or "")
            UI.setBorderColor(c, gradeColor(item))
            c.tex:SetDesaturated(not Items.usableBy(item, heroId))
        else
            c.tex:Hide()
            c.level:SetText("")
            c.lock:SetText("")
            UI.setBorderColor(c, C.line, 0.6)
        end
        c.bg:SetColorTexture(UI.rgb(n == f.selected and C.press or C.raised))
        c:Show()
    end
    for i = cap + 1, #f.cells do f.cells[i]:Hide() end
    f.grid:setHeight(math.ceil(cap / COLS) * (CELL + 4))

    -- 상세
    local entry = f.selected and s.inventory.items[f.selected]
    local item = entry and Items.byId[entry.id]
    local has = item ~= nil
    f.dIcon:SetShown(has); f.dName:SetShown(has); f.dMeta:SetShown(has); f.dBody:SetShown(has)
    f.dEquip:SetShown(has); f.dLock:SetShown(has); f.dSell:SetShown(has)
    f.dEmpty:SetShown(not has)
    if has then
        f.dIcon.tex:SetTexture(UI.iconPath(item.icon))
        UI.setBorderColor(f.dIcon, gradeColor(item))
        f.dName:SetText(Items.name(item))
        f.dName:SetTextColor(UI.rgb(gradeColor(item)))
        f.dMeta:SetText(Items.gradeName(item) .. "  ·  " .. Items.SLOT_NAMES[item.slot] .. "  ·  아이템 레벨 " .. item.level)
        local lines = {}
        for _, mod in ipairs(item.mods) do lines[#lines + 1] = Items.modText(mod) end
        local cur = Inventory.equipped(s, heroId, item.slot)
        if cur then
            local curLines = {}
            for _, mod in ipairs(cur.mods) do curLines[#curLines + 1] = Items.modText(mod) end
            lines[#lines + 1] = "|cff6b6e75지금 낀 것: " .. Items.name(cur) .. " (" .. Items.gradeName(cur) .. ") — " .. table.concat(curLines, ", ") .. "|r"
        end
        f.dBody:SetText(table.concat(lines, "\n"))
        local usable = Items.usableBy(item, heroId)
        f.dEquip:setEnabled(usable)
        f.dEquip.tooltip = usable and nil or { title = "장착할 수 없음", lines = { hero.name .. "이(가) 쓰는 종류가 아닙니다." } }
        f.dLock:setText(entry.lock and "잠금 해제" or "잠금")
        f.dSell:setText("팔기 +" .. UI.number(Inventory.alchemyValue(s, item)) .. " G")
        f.dSell:setEnabled(not entry.lock)
    end
    paintChests(f)
end

-- 상자의 시간 표시는 계속 바뀐다. 1초마다 그 줄만 다시 적는다.
local function update(f, elapsed)
    f.acc = f.acc + elapsed
    if f.acc < 1 then return end
    f.acc = 0
    if App.state then paintChests(f) end
end

UI.screens.bag = { label = "가방", order = 3, create = create, refresh = refresh, update = update }
