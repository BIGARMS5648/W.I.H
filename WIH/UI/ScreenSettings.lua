-- 설정 화면: 진영, 진행 방식, 저장 데이터(상태·백업·초기화), 기록, 최근 오류.

local addonName, WIH = ...
local UI = WIH.module("UI")
local App = WIH.module("App")
local Game = WIH.module("Game")
local Save = WIH.module("Save")
local Tables = WIH.module("Tables")

local C = UI.C
local STATUS_TEXT = {
    new = "새 게임", ok = "정상", fixed = "일부를 바로잡고 불러옴", broken = "불러오지 못함", newer = "더 새로운 버전의 저장",
}

local function stamp(t)
    if not t or t <= 0 then return "시각 알 수 없음" end
    if date then return date("%Y-%m-%d %H:%M", t) end
    return tostring(t)
end

local function duration(sec)
    sec = math.floor(sec or 0)
    local h, m = math.floor(sec / 3600), math.floor(sec % 3600 / 60)
    if h > 0 then return h .. "시간 " .. m .. "분" end
    return m .. "분 " .. (sec % 60) .. "초"
end

local function backupSummary(entry)
    local data = entry and entry.data
    if type(data) ~= "table" or type(data.heroes) ~= "table" then return "내용을 읽을 수 없음" end
    local count, top = 0, 0
    for _, h in pairs(data.heroes) do
        if type(h) == "table" then
            count = count + 1
            if type(h.level) == "number" and h.level > top then top = h.level end
        end
    end
    local gold = type(data.gold) == "number" and data.gold or 0
    return string.format("영웅 %d명 · 최고 레벨 %d · %s G", count, top, UI.number(math.floor(gold)))
end

local function section(f, title, y)
    local t = UI.text(f, 12, C.sub)
    t:SetPoint("TOPLEFT", 14, y)
    t:SetText(title)
    local line = UI.fill(f, C.line, "ARTWORK")
    line:SetPoint("TOPLEFT", 14, y - 18)
    line:SetPoint("TOPRIGHT", -14, y - 18)
    line:SetHeight(1)
    return t
end

