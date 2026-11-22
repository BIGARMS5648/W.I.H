-- 전투 장면: 사냥 띠 안에서 영웅과 몬스터가 싸우는 모습을 그린다.
-- 엔진의 상태를 읽어 그리기만 한다. 유닛은 3D 모델로 보여 주고, 모델을 쓸 수 없으면 아이콘 표시로 바꾼다.
-- 화면에서의 자리는 엔진의 좌표를 그대로 쓰지 않는다: 영웅은 편성 순서대로 대열을 이뤄 서고(원거리 영웅이 화면 밖으로
-- 나가지 않게), 적은 선두 영웅과의 실제 거리에 비례해 오른쪽에 놓인다.

local _, WIH = ...
local UI = WIH.module("UI")
local App = WIH.module("App")
local Heroes = WIH.module("Heroes")
local Models = WIH.module("Models")
local SkillData = WIH.module("SkillData")
local Scene = WIH.module("Scene")

local C = UI.C
local GROUND = 12               -- 바닥선의 높이(장면 아래에서부터)
local HERO_SPACING = 56         -- 대열에서 영웅 사이의 간격(픽셀)
local FRONT_AT = 0.36           -- 선두 영웅이 서는 가로 위치(장면 폭에 대한 비율)
local VIEW_RANGE = 900          -- 선두 영웅 앞으로 보이는 거리(엔진 단위)
local FACING = 0.95             -- 모델이 옆을 보는 각도(라디안). 영웅은 오른쪽, 적은 왼쪽을 본다

local SIZE = {                  -- 유닛 종류별 {모델 프레임 폭, 높이, 아이콘 표시 크기}
    hero = { 56, 74, 30 }, boss = { 100, 96, 44 }, mob = { 58, 60, 28 }, summon = { 40, 44, 20 },
}
local STATUS_COLORS = {
    Chill = { 0.45, 0.70, 0.95 }, Freeze = { 0.75, 0.90, 1.00 }, Ignite = { 0.95, 0.50, 0.25 },
    Shock = { 0.95, 0.88, 0.40 }, Bleed = { 0.80, 0.25, 0.25 }, Stun = { 0.70, 0.70, 0.72 },
}

-- 표시 설정(창 배치와 함께 저장된다)
function Scene.options()
    WIH_UI = type(WIH_UI) == "table" and WIH_UI or {}
    local o = WIH_UI
    if o.models == nil then o.models = true end
    if type(o.modelLimit) ~= "number" then o.modelLimit = 12 end
    return o
end

local function firstChar(s)
    return (s and s:match("[%z\1-\127\194-\244][\128-\191]*")) or "?"
end

local function kindOf(u)
    if u.kind == "hero" then return "hero" end
    if u.kind == "summon" then return "summon" end
    return u.isBoss and "boss" or "mob"
end

------------------------------------------------------------------------
-- 유닛 하나의 표시
------------------------------------------------------------------------

