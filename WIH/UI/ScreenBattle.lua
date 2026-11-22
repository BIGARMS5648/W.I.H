-- 전투 화면: 전투 장면(유닛 위치, 체력, 상태 이상, 피해·회복 숫자, 투사체, 영역), 파티 상태, 진행 기록.
-- 화면은 엔진의 상태를 읽어 그리기만 한다. 창이 닫혀 있으면 아무것도 그리지 않는다.
-- 유닛은 아이콘 토큰으로 표시한다. 내장 3D 모델 표시는 게임 내 확인(모델이 보이는지, 동작, 부하)이 끝난 뒤에 붙인다.

local _, WIH = ...
local UI = WIH.module("UI")
local App = WIH.module("App")
local Heroes = WIH.module("Heroes")
local Tables = WIH.module("Tables")
local Dungeons = WIH.module("Dungeons")
local SkillData = WIH.module("SkillData")

local C = UI.C
local SCENE_H = 250
local WORLD_SPAN = 1500         -- 장면에 보이는 전장의 폭(거리 단위)
local LANES = 5

local STATUS_COLORS = {
    Chill = { 0.45, 0.70, 0.95 }, Freeze = { 0.75, 0.90, 1.00 }, Ignite = { 0.95, 0.50, 0.25 },
    Shock = { 0.95, 0.88, 0.40 }, Bleed = { 0.80, 0.25, 0.25 }, Stun = { 0.70, 0.70, 0.72 },
}

local function firstChar(s)
    return (s and s:match("[%z\1-\127\194-\244][\128-\191]*")) or "?"
end

------------------------------------------------------------------------
-- 장면
------------------------------------------------------------------------

