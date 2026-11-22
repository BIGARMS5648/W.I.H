-- 화면의 색, 글꼴, 간격과 기본 부품.
-- 방향: 어두운 무채색 바탕, 얇은 선, 절제된 강조색. 색은 의미가 있는 곳(진영, 등급, 위험)에만 쓴다.
-- 게임 내 확인(2026-11-22): SetColorTexture, 글꼴 객체 상속, SetResizeBounds 사용 가능. SetBackdrop은 쓰지 않는다.
-- 배치 규칙: 폭을 늘이는 두 번째 기준점은 첫 기준점과 세로 기준이 같은 것만 쓴다
--   (TOPLEFT + TOPRIGHT, LEFT + RIGHT, BOTTOMLEFT + BOTTOMRIGHT, 또는 TOPLEFT + BOTTOMRIGHT).
--   TOPLEFT + RIGHT처럼 섞으면 "위"와 "세로 가운데"가 함께 정해져 높이가 뜻하지 않게 늘어난다.

local _, WIH = ...
local UI = WIH.module("UI")

-- 색은 시안(docs/design/mockups/ui-01-strip-and-menu.png)의 값이다.
UI.C = {
    bg     = { 0.071, 0.075, 0.086 },    -- 창 바탕
    panel  = { 0.098, 0.106, 0.122 },    -- 패널
    raised = { 0.129, 0.141, 0.161 },    -- 버튼, 선택된 줄
    hover  = { 0.165, 0.176, 0.200 },
    press  = { 0.200, 0.212, 0.240 },
    well   = { 0.082, 0.090, 0.102 },    -- 아이콘 칸의 바탕
    line   = { 0.180, 0.192, 0.220 },    -- 얇은 선
    line2  = { 0.227, 0.243, 0.275 },    -- 조금 밝은 선(아이콘 칸, 버튼)
    text   = { 0.910, 0.914, 0.925 },
    sub    = { 0.616, 0.635, 0.667 },
    dim    = { 0.400, 0.420, 0.455 },
    good   = { 0.435, 0.690, 0.498 },
    bad    = { 0.812, 0.373, 0.345 },
    warn   = { 0.824, 0.651, 0.353 },
    shield = { 0.561, 0.698, 0.859 },
    exp    = { 0.541, 0.518, 0.769 },
    Alliance = { 0.365, 0.518, 0.722 },
    Horde    = { 0.706, 0.282, 0.247 },
}

UI.ELEMENT_COLORS = {
    Physical = { 0.86, 0.86, 0.86 }, Fire = { 0.92, 0.50, 0.30 }, Cold = { 0.50, 0.74, 0.92 },
    Lightning = { 0.92, 0.84, 0.44 }, Chaos = { 0.66, 0.48, 0.84 },
}

UI.CLASS_ICONS = {
    WARRIOR = "Interface\\Icons\\ClassIcon_Warrior", PALADIN = "Interface\\Icons\\ClassIcon_Paladin",
    HUNTER = "Interface\\Icons\\ClassIcon_Hunter", ROGUE = "Interface\\Icons\\ClassIcon_Rogue",
    PRIEST = "Interface\\Icons\\ClassIcon_Priest", SHAMAN = "Interface\\Icons\\ClassIcon_Shaman",
    MAGE = "Interface\\Icons\\ClassIcon_Mage", WARLOCK = "Interface\\Icons\\ClassIcon_Warlock",
    DRUID = "Interface\\Icons\\ClassIcon_Druid", TINKER = "Interface\\Icons\\Trade_Engineering",
}
UI.FALLBACK_ICON = "Interface\\Icons\\INV_Misc_QuestionMark"

function UI.accent()
    local faction = WIH.App and WIH.App.state and WIH.App.state.faction
    return UI.C[faction or "Alliance"] or UI.C.Alliance
end

local function rgb(c, a) return c[1], c[2], c[3], a or 1 end
UI.rgb = rgb

-- 단색 사각형
function UI.fill(parent, color, layer, alpha)
    local t = parent:CreateTexture(nil, layer or "BACKGROUND")
    t:SetColorTexture(rgb(color, alpha))
    return t
end

