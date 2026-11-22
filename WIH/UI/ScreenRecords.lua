-- 기록 화면: 지금 싸우고 있는 편성의 상태, 최근 진행 기록, 누적 통계.

local _, WIH = ...
local UI = WIH.module("UI")
local App = WIH.module("App")
local Heroes = WIH.module("Heroes")
local Tables = WIH.module("Tables")
local SkillData = WIH.module("SkillData")

local C = UI.C
local CARD_W = 178

local function duration(sec)
    sec = math.floor(sec or 0)
    local h, m = math.floor(sec / 3600), math.floor(sec % 3600 / 60)
    if h > 0 then return h .. "시간 " .. m .. "분" end
    return m .. "분 " .. (sec % 60) .. "초"
end

local function newCard(parent)
    local card = UI.panel(parent, C.panel, true)
    card:SetSize(CARD_W, 128)
    card.icon = UI.icon(card, 30)
    card.icon:SetPoint("TOPLEFT", 10, -10)
    card.name = UI.text(card, 12, C.text)
    card.name:SetPoint("TOPLEFT", 48, -10)
    card.name:SetPoint("TOPRIGHT", -8, -10)
    card.level = UI.text(card, 11, C.sub)
    card.level:SetPoint("TOPLEFT", 48, -27)
    card.hp = UI.bar(card, CARD_W - 20, 8, C.good)
    card.hp:SetPoint("TOPLEFT", 10, -48)
    card.hpText = UI.text(card, 10, C.sub)
    card.hpText:SetPoint("TOPLEFT", 10, -60)
    card.exp = UI.bar(card, CARD_W - 20, 3, C.exp)
    card.exp:SetPoint("TOPLEFT", 10, -76)
    card.skills = {}
    for i = 1, 4 do
        local s = UI.icon(card, 30)
        s:SetPoint("TOPLEFT", 10 + (i - 1) * 36, -86)
        s.shade = UI.fill(s, C.bg, "OVERLAY", 0.75)
        s.shade:SetPoint("BOTTOMLEFT", 1, 1)
        s.shade:SetPoint("BOTTOMRIGHT", -1, 1)
        s.shade:SetHeight(1)
        s.count = UI.text(s, 10, C.text, "CENTER")
        s.count:SetPoint("BOTTOM", 0, 2)
        s:EnableMouse(true)
        s:SetScript("OnEnter", function(self)
            if not self.def then return end
            UI.showTooltip(self, { title = self.def.name .. "  " .. self.level .. "레벨",
                lines = { { SkillData.activation(self.def, self.level), C.dim }, SkillData.describe(self.def, self.level) } })
        end)
        s:SetScript("OnLeave", UI.hideTooltip)
        card.skills[i] = s
    end
    return card
end

local function updateCard(card, u, heroState)
    local hero = Heroes.byId[u.heroId]
    if card.unit ~= u then
        card.unit = u
        card.icon:set(UI.CLASS_ICONS[hero.class])
        card.name:SetText(hero.name .. (u.form and hero.forms and (" · " .. hero.forms[u.form].name) or ""))
        for i = 1, 4 do
            local slot, s = u.skills[i], card.skills[i]
            if slot then
                s.def, s.level = slot.def, WIH.Skills.effectiveLevel(u, slot)
                s:set(slot.def.icon)
                s:Show()
            else
                s.def = nil
                s:Hide()
            end
        end
    end
    card.level:SetText("레벨 " .. heroState.level)
    local maxHp = u:get("MaxHp")
    if u.alive then
        card.hp:set(u.hp / maxHp, u:shieldTotal() / maxHp)
        card.hpText:SetText(UI.number(u.hp) .. " / " .. UI.number(maxHp))
        card.hpText:SetTextColor(UI.rgb(C.sub))
        card:SetAlpha(1)
    else
        card.hp:set(0)
        local battle = u.battle
        local left = battle and u.diedAt and math.max(0, battle.reviveDelay - (battle.time - u.diedAt)) or 0
        card.hpText:SetText(string.format("쓰러짐 · 부활까지 %d초", math.ceil(left)))
        card.hpText:SetTextColor(UI.rgb(C.bad))
        card:SetAlpha(0.7)
    end
    local need = Tables.EXP[heroState.level]
    card.exp:set(need and heroState.exp / need or 1)
    for i = 1, 4 do
        local slot, s = u.skills[i], card.skills[i]
        if slot and s.def then
            local actDef = slot.def.act
            if actDef.type == "cd" and slot.cd then
                local ratio = 1 - math.min(1, slot.charge / slot.cd)
                s.shade:SetHeight(math.max(1, 28 * ratio))
                s.shade:SetShown(ratio > 0.02)
                s.count:SetText("")
            elseif actDef.type == "count" then
                s.shade:Hide()
                s.count:SetText(slot.count .. "/" .. actDef.n)
            else
                s.shade:Hide()
                s.count:SetText("")
            end
        end
    end
