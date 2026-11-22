-- 오프라인 보상 창: 접속했을 때 받을 것이 있으면 뜬다. "받기"를 눌러야 지급된다(닫아도 사라지지 않는다).

local _, WIH = ...
local UI = WIH.module("UI")
local App = WIH.module("App")
local Heroes = WIH.module("Heroes")
local Offline = WIH.module("Offline")
local Reward = WIH.module("Reward")

local C = UI.C
local frame

local function duration(sec)
    sec = math.floor(sec or 0)
    local h, m = math.floor(sec / 3600), math.floor(sec % 3600 / 60)
    if h > 0 then return h .. "시간 " .. m .. "분" end
    return m .. "분"
end

local function create()
    frame = CreateFrame("Frame", "WIH_RewardFrame", UIParent)
    frame:SetSize(360, 250)
    frame:SetPoint("CENTER", 0, 120)
    frame:SetFrameStrata("DIALOG")
    frame:EnableMouse(true)
    frame:Hide()
    frame.bg = UI.fill(frame, C.bg)
    frame.bg:SetAllPoints()
    UI.border(frame, C.line2)
    local title = UI.text(frame, 15, C.text)
    title:SetPoint("TOPLEFT", 18, -16)
    title:SetText("오프라인 보상")
    frame.sub = UI.text(frame, 11, C.sub)
    frame.sub:SetPoint("TOPLEFT", 18, -40)
    local line = UI.fill(frame, C.line, "ARTWORK")
    line:SetPoint("TOPLEFT", 18, -60)
    line:SetPoint("TOPRIGHT", -18, -60)
    line:SetHeight(1)
    frame.goldLabel = UI.label(frame, "골드")
    frame.goldLabel:SetPoint("TOPLEFT", 18, -74)
    frame.gold = UI.text(frame, 18, C.warn)
    frame.gold:SetPoint("TOPLEFT", 18, -90)
    frame.expLabel = UI.label(frame, "경험치")
    frame.expLabel:SetPoint("TOPLEFT", 18, -122)
    frame.exp = UI.paragraph(frame, 12, C.text)
    frame.exp:SetPoint("TOPLEFT", 18, -140)
    frame.exp:SetPoint("TOPRIGHT", -18, -140)
    if frame.exp.SetSpacing then frame.exp:SetSpacing(3) end
    frame.claim = UI.button(frame, "받기", 120, 28, function()
        local out = Offline.claim(App.state)
        frame:Hide()
        if out then
            local ups = {}
            for heroId, lv in pairs(out.levels) do
                if lv[2] > lv[1] then ups[#ups + 1] = Heroes.byId[heroId].name .. " 레벨 " .. lv[2] end
            end
            App.addLog("|cffd9b05e오프라인 보상|r  " .. UI.number(out.gold) .. " G" .. (#ups > 0 and ("  ·  " .. table.concat(ups, ", ")) or ""))
            App.notify("offline")
        end
    end)
    frame.claim:SetPoint("BOTTOM", 0, 16)
    return frame
end

-- 받을 것이 있으면 창을 띄운다.
function Reward.check()
    local state = App.state
    local p = state and Offline.pending(state)
    if not p then
        if frame then frame:Hide() end
        return false
    end
    if not frame then create() end
    frame.sub:SetText("자리를 비운 " .. duration(p.seconds) .. " 동안의 보상  ·  " .. (p.stageKey and App.stageName(p.stageKey) or ""))
    frame.gold:SetText(UI.number(p.gold) .. " G")
    local lines = {}
    for _, heroId in ipairs(state.party) do
        if p.exp[heroId] then lines[#lines + 1] = Heroes.byId[heroId].name .. "   +" .. UI.number(p.exp[heroId]) end
    end
    for heroId, amount in pairs(p.exp) do
        local listed = false
        for _, id in ipairs(state.party) do if id == heroId then listed = true end end
        if not listed and Heroes.byId[heroId] then lines[#lines + 1] = Heroes.byId[heroId].name .. "   +" .. UI.number(amount) end
    end
    frame.exp:SetText(table.concat(lines, "\n"))
    frame:Show()
    return true
end

function Reward.frame() return frame end

App.watchers[#App.watchers + 1] = function(tag)
    if tag == "loaded" or tag == "restore" or tag == "reset" then Reward.check() end
end

return Reward
