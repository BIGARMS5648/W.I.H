-- 스테이지 화면: 난이도와 던전 선택, 등장 몬스터와 보스 패턴, 진행 상황.

local _, WIH = ...
local UI = WIH.module("UI")
local App = WIH.module("App")
local Game = WIH.module("Game")
local Heroes = WIH.module("Heroes")
local Tables = WIH.module("Tables")
local Level = WIH.module("Level")
local Dungeons = WIH.module("Dungeons")
local Monsters = WIH.module("Monsters")
local Runes = WIH.module("Runes")
local Raids = WIH.module("Raids")
local Expeditions = WIH.module("Expeditions")
local ExpeditionData = WIH.module("ExpeditionData")
local ExpeditionTable = WIH.module("ExpeditionTable")

local C = UI.C
local ARCHETYPE_TEXT = {
    grunt = "근접", soldier = "단단한 근접", brute = "느리고 강한 근접", tank = "체력이 많은 근접", fast = "빠른 근접",
    swarm = "무리", stalker = "공격이 빠른 근접", berserk = "돌진", caster = "원거리 주문", archer = "원거리 물리",
}
local ELEMENT_HEX = { Physical = "dbdbdb", Fire = "eb804d", Cold = "80bdeb", Lightning = "ebd670", Chaos = "a87ad6" }

