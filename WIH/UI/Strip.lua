-- 사냥 띠: 늘 떠 있는 가로 띠. 전투 장면과 현재 스테이지·재화를 보여 준다. 메뉴 창과는 별개의 창이다.
-- 위쪽 줄을 끌어 옮기고, 오른쪽 아래 손잡이로 폭을 조절하며, "접기"로 한 줄만 남길 수 있다.

local _, WIH = ...
local UI = WIH.module("UI")
local App = WIH.module("App")
local Game = WIH.module("Game")
local Tables = WIH.module("Tables")
local Dungeons = WIH.module("Dungeons")
local Chests = WIH.module("Chests")
local Scene = WIH.module("Scene")
local Strip = WIH.module("Strip")

local C = UI.C
local HEAD, FOOT, FULL_H = 28, 20, 172
local MIN_W, DEF_W, MAX_W = 700, 1180, 2400
local MAX_PIPS = 16

local frame, scene, pill, nameText, waveText, pips, progress, goldText, chestText, bossBar, bossName
local footToggles, dpsText, lootText, collapseBtn
local watching

local function saved()
    WIH_UI = type(WIH_UI) == "table" and WIH_UI or {}
    if type(WIH_UI.strip) ~= "table" then WIH_UI.strip = {} end
    return WIH_UI.strip
end

local function savePlace()
    local s = saved()
    s.w = frame:GetWidth()
    s.x, s.y = frame:GetLeft(), frame:GetBottom()
end

-- 전투 중계는 띠가 펼쳐져 보일 때만 켠다.
local function attach()
    local session = App.session
    local want = session ~= nil and frame ~= nil and frame:IsShown() and not saved().collapsed
    if watching and (watching ~= session or not want) then
        watching:removeListener(Strip.listener)
        watching:watchBattle(false)
        watching = nil
    end
    if want and not watching then
        session:addListener(Strip.listener)
        session:watchBattle(true)
        watching = session
    end
end

Strip.listener = function(ev, a, b, c, d, e, g)
    if not scene then return end
    if ev == "battle" then
        Scene.onBattleEvent(scene, a, b, c, d, e, g)
    elseif ev == "boss" and a then
        Scene.banner(scene, a.name, C.warn)
    elseif ev == "clear" then
        Scene.banner(scene, "클리어", C.good)
    elseif ev == "fail" then
        Scene.banner(scene, "전멸", C.bad)
    end
end

local function stageLabel(state, runner)
    local key = runner and runner.key or Game.currentStageKey(state)
    return App.stageCode(key), App.stageName(key)
end

local function layout()
    local s = saved()
    local collapsed = s.collapsed and true or false
    frame:SetHeight(collapsed and HEAD or FULL_H)
    scene:SetShown(not collapsed)
    frame.foot:SetShown(not collapsed)
    frame.grip:SetShown(not collapsed and not s.locked)
    collapseBtn:setText(collapsed and "펼치기" or "접기")
    attach()
end