end

local function create(parent)
    local f = CreateFrame("Frame", nil, parent)
    local l1 = UI.label(f, "현재 전투")
    l1:SetPoint("TOPLEFT", 14, -14)
    f.where = UI.text(f, 11, C.sub, "RIGHT")
    f.where:SetPoint("TOPRIGHT", -14, -14)
    f.cards = {}
    for i = 1, 5 do
        local card = newCard(f)
        card:SetPoint("TOPLEFT", 14 + (i - 1) * (CARD_W + 8), -34)
        f.cards[i] = card
    end

    local l2 = UI.label(f, "최근 기록")
    l2:SetPoint("TOPLEFT", 14, -176)
    f.logPanel = UI.panel(f, C.panel, true)
    f.logPanel:SetPoint("TOPLEFT", 14, -196)
    f.logPanel:SetPoint("BOTTOMRIGHT", -330, 14)
    f.log = UI.paragraph(f.logPanel, 11, C.sub)
    f.log:SetPoint("TOPLEFT", 12, -10)
    f.log:SetPoint("BOTTOMRIGHT", -12, 10)
    f.log:SetJustifyV("BOTTOM")
    if f.log.SetSpacing then f.log:SetSpacing(3) end

    f.statPanel = UI.panel(f, C.panel, true)
    local l3 = UI.label(f, "통계")
    l3:SetPoint("BOTTOMLEFT", f.statPanel, "TOPLEFT", 0, 8)
    f.statPanel:SetPoint("TOPRIGHT", -14, -196)
    f.statPanel:SetPoint("BOTTOMRIGHT", -14, 14)
    f.statPanel:SetWidth(302)
    f.statNames = UI.paragraph(f.statPanel, 12, C.sub)
    f.statNames:SetPoint("TOPLEFT", 14, -12)
    f.statNames:SetWidth(150)
    f.statValues = UI.paragraph(f.statPanel, 12, C.text)
    f.statValues:SetPoint("TOPRIGHT", -14, -12)
    f.statValues:SetWidth(130)
    f.statValues:SetJustifyH("RIGHT")
    if f.statNames.SetSpacing then f.statNames:SetSpacing(6); f.statValues:SetSpacing(6) end
    f.acc = 1
    return f
end

local function paint(f)
    local s = App.state
    if not s then return end
    local runner = App.session and App.session.runner
    f.where:SetText(runner and (App.stageName(runner.key) .. "  ·  " .. (runner.raid and "보스 " or (runner.phase == "boss" and "보스  ·  웨이브 " or "웨이브 "))
        .. runner.wave .. " / " .. runner.waves) or "")
    for i = 1, 5 do
        local card = f.cards[i]
        local u = runner and runner.heroes[i]
        if u and s.heroes[u.heroId] then
            card:Show()
            updateCard(card, u, s.heroes[u.heroId])
        else
            card:Hide()
        end
    end
    local log = App.log
    local from = math.max(1, #log - 15)
    local lines = {}
    for i = from, #log do lines[#lines + 1] = log[i] end
    f.log:SetText(#lines > 0 and table.concat(lines, "\n") or "|cff666b74아직 기록이 없습니다.|r")
    local st = s.stats
    f.statNames:SetText("진행 시간\n처치\n보스 처치\n클리어\n전멸\n번 골드\n연 상자")
    f.statValues:SetText(table.concat({ duration(st.playSeconds), UI.number(st.kills), UI.number(st.bossKills), UI.number(st.clears),
        UI.number(st.fails), UI.number(math.floor(st.goldEarned)), UI.number(st.chestsOpened or 0) }, "\n"))
end

local function refresh(f)
    paint(f)
end

local function update(f, elapsed)
    f.acc = f.acc + elapsed
    if f.acc < 0.2 then return end
    f.acc = 0
    paint(f)
end

UI.screens.records = { label = "기록", order = 6, create = create, refresh = refresh, update = update }
