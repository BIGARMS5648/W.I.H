-- 첫 실행 화면: 진영 선택 → 첫 영웅 선택.

local _, WIH = ...
local UI = WIH.module("UI")
local App = WIH.module("App")
local Heroes = WIH.module("Heroes")
local SkillData = WIH.module("SkillData")

local FACTIONS = {
    { id = "Alliance", name = "얼라이언스", atlas = "AllianceEmblem", desc = "청색과 은색의 깃발 아래 모인 연합." },
    { id = "Horde", name = "호드", atlas = "HordeEmblem", desc = "적색과 흑철의 깃발 아래 모인 무리." },
}

local function create(parent)
    local f = CreateFrame("Frame", nil, parent)
    f.step = 1
    f.faction = nil
    f.hero = nil

    local title = UI.text(f, 18, UI.C.text)
    title:SetPoint("TOPLEFT", 24, -22)
    f.title = title
    local sub = UI.text(f, 12, UI.C.sub)
    sub:SetPoint("TOPLEFT", title, "BOTTOMLEFT", 0, -8)
    f.sub = sub

    -- 1단계: 진영
    local step1 = CreateFrame("Frame", nil, f)
    step1:SetPoint("TOPLEFT", 24, -80)
    step1:SetPoint("BOTTOMRIGHT", -24, 24)
    f.step1 = step1
    f.factionCards = {}
    for i, fac in ipairs(FACTIONS) do
        local card = CreateFrame("Button", nil, step1)
        card:SetSize(300, 300)
        card:SetPoint("TOPLEFT", (i - 1) * 320, 0)
        card.bg = UI.fill(card, UI.C.panel)
        card.bg:SetAllPoints()
        UI.border(card)
        local stripe = UI.fill(card, UI.C[fac.id], "ARTWORK")
        stripe:SetPoint("TOPLEFT", 1, -1)
        stripe:SetPoint("TOPRIGHT", -1, -1)
        stripe:SetHeight(3)
        local emblem = card:CreateTexture(nil, "ARTWORK")
        emblem:SetSize(96, 96)
        emblem:SetPoint("TOP", 0, -46)
        if emblem.SetAtlas then pcall(emblem.SetAtlas, emblem, fac.atlas) end
        local name = UI.text(card, 16, UI.C.text, "CENTER")
        name:SetPoint("TOP", emblem, "BOTTOM", 0, -18)
        name:SetText(fac.name)
        local desc = UI.paragraph(card, 12, UI.C.sub, 250)
        desc:SetPoint("TOP", name, "BOTTOM", 0, -12)
        desc:SetJustifyH("CENTER")
        desc:SetText(fac.desc .. "\n\n진영에 따라 화면의 강조색과 일부 명칭이 달라집니다. 직업과 콘텐츠는 같고, 설정에서 언제든 바꿀 수 있습니다.")
        card:SetScript("OnEnter", function(self) self.bg:SetColorTexture(UI.rgb(UI.C.raised)) end)
        card:SetScript("OnLeave", function(self) self.bg:SetColorTexture(UI.rgb(UI.C.panel)) end)
        card:SetScript("OnClick", function()
            f.faction = fac.id
            f.step = 2
            UI.screens.setup.refresh(f)
        end)
        f.factionCards[i] = card
    end

    f.restore = UI.button(step1, "", 620, 28, function()
        local ok, why = App.restoreBackup(1)
        if not ok and WIH.Main then WIH.Main.notice(why, UI.C.bad) end
    end)
    f.restore:SetPoint("TOPLEFT", 0, -316)
    f.restore.tooltip = { title = "백업에서 되돌리기", lines = { "가장 최근 백업의 상태로 돌아갑니다. 다른 백업은 되돌린 뒤 설정 화면에서 고를 수 있습니다." } }

    -- 2단계: 첫 영웅
    local step2 = CreateFrame("Frame", nil, f)
    step2:SetPoint("TOPLEFT", 24, -80)
    step2:SetPoint("BOTTOMRIGHT", -24, 24)
    f.step2 = step2
    f.heroButtons = {}
    local colW, rowH = 150, 30
    for ci, class in ipairs(Heroes.CLASS_ORDER) do
        local label = UI.text(step2, 11, UI.C.dim)
        label:SetPoint("TOPLEFT", 0, -((ci - 1) * (rowH + 4)) - 8)
        label:SetWidth(64)
        label:SetText(Heroes.CLASSES[class])
        local n = 0
        for _, hero in ipairs(Heroes.list) do
            if hero.class == class then
                n = n + 1
                local b = UI.button(step2, hero.name, colW, rowH - 2, function()
                    f.hero = hero.id
                    UI.screens.setup.refresh(f)
                end)
                b:SetPoint("TOPLEFT", 70 + (n - 1) * (colW + 6), -((ci - 1) * (rowH + 4)))
                f.heroButtons[hero.id] = b
            end
        end
    end
    local detail = UI.panel(step2, UI.C.panel, true)
    detail:SetPoint("TOPLEFT", 70 + 3 * (colW + 6) + 8, 0)
    detail:SetPoint("BOTTOMRIGHT", 0, 44)
    f.detail = detail
    f.detailIcon = UI.icon(detail, 40)
    f.detailIcon:SetPoint("TOPLEFT", 14, -14)
    f.detailName = UI.text(detail, 15, UI.C.text)
    f.detailName:SetPoint("TOPLEFT", f.detailIcon, "TOPRIGHT", 12, -2)
    f.detailRole = UI.text(detail, 12, UI.C.sub)
    f.detailRole:SetPoint("TOPLEFT", f.detailName, "BOTTOMLEFT", 0, -6)
    f.detailBody = UI.paragraph(detail, 12, UI.C.sub)
    f.detailBody:SetPoint("TOPLEFT", 14, -70)
    f.detailBody:SetPoint("TOPRIGHT", -14, -70)

    f.back = UI.button(step2, "진영 다시 고르기", 130, 28, function()
        f.step = 1
        UI.screens.setup.refresh(f)
    end)
    f.back:SetPoint("BOTTOMLEFT", 0, 0)
    f.start = UI.button(step2, "이 영웅으로 시작", 160, 28, function()
        if f.faction and f.hero then
            local ok, why = App.newGame(f.faction, f.hero)
            if not ok and WIH.Main then WIH.Main.notice(why, UI.C.bad) end
        end
    end)
    f.start:SetPoint("BOTTOMRIGHT", 0, 0)
    return f
