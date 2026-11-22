-- WoW API 대역(stub). 게임 밖 Lua 5.1에서 애드온 파일을 불러와 실행 오류를 잡기 위한 것이다.
-- 실제 클라이언트의 동작을 흉내 내지 않는다. 위젯의 모든 메서드는 호출 가능하고, 화면에는 아무것도 그리지 않는다.
-- 이 대역을 통과했다는 것은 "Lua 문법과 자체 로직에 실행 오류가 없다"는 뜻일 뿐, 게임 안에서 동작한다는 뜻이 아니다.

local Stub = {}

local widgetMeta = {}

local function newWidget(kind, name, parent)
    local w = { __kind = kind, __name = name, __parent = parent, __shown = true, __scripts = {}, __events = {},
        __children = {}, __text = "", __points = {}, __scroll = 0 }
    return setmetatable(w, widgetMeta)
end

local methods = {}

function methods:Show() self.__shown = true; local s = self.__scripts.OnShow; if s then s(self) end end
function methods:Hide() self.__shown = false; local s = self.__scripts.OnHide; if s then s(self) end end
function methods:SetShown(v) if v then self:Show() else self:Hide() end end
function methods:IsShown() return self.__shown end
function methods:IsVisible() return self.__shown end
function methods:SetScript(name, fn) self.__scripts[name] = fn end
function methods:GetScript(name) return self.__scripts[name] end
function methods:HookScript(name, fn)
    local old = self.__scripts[name]
    self.__scripts[name] = function(...) if old then old(...) end return fn(...) end