local function create(parent)
    local f = CreateFrame("Frame", nil, parent)
    f.difficulty = nil
    f.section = nil

    f.tabs = {}
    for d = 1, 4 do
        local b = UI.button(f, Tables.DIFFICULTY_NAMES[d], 70, 24, function()
            f.difficulty = d
            f.intensity = nil
            UI.screens.stage.refresh(f)
        end)
        b:SetPoint("TOPLEFT", 10 + (d - 1) * 74, -10)
        f.tabs[d] = b
    end
    f.tabHint = UI.text(f, 11, C.dim)
    f.tabHint:SetPoint("LEFT", f.tabs[4], "RIGHT", 12, 0)

    f.list = UI.scroll(f)
    f.list:SetPoint("TOPLEFT", 10, -44)
    f.list:SetPoint("BOTTOMLEFT", 10, 10)
    f.list:SetWidth(250)
    f.rows = {}
    f.raidRows = {}
    local y = 0
    for act = 1, 3 do
        local head = UI.text(f.list.content, 11, C.dim)
        head:SetPoint("TOPLEFT", 4, -y - 4)
        head:SetText("액트 " .. act)
        y = y + 22
        for n = 1, 9 do
            local key = act * 100 + n
            local sec = Dungeons.sections[key]
            if sec then
                local b = UI.button(f.list.content, sec.name, 244, 24, function()
                    f.section = key
                    f.raidAct, f.special = nil, nil
                    UI.screens.stage.refresh(f)
                end)
                b:SetPoint("TOPLEFT", 0, -y)
                b.label:ClearAllPoints()
                b.label:SetPoint("LEFT", 8, 0)
                b.label:SetJustifyH("LEFT")
                b.right = UI.text(b, 11, C.sub, "RIGHT")
                b.right:SetPoint("RIGHT", -8, 0)
                f.rows[key] = b
                y = y + 26
            end
        end
        -- 레이드(액트 보스 자리)
        local rb = UI.button(f.list.content, "레이드 · " .. Raids.byAct[act].name, 244, 24, function()
            f.raidAct, f.special = act, nil
            UI.screens.stage.refresh(f)
        end)
        rb:SetPoint("TOPLEFT", 0, -y)
        rb.label:ClearAllPoints()
        rb.label:SetPoint("LEFT", 8, 0)
        rb.label:SetJustifyH("LEFT")
        rb.right = UI.text(rb, 11, C.sub, "RIGHT")
        rb.right:SetPoint("RIGHT", -8, 0)
        f.raidRows[act] = rb
        y = y + 32
    end
    -- 원정과 낙스라마스(악몽 이상)
    local function listButton(text, onClick)
        local b = UI.button(f.list.content, text, 244, 24, onClick)
        b:SetPoint("TOPLEFT", 0, -y)
        b.label:ClearAllPoints()
        b.label:SetPoint("LEFT", 8, 0)
        b.label:SetJustifyH("LEFT")
        b.right = UI.text(b, 11, C.sub, "RIGHT")
        b.right:SetPoint("RIGHT", -8, 0)
        y = y + 26
        return b
    end
    f.specialHead = UI.text(f.list.content, 11, C.dim)
    f.specialHead:SetPoint("TOPLEFT", 4, -y - 4)
    f.specialHead:SetText("원정 · 낙스라마스")
    y = y + 22
    f.expRow = listButton("원정", function()
        f.special, f.raidAct = "exp", nil
        f.intensity = nil
        UI.screens.stage.refresh(f)
    end)
    f.naxxRows = {}
    for a = 1, 3 do
        f.naxxRows[a] = listButton(ExpeditionData.NAXX[a].name, function()
            f.special, f.raidAct = a, nil
            UI.screens.stage.refresh(f)
        end)
    end
    f.specialHint = UI.paragraph(f.list.content, 10, C.dim)
    f.specialHint:SetPoint("TOPLEFT", 4, -y - 2)
    f.specialHint:SetPoint("TOPRIGHT", -4, -y - 2)
    y = y + 40
    f.list:setHeight(y)

    local d = CreateFrame("Frame", nil, f)
    d:SetPoint("TOPLEFT", f.list, "TOPRIGHT", 14, 0)
    d:SetPoint("BOTTOMRIGHT", -10, 10)
    f.detail = d
    f.name = UI.text(d, 15, C.text)
    f.name:SetPoint("TOPLEFT", 0, 0)
    f.meta = UI.text(d, 12, C.sub)
    f.meta:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, -6)
    f.go = UI.button(d, "이 스테이지로 이동", 190, 26, function()
        if f.special then
            UI.screens.stage.startSpecial(f)
            return
        end
        if f.raidAct then
            local ok, why = Game.startRaid(App.state, f.difficulty, f.raidAct)
            if not ok then
                WIH.Main.notice(why, C.bad)
            else
                App.restartStage()
                WIH.Main.notice(Raids.byAct[f.raidAct].name .. " 레이드를 시작했습니다. 전투 화면에서 볼 수 있습니다.", C.good)
            end
            UI.screens.stage.refresh(f)
            return
        end
        local ok, why = Game.selectStage(App.state, f.difficulty, f.section)
        if not ok then
            WIH.Main.notice(why, C.bad)
        else
            App.restartStage()
            WIH.Main.notice(Dungeons.sections[f.section].name .. "(으)로 이동했습니다.", C.good)
        end
        UI.screens.stage.refresh(f)
    end)
    f.go:SetPoint("TOPRIGHT", 0, 0)
    f.state = UI.text(d, 11, C.dim, "RIGHT")
    f.state:SetPoint("TOPRIGHT", f.go, "BOTTOMRIGHT", 0, -6)
    f.leave = UI.button(d, "원정에서 나가기", 130, 26, function()
        Expeditions.leave(App.state)
        App.restartStage()
        WIH.Main.notice("원정에서 나와 던전으로 돌아갔습니다.", C.good)
        UI.screens.stage.refresh(f)
    end)
    f.leave:SetPoint("RIGHT", f.go, "LEFT", -6, 0)
    f.leave:Hide()

    -- 원정 강도(1~20)
    f.intensityRow = CreateFrame("Frame", nil, d)
    f.intensityRow:SetPoint("TOPLEFT", 0, -50)
    f.intensityRow:SetPoint("TOPRIGHT", 0, -50)
    f.intensityRow:SetHeight(54)
    f.intensityBtns = {}
    for n = 1, 20 do
        local b = UI.button(f.intensityRow, tostring(n), 36, 24, function()
            f.intensity = n
            UI.screens.stage.refresh(f)
        end)
        b:SetPoint("TOPLEFT", ((n - 1) % 10) * 39, -math.floor((n - 1) / 10) * 27)
        f.intensityBtns[n] = b
    end
    f.supplyBar = UI.bar(f.intensityRow, 170, 4, C.warn)
    f.supplyBar:SetPoint("TOPLEFT", 10 * 39 + 12, -8)
    f.supplyText = UI.text(f.intensityRow, 11, C.sub)
    f.supplyText:SetPoint("TOPLEFT", 10 * 39 + 12, -18)
    f.intensityRow:Hide()

    f.info = UI.scroll(d)
    f.info:SetPoint("TOPLEFT", 0, -50)
    f.infoTop = -50
    f.info:SetPoint("BOTTOMRIGHT", 0, 0)
    f.body = UI.paragraph(f.info.content, 12, C.sub)
    f.body:SetPoint("TOPLEFT", 0, 0)
    f.body:SetPoint("TOPRIGHT", -4, 0)
    if f.body.SetSpacing then f.body:SetSpacing(3) end
    return f
