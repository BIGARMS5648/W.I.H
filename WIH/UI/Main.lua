-- 본 창: 상단 띠, 왼쪽 메뉴, 화면 전환. 이동과 크기 조정을 지원하고 위치·크기를 저장한다.

local _, WIH = ...
local UI = WIH.module("UI")
local App = WIH.module("App")
local Game = WIH.module("Game")
local Tables = WIH.module("Tables")
local Dungeons = WIH.module("Dungeons")
local Main = WIH.module("Main")

UI.screens = UI.screens or {}       -- [id] = { label, order, create(parent) → frame, refresh(frame), update(frame, elapsed), onShow, onHide }
local NAV_WIDTH, TOP_HEIGHT = 124, 38
local MIN_W, MIN_H, DEF_W, DEF_H = 980, 610, 980, 640

local frame, content, navButtons, topStage, topGold, noticeText
local built = {}
local current
Main.built = built                  -- 화면 ID → 만들어진 프레임(검사와 진단용)
function Main.current() return current end

local function layoutSaved()
    WIH_UI = type(WIH_UI) == "table" and WIH_UI or {}
    return WIH_UI
end

local function navOrder()
    local list = {}
    for id, s in pairs(UI.screens) do
        if s.order then list[#list + 1] = id end
    end
    table.sort(list, function(a, b) return UI.screens[a].order < UI.screens[b].order end)
    return list
end

local function updateTop()
    if not frame then return end
    local state = App.state
    if not state then
        topStage:SetText("")
        topGold:SetText("")
        return
    end
    local sec = Dungeons.sections[state.stage.section]
    local text = Tables.DIFFICULTY_NAMES[state.stage.difficulty] .. "  ·  " .. (sec and sec.name or "")
    local runner = App.session and App.session.runner
    if runner and runner.raid then
        text = Tables.DIFFICULTY_NAMES[runner.difficulty] .. "  ·  " .. runner.raid.name .. " 레이드  ·  보스 " .. runner.wave .. "/" .. runner.waves
    elseif runner then
        if runner.phase == "boss" and runner.boss then
            text = text .. "  ·  보스"
        else
            text = text .. "  ·  웨이브 " .. runner.wave .. "/" .. runner.waves
        end
    end
    topStage:SetText(text)
    topGold:SetText(UI.number(math.floor(state.gold)) .. " G")
end

function Main.show(id)
    if not frame then Main.create() end
    if not App.state then id = "setup" end
    local screen = UI.screens[id]
    if not screen then return end
    if current and current ~= id and built[current] then
        built[current]:Hide()
        local old = UI.screens[current]
        if old.onHide then old.onHide(built[current]) end
    end
    if not built[id] then
        local f = screen.create(content)
        f:SetAllPoints(content)
        built[id] = f
    end
    current = id
    built[id]:Show()
    if screen.onShow then screen.onShow(built[id]) end
    if screen.refresh then screen.refresh(built[id]) end
    for navId, b in pairs(navButtons) do
        b:setSelected(navId == id)
        b:SetShown(App.state ~= nil)
    end
    updateTop()
end

function Main.refresh()
    if not frame or not frame:IsShown() or not current then return end
    if not App.state and current ~= "setup" then return Main.show("setup") end
    local screen = UI.screens[current]
    if screen.refresh and built[current] then screen.refresh(built[current]) end
    updateTop()
end

function Main.notice(text, color)
    if not noticeText then return end
    noticeText:SetText(text or "")
    noticeText:SetTextColor(UI.rgb(color or UI.C.sub))
    noticeText.until_ = (GetTime and GetTime() or 0) + 5
end

function Main.create()
    if frame then return frame end
    local saved = layoutSaved()
    frame = CreateFrame("Frame", "WIH_MainFrame", UIParent)
    frame:SetSize(math.max(MIN_W, tonumber(saved.w) or DEF_W), math.max(MIN_H, tonumber(saved.h) or DEF_H))
    if tonumber(saved.x) and tonumber(saved.y) then
        frame:SetPoint("TOPLEFT", UIParent, "BOTTOMLEFT", saved.x, saved.y)
    else
        frame:SetPoint("CENTER")
    end
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then frame:SetResizeBounds(MIN_W, MIN_H, 1800, 1200) end
    frame:EnableMouse(true)
    frame:Hide()
    frame.bg = UI.fill(frame, UI.C.bg)
    frame.bg:SetAllPoints()
    UI.border(frame)

    local function savePlace()
        local s = layoutSaved()
        s.w, s.h = frame:GetWidth(), frame:GetHeight()
        s.x, s.y = frame:GetLeft(), frame:GetTop()
    end

    -- 상단 띠(끌어서 이동)
    local top = UI.panel(frame, UI.C.panel)
    top:SetPoint("TOPLEFT", 1, -1)
    top:SetPoint("TOPRIGHT", -1, -1)
    top:SetHeight(TOP_HEIGHT)
    top:EnableMouse(true)
    top:RegisterForDrag("LeftButton")
    top:SetScript("OnDragStart", function() frame:StartMoving() end)
    top:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); savePlace() end)
    local title = UI.text(top, 14, UI.C.text)
    title:SetPoint("LEFT", 14, 0)
    title:SetText("W.I.H")
    topStage = UI.text(top, 12, UI.C.sub)
    topStage:SetPoint("LEFT", title, "RIGHT", 18, 0)
    local close = UI.button(top, "닫기", 52, 22, function() frame:Hide() end)
    close:SetPoint("RIGHT", -8, 0)
    topGold = UI.text(top, 13, UI.C.warn, "RIGHT")
    topGold:SetPoint("RIGHT", close, "LEFT", -14, 0)
    local line = UI.fill(frame, UI.C.line, "BORDER")
    line:SetPoint("TOPLEFT", top, "BOTTOMLEFT")
    line:SetPoint("TOPRIGHT", top, "BOTTOMRIGHT")
    line:SetHeight(1)

    -- 왼쪽 메뉴
    local nav = UI.panel(frame, UI.C.panel)
    nav:SetPoint("TOPLEFT", top, "BOTTOMLEFT", 0, -1)
    nav:SetPoint("BOTTOMLEFT", 1, 1)
    nav:SetWidth(NAV_WIDTH)
    navButtons = {}
    local y = -10
    for _, id in ipairs(navOrder()) do
        local b = UI.button(nav, UI.screens[id].label, NAV_WIDTH - 20, 30, function() Main.show(id) end)
        b:SetPoint("TOPLEFT", 10, y)
        navButtons[id] = b
        y = y - 36
    end
    local navLine = UI.fill(frame, UI.C.line, "BORDER")
    navLine:SetPoint("TOPLEFT", nav, "TOPRIGHT")
    navLine:SetPoint("BOTTOMLEFT", nav, "BOTTOMRIGHT")
    navLine:SetWidth(1)

    -- 아래 알림 줄
    local foot = UI.panel(frame, UI.C.panel)
    foot:SetPoint("BOTTOMLEFT", nav, "BOTTOMRIGHT", 1, 0)
    foot:SetPoint("BOTTOMRIGHT", -1, 1)
    foot:SetHeight(22)
    noticeText = UI.text(foot, 11, UI.C.sub)
    noticeText:SetPoint("LEFT", 10, 0)
    noticeText:SetPoint("RIGHT", -24, 0)

    -- 크기 조정 손잡이
    local grip = CreateFrame("Frame", nil, frame)
    grip:SetSize(16, 16)
    grip:SetPoint("BOTTOMRIGHT", -1, 1)
    grip:EnableMouse(true)
    grip:SetFrameLevel(foot:GetFrameLevel() + 5)
    for i = 1, 3 do
        local t = UI.fill(grip, UI.C.dim, "OVERLAY")
        t:SetSize(i * 4, 1)
        t:SetPoint("BOTTOMRIGHT", -2, i * 4 - 2)
    end
    grip:SetScript("OnMouseDown", function() frame:StartSizing("BOTTOMRIGHT") end)
    grip:SetScript("OnMouseUp", function()
        frame:StopMovingOrSizing()
        savePlace()
        Main.refresh()
    end)

    content = CreateFrame("Frame", nil, frame)
    content:SetPoint("TOPLEFT", nav, "TOPRIGHT", 1, 0)
    content:SetPoint("BOTTOMRIGHT", foot, "TOPRIGHT", 0, 1)
    if content.SetClipsChildren then content:SetClipsChildren(true) end

    local acc = 0
    frame:SetScript("OnUpdate", function(_, elapsed)
        local screen = current and UI.screens[current]
        if screen and screen.update and built[current] then
            local ok, err = pcall(screen.update, built[current], elapsed)
            if not ok then
                UI.reportError(err)
                screen.update = nil      -- 같은 오류가 프레임마다 반복되지 않게 한다
            end
        end
        acc = acc + elapsed
        if acc >= 0.25 then
            acc = 0
            updateTop()
            if noticeText.until_ and GetTime and GetTime() > noticeText.until_ then
                noticeText:SetText("")
                noticeText.until_ = nil
            end
        end
    end)
    frame:SetScript("OnShow", function()
        Main.show(current or (App.state and "battle" or "setup"))
    end)
    frame:SetScript("OnHide", function()
        if current and built[current] and UI.screens[current].onHide then UI.screens[current].onHide(built[current]) end
    end)

    if UISpecialFrames then table.insert(UISpecialFrames, "WIH_MainFrame") end   -- ESC로 닫기
    return frame
end

function Main.toggle()
    if not frame then Main.create() end
    if frame:IsShown() then frame:Hide() else frame:Show() end
end

function Main.isShown()
    return frame ~= nil and frame:IsShown()
end

-- 상태가 바뀌면 보이는 화면을 다시 그린다.
App.watchers[#App.watchers + 1] = function(tag)
    if tag == "reset" or tag == "newGame" or tag == "restore" then
        if frame and frame:IsShown() then Main.show(App.state and "battle" or "setup") end
        return
    end
    if tag == "loaded" then
        print("|cffc0c0c0W.I.H|r: /wih 를 입력하면 창이 열립니다.")
        if App.loadInfo and App.loadInfo.status == "fixed" then
            print("|cffc0c0c0W.I.H|r: 저장 데이터의 일부를 바로잡았습니다. 설정 화면에서 내용을 볼 수 있습니다.")
        elseif App.loadInfo and App.loadInfo.status == "newer" then
            print("|cffd06058W.I.H|r: 더 새로운 버전의 저장 데이터입니다. 애드온을 최신 버전으로 올려 주세요. 저장 데이터는 건드리지 않습니다.")
        end
        return
    end
    Main.refresh()
end

return Main