local function create(parent)
    local f = CreateFrame("Frame", nil, parent)

    -- 진영
    section(f, "진영", -14)
    f.factions = {}
    for i, fac in ipairs({ { "Alliance", "얼라이언스" }, { "Horde", "호드" } }) do
        local b = UI.button(f, fac[2], 110, 26, function()
            local ok, why = Game.setFaction(App.state, fac[1])
            if not ok then WIH.Main.notice(why, C.bad) end
            WIH.Main.show("settings")      -- 강조색이 바뀌므로 메뉴까지 다시 칠한다
        end)
        b:SetPoint("TOPLEFT", 14 + (i - 1) * 116, -42)
        f.factions[fac[1]] = b
    end
    local factionHint = UI.text(f, 11, C.dim)
    factionHint:SetPoint("LEFT", f.factions.Horde, "RIGHT", 14, 0)
    factionHint:SetText("화면의 강조색이 바뀝니다. 영웅과 콘텐츠는 같습니다.")

    -- 진행 방식
    section(f, "진행 방식", -84)
    f.toggles = {}
    local defs = {
        { "autoAdvance", "자동 진행", "클리어하면 다음 스테이지로 넘어갑니다." },
        { "repeatMode", "반복", "클리어해도 같은 스테이지를 반복합니다. 자동 진행보다 먼저 적용됩니다." },
        { "autoRetry", "실패 시 재시도", "전멸하면 같은 스테이지를 다시 합니다. 끄면 이전 스테이지로 내려갑니다." },
    }
    for i, def in ipairs(defs) do
        local b = UI.button(f, def[2], 110, 26, function(self)
            local s = App.state.settings
            s[def[1]] = not s[def[1]]
            UI.screens.settings.refresh(f)
        end)
        b:SetPoint("TOPLEFT", 14 + (i - 1) * 116, -112)
        b.tooltip = { title = def[2], lines = { def[3] } }
        b.key = def[1]
        f.toggles[i] = b
    end
    f.toggleHint = UI.text(f, 11, C.dim)
    f.toggleHint:SetPoint("LEFT", f.toggles[3], "RIGHT", 14, 0)

    -- 저장 데이터
    section(f, "저장 데이터", -154)
    f.saveInfo = UI.paragraph(f, 11, C.sub)
    f.saveInfo:SetPoint("TOPLEFT", 14, -182)
    f.saveInfo:SetPoint("TOPRIGHT", -14, -182)
    f.backups = {}
    for i = 1, Save.BACKUPS do
        local row = CreateFrame("Frame", nil, f)
        row:SetHeight(26)
        row:SetPoint("TOPLEFT", 14, -236 - (i - 1) * 30)
        row:SetPoint("TOPRIGHT", -14, -236 - (i - 1) * 30)
        row.text = UI.text(row, 11, C.sub)
        row.text:SetPoint("LEFT", 0, 0)
        row.restore = UI.button(row, "이 백업으로 되돌리기", 150, 24, function()
            local ok, why = App.restoreBackup(i)
            WIH.Main.notice(ok and "백업으로 되돌렸습니다. 직전 상태는 백업 1번에 남겼습니다." or why, ok and C.good or C.bad)
        end)
        row.restore:SetPoint("RIGHT", 0, 0)
        f.backups[i] = row
    end
    f.noBackup = UI.text(f, 11, C.dim)
    f.noBackup:SetPoint("TOPLEFT", 14, -240)
    f.noBackup:SetText("백업이 없습니다. 전체 초기화나 되돌리기를 하면 그 직전 상태가 백업으로 남습니다(최대 " .. Save.BACKUPS .. "개).")

    f.reset = UI.button(f, "전체 초기화", 150, 26, function(self)
        local t = GetTime and GetTime() or 0
        if f.resetArmed and t < f.resetArmed then
            f.resetArmed = nil
            App.resetAll()
            return
        end
        f.resetArmed = t + 5
        self:setText("한 번 더 누르면 초기화")
        WIH.Main.notice("5초 안에 한 번 더 누르면 처음부터 다시 시작합니다. 현재 상태는 백업에 남습니다.", C.warn)
    end)
    f.reset:SetPoint("TOPLEFT", 14, -334)
    f.reset.tooltip = { title = "전체 초기화", lines = { "진영 선택부터 다시 시작합니다. 현재 상태는 백업 1번으로 남아 되돌릴 수 있습니다." } }

    -- 화면: 전투 표시와 사냥 띠
    section(f, "화면", -376)
    f.display = {}
    local function opt(label, width, tip, onClick)
        local b = UI.button(f, label, width, 26, function(self)
            onClick(self)
            UI.screens.settings.refresh(f)
        end)
        b.tooltip = { title = label, lines = { tip } }
        local prev = f.display[#f.display]
        if prev then b:SetPoint("LEFT", prev, "RIGHT", 6, 0) else b:SetPoint("TOPLEFT", 14, -404) end
        f.display[#f.display + 1] = b
        return b
    end
    f.optModels = opt("3D 모델", 86, "전투 장면과 영웅 화면에 캐릭터 모델을 씁니다. 끄면 아이콘으로 표시합니다.", function()
        local o = WIH.Scene.options()
        o.models = not o.models
        if WIH.Main.built.heroes then WIH.Main.built.heroes.modelKey = nil end
    end)
    f.optLooks = opt("장비 룩", 76, "영웅이 낀 장비대로 옷과 무기를 입은 모습으로 보여 줍니다. 끄면 직업별 고정 모델을 씁니다.", function()
        local o = WIH.Scene.options()
        o.looks = not (o.looks ~= false)
        if WIH.Strip.scene then WIH.Strip.scene.battle = nil end
    end)
    f.optFlip = opt("방향 뒤집기", 96, "모델이 반대쪽을 보고 있을 때 켭니다(영웅은 오른쪽, 적은 왼쪽을 봐야 합니다).", function()
        local o = WIH.Scene.options()
        o.modelFlip = not o.modelFlip
    end)
    f.optLimit = opt("", 86, "전투 장면에서 모델로 보여 줄 수의 상한입니다. 영웅과 보스는 늘 모델로 보여 주고, 나머지 적은 이 수까지만 모델로 보여 줍니다. 화면이 끊기면 낮추세요.", function()
        local o = WIH.Scene.options()
        local steps = { 4, 8, 12, 20, 30 }
        local nextValue = steps[1]
        for i, v in ipairs(steps) do
            if o.modelLimit == v then nextValue = steps[i % #steps + 1] end
        end
        o.modelLimit = nextValue
        if WIH.Strip.scene then WIH.Strip.scene.battle = nil end      -- 장면을 다시 꾸민다
    end)
    f.optStrip = opt("", 86, "사냥 띠를 숨기거나 다시 보입니다. 숨겨도 사냥은 계속됩니다. 채팅창에 /wih 띠 를 입력해도 됩니다.", function()
        WIH.Strip.toggleHidden()
    end)
    f.optLock = opt("", 92, "사냥 띠를 끌어서 옮기거나 폭을 바꾸지 못하게 고정합니다.", function()
        WIH.Strip.setLocked(not WIH.Strip.saved().locked)
    end)
    opt("띠 위치 초기화", 100, "사냥 띠를 처음 자리(화면 아래 가운데)와 처음 폭으로 되돌립니다.", function()
        WIH.Strip.resetPlace()
    end)
    opt("모델 점검", 76, "영웅과 몬스터의 모델이 제대로 나오는지 한눈에 봅니다. 잘못 나오는 것을 알려 주시면 고칩니다.", function()
        WIH.Main.show("modelcheck")
    end)

    -- 오류
    f.errorTitle = section(f, "최근 오류", -446)
    f.errors = UI.paragraph(f, 11, C.bad)
    f.errors:SetPoint("TOPLEFT", 14, -474)
    f.errors:SetPoint("TOPRIGHT", -130, -474)
    f.errors:SetHeight(44)
    f.resume = UI.button(f, "진행 다시 시작", 110, 24, function()
        App.paused = false
        App.restartStage()
        UI.screens.settings.refresh(f)
    end)
    f.resume:SetPoint("TOPRIGHT", -14, -470)
    f.resume.tooltip = { title = "진행 다시 시작", lines = { "오류로 멈춘 진행을 현재 스테이지의 처음부터 다시 시작합니다." } }
    f.acc = 0
    return f
end

local function refresh(f)
    local s = App.state
    if not s then return end
    for id, b in pairs(f.factions) do b:setSelected(s.faction == id) end
    for _, b in ipairs(f.toggles) do b:setSelected(s.settings[b.key]) end
    f.toggleHint:SetText(s.settings.repeatMode and "반복이 켜져 있어 같은 스테이지에 머뭅니다." or "")

    local info = App.loadInfo or { status = "new", notes = {} }
    local lines = { "불러오기 결과: " .. (STATUS_TEXT[info.status] or info.status)
        .. "   ·   저장 형식 " .. tostring(s.schema) .. "   ·   시작 " .. stamp(s.createdAt) .. "   ·   마지막 저장 " .. stamp(s.savedAt) }
    for i = 1, math.min(2, #(info.notes or {})) do lines[#lines + 1] = "· " .. info.notes[i] end
    if #(info.notes or {}) > 2 then lines[#lines + 1] = "· 그 밖에 " .. (#info.notes - 2) .. "건" end
    local version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
    lines[#lines + 1] = "저장은 접속 종료나 화면 다시 불러오기 때 클라이언트가 기록합니다.   ·   버전 " .. tostring(version)
    f.saveInfo:SetText(table.concat(lines, "\n"))

    local list = type(WIH_DB_BACKUP) == "table" and WIH_DB_BACKUP or {}
    for i, row in ipairs(f.backups) do
        local entry = list[i]
        row:SetShown(entry ~= nil)
        if entry then
            row.text:SetText(string.format("백업 %d   %s   %s%s", i, stamp(entry.at), backupSummary(entry),
                entry.reason and ("   (" .. (STATUS_TEXT[entry.reason] or entry.reason) .. " 때의 원본)") or ""))
        end
    end
    f.noBackup:SetShown(#list == 0)
    f.reset:setText("전체 초기화")
    f.resetArmed = nil

    local o = WIH.Scene.options()
    f.optModels:setSelected(o.models)
    f.optFlip:setSelected(o.modelFlip == true)
    f.optLooks:setSelected(o.looks ~= false)
    f.optLimit:setText("모델 수 " .. o.modelLimit)
    f.optStrip:setText(WIH.Strip.saved().hidden and "띠 보이기" or "띠 숨기기")
    f.optLock:setText(WIH.Strip.saved().locked and "띠 고정 해제" or "띠 고정")
    f.optLock:setSelected(WIH.Strip.saved().locked == true)

    local errs = App.lastErrors
    if #errs == 0 then
        f.errors:SetText("|cff6b6e75기록된 오류가 없습니다.|r")
    else
        local out = {}
        for i = math.max(1, #errs - 2), #errs do out[#out + 1] = errs[i] end
        f.errors:SetText(table.concat(out, "\n"))
    end
    f.resume:SetShown(App.paused == true)
end

-- 진행 시간과 처치 수는 계속 바뀐다. 2초마다 다시 적는다(초기화 확인 중에는 버튼 글자를 지키기 위해 건너뛴다).
local function update(f, elapsed)
    f.acc = f.acc + elapsed
    if f.acc < 2 then return end
    f.acc = 0
    if f.resetArmed then
        if (GetTime and GetTime() or 0) < f.resetArmed then return end
    end
    refresh(f)
end

UI.screens.settings = { label = "설정", order = 7, create = create, refresh = refresh, update = update }