end

local function elemTag(elem)
    return "|cff" .. (ELEMENT_HEX[elem] or ELEMENT_HEX.Physical) .. WIH.Stats.ELEMENT_NAMES[elem] .. "|r"
end

local function detailText(s, difficulty, section)
    local sec = Dungeons.sections[section]
    local key = Dungeons.stageKey(difficulty, section)
    local stage = Tables.STAGES[key]
    local lines = {}
    local function add(t) lines[#lines + 1] = t end

    -- 현재 편성이 이 스테이지에서 받는 경험치 비율(엔진과 같은 함수)
    local parts = {}
    for _, id in ipairs(s.party) do
        local h = s.heroes[id]
        parts[#parts + 1] = string.format("%s %d%%", Heroes.byId[id].name, Level.expPenalty(h.level, stage.level) * 100 + 0.5)
    end
    add("|cffe8e8ea경험치 획득 비율|r  (영웅 레벨과 스테이지 레벨의 차이에 따라)")
    add(table.concat(parts, "   "))
    add("")

    add("|cffe8e8ea등장 몬스터|r")
    for _, m in ipairs(sec.mobs) do
        local def = Monsters.defs[m.id]
        add(string.format("%s  |cff6b6e75%s · %s 피해|r", def.name, ARCHETYPE_TEXT[def.archetype] or def.archetype, elemTag(def.elem)))
    end
    add("")

    local nextIndex = ((s.stage.bossIndex[key] or 1) - 1) % #sec.bosses + 1
    add("|cffe8e8ea보스|r  (클리어할 때마다 다음 보스로 바뀝니다)")
    for i, id in ipairs(sec.bosses) do
        local def = Monsters.defs[id]
        add("")
        add(string.format("|cffd9b05e%s|r%s  |cff6b6e75%s 피해 · %s|r", def.name, i == nextIndex and "  |cff70b880다음 등장|r" or "",
            elemTag(def.elem), def.melee and "근접" or "원거리"))
        for _, sk in ipairs(def.skills or {}) do
            add("  " .. sk.name .. ":  " .. sk.desc)
        end
        if not def.skills or #def.skills == 0 then add("  특수 패턴 없음") end
    end
    return table.concat(lines, "\n")
end

-- 레이드의 상세: 보스 순서와 이 난이도에서 쓰는 패턴
local function raidText(s, difficulty, act)
    local raid = Raids.byAct[act]
    local stage = Tables.STAGES[Raids.key(difficulty, act)]
    local lines = {}
    local function add(t) lines[#lines + 1] = t end
    local parts = {}
    for _, id in ipairs(s.party) do
        local h = s.heroes[id]
        parts[#parts + 1] = string.format("%s %d%%", Heroes.byId[id].name, Level.expPenalty(h.level, stage.level) * 100 + 0.5)
    end
    add("|cffe8e8ea경험치 획득 비율|r  " .. table.concat(parts, "   "))
    add("")
    add("|cffe8e8ea진행|r  보스 " .. #raid.bosses .. "명을 차례로 상대합니다. 보스 사이에 체력과 재사용 시간이 이어집니다. 전멸하면 실패이고, 실패하면 "
        .. Raids.TOKEN_NAME .. "는 쓰이지 않습니다. 클리어하면 레이드 상자 1개를 받습니다.")
    local count = Raids.skillCount(difficulty)
    for i, id in ipairs(raid.bosses) do
        local def = Monsters.defs[id]
        add("")
        add(string.format("|cffd9b05e%d. %s|r%s  |cff6b6e75%s 피해 · %s|r", i, def.name, i == #raid.bosses and "  |cff70b880마지막 보스|r" or "",
            elemTag(def.elem), def.melee and "근접" or "원거리"))
        for k, sk in ipairs(def.skills) do
            if k <= count then
                add("  " .. sk.name .. ":  " .. sk.desc)
            else
                add("  |cff6b6e75" .. sk.name .. " (" .. Tables.DIFFICULTY_NAMES[k - 1] .. " 난이도부터)|r")
            end
        end
    end
    return table.concat(lines, "\n")
end

local function partyExpText(s, level)
    local parts = {}
    for _, id in ipairs(s.party) do
        local h = s.heroes[id]
        parts[#parts + 1] = string.format("%s %d%%", Heroes.byId[id].name, Level.expPenalty(h.level, level) * 100 + 0.5)
    end
    return "|cffe8e8ea경험치 획득 비율|r  " .. table.concat(parts, "   ")
end

local function bossLines(add, ids, count, numbered)
    for i, id in ipairs(ids) do
        local def = Monsters.defs[id]
        add("")
        add(string.format("|cffd9b05e%s%s|r%s  |cff6b6e75%s 피해 · %s|r", numbered and (i .. ". ") or "", def.name,
            numbered and i == #ids and "  |cff70b880마지막 보스|r" or "", elemTag(def.elem), def.melee and "근접" or "원거리"))
        for k, sk in ipairs(def.skills or {}) do
            if not count or k <= count then add("  " .. sk.name .. ":  " .. sk.desc) end
        end
    end
end

-- 원정의 상세: 강도의 강화, 몬스터, 강도별 보스, 보상
local function expeditionText(s, d, n)
    local sec = ExpeditionData.EXPEDITIONS[d]
    local stage = Tables.STAGES[Expeditions.keys[d][n]]
    local b = ExpeditionTable.INTENSITY[n]
    local lines = {}
    local function add(t) lines[#lines + 1] = t end
    add(partyExpText(s, stage.level))
    add("")
    add(string.format("|cffe8e8ea강도 %d|r  몬스터 체력 +%s%%  ·  공격력 +%s%%  ·  이동속도 +%s%%", n, UI.number(b[1] / 10), UI.number(b[2] / 10), UI.number(b[3] / 10)))
    add("강도를 클리어하면 다음 강도가 열립니다. 자동 진행이 켜져 있으면 다음 강도로, 전멸하고 재시도가 꺼져 있으면 한 강도 아래로 갑니다.")
    add(string.format("원정에 있는 동안 보급품이 분당 1씩 줄고, 0이 되면 던전으로 돌아갑니다. 밖에서는 10분에 1씩 찹니다. 큐브의 부식으로도 채웁니다."))
    add("")
    add("|cffe8e8ea얻는 것|r  오염된 유물함·유물(큐브의 기원 → 유물), 역병 열매(부식), " .. WIH.Materials.name(Expeditions.NAXX_TOKEN[d]) .. "(낙스라마스 입장)")
    add("")
    add("|cffe8e8ea등장 몬스터|r")
    for _, m in ipairs(sec.mobs) do
        local def = Monsters.defs[m.id]
        add(string.format("%s  |cff6b6e75%s · %s 피해|r", def.name, ARCHETYPE_TEXT[def.archetype] or def.archetype, elemTag(def.elem)))
    end
    add("")
    local turn = WIH.Runner.rotationTurn(n, #sec.bosses)
    add("|cffe8e8ea이 강도의 보스|r  (강도마다 다른 보스가 나오고, 강도 20은 마지막 보스입니다)")
    bossLines(add, { sec.bosses[turn] })
    return table.concat(lines, "\n")
end

local function naxxText(s, d, a)
    local raid = ExpeditionData.NAXX[a]
    local stage = Tables.STAGES[Expeditions.naxxKeys[d][a]]
    local lines = {}
    local function add(t) lines[#lines + 1] = t end
    add(partyExpText(s, stage.level))
    add("")
    add("|cffe8e8ea진행|r  보스 " .. #raid.bosses .. "명을 차례로 상대합니다. 입장에 " .. WIH.Materials.name(Expeditions.NAXX_TOKEN[d])
        .. " 1개가 필요하고, 클리어했을 때만 쓰입니다. 클리어하면 오염된 레이드 상자를 받습니다.")
    bossLines(add, raid.bosses, nil, true)
    return table.concat(lines, "\n")
end

local function setInfoTop(f, top)
    if f.infoTop == top then return end
    f.infoTop = top
    f.info:ClearAllPoints()
    f.info:SetPoint("TOPLEFT", 0, top)
    f.info:SetPoint("BOTTOMRIGHT", 0, 0)
end

local function paintSpecialList(f, s)
    local d = f.difficulty
    local hasExp = ExpeditionData.EXPEDITIONS[d] ~= nil
    f.expRow:SetShown(hasExp)
    for a, b in ipairs(f.naxxRows) do b:SetShown(hasExp) end
    f.specialHint:SetShown(not hasExp)
    f.specialHint:SetText("원정과 낙스라마스는 악몽 난이도부터 있습니다.")
    if not hasExp then
        if f.special then f.special = nil end
        return
    end
    local open = Expeditions.unlocked(s, d)
    local cur = s.stage.expedition and Tables.STAGES[s.stage.expedition]
    local inside = cur and cur.expedition and cur.expedition.difficulty == d
    f.expRow:setText("원정 · " .. Expeditions.NAMES[d])
    f.expRow:setSelected(f.special == "exp")
    f.expRow.right:SetText(inside and ("진행 중 · 강도 " .. cur.expedition.intensity) or (open and ("최고 강도 " .. Expeditions.highest(s, d)) or "잠김"))
    f.expRow.right:SetTextColor(UI.rgb(inside and C.good or (open and C.warn or C.dim)))
    f.expRow.label:SetTextColor(UI.rgb(open and C.text or C.dim))
    for a, b in ipairs(f.naxxRows) do
        local key = Expeditions.naxxKeys[d][a]
        local nOpen = Expeditions.naxxUnlocked(s, d, a)
        local running = s.stage.raidKey == key
        b:setSelected(f.special == a)
        b.right:SetText((running and "진행 중 · " or "") .. (nOpen and ("Lv " .. Tables.STAGES[key].level) or "잠김"))
        b.right:SetTextColor(UI.rgb(running and C.good or (nOpen and C.warn or C.dim)))
        b.label:SetTextColor(UI.rgb(nOpen and C.text or C.dim))
    end
end

-- 원정·낙스라마스의 상세. 그렸으면 참.
local function paintSpecial(f, s)
    local d = f.difficulty
    f.intensityRow:SetShown(f.special == "exp")
    f.leave:Hide()
    if not f.special then setInfoTop(f, -50); return false end
    for _, b in pairs(f.rows) do b:setSelected(false) end
    if f.special == "exp" then
        local open = Expeditions.unlocked(s, d)
        local cur = s.stage.expedition and Tables.STAGES[s.stage.expedition]
        local inside = cur and cur.expedition and cur.expedition.difficulty == d
        if not f.intensity then
            f.intensity = inside and cur.expedition.intensity or math.max(1, math.min(20, Expeditions.highest(s, d) + 1))
            if not Expeditions.intensityUnlocked(s, d, f.intensity) then f.intensity = math.max(1, Expeditions.highest(s, d)) end
        end
        local n = f.intensity
        local stage = Tables.STAGES[Expeditions.keys[d][n]]
        for i, b in ipairs(f.intensityBtns) do
            local ok = Expeditions.intensityUnlocked(s, d, i)
            b:setEnabled(ok)
            b:setSelected(i == n)
            local cleared = (s.stage.cleared[Expeditions.keys[d][i]] or 0) > 0
            b.label:SetTextColor(UI.rgb(inside and cur.expedition.intensity == i and C.good or (cleared and C.sub or (ok and C.text or C.dim))))
        end
        f.supplyBar:set(s.supply / Expeditions.SUPPLY_MAX)
        f.supplyText:SetText(string.format("원정 보급품  %d / %d  (입장 %d 이상)", math.floor(s.supply), Expeditions.SUPPLY_MAX, Expeditions.SUPPLY_ENTRY))
        f.name:SetText(Expeditions.NAMES[d] .. " 원정")
        f.meta:SetText(string.format("%s  ·  %s  ·  스테이지 레벨 %d  ·  웨이브 %d  ·  웨이브당 %d마리", Tables.DIFFICULTY_NAMES[d],
            ExpeditionData.EXPEDITIONS[d].zone, stage.level, stage.waves, stage.perWave))
        local here = inside and cur.expedition.intensity == n
        f.go:setText(here and "진행 중" or (inside and ("강도 " .. n .. "(으)로 이동") or ("원정 시작 · 강도 " .. n)))
        f.go:setEnabled(open and not here and Expeditions.intensityUnlocked(s, d, n) and (inside and s.supply > 0 or s.supply >= Expeditions.SUPPLY_ENTRY))
        f.leave:SetShown(inside == true)
        if not open then
            f.state:SetText("이 난이도의 첫 레이드(" .. Raids.byAct[1].name .. ")를 클리어하면 열립니다.")
        elseif not inside and s.supply < Expeditions.SUPPLY_ENTRY then
            f.state:SetText("보급품이 " .. Expeditions.SUPPLY_ENTRY .. " 이상 있어야 들어갑니다.")
        else
            f.state:SetText("클리어 " .. (s.stage.cleared[Expeditions.keys[d][n]] or 0) .. "회")
        end
        setInfoTop(f, -108)
        f.body:SetText(expeditionText(s, d, n))
    else
        local a = f.special
        local raid = ExpeditionData.NAXX[a]
        local key = Expeditions.naxxKeys[d][a]
        local stage = Tables.STAGES[key]
        local token = Expeditions.NAXX_TOKEN[d]
        local have = s.materials[token] or 0
        f.name:SetText(raid.name)
        f.meta:SetText(string.format("%s  ·  스테이지 레벨 %d  ·  보스 %d명  ·  %s %d개", Tables.DIFFICULTY_NAMES[d], stage.level, #raid.bosses,
            WIH.Materials.name(token), have))
        local running = s.stage.raidKey == key
        local open = Expeditions.naxxUnlocked(s, d, a)
        f.go:setText(running and "진행 중" or "낙스라마스 시작 (증표 1개)")
        f.go:setEnabled(open and not running and have > 0)
        if not open then f.state:SetText("이 난이도의 액트 " .. a .. " 레이드를 클리어하면 열립니다.")
        elseif have < 1 then f.state:SetText("증표가 없습니다. 원정 상자에서 나옵니다.")
        else f.state:SetText("클리어 " .. (s.stage.cleared[key] or 0) .. "회") end
        setInfoTop(f, -50)
        f.body:SetText(naxxText(s, d, a))
    end
    f.info:setHeight((f.body:GetStringHeight() or 400) + 10)
    return true
end

local function startSpecial(f)
    local s = App.state
    local d = f.difficulty
    local ok, why
    if f.special == "exp" then
        ok, why = Expeditions.start(s, d, f.intensity or 1)
        if ok then
            App.restartStage()
            WIH.Main.notice(Expeditions.NAMES[d] .. " 원정 강도 " .. f.intensity .. "(으)로 들어갔습니다.", C.good)
        end
    else
        ok, why = Expeditions.startNaxx(s, d, f.special)
        if ok then
            App.restartStage()
            WIH.Main.notice(ExpeditionData.NAXX[f.special].name .. "를 시작했습니다.", C.good)
        end
    end
    if not ok then WIH.Main.notice(why, C.bad) end
    UI.screens.stage.refresh(f)
end

local function refresh(f)
    local s = App.state
    if not s then return end
    if not f.difficulty then f.difficulty = s.stage.difficulty end
    if not f.section or not Dungeons.sections[f.section] then f.section = s.stage.section end
    local highest = 1
    for d = 1, 4 do
        local open = Game.stageUnlocked(s, Dungeons.stageKey(d, 101))
        if open then highest = d end
        f.tabs[d]:setEnabled(open)
        f.tabs[d]:setSelected(d == f.difficulty)
    end
    f.tabHint:SetText(highest < 4 and "다음 난이도는 앞 난이도의 마지막 레이드를 클리어하면 열립니다." or "")

    local rune = Runes.total(s, "WaveCountReduction")
    for key, b in pairs(f.rows) do
        local stageKey = Dungeons.stageKey(f.difficulty, key)
        local stage = Tables.STAGES[stageKey]
        local open = Game.stageUnlocked(s, stageKey)
        local cleared = s.stage.cleared[stageKey] or 0
        local here = s.stage.difficulty == f.difficulty and s.stage.section == key
        b:setSelected(key == f.section)
        b.right:SetText((here and "진행 중 · " or "") .. (open and ("Lv " .. stage.level) or "잠김"))
        b.right:SetTextColor(UI.rgb(here and C.good or (open and (cleared > 0 and C.sub or C.text) or C.dim)))
        b.label:SetTextColor(UI.rgb(open and C.text or C.dim))
    end

    paintSpecialList(f, s)
    for act, rb in pairs(f.raidRows) do
        local key = Raids.key(f.difficulty, act)
        local open = Game.stageUnlocked(s, key)
        local running = s.stage.raidKey == key
        rb:setSelected(f.raidAct == act)
        rb.right:SetText((running and "진행 중 · " or "") .. (open and ("Lv " .. Tables.STAGES[key].level) or "잠김"))
        rb.right:SetTextColor(UI.rgb(running and C.good or (open and C.warn or C.dim)))
        rb.label:SetTextColor(UI.rgb(open and C.text or C.dim))
    end
    if paintSpecial(f, s) then return end
    if f.raidAct then
        for _, b in pairs(f.rows) do b:setSelected(false) end
        local raid = Raids.byAct[f.raidAct]
        local key = Raids.key(f.difficulty, f.raidAct)
        local stage = Tables.STAGES[key]
        local tokens = Game.raidTokens(s, f.difficulty)
        f.name:SetText(raid.name)
        f.meta:SetText(string.format("%s 레이드  ·  %s  ·  스테이지 레벨 %d  ·  보스 %d명  ·  %s %d개", Tables.DIFFICULTY_NAMES[f.difficulty],
            raid.zone, stage.level, #raid.bosses, Raids.TOKEN_NAME, tokens))
        local running = s.stage.raidKey == key
        local can, why = Game.canStartRaid(s, f.difficulty, f.raidAct)
        f.go:setEnabled(can and not running)
        f.go:setText(running and "진행 중" or ("레이드 시작 (" .. Raids.TOKEN_NAME .. " 1개)"))
        local cleared = s.stage.cleared[key] or 0
        f.state:SetText(can and ("클리어 " .. cleared .. "회") or (why .. (cleared > 0 and ("  ·  클리어 " .. cleared .. "회") or "")))
        f.body:SetText(raidText(s, f.difficulty, f.raidAct))
        f.info:setHeight((f.body:GetStringHeight() or 400) + 10)
        return
    end

    local sec = Dungeons.sections[f.section]
    local stageKey = Dungeons.stageKey(f.difficulty, f.section)
    local stage = Tables.STAGES[stageKey]
    local open = Game.stageUnlocked(s, stageKey)
    local waves = math.max(1, stage.waves - rune)
    f.name:SetText(sec.name)
    f.meta:SetText(string.format("%s  ·  %s  ·  스테이지 레벨 %d  ·  웨이브 %d%s  ·  웨이브당 %d마리", Tables.DIFFICULTY_NAMES[f.difficulty],
        sec.zone, stage.level, waves, rune > 0 and (" (룬 -" .. rune .. ")") or "", stage.perWave))
    local here = s.stage.difficulty == f.difficulty and s.stage.section == f.section
    f.go:setEnabled(open and not here)
    f.go:setText(here and "진행 중" or "이 스테이지로 이동")
    local cleared = s.stage.cleared[stageKey] or 0
    f.state:SetText(open and ("클리어 " .. cleared .. "회") or "앞 스테이지를 클리어하면 열립니다")
    f.body:SetText(detailText(s, f.difficulty, f.section))
    f.info:setHeight((f.body:GetStringHeight() or 400) + 10)
end

-- 여러 줄 글자의 높이는 배치가 끝난 뒤에야 정확하다. 보이는 동안 가끔 다시 재서 스크롤 범위를 맞춘다.
local function update(f, elapsed)
    f.acc = (f.acc or 0) + elapsed
    if f.acc < 0.5 then return end
    f.acc = 0
    f.info:setHeight((f.body:GetStringHeight() or 400) + 10)
end

UI.screens.stage = { label = "스테이지", order = 4, create = create, refresh = refresh, update = update, startSpecial = startSpecial }