-- 1픽셀 테두리 네 변
function UI.border(frame, color, alpha)
    local edges = {}
    for i = 1, 4 do
        edges[i] = frame:CreateTexture(nil, "BORDER")
        edges[i]:SetColorTexture(rgb(color or UI.C.line, alpha))
    end
    edges[1]:SetPoint("TOPLEFT"); edges[1]:SetPoint("TOPRIGHT"); edges[1]:SetHeight(1)
    edges[2]:SetPoint("BOTTOMLEFT"); edges[2]:SetPoint("BOTTOMRIGHT"); edges[2]:SetHeight(1)
    edges[3]:SetPoint("TOPLEFT"); edges[3]:SetPoint("BOTTOMLEFT"); edges[3]:SetWidth(1)
    edges[4]:SetPoint("TOPRIGHT"); edges[4]:SetPoint("BOTTOMRIGHT"); edges[4]:SetWidth(1)
    frame.edges = edges
    return edges
end

function UI.setBorderColor(frame, color, alpha)
    if not frame.edges then return end
    for i = 1, 4 do frame.edges[i]:SetColorTexture(rgb(color, alpha)) end
end

-- 바탕이 있는 프레임
function UI.panel(parent, color, withBorder)
    local f = CreateFrame("Frame", nil, parent)
    f.bg = UI.fill(f, color or UI.C.panel)
    f.bg:SetAllPoints()
    if withBorder then UI.border(f) end
    return f
end

-- 글자. size를 주면 한국어 기본 글꼴 파일로 크기를 정한다.
function UI.text(parent, size, color, justify)
    local fs = parent:CreateFontString(nil, "OVERLAY", "GameFontHighlight")
    if size then
        local font = STANDARD_TEXT_FONT or "Fonts\\2002.TTF"
        fs:SetFont(font, size, "")
    end
    fs:SetTextColor(rgb(color or UI.C.text))
    fs:SetJustifyH(justify or "LEFT")
    if fs.SetWordWrap then fs:SetWordWrap(false) end
    return fs
end

-- 여러 줄 글자
function UI.paragraph(parent, size, color, width)
    local fs = UI.text(parent, size, color)
    if fs.SetWordWrap then fs:SetWordWrap(true) end
    if fs.SetNonSpaceWrap then fs:SetNonSpaceWrap(true) end
    fs:SetJustifyV("TOP")
    if width then fs:SetWidth(width) end
    return fs
end

-- 아이콘. 경로가 해석되지 않으면 물음표 아이콘을 쓴다.
function UI.iconPath(name)
    if not name then return UI.FALLBACK_ICON end
    local path = name
    if not name:find("\\", 1, true) then path = "Interface\\Icons\\" .. name end
    if GetFileIDFromPath and not GetFileIDFromPath(path) then return UI.FALLBACK_ICON end
    return path
end

function UI.icon(parent, size, name)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(size, size)
    f.tex = f:CreateTexture(nil, "ARTWORK")
    f.tex:SetPoint("TOPLEFT", 1, -1)
    f.tex:SetPoint("BOTTOMRIGHT", -1, 1)
    f.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    UI.border(f)
    function f:set(iconName)
        self.tex:SetTexture(UI.iconPath(iconName))
    end
    f:set(name)
    return f
end

-- 버튼. 상태: 보통, 올림, 누름, 선택, 사용 불가
function UI.button(parent, label, width, height, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width or 80, height or 24)
    b.bg = UI.fill(b, UI.C.raised)
    b.bg:SetAllPoints()
    UI.border(b)
    b.label = UI.text(b, 12, UI.C.text, "CENTER")
    b.label:SetPoint("CENTER")
    b.label:SetText(label or "")
    b.enabled, b.selected, b.over, b.down = true, false, false, false
    function b:paint()
        if not self.enabled then
            self.bg:SetColorTexture(rgb(UI.C.panel))
            self.label:SetTextColor(rgb(UI.C.dim))
            UI.setBorderColor(self, UI.C.line, 0.5)
        elseif self.selected then
            local a = UI.accent()
            self.bg:SetColorTexture(a[1] * 0.45, a[2] * 0.45, a[3] * 0.45, 1)
            self.label:SetTextColor(rgb(UI.C.text))
            UI.setBorderColor(self, a)
        else
            local c = self.down and UI.C.press or (self.over and UI.C.hover or UI.C.raised)
            self.bg:SetColorTexture(rgb(c))
            self.label:SetTextColor(rgb(UI.C.text))
            UI.setBorderColor(self, UI.C.line)
        end
    end
    function b:setEnabled(v) self.enabled = v and true or false; self:paint() end
    function b:setSelected(v) self.selected = v and true or false; self:paint() end
    function b:setText(t) self.label:SetText(t or "") end
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnEnter", function(self)
        self.over = true
        self:paint()
        if self.tooltip then UI.showTooltip(self, self.tooltip) end
    end)
    b:SetScript("OnLeave", function(self)
        self.over, self.down = false, false
        self:paint()
        UI.hideTooltip()
    end)
    b:SetScript("OnMouseDown", function(self) self.down = true; self:paint() end)
    b:SetScript("OnMouseUp", function(self) self.down = false; self:paint() end)
    b:SetScript("OnClick", function(self, mouseButton)
        if not self.enabled then return end
        if self.onClick then
            local ok, err = pcall(self.onClick, self, mouseButton)
            if not ok then UI.reportError(err) end
        end
    end)
    b.onClick = onClick
    b:paint()
    return b
