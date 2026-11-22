-- 메뉴 창: 영웅, 가방, 편성, 스테이지, 성장, 기록, 설정. 사냥 띠와는 별개의 창이고 필요할 때만 연다.
-- 위쪽 줄에 탭이 있고(끌어서 이동), 아래에 알림 줄이 있다. 크기 조정과 위치·크기 저장을 지원한다.

local _, WIH = ...
local UI = WIH.module("UI")
local App = WIH.module("App")
local Main = WIH.module("Main")

UI.screens = UI.screens or {}       -- [id] = { label, order, create(parent) → frame, refresh(frame), update(frame, elapsed), onShow, onHide }
local HEAD, FOOT = 44, 22
local MIN_W, MIN_H, DEF_W, DEF_H = 960, 600, 960, 600

local frame, content, tabs, goldText, noticeText
local built = {}
local current
Main.built = built                  -- 화면 ID → 만들어진 프레임(검사와 진단용)
function Main.current() return current end

local function layoutSaved()
    WIH_UI = type(WIH_UI) == "table" and WIH_UI or {}
    return WIH_UI
end

local function tabOrder()
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
    goldText:SetText(state and (UI.number(math.floor(state.gold)) .. " G") or "")
end

function Main.show(id)
    if not frame then Main.create() end
    if not App.state then id = "setup" end
    if id == "setup" and App.state then id = "heroes" end
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
    for tabId, b in pairs(tabs) do
        b:setSelected(tabId == id)
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
        frame:SetPoint("CENTER", 0, 60)
    end
    frame:SetFrameStrata("HIGH")
    frame:SetToplevel(true)
    frame:SetClampedToScreen(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    if frame.SetResizeBounds then frame:SetResizeBounds(MIN_W, MIN_H, 1500, 950) end
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

    -- 위쪽 줄: 이름, 탭, 골드, 닫기(끌어서 이동)
    local top = UI.panel(frame, UI.C.panel)
    top:SetPoint("TOPLEFT", 1, -1)
    top:SetPoint("TOPRIGHT", -1, -1)
    top:SetHeight(HEAD)
    top:EnableMouse(true)
    top:RegisterForDrag("LeftButton")
    top:SetScript("OnDragStart", function() frame:StartMoving() end)
    top:SetScript("OnDragStop", function() frame:StopMovingOrSizing(); savePlace() end)
    local brand = UI.text(top, 14, UI.C.text)
    brand:SetPoint("LEFT", 16, 0)
    brand:SetText("W.I.H")
    tabs = {}
    local x = 76
    for _, id in ipairs(tabOrder()) do
        local b = UI.tab(top, UI.screens[id].label, function() Main.show(id) end)
        b:SetPoint("LEFT", x, 0)
        tabs[id] = b
        x = x + b:GetWidth()
    end
    local close = UI.button(top, "닫기", 48, 24, function() frame:Hide() end)
    close:SetPoint("RIGHT", -10, 0)
    goldText = UI.text(top, 13, UI.C.warn, "RIGHT")
    goldText:SetPoint("RIGHT", close, "LEFT", -16, 0)
    local line = UI.fill(frame, UI.C.line, "BORDER")
    line:SetPoint("TOPLEFT", top, "BOTTOMLEFT")
    line:SetPoint("TOPRIGHT", top, "BOTTOMRIGHT")
    line:SetHeight(1)

    -- 아래 알림 줄
    local foot = UI.panel(frame, UI.C.panel)
    foot:SetPoint("BOTTOMLEFT", 1, 1)
    foot:SetPoint("BOTTOMRIGHT", -1, 1)
    foot:SetHeight(FOOT)
    noticeText = UI.text(foot, 11, UI.C.sub)
    noticeText:SetPoint("LEFT", 12, 0)
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
    content:SetPoint("TOPLEFT", 1, -HEAD - 2)
    content:SetPoint("BOTTOMRIGHT", -1, FOOT + 2)
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
        Main.show(current or (App.state and "heroes" or "setup"))
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

function Main.open(id)
    if not frame then Main.create() end
    if not frame:IsShown() then frame:Show() end
    if id then Main.show(id) end
end

function Main.isShown()
    return frame ~= nil and frame:IsShown()
end

-- 상태가 바뀌면 보이는 화면을 다시 그린다.
App.watchers[#App.watchers + 1] = function(tag)
    if tag == "reset" or tag == "newGame" or tag == "restore" then
        if tag == "reset" then Main.open() end      -- 초기화하면 진영 선택부터 다시 해야 하므로 창을 연다
        if frame and frame:IsShown() then Main.show(App.state and "heroes" or "setup") end
        return
    end
    if tag == "loaded" then
        print("|cffc0c0c0W.I.H|r: /wih 를 입력하면 메뉴 창이 열립니다." .. (App.state and "" or " 처음이면 진영과 첫 영웅을 고릅니다."))
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
