-- W.I.H 환경 점검 도구
-- 실제 클라이언트에서만 확인할 수 있는 항목을 한 번에 점검하고, 결과를 복사할 수 있는 글로 보여 준다.
-- 모든 점검은 pcall 안에서 실행한다. 점검 하나가 실패해도 나머지는 계속된다.
-- 캐릭터 이름, 서버 이름, GUID는 글자 모양만 남기고 가린다.

local ADDON_NAME = ...
ADDON_NAME = ADDON_NAME or "WIH_EnvCheck"

local lines = {}          -- 이번 점검의 결과 줄
local combatLines = {}    -- 전투 중 점검 결과 (전투가 끝난 뒤에도 유지)
local blockedEvents = {}  -- ADDON_ACTION_BLOCKED / FORBIDDEN 기록
local ui = {}

local function add(tag, text)
    lines[#lines + 1] = "[" .. tag .. "] " .. tostring(text)
end

local function section(title)
    lines[#lines + 1] = ""
    lines[#lines + 1] = "== " .. title .. " =="
end

-- 값 여러 개를 한 줄 문자열로 만든다. nil도 표시한다.
local function join(...)
    local n = select("#", ...)
    local out = {}
    for i = 1, n do
        local v = select(i, ...)
        if type(v) == "string" then
            out[i] = '"' .. v .. '"'
        else
            out[i] = tostring(v)
        end
    end
    if n == 0 then return "(반환값 없음)" end
    return table.concat(out, ", ")
end

-- 함수를 pcall로 실행하고 결과를 한 줄로 기록한다. 반환값 중간의 nil도 그대로 표시한다.
local function packResults(ok, ...)
    return ok, select("#", ...), { ... }
end

local function try(label, fn)
    local ok, n, values = packResults(pcall(fn))
    if ok then
        add("OK", label .. " = " .. join(unpack(values, 1, n)))
    else
        add("오류", label .. " : " .. tostring(values[1]))
    end
end

-- 한 번만 실행하면 되는 점검(프레임을 새로 만드는 점검 등)의 결과를 보관한다.
local cache = {}
local function cached(key, fn)
    return function()
        if cache[key] then
            for i = 1, #cache[key] do lines[#lines + 1] = cache[key][i] end
            return
        end
        local first = #lines + 1
        fn()
        local copy = {}
        for i = first, #lines do copy[#copy + 1] = lines[i] end
        cache[key] = copy
    end
end

-- 개인 식별 정보를 가린다. 글자 종류와 길이만 남긴다.
local function mask(s)
    if type(s) ~= "string" then return tostring(s) end
    local out = s:gsub("[\128-\255]+", function(seq)
        -- 한글 등 멀티바이트 글자는 글자 수만큼 '가'로 바꾼다 (UTF-8 3바이트 기준 근사).
        local n = math.max(1, math.floor(#seq / 3))
        return string.rep("가", n)
    end)
    out = out:gsub("%u", "A"):gsub("%l", "a"):gsub("%d", "9")
    return out
end

local function typeOfPath(path)
    -- "C_Timer.After" 같은 경로의 타입을 돌려준다.
    local obj = _G
    for part in string.gmatch(path, "[^%.]+") do
        if type(obj) ~= "table" then return "nil(상위 없음)" end
        obj = obj[part]
    end
    return type(obj)
end

local function listTypes(title, paths)
    local parts = {}
    for i = 1, #paths do
        parts[#parts + 1] = paths[i] .. ":" .. typeOfPath(paths[i])
    end
    add("정보", title .. " → " .. table.concat(parts, "  "))
end

local function methodTypes(title, obj, methods)
    if not obj then
        add("오류", title .. " : 객체를 만들지 못함")
        return
    end
    local has, missing = {}, {}
    for i = 1, #methods do
        if type(obj[methods[i]]) == "function" then
            has[#has + 1] = methods[i]
        else
            missing[#missing + 1] = methods[i]
        end
    end
    add("정보", title .. " 있음: " .. (#has > 0 and table.concat(has, " ") or "(없음)"))
    add(#missing > 0 and "주의" or "정보", title .. " 없음: " .. (#missing > 0 and table.concat(missing, " ") or "(없음)"))
end

local function now()
    if type(debugprofilestop) == "function" then return debugprofilestop() end
    return (GetTime and GetTime() or 0) * 1000
end

------------------------------------------------------------------------
-- 점검 항목
------------------------------------------------------------------------

local function checkBuild()
    section("1. 빌드와 프로젝트")
    try("GetBuildInfo()", function() return GetBuildInfo() end)
    add("정보", "WOW_PROJECT_ID=" .. tostring(WOW_PROJECT_ID)
        .. " CAMELOT=" .. tostring(WOW_PROJECT_CAMELOT)
        .. " MAINLINE=" .. tostring(WOW_PROJECT_MAINLINE)
        .. " CLASSIC=" .. tostring(WOW_PROJECT_CLASSIC))
    add("정보", "_VERSION=" .. tostring(_VERSION))
    try("불러온 TOC (X-WIH-TOC)", function()
        if C_AddOns and C_AddOns.GetAddOnMetadata then
            return C_AddOns.GetAddOnMetadata(ADDON_NAME, "X-WIH-TOC"), C_AddOns.GetAddOnMetadata(ADDON_NAME, "Title")
        end
        return "C_AddOns.GetAddOnMetadata 없음"
    end)
    try("C_GameRules.GetForeverExperiencePreset()", function()
        if C_GameRules and C_GameRules.GetForeverExperiencePreset then
            return C_GameRules.GetForeverExperiencePreset()
        end
        return "함수 없음"
    end)
end

local function checkLocaleAndFonts()
    section("2. 로캘과 글꼴")
    try("GetLocale()", function() return GetLocale() end)
    add("정보", "STANDARD_TEXT_FONT=" .. tostring(STANDARD_TEXT_FONT)
        .. " UNIT_NAME_FONT=" .. tostring(UNIT_NAME_FONT)
        .. " DAMAGE_TEXT_FONT=" .. tostring(DAMAGE_TEXT_FONT))
    local fonts = { "GameFontNormal", "GameFontHighlight", "GameFontHighlightSmall", "GameFontNormalLarge",
        "GameFontDisable", "SystemFont_Shadow_Med1", "NumberFontNormal", "ChatFontNormal", "GameTooltipText" }
    for i = 1, #fonts do
        local name = fonts[i]
        try(name .. ":GetFont()", function()
            local obj = _G[name]
            if not obj then return "객체 없음" end
            return obj:GetFont()
        end)
    end
    try("한글 문자열 폭", function()
        local fs = UIParent:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetText("가나다라마바사 ABC 123")
        local w = fs:GetStringWidth()
        local h = fs:GetStringHeight()
        fs:Hide()
        return w, h, strlenutf8 and strlenutf8("가나다") or "strlenutf8 없음", #"가나다"
    end)
end

local function checkPlayer()
    section("3. 플레이어 기본 정보 (이름·서버·GUID는 가림)")
    try("UnitName(\"player\")", function()
        local a, b = UnitName("player")
        return mask(a), b == nil and "nil" or mask(b)
    end)
    try("UnitFullName(\"player\")", function()
        if not UnitFullName then return "함수 없음" end
        local a, b = UnitFullName("player")
        return mask(a), b == nil and "nil" or mask(b)
    end)
    try("GetRealmName()", function() return mask(GetRealmName()) end)
    try("GetNormalizedRealmName()", function()
        if not GetNormalizedRealmName then return "함수 없음" end
        return mask(GetNormalizedRealmName())
    end)
    try("UnitGUID(\"player\")", function() return mask(UnitGUID("player")) end)
    try("RegionalUniqueNamesEnabled()", function()
        if not RegionalUniqueNamesEnabled then return "함수 없음" end
        return RegionalUniqueNamesEnabled()
    end)
    try("UnitFactionGroup(\"player\")", function() return UnitFactionGroup("player") end)
    try("UnitClass(\"player\")", function() return UnitClass("player") end)
    try("UnitRace(\"player\")", function() return UnitRace("player") end)
    try("UnitLevel / GetMaxPlayerLevel", function()
        return UnitLevel("player"), GetMaxPlayerLevel and GetMaxPlayerLevel() or "함수 없음"
    end)
end

local function secretState(prefix)
    local out = {}
    local function rec(label, fn)
        local ok, a, b = pcall(fn)
        local shown
        if not ok then
            shown = "오류:" .. tostring(a)
        elseif b == nil then
            shown = join(a)
        else
            shown = join(a, b)
        end
        out[#out + 1] = label .. "=" .. shown
    end
    rec("issecretvalue 타입", function() return type(issecretvalue) end)
    if type(issecretvalue) == "function" then
        rec("secret(UnitLevel)", function() return issecretvalue(UnitLevel("player")) end)
        rec("secret(UnitClass)", function() return issecretvalue((UnitClass("player"))) end)
        rec("secret(UnitName)", function() return issecretvalue((UnitName("player"))) end)
        rec("secret(UnitHealth)", function() return issecretvalue(UnitHealth("player")) end)
        rec("secret(GetTime)", function() return issecretvalue(GetTime()) end)
    end
    rec("C_Secrets.HasSecretRestrictions", function()
        if C_Secrets and C_Secrets.HasSecretRestrictions then return C_Secrets.HasSecretRestrictions() end
        return "함수 없음"
    end)
    rec("InCombatLockdown", function() return InCombatLockdown() end)
    rec("IsInInstance", function() return IsInInstance() end)
    return prefix .. table.concat(out, "  ")
end

local function checkRestrictions()
    section("4. 애드온 제한 (전투 밖 기준. 전투 중 결과는 맨 아래)")
    add("정보", secretState(""))
    listTypes("제한 관련 API", { "issecretvalue", "C_Secrets", "C_RestrictedActions", "C_AddOnRestrictions",
        "InCombatLockdown", "securecallfunction", "issecure", "forceinsecure" })
end

local function checkGlobals()
    section("5. 전역 함수와 라이브러리")
    listTypes("타이머·시간", { "C_Timer.After", "C_Timer.NewTicker", "C_Timer.NewTimer", "GetTime", "time", "date",
        "GetServerTime", "debugprofilestop", "GetFramerate", "GetTimePreciseSec" })
    listTypes("Lua 기본", { "math.random", "math.randomseed", "math.floor", "math.huge", "string.format", "string.rep",
        "table.concat", "table.sort", "table.wipe", "wipe", "unpack", "select", "loadstring", "setfenv", "getfenv",
        "pcall", "xpcall", "collectgarbage", "gcinfo", "bit.band", "bit.bxor", "bit.lshift", "next", "rawget",
        "setmetatable", "tostring", "tonumber", "strsplit", "strtrim", "strjoin", "strlenutf8", "tinsert", "tremove",
        "CopyTable", "Mixin", "CreateFromMixins", "format", "floor", "max", "min", "abs" })
    listTypes("애드온·설정", { "C_AddOns.GetAddOnMetadata", "C_AddOns.IsAddOnLoaded", "GetAddOnMetadata",
        "Settings.RegisterCanvasLayoutCategory", "Settings.RegisterAddOnCategory", "Settings.OpenToCategory",
        "InterfaceOptions_AddCategory", "AddonCompartmentFrame", "SlashCmdList", "StaticPopup_Show",
        "StaticPopupDialogs", "UISpecialFrames", "EventRegistry", "hooksecurefunc", "geterrorhandler",
        "C_CVar.GetCVar", "GetCVar", "ReloadUI", "C_UI.Reload" })
    listTypes("UI 도우미", { "CreateFrame", "CreateFramePool", "CreateColor", "BackdropTemplateMixin", "ScrollUtil",
        "CreateScrollBoxListLinearView", "CreateDataProvider", "GameTooltip", "GameTooltip_SetDefaultAnchor",
        "UIParent", "WorldFrame", "GetCursorPosition", "GetPhysicalScreenSize", "GetScreenWidth", "GetScreenHeight",
        "PixelUtil", "UIFrameFadeIn", "CreateTextureMarkup", "CreateAtlasMarkup" })
    listTypes("리소스", { "GetFileIDFromPath", "C_Texture.GetAtlasInfo", "C_Texture.GetFilenameFromFileDataID",
        "PlaySound", "PlaySoundFile", "SOUNDKIT", "C_Spell.GetSpellTexture", "C_Item.GetItemIconByID",
        "GetSpellInfo", "GetItemInfo", "GetSpellTexture" })
    try("C_CVar loadDeprecationFallbacks", function()
        if C_CVar and C_CVar.GetCVar then return C_CVar.GetCVar("loadDeprecationFallbacks") end
        return "함수 없음"
    end)
end

local testObjects = {}

local function checkWidgets()
    section("6. 위젯 종류, 템플릿, 메서드")
    local types = { "Frame", "Button", "CheckButton", "EditBox", "ScrollFrame", "Slider", "StatusBar", "Cooldown",
        "PlayerModel", "Model", "ModelScene", "DressUpModel", "CinematicModel", "MessageFrame", "SimpleHTML",
        "GameTooltip", "ColorSelect", "EventFrame" }
    local okTypes, badTypes = {}, {}
    for i = 1, #types do
        local t = types[i]
        local ok, obj = pcall(CreateFrame, t, nil, UIParent)
        if ok and obj then
            okTypes[#okTypes + 1] = t
            testObjects[t] = obj
            pcall(obj.Hide, obj)
        else
            badTypes[#badTypes + 1] = t
        end
    end
    add("정보", "만들 수 있는 프레임 종류: " .. table.concat(okTypes, " "))
    add(#badTypes > 0 and "주의" or "정보", "만들 수 없는 프레임 종류: " .. (#badTypes > 0 and table.concat(badTypes, " ") or "(없음)"))

    local templates = {
        { "Frame", "BackdropTemplate" }, { "Button", "UIPanelButtonTemplate" }, { "Button", "UIPanelCloseButton" },
        { "ScrollFrame", "UIPanelScrollFrameTemplate" }, { "ScrollFrame", "ScrollFrameTemplate" },
        { "EditBox", "InputBoxTemplate" }, { "Frame", "BasicFrameTemplateWithInset" }, { "Frame", "WowScrollBoxList" },
        { "EventFrame", "MinimalScrollBar" }, { "Slider", "OptionsSliderTemplate" }, { "Slider", "MinimalSliderTemplate" },
        { "CheckButton", "UICheckButtonTemplate" }, { "Frame", "TooltipBackdropTemplate" },
        { "GameTooltip", "GameTooltipTemplate" }, { "Frame", "SecureHandlerBaseTemplate" },
    }
    local okT, badT = {}, {}
    for i = 1, #templates do
        local t = templates[i]
        local ok, obj = pcall(CreateFrame, t[1], nil, UIParent, t[2])
        if ok and obj then
            okT[#okT + 1] = t[2]
            pcall(obj.Hide, obj)
        else
            badT[#badT + 1] = t[2]
        end
    end
    add("정보", "쓸 수 있는 템플릿: " .. table.concat(okT, " "))
    add(#badT > 0 and "주의" or "정보", "쓸 수 없는 템플릿: " .. (#badT > 0 and table.concat(badT, " ") or "(없음)"))

    local frame = testObjects.Frame
    methodTypes("Frame", frame, { "SetResizeBounds", "SetMinResize", "SetMaxResize", "SetResizable", "StartSizing",
        "StartMoving", "StopMovingOrSizing", "SetMovable", "SetClampedToScreen", "SetClipsChildren", "SetFrameStrata",
        "SetFrameLevel", "SetToplevel", "SetBackdrop", "SetPropagateKeyboardInput", "EnableKeyboard", "EnableMouse",
        "EnableMouseWheel", "SetScale", "SetIgnoreParentScale", "SetHitRectInsets", "SetFlattensRenderLayers",
        "CreateTexture", "CreateMaskTexture", "CreateLine", "CreateFontString", "CreateAnimationGroup",
        "SetUserPlaced", "SetAlpha", "SetShown", "RegisterForDrag", "SetMouseClickEnabled", "SetMouseMotionEnabled",
        "SetPassThroughButtons", "RegisterEvent", "RegisterUnitEvent", "HookScript", "SetAttribute", "SetID",
        "GetEffectiveScale", "SetFixedFrameStrata", "Raise", "IsMouseOver", "SetIsFrameBuffer" })

    if frame then
        local tex = frame:CreateTexture(nil, "ARTWORK")
        methodTypes("Texture", tex, { "SetColorTexture", "SetTexture", "SetAtlas", "SetGradient", "SetGradientAlpha",
            "SetTexCoord", "SetRotation", "SetBlendMode", "SetDesaturated", "SetDesaturation", "AddMaskTexture",
            "SetVertexColor", "SetSnapToPixelGrid", "SetTexelSnappingBias", "SetSpriteSheetCell", "SetHorizTile",
            "SetVertTile", "SetDrawLayer", "SetVertexOffset", "GetTexture", "GetAtlas", "SetMask", "SetScale" })
        try("Texture:SetGradient(색 객체 2개)", function()
            tex:SetColorTexture(1, 1, 1, 1)
            tex:SetGradient("VERTICAL", CreateColor(0.1, 0.1, 0.1, 1), CreateColor(0.3, 0.3, 0.3, 1))
            return "성공"
        end)
        local fs = frame:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        methodTypes("FontString", fs, { "SetFontObject", "SetFont", "SetText", "SetFormattedText", "SetWordWrap",
            "SetNonSpaceWrap", "SetMaxLines", "GetStringWidth", "GetUnboundedStringWidth", "GetStringHeight",
            "SetJustifyH", "SetJustifyV", "SetTextColor", "SetSpacing", "SetTextScale", "IsTruncated",
            "SetShadowOffset", "SetShadowColor", "SetIndentedWordWrap", "GetNumLines", "SetRotation" })
        local okAg, ag = pcall(frame.CreateAnimationGroup, frame)
        if okAg and ag then
            methodTypes("AnimationGroup", ag, { "CreateAnimation", "Play", "Stop", "SetLooping", "IsPlaying",
                "SetToFinalAlpha", "Restart", "Finish", "SetScript" })
            local kinds, okK, badK = { "Alpha", "Translation", "Scale", "Rotation", "Path", "FlipBook", "VertexColor",
                "TextureCoordTranslation", "LineTranslation", "LineScale" }, {}, {}
            for i = 1, #kinds do
                local ok = pcall(ag.CreateAnimation, ag, kinds[i])
                if ok then okK[#okK + 1] = kinds[i] else badK[#badK + 1] = kinds[i] end
            end
            add("정보", "애니메이션 종류 있음: " .. table.concat(okK, " ") .. " / 없음: "
                .. (#badK > 0 and table.concat(badK, " ") or "(없음)"))
        end
    end

    methodTypes("EditBox", testObjects.EditBox, { "SetMultiLine", "SetAutoFocus", "SetMaxLetters", "SetMaxBytes",
        "SetNumeric", "HighlightText", "SetCursorPosition", "SetTextInsets", "ClearFocus", "SetFocus", "GetText",
        "SetText", "Insert", "SetEnabled", "GetNumLetters", "SetCountInvisibleLetters" })
    methodTypes("ScrollFrame", testObjects.ScrollFrame, { "SetScrollChild", "SetVerticalScroll", "GetVerticalScroll",
        "GetVerticalScrollRange", "SetHorizontalScroll", "UpdateScrollChildRect" })
    methodTypes("StatusBar", testObjects.StatusBar, { "SetStatusBarTexture", "SetStatusBarColor", "SetMinMaxValues",
        "SetValue", "SetOrientation", "SetReverseFill", "SetFillStyle", "GetStatusBarTexture" })
    methodTypes("PlayerModel", testObjects.PlayerModel, { "SetUnit", "SetCreature", "SetDisplayInfo", "SetModel",
        "SetModelByFileID", "SetAnimation", "SetSequence", "SetSequenceTime", "FreezeAnimation", "SetPaused",
        "HasAnimation", "PlayAnimKit", "StopAnimKit", "SetCamDistanceScale", "SetPosition", "SetFacing", "SetPitch",
        "SetRoll", "SetModelScale", "SetPortraitZoom", "ClearModel", "GetModelFileID", "SetLight", "SetKeepModelOnHide",
        "SetModelAlpha", "SetDoBlend", "RefreshUnit", "SetCamera", "SetCustomCamera", "SetModelDrawLayer",
        "SetGlow", "SetDesaturation", "SetParticlesEnabled", "SetViewTranslation", "SetViewInsets", "GetDisplayInfo",
        "CanSetUnit", "SetBarberShopAlternateForm", "SetItem", "SetItemAppearance", "ApplySpellVisualKit" })
end

local function checkResources()
    section("7. 내장 아이콘과 아틀라스")
    local icons = {
        "Interface\\Icons\\INV_Misc_QuestionMark", "Interface\\Icons\\INV_Sword_04", "Interface\\Icons\\INV_Shield_04",
        "Interface\\Icons\\INV_Staff_13", "Interface\\Icons\\INV_Weapon_Bow_07", "Interface\\Icons\\INV_Misc_Gear_01",
        "Interface\\Icons\\INV_Helmet_03", "Interface\\Icons\\INV_Chest_Plate01", "Interface\\Icons\\INV_Jewelry_Ring_03",
        "Interface\\Icons\\INV_Misc_Gem_Ruby_02", "Interface\\Icons\\INV_Misc_Coin_01", "Interface\\Icons\\INV_Box_01",
        "Interface\\Icons\\Spell_Fire_Fireball02", "Interface\\Icons\\Spell_Frost_FrostBolt02",
        "Interface\\Icons\\Spell_Holy_HolyBolt", "Interface\\Icons\\Spell_Shadow_ShadowBolt",
        "Interface\\Icons\\Spell_Nature_Lightning", "Interface\\Icons\\Ability_Warrior_SavageBlow",
        "Interface\\Icons\\Ability_Rogue_Eviscerate", "Interface\\Icons\\Ability_Hunter_BeastCall",
        "Interface\\Icons\\Ability_Druid_CatForm", "Interface\\Icons\\Ability_Racial_BearForm",
        "Interface\\Icons\\ClassIcon_Warrior", "Interface\\Icons\\ClassIcon_Paladin", "Interface\\Icons\\ClassIcon_Hunter",
        "Interface\\Icons\\ClassIcon_Rogue", "Interface\\Icons\\ClassIcon_Priest", "Interface\\Icons\\ClassIcon_Shaman",
        "Interface\\Icons\\ClassIcon_Mage", "Interface\\Icons\\ClassIcon_Warlock", "Interface\\Icons\\ClassIcon_Druid",
        "Interface\\Icons\\Trade_Engineering", "Interface\\Icons\\INV_Misc_Rune_01", "Interface\\Icons\\Achievement_Boss_Ragnaros",
        "Interface\\Icons\\Achievement_Boss_Onyxia", "Interface\\Buttons\\WHITE8X8", "Interface\\Tooltips\\UI-Tooltip-Border",
        "Interface\\TargetingFrame\\UI-StatusBar", "Interface\\ChatFrame\\ChatFrameBackground",
        "Interface\\GLUES\\CHARACTERCREATE\\UI-CHARACTERCREATE-CLASSES", "Interface\\WorldStateFrame\\Icons-Classes",
        "Interface\\PVPFrame\\PVP-Currency-Alliance", "Interface\\PVPFrame\\PVP-Currency-Horde",
        "Interface\\FriendsFrame\\PlusManz-Alliance", "Interface\\FriendsFrame\\PlusManz-Horde",
    }
    if type(GetFileIDFromPath) == "function" then
        local okI, badI = {}, {}
        for i = 1, #icons do
            local ok, id = pcall(GetFileIDFromPath, icons[i])
            local short = icons[i]:match("[^\\]+$") or icons[i]
            if ok and id then okI[#okI + 1] = short .. "=" .. tostring(id) else badI[#badI + 1] = short end
        end
        add("정보", "경로가 해석된 텍스처 " .. #okI .. "개: " .. table.concat(okI, " "))
        add(#badI > 0 and "주의" or "정보", "해석되지 않은 텍스처 " .. #badI .. "개: " .. (#badI > 0 and table.concat(badI, " ") or "(없음)"))
    else
        add("주의", "GetFileIDFromPath 없음. 아래 화면의 아이콘 줄을 눈으로 확인해야 함")
    end
    local atlases = { "classicon-warrior", "classicon-paladin", "classicon-hunter", "classicon-rogue", "classicon-priest",
        "classicon-shaman", "classicon-mage", "classicon-warlock", "classicon-druid", "ui-hud-minimap-addon-indicator",
        "common-icon-checkmark", "common-icon-redx", "Padlock", "UI-HUD-ActionBar-IconFrame", "bags-icon-addslots",
        "AllianceEmblem", "HordeEmblem", "groupfinder-icon-role-large-tank", "groupfinder-icon-role-large-heal",
        "groupfinder-icon-role-large-dps", "UI-Frame-Bar-Fill-Blue", "auctionhouse-icon-favorite" }
    if C_Texture and C_Texture.GetAtlasInfo then
        local okA, badA = {}, {}
        for i = 1, #atlases do
            local ok, info = pcall(C_Texture.GetAtlasInfo, atlases[i])
            if ok and info then okA[#okA + 1] = atlases[i] else badA[#badA + 1] = atlases[i] end
        end
        add("정보", "있는 아틀라스: " .. (#okA > 0 and table.concat(okA, " ") or "(없음)"))
        add("정보", "없는 아틀라스: " .. (#badA > 0 and table.concat(badA, " ") or "(없음)"))
    else
        add("주의", "C_Texture.GetAtlasInfo 없음")
    end
end

local function checkCustomTextures()
    section("8. 애드온에 포함한 텍스처 (창 아래쪽 그림도 확인)")
    local base = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\"
    local files = { "test256.tga", "test300x200.tga", "test256.png", "test256" }
    for i = 1, #files do
        try("SetTexture(" .. files[i] .. ")", function()
            local tex = UIParent:CreateTexture(nil, "BACKGROUND")
            tex:SetSize(1, 1)
            local ret = tex:SetTexture(base .. files[i])
            local got = tex:GetTexture()
            tex:Hide()
            return ret, got
        end)
    end
end

local function checkTime()
    section("9. 시간")
    try("time()", function() return time() end)
    try("GetServerTime()", function() return GetServerTime() end)
    try("GetTime()", function() return GetTime() end)
    try("date()", function() return date("%Y-%m-%d %H:%M:%S") end)
    try("debugprofilestop()", function() return debugprofilestop() end)
end

local function checkSavedVariables()
    section("10. 저장 (SavedVariables)")
    local db = WIH_EnvCheckDB
    if type(db) ~= "table" then
        add("오류", "WIH_EnvCheckDB가 테이블이 아님: " .. type(db))
        return
    end
    add("정보", "계정 저장: 불러온 횟수=" .. tostring(db.loads) .. " 점검 실행 횟수=" .. tostring(db.runs)
        .. " 처음 불러온 시각=" .. tostring(db.firstLoad) .. " 직전 로그아웃 저장 시각=" .. tostring(db.lastLogout)
        .. " 직전 세션 시작 시각=" .. tostring(db.prevSessionStart))
    if db.loads and db.loads >= 2 then
        add("OK", "불러온 횟수가 2 이상이므로 /reload 또는 재접속 뒤에도 값이 유지됨")
    else
        add("정보", "아직 첫 실행. /reload 한 뒤 다시 점검하면 유지 여부를 알 수 있음")
    end
    if db.lastLogout and db.prevSessionStart and db.lastLogout >= db.prevSessionStart then
        add("OK", "PLAYER_LOGOUT 때 기록한 값이 저장됨 (종료 시점 저장 동작)")
    end
    local cdb = WIH_EnvCheckCharDB
    add("정보", "캐릭터별 저장: " .. (type(cdb) == "table" and ("불러온 횟수=" .. tostring(cdb.loads)) or ("타입 " .. type(cdb))))
    try("큰 문자열과 깊은 테이블 저장 준비", function()
        db.blob = string.rep("x", 100000)
        db.nested = { a = { b = { c = { d = { 1, 2, 3 } } } }, list = {} }
        for i = 1, 2000 do db.nested.list[i] = { id = i, v = i * 1.5, s = "item" .. i } end
        return "10만 글자 문자열과 2000개 항목 테이블을 넣음. /reload 뒤 '저장 왕복' 줄 확인"
    end)
    if db.blobCheck then
        add("OK", "저장 왕복: " .. tostring(db.blobCheck))
    end
end

local function checkPerformance()
    section("11. 계산 성능 (전투 시뮬레이션 예산 추정)")
    try("산술 100만 회", function()
        local t0 = now()
        local s = 0
        for i = 1, 1000000 do s = s + (i % 7) * 0.5 end
        return string.format("%.1f ms", now() - t0)
    end)
    try("테이블 접근 20만 회", function()
        local t = {}
        for i = 1, 200 do t[i] = { hp = 100, atk = 5, x = i } end
        local t0 = now()
        local s = 0
        for n = 1, 1000 do
            for i = 1, 200 do
                local u = t[i]
                u.hp = u.hp - 1
                if u.hp <= 0 then u.hp = 100 end
                s = s + u.atk
            end
        end
        return string.format("%.1f ms", now() - t0)
    end)
    try("함수 호출 50만 회", function()
        local function f(a, b) return a * b + 1 end
        local t0 = now()
        local s = 0
        for i = 1, 500000 do s = f(i, 2) end
        return string.format("%.1f ms", now() - t0)
    end)
    try("GetFramerate()", function() return GetFramerate() end)
    try("메모리(KB)", function() return collectgarbage("count") end)
end

local function checkSound()
    section("12. 소리")
    try("PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON)", function()
        if not SOUNDKIT then return "SOUNDKIT 없음" end
        return PlaySound(SOUNDKIT.IG_MAINMENU_OPTION_CHECKBOX_ON, "SFX")
    end)
end

local function checkSettingsPanel()
    section("13. 설정 패널 등록")
    try("Settings.RegisterCanvasLayoutCategory", function()
        if not (Settings and Settings.RegisterCanvasLayoutCategory) then return "Settings API 없음" end
        if ui.settingsCategory then return "이미 등록됨" end
        local panel = CreateFrame("Frame")
        local fs = panel:CreateFontString(nil, "OVERLAY", "GameFontNormal")
        fs:SetPoint("TOPLEFT", 16, -16)
        fs:SetText("W.I.H 환경 점검: /wihcheck")
        local category = Settings.RegisterCanvasLayoutCategory(panel, "W.I.H 환경 점검")
        Settings.RegisterAddOnCategory(category)
        ui.settingsCategory = category
        return "등록 성공", category and category.GetID and category:GetID() or "ID 없음"
    end)
end

------------------------------------------------------------------------
-- 전투 중 점검
------------------------------------------------------------------------

local function runCombatCheck(reason)
    combatLines = {}
    local function cadd(text) combatLines[#combatLines + 1] = "[전투] " .. text end
    cadd("시점: " .. reason .. "  " .. secretState(""))
    local probe = ui.combatProbe
    if not probe then
        local ok, f = pcall(CreateFrame, "Frame", nil, UIParent)
        if ok then
            probe = f
            probe:SetSize(10, 10)
            probe:SetPoint("TOPLEFT", UIParent, "TOPLEFT", -100, 100)
            ui.combatProbe = probe
        end
    end
    local function attempt(label, fn)
        local before = #blockedEvents
        local ok, err = pcall(fn)
        local blocked = #blockedEvents > before
        cadd(label .. ": " .. (ok and "오류 없음" or ("Lua 오류 " .. tostring(err))) .. (blocked and " / 차단 이벤트 발생" or ""))
    end
    if probe then
        attempt("일반 프레임 Show", function() probe:Show() end)
        attempt("일반 프레임 Hide", function() probe:Hide() end)
        attempt("일반 프레임 SetPoint", function() probe:ClearAllPoints(); probe:SetPoint("CENTER", UIParent, "CENTER", 0, 300) end)
        attempt("일반 프레임 SetSize", function() probe:SetSize(20, 20) end)
        attempt("일반 프레임 EnableMouse", function() probe:EnableMouse(true); probe:EnableMouse(false) end)
        attempt("일반 프레임 EnableKeyboard", function() probe:EnableKeyboard(true); probe:EnableKeyboard(false) end)
        attempt("SetPropagateKeyboardInput", function() probe:EnableKeyboard(true); probe:SetPropagateKeyboardInput(true); probe:EnableKeyboard(false) end)
        attempt("새 프레임 만들기", function() local f = CreateFrame("Frame", nil, UIParent); f:Hide() end)
        attempt("새 PlayerModel 만들기", function() local m = CreateFrame("PlayerModel", nil, UIParent); m:SetSize(10, 10); m:Hide() end)
    end
    if ui.frame then
        attempt("점검 창 Show/Hide", function()
            local shown = ui.frame:IsShown()
            ui.frame:Hide(); ui.frame:Show()
            if not shown then ui.frame:Hide() end
        end)
    end
    cadd("차단 이벤트 누적 " .. #blockedEvents .. "건" .. (#blockedEvents > 0 and (": " .. table.concat(blockedEvents, " | ")) or ""))
    if type(WIH_EnvCheckDB) == "table" then
        WIH_EnvCheckDB.lastCombat = combatLines
    end
end

------------------------------------------------------------------------
-- 창
------------------------------------------------------------------------

local function makeButton(parent, text, width, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, 22)
    local bg = b:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.20, 0.21, 0.23, 1)
    b.bg = bg
    local fs = b:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    fs:SetPoint("CENTER")
    fs:SetText(text)
    b.label = fs
    b:SetScript("OnEnter", function(self) self.bg:SetColorTexture(0.30, 0.31, 0.34, 1) end)
    b:SetScript("OnLeave", function(self) self.bg:SetColorTexture(0.20, 0.21, 0.23, 1) end)
    b:SetScript("OnClick", function() local ok, err = pcall(onClick); if not ok then print("|cffff6060W.I.H 점검 오류:|r " .. tostring(err)) end end)
    return b
end

local MODEL_TESTS = {
    { label = "플레이어", fn = function(m) m:SetUnit("player") end },
    { label = "생물 11502", fn = function(m) m:SetCreature(11502) end },   -- 라그나로스
    { label = "생물 10184", fn = function(m) m:SetCreature(10184) end },   -- 오닉시아
    { label = "생물 3098",  fn = function(m) m:SetCreature(3098) end },    -- 얼룩무늬 멧돼지
    { label = "표시 11121", fn = function(m) m:SetDisplayInfo(11121) end },
    { label = "표시 8570",  fn = function(m) m:SetDisplayInfo(8570) end },
    { label = "표시 503",   fn = function(m) m:SetDisplayInfo(503) end },
    { label = "표시 4449",  fn = function(m) m:SetDisplayInfo(4449) end },
}

local ANIMS = { 0, 4, 5, 16, 17, 18, 26, 51, 52, 53, 54, 8, 1, 6, 60, 69, 113 }

local function buildModels()
    if ui.models then return end
    ui.models = {}
    local strip = ui.strip
    for i = 1, #MODEL_TESTS do
        local ok, m = pcall(CreateFrame, "PlayerModel", nil, strip)
        if ok and m then
            m:SetSize(88, 110)
            m:SetPoint("TOPLEFT", strip, "TOPLEFT", (i - 1) * 92 + 4, -22)
            local bg = strip:CreateTexture(nil, "BACKGROUND")
            bg:SetPoint("TOPLEFT", m, "TOPLEFT")
            bg:SetPoint("BOTTOMRIGHT", m, "BOTTOMRIGHT")
            bg:SetColorTexture(0.13, 0.13, 0.15, 1)
            local fs = strip:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
            fs:SetPoint("TOP", m, "BOTTOM", 0, -2)
            fs:SetText(MODEL_TESTS[i].label)
            local okSet, err = pcall(MODEL_TESTS[i].fn, m)
            ui.models[i] = { frame = m, setOk = okSet, err = err, label = MODEL_TESTS[i].label }
        else
            ui.models[i] = { frame = nil, setOk = false, err = "PlayerModel 생성 실패", label = MODEL_TESTS[i].label }
        end
    end
end

local function reportModels()
    section("14. 모델 표시 (창 아래쪽에 보이는지 눈으로도 확인)")
    if not ui.models then
        add("정보", "아직 모델 시험을 실행하지 않음. '모델 시험' 버튼을 누른 뒤 2초 기다리고 '다시 점검'")
        return
    end
    for i = 1, #ui.models do
        local e = ui.models[i]
        local fileID, display = "?", "?"
        if e.frame then
            local ok1, v1 = pcall(function() return e.frame:GetModelFileID() end)
            if ok1 then fileID = tostring(v1) end
            local ok2, v2 = pcall(function() return e.frame:GetDisplayInfo() end)
            if ok2 then display = tostring(v2) end
        end
        add(e.setOk and "정보" or "오류", e.label .. ": 설정 " .. (e.setOk and "성공" or ("실패 " .. tostring(e.err)))
            .. " / 모델 파일 ID=" .. fileID .. " / 표시 ID=" .. display)
    end
    if ui.animIndex then
        add("정보", "현재 동작 번호 = " .. tostring(ANIMS[ui.animIndex]) .. " (버튼을 누를 때마다 다음 번호. 동작이 실제로 바뀌는지 눈으로 확인)")
    end
    if ui.modelStress then
        add("정보", "모델 " .. ui.modelStress.count .. "개 동시 표시 때 프레임율 = " .. tostring(ui.modelStress.fps)
            .. " (시험 전 " .. tostring(ui.modelStress.before) .. ")")
    end
end

local cachedLocale = cached("locale", checkLocaleAndFonts)
local cachedGlobals = cached("globals", checkGlobals)
local cachedWidgets = cached("widgets", checkWidgets)
local cachedResources = cached("resources", checkResources)
local cachedTextures = cached("textures", checkCustomTextures)

local function runAll()
    lines = {}
    lines[#lines + 1] = "W.I.H 환경 점검 결과 — 이 글 전체를 복사해 전달해 주세요. (글 상자를 누르고 Ctrl+A, Ctrl+C)"
    local steps = { checkBuild, cachedLocale, checkPlayer, checkRestrictions, cachedGlobals, cachedWidgets,
        cachedResources, cachedTextures, checkTime, checkSavedVariables, checkPerformance, checkSound,
        checkSettingsPanel, reportModels }
    for i = 1, #steps do
        local ok, err = pcall(steps[i])
        if not ok then add("오류", "점검 단계 " .. i .. " 중단: " .. tostring(err)) end
    end
    section("15. 전투 중 점검")
    local saved = (type(WIH_EnvCheckDB) == "table" and WIH_EnvCheckDB.lastCombat) or combatLines
    if saved and #saved > 0 then
        for i = 1, #saved do lines[#lines + 1] = saved[i] end
    else
        lines[#lines + 1] = "[정보] 아직 전투 중 점검 기록이 없음. 아무 몬스터와 전투를 시작하면 자동으로 기록됨. 전투가 끝난 뒤 '다시 점검'"
    end
    section("16. 차단 이벤트")
    lines[#lines + 1] = "[정보] 누적 " .. #blockedEvents .. "건" .. (#blockedEvents > 0 and (": " .. table.concat(blockedEvents, " | ")) or "")
    if type(WIH_EnvCheckDB) == "table" then
        WIH_EnvCheckDB.runs = (WIH_EnvCheckDB.runs or 0) + 1
        WIH_EnvCheckDB.lastReport = lines
    end
    if ui.edit then
        ui.edit:SetText(table.concat(lines, "\n"))
        ui.edit:SetCursorPosition(0)
    end
    if ui.scroll then
        pcall(ui.scroll.UpdateScrollChildRect, ui.scroll)
        ui.scroll:SetVerticalScroll(0)
    end
end

local function buildWindow()
    if ui.frame then return ui.frame end
    local f = CreateFrame("Frame", "WIH_EnvCheckFrame", UIParent)
    ui.frame = f
    f:SetSize(780, 620)
    f:SetPoint("CENTER")
    f:SetFrameStrata("DIALOG")
    f:SetMovable(true)
    f:EnableMouse(true)
    f:SetClampedToScreen(true)
    f:RegisterForDrag("LeftButton")
    f:SetScript("OnDragStart", function(self) self:StartMoving() end)
    f:SetScript("OnDragStop", function(self) self:StopMovingOrSizing() end)
    local bg = f:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints()
    bg:SetColorTexture(0.07, 0.07, 0.08, 0.97)
    local top = f:CreateTexture(nil, "BORDER")
    top:SetPoint("TOPLEFT")
    top:SetPoint("TOPRIGHT")
    top:SetHeight(30)
    top:SetColorTexture(0.12, 0.12, 0.14, 1)
    local title = f:CreateFontString(nil, "OVERLAY", "GameFontNormal")
    title:SetPoint("TOPLEFT", 12, -9)
    title:SetText("W.I.H 환경 점검")
    title:SetTextColor(0.92, 0.92, 0.92)

    local close = makeButton(f, "닫기", 54, function() f:Hide() end)
    close:SetPoint("TOPRIGHT", -6, -4)
    local rerun = makeButton(f, "다시 점검", 76, runAll)
    rerun:SetPoint("RIGHT", close, "LEFT", -6, 0)
    local modelBtn = makeButton(f, "모델 시험", 76, function()
        buildModels()
        if C_Timer and C_Timer.After then C_Timer.After(2, runAll) end
    end)
    modelBtn:SetPoint("RIGHT", rerun, "LEFT", -6, 0)
    local animBtn = makeButton(f, "동작 바꾸기", 86, function()
        if not ui.models then buildModels() end
        ui.animIndex = (ui.animIndex or 0) % #ANIMS + 1
        local id = ANIMS[ui.animIndex]
        for i = 1, #ui.models do
            local m = ui.models[i].frame
            if m and m.SetAnimation then pcall(m.SetAnimation, m, id) end
        end
        if ui.animLabel then ui.animLabel:SetText("동작 번호 " .. id) end
    end)
    animBtn:SetPoint("RIGHT", modelBtn, "LEFT", -6, 0)
    local stressBtn = makeButton(f, "모델 16개 부하", 100, function()
        local before = GetFramerate and GetFramerate() or 0
        ui.stressModels = ui.stressModels or {}
        for i = #ui.stressModels + 1, 16 do
            local ok, m = pcall(CreateFrame, "PlayerModel", nil, f)
            if ok and m then
                m:SetSize(44, 56)
                m:SetPoint("BOTTOMLEFT", f, "BOTTOMLEFT", 6 + (i - 1) * 47, 150)
                pcall(m.SetUnit, m, "player")
                ui.stressModels[i] = m
            end
        end
        if C_Timer and C_Timer.After then
            C_Timer.After(3, function()
                ui.modelStress = { count = #ui.stressModels, fps = GetFramerate and GetFramerate() or 0, before = before }
                runAll()
            end)
        end
    end)
    stressBtn:SetPoint("RIGHT", animBtn, "LEFT", -6, 0)

    -- 결과 글 상자 (템플릿 없이 직접 구성)
    local scroll = CreateFrame("ScrollFrame", nil, f)
    ui.scroll = scroll
    scroll:SetPoint("TOPLEFT", 10, -38)
    scroll:SetPoint("BOTTOMRIGHT", -10, 216)
    local sbg = f:CreateTexture(nil, "BORDER")
    sbg:SetPoint("TOPLEFT", scroll, "TOPLEFT", -4, 4)
    sbg:SetPoint("BOTTOMRIGHT", scroll, "BOTTOMRIGHT", 4, -4)
    sbg:SetColorTexture(0.04, 0.04, 0.05, 1)
    local edit = CreateFrame("EditBox", nil, scroll)
    ui.edit = edit
    edit:SetMultiLine(true)
    edit:SetAutoFocus(false)
    edit:SetFontObject(GameFontHighlightSmall or GameFontNormal)
    edit:SetWidth(750)
    edit:SetScript("OnEscapePressed", function(self) self:ClearFocus() end)
    scroll:SetScrollChild(edit)
    scroll:EnableMouseWheel(true)
    scroll:SetScript("OnMouseWheel", function(self, delta)
        local range = self:GetVerticalScrollRange() or 0
        local pos = (self:GetVerticalScroll() or 0) - delta * 60
        if pos < 0 then pos = 0 elseif pos > range then pos = range end
        self:SetVerticalScroll(pos)
    end)

    -- 아래 띠: 모델과 텍스처 시험
    local strip = CreateFrame("Frame", nil, f)
    ui.strip = strip
    strip:SetPoint("BOTTOMLEFT", 10, 8)
    strip:SetPoint("BOTTOMRIGHT", -10, 8)
    strip:SetHeight(140)
    local stripLabel = strip:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
    stripLabel:SetPoint("TOPLEFT", 4, -4)
    stripLabel:SetText("모델 시험 칸 ('모델 시험'을 누르면 채워짐)")
    ui.animLabel = strip:CreateFontString(nil, "OVERLAY", "GameFontHighlightSmall")
    ui.animLabel:SetPoint("TOPRIGHT", -4, -4)
    ui.animLabel:SetText("")

    local texRow = CreateFrame("Frame", nil, f)
    texRow:SetPoint("BOTTOMLEFT", strip, "TOPLEFT", 0, 4)
    texRow:SetPoint("BOTTOMRIGHT", strip, "TOPRIGHT", 0, 4)
    texRow:SetHeight(58)
    local base = "Interface\\AddOns\\" .. ADDON_NAME .. "\\Media\\"
    local samples = {
        { "TGA 256", base .. "test256.tga" }, { "TGA 300x200", base .. "test300x200.tga" },
        { "PNG 256", base .. "test256.png" }, { "물음표", "Interface\\Icons\\INV_Misc_QuestionMark" },
        { "검", "Interface\\Icons\\INV_Sword_04" }, { "화염구", "Interface\\Icons\\Spell_Fire_Fireball02" },
        { "전사", "Interface\\Icons\\ClassIcon_Warrior" }, { "기계공학", "Interface\\Icons\\Trade_Engineering" },
        { "라그나로스", "Interface\\Icons\\Achievement_Boss_Ragnaros" },
    }
    for i = 1, #samples do
        local tex = texRow:CreateTexture(nil, "ARTWORK")
        tex:SetSize(40, 40)
        tex:SetPoint("TOPLEFT", (i - 1) * 84 + 4, 0)
        pcall(tex.SetTexture, tex, samples[i][2])
        local fs = texRow:CreateFontString(nil, "OVERLAY", "GameFontDisableSmall")
        fs:SetPoint("TOPLEFT", tex, "BOTTOMLEFT", 0, -2)
        fs:SetText(samples[i][1])
    end
    f:Hide()
    return f
end

local function toggle()
    local f = buildWindow()
    if f:IsShown() then
        f:Hide()
    else
        f:Show()
        runAll()
    end
end

function WIH_EnvCheck_OnCompartmentClick()
    local ok, err = pcall(toggle)
    if not ok then print("|cffff6060W.I.H 점검 오류:|r " .. tostring(err)) end
end

SLASH_WIHCHECK1 = "/wihcheck"
SlashCmdList = SlashCmdList or {}
SlashCmdList["WIHCHECK"] = function()
    local ok, err = pcall(toggle)
    if not ok then print("|cffff6060W.I.H 점검 오류:|r " .. tostring(err)) end
end

------------------------------------------------------------------------
-- 이벤트
------------------------------------------------------------------------

local events = CreateFrame("Frame")
local wanted = { "ADDON_LOADED", "PLAYER_LOGIN", "PLAYER_LOGOUT", "PLAYER_REGEN_DISABLED", "PLAYER_REGEN_ENABLED",
    "ADDON_ACTION_BLOCKED", "ADDON_ACTION_FORBIDDEN" }
for i = 1, #wanted do
    pcall(events.RegisterEvent, events, wanted[i])
end

events:SetScript("OnEvent", function(_, event, arg1, arg2)
    if event == "ADDON_LOADED" then
        if arg1 ~= ADDON_NAME then return end
        if type(WIH_EnvCheckDB) ~= "table" then WIH_EnvCheckDB = {} end
        if type(WIH_EnvCheckCharDB) ~= "table" then WIH_EnvCheckCharDB = {} end
        local db = WIH_EnvCheckDB
        db.loads = (db.loads or 0) + 1
        db.firstLoad = db.firstLoad or time()
        db.prevSessionStart = db.sessionStart
        db.sessionStart = time()
        WIH_EnvCheckCharDB.loads = (WIH_EnvCheckCharDB.loads or 0) + 1
        -- 직전 세션에서 넣어 둔 큰 데이터가 그대로 돌아왔는지 확인
        if type(db.blob) == "string" and type(db.nested) == "table" then
            local okList = type(db.nested.list) == "table" and #db.nested.list == 2000
            local deep = db.nested.a and db.nested.a.b and db.nested.a.b.c and db.nested.a.b.c.d
            db.blobCheck = "문자열 길이=" .. #db.blob .. " 목록 2000개=" .. tostring(okList)
                .. " 깊은 값=" .. tostring(deep and deep[3]) .. " 소수 값=" .. tostring(okList and db.nested.list[3].v)
        end
        db.blob, db.nested = nil, nil
    elseif event == "PLAYER_LOGIN" then
        print("|cffc0c0c0W.I.H 환경 점검|r: /wihcheck 를 입력하면 점검 창이 열립니다.")
    elseif event == "PLAYER_LOGOUT" then
        if type(WIH_EnvCheckDB) == "table" then
            WIH_EnvCheckDB.lastLogout = time()
        end
    elseif event == "PLAYER_REGEN_DISABLED" then
        local ok, err = pcall(runCombatCheck, "전투 시작")
        if not ok then
            combatLines[#combatLines + 1] = "[전투] 점검 중 오류: " .. tostring(err)
            if type(WIH_EnvCheckDB) == "table" then WIH_EnvCheckDB.lastCombat = combatLines end
        end
    elseif event == "PLAYER_REGEN_ENABLED" then
        -- 전투가 끝난 직후의 상태도 한 줄 남긴다.
        combatLines[#combatLines + 1] = "[전투] 전투 종료 직후: " .. secretState("")
        if type(WIH_EnvCheckDB) == "table" then WIH_EnvCheckDB.lastCombat = combatLines end
    elseif event == "ADDON_ACTION_BLOCKED" or event == "ADDON_ACTION_FORBIDDEN" then
        blockedEvents[#blockedEvents + 1] = event .. ":" .. tostring(arg1) .. ":" .. tostring(arg2)
    end
end)