local function newToken(scene)
    local t = CreateFrame("Frame", nil, scene)
    t:SetSize(30, 30)
    t.bg = UI.fill(t, C.raised)
    t.bg:SetAllPoints()
    t.icon = t:CreateTexture(nil, "ARTWORK")
    t.icon:SetPoint("TOPLEFT", 1, -1)
    t.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    t.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    t.letter = UI.text(t, 13, C.text, "CENTER")
    t.letter:SetPoint("CENTER")
    UI.border(t)
    t.hp = UI.bar(t, 30, 4, C.good)
    t.hp:SetPoint("TOP", t, "BOTTOM", 0, -2)
    t.marks = {}
    for i = 1, 4 do
        local m = UI.fill(t, C.sub, "OVERLAY")
        m:SetSize(5, 5)
        m:SetPoint("BOTTOMLEFT", t, "TOPLEFT", (i - 1) * 7, 2)
        m:Hide()
        t.marks[i] = m
    end
    t.cast = UI.text(t, 10, C.text, "CENTER")
    t.cast:SetPoint("BOTTOM", t, "TOP", 0, 9)
    t:EnableMouse(true)
    t:SetScript("OnEnter", function(self)
        local u = self.unit
        if not u then return end
        local lines = { string.format("체력 %s / %s", UI.number(math.max(0, u.hp)), UI.number(u:get("MaxHp"))) }
        local shield = u:shieldTotal()
        if shield > 0 then lines[#lines + 1] = "보호막 " .. UI.number(shield) end
        if u.def and u.def.skills and u.team == 2 then
            for _, s in ipairs(u.def.skills) do lines[#lines + 1] = { s.name .. ": " .. s.desc, C.sub } end
        end
        UI.showTooltip(self, { title = u.name, lines = lines })
    end)
    t:SetScript("OnLeave", UI.hideTooltip)
    return t
end

local function styleToken(t, u)
    t.unit = u
    t.styledFor = u.id
    local size = 30
    if u.isBoss then size = 46 elseif u.kind == "summon" then size = 22 end
    t:SetSize(size, size)
    t.hp:SetWidth(size)
    if u.kind == "hero" then
        local hero = Heroes.byId[u.heroId]
        t.icon:SetTexture(UI.iconPath(UI.CLASS_ICONS[hero.class]))
        t.icon:Show()
        t.letter:SetText("")
        UI.setBorderColor(t, UI.accent())
        t.hp:setColor(C.good)
    else
        t.icon:Hide()
        t.letter:SetText(firstChar(u.name))
        if u.team == 1 then
            t.bg:SetColorTexture(0.16, 0.22, 0.20, 1)
            UI.setBorderColor(t, C.good, 0.7)
            t.hp:setColor(C.good)
        else
            local e = UI.ELEMENT_COLORS[u.basicElem] or UI.ELEMENT_COLORS.Physical
            t.bg:SetColorTexture(0.20 + e[1] * 0.08, 0.13 + e[2] * 0.06, 0.13 + e[3] * 0.06, 1)
            UI.setBorderColor(t, u.isBoss and C.warn or C.bad, u.isBoss and 1 or 0.7)
            t.hp:setColor(C.bad)
        end
    end
end

local function createScene(parent)
    local scene = UI.panel(parent, C.panel, true)
    if scene.SetClipsChildren then scene:SetClipsChildren(true) end
    scene.ground = UI.fill(scene, C.line, "BORDER", 0.6)
    scene.ground:SetPoint("BOTTOMLEFT", 0, 26)
    scene.ground:SetPoint("BOTTOMRIGHT", 0, 26)
    scene.ground:SetHeight(1)
    scene.tokens, scene.free = {}, {}
    scene.floats, scene.shots, scene.zones = {}, {}, {}
    scene.camX = 0
    scene.lunge = {}
    for i = 1, 36 do
        local fs = UI.text(scene, 12, C.text, "CENTER")
        fs:Hide()
        scene.floats[i] = { fs = fs, t = 0 }
    end
    for i = 1, 24 do
        local dot = UI.fill(scene, C.text, "OVERLAY")
        dot:SetSize(5, 5)
        dot:Hide()
        scene.shots[i] = { tex = dot, t = 0 }
    end
    for i = 1, 12 do
        local z = UI.fill(scene, C.good, "ARTWORK", 0.12)
        z:Hide()
        scene.zones[i] = z
    end
    scene.banner = UI.text(scene, 16, C.text, "CENTER")
    scene.banner:SetPoint("TOP", 0, -14)
    return scene
end

local function sceneXY(scene, u, lane)
    local w = scene:GetWidth()
    if not w or w <= 0 then w = 800 end
    local x = w * 0.32 + (u.x - scene.camX) * (w / WORLD_SPAN)
    local y = 36 + lane * ((SCENE_H - 90) / (LANES - 1))
    return x, y
end

local function laneOf(u)
    if u.kind == "hero" then return (u.rank - 1) % LANES end
    if u.kind == "summon" and u.owner then
        if u.owner.kind == "hero" then return ((u.owner.rank - 1) + 0.45) % LANES end
        return (u.owner.id % LANES)
    end
    return u.id % LANES
end

local function spawnFloat(scene, x, y, text, color, big)
    for i = 1, #scene.floats do
        local fl = scene.floats[i]
        if fl.t <= 0 then
            fl.t, fl.x, fl.y = 0.9, x, y
            fl.fs:SetText(text)
            fl.fs:SetTextColor(color[1], color[2], color[3], 1)
            local font = STANDARD_TEXT_FONT or "Fonts\\2002.TTF"
            fl.fs:SetFont(font, big and 15 or 11, "OUTLINE")
            fl.fs:Show()
            return
        end
    end
end

local function spawnShot(scene, x0, y0, x1, y1, color)
    for i = 1, #scene.shots do
        local s = scene.shots[i]
        if s.t <= 0 then
            s.t, s.dur, s.x0, s.y0, s.x1, s.y1 = 0.16, 0.16, x0, y0, x1, y1
            s.tex:SetColorTexture(color[1], color[2], color[3], 1)
            s.tex:Show()
            return
        end
    end
end

-- 전투 이벤트 → 시각 표현
local function onBattleEvent(scene, ev, a, b, c, d, e)
    if ev == "damage" then
        local dst, dmg, elem, crit = b, c, d, e
        local tok = dst and scene.tokens[dst.id]
        if tok and tok.sx and dmg and dmg >= 1 then
            local col = UI.ELEMENT_COLORS[elem] or C.text
            spawnFloat(scene, tok.sx + ((dst.id * 7) % 16) - 8, tok.sy + 22, UI.number(dmg), col, crit)
        end
    elseif ev == "heal" then
        local tok = b and scene.tokens[b.id]
        if tok and tok.sx and c and c >= 1 then spawnFloat(scene, tok.sx, tok.sy + 30, "+" .. UI.number(c), C.good) end
    elseif ev == "dodge" then
        local tok = b and scene.tokens[b.id]
        if tok and tok.sx then spawnFloat(scene, tok.sx, tok.sy + 22, "회피", C.sub) end
    elseif ev == "attack" then
        local src, dst = a, b
        local ta, tb = src and scene.tokens[src.id], dst and scene.tokens[dst.id]
        if ta and tb and ta.sx and tb.sx then
            if src.basicDelivery == "proj" then
                spawnShot(scene, ta.sx, ta.sy, tb.sx, tb.sy, UI.ELEMENT_COLORS[src.basicElem] or C.text)
            else
                scene.lunge[src.id] = 0.14
            end
        end
    elseif ev == "cast" then
        local tok = a and scene.tokens[a.id]
        if tok and b then
            tok.cast:SetText(b.name or "")
            tok.castT = 1.0
        end
    elseif ev == "revive" then
        local tok = a and scene.tokens[a.id]
        if tok and tok.sx then spawnFloat(scene, tok.sx, tok.sy + 30, "부활", C.good, true) end
    elseif ev == "cheatDeath" then
        local tok = a and scene.tokens[a.id]
        if tok and tok.sx then spawnFloat(scene, tok.sx, tok.sy + 30, "버팀", C.warn, true) end
    end
end

local function updateScene(scene, elapsed)
    local runner = App.session and App.session.runner
    local battle = runner and runner.battle
    if not battle then return end
    local units = battle.units

    -- 스테이지가 바뀌면 전투가 새로 만들어지고 유닛 번호가 1부터 다시 시작한다. 이전 전투의 표시를 모두 거둔다.
    if scene.battle ~= battle then
        scene.battle = battle
        for id, tok in pairs(scene.tokens) do
            tok:Hide()
            tok.unit, tok.styledFor = nil, nil
            scene.tokens[id] = nil
            scene.free[#scene.free + 1] = tok
        end
        for id in pairs(scene.lunge) do scene.lunge[id] = nil end
        scene.camX = 0
    end

    -- 시점: 살아 있는 영웅 중 가장 앞의 위치를 부드럽게 따라간다.
    local front
    for i = 1, #units do
        local u = units[i]
        if u.kind == "hero" and u.alive and (not front or u.x > front) then front = u.x end
    end
    if front then
        local diff = front - scene.camX
        if math.abs(diff) > 2000 then scene.camX = front else scene.camX = scene.camX + diff * math.min(1, elapsed * 6) end
    end

    local seen = {}
    for i = 1, #units do
        local u = units[i]
        local tok = scene.tokens[u.id]
        if not tok then
            tok = table.remove(scene.free) or newToken(scene)
            scene.tokens[u.id] = tok
            tok.castT = 0
            tok.cast:SetText("")
        end
        if tok.unit ~= u then styleToken(tok, u) end
        seen[u.id] = true
        local x, y = sceneXY(scene, u, laneOf(u))
        local lunge = scene.lunge[u.id]
        if lunge then
            lunge = lunge - elapsed
            scene.lunge[u.id] = lunge > 0 and lunge or nil
            x = x + (u.team == 1 and 7 or -7)
        end
        tok.sx, tok.sy = x, y
        tok:ClearAllPoints()
        tok:SetPoint("CENTER", scene, "BOTTOMLEFT", x, y)
        if u.alive then
            tok:SetAlpha(u.noTarget and 0.45 or 1)
            local maxHp = u:get("MaxHp")
            tok.hp:set(maxHp > 0 and u.hp / maxHp or 0, maxHp > 0 and u:shieldTotal() / maxHp or 0)
            tok.hp:Show()
        else
            tok:SetAlpha(0.28)
            tok.hp:Hide()
        end
        -- 상태 이상 표시
        local n = 0
        for j = 1, #u.effects do
            local eff = u.effects[j]
            if eff.status and n < 4 then
                n = n + 1
                local col = STATUS_COLORS[eff.status] or C.sub
                tok.marks[n]:SetColorTexture(col[1], col[2], col[3], 1)
                tok.marks[n]:Show()
            end
        end
        for j = n + 1, 4 do tok.marks[j]:Hide() end
        if tok.castT and tok.castT > 0 then
            tok.castT = tok.castT - elapsed
            if tok.castT <= 0 then tok.cast:SetText("") end
        end
        tok:Show()
    end
    for id, tok in pairs(scene.tokens) do
        if not seen[id] then
            tok:Hide()
            tok.unit, tok.styledFor = nil, nil
            scene.tokens[id] = nil
            scene.free[#scene.free + 1] = tok
        end
    end

    -- 지면 영역
    local zi = 0
    local w = scene:GetWidth()
    for i = 1, #battle.zones do
        local z = battle.zones[i]
        if not z.hidden and not z.isDrone and not z.isChannel and zi < #scene.zones then
            zi = zi + 1
            local tex = scene.zones[zi]
            local cx = w * 0.32 + (z.x - scene.camX) * (w / WORLD_SPAN)
            local half = math.max(6, z.radius * (w / WORLD_SPAN))
            local col = z.team == 1 and C.good or C.bad
            tex:SetColorTexture(col[1], col[2], col[3], z.isTrap and 0.35 or 0.12)
            tex:ClearAllPoints()
            if z.isTrap then
                tex:SetSize(8, 8)
                tex:SetPoint("CENTER", scene, "BOTTOMLEFT", cx, 30)
            else
                tex:SetSize(half * 2, SCENE_H - 60)
                tex:SetPoint("BOTTOM", scene, "BOTTOMLEFT", cx, 27)
            end
            tex:Show()
        end
    end
    for i = zi + 1, #scene.zones do scene.zones[i]:Hide() end

    -- 떠오르는 숫자와 투사체
    for i = 1, #scene.floats do
        local fl = scene.floats[i]
        if fl.t > 0 then
            fl.t = fl.t - elapsed
            if fl.t <= 0 then
                fl.fs:Hide()
            else
                fl.y = fl.y + elapsed * 34
                fl.fs:ClearAllPoints()
                fl.fs:SetPoint("CENTER", scene, "BOTTOMLEFT", fl.x, fl.y)
                fl.fs:SetAlpha(math.min(1, fl.t * 2.2))
            end
        end
    end
    for i = 1, #scene.shots do
        local s = scene.shots[i]
        if s.t > 0 then
            s.t = s.t - elapsed
            if s.t <= 0 then
                s.tex:Hide()
            else
                local k = 1 - s.t / s.dur
                s.tex:ClearAllPoints()
                s.tex:SetPoint("CENTER", scene, "BOTTOMLEFT", s.x0 + (s.x1 - s.x0) * k, s.y0 + (s.y1 - s.y0) * k)
            end
        end
    end
    if scene.bannerT and scene.bannerT > 0 then
        scene.bannerT = scene.bannerT - elapsed
        if scene.bannerT <= 0 then scene.banner:SetText("") end
    end
end

local function banner(scene, text, color)
    scene.banner:SetText(text)
    scene.banner:SetTextColor(UI.rgb(color or C.text))
    scene.bannerT = 2.2
end

------------------------------------------------------------------------
-- 파티 카드
------------------------------------------------------------------------

local function newCard(parent)
    local card = UI.panel(parent, C.panel, true)
    card:SetSize(160, 132)
    card.icon = UI.icon(card, 30)
    card.icon:SetPoint("TOPLEFT", 8, -8)
    card.name = UI.text(card, 12, C.text)
    card.name:SetPoint("TOPLEFT", 46, -8)
    card.name:SetPoint("TOPRIGHT", -6, -8)
    card.level = UI.text(card, 11, C.sub)
    card.level:SetPoint("TOPLEFT", card.name, "BOTTOMLEFT", 0, -4)
    card.hp = UI.bar(card, 144, 9, C.good)
    card.hp:SetPoint("TOPLEFT", 8, -46)
    card.hpText = UI.text(card, 10, C.sub)
    card.hpText:SetPoint("TOPLEFT", card.hp, "BOTTOMLEFT", 0, -3)
    card.exp = UI.bar(card, 144, 3, C.exp)
    card.exp:SetPoint("TOPLEFT", 8, -74)
    card.skills = {}
    for i = 1, 4 do
        local s = UI.icon(card, 30)
        s:SetPoint("TOPLEFT", 8 + (i - 1) * 37, -84)
        s.shade = UI.fill(s, C.bg, "OVERLAY", 0.72)
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
    if card.heroId ~= u.heroId or card.unit ~= u then
        card.heroId, card.unit = u.heroId, u
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
            local act = slot.def.act
            if act.type == "cd" then
                local ratio = 1 - math.min(1, slot.charge / slot.cd)
                s.shade:SetHeight(math.max(1, 28 * ratio))
                s.shade:SetShown(ratio > 0.02)
                s.count:SetText("")
            elseif act.type == "count" then
                s.shade:Hide()
                s.count:SetText(slot.count .. "/" .. act.n)
            else
                s.shade:Hide()
                s.count:SetText("")
            end
        end
    end
end

------------------------------------------------------------------------
-- 화면
------------------------------------------------------------------------

-- 스테이지 키 → 이름(던전 또는 레이드)
local function stageName(key)
    local n = key % 1000
    if n % 100 == 10 then
        local raid = WIH.Raids.byAct[math.floor(n / 100)]
        return raid and (raid.name .. " 레이드") or ""
    end
    return Dungeons.sections[n] and Dungeons.sections[n].name or ""
end

local function create(parent)
    local f = CreateFrame("Frame", nil, parent)
    f.scene = createScene(f)
    f.scene:SetPoint("TOPLEFT", 10, -10)
    f.scene:SetPoint("TOPRIGHT", -10, -10)
    f.scene:SetHeight(SCENE_H)

    -- 진행 줄
    f.wave = UI.text(f, 12, C.sub)
    f.wave:SetPoint("TOPLEFT", f.scene, "BOTTOMLEFT", 2, -10)
    f.bossBar = UI.bar(f, 260, 10, C.bad)
    f.bossBar:SetPoint("LEFT", f.wave, "RIGHT", 16, 0)
    f.bossName = UI.text(f, 11, C.warn)
    f.bossName:SetPoint("LEFT", f.bossBar, "RIGHT", 8, 0)

    local function toggle(label, key, tip)
        local b = UI.button(f, label, 96, 22, function(self)
            local s = App.state
            if not s then return end
            s.settings[key] = not s.settings[key]
            self:setSelected(s.settings[key])
        end)
        b.tooltip = { title = label, lines = { tip } }
        b.key = key
        return b
    end
    f.tRetry = toggle("실패 시 재시도", "autoRetry", "전멸하면 같은 스테이지를 다시 합니다. 끄면 이전 스테이지로 내려갑니다.")
    f.tRetry:SetPoint("TOPRIGHT", f.scene, "BOTTOMRIGHT", 0, -6)
    f.tRepeat = toggle("반복", "repeatMode", "클리어해도 다음 스테이지로 넘어가지 않고 같은 스테이지를 반복합니다.")
    f.tRepeat:SetPoint("RIGHT", f.tRetry, "LEFT", -6, 0)
    f.tAdvance = toggle("자동 진행", "autoAdvance", "클리어하면 다음 스테이지로 넘어갑니다.")
    f.tAdvance:SetPoint("RIGHT", f.tRepeat, "LEFT", -6, 0)

    -- 파티 카드
    f.cards = {}
    for i = 1, 5 do
        local card = newCard(f)
        card:SetPoint("TOPLEFT", f.scene, "BOTTOMLEFT", (i - 1) * 166, -40)
        f.cards[i] = card
    end

    -- 기록
    f.logPanel = UI.panel(f, C.panel, true)
    f.logPanel:SetPoint("TOPLEFT", f.scene, "BOTTOMLEFT", 0, -180)
    f.logPanel:SetPoint("BOTTOMRIGHT", -10, 10)
    f.log = UI.paragraph(f.logPanel, 11, C.sub)
    f.log:SetPoint("TOPLEFT", 10, -8)
    f.log:SetPoint("BOTTOMRIGHT", -10, 8)
    f.log:SetJustifyV("BOTTOM")
    f.lines = {}
    f.acc = 0

    f.listener = function(ev, a, b, c, d, e, g)
        if ev == "battle" then
            onBattleEvent(f.scene, a, b, c, d, e, g)
            return
        end
        local line
        if ev == "boss" and a then
            line = "보스 등장: " .. a.name
            banner(f.scene, a.name, C.warn)
        elseif ev == "clear" then
            line = "|cff70b880클리어|r  " .. stageName(a)
            banner(f.scene, "클리어", C.good)
        elseif ev == "fail" then
            line = "|cffd06058전멸|r  " .. stageName(a)
            banner(f.scene, "전멸", C.bad)
        elseif ev == "token" then
            line = "|cffd9b05e" .. WIH.Raids.TOKEN_NAME .. "|r 1개를 얻었습니다. 스테이지 화면에서 레이드에 도전할 수 있습니다."
        elseif ev == "raidClear" then
            line = "|cffd9b05e레이드 클리어|r  레이드 상자를 " .. (b == "opened" and ("바로 열었습니다: " .. UI.lootText(c)) or "받았습니다.")
        elseif ev == "levelUp" then
            line = Heroes.byId[a].name .. " 레벨 " .. b
        elseif ev == "firstClear" then
            local names = {}
            for _, item in ipairs(a) do names[#names + 1] = WIH.Items.name(item) end
            line = "|cffd9b05e첫 클리어 보상|r  " .. table.concat(names, ", ") .. "  (가방 화면에서 장착하세요)"
        elseif ev == "chest" then
            line = WIH.Chests.NAMES[a] .. "를 얻었습니다."
        elseif ev == "loot" then
            line = WIH.Chests.NAMES[a] .. " 자동 개봉: " .. UI.lootText(b)
        elseif ev == "raidUnlocked" then
            local act = math.floor(a % 1000 / 100)
            line = "이 액트의 던전을 모두 돌파했습니다. 다음으로 가려면 스테이지 화면에서 |cffd9b05e" .. WIH.Raids.byAct[act].name .. "|r 레이드를 클리어해야 합니다."
        end
        if line then
            f.lines[#f.lines + 1] = line
            while #f.lines > 7 do table.remove(f.lines, 1) end
            f.log:SetText(table.concat(f.lines, "\n"))
        end
    end
    return f
end

local function refresh(f)
    local s = App.state
    if not s then return end
    f.tRetry:setSelected(s.settings.autoRetry)
    f.tRepeat:setSelected(s.settings.repeatMode)
    f.tAdvance:setSelected(s.settings.autoAdvance)
end

local function update(f, elapsed)
    local session = App.session
    if not session then return end
    updateScene(f.scene, elapsed)
    f.acc = f.acc + elapsed
    if f.acc < 0.1 then return end
    f.acc = 0
    local runner = session.runner
    if not runner then return end
    if runner.phase == "boss" and runner.boss then
        local boss = runner.boss
        f.wave:SetText(runner.raid and ("보스 " .. runner.wave .. " / " .. runner.waves) or "보스")
        f.bossBar:Show()
        f.bossBar:set(boss.alive and boss.hp / boss:get("MaxHp") or 0)
        f.bossName:SetText(boss.name)
    else
        f.wave:SetText(runner.raid and ("보스 " .. runner.wave .. " / " .. runner.waves) or ("웨이브 " .. runner.wave .. " / " .. runner.waves))
        f.bossBar:Hide()
        f.bossName:SetText("")
    end
    for i = 1, 5 do
        local u = runner.heroes[i]
        local card = f.cards[i]
        if u then
            card:Show()
            updateCard(card, u, App.state.heroes[u.heroId])
        else
            card:Hide()
        end
    end
end

local function onHide(f)
    if f.watching then
        f.watching:removeListener(f.listener)
        f.watching:watchBattle(false)
        f.watching = nil
    end
end

local function onShow(f)
    onHide(f)        -- 같은 화면을 다시 열거나 진행 세션이 바뀐 경우에 중복 등록을 막는다
    if App.session then
        App.session:addListener(f.listener)
        App.session:watchBattle(true)
        f.watching = App.session
    end
end

UI.screens.battle = { label = "전투", order = 1, create = create, refresh = refresh, update = update, onShow = onShow, onHide = onHide }
