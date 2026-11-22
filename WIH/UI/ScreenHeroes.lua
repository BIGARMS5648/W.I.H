-- 영웅 화면: 왼쪽 목록, 가운데 캐릭터와 장비 10칸·전투력, 오른쪽 스킬·패시브·능력치.
-- 규칙은 Game·Inventory·Power의 함수가 판단한다. 이 화면은 보여 주고 그 함수를 부르기만 한다.

local _, WIH = ...
local UI = WIH.module("UI")
local App = WIH.module("App")
local Game = WIH.module("Game")
local Heroes = WIH.module("Heroes")
local Stats = WIH.module("Stats")
local Tables = WIH.module("Tables")
local SkillData = WIH.module("SkillData")
local HeroBuild = WIH.module("HeroBuild")
local Runes = WIH.module("Runes")
local Items = WIH.module("Items")
local Inventory = WIH.module("Inventory")
local Power = WIH.module("Power")
local Models = WIH.module("Models")
local Looks = WIH.module("Looks")

local C = UI.C
local LIST_W, SIDE_W = 232, 292
local LEFT_SLOTS = { "MAIN", "HELMET", "ARMOR", "GLOVES", "BOOTS" }
local RIGHT_SLOTS = { "SUB", "AMULET", "EARRING", "RING", "BRACER" }
local FILTERS = { { "all", "전체" }, { "tank", "탱커" }, { "dps", "딜러" }, { "healer", "힐러" } }

-- 수정치 한 줄의 표기: "최대 체력 +15", "공격속도 +4% 증가"
function UI.modModText(stat, kind, raw)
    return Items.modText({ stat, kind, raw })
end

local function roleOf(hero, form)
    local _, _, role = HeroBuild.baseOf(hero, form)
    return role
end

local function matches(filter, role)
    if filter == "all" then return true end
    if filter == "dps" then return role == "melee" or role == "ranged" or role == "summoner" end
    return role == filter
end

local function selected(f)
    local s = App.state
    if not f.heroId or not Heroes.byId[f.heroId] then f.heroId = s.party[1] end
    return Heroes.byId[f.heroId], s.heroes[f.heroId]
end

local function act(f, ok, why)
    if not ok then WIH.Main.notice(why, C.bad) else f.dirty = true end
    UI.screens.heroes.refresh(f)
end

------------------------------------------------------------------------
-- 만들기
------------------------------------------------------------------------