local function newView(scene)
    local t = CreateFrame("Frame", nil, scene)
    t.view = UI.modelView(t)
    t.view:SetAllPoints()
    -- 아이콘 표시(모델을 쓰지 않을 때)
    t.token = CreateFrame("Frame", nil, t)
    t.token:SetPoint("BOTTOM", 0, 2)
    t.token.bg = UI.fill(t.token, C.raised)
    t.token.bg:SetAllPoints()
    t.token.icon = t.token:CreateTexture(nil, "ARTWORK")
    t.token.icon:SetPoint("TOPLEFT", 1, -1)
    t.token.icon:SetPoint("BOTTOMRIGHT", -1, 1)
    t.token.icon:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    t.token.letter = UI.text(t.token, 12, C.text, "CENTER")
    t.token.letter:SetPoint("CENTER")
    UI.border(t.token)
    t.hp = UI.bar(t, 42, 3, C.good)
    t.hp:SetPoint("BOTTOM", t, "TOP", 0, 2)
    t.marks = {}
    for i = 1, 4 do
        local m = UI.fill(t, C.sub, "OVERLAY")
        m:SetSize(4, 4)
        m:SetPoint("BOTTOMLEFT", t.hp, "TOPLEFT", (i - 1) * 6, 2)
        m:Hide()
        t.marks[i] = m
    end
    t.cast = UI.text(t, 10, C.text, "CENTER")
    t.cast:SetPoint("BOTTOM", t.hp, "TOP", 0, 8)
    t.view.onFail = function() t.useModel = false; t.token:Show() end
    t:EnableMouse(true)
    t:SetScript("OnEnter", function(self)
        local u = self.unit
        if not u then return end
        local lines = { string.format("체력 %s / %s", UI.number(math.max(0, u.hp)), UI.number(u:get("MaxHp"))) }
        local shield = u:shieldTotal()
        if shield > 0 then lines[#lines + 1] = "보호막 " .. UI.number(shield) end
        if u.kind == "hero" and u.heroId and App.state and App.state.heroes[u.heroId] then
            lines[#lines + 1] = { "레벨 " .. App.state.heroes[u.heroId].level, C.dim }
            for _, slot in ipairs(u.skills or {}) do
                local act = slot.def.act
                local state = ""
                if act.type == "cd" and slot.cd then
                    local left = math.max(0, slot.cd - slot.charge)
                    state = left > 0.05 and string.format("  %.1f초", left) or "  준비됨"
                elseif act.type == "count" then
                    state = "  " .. slot.count .. "/" .. act.n
                end
                lines[#lines + 1] = { slot.def.name .. state, C.sub }
            end
        elseif u.def and u.def.skills and u.team == 2 then
            for _, s in ipairs(u.def.skills) do lines[#lines + 1] = { s.name .. ": " .. s.desc, C.sub } end
        end
        UI.showTooltip(self, { title = u.name, lines = lines })
    end)
    t:SetScript("OnLeave", UI.hideTooltip)
    return t
end

-- 유닛에 맞게 모양을 정한다. wantModel이 참이면 3D 모델을 시도한다.
local function style(scene, t, u, wantModel)
    t.unit = u
    local kind = kindOf(u)
    local size = SIZE[kind]
    t.kind = kind
    t:SetSize(size[1], size[2])
    t.token:SetSize(size[3], size[3])
    t.hp:SetWidth(math.min(size[1] - 12, 60))
    t.anim, t.animUntil, t.deadFor, t.lastX = nil, nil, nil, nil
    t:SetAlpha(1)
    -- 아이콘 표시의 내용
    if u.kind == "hero" and u.heroId then
        local hero = Heroes.byId[u.heroId]
        t.token.icon:SetTexture(UI.iconPath(UI.CLASS_ICONS[hero.class]))
        t.token.icon:Show()
        t.token.letter:SetText("")
        t.token.bg:SetColorTexture(UI.rgb(C.raised))
        UI.setBorderColor(t.token, UI.accent())
        t.hp:setColor(C.good)
    else
        t.token.icon:Hide()
        t.token.letter:SetText(firstChar(u.name))
        if u.team == 1 then
            t.token.bg:SetColorTexture(0.16, 0.22, 0.20, 1)
            UI.setBorderColor(t.token, C.good, 0.7)
            t.hp:setColor(C.good)
        else
            local e = UI.ELEMENT_COLORS[u.basicElem] or UI.ELEMENT_COLORS.Physical
            t.token.bg:SetColorTexture(0.20 + e[1] * 0.08, 0.13 + e[2] * 0.06, 0.13 + e[3] * 0.06, 1)
            UI.setBorderColor(t.token, u.isBoss and C.warn or C.bad, u.isBoss and 1 or 0.7)
            t.hp:setColor(C.bad)
        end
    end
    -- 3D 모델
    t.useModel = false
    if wantModel then
        local faction = App.state and App.state.faction or "Alliance"
        local flip = Scene.options().modelFlip and -1 or 1
        local facing = (u.team == 1 and FACING or -FACING) * flip
        if t.view:setCreature(Models.candidates(u, faction), facing, kind == "boss" and 1.05 or 1.15) then
            t.useModel = true
        end
    else
        t.view:clear()
    end
    t.token:SetShown(not t.useModel)
end

local function release(scene, id, t)
    t:Hide()
    t.view:clear()
    t.unit = nil
    scene.views[id] = nil
    scene.free[#scene.free + 1] = t
end

------------------------------------------------------------------------
-- 장면
------------------------------------------------------------------------

function Scene.create(parent)
    local scene = CreateFrame("Frame", nil, parent)
    if scene.SetClipsChildren then scene:SetClipsChildren(true) end
    scene.ground = UI.fill(scene, C.text, "BORDER", 0.10)
    scene.ground:SetPoint("BOTTOMLEFT", 0, GROUND - 2)
    scene.ground:SetPoint("BOTTOMRIGHT", 0, GROUND - 2)
    scene.ground:SetHeight(1)
    scene.views, scene.free = {}, {}
    scene.floats, scene.shots, scene.zones = {}, {}, {}
    scene.pos = {}          -- [유닛 번호] = { x, y }: 이번 프레임의 화면 자리
    for i = 1, 36 do
        local fs = UI.text(scene, 12, C.text, "CENTER")
        fs:Hide()
        scene.floats[i] = { fs = fs, t = 0 }
    end
    for i = 1, 24 do
        local dot = UI.fill(scene, C.text, "OVERLAY")
        dot:SetSize(10, 2)
        dot:Hide()
        scene.shots[i] = { tex = dot, t = 0 }
    end
    for i = 1, 12 do
        local z = UI.fill(scene, C.good, "ARTWORK", 0.2)
        z:Hide()
        scene.zones[i] = z
    end
    scene.banner = UI.text(scene, 15, C.text, "CENTER")
    scene.banner:SetPoint("TOP", 0, -6)
    scene.modelCount = 0
    return scene
end

local function spawnFloat(scene, x, y, text, color, big)
    for i = 1, #scene.floats do
        local fl = scene.floats[i]
        if fl.t <= 0 then
            fl.t, fl.x, fl.y = 0.9, x, y
            fl.fs:SetText(text)
            fl.fs:SetTextColor(color[1], color[2], color[3], 1)
            fl.fs:SetFont(STANDARD_TEXT_FONT or "Fonts\\2002.TTF", big and 16 or 11, "OUTLINE")
            fl.fs:Show()
            return
        end
    end
end

local function spawnShot(scene, x0, y0, x1, y1, color)
    for i = 1, #scene.shots do
        local s = scene.shots[i]
        if s.t <= 0 then
            s.t, s.dur, s.x0, s.y0, s.x1, s.y1 = 0.18, 0.18, x0, y0, x1, y1
            s.tex:SetColorTexture(color[1], color[2], color[3], 1)
            s.tex:Show()
            return
        end
    end
end

local function playAnim(t, id, seconds)
    if not t or not t.useModel then return end
    t.view:setAnim(id)
    t.anim, t.animUntil = id, seconds
end

-- 전투 이벤트 → 시각 표현
function Scene.onBattleEvent(scene, ev, a, b, c, d, e)
    local pos = scene.pos
    if ev == "damage" then
        local dst, dmg, elem, crit = b, c, d, e
        local p = dst and pos[dst.id]
        if p and dmg and dmg >= 1 then
            local col = UI.ELEMENT_COLORS[elem] or C.text
            if dst.team == 1 then col = C.bad end
            spawnFloat(scene, p.x + ((dst.id * 7) % 16) - 8, p.top + 6, UI.number(dmg), col, crit)
        end
    elseif ev == "heal" then
        local p = b and pos[b.id]
        if p and c and c >= 1 then spawnFloat(scene, p.x, p.top + 12, "+" .. UI.number(c), C.good) end
    elseif ev == "dodge" then
        local p = b and pos[b.id]
        if p then spawnFloat(scene, p.x, p.top + 6, "회피", C.sub) end
    elseif ev == "attack" then
        local src, dst = a, b
        local pa, pb = src and pos[src.id], dst and pos[dst.id]
        if pa and pb then
            if src.basicDelivery == "proj" then
                spawnShot(scene, pa.x, pa.mid, pb.x, pb.mid, UI.ELEMENT_COLORS[src.basicElem] or C.text)
            else
                scene.lunge[src.id] = 0.14
            end
        end
        playAnim(src and scene.views[src.id], UI.ANIM.attack, 0.55)
    elseif ev == "cast" then
        local t = a and scene.views[a.id]
        if t and b then
            t.cast:SetText(b.name or "")
            t.castT = 1.0
            playAnim(t, UI.ANIM.cast, 0.8)
        end
    elseif ev == "death" then
        local t = a and scene.views[a.id]
        if t then
            t.deadFor = 0
            if t.useModel then t.view:setAnim(UI.ANIM.death) end
        end
    elseif ev == "revive" then
        local p = a and pos[a.id]
        if p then spawnFloat(scene, p.x, p.top + 12, "부활", C.good, true) end
        local t = a and scene.views[a.id]
        if t then t.deadFor = nil; if t.useModel then t.view:setAnim(UI.ANIM.stand) end; t:SetAlpha(1) end
    elseif ev == "cheatDeath" then
        local p = a and pos[a.id]
        if p then spawnFloat(scene, p.x, p.top + 12, "버팀", C.warn, true) end
    end
end

function Scene.banner(scene, text, color)
    scene.banner:SetText(text)
    scene.banner:SetTextColor(UI.rgb(color or C.text))
    scene.bannerT = 2.2
end

function Scene.update(scene, elapsed)
    local runner = App.session and App.session.runner
    local battle = runner and runner.battle
    if not battle then return end
    local units = battle.units
    local opts = Scene.options()
    scene.lunge = scene.lunge or {}

    -- 전투가 새로 만들어지면(스테이지가 바뀌면) 유닛 번호가 다시 1부터 시작한다. 이전 표시를 모두 거둔다.
    if scene.battle ~= battle or scene.optModels ~= opts.models or scene.optFlip ~= opts.modelFlip then
        scene.battle, scene.optModels, scene.optFlip = battle, opts.models, opts.modelFlip
        for id, t in pairs(scene.views) do release(scene, id, t) end
        for id in pairs(scene.lunge) do scene.lunge[id] = nil end
        for id in pairs(scene.pos) do scene.pos[id] = nil end
        scene.modelCount = 0
    end

    local w, h = scene:GetWidth(), scene:GetHeight()
    if not w or w <= 0 then w = 1000 end
    if not h or h <= 0 then h = 100 end
    local frontX = w * FRONT_AT
    local scale = (w - frontX - 70) / VIEW_RANGE

    -- 선두(가장 앞에 있는 살아 있는 영웅)의 엔진 좌표
    local lead
    for i = 1, #units do
        local u = units[i]
        if u.kind == "hero" and u.alive and (not lead or u.x > lead) then lead = u.x end
    end
    if not lead then lead = scene.lastLead or 0 end
    local moving = scene.lastLead ~= nil and math.abs(lead - scene.lastLead) > 0.01
    scene.lastLead = lead

    local seen = {}
    local pos = scene.pos
    for i = 1, #units do
        local u = units[i]
        -- 화면에서의 자리
        local x, lane
        if u.kind == "hero" then
            x = frontX - ((u.rank or 1) - 1) * HERO_SPACING
            lane = ((u.rank or 1) % 2) * 5
        elseif u.team == 1 then
            local owner = u.owner
            local op = owner and pos[owner.id]
            x = (op and op.x or frontX) + 30 + (u.id % 3) * 10
            lane = 10
        else
            local d = u.x - lead
            if d < 40 then d = 40 end
            x = frontX + 14 + d * scale
            lane = (u.id % 3) * 5
        end
        local visible = x > -40 and x < w + 40
        local t = scene.views[u.id]
        if visible then
            if not t then
                t = table.remove(scene.free) or newView(scene)
                scene.views[u.id] = t
                t.castT = 0
                t.cast:SetText("")
            end
            if t.unit ~= u then
                -- 영웅과 보스가 먼저 모델을 받고, 남는 수만큼 다른 유닛이 받는다.
                local want = opts.models and (u.kind == "hero" or u.isBoss or scene.modelCount < opts.modelLimit)
                style(scene, t, u, want)
                if t.useModel then scene.modelCount = scene.modelCount + 1 end
            end
            seen[u.id] = true
            local lunge = scene.lunge[u.id]
            if lunge then
                lunge = lunge - elapsed
                scene.lunge[u.id] = lunge > 0 and lunge or nil
                x = x + (u.team == 1 and 6 or -6)
            end
            local size = SIZE[t.kind]
            local y = GROUND + lane
            local p = pos[u.id]
            if not p then p = {}; pos[u.id] = p end
            p.x, p.top, p.mid = x, y + size[2], y + size[2] * 0.55
            t:ClearAllPoints()
            t:SetPoint("BOTTOM", scene, "BOTTOMLEFT", x, y)
            t:SetFrameLevel(scene:GetFrameLevel() + 2 + (10 - lane))
            if t.useModel then t.view:update(elapsed) end

            if u.alive then
                t:SetAlpha(u.noTarget and 0.45 or 1)
                local maxHp = u:get("MaxHp")
                t.hp:set(maxHp > 0 and u.hp / maxHp or 0, maxHp > 0 and u:shieldTotal() / maxHp or 0)
                t.hp:Show()
                -- 동작: 공격·시전이 끝나면 달리기 또는 서 있기로 돌아간다.
                if t.useModel then
                    if t.animUntil then
                        t.animUntil = t.animUntil - elapsed
                        if t.animUntil <= 0 then t.animUntil = nil end
                    end
                    if not t.animUntil then
                        local run = (u.kind == "hero" and moving) or (u.team == 2 and t.lastX ~= nil and math.abs(u.x - t.lastX) > 0.01)
                        t.view:setAnim(run and UI.ANIM.run or UI.ANIM.stand)
                    end
                end
            else
                t.hp:Hide()
                t.deadFor = (t.deadFor or 0) + elapsed
                -- 쓰러지는 동작이 되풀이되지 않게, 끝난 뒤에는 쓰러져 있는 자세로 둔다.
                if t.useModel and t.deadFor > 1.0 then t.view:setAnim(UI.ANIM.dead) end
                -- 쓰러지는 동작이 끝난 뒤 서서히 옅어진다. 영웅은 부활을 기다리므로 남겨 둔다.
                local fade = u.kind == "hero" and 0.4 or math.max(0, 1 - math.max(0, t.deadFor - 0.8) * 1.5)
                t:SetAlpha(t.useModel and math.max(fade, u.kind == "hero" and 0.4 or 0) or 0.28)
            end
            t.lastX = u.x

            local n = 0
            for j = 1, #u.effects do
                local eff = u.effects[j]
                if eff.status and n < 4 then
                    n = n + 1
                    local col = STATUS_COLORS[eff.status] or C.sub
                    t.marks[n]:SetColorTexture(col[1], col[2], col[3], 1)
                    t.marks[n]:Show()
                end
            end
            for j = n + 1, 4 do t.marks[j]:Hide() end
            if t.castT and t.castT > 0 then
                t.castT = t.castT - elapsed
                if t.castT <= 0 then t.cast:SetText("") end
            end
            t:Show()
        elseif t then
            if t.useModel then scene.modelCount = math.max(0, scene.modelCount - 1) end
            release(scene, u.id, t)
            pos[u.id] = nil
        end
    end
    for id, t in pairs(scene.views) do
        if not seen[id] then
            if t.useModel then scene.modelCount = math.max(0, scene.modelCount - 1) end
            release(scene, id, t)
            pos[id] = nil
        end
    end

    -- 지면 영역
    local zi = 0
    for i = 1, #battle.zones do
        local z = battle.zones[i]
        if not z.isDrone and not z.isChannel and zi < #scene.zones then
            local d = z.x - lead
            local cx
            if d >= 0 then cx = frontX + 14 + d * scale else cx = frontX + math.max(d * 0.06, -4 * HERO_SPACING) end
            local half = math.max(6, z.radius * scale)
            if cx + half > 0 and cx - half < w then
                zi = zi + 1
                local tex = scene.zones[zi]
                local col = z.team == 1 and C.good or C.bad
                tex:SetColorTexture(col[1], col[2], col[3], z.isTrap and 0.5 or 0.28)
                tex:ClearAllPoints()
                tex:SetSize(z.isTrap and 8 or half * 2, z.isTrap and 6 or 5)
                tex:SetPoint("BOTTOM", scene, "BOTTOMLEFT", cx, GROUND - 2)
                tex:Show()
            end
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
                fl.y = fl.y + elapsed * 26
                fl.fs:ClearAllPoints()
                fl.fs:SetPoint("CENTER", scene, "BOTTOMLEFT", fl.x, math.min(fl.y, h - 8))
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

return Scene