end

-- 막대(체력, 경험치 등)
function UI.bar(parent, width, height, color)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(width, height)
    f.bg = UI.fill(f, UI.C.bg)
    f.bg:SetAllPoints()
    f.fill = UI.fill(f, color or UI.C.good, "ARTWORK")
    f.fill:SetPoint("TOPLEFT")
    f.fill:SetPoint("BOTTOMLEFT")
    f.fill:SetWidth(1)
    f.over = UI.fill(f, UI.C.shield, "OVERLAY", 0.85)
    f.over:SetPoint("TOPLEFT")
    f.over:SetHeight(math.max(2, math.floor(height * 0.35)))
    f.over:Hide()
    UI.border(f, UI.C.line, 0.8)
    function f:set(ratio, overRatio)
        local w = self:GetWidth()
        if not w or w <= 0 then w = width end
        if ratio ~= ratio or ratio < 0 then ratio = 0 elseif ratio > 1 then ratio = 1 end
        if ratio <= 0 then self.fill:Hide() else self.fill:Show(); self.fill:SetWidth(math.max(1, w * ratio)) end
        if overRatio and overRatio > 0 then
            if overRatio > 1 then overRatio = 1 end
            self.over:Show()
            self.over:SetWidth(math.max(1, w * overRatio))
        else
            self.over:Hide()
        end
    end
    function f:setColor(c) self.fill:SetColorTexture(rgb(c)) end
    f:set(0)
    return f
end

-- 세로로 스크롤되는 영역. content에 내용을 붙이고 setHeight로 내용 높이를 알려 준다.
function UI.scroll(parent)
    local sf = CreateFrame("ScrollFrame", nil, parent)
    local content = CreateFrame("Frame", nil, sf)
    content:SetSize(10, 10)
    sf:SetScrollChild(content)
    sf.content = content
    sf:EnableMouseWheel(true)
    sf:SetScript("OnMouseWheel", function(self, delta)
        local range = self:GetVerticalScrollRange() or 0
        local pos = (self:GetVerticalScroll() or 0) - delta * 48
        if pos > range then pos = range end
        if pos < 0 then pos = 0 end
        self:SetVerticalScroll(pos)
    end)
    sf:SetScript("OnSizeChanged", function(self, w)
        if w and w > 0 then content:SetWidth(w) end
    end)
    function sf:setHeight(h)
        content:SetHeight(math.max(1, h))
        if self.UpdateScrollChildRect then self:UpdateScrollChildRect() end
        local range = self:GetVerticalScrollRange() or 0
        if (self:GetVerticalScroll() or 0) > range then self:SetVerticalScroll(range) end
    end
    return sf
end

-- 툴팁: { title = "...", lines = { "...", {text, color}, ... } }
function UI.showTooltip(owner, tip)
    if not GameTooltip then return end
    if type(tip) == "function" then tip = tip(owner) end
    if not tip then return end
    GameTooltip:SetOwner(owner, "ANCHOR_RIGHT")
    GameTooltip:ClearLines()
    if tip.title then GameTooltip:AddLine(tip.title, 1, 1, 1) end
    for i = 1, #(tip.lines or {}) do
        local line = tip.lines[i]
        if type(line) == "table" then
            local c = line[2] or UI.C.sub
            GameTooltip:AddLine(line[1], c[1], c[2], c[3], true)
        else
            GameTooltip:AddLine(line, UI.C.sub[1], UI.C.sub[2], UI.C.sub[3], true)
        end
    end
    GameTooltip:Show()
end

function UI.hideTooltip()
    if GameTooltip then GameTooltip:Hide() end
end

