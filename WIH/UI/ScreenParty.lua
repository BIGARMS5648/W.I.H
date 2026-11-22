-- 편성 화면: 전투에 나갈 영웅과 순서. 1번이 선두에 선다.

local _, WIH = ...
local UI = WIH.module("UI")
local App = WIH.module("App")
local Game = WIH.module("Game")
local Heroes = WIH.module("Heroes")
local HeroBuild = WIH.module("HeroBuild")

local C = UI.C
local CARD_W, CARD_H = 430, 62

local function copyParty()
    local list = {}
    for i, id in ipairs(App.state.party) do list[i] = id end
    return list
end

local function apply(f, list)
    local ok, why = Game.setParty(App.state, list)
    if not ok then
        WIH.Main.notice(why, C.bad)
    else
        f.dirty = true
    end
    UI.screens.party.refresh(f)
end

local function roleText(hero, form)
    local _, _, role = HeroBuild.baseOf(hero, form)
    return Heroes.ROLES[role] or ""
end

local function create(parent)
    local f = CreateFrame("Frame", nil, parent)
    local title = UI.text(f, 15, C.text)
    title:SetPoint("TOPLEFT", 14, -14)
    title:SetText("편성")
    f.help = UI.paragraph(f, 11, C.sub)
    f.help:SetPoint("TOPLEFT", 14, -36)
    f.help:SetPoint("TOPRIGHT", -14, -36)
    f.help:SetText("1번이 맨 앞에 섭니다. 적은 가장 가까운 영웅부터 공격하므로 버틸 수 있는 영웅을 앞에 두세요. 편성 칸은 룬에서 늘립니다.")

    f.cards = {}
    for i = 1, Game.MAX_PARTY_SLOTS do
        local card = UI.panel(f, C.panel, true)
        card:SetSize(CARD_W, CARD_H)
        card:SetPoint("TOPLEFT", 14, -62 - (i - 1) * (CARD_H + 6))
        card.num = UI.text(card, 13, C.dim, "CENTER")
        card.num:SetPoint("LEFT", 0, 0)
        card.num:SetWidth(30)
        card.num:SetText(tostring(i))
        card.icon = UI.icon(card, 40)
        card.icon:SetPoint("LEFT", 32, 0)
        card.name = UI.text(card, 13, C.text)
        card.name:SetPoint("TOPLEFT", card.icon, "TOPRIGHT", 10, -3)
        card.sub = UI.text(card, 11, C.sub)
        card.sub:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -6)
        card.empty = UI.text(card, 12, C.dim)
        card.empty:SetPoint("LEFT", 40, 0)

        card.remove = UI.button(card, "빼기", 46, 22, function()
            local list = copyParty()
            table.remove(list, i)
            apply(f, list)
        end)
        card.remove:SetPoint("RIGHT", -8, 0)
        card.back = UI.button(card, "뒤로", 46, 22, function()
            local list = copyParty()
            if list[i + 1] then
                list[i], list[i + 1] = list[i + 1], list[i]
                apply(f, list)
            end
        end)
        card.back:SetPoint("RIGHT", card.remove, "LEFT", -4, 0)
        card.front = UI.button(card, "앞으로", 50, 22, function()
            local list = copyParty()
            if i > 1 and list[i] then
                list[i], list[i - 1] = list[i - 1], list[i]
                apply(f, list)
            end
        end)
        card.front:SetPoint("RIGHT", card.back, "LEFT", -4, 0)

        card.forms = {}
        for k, form in ipairs({ "bear", "cat" }) do
            local b = UI.button(card, form == "bear" and "곰" or "표범", 40, 18, function()
                local id = App.state.party[i]
                if not id then return end
                local ok, why = Game.setForm(App.state, id, form)
                if not ok then WIH.Main.notice(why, C.bad) else f.dirty = true end
                UI.screens.party.refresh(f)
            end)
            b.tooltip = { title = form == "bear" and "곰 형태" or "표범 형태",
                lines = { form == "bear" and "탱커로 싸웁니다." or "근접 딜러로 싸웁니다.", "형태마다 스킬 효과가 다릅니다." } }
            b:SetPoint("BOTTOMRIGHT", card.front, "BOTTOMLEFT", -6 - (2 - k) * 44, 2)
            card.forms[form] = b
        end
        f.cards[i] = card
    end

    -- 오른쪽: 대기 중인 영웅
    local benchTitle = UI.text(f, 12, C.sub)
    benchTitle:SetPoint("TOPLEFT", 14 + CARD_W + 16, -62)
    benchTitle:SetText("대기 중인 영웅")
    f.benchTitle = benchTitle
    f.bench = UI.scroll(f)
    f.bench:SetPoint("TOPLEFT", benchTitle, "BOTTOMLEFT", 0, -8)
    f.bench:SetPoint("BOTTOMRIGHT", -14, 50)
    f.benchRows = {}
    f.benchEmpty = UI.paragraph(f, 11, C.dim)
    f.benchEmpty:SetPoint("TOPLEFT", 14 + CARD_W + 16, -86)
    f.benchEmpty:SetPoint("TOPRIGHT", -14, -86)

    f.apply = UI.button(f, "지금 적용", 96, 26, function()
        f.dirty = false
        App.restartStage()
        UI.screens.party.refresh(f)
    end)
    f.apply.tooltip = { title = "지금 적용", lines = { "현재 스테이지를 처음부터 다시 시작해 바꾼 편성을 바로 적용합니다. 누르지 않으면 다음 스테이지부터 적용됩니다." } }
    f.apply:SetPoint("BOTTOMLEFT", 14, 14)
    f.hint = UI.text(f, 11, C.dim)
    f.hint:SetPoint("LEFT", f.apply, "RIGHT", 12, 0)
    return f