local function updateHead()
    local state = App.state
    if not state then return end
    local runner = App.session and App.session.runner
    local a, b = stageLabel(state, runner)
    pill.label:SetText(a)
    pill:SetWidth((pill.label:GetStringWidth() or 40) + 16)
    nameText:SetText(b)
    goldText:SetText(UI.number(math.floor(state.gold)) .. " G")
    local parts = {}
    for _, kind in ipairs(Chests.KINDS) do
        local n = Chests.count(state, kind)
        if n > 0 or kind ~= "raid" then parts[#parts + 1] = Chests.NAMES[kind]:gsub(" 상자", "") .. " " .. n end
    end
    chestText:SetText("상자  " .. table.concat(parts, " · "))
    chestText:SetShown((frame:GetWidth() or DEF_W) >= 900)       -- 폭이 좁으면 왼쪽 표시와 겹치므로 감춘다

    local boss = runner and runner.phase == "boss" and runner.boss
    local showBoss = boss and boss.alive
    bossBar:SetShown(showBoss and true or false)
    bossName:SetShown(showBoss and true or false)
    if showBoss then
        bossBar:set(boss.hp / boss:get("MaxHp"))
        bossName:SetText(boss.name .. (runner.raid and ("  " .. runner.wave .. " / " .. runner.waves) or ""))
    end
    local showWaves = runner ~= nil and not showBoss
    waveText:SetShown(showWaves)
    if runner and not showBoss then
        waveText:SetText((runner.raid and "보스 " or "웨이브 ") .. runner.wave .. " / " .. runner.waves)
    end
    local usePips = showWaves and runner.waves <= MAX_PIPS
    for i = 1, MAX_PIPS do
        local p = pips[i]
        p:SetShown(usePips and i <= runner.waves)
        if usePips and i <= runner.waves then p:SetColorTexture(UI.rgb(i <= runner.wave and C.text or C.line2)) end
    end
    progress:SetShown(showWaves and not usePips)
    if showWaves and not usePips then progress:set(runner.wave / runner.waves) end
    if showWaves then
        waveText:ClearAllPoints()
        waveText:SetPoint("LEFT", nameText, "RIGHT", 14 + (usePips and runner.waves * 15 or 158) + 4, 0)
    end
end

local function updateFoot(elapsed)
    local state = App.state
    if not state then return end
    for _, b in ipairs(footToggles) do
        b.label:SetText(b.title .. "  " .. (state.settings[b.key] and "켜짐" or "꺼짐"))
        b.label:SetTextColor(UI.rgb(state.settings[b.key] and C.sub or C.dim))
    end
    -- 초당 피해: 최근 5초 동안 영웅과 소환물이 준 피해
    local runner = App.session and App.session.runner
    if runner then
        local total = 0
        for _, u in ipairs(runner.heroes) do total = total + u.stats.dealt end
        local hist = frame.hist
        if frame.histRunner ~= runner then frame.histRunner, hist = runner, {}; frame.hist = hist end
        hist[#hist + 1] = { t = runner.battle.time, v = total }
        while #hist > 1 and hist[1].t < runner.battle.time - 5 do table.remove(hist, 1) end
        local span = hist[#hist].t - hist[1].t
        dpsText:SetText("초당 피해  " .. (span > 0.5 and UI.number((hist[#hist].v - hist[1].v) / span) or "-"))
    end
    lootText:SetText(App.lastLoot and ("최근 획득  " .. App.lastLoot) or "")
end

function Strip.create()
    if frame then return frame end
    local s = saved()
    frame = CreateFrame("Frame", "WIH_StripFrame", UIParent)
    local maxW = math.min(MAX_W, (UIParent:GetWidth() or 1400) - 20)
    if maxW < MIN_W then maxW = MAX_W end
    frame:SetSize(math.max(MIN_W, math.min(maxW, tonumber(s.w) or DEF_W)), FULL_H)
    if tonumber(s.x) and tonumber(s.y) then
        frame:SetPoint("BOTTOMLEFT", UIParent, "BOTTOMLEFT", s.x, s.y)
    else
        frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 190)
    end
    frame:SetFrameStrata("MEDIUM")
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then frame:SetResizeBounds(MIN_W, HEAD, MAX_W, FULL_H) end
    frame:Hide()
    frame.bg = UI.fill(frame, C.bg, "BACKGROUND", 0.88)
    frame.bg:SetAllPoints()
    UI.border(frame)

    -- 위쪽 줄(끌어서 이동)
    local head = CreateFrame("Frame", nil, frame)
    head:SetPoint("TOPLEFT", 1, -1)
    head:SetPoint("TOPRIGHT", -1, -1)
    head:SetHeight(HEAD - 1)
    head:EnableMouse(true)
    head:RegisterForDrag("LeftButton")
    head:SetScript("OnDragStart", function() if not saved().locked then frame:StartMoving() end end)
    head:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); savePlace() end)
    frame.head = head

    pill = CreateFrame("Frame", nil, head)
    pill:SetSize(60, 18)
    pill:SetPoint("LEFT", 9, 0)
    UI.border(pill, C.line2)
    pill.label = UI.text(pill, 11, C.sub, "CENTER")
    pill.label:SetPoint("CENTER")
    nameText = UI.text(head, 12, C.text)
    nameText:SetPoint("LEFT", pill, "RIGHT", 9, 0)

    -- 웨이브 표시: 점(웨이브가 많으면 막대) + 글자
    pips = {}
    for i = 1, MAX_PIPS do
        local p = UI.fill(head, C.line2, "ARTWORK")
        p:SetSize(12, 4)
        p:SetPoint("LEFT", nameText, "RIGHT", 14 + (i - 1) * 15, 0)
        pips[i] = p
    end
    progress = UI.bar(head, 150, 4, C.text)
    progress:SetPoint("LEFT", nameText, "RIGHT", 14, 0)
    waveText = UI.text(head, 11, C.dim)
    waveText:SetPoint("LEFT", nameText, "RIGHT", 14 + MAX_PIPS * 15 + 6, 0)
    -- 보스 체력(보스가 나오면 웨이브 표시 자리에 뜬다)
    bossBar = UI.bar(head, 200, 5, C.bad)
    bossBar:SetPoint("LEFT", nameText, "RIGHT", 14, 0)
    bossName = UI.text(head, 11, C.warn)
    bossName:SetPoint("LEFT", bossBar, "RIGHT", 8, 0)

    collapseBtn = UI.button(head, "접기", 52, 20, function()
        local st = saved()
        st.collapsed = not st.collapsed
        layout()
    end)
    collapseBtn:SetPoint("RIGHT", -6, 0)
    collapseBtn.tooltip = { title = "접기 / 펼치기", lines = { "접으면 한 줄만 남고 전투 장면을 그리지 않습니다. 사냥은 계속됩니다." } }
    local menu = UI.button(head, "메뉴", 52, 20, function() WIH.Main.toggle() end)
    menu:SetPoint("RIGHT", collapseBtn, "LEFT", -6, 0)
    menu.tooltip = { title = "메뉴", lines = { "영웅, 가방, 편성, 스테이지, 성장, 설정 창을 엽니다. /wih 로도 열 수 있습니다." } }
    chestText = UI.text(head, 11, C.sub, "RIGHT")
    chestText:SetPoint("RIGHT", menu, "LEFT", -14, 0)
    goldText = UI.text(head, 12, C.warn, "RIGHT")
    goldText:SetPoint("RIGHT", chestText, "LEFT", -14, 0)
    local headLine = UI.fill(frame, C.text, "BORDER", 0.05)
    headLine:SetPoint("TOPLEFT", 1, -HEAD)
    headLine:SetPoint("TOPRIGHT", -1, -HEAD)
    headLine:SetHeight(1)

    -- 전투 장면
    scene = Scene.create(frame)
    scene:SetPoint("TOPLEFT", 1, -HEAD - 1)
    scene:SetPoint("BOTTOMRIGHT", -1, FOOT)
    Strip.scene = scene

    -- 아래 줄: 진행 설정(누르면 바뀐다), 초당 피해, 최근 획득
    local foot = CreateFrame("Frame", nil, frame)
    foot:SetPoint("BOTTOMLEFT", 1, 1)
    foot:SetPoint("BOTTOMRIGHT", -1, 1)
    foot:SetHeight(FOOT - 1)
    frame.foot = foot
    footToggles = {}
    local x = 8
    for _, def in ipairs({
        { "repeatMode", "반복", "클리어해도 같은 스테이지를 반복합니다." },
        { "autoAdvance", "자동 진행", "클리어하면 다음 스테이지로 넘어갑니다." },
        { "autoRetry", "실패 시 재시도", "전멸하면 같은 스테이지를 다시 합니다. 끄면 이전 스테이지로 내려갑니다." },
    }) do
        local b = CreateFrame("Button", nil, foot)
        b:SetSize(104, FOOT - 2)
        b:SetPoint("LEFT", x, 0)
        b.label = UI.text(b, 10, C.sub)
        b.label:SetPoint("LEFT", 0, 0)
        b.key, b.title = def[1], def[2]
        b:SetScript("OnClick", function()
            local st = App.state
            if st then st.settings[def[1]] = not st.settings[def[1]] end
            updateFoot(0)
            App.notify("settings")
        end)
        b:SetScript("OnEnter", function(self) UI.showTooltip(self, { title = def[2], lines = { def[3], "누르면 켜고 끕니다." } }) end)
        b:SetScript("OnLeave", UI.hideTooltip)
        footToggles[#footToggles + 1] = b
        x = x + (def[1] == "autoRetry" and 124 or 96)
    end
    dpsText = UI.text(foot, 10, C.dim)
    dpsText:SetPoint("LEFT", x + 4, 0)
    lootText = UI.text(foot, 10, C.sub, "RIGHT")
    lootText:SetPoint("RIGHT", -18, 0)

    -- 폭 조절 손잡이
    local grip = CreateFrame("Frame", nil, frame)
    grip:SetSize(14, 14)
    grip:SetPoint("BOTTOMRIGHT", -1, 1)
    grip:EnableMouse(true)
    grip:SetFrameLevel(foot:GetFrameLevel() + 5)
    for i = 1, 2 do
        local t = UI.fill(grip, C.dim, "OVERLAY")
        t:SetSize(i * 4, 1)
        t:SetPoint("BOTTOMRIGHT", -2, i * 4 - 2)
    end
    grip:SetScript("OnMouseDown", function() frame:StartSizing("RIGHT") end)
    grip:SetScript("OnMouseUp", function() frame:StopMovingOrSizing(); frame:SetHeight(saved().collapsed and HEAD or FULL_H); savePlace() end)
    frame.grip = grip

    local acc = 0
    frame:SetScript("OnUpdate", function(_, elapsed)
        if App.session ~= watching then attach() end
        if not saved().collapsed then
            local ok, err = pcall(Scene.update, scene, elapsed)
            if not ok then
                UI.reportError(err)
                saved().collapsed = true      -- 같은 오류가 프레임마다 반복되지 않게 장면을 접는다
                layout()
            end
        end
        acc = acc + elapsed
        if acc >= 0.25 then
            local ok, err = pcall(function() updateHead(); updateFoot(acc) end)
            acc = 0
            if not ok then UI.reportError(err) end
        end
    end)
    frame:SetScript("OnShow", function() layout(); updateHead() end)
    frame:SetScript("OnHide", attach)
    layout()
    return frame
end

-- 게임이 진행 중이고 숨기지 않았으면 띠를 보인다.
function Strip.refresh()
    local want = App.state ~= nil and not saved().hidden
    if want then
        if not frame then Strip.create() end
        if not frame:IsShown() then frame:Show() end
        layout()
        updateHead()
    elseif frame and frame:IsShown() then
        frame:Hide()
    end
end

function Strip.toggleHidden()
    local s = saved()
    s.hidden = not s.hidden
    Strip.refresh()
    return s.hidden
end

function Strip.setLocked(v)
    saved().locked = v and true or false
    if frame then layout() end
end

function Strip.resetPlace()
    local s = saved()
    s.x, s.y, s.w = nil, nil, nil
    if frame then
        frame:ClearAllPoints()
        frame:SetPoint("BOTTOM", UIParent, "BOTTOM", 0, 190)
        frame:SetWidth(DEF_W)
    end
end

function Strip.frame() return frame end
function Strip.saved() return saved() end

App.watchers[#App.watchers + 1] = function(tag)
    if tag == "loaded" or tag == "newGame" or tag == "restore" or tag == "reset" then Strip.refresh() end
end

return Strip