local function createList(f)
    f.chips = {}
    local x = 10
    for _, it in ipairs(FILTERS) do
        local b = UI.chip(f, it[2], function()
            f.filter = it[1]
            UI.screens.heroes.refresh(f)
        end)
        b:SetPoint("TOPLEFT", x, -12)
        b.id = it[1]
        f.chips[#f.chips + 1] = b
        x = x + b:GetWidth() + 5
    end
    f.list = UI.scroll(f)
    f.list:SetPoint("TOPLEFT", 10, -44)
    f.list:SetPoint("BOTTOMLEFT", 10, 8)
    f.list:SetWidth(LIST_W - 20)
    f.rows, f.heads = {}, {}
    local line = UI.fill(f, C.line, "ARTWORK")
    line:SetPoint("TOPLEFT", LIST_W, 0)
    line:SetPoint("BOTTOMLEFT", LIST_W, 0)
    line:SetWidth(1)
end

local function listRow(f, n)
    local row = f.rows[n]
    if row then return row end
    row = UI.listRow(f.list.content, LIST_W - 20, 40, function(self)
        f.heroId = self.heroId
        UI.screens.heroes.refresh(f)
    end)
    row.icon = UI.icon(row, 28)
    row.icon:SetPoint("LEFT", 8, 0)
    row.name = UI.text(row, 12, C.text)
    row.name:SetPoint("TOPLEFT", 46, -6)
    row.role = UI.text(row, 10, C.dim)
    row.role:SetPoint("TOPLEFT", 46, -22)
    row.right = UI.text(row, 11, C.sub, "RIGHT")
    row.right:SetPoint("RIGHT", -8, 0)
    f.rows[n] = row
    return row
end

local function listHead(f, n)
    local h = f.heads[n]
    if h then return h end
    h = UI.label(f.list.content, "")
    f.heads[n] = h
    return h
end

local function createMid(f)
    local mid = CreateFrame("Frame", nil, f)
    mid:SetPoint("TOPLEFT", LIST_W + 1, 0)
    mid:SetPoint("BOTTOMRIGHT", -SIDE_W, 0)
    f.mid = mid
    f.name = UI.text(mid, 19, C.text)
    f.name:SetPoint("TOPLEFT", 22, -18)
    f.sub = UI.text(mid, 12, C.sub)
    f.sub:SetPoint("TOPLEFT", 22, -46)
    f.forms = {}
    for i, form in ipairs({ "bear", "cat" }) do
        local b = UI.chip(mid, form == "bear" and "곰 형태" or "표범 형태", function()
            act(f, Game.setForm(App.state, f.heroId, form))
        end)
        b:SetPoint("TOPLEFT", 22 + (i - 1) * 62, -66)
        f.forms[form] = b
    end
    f.level = UI.text(mid, 13, C.text, "RIGHT")
    f.level:SetPoint("TOPRIGHT", -22, -22)
    f.exp = UI.bar(mid, 150, 3, C.exp)
    f.exp:SetPoint("TOPRIGHT", -22, -46)
    f.expText = UI.text(mid, 10, C.dim, "RIGHT")
    f.expText:SetPoint("TOPRIGHT", -22, -54)

    -- 캐릭터(3D 모델). 쓸 수 없으면 직업 아이콘으로 바꾼다.
    f.model = UI.modelView(mid)
    f.model:SetSize(230, 300)
    f.model:SetPoint("TOP", 0, -84)
    f.modelIcon = UI.icon(mid, 64)
    f.modelIcon:SetPoint("TOP", 0, -180)
    f.modelIcon:Hide()

    -- 장비 10칸: 캐릭터의 양옆
    f.slots = {}
    local function makeSlots(list, right)
        for i, slot in ipairs(list) do
            local b = UI.slot(mid, 46)
            if right then b:SetPoint("TOPRIGHT", -26, -104 - (i - 1) * 55) else b:SetPoint("TOPLEFT", 26, -104 - (i - 1) * 55) end
            b.slot = slot
            b.onClick = function(self, button)
                local s = App.state
                if not s.heroes[f.heroId] then return end
                if button == "RightButton" then
                    if Inventory.equipped(s, f.heroId, slot) then act(f, Inventory.unequip(s, f.heroId, slot)) end
                else
                    -- 가방 화면을 이 영웅과 이 칸으로 맞춰서 연다.
                    UI.bagTarget = { heroId = f.heroId, slot = slot }
                    WIH.Main.show("bag")
                end
            end
            b.tooltip = function()
                local item, entry = Inventory.equipped(App.state, f.heroId, slot)
                if not item then
                    return { title = Items.SLOT_NAMES[slot], lines = { "비어 있습니다.", { "왼쪽 클릭: 가방에서 고르기", C.dim } } }
                end
                local tip = UI.itemTip(item, entry)
                tip.lines[#tip.lines + 1] = { "왼쪽 클릭: 가방에서 바꾸기 · 오른쪽 클릭: 해제", C.dim }
                return tip
            end
            f.slots[slot] = b
        end
    end
    makeSlots(LEFT_SLOTS, false)
    makeSlots(RIGHT_SLOTS, true)

    -- 아래: 전투력
    local line = UI.fill(mid, C.line, "ARTWORK")
    line:SetPoint("BOTTOMLEFT", 22, 62)
    line:SetPoint("BOTTOMRIGHT", -22, 62)
    line:SetHeight(1)
    f.powerLine = line
    f.powerLabel = UI.label(mid, "전투력")
    f.powerLabel:SetPoint("BOTTOMLEFT", 22, 42)
    f.power = UI.text(mid, 21, C.text)
    f.power:SetPoint("BOTTOMLEFT", 22, 14)
    f.kv = {}
    for i = 1, 3 do
        local k = UI.label(mid, "")
        k:SetPoint("BOTTOMLEFT", 118 + (i - 1) * 84, 36)
        local v = UI.text(mid, 13, C.text)
        v:SetPoint("BOTTOMLEFT", 118 + (i - 1) * 84, 16)
        f.kv[i] = { k = k, v = v }
    end
    f.powerTip = CreateFrame("Frame", nil, mid)
    f.powerTip:SetPoint("BOTTOMLEFT", 22, 12)
    f.powerTip:SetSize(340, 46)
    UI.setTooltip(f.powerTip, { title = "전투력", lines = {
        "초당 피해: 적 허수아비 하나를 30초 동안 실제 전투 계산으로 때린 결과입니다.",
        "초당 회복: 같은 전투에서 체력이 절반인 아군에게 들어간 회복과 보호막입니다.",
        "유효 체력: 현재 스테이지 보스의 기본 공격을 기준으로 쓰러질 때까지 받아낼 수 있는 피해의 총량입니다.",
        { "전투력 = 초당 피해 × 10 + 초당 회복 × 10 + 유효 체력 × 0.25", C.dim } } })
    f.unlock = UI.button(mid, "", 170, 30, function()
        local ok, why = Game.unlockHero(App.state, f.heroId)
        if not ok then WIH.Main.notice(why, C.bad) end
        UI.screens.heroes.refresh(f)
    end)
    f.unlock:SetPoint("BOTTOM", 0, 18)
end

local function createSide(f)
    local side = CreateFrame("Frame", nil, f)
    side:SetPoint("TOPRIGHT", 0, 0)
    side:SetPoint("BOTTOMRIGHT", 0, 0)
    side:SetWidth(SIDE_W)
    f.side = side
    local line = UI.fill(side, C.line, "ARTWORK")
    line:SetPoint("TOPLEFT", 0, 0)
    line:SetPoint("BOTTOMLEFT", 0, 0)
    line:SetWidth(1)
    local W = SIDE_W - 28
    f.pages = {}
    f.seg = UI.segment(side, { { "skill", "스킬" }, { "passive", "패시브" }, { "stat", "능력치" } }, W, function(id)
        f.page = id
        UI.screens.heroes.refresh(f)
    end)
    f.seg:SetPoint("TOPLEFT", 14, -14)
    f.page = "skill"
    local function page(id)
        local p = CreateFrame("Frame", nil, side)
        p:SetPoint("TOPLEFT", 14, -56)
        p:SetPoint("BOTTOMRIGHT", -14, 46)
        f.pages[id] = p
        return p
    end

    -- 스킬
    local sp = page("skill")
    local l1 = UI.label(sp, "장착 스킬")
    l1:SetPoint("TOPLEFT", 0, 0)
    local l1r = UI.label(sp, "앞에서부터 사용")
    l1r:SetPoint("TOPRIGHT", 0, 0)
    f.bar = {}
    for i = 1, Game.MAX_SKILL_SLOTS do
        local b = UI.slot(sp, 44)
        b:SetPoint("TOPLEFT", (i - 1) * 51, -18)
        b.onClick = function()
            local h = App.state.heroes[f.heroId]
            if not h or not h.bar[i] then return end
            local bar = {}
            for k, id in ipairs(h.bar) do if k ~= i then bar[#bar + 1] = id end end
            act(f, Game.setBar(App.state, f.heroId, bar))
        end
        f.bar[i] = b
    end
    local l2 = UI.label(sp, "스킬")
    l2:SetPoint("TOPLEFT", 0, -74)
    f.points = UI.text(sp, 11, C.warn, "RIGHT")
    f.points:SetPoint("TOPRIGHT", 0, -74)
    f.tiles = {}
    for idx = 1, 6 do
        local t = CreateFrame("Button", nil, sp)
        t:SetSize(W, 48)
        t:SetPoint("TOPLEFT", 0, -92 - (idx - 1) * 54)
        t.bg = UI.fill(t, C.panel)
        t.bg:SetAllPoints()
        UI.border(t)
        t.tier = UI.text(t, 10, C.dim, "RIGHT")
        t.tier:SetPoint("LEFT", 0, 0)
        t.tier:SetWidth(20)
        t.tier:SetText(tostring(Heroes.ACTIVE_TIERS[idx]))
        t.icon = UI.icon(t, 34)
        t.icon:SetPoint("LEFT", 26, 0)
        t.name = UI.text(t, 12, C.text)
        t.name:SetPoint("TOPLEFT", 70, -8)
        t.info = UI.text(t, 10, C.sub)
        t.info:SetPoint("TOPLEFT", 70, -27)
        t.pips = UI.pips(t, Heroes.ACTIVE_MAX_BY_POINTS)
        t.pips:SetPoint("TOPRIGHT", -8, -8)
        t.equip = UI.button(t, "장착", 44, 17, function()
            local hero, h = Heroes.byId[f.heroId], App.state.heroes[f.heroId]
            local id = hero.skills[idx]
            local bar, found = {}, false
            for _, sid in ipairs(h.bar) do
                if sid == id then found = true else bar[#bar + 1] = sid end
            end
            if not found then bar[#bar + 1] = id end
            act(f, Game.setBar(App.state, f.heroId, bar))
        end)
        t.equip.label:SetFont(STANDARD_TEXT_FONT or "Fonts\\2002.TTF", 10, "")
        t.equip:SetPoint("BOTTOMRIGHT", -6, 5)
        t:RegisterForClicks("LeftButtonUp", "RightButtonUp")
        t:SetScript("OnClick", function(_, button)
            local hero = Heroes.byId[f.heroId]
            if not App.state.heroes[f.heroId] then return end
            local id = hero.skills[idx]
            if button == "RightButton" then act(f, Game.refundActive(App.state, f.heroId, id))
            else act(f, Game.investActive(App.state, f.heroId, id)) end
        end)
        t:SetScript("OnEnter", function(self)
            local hero, h = Heroes.byId[f.heroId], App.state.heroes[f.heroId]
            local def = SkillData.resolve(hero.skills[idx], h and h.form or hero.defaultForm)
            local lv = h and h.active[hero.skills[idx]] or 0
            local lines = { { SkillData.activation(def, math.max(1, lv)), C.dim } }
            if lv > 0 then lines[#lines + 1] = { "현재 " .. lv .. "레벨: " .. SkillData.describe(def, lv), C.text } end
            if lv < 10 then lines[#lines + 1] = { (lv + 1) .. "레벨: " .. SkillData.describe(def, lv + 1), C.sub } end
            lines[#lines + 1] = { "왼쪽 클릭: 포인트 투자 · 오른쪽 클릭: 환급. 포인트로는 " .. Heroes.ACTIVE_MAX_BY_POINTS .. "레벨까지.", C.dim }
            UI.showTooltip(self, { title = def.name, lines = lines })
        end)
        t:SetScript("OnLeave", UI.hideTooltip)
        f.tiles[idx] = t
    end

    -- 패시브
    local pp = page("passive")
    f.passivePoints = UI.text(pp, 11, C.warn, "RIGHT")
    f.passivePoints:SetPoint("TOPRIGHT", 0, 0)
    local pl = UI.label(pp, "패시브  ·  왼쪽 클릭 투자, 오른쪽 클릭 환급")
    pl:SetPoint("TOPLEFT", 0, 0)
    f.passives = {}
    for index = 1, 16 do
        local row = UI.listRow(pp, W, 24, function(_, button)
            if not App.state.heroes[f.heroId] then return end
            if button == "RightButton" then act(f, Game.refundPassive(App.state, f.heroId, index))
            else act(f, Game.investPassive(App.state, f.heroId, index)) end
        end)
        row:SetPoint("TOPLEFT", 0, -18 - (index - 1) * 25)
        row.tier = UI.text(row, 10, C.dim, "RIGHT")
        row.tier:SetPoint("LEFT", 0, 0)
        row.tier:SetWidth(20)
        row.tier:SetText(index % 2 == 1 and tostring(Heroes.PASSIVE_TIERS[index]) or "")
        row.name = UI.text(row, 11, C.text)
        row.name:SetPoint("LEFT", 28, 0)
        row.right = UI.text(row, 11, C.sub, "RIGHT")
        row.right:SetPoint("RIGHT", -6, 0)
        f.passives[index] = row
    end

    -- 능력치
    local tp = page("stat")
    f.statNames = UI.paragraph(tp, 11, C.sub)
    f.statNames:SetPoint("TOPLEFT", 0, 0)
    f.statNames:SetWidth(150)
    f.statValues = UI.paragraph(tp, 11, C.text)
    f.statValues:SetPoint("TOPRIGHT", 0, 0)
    f.statValues:SetWidth(110)
    f.statValues:SetJustifyH("RIGHT")
    if f.statNames.SetSpacing then f.statNames:SetSpacing(4); f.statValues:SetSpacing(4) end

    -- 아래: 적용
    f.apply = UI.button(side, "지금 적용", 92, 26, function()
        f.dirty = false
        App.restartStage()
        UI.screens.heroes.refresh(f)
    end)
    f.apply:SetPoint("BOTTOMLEFT", 14, 12)
    f.apply.tooltip = { title = "지금 적용", lines = { "현재 스테이지를 처음부터 다시 시작해 바꾼 내용을 바로 적용합니다. 누르지 않으면 다음 스테이지부터 적용됩니다." } }
    f.reset = UI.button(side, "트리 초기화", 92, 26, function()
        if not App.state.heroes[f.heroId] then return end
        Game.resetTree(App.state, f.heroId)
        f.dirty = true
        UI.screens.heroes.refresh(f)
    end)
    f.reset:SetPoint("LEFT", f.apply, "RIGHT", 6, 0)
    f.reset.tooltip = { title = "트리 초기화", lines = { "이 영웅의 스킬과 패시브에 넣은 포인트를 모두 돌려받습니다. 비용은 없습니다." } }
    f.hint = UI.text(side, 10, C.dim)
    f.hint:SetPoint("BOTTOMLEFT", 14, 44)
end

local function create(parent)
    local f = CreateFrame("Frame", nil, parent)
    f.filter = "all"
    createList(f)
    createMid(f)
    createSide(f)
    return f
end

------------------------------------------------------------------------
-- 그리기
------------------------------------------------------------------------

local function refreshList(f)
    local s = App.state
    for _, b in ipairs(f.chips) do b:setSelected(b.id == f.filter) end
    local groups = { { title = "편성 중", items = {} }, { title = "대기", items = {} }, { title = "잠김  ·  해금 " .. Game.HERO_UNLOCK_COST .. " G", items = {} } }
    local inParty = {}
    for _, id in ipairs(s.party) do inParty[id] = true end
    for _, id in ipairs(s.party) do
        local hero = Heroes.byId[id]
        if matches(f.filter, roleOf(hero, s.heroes[id].form)) then table.insert(groups[1].items, hero) end
    end
    for _, hero in ipairs(Heroes.list) do
        local h = s.heroes[hero.id]
        if not inParty[hero.id] and matches(f.filter, roleOf(hero, h and h.form)) then
            table.insert(groups[h and 2 or 3].items, hero)
        end
    end
    local y, n, hn = 0, 0, 0
    for _, g in ipairs(groups) do
        if #g.items > 0 then
            hn = hn + 1
            local head = listHead(f, hn)
            head:ClearAllPoints()
            head:SetPoint("TOPLEFT", 4, -y - 6)
            head:SetText(g.title)
            head:Show()
            y = y + 24
            for _, hero in ipairs(g.items) do
                n = n + 1
                local row = listRow(f, n)
                local h = s.heroes[hero.id]
                row.heroId = hero.id
                row:ClearAllPoints()
                row:SetPoint("TOPLEFT", 0, -y)
                row.icon:set(UI.CLASS_ICONS[hero.class])
                row.name:SetText(hero.name)
                row.role:SetText(Heroes.ROLES[roleOf(hero, h and h.form)])
                row.right:SetText(h and ("Lv " .. h.level) or "해금")
                row:SetAlpha(h and 1 or 0.5)
                row:setSelected(hero.id == f.heroId)
                row:Show()
                y = y + 42
            end
            y = y + 4
        end
    end
    for i = n + 1, #f.rows do f.rows[i]:Hide() end
    for i = hn + 1, #f.heads do f.heads[i]:Hide() end
    f.list:setHeight(y)
end

local STAT_ROWS = {
    { "MaxHp", "num" }, { "Armor", "num" }, { "AttackDamage", "dec" }, { "AttackSpeed", "dec2" }, { "CriticalChance", "pct" },
    { "CriticalDamage", "pct" }, { "CooldownReduction", "pct" }, { "CastSpeed", "pct" }, { "MovementSpeed", "num" },
    { "DodgeChance", "pct" }, { "BlockChance", "pct" }, { "DamageReduction", "pct" }, { "DamageAbsorption", "dec" },
    { "HpRegenPerSec", "dec" }, { "HpLeech", "pct" }, { "FireResistance", "num" }, { "ColdResistance", "num" },
    { "LightningResistance", "num" }, { "ChaosResistance", "num" }, { "AreaOfEffect", "pct" }, { "SkillDurationIncrease", "pct" },
    { "SkillHealIncrease", "pct" }, { "IncreaseExpAmount", "pct" },
}

local function statText(u, range)
    local names, values = {}, {}
    for _, row in ipairs(STAT_ROWS) do
        local v = u:get(row[1])
        names[#names + 1] = Stats.defs[row[1]].label
        if row[2] == "pct" then values[#values + 1] = SkillData.formatNumber(math.floor(v * 1000 + 0.5) / 10) .. "%"
        elseif row[2] == "dec2" then values[#values + 1] = string.format("%.2f", v)
        elseif row[2] == "dec" then values[#values + 1] = SkillData.formatNumber(math.floor(v * 10 + 0.5) / 10)
        else values[#values + 1] = UI.number(v) end
    end
    names[#names + 1] = "사거리"
    values[#values + 1] = tostring(range)
    return table.concat(names, "\n"), table.concat(values, "\n")
end

local function refresh(f)
    local s = App.state
    if not s then return end
    local hero, h = selected(f)
    local owned = h ~= nil
    local form = h and h.form or hero.defaultForm
    local _, range, role = HeroBuild.baseOf(hero, form)
    refreshList(f)

    -- 가운데
    f.name:SetText(hero.name)
    f.sub:SetText(Heroes.CLASSES[hero.class] .. "  ·  " .. Heroes.ROLES[role] .. "  ·  " .. Heroes.MAIN_WEAPONS[hero.main].name .. "와 " .. Heroes.SUB_WEAPONS[hero.sub].name)
    for name, b in pairs(f.forms) do
        b:SetShown(owned and hero.forms ~= nil)
        b:setSelected(form == name)
    end
    f.level:SetText(owned and ("레벨 " .. h.level) or "잠김")
    f.exp:SetShown(owned)
    f.expText:SetShown(owned)
    if owned then
        local need = Tables.EXP[h.level]
        f.exp:set(need and h.exp / need or 1)
        f.expText:SetText(need and ("다음 레벨까지 " .. UI.number(need - h.exp)) or "최대 레벨")
    end
    -- 모델: 영웅, 형태, 진영, 낀 장비(겉모습)가 바뀌었을 때만 다시 불러온다.
    -- 낀 장비대로 옷을 입힌 캐릭터를 먼저 시도하고, 안 되면 생물 모델, 그것도 안 되면 직업 아이콘을 보여 준다.
    local opts = WIH.Scene.options()
    local look = opts.looks ~= false and Looks.forHero(s, hero.id) or nil
    local modelKey = hero.id .. ":" .. tostring(form) .. ":" .. s.faction .. ":" .. (look and look.key or "-") .. ":" .. tostring(opts.models)
    if f.modelKey ~= modelKey then
        f.modelKey = modelKey
        f.modelIcon:Hide()
        f.modelIcon:set(UI.CLASS_ICONS[hero.class])
        local candidates = Models.heroCandidates(hero.id, s.faction, hero.forms and form or nil)
        local function showIcon() f.model:clear(); f.modelIcon:Show() end
        if not opts.models then
            showIcon()
        elseif look and f.model:setCharacter(look, 0.35, 1.2) then
            f.model.onFail = function()
                f.model.onFail = showIcon
                if not f.model:setCreature(candidates, 0.35, 1.2) then showIcon() end
            end
        else
            f.model.onFail = showIcon
            if not f.model:setCreature(candidates, 0.35, 1.2) then showIcon() end
        end
    end
    for slot, b in pairs(f.slots) do
        local item = owned and Inventory.equipped(s, hero.id, slot) or nil
        b:SetShown(owned)
        if item then
            b:setIcon(item.icon, Items.GRADES[item.grade].color)
            b.corner:SetText(tostring(item.level))
            b.center:SetText("")
        else
            b:setIcon(nil, C.line)
            b.corner:SetText("")
            b.center:SetText(Items.SLOT_NAMES[slot])
        end
    end
    f.unlock:SetShown(not owned)
    f.powerLabel:SetShown(owned); f.power:SetShown(owned); f.powerTip:SetShown(owned); f.powerLine:SetShown(owned)
    for _, kv in ipairs(f.kv) do kv.k:SetShown(owned); kv.v:SetShown(owned) end
    if owned then
        local p = Power.get(s, hero.id)
        f.power:SetText(UI.number(p.power))
        local list = { { "초당 피해", SkillData.formatNumber(math.floor(p.dps * 10 + 0.5) / 10) } }
        if p.hps > 0.05 then list[#list + 1] = { "초당 회복", SkillData.formatNumber(math.floor(p.hps * 10 + 0.5) / 10) } end
        list[#list + 1] = { "유효 체력", p.ehp == math.huge and "∞" or UI.number(p.ehp) }
        for i, kv in ipairs(f.kv) do
            kv.k:SetText(list[i] and list[i][1] or "")
            kv.v:SetText(list[i] and list[i][2] or "")
        end
    else
        f.unlock:setText("해금  " .. Game.HERO_UNLOCK_COST .. " G")
        f.unlock:setEnabled(s.gold >= Game.HERO_UNLOCK_COST)
    end

    -- 오른쪽
    f.seg:pick(f.page)
    for id, p in pairs(f.pages) do p:SetShown(id == f.page) end
    f.apply:setEnabled(owned)
    f.reset:setEnabled(owned)
    f.hint:SetText(f.dirty and "바꾼 내용은 다음 스테이지부터 적용됩니다." or "")
    local free = owned and Game.freePoints(s, hero.id) or 0
    local slots = Game.skillSlots(s)

    if f.page == "skill" then
        f.points:SetText(owned and ("남은 포인트 " .. free) or "")
        local equipped = {}
        for i, id in ipairs(h and h.bar or {}) do equipped[id] = i end
        for i, b in ipairs(f.bar) do
            local id = h and h.bar[i]
            if i > slots then
                b:setIcon(nil, C.line)
                b.center:SetText("룬")
                b.tooltip = { title = "잠긴 칸", lines = { "성장 화면의 룬에서 스킬 칸을 엽니다." } }
            elseif id then
                local def = SkillData.resolve(id, form)
                b:setIcon(def.icon, C.line2)
                b.center:SetText("")
                b.tooltip = { title = def.name, lines = { SkillData.describe(def, h.active[id] or 1), { "누르면 해제합니다.", C.dim } } }
            else
                b:setIcon(nil, C.line)
                b.center:SetText("")
                b.tooltip = { title = "빈 칸", lines = { "아래에서 배운 스킬의 '장착'을 누르세요." } }
            end
        end
        for idx, t in ipairs(f.tiles) do
            local id = hero.skills[idx]
            local def = SkillData.resolve(id, form)
            local lv = h and h.active[id] or 0
            local open = owned and Game.tierOpen(s, hero.id, Heroes.ACTIVE_TIERS[idx])
            t.icon:set(def.icon)
            t.icon.tex:SetDesaturated(lv == 0)
            t.name:SetText(def.name)
            if not owned then
                t.info:SetText(SkillData.activation(def, 1))
            elseif not open then
                t.info:SetText("포인트 " .. Heroes.ACTIVE_TIERS[idx] .. " 이상 투자 시 열림")
            else
                t.info:SetText(SkillData.activation(def, math.max(1, lv)) .. (lv > Heroes.ACTIVE_MAX_BY_POINTS and ("  ·  " .. lv .. "레벨") or ""))
            end
            t.pips:set(math.min(lv, Heroes.ACTIVE_MAX_BY_POINTS))
            t:SetAlpha((owned and (open or lv > 0)) and 1 or 0.5)
            t.bg:SetColorTexture(UI.rgb(lv > 0 and C.raised or C.panel))
            UI.setBorderColor(t, equipped[id] and UI.accent() or (lv > 0 and C.line2 or C.line))
            t.equip:SetShown(owned and lv > 0)
            t.equip:setText(equipped[id] and "해제" or "장착")
            t.equip:setSelected(equipped[id] ~= nil)
        end
    elseif f.page == "passive" then
        f.passivePoints:SetText(owned and ("남은 포인트 " .. free) or "")
        for index, row in ipairs(f.passives) do
            local node = hero.passives[index]
            local pts = h and h.passive[index] or 0
            local open = owned and Game.tierOpen(s, hero.id, Heroes.PASSIVE_TIERS[index])
            row.name:SetText(Items.modText({ node.stat, node.kind, node.per }))
            row.name:SetTextColor(UI.rgb(pts > 0 and C.text or C.sub))
            row.right:SetText(pts .. " / " .. node.max)
            row.right:SetTextColor(UI.rgb(pts >= node.max and C.good or (pts > 0 and C.text or C.dim)))
            row:SetAlpha((open or pts > 0) and 1 or 0.45)
            row.tooltip = { title = Stats.defs[node.stat].label, lines = {
                "포인트 하나마다 " .. Items.modText({ node.stat, node.kind, node.per }),
                { open and "왼쪽 클릭 투자 · 오른쪽 클릭 환급" or ("포인트 " .. Heroes.PASSIVE_TIERS[index] .. " 이상 투자 시 열림"), C.dim } } }
        end
    else
        -- 능력치: 전투와 같은 계산으로 만든 유닛에서 읽는다.
        local u = HeroBuild.makeUnit(hero.id, { form = form, passivePoints = h and h.passive or nil, account = Runes.sheet(s),
            gear = Inventory.gearSheet(s, hero.id) })
        local names, values = statText(u, range)
        f.statNames:SetText(names)
        f.statValues:SetText(values)
    end
end

-- 모델이 불러와졌는지 확인(실패하면 아이콘으로 바뀐다)
local function update(f, elapsed)
    if f.model then f.model:update(elapsed) end
end

UI.screens.heroes = { label = "영웅", order = 1, create = create, refresh = refresh, update = update }