end

local function refresh(f)
    if App.readOnly then
        f.title:SetText("저장 데이터를 열 수 없습니다")
        f.sub:SetText("더 새로운 버전의 W.I.H가 만든 저장 데이터입니다. 애드온을 최신 버전으로 올려 주세요. 저장 데이터는 건드리지 않습니다.")
        f.step1:Hide()
        f.step2:Hide()
        return
    end
    f.step1:SetShown(f.step == 1)
    f.step2:SetShown(f.step == 2)
    if f.step == 1 then
        f.title:SetText("진영을 고르세요")
        local backup = type(WIH_DB_BACKUP) == "table" and WIH_DB_BACKUP[1] or nil
        f.restore:SetShown(backup ~= nil)
        if backup then
            local at = (date and type(backup.at) == "number" and backup.at > 0) and date("%Y-%m-%d %H:%M", backup.at) or ""
            f.restore:setText("가장 최근 백업에서 되돌리기  " .. at)
        end
        local info = App.loadInfo
        if info and info.status == "broken" then
            f.sub:SetText("이전 저장 데이터를 불러오지 못했습니다(" .. (info.notes[1] or "") .. "). 원본은 백업에 남겨 두었습니다.")
        else
            f.sub:SetText("W.I.H는 이 창 안에서 따로 진행되는 방치형 RPG입니다. 실제 캐릭터와 골드에는 영향을 주지 않습니다.")
        end
        return
    end
    f.title:SetText("첫 영웅을 고르세요")
    f.sub:SetText("나머지 영웅은 게임 안에서 골드 500으로 해금합니다. 영웅마다 레벨과 스킬을 따로 키웁니다.")
    for id, b in pairs(f.heroButtons) do b:setSelected(id == f.hero) end
    f.start:setEnabled(f.hero ~= nil)
    f.detail:SetShown(f.hero ~= nil)
    if f.hero then
        local hero = Heroes.byId[f.hero]
        f.detailIcon:set(UI.CLASS_ICONS[hero.class])
        f.detailName:SetText(hero.name)
        local main, subw = Heroes.MAIN_WEAPONS[hero.main].name, Heroes.SUB_WEAPONS[hero.sub].name
        f.detailRole:SetText(Heroes.ROLES[hero.role] .. "  ·  " .. main .. " + " .. subw)
        local lines = {}
        for i, id in ipairs(hero.skills) do
            local def = SkillData.resolve(id, hero.defaultForm)
            lines[#lines + 1] = "|cffe8e8ea" .. def.name .. "|r  (" .. SkillData.activation(def, 1) .. ")\n" .. SkillData.describe(def, 1)
        end
        if hero.forms then
            lines[#lines + 1] = "|cffa8aab0편성 화면에서 곰(탱커)과 표범(딜러) 형태를 고를 수 있습니다. 위는 곰 형태의 스킬입니다.|r"
        end
        f.detailBody:SetText(table.concat(lines, "\n\n"))
    end
end

-- 이 화면이 열릴 때는 언제나 진영 선택부터 다시 시작한다(전체 초기화 뒤에 예전 선택이 남지 않게).
local function onShow(f)
    f.step, f.faction, f.hero = 1, nil, nil
end

UI.screens.setup = { label = "시작", create = create, refresh = refresh, onShow = onShow }