function UI.setTooltip(frame, tip)
    frame.tooltip = tip
    if not frame.tooltipHooked then
        frame.tooltipHooked = true
        frame:EnableMouse(true)
        if not frame:GetScript("OnEnter") then
            frame:SetScript("OnEnter", function(self) if self.tooltip then UI.showTooltip(self, self.tooltip) end end)
            frame:SetScript("OnLeave", UI.hideTooltip)
        end
    end
end

-- 큰 수를 읽기 쉽게: 1,234 / 12.3만 / 1.23억
function UI.number(v)
    v = v or 0
    local sign = v < 0 and "-" or ""
    v = math.abs(v)
    if v >= 1e8 then return sign .. string.format("%.2f억", v / 1e8) end
    if v >= 1e5 then return sign .. string.format("%.1f만", v / 1e4) end
    local s = tostring(math.floor(v + 0.5))
    local out = s:reverse():gsub("(%d%d%d)", "%1,"):reverse()
    if out:sub(1, 1) == "," then out = out:sub(2) end
    return sign .. out
end

------------------------------------------------------------------------
-- 시안의 부품들
------------------------------------------------------------------------

-- 위쪽 탭: 글자 + 선택되면 아래에 강조색 줄
function UI.tab(parent, label, onClick)
    local b = CreateFrame("Button", nil, parent)
    b.label = UI.text(b, 13, UI.C.sub, "CENTER")
    b.label:SetPoint("CENTER")
    b.label:SetText(label)
    b:SetSize(math.max(44, (b.label:GetStringWidth() or 30) + 30), 44)
    b.line = UI.fill(b, UI.accent(), "OVERLAY")
    b.line:SetPoint("BOTTOMLEFT", 12, 0)
    b.line:SetPoint("BOTTOMRIGHT", -12, 0)
    b.line:SetHeight(2)
    b.line:Hide()
    function b:setSelected(v)
        self.selected = v and true or false
        self.line:SetColorTexture(rgb(UI.accent()))
        self.line:SetShown(self.selected)
        self.label:SetTextColor(rgb(self.selected and UI.C.text or (self.over and UI.C.text or UI.C.sub)))
    end
    b:SetScript("OnEnter", function(self) self.over = true; self:setSelected(self.selected) end)
    b:SetScript("OnLeave", function(self) self.over = false; self:setSelected(self.selected) end)
    b:SetScript("OnClick", function(self)
        local ok, err = pcall(onClick, self)
        if not ok then UI.reportError(err) end
    end)
    return b
end

-- 작은 선택 칩(필터)
function UI.chip(parent, label, onClick)
    local b = UI.button(parent, label, 10, 22, onClick)
    b.label:SetFont(STANDARD_TEXT_FONT or "Fonts\\2002.TTF", 11, "")
    b:SetWidth(math.max(36, (b.label:GetStringWidth() or 20) + 18))
    function b:paint()
        if self.selected then
            self.bg:SetColorTexture(rgb(UI.C.raised))
            self.label:SetTextColor(rgb(UI.C.text))
            UI.setBorderColor(self, UI.C.line2)
        else
            self.bg:SetColorTexture(rgb(self.over and UI.C.panel or UI.C.bg))
            self.label:SetTextColor(rgb(self.enabled and UI.C.sub or UI.C.dim))
            UI.setBorderColor(self, UI.C.line)
        end
    end
    b:paint()
    return b
end

-- 나란히 붙은 선택 묶음: items = { {id, label}, ... }, onPick(id)
function UI.segment(parent, items, width, onPick)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(width, 28)
    UI.border(f)
    f.buttons = {}
    local w = width / #items
    for i, it in ipairs(items) do
        local b = CreateFrame("Button", nil, f)
        b:SetSize(w, 28)
        b:SetPoint("LEFT", (i - 1) * w, 0)
        b.bg = UI.fill(b, UI.C.raised)
        b.bg:SetPoint("TOPLEFT", 1, -1)
        b.bg:SetPoint("BOTTOMRIGHT", -1, 1)
        b.label = UI.text(b, 12, UI.C.sub, "CENTER")
        b.label:SetPoint("CENTER")
        b.label:SetText(it[2])
        b.id = it[1]
        b:SetScript("OnClick", function()
            f:pick(it[1])
            local ok, err = pcall(onPick, it[1])
            if not ok then UI.reportError(err) end
        end)
        if i > 1 then
            local sep = UI.fill(f, UI.C.line, "ARTWORK")
            sep:SetSize(1, 28)
            sep:SetPoint("LEFT", (i - 1) * w, 0)
        end
        f.buttons[i] = b
    end
    function f:pick(id)
        self.value = id
        for _, b in ipairs(self.buttons) do
            local on = b.id == id
            b.bg:SetShown(on)
            b.label:SetTextColor(rgb(on and UI.C.text or UI.C.sub))
        end
    end
    f:pick(items[1][1])
    return f
