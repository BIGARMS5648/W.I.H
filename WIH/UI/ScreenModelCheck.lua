-- 모델 점검: 영웅과 몬스터에 지정한 모델이 실제로 나오는지 한 쪽에 열두 개씩 보여 준다.
-- 모델 번호는 기억에 의존해 적은 것이라, 잘못 나오거나 안 나오는 것을 눈으로 확인하기 위한 화면이다.
-- 설정 화면의 "모델 점검" 버튼으로 연다(탭에는 없다).

local _, WIH = ...
local UI = WIH.module("UI")
local App = WIH.module("App")
local Heroes = WIH.module("Heroes")
local Monsters = WIH.module("Monsters")
local Dungeons = WIH.module("Dungeons")
local Raids = WIH.module("Raids")
local Models = WIH.module("Models")
local Looks = WIH.module("Looks")
local Game = WIH.module("Game")

local C = UI.C
local COLS, ROWS = 6, 2
local PER_PAGE = COLS * ROWS

-- 점검할 목록: { name = 이름, ids = 후보 번호 목록 }
local function buildList(kind, faction)
    local list = {}
    if kind == "look" then
        -- 직업마다 겉모습 단계 여섯 개를 한 벌씩 입혀 본다(그 직업의 첫 영웅의 종족과 무기로).
        for _, class in ipairs(Heroes.CLASS_ORDER) do
            local sample
            for _, hero in ipairs(Heroes.list) do
                if hero.class == class and not hero.forms then sample = sample or hero end
            end
            local pair = Looks.RACE[sample.id][faction == "Horde" and 2 or 1]
            for tier = 1, 6 do
                local set = Looks.set(class, tier)
                local items = {}
                for _, slot in ipairs({ "chest", "shoulder", "legs", "head", "hands", "feet" }) do
                    if set[slot] then items[#items + 1] = set[slot] end
                end
                if Looks.WEAPONS[sample.main] then items[#items + 1] = Looks.WEAPONS[sample.main][tier] end
                local offhand
                if Looks.WEAPONS[sample.sub] then
                    if Looks.OFFHAND_WEAPON[sample.sub] then offhand = Looks.WEAPONS[sample.sub][tier] else items[#items + 1] = Looks.WEAPONS[sample.sub][tier] end
                end
                list[#list + 1] = { name = Heroes.CLASSES[class] .. " · " .. Looks.TIER_NAMES[tier],
                    look = { race = pair[1], sex = pair[2], items = items, offhand = offhand }, ids = {} }
            end
        end
    elseif kind == "hero" then
        for _, hero in ipairs(Heroes.list) do
            list[#list + 1] = { name = hero.name, ids = Models.heroCandidates(hero.id, faction) }
            if hero.forms then
                for form, def in pairs(hero.forms) do
                    list[#list + 1] = { name = hero.name .. " (" .. def.name .. ")", ids = { Models.FORMS[form] } }
                end
            end
        end
    else
        local function add(id)
            local def = Monsters.defs[id]
            if def and ((kind == "boss") == (def.isBoss == true)) then
                list[#list + 1] = { name = def.name, ids = Models.candidates({ kind = "monster", def = def }, faction) }
            end
        end
        for _, key in ipairs(Dungeons.order) do
            local sec = Dungeons.sections[key]
            for _, m in ipairs(sec.mobs) do add(m.id) end
            for _, id in ipairs(sec.bosses) do add(id) end
        end
        for act = 1, 3 do
            for _, id in ipairs(Raids.byAct[act].bosses) do add(id) end
        end
    end
    return list
end

local function create(parent)
    local f = CreateFrame("Frame", nil, parent)
    f.kind, f.page = "look", 1
    f.kinds = {}
    local x = 14
    for _, it in ipairs({ { "look", "장비 룩" }, { "hero", "영웅(고정 모델)" }, { "boss", "보스" }, { "mob", "일반 몬스터" } }) do
        local b = UI.chip(f, it[2], function()
            f.kind, f.page = it[1], 1
            UI.screens.modelcheck.refresh(f)
        end)
        b:SetPoint("TOPLEFT", x, -12)
        b.id = it[1]
        f.kinds[#f.kinds + 1] = b
        x = x + b:GetWidth() + 5
    end
    f.info = UI.text(f, 11, C.sub)
    f.info:SetPoint("TOPLEFT", x + 12, -17)
    f.diag = UI.text(f, 11, C.dim)
    f.diag:SetPoint("BOTTOMLEFT", 14, 4)
    local back = UI.button(f, "설정으로", 76, 24, function() WIH.Main.show("settings") end)
    back:SetPoint("TOPRIGHT", -14, -10)
    local retry = UI.button(f, "다시 시도", 70, 24, function()
        Models.resetKnown()
        UI.screens.modelcheck.refresh(f)
    end)
    retry:SetPoint("RIGHT", back, "LEFT", -8, 0)
    retry.tooltip = { title = "다시 시도", lines = { "실패로 기억해 둔 모델을 지우고 처음부터 다시 불러옵니다." } }
    f.nextBtn = UI.button(f, "다음", 56, 24, function()
        f.page = f.page + 1
        UI.screens.modelcheck.refresh(f)
    end)
    f.nextBtn:SetPoint("RIGHT", retry, "LEFT", -8, 0)
    f.prevBtn = UI.button(f, "이전", 56, 24, function()
        f.page = math.max(1, f.page - 1)
        UI.screens.modelcheck.refresh(f)
    end)
    f.prevBtn:SetPoint("RIGHT", f.nextBtn, "LEFT", -6, 0)

    f.cells = {}
    for i = 1, PER_PAGE do
        local col, row = (i - 1) % COLS, math.floor((i - 1) / COLS)
        local cell = UI.panel(f, C.panel, true)
        cell:SetSize(148, 226)
        cell:SetPoint("TOPLEFT", 14 + col * 155, -44 - row * 232)
        cell.view = UI.modelView(cell)
        cell.view:SetPoint("TOPLEFT", 4, -4)
        cell.view:SetPoint("BOTTOMRIGHT", -4, 44)
        cell.name = UI.text(cell, 11, C.text, "CENTER")
        cell.name:SetPoint("BOTTOMLEFT", 4, 24)
        cell.name:SetPoint("BOTTOMRIGHT", -4, 24)
        cell.state = UI.text(cell, 10, C.dim, "CENTER")
        cell.state:SetPoint("BOTTOMLEFT", 4, 8)
        cell.state:SetPoint("BOTTOMRIGHT", -4, 8)
        cell.view.onFail = function() cell.failed = true end
        f.cells[i] = cell
    end
    f.acc = 0
    return f
end

local function refresh(f)
    local s = App.state
    if not s then return end
    for _, b in ipairs(f.kinds) do b:setSelected(b.id == f.kind) end
    local list = buildList(f.kind, s.faction)
    local pages = math.max(1, math.ceil(#list / PER_PAGE))
    if f.page > pages then f.page = pages end
    f.info:SetText(string.format("%d개 중 %d ~ %d   ·   %d / %d쪽", #list,
        (f.page - 1) * PER_PAGE + 1, math.min(#list, f.page * PER_PAGE), f.page, pages))
    f.prevBtn:setEnabled(f.page > 1)
    f.nextBtn:setEnabled(f.page < pages)
    for i, cell in ipairs(f.cells) do
        local entry = list[(f.page - 1) * PER_PAGE + i]
        cell:SetShown(entry ~= nil)
        if entry then
            cell.entry, cell.failed = entry, nil
            cell.name:SetText(entry.name)
            if entry.look then
                if not cell.view:setCharacter(entry.look, 0.4, 1.2) then cell.failed = true end
            elseif #entry.ids == 0 or not cell.view:setCreature(entry.ids, 0.4, 1.2) then
                cell.failed = true
            end
        else
            cell.view:clear()
        end
    end
end

-- 진단 줄: 옷 입히기에 쓰는 함수가 이 클라이언트에 있는지, 호출이 성공했는지
local function diagText()
    local d = Models.dressInfo
    local function yes(v) return v == nil and "?" or (v and "됨" or "안 됨") end
    local state = Models.dress == nil and "확인 중" or (Models.dress and "됨" or "안 됨(고정 모델로 대체)")
    return string.format("장비 룩 진단   프레임 %s  ·  SetCustomRace %s(호출 %s)  ·  TryOn %s(입힌 수 %s)  ·  Undress %s  ·  SetSheathed %s  ·  결과: %s   |   붉은 번호 = 나오지 않은 모델",
        tostring(d.frame or "?"), d.hasRace == nil and "?" or (d.hasRace and "있음" or "없음"), yes(d.race),
        d.hasTryOn == nil and "?" or (d.hasTryOn and "있음" or "없음"), tostring(d.tryOn or "?"), yes(d.undress), yes(d.sheath), state)
end

local function update(f, elapsed)
    f.diag:SetText(diagText())
    for _, cell in ipairs(f.cells) do
        if cell:IsShown() and cell.entry then
            cell.view:update(elapsed)
            if cell.entry.look then
                local n = #cell.entry.look.items + (cell.entry.look.offhand and 1 or 0)
                cell.state:SetText(cell.failed and "|cffcf5f58입히기 실패|r" or (cell.view:isPending() and "불러오는 중" or ("|cff6fb07f아이템 " .. n .. "개|r")))
            end
            local parts = {}
            for _, id in ipairs(cell.entry.ids) do
                local known = Models.known[id]
                parts[#parts + 1] = (known == false and "|cffcf5f58" or (known == true and "|cff6fb07f" or "|cff9da2aa")) .. id .. "|r"
            end
            if not cell.entry.look then cell.state:SetText(#parts > 0 and table.concat(parts, " → ") or "지정한 모델 없음") end
        end
    end
end

local function onHide(f)
    for _, cell in ipairs(f.cells) do cell.view:clear() end
end

UI.screens.modelcheck = { label = "모델 점검", create = create, refresh = refresh, update = update, onHide = onHide }