end
function methods:RegisterEvent(event) self.__events[event] = true; Stub.eventFrames[self] = true end
function methods:UnregisterEvent(event) self.__events[event] = nil end
function methods:UnregisterAllEvents() self.__events = {} end
function methods:CreateTexture() local t = newWidget("Texture", nil, self); self.__children[#self.__children + 1] = t; return t end
function methods:CreateMaskTexture() return newWidget("MaskTexture", nil, self) end
function methods:CreateLine() return newWidget("Line", nil, self) end
function methods:CreateFontString() local t = newWidget("FontString", nil, self); self.__children[#self.__children + 1] = t; return t end
function methods:CreateAnimationGroup() return newWidget("AnimationGroup", nil, self) end
function methods:CreateAnimation(kind) return newWidget("Animation:" .. tostring(kind), nil, self) end
function methods:SetText(t) self.__text = tostring(t or "") end
function methods:GetText() return self.__text end
function methods:SetFormattedText(fmt, ...) self.__text = string.format(fmt, ...) end
function methods:GetStringWidth() return #self.__text * 6 end
function methods:GetUnboundedStringWidth() return #self.__text * 6 end
function methods:GetStringHeight() return 12 end
function methods:GetFont() return "Fonts\\2002.TTF", 12, "" end
function methods:SetSize(w, h) self.__w, self.__h = w, h end
function methods:SetWidth(w) self.__w = w end
function methods:SetHeight(h) self.__h = h end
function methods:GetWidth() return self.__w or 0 end
function methods:GetHeight() return self.__h or 0 end
function methods:GetSize() return self.__w or 0, self.__h or 0 end
function methods:SetPoint(...) self.__points[#self.__points + 1] = { ... } end
function methods:ClearAllPoints() self.__points = {} end
function methods:GetParent() return self.__parent end
function methods:GetName() return self.__name end
function methods:SetVerticalScroll(v) self.__scroll = v end
function methods:GetVerticalScroll() return self.__scroll end
function methods:GetVerticalScrollRange() return 1000 end
function methods:SetScrollChild(c) self.__scrollChild = c end
function methods:SetTexture(path) self.__texture = path; return true end
function methods:GetTexture() return self.__texture end
function methods:GetModelFileID() return nil end
function methods:GetEffectiveScale() return 1 end
function methods:GetScale() return 1 end
function methods:GetAlpha() return 1 end
function methods:GetFrameLevel() return 1 end
function methods:GetChildren() return unpack(self.__children) end
function methods:GetNumChildren() return #self.__children end
function methods:IsMouseOver() return false end
function methods:GetCenter() return 0, 0 end
function methods:GetLeft() return 0 end
function methods:GetRight() return self.__w or 0 end
function methods:GetTop() return self.__h or 0 end
function methods:GetBottom() return 0 end
function methods:GetID() return self.__id or 0 end
function methods:SetID(id) self.__id = id end
function methods:GetValue() return self.__value or 0 end
function methods:SetValue(v) self.__value = v end
function methods:GetChecked() return self.__checked or false end
function methods:SetChecked(v) self.__checked = v and true or false end
function methods:IsEnabled() return self.__disabled ~= true end
function methods:Enable() self.__disabled = false end
function methods:Disable() self.__disabled = true end
function methods:SetEnabled(v) self.__disabled = not v end
function methods:Click(...)
    local s = self.__scripts.OnClick
    if s then s(self, ...) end
end

-- 정의하지 않은 메서드는 아무 일도 하지 않고 nil을 돌려주는 함수가 된다.
widgetMeta.__index = function(self, key)
    local m = methods[key]
    if m then return m end
    if type(key) == "string" and key:sub(1, 2) == "__" then return nil end
    if Stub.missingMethods and Stub.missingMethods[key] then return nil end
    Stub.unknownCalls[key] = (Stub.unknownCalls[key] or 0) + 1
    return function() return nil end
end

-- 실제 클라이언트에서 프레임은 수거되지 않는다. 약한 참조를 쓰면 지역 변수로만 잡힌 이벤트 프레임이 사라진다.
Stub.eventFrames = {}
Stub.unknownCalls = {}
Stub.timers = {}
Stub.printed = {}
Stub.clock = 1000
Stub.epoch = 1795300000
Stub.missingMethods = { SetMinResize = true, SetMaxResize = true, SetGradientAlpha = true }

function Stub.install(env)
    env = env or _G
    env.UIParent = newWidget("Frame", "UIParent", nil)
    env.WorldFrame = newWidget("Frame", "WorldFrame", nil)
    env.CreateFrame = function(kind, name, parent, template)
        if type(kind) ~= "string" then error("CreateFrame: 종류가 문자열이 아님") end
        local w = newWidget(kind, name, parent)
        w.__template = template
        if name then env[name] = w end
        if parent and parent.__children then parent.__children[#parent.__children + 1] = w end
        return w
    end
    env.CreateColor = function(r, g, b, a) return { r = r, g = g, b = b, a = a } end
    env.GetTime = function() return Stub.clock end
    env.time = function() return Stub.epoch + math.floor(Stub.clock) end
    env.GetServerTime = env.time
    env.date = function(fmt, t) return os.date(fmt or "%c", t or env.time()) end
    env.debugprofilestop = function() return os.clock() * 1000 end
    env.GetFramerate = function() return 60 end
    env.GetBuildInfo = function() return "1.60.1", "71037", "Nov 20 2026", 16001 end
    env.GetLocale = function() return "koKR" end
    env.WOW_PROJECT_ID, env.WOW_PROJECT_CAMELOT, env.WOW_PROJECT_MAINLINE, env.WOW_PROJECT_CLASSIC = 18, 18, 1, 2
    env.STANDARD_TEXT_FONT, env.UNIT_NAME_FONT, env.DAMAGE_TEXT_FONT = "Fonts\\2002.TTF", "Fonts\\2002B.TTF", "Fonts\\K_Damage.TTF"
    env.UnitName = function() return "시험용", "캐릭터" end
    env.UnitFullName = function() return "시험용", "Realm1" end
    env.GetRealmName = function() return "TEST KR1 Realm 11" end
    env.GetNormalizedRealmName = function() return "TESTKR1Realm11" end
    env.UnitGUID = function() return "Player-1234-0ABCDEF1" end
    env.UnitFactionGroup = function() return "Alliance", "얼라이언스" end
    env.UnitClass = function() return "전사", "WARRIOR", 1 end
    env.UnitRace = function() return "인간", "Human", 1 end
    env.UnitLevel = function() return 60 end
    env.UnitHealth = function() return 1000 end
    env.GetMaxPlayerLevel = function() return 60 end
    env.InCombatLockdown = function() return Stub.inCombat or false end
    env.IsInInstance = function() return false, "none" end
    env.issecretvalue = function() return false end
    env.strlenutf8 = function(s)
        local n = 0
        for _ in string.gmatch(s, "[%z\1-\127\194-\244][\128-\191]*") do n = n + 1 end
        return n
    end
    env.wipe = function(t) for k in pairs(t) do t[k] = nil end return t end
    env.tinsert, env.tremove, env.format, env.floor = table.insert, table.remove, string.format, math.floor
    env.max, env.min, env.abs = math.max, math.min, math.abs
    env.strsplit = function(sep, s)
        local out = {}
        for part in string.gmatch(s, "([^" .. sep .. "]*)") do out[#out + 1] = part end
        return unpack(out)
    end
    env.strtrim = function(s) return (s:gsub("^%s+", ""):gsub("%s+$", "")) end
    env.C_Timer = {
        After = function(delay, fn) Stub.timers[#Stub.timers + 1] = { at = Stub.clock + delay, fn = fn } end,
        NewTicker = function(interval, fn)
            local ticker = { cancelled = false }
            function ticker:Cancel() self.cancelled = true end
            Stub.timers[#Stub.timers + 1] = { at = Stub.clock + interval, fn = fn, every = interval, ticker = ticker }
            return ticker
        end,
    }
    env.C_AddOns = {
        GetAddOnMetadata = function(_, field) return field == "X-WIH-TOC" and "stub" or "stub-title" end,
        IsAddOnLoaded = function() return true end,
    }
    env.C_Texture = { GetAtlasInfo = function() return nil end }
    env.GetFileIDFromPath = function(path) return path:find("QuestionMark") and 134400 or nil end
    env.Settings = {
        RegisterCanvasLayoutCategory = function(_, name) return { GetID = function() return name end } end,
        RegisterAddOnCategory = function() end,
        OpenToCategory = function() end,
    }
    env.SOUNDKIT = setmetatable({}, { __index = function() return 1 end })
    env.PlaySound = function() return true, 1 end
    env.SlashCmdList = {}
    env.GameFontNormal = newWidget("Font", "GameFontNormal")
    env.GameFontHighlight = newWidget("Font", "GameFontHighlight")
    env.GameFontHighlightSmall = newWidget("Font", "GameFontHighlightSmall")
    env.GameFontDisableSmall = newWidget("Font", "GameFontDisableSmall")
    env.print = function(...)
        local parts = {}
        for i = 1, select("#", ...) do parts[i] = tostring(select(i, ...)) end
        Stub.printed[#Stub.printed + 1] = table.concat(parts, " ")
    end
    return env
end

-- 등록된 모든 프레임에 이벤트를 보낸다.
function Stub.fire(event, ...)
    local frames = {}
    for frame in pairs(Stub.eventFrames) do frames[#frames + 1] = frame end
    for i = 1, #frames do
        local frame = frames[i]
        if frame.__events[event] and frame.__scripts.OnEvent then
            frame.__scripts.OnEvent(frame, event, ...)
        end
    end
end

-- 시간을 앞으로 보내고 그 사이의 타이머와 OnUpdate를 실행한다.
function Stub.advance(seconds, step)
    step = step or 0.1
    local target = Stub.clock + seconds
    while Stub.clock < target do
        Stub.clock = Stub.clock + step
        local i = 1
        while i <= #Stub.timers do
            local t = Stub.timers[i]
            if t.ticker and t.ticker.cancelled then
                table.remove(Stub.timers, i)
            elseif t.at <= Stub.clock then
                if t.every then t.at = t.at + t.every else table.remove(Stub.timers, i) end
                t.fn(t.ticker)
                if t.every then i = i + 1 end
            else
                i = i + 1
            end
        end
        for frame in pairs(Stub.updateFrames or {}) do
            local s = frame.__scripts.OnUpdate
            if s and frame.__shown then s(frame, step) end
        end
    end
end

-- TOC 파일의 순서대로 애드온 파일을 불러온다. 실제 클라이언트처럼 각 파일에 (애드온 이름, 공용 테이블)을 넘긴다.
function Stub.loadAddon(dir, tocName, addonName)
    local ns = {}
    local toc = assert(io.open(dir .. "/" .. tocName, "r"))
    local files, meta = {}, {}
    for line in toc:lines() do
        line = line:gsub("\r", "")
        local key, value = line:match("^##%s*([^:]+):%s*(.*)$")
        if key then
            meta[key] = value
        elseif line ~= "" and not line:match("^#") then
            files[#files + 1] = (line:gsub("\\", "/"))
        end
    end
    toc:close()
    for i = 1, #files do
        local chunk, err = loadfile(dir .. "/" .. files[i])
        if not chunk then error("불러오기 실패 " .. files[i] .. ": " .. tostring(err)) end
        chunk(addonName, ns)
    end
    return ns, meta, files
end

return Stub
