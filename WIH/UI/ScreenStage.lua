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

local C = UI.C
local ACT_RAIDS = { "오닉시아의 둥지", "화산 심장부", "검은날개 둥지" }       -- 설계 문서 9절의 대응
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
        -- 레이드(액트 보스 자리)는 아직 들어오지 않았다. 누를 수 없는 안내 줄로만 둔다.
        local raid = UI.text(f.list.content, 11, C.dim)
        raid:SetPoint("TOPLEFT", 8, -y - 5)
        raid:SetText("레이드  ·  " .. ACT_RAIDS[act] .. "  (미구현)")
        f.raidRows[act] = raid
        y = y + 28
    end
    f.list:setHeight(y)

    local d = CreateFrame("Frame", nil, f)
    d:SetPoint("TOPLEFT", f.list, "TOPRIGHT", 14, 0)
    d:SetPoint("BOTTOMRIGHT", -10, 10)
    f.detail = d
    f.name = UI.text(d, 15, C.text)
    f.name:SetPoint("TOPLEFT", 0, 0)
    f.meta = UI.text(d, 12, C.sub)
    f.meta:SetPoint("TOPLEFT", f.name, "BOTTOMLEFT", 0, -6)
    f.go = UI.button(d, "이 스테이지로 이동", 150, 26, function()
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

    f.info = UI.scroll(d)
    f.info:SetPoint("TOPLEFT", 0, -50)
    f.info:SetPoint("BOTTOMRIGHT", 0, 0)
    f.body = UI.paragraph(f.info.content, 12, C.sub)
    f.body:SetPoint("TOPLEFT", 0, 0)
    f.body:SetPoint("RIGHT", -4, 0)
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

UI.screens.stage = { label = "스테이지", order = 4, create = create, refresh = refresh, update = update }