end

local function benchRow(f, n)
    local row = f.benchRows[n]
    if row then return row end
    row = UI.button(f.bench.content, "", 100, 30, function(self)
        local list = copyParty()
        list[#list + 1] = self.heroId
        apply(f, list)
    end)
    row:SetPoint("TOPLEFT", 0, -(n - 1) * 34)
    row:SetPoint("TOPRIGHT", 0, -(n - 1) * 34)
    row.label:ClearAllPoints()
    row.label:SetPoint("LEFT", 10, 0)
    row.label:SetJustifyH("LEFT")
    row.right = UI.text(row, 11, C.sub, "RIGHT")
    row.right:SetPoint("RIGHT", -10, 0)
    row.tooltip = { title = "편성에 넣기", lines = { "누르면 편성의 맨 뒤에 들어갑니다." } }
    f.benchRows[n] = row
    return row
end

local function refresh(f)
    local s = App.state
    if not s then return end
    local slots = Game.partySlots(s)
    local inParty = {}
    for i, card in ipairs(f.cards) do
        local id = s.party[i]
        local owned = id ~= nil
        local locked = i > slots
        if id then inParty[id] = true end
        card.icon:SetShown(owned)
        card.name:SetShown(owned)
        card.sub:SetShown(owned)
        card.empty:SetShown(not owned)
        card.remove:SetShown(owned)
        card.back:SetShown(owned)
        card.front:SetShown(owned)
        card.bg:SetColorTexture(UI.rgb(locked and C.bg or C.panel))
        local hero = owned and Heroes.byId[id] or nil
        for name, b in pairs(card.forms) do
            b:SetShown(hero ~= nil and hero.forms ~= nil)
            if hero and hero.forms then b:setSelected((s.heroes[id].form or hero.defaultForm) == name) end
        end
        if owned then
            local h = s.heroes[id]
            card.icon:set(UI.CLASS_ICONS[hero.class])
            card.name:SetText(hero.name)
            card.sub:SetText(roleText(hero, h.form) .. "  ·  레벨 " .. h.level)
            card.remove:setEnabled(#s.party > 1)
            card.front:setEnabled(i > 1)
            card.back:setEnabled(s.party[i + 1] ~= nil)
        elseif locked then
            card.empty:SetText("잠김  ·  룬에서 편성 칸을 엽니다")
        else
            card.empty:SetText("비어 있음  ·  오른쪽에서 영웅을 고르세요")
        end
    end

    local n = 0
    local full = #s.party >= slots
    for _, hero in ipairs(Heroes.list) do
        local h = s.heroes[hero.id]
        if h and not inParty[hero.id] then
            n = n + 1
            local row = benchRow(f, n)
            row.heroId = hero.id
            row:setText(hero.name)
            row.right:SetText(roleText(hero, h.form) .. "  ·  레벨 " .. h.level)
            row:setEnabled(not full)
            row:Show()
        end
    end
    for i = n + 1, #f.benchRows do f.benchRows[i]:Hide() end
    f.bench:setHeight(n * 34)
    if n == 0 then
        f.benchEmpty:SetText("대기 중인 영웅이 없습니다. 영웅 화면에서 골드 " .. Game.HERO_UNLOCK_COST .. "으로 새 영웅을 해금할 수 있습니다.")
    elseif full then
        f.benchEmpty:SetText("")
        f.benchTitle:SetText("대기 중인 영웅  ·  편성 칸이 가득 찼습니다")
    end
    if n > 0 and not full then f.benchTitle:SetText("대기 중인 영웅  ·  누르면 편성에 들어갑니다") end
    if n == 0 then f.benchTitle:SetText("대기 중인 영웅") end
    f.benchEmpty:SetShown(n == 0)
    f.hint:SetText(f.dirty and "바꾼 편성은 다음 스테이지부터 적용됩니다." or ("편성 칸 " .. #s.party .. " / " .. slots))
end

UI.screens.party = { label = "편성", order = 4, create = create, refresh = refresh }
