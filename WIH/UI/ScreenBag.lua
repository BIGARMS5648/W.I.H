-- 가방 화면: 인벤토리(필터·정렬·장착·잠금·팔기)와 상자 보관함. 장비 칸은 영웅 화면에 있다.
-- 규칙은 Inventory와 Chests의 함수가 판단한다. 이 화면은 보여 주고 그 함수를 부르기만 한다.

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
local CELL, COLS, ROWS = 38, 12, 8
local BULK_GRADE = 2        -- "일반·고급 팔기"의 등급 상한
local FILTERS = {
    { "all", "전체" }, { "MAIN", "주무기" }, { "SUB", "보조무기" }, { "ARMOR", "방어구" }, { "ACC", "장신구" }, { "usable", "착용 가능" },
}
local GROUP = { MAIN = "MAIN", SUB = "SUB", HELMET = "ARMOR", ARMOR = "ARMOR", GLOVES = "ARMOR", BOOTS = "ARMOR",
    AMULET = "ACC", EARRING = "ACC", RING = "ACC", BRACER = "ACC" }

local function gradeColor(item) return Items.GRADES[item.grade].color end

-- 아이템 툴팁의 내용. compareTo가 있으면 지금 낀 것을 덧붙인다.
function UI.itemTip(item, entry, compareTo, heroId)
    local lines = {}
    lines[#lines + 1] = { Items.gradeName(item) .. "  ·  " .. Items.SLOT_NAMES[item.slot] .. "  ·  아이템 레벨 " .. item.level, gradeColor(item) }
    for _, mod in ipairs(item.mods) do
        lines[#lines + 1] = { Items.modText(mod), mod.base and C.text or C.sub }
    end
    if item.unique then lines[#lines + 1] = { "고유: " .. WIH.Uniques.text(item.unique, heroId), C.warn } end
    for _, a in ipairs(entry and entry.added or {}) do
        lines[#lines + 1] = { WIH.Cube.NAMES[a.kind] .. "  " .. Items.modText({ a.stat, a.mod, a.value }), C.shield }
    end
    local slots = {}
    for _, kind in ipairs({ "DECORATION", "ENGRAVING", "INSCRIPTION" }) do
        local n = WIH.Cube.slots(item, kind)
        if n > 0 then slots[#slots + 1] = WIH.Cube.NAMES[kind] .. " " .. (entry and WIH.Cube.used(entry, kind) or 0) .. "/" .. n end
    end
    if #slots > 0 then lines[#lines + 1] = { "칸  " .. table.concat(slots, " · "), C.dim } end
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

UI.lootText = Chests.resultText

local function target(f)
    local s = App.state
    if not f.heroId or not s.heroes[f.heroId] then f.heroId = s.party[1] end
    return f.heroId
end

local function note(ok, why)
    if not ok and why then WIH.Main.notice(why, C.bad) end
end

-- 지금 보는 곳: 가방이면 인벤토리 목록, 창고면 그 페이지의 목록
local function source(f, s)
    if f.src == "bag" then return s.inventory.items, Inventory.capacity(s) end
    Inventory.ensureStash(s)
    return s.stash.pages[f.src], Inventory.stashCapacity(s)
end

local function passes(f, item)
    if f.filter == "all" then return true end
    if f.filter == "usable" then return Items.usableBy(item, target(f)) end
    return GROUP[item.slot] == f.filter
end

local function create(parent)
    local f = CreateFrame("Frame", nil, parent)
    f.filter = "all"
    f.view = {}             -- 화면의 칸 번호 → 인벤토리(또는 창고 페이지) 번호
    f.selected = nil        -- 고른 번호
    f.src = "bag"           -- "bag" 또는 창고 페이지 번호

    -- 오른쪽 위: 가방 / 창고 페이지
    f.srcSeg = UI.segment(f, { { "bag", "가방" }, { 1, "창고 1" }, { 2, "창고 2" }, { 3, "창고 3" }, { 4, "창고 4" } }, 330, function(id)
        local s = App.state
        if id ~= "bag" and id > Inventory.stashPages(s) then
            WIH.Main.notice("창고 " .. id .. "쪽은 성장 → 룬의 '창고의 룬'으로 엽니다.", C.bad)
        else
            f.src = id
            f.selected = nil
        end
        UI.screens.bag.refresh(f)
    end)
    f.srcSeg:SetPoint("TOPRIGHT", -12, -8)

    -- 첫 줄: 장착 대상
    local tl = UI.label(f, "장착 대상")
    tl:SetPoint("TOPLEFT", 12, -17)
    f.targets = {}
    -- 둘째 줄: 필터, 가방 용량과 버튼
    f.filters = {}
    local x = 12
    for _, it in ipairs(FILTERS) do
        local b = UI.chip(f, it[2], function()
            f.filter = it[1]
            f.selected = nil
            UI.screens.bag.refresh(f)
        end)
        b:SetPoint("TOPLEFT", x, -44)
        b.id = it[1]
        f.filters[#f.filters + 1] = b
        x = x + b:GetWidth() + 5
    end
    f.sort = UI.button(f, "정렬", 46, 22, function()
        if f.src ~= "bag" then return end
        Inventory.sort(App.state)
        f.selected = nil
        UI.screens.bag.refresh(f)
    end)
    f.sort:SetPoint("TOPRIGHT", -12, -44)
    f.buy = UI.button(f, "", 116, 22, function()
        if f.src == "bag" then note(Inventory.buySlot(App.state)) else note(Inventory.buyStashSlot(App.state)) end
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
        local gold, n, ups, skipped = WIH.Cube.alchemy(s, list)
        f.selected = nil
        local msg = n > 0 and (n .. "개를 연금술로 팔아 " .. UI.number(gold) .. " G를 얻었습니다.") or "팔 것이 없습니다."
        if ups > 0 then msg = msg .. "  큐브 레벨 " .. s.cube.level end
        if skipped > 0 then msg = msg .. "  (큐브 레벨보다 " .. WIH.Cube.LEVEL_GAP .. "레벨 넘게 높은 장비 " .. skipped .. "개는 남김)" end
        WIH.Main.notice(msg, C.sub)
        UI.screens.bag.refresh(f)
    end)
    f.bulk:SetPoint("RIGHT", f.buy, "LEFT", -6, 0)
    f.bulk.tooltip = { title = "일반·고급 팔기", lines = { "가방에 있는 일반·고급 등급 장비를 모두 연금술로 골드로 바꿉니다. 큐브 경험치도 얻습니다. 잠근 것과 낀 것은 팔리지 않습니다." } }
    f.bagTitle = UI.text(f, 12, C.text, "RIGHT")
    f.bagTitle:SetPoint("RIGHT", f.bulk, "LEFT", -14, 0)

    -- 칸
    f.grid = UI.scroll(f)
    f.grid:SetPoint("TOPLEFT", 12, -78)
    f.grid:SetSize(COLS * (CELL + 4), ROWS * (CELL + 4))
    f.cells = {}

    -- 고른 아이템의 상세
    local d = UI.panel(f, C.panel, true)
    d:SetPoint("TOPLEFT", 12 + COLS * (CELL + 4) + 12, -78)
    d:SetPoint("BOTTOMRIGHT", -12, 100)
    f.detail = d
    f.dIcon = UI.icon(d, 40)
    f.dIcon:SetPoint("TOPLEFT", 12, -12)
    f.dName = UI.text(d, 14, C.text)
    f.dName:SetPoint("TOPLEFT", 62, -13)
    f.dMeta = UI.text(d, 11, C.sub)
    f.dMeta:SetPoint("TOPLEFT", 62, -34)
    f.dBody = UI.paragraph(d, 12, C.sub)
    f.dBody:SetPoint("TOPLEFT", 12, -66)
    f.dBody:SetPoint("TOPRIGHT", -12, -66)
    if f.dBody.SetSpacing then f.dBody:SetSpacing(3) end
    f.dEmpty = UI.paragraph(d, 12, C.dim)
    f.dEmpty:SetPoint("TOPLEFT", 14, -16)
    f.dEmpty:SetPoint("TOPRIGHT", -14, -16)
    f.dEmpty:SetText("아이템을 누르면 여기에 내용이 나옵니다.\n오른쪽 클릭하면 장착 대상에게 바로 낍니다.")
    f.dEquip = UI.button(d, "장착", 76, 26, function()
        if f.src ~= "bag" then
            note(Inventory.fromStash(App.state, f.src, f.selected))
            f.selected = nil
            UI.screens.bag.refresh(f)
            return
        end
        note(Inventory.equip(App.state, target(f), f.selected))
        f.dirty = true
        f.selected = nil
        UI.screens.bag.refresh(f)
    end)
    f.dEquip:SetPoint("BOTTOMLEFT", 12, 12)
    f.dStash = UI.button(d, "창고로", 64, 22, function()
        local page, why = Inventory.toStash(App.state, f.selected)
        if page then WIH.Main.notice("창고 " .. page .. "쪽에 넣었습니다.", C.good) else note(false, why) end
        f.selected = nil
        UI.screens.bag.refresh(f)
    end)
    f.dStash:SetPoint("TOPRIGHT", -12, -12)
    f.dStash.tooltip = { title = "창고로", lines = { "자리가 있는 첫 창고 페이지에 맡깁니다. 창고의 장비는 큐브 자동 채우기와 일괄 팔기에 쓰이지 않습니다." } }
    f.dLock = UI.button(d, "잠금", 76, 26, function()
        local entry = App.state.inventory.items[f.selected]
        if entry then Inventory.setLock(App.state, f.selected, not entry.lock) end
        UI.screens.bag.refresh(f)
    end)
    f.dLock:SetPoint("LEFT", f.dEquip, "RIGHT", 6, 0)
    f.dSell = UI.button(d, "", 132, 26, function()
        local _, n = WIH.Cube.alchemy(App.state, { f.selected })
        if n == 0 then WIH.Main.notice("잠근 장비와 큐브 레벨보다 " .. WIH.Cube.LEVEL_GAP .. "레벨 넘게 높은 장비는 팔 수 없습니다.", C.bad) end
        f.selected = nil
        UI.screens.bag.refresh(f)
    end)
    f.dSell:SetPoint("LEFT", f.dLock, "RIGHT", 6, 0)
    f.apply = UI.button(d, "지금 적용", 84, 26, function()
        f.dirty = false
        App.restartStage()
        UI.screens.bag.refresh(f)
    end)
    f.apply:SetPoint("BOTTOMRIGHT", -12, 12)
    f.apply.tooltip = { title = "지금 적용", lines = { "현재 스테이지를 처음부터 다시 시작해 바꾼 장비를 바로 적용합니다. 누르지 않으면 다음 스테이지부터 적용됩니다." } }

    -- 아래: 상자 보관함
    local chest = UI.panel(f, C.panel, true)
    chest:SetPoint("BOTTOMLEFT", 12, 10)
    chest:SetPoint("BOTTOMRIGHT", -12, 10)
    chest:SetHeight(78)
    f.chestRows = {}
    f.chestGroup = "regular"
    for i = 1, 3 do
        local row = CreateFrame("Frame", nil, chest)
        row:SetSize(296, 24)
        row:SetPoint("TOPLEFT", 12 + (i - 1) * 308, -6)
        row.text = UI.text(row, 12, C.text)
        row.text:SetPoint("LEFT", 0, 0)
        row.open = UI.button(row, "열기", 48, 22, function()
            local kind = row.kind
            local result, why = Chests.open(App.state, kind, App.session.lootRng)
            if not result then
                WIH.Main.notice(why, C.bad)
            else
                App.lastLoot = Chests.resultText(result)
                WIH.Main.notice(Chests.NAMES[kind] .. ": " .. App.lastLoot, C.good)
            end
            UI.screens.bag.refresh(f)
        end)
        row.open:SetPoint("LEFT", 140, 0)
        row.all = UI.button(row, "모두 열기", 70, 22, function()
            local kind = row.kind
            local s = App.state
            if not Chests.canOpenAll(s) then return WIH.Main.notice("모두 열기는 룬으로 해금합니다.", C.bad) end
            local n, last = 0, nil
            while Chests.count(s, kind) > 0 do
                local result = Chests.open(s, kind, App.session.lootRng)
                if not result then break end
                n, last = n + 1, result
            end
            if n > 0 then
                App.lastLoot = Chests.resultText(last)
                WIH.Main.notice(Chests.NAMES[kind] .. " " .. n .. "개를 열었습니다. 마지막: " .. App.lastLoot, C.good)
            end
            UI.screens.bag.refresh(f)
        end)
        row.all:SetPoint("LEFT", row.open, "RIGHT", 6, 0)
        row.all.tooltip = { title = "모두 열기", lines = { "보관함의 이 종류 상자를 한 번에 엽니다. 룬에서 해금합니다." } }
        row.timer = UI.text(row, 11, C.dim)
        row.timer:SetPoint("TOPLEFT", 0, -26)
        f.chestRows[i] = row
    end
    f.chestToggle = UI.button(chest, "원정 상자 보기", 110, 22, function()
        f.chestGroup = f.chestGroup == "regular" and "plague" or "regular"
        UI.screens.bag.refresh(f)
    end)
    f.chestToggle:SetPoint("BOTTOMRIGHT", -12, 4)
    f.chestToggle.tooltip = { title = "원정 상자", lines = { "원정과 낙스라마스에서 나온 상자는 따로 보관합니다.", "드롭 확률·보관 한도·자동 개봉은 역병의 룬이 정합니다." } }
    f.extra = UI.text(chest, 11, C.sub)
    f.extra:SetPoint("BOTTOMLEFT", 12, 8)
    f.claim = UI.button(chest, "임시 보관함에서 꺼내기", 150, 22, function()
        local n = Inventory.claimMail(App.state)
        WIH.Main.notice(n > 0 and (n .. "개를 가방으로 옮겼습니다.") or "가방에 빈칸이 없습니다.", n > 0 and C.good or C.bad)
        UI.screens.bag.refresh(f)
    end)
    f.claim:SetPoint("RIGHT", f.chestToggle, "LEFT", -6, 0)
    f.acc = 0
    return f
end

local function targetChip(f, n)
    local b = f.targets[n]
    if b then return b end
    b = UI.chip(f, "", function(self)
        f.heroId = self.heroId
        f.selected = nil
        UI.screens.bag.refresh(f)
    end)
    f.targets[n] = b
    return b
end

local function cell(f, n)
    local c = f.cells[n]
    if c then return c end
    c = UI.slot(f.grid.content, CELL)
    local col, rowIndex = (n - 1) % COLS, math.floor((n - 1) / COLS)
    c:SetPoint("TOPLEFT", col * (CELL + 4), -rowIndex * (CELL + 4))
    c.lock = UI.text(c, 10, C.warn)
    c.lock:SetPoint("TOPLEFT", 3, -3)
    c.onClick = function(_, button)
        local s = App.state
        local index = f.view[n]
        local list = source(f, s)
        if not index or not list[index] then return end
        if f.src ~= "bag" then
            if button == "RightButton" then
                note(Inventory.fromStash(s, f.src, index))
                f.selected = nil
            else
                f.selected = (f.selected ~= index) and index or nil
            end
            UI.screens.bag.refresh(f)
            return
        end
        if button == "RightButton" then
            -- 오른쪽 클릭: 장착 대상에게 바로 장착
            local ok, why = Inventory.equip(s, target(f), index)
            note(ok, why)
            if ok then f.dirty = true; f.selected = nil end
        else
            f.selected = (f.selected ~= index) and index or nil
        end
        UI.screens.bag.refresh(f)
    end
    c.tooltip = function()
        local s = App.state
        local index = f.view[n]
        local entry = s and index and source(f, s)[index]
        local item = entry and Items.byId[entry.id]
        if not item then return nil end
        return UI.itemTip(item, entry, Inventory.equipped(s, target(f), item.slot), target(f))
    end
    f.cells[n] = c
    return c
end

local function timerText(s, kind)
    if kind == "raid" then return "레이드를 클리어하면 받습니다" end
    if kind == "praid" then return "낙스라마스를 클리어하면 받습니다" end
    local c = s.chests[kind]
    if c.allowance >= 1 then return "상자를 받을 수 있습니다" end
    local key = s.stage.expedition or Game.currentStageKey(s)
    if Chests.isPlague(kind) ~= (s.stage.expedition ~= nil) then
        return Chests.isPlague(kind) and "원정에 있을 때 다음 상자가 찹니다" or "일반 지역에 있을 때 다음 상자가 찹니다"
    end
    local info = ChestTable.STAGE[key]
    local minutes = info and ((kind == "normal" or kind == "pnormal") and info.cool or info.bossCool) or 0
    local left = (1 - c.allowance) * minutes * 60
    return string.format("다음 상자까지 %d:%02d", math.floor(left / 60), math.floor(left % 60))
end

local function paintChests(f)
    local s = App.state
    local group = f.chestGroup == "plague" and Chests.PLAGUE or Chests.REGULAR
    local plagueCount = 0
    for _, kind in ipairs(Chests.PLAGUE) do plagueCount = plagueCount + Chests.count(s, kind) end
    f.chestToggle:setText(f.chestGroup == "plague" and "일반 지역 상자" or ("원정 상자" .. (plagueCount > 0 and (" " .. plagueCount) or "") .. " 보기"))
    for i, kind in ipairs(group) do
        local row = f.chestRows[i]
        row.kind = kind
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
    f.extra:SetText(string.format("임시 보관함 %d개  ·  재료 %d개(큐브 탭에서 씁니다)  ·  %s %s", #s.mail, mats, WIH.Raids.TOKEN_NAME,
        #tokens > 0 and table.concat(tokens, ", ") or "없음"))
    f.claim:SetShown(#s.mail > 0)
end

-- 영웅 화면에서 장비 칸을 눌러 넘어온 경우: 그 영웅과 그 칸의 종류로 맞춘다.
local function onShow(f)
    local t = UI.bagTarget
    if t and App.state and App.state.heroes[t.heroId] then
        f.heroId = t.heroId
        f.filter = GROUP[t.slot] or "all"
        f.selected = nil
    end
    UI.bagTarget = nil
end

local function refresh(f)
    local s = App.state
    if not s then return end
    local heroId = target(f)
    local hero = Heroes.byId[heroId]

    -- 장착 대상: 편성한 영웅들(+ 편성 밖의 영웅이 대상이면 그 영웅)
    local list, inParty = {}, {}
    for _, id in ipairs(s.party) do list[#list + 1] = id; inParty[id] = true end
    if not inParty[heroId] then list[#list + 1] = heroId end
    local x = 76
    for n, id in ipairs(list) do
        local b = targetChip(f, n)
        b.heroId = id
        b:setText(Heroes.byId[id].name)
        b:SetWidth((b.label:GetStringWidth() or 60) + 18)
        b:ClearAllPoints()
        b:SetPoint("TOPLEFT", x, -12)
        b:setSelected(id == heroId)
        b:Show()
        x = x + b:GetWidth() + 5
    end
    for i = #list + 1, #f.targets do f.targets[i]:Hide() end
    for _, b in ipairs(f.filters) do b:setSelected(b.id == f.filter) end

    -- 가방 또는 창고
    if f.src ~= "bag" and f.src > Inventory.stashPages(s) then f.src = "bag" end
    local inBag = f.src == "bag"
    f.srcSeg:pick(f.src)
    for _, b in ipairs(f.srcSeg.buttons) do
        b.label:SetTextColor(UI.rgb((b.id == f.src) and C.text or ((b.id == "bag" or b.id <= Inventory.stashPages(s)) and C.sub or C.dim)))
    end
    local list, cap = source(f, s)
    local count = #list
    f.bagTitle:SetText(string.format(inBag and "가방  %d / %d" or ("창고 " .. f.src .. "쪽  %d / %d"), count, cap))
    f.bagTitle:SetTextColor(UI.rgb(count >= cap and C.warn or C.text))
    local cost
    if inBag then cost = Inventory.nextSlotCost(s) else cost = Inventory.nextStashSlotCost(s) end
    f.buy:setText(cost and ("칸 구매 " .. UI.number(cost) .. " G") or "칸 최대")
    f.buy:setEnabled(cost ~= nil and s.gold >= cost)
    f.buy.tooltip = not inBag and { title = "창고 칸 구매", lines = { "모든 창고 페이지의 칸이 하나씩 늘어납니다." } } or nil
    f.sort:SetShown(inBag)
    f.bulk:SetShown(inBag)
    if f.selected and not list[f.selected] then f.selected = nil end

    local view = {}
    for index, entry in ipairs(list) do
        local item = Items.byId[entry.id]
        if item and passes(f, item) then view[#view + 1] = index end
    end
    f.view = view
    local shown = f.filter == "all" and cap or #view       -- 전체 보기에서는 빈칸까지 보여 용량을 알 수 있게 한다
    for n = 1, shown do
        local c = cell(f, n)
        local index = view[n]
        local entry = index and list[index]
        local item = entry and Items.byId[entry.id]
        if item then
            c:setIcon(item.icon, gradeColor(item))
            c.corner:SetText(tostring(item.level))
            c.lock:SetText(entry.lock and "잠" or "")
            c.tex:SetDesaturated(not Items.usableBy(item, heroId))
        else
            c:setIcon(nil, C.line)
            c.corner:SetText("")
            c.lock:SetText("")
        end
        c.bg:SetColorTexture(UI.rgb((index and index == f.selected) and C.press or C.well))
        c:Show()
    end
    for i = shown + 1, #f.cells do f.cells[i]:Hide() end
    f.grid:setHeight(math.ceil(shown / COLS) * (CELL + 4))

    -- 상세
    local entry = f.selected and list[f.selected]
    local item = entry and Items.byId[entry.id]
    local has = item ~= nil
    f.dIcon:SetShown(has); f.dName:SetShown(has); f.dMeta:SetShown(has); f.dBody:SetShown(has)
    f.dEquip:SetShown(has); f.dLock:SetShown(has and inBag); f.dSell:SetShown(has and inBag)
    f.dStash:SetShown(has and inBag)
    f.dEmpty:SetText(inBag and "아이템을 누르면 여기에 내용이 나옵니다.\n오른쪽 클릭하면 장착 대상에게 바로 낍니다."
        or "창고의 아이템을 누르면 여기에 내용이 나옵니다.\n오른쪽 클릭하면 가방으로 꺼냅니다.")
    f.dEmpty:SetShown(not has)
    f.apply:SetShown(f.dirty == true)
    if has then
        f.dIcon.tex:SetTexture(UI.iconPath(item.icon))
        UI.setBorderColor(f.dIcon, gradeColor(item))
        f.dName:SetText(Items.name(item))
        f.dName:SetTextColor(UI.rgb(gradeColor(item)))
        f.dMeta:SetText(Items.gradeName(item) .. "  ·  " .. Items.SLOT_NAMES[item.slot] .. "  ·  아이템 레벨 " .. item.level)
        local lines = {}
        for _, mod in ipairs(item.mods) do
            lines[#lines + 1] = (mod.base and "|cffe8e9ec" or "") .. Items.modText(mod) .. (mod.base and "|r" or "")
        end
        for _, a in ipairs(entry.added or {}) do
            lines[#lines + 1] = "|cff8fb2db" .. WIH.Cube.NAMES[a.kind] .. "  " .. Items.modText({ a.stat, a.mod, a.value }) .. "|r"
        end
        if item.unique then lines[#lines + 1] = "|cffd9b05e고유  " .. WIH.Uniques.text(item.unique, heroId) .. "|r" end
        local cur = Inventory.equipped(s, heroId, item.slot)
        if cur and Items.usableBy(item, heroId) then
            lines[#lines + 1] = ""
            lines[#lines + 1] = "|cff666b74" .. hero.name .. "이(가) 지금 낀 것: " .. Items.name(cur) .. " [" .. Items.gradeName(cur) .. ", 레벨 " .. cur.level .. "]"
            for _, mod in ipairs(cur.mods) do lines[#lines + 1] = "  " .. Items.modText(mod) end
            lines[#lines] = lines[#lines] .. "|r"
        end
        f.dBody:SetText(table.concat(lines, "\n"))
        local usable = Items.usableBy(item, heroId)
        f.dEquip:setText(inBag and "장착" or "가방으로")
        f.dEquip:setEnabled(usable or not inBag)
        f.dEquip.tooltip = not inBag and { title = "가방으로", lines = { "창고에서 꺼내 가방에 넣습니다." } }
            or (usable and { title = "장착", lines = { hero.name .. "에게 낍니다. 끼고 있던 것은 가방으로 돌아옵니다." } }
            or { title = "장착할 수 없음", lines = { hero.name .. "이(가) 쓰는 종류가 아닙니다." } })
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

UI.screens.bag = { label = "가방", order = 2, create = create, refresh = refresh, update = update, onShow = onShow }