end

-- 레벨 점: 세로 막대 n개 중 앞의 몇 개가 채워진다
function UI.pips(parent, count)
    local f = CreateFrame("Frame", nil, parent)
    f:SetSize(count * 6 - 2, 12)
    f.items = {}
    for i = 1, count do
        local t = UI.fill(f, UI.C.line, "ARTWORK")
        t:SetSize(4, 12)
        t:SetPoint("LEFT", (i - 1) * 6, 0)
        f.items[i] = t
    end
    function f:set(n)
        for i, t in ipairs(self.items) do
            t:SetColorTexture(rgb(i <= n and UI.C.text or UI.C.line))
        end
    end
    return f
end

-- 목록의 한 줄: 선택되면 바탕이 밝아지고 왼쪽에 강조색 줄이 생긴다
function UI.listRow(parent, width, height, onClick)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(width, height)
    b.bg = UI.fill(b, UI.C.raised)
    b.bg:SetAllPoints()
    b.bg:Hide()
    b.bar = UI.fill(b, UI.accent(), "ARTWORK")
    b.bar:SetPoint("TOPLEFT")
    b.bar:SetPoint("BOTTOMLEFT")
    b.bar:SetWidth(2)
    b.bar:Hide()
    function b:setSelected(v)
        self.selected = v and true or false
        self.bar:SetColorTexture(rgb(UI.accent()))
        self.bar:SetShown(self.selected)
        self.bg:SetShown(self.selected or self.over == true)
        self.bg:SetColorTexture(rgb(self.selected and UI.C.raised or UI.C.panel))
    end
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnEnter", function(self)
        self.over = true
        self:setSelected(self.selected)
        if self.tooltip then UI.showTooltip(self, self.tooltip) end
    end)
    b:SetScript("OnLeave", function(self) self.over = false; self:setSelected(self.selected); UI.hideTooltip() end)
    b:SetScript("OnClick", function(self, button)
        local ok, err = pcall(onClick, self, button)
        if not ok then UI.reportError(err) end
    end)
    return b
end

-- 아이콘 칸(장비, 스킬): 어두운 바탕 + 얇은 선 + 아이콘
function UI.slot(parent, size)
    local b = CreateFrame("Button", nil, parent)
    b:SetSize(size, size)
    b.bg = UI.fill(b, UI.C.well)
    b.bg:SetAllPoints()
    b.tex = b:CreateTexture(nil, "ARTWORK")
    b.tex:SetPoint("TOPLEFT", 2, -2)
    b.tex:SetPoint("BOTTOMRIGHT", -2, 2)
    b.tex:SetTexCoord(0.08, 0.92, 0.08, 0.92)
    UI.border(b, UI.C.line2)
    b.corner = UI.text(b, 10, UI.C.sub, "RIGHT")
    b.corner:SetPoint("BOTTOMRIGHT", -3, 3)
    b.center = UI.text(b, 10, UI.C.dim, "CENTER")
    b.center:SetPoint("CENTER")
    function b:setIcon(name, borderColor)
        if name then
            self.tex:SetTexture(UI.iconPath(name))
            self.tex:Show()
        else
            self.tex:Hide()
        end
        UI.setBorderColor(self, borderColor or UI.C.line2)
    end
    b:RegisterForClicks("LeftButtonUp", "RightButtonUp")
    b:SetScript("OnEnter", function(self) if self.tooltip then UI.showTooltip(self, self.tooltip) end end)
    b:SetScript("OnLeave", UI.hideTooltip)
    b:SetScript("OnClick", function(self, button)
        if not self.onClick then return end
        local ok, err = pcall(self.onClick, self, button)
        if not ok then UI.reportError(err) end
    end)
    return b
end

-- 작은 제목 글자(구역 이름)
function UI.label(parent, text)
    local fs = UI.text(parent, 11, UI.C.dim)
    fs:SetText(text or "")
    return fs
end

function UI.reportError(err)
    local msg = "|cffd06058W.I.H 오류:|r " .. tostring(err)
    if WIH.App and WIH.App.lastErrors then
        local list = WIH.App.lastErrors
        list[#list + 1] = tostring(err)
        if #list > 20 then table.remove(list, 1) end
    end
    print(msg)
end

return UI
