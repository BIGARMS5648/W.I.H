-- 영웅 화면: 영웅 목록과 해금, 능력치, 스킬 트리(투자·환급), 장착 스킬.

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

local C = UI.C

-- 수정치 한 줄의 표기: "최대 체력 +15", "공격속도 +4% 증가"
function UI.modText(stat, kind, raw)
    local d = Stats.defs[stat]
    local label = d and d.label or stat
    if kind == Stats.FLAT then
        local v, unit = raw, ""
        if d.scale == 1000 then v, unit = raw / 10, "%"
        elseif d.scale == 100 then v = raw / 100
        elseif d.scale == 10 then v = raw / 10 end
        return string.format("%s %s%s%s", label, v >= 0 and "+" or "", SkillData.formatNumber(v), unit)
    end
    local v = raw / 10
    return string.format("%s %s%s%% %s", label, v >= 0 and "+" or "", SkillData.formatNumber(v), kind == Stats.INC and "증가" or "곱")
end

local function selectedHero(f)
    local s = App.state
    if not f.heroId or not Heroes.byId[f.heroId] then f.heroId = s.party[1] end
    return Heroes.byId[f.heroId], s.heroes[f.heroId]
end

local function create(parent)
    local f = CreateFrame("Frame", nil, parent)

    -- 왼쪽: 영웅 목록
    f.list = UI.scroll(f)
    f.list:SetPoint("TOPLEFT", 10, -10)
    f.list:SetPoint("BOTTOMLEFT", 10, 10)
    f.list:SetWidth(176)
    f.rows = {}
    local y = 0
    for _, class in ipairs(Heroes.CLASS_ORDER) do
        local head = UI.text(f.list.content, 11, C.dim)
        head:SetPoint("TOPLEFT", 4, -y - 4)
        head:SetText(Heroes.CLASSES[class])
        y = y + 20
        for _, hero in ipairs(Heroes.list) do
            if hero.class == class then
                local b = UI.button(f.list.content, "", 170, 24, function()
                    f.heroId = hero.id
                    UI.screens.heroes.refresh(f)
                end)
                b:SetPoint("TOPLEFT", 0, -y)
                b.label:ClearAllPoints()
                b.label:SetPoint("LEFT", 8, 0)
                b.label:SetJustifyH("LEFT")
                b.right = UI.text(b, 11, C.sub, "RIGHT")
                b.right:SetPoint("RIGHT", -8, 0)
                f.rows[hero.id] = b
                y = y + 26
            end
        end
        y = y + 4
    end
    f.list:setHeight(y)

    -- 오른쪽: 상세
    local d = CreateFrame("Frame", nil, f)
    d:SetPoint("TOPLEFT", f.list, "TOPRIGHT", 12, 0)
    d:SetPoint("BOTTOMRIGHT", -10, 10)
    f.detail = d
    f.icon = UI.icon(d, 40)
    f.icon:SetPoint("TOPLEFT", 0, 0)
    f.name = UI.text(d, 15, C.text)
    f.name:SetPoint("TOPLEFT", f.icon, "TOPRIGHT", 12, -1)
    f.role = UI.text(d, 12, C.sub)
    f.role:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, -6)
    f.level = UI.text(d, 12, C.text, "RIGHT")
    f.level:SetPoint("TOPRIGHT", 0, -2)
    f.exp = UI.bar(d, 200, 5, C.exp)
    f.exp:SetPoint("TOPRIGHT", 0, -22)
    f.points = UI.text(d, 12, C.warn, "RIGHT")
    f.points:SetPoint("TOPRIGHT", 0, -34)
    f.unlock = UI.button(d, "", 150, 26, function()
        local ok, why = Game.unlockHero(App.state, f.heroId)
        if not ok then WIH.Main.notice(why, C.bad) end
        UI.screens.heroes.refresh(f)
    end)
    f.unlock:SetPoint("TOPLEFT", 0, -56)

    f.stats = UI.paragraph(d, 11, C.sub)
    f.stats:SetPoint("TOPLEFT", 0, -56)
    f.stats:SetPoint("RIGHT", 0, 0)

    f.forms = {}
    for i, form in ipairs({ "bear", "cat" }) do
        local b = UI.button(d, form == "bear" and "곰 형태" or "표범 형태", 84, 22, function()
            Game.setForm(App.state, f.heroId, form)
            f.dirty = true
            UI.screens.heroes.refresh(f)
        end)
        b:SetPoint("TOPLEFT", (i - 1) * 90, -96)
        f.forms[form] = b
    end

    -- 스킬 트리: 티어 8줄
    local tree = CreateFrame("Frame", nil, d)
    tree:SetPoint("TOPLEFT", 0, -124)
    tree:SetPoint("RIGHT", 0, 0)
    tree:SetHeight(8 * 42)
    f.tree = tree
    f.actives, f.passives, f.equips = {}, {}, {}
    local activeAt = { [0] = { 1, 2 }, [10] = { 3 }, [20] = { 4 }, [30] = { 5 }, [40] = { 6 } }
    for row = 0, 7 do
        local tier = row * 10
        local yy = -row * 42
        local label = UI.text(tree, 11, C.dim, "RIGHT")
        label:SetPoint("TOPLEFT", 0, yy - 12)
        label:SetWidth(24)
        label:SetText(tostring(tier))
        f["tierLabel" .. tier] = label
        local x = 34
        for _, idx in ipairs(activeAt[tier] or {}) do
            local b = CreateFrame("Button", nil, tree)
            b:SetSize(38, 38)
            b:SetPoint("TOPLEFT", x, yy)
            b.icon = UI.icon(b, 38)
            b.icon:SetAllPoints()
            b.lvbg = UI.fill(b.icon, C.bg, "OVERLAY", 0.8)
            b.lvbg:SetPoint("BOTTOMRIGHT", -1, 1)
            b.lvbg:SetSize(18, 14)
            b.lv = UI.text(b.icon, 11, C.text, "CENTER")
            b.lv:SetPoint("CENTER", b.lvbg, "CENTER", 0, 0)
            b.lv:SetDrawLayer("OVERLAY", 2)
            b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
            b:SetScript("OnClick", function(_, button)
                local hero = Heroes.byId[f.heroId]
                local id = hero.skills[idx]
                local ok, why
                if button == "RightButton" then ok, why = Game.refundActive(App.state, f.heroId, id)
                else ok, why = Game.investActive(App.state, f.heroId, id) end
                if not ok then WIH.Main.notice(why, C.bad) else f.dirty = true end
                UI.screens.heroes.refresh(f)
            end)
            b:SetScript("OnEnter", function(self)
                local hero, h = Heroes.byId[f.heroId], App.state.heroes[f.heroId]
                local def = SkillData.resolve(hero.skills[idx], h and h.form or hero.defaultForm)
                local lv = h and h.active[hero.skills[idx]] or 0
                local lines = { { SkillData.activation(def, math.max(1, lv)), C.dim } }
                if lv > 0 then lines[#lines + 1] = { "현재 " .. lv .. "레벨: " .. SkillData.describe(def, lv), C.text } end
                if lv < 10 then lines[#lines + 1] = { (lv + 1) .. "레벨: " .. SkillData.describe(def, lv + 1), C.sub } end
                lines[#lines + 1] = { "왼쪽 클릭: 포인트 투자 / 오른쪽 클릭: 환급. 포인트로는 5레벨까지.", C.dim }
                UI.showTooltip(self, { title = def.name, lines = lines })
            end)
            b:SetScript("OnLeave", UI.hideTooltip)
            f.actives[idx] = b
            local eq = UI.button(tree, "장착", 38, 16, function()
                local hero, h = Heroes.byId[f.heroId], App.state.heroes[f.heroId]
                local id = hero.skills[idx]
                local bar = {}
                local found = false
                for _, sid in ipairs(h.bar) do
                    if sid == id then found = true else bar[#bar + 1] = sid end
                end
                if not found then bar[#bar + 1] = id end
                local ok, why = Game.setBar(App.state, f.heroId, bar)
                if not ok then WIH.Main.notice(why, C.bad) else f.dirty = true end
                UI.screens.heroes.refresh(f)
            end)
            eq.label:SetFont(STANDARD_TEXT_FONT or "Fonts\\2002.TTF", 10, "")
            eq:SetPoint("TOPLEFT", x + 42, yy - 11)
            f.equips[idx] = eq
            x = x + 86
        end
        for k = 1, 2 do
            local index = row * 2 + k
            local b = UI.button(tree, "", 186, 36, function(_, button)
                local ok, why
                if button == "RightButton" then ok, why = Game.refundPassive(App.state, f.heroId, index)
                else ok, why = Game.investPassive(App.state, f.heroId, index) end
                if not ok then WIH.Main.notice(why, C.bad) else f.dirty = true end
                UI.screens.heroes.refresh(f)
            end)
            b:SetPoint("TOPLEFT", 210 + (k - 1) * 192, yy)
            b.label:ClearAllPoints()
            b.label:SetPoint("LEFT", 8, 0)
            b.label:SetJustifyH("LEFT")
            b.right = UI.text(b, 11, C.sub, "RIGHT")
            b.right:SetPoint("RIGHT", -8, 0)
            b.tooltip = { title = "패시브", lines = { "왼쪽 클릭: 포인트 투자 / 오른쪽 클릭: 환급" } }
            f.passives[index] = b
        end
    end

    -- 장착 스킬 줄
    f.barLabel = UI.text(d, 11, C.dim)
    f.barLabel:SetPoint("TOPLEFT", tree, "BOTTOMLEFT", 0, -10)
    f.barLabel:SetText("장착 스킬(앞에 있을수록 먼저 사용)")
    f.barIcons = {}
    for i = 1, Game.MAX_SKILL_SLOTS do
        local s = UI.icon(d, 34)
        s:SetPoint("TOPLEFT", tree, "BOTTOMLEFT", (i - 1) * 40, -28)
        s.lock = UI.text(s, 10, C.dim, "CENTER")
        s.lock:SetPoint("CENTER")
        f.barIcons[i] = s
    end
    f.apply = UI.button(d, "지금 적용", 96, 26, function()
        f.dirty = false
        App.restartStage()
        UI.screens.heroes.refresh(f)
    end)
    f.apply.tooltip = { title = "지금 적용", lines = { "현재 스테이지를 처음부터 다시 시작해 바꾼 내용을 바로 적용합니다. 누르지 않으면 다음 스테이지부터 적용됩니다." } }
    f.apply:SetPoint("TOPLEFT", tree, "BOTTOMLEFT", 200, -32)
    f.reset = UI.button(d, "트리 초기화", 96, 26, function()
        Game.resetTree(App.state, f.heroId)
        f.dirty = true
        UI.screens.heroes.refresh(f)
    end)
    f.reset:SetPoint("LEFT", f.apply, "RIGHT", 8, 0)
    f.hint = UI.text(d, 11, C.dim)
    f.hint:SetPoint("LEFT", f.reset, "RIGHT", 12, 0)
    return f
end

local function refresh(f)
    local s = App.state
    if not s then return end
    local hero, h = selectedHero(f)
    for id, b in pairs(f.rows) do
        local hs = s.heroes[id]
        b:setText(Heroes.byId[id].name)
        b:setSelected(id == f.heroId)
        b.right:SetText(hs and ("Lv " .. hs.level) or "잠김")
        b.right:SetTextColor(UI.rgb(hs and C.sub or C.dim))
    end
    f.icon:set(UI.CLASS_ICONS[hero.class])
    f.name:SetText(hero.name)
    local form = h and h.form or hero.defaultForm
    local base, range, role = HeroBuild.baseOf(hero, form)
    f.role:SetText(Heroes.ROLES[role] .. "  ·  " .. Heroes.MAIN_WEAPONS[hero.main].name .. " + " .. Heroes.SUB_WEAPONS[hero.sub].name)
    local owned = h ~= nil
    f.unlock:SetShown(not owned)
    f.stats:SetShown(owned)
    f.tree:SetShown(owned)
    f.apply:SetShown(owned); f.reset:SetShown(owned); f.barLabel:SetShown(owned)
    for _, s2 in ipairs(f.barIcons) do s2:SetShown(owned) end
    for name, b in pairs(f.forms) do b:SetShown(owned and hero.forms ~= nil); b:setSelected(form == name) end
    if not owned then
        f.level:SetText("")
        f.points:SetText("")
        f.exp:Hide()
        f.unlock:setText("해금  " .. Game.HERO_UNLOCK_COST .. " G")
        f.unlock:setEnabled(s.gold >= Game.HERO_UNLOCK_COST)
        f.hint:SetText("")
        return
    end
    f.exp:Show()
    local need = Tables.EXP[h.level]
    f.level:SetText("레벨 " .. h.level .. (need and "" or " (최대)"))
    f.exp:set(need and h.exp / need or 1)
    f.points:SetText("남은 스킬 포인트 " .. Game.freePoints(s, f.heroId))

    -- 능력치: 전투와 같은 계산으로 만든 유닛에서 읽는다.
    local sheet = Runes.sheet(s)
    local u = HeroBuild.makeUnit(f.heroId, { form = form, passivePoints = h.passive, account = sheet })
    f.stats:SetText(string.format(
        "체력 %s   방어도 %s   공격력 %s   공격속도 %.2f   치명타 %.1f%%   치명타 피해 %.0f%%\n이동속도 %s   사거리 %d   재사용 감소 %.0f%%   회피 %.0f%%   막기 %.0f%%   피해 감소 %.0f%%",
        UI.number(u:get("MaxHp")), UI.number(u:get("Armor")), SkillData.formatNumber(u:get("AttackDamage")), u:get("AttackSpeed"),
        u:get("CriticalChance") * 100, u:get("CriticalDamage") * 100, UI.number(u:get("MovementSpeed")), range,
        u:get("CooldownReduction") * 100, u:get("DodgeChance") * 100, u:get("BlockChance") * 100, u:get("DamageReduction") * 100))

    local equipped = {}
    for i, id in ipairs(h.bar) do equipped[id] = i end
    for idx, b in pairs(f.actives) do
        local id = hero.skills[idx]
        local def = SkillData.resolve(id, form)
        local lv = h.active[id] or 0
        b.icon:set(def.icon)
        b.lv:SetText(lv > 0 and tostring(lv) or "")
        b.lvbg:SetShown(lv > 0)
        b.icon.tex:SetDesaturated(lv == 0)
        b.icon:SetAlpha(lv > 0 and 1 or 0.55)
        local eq = f.equips[idx]
        eq:SetShown(lv > 0)
        eq:setText(equipped[id] and "해제" or "장착")
        eq:setSelected(equipped[id] ~= nil)
    end
    for index, b in pairs(f.passives) do
        local node = hero.passives[index]
        local pts = h.passive[index] or 0
        b:setText(UI.modText(node.stat, node.kind, node.per))
        b.right:SetText(pts .. "/" .. node.max)
        b.right:SetTextColor(UI.rgb(pts >= node.max and C.good or (pts > 0 and C.text or C.dim)))
        b:setSelected(pts > 0)
    end
    local slots = Game.skillSlots(s)
    for i, icon in ipairs(f.barIcons) do
        local id = h.bar[i]
        if i > slots then
            icon.tex:SetTexture(nil)
            icon.lock:SetText("룬")
            icon:SetAlpha(0.5)
        elseif id then
            icon:set(SkillData.resolve(id, form).icon)
            icon.lock:SetText("")
            icon:SetAlpha(1)
        else
            icon.tex:SetTexture(nil)
            icon.lock:SetText("")
            icon:SetAlpha(1)
        end
    end
    f.hint:SetText(f.dirty and "바꾼 내용은 다음 스테이지부터 적용됩니다." or "")
end

UI.screens.heroes = { label = "영웅", order = 2, create = create, refresh = refresh }
