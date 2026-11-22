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

    -- 기록
    section(f, "기록", -376)
    f.stats = UI.paragraph(f, 11, C.sub)
    f.stats:SetPoint("TOPLEFT", 14, -404)
    f.stats:SetPoint("TOPRIGHT", -14, -404)

    -- 오류
    f.errorTitle = section(f, "최근 오류", -446)
    f.errors = UI.paragraph(f, 11, C.bad)
    f.errors:SetPoint("TOPLEFT", 14, -474)
    f.errors:SetPoint("TOPRIGHT", -130, -474)
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
    lines[#lines + 1] = "저장은 접속 종료나 화면 다시 불러오기 때 클라이언트가 기록합니다."
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

    local st = s.stats
    local version = C_AddOns and C_AddOns.GetAddOnMetadata and C_AddOns.GetAddOnMetadata(addonName, "Version") or "?"
    f.stats:SetText(string.format("진행 시간 %s   ·   처치 %s   ·   보스 처치 %s   ·   클리어 %s   ·   전멸 %s   ·   번 골드 %s\n버전 %s   ·   최대 레벨 %d   ·   전투 계산 간격 %.2f초",
        duration(st.playSeconds), UI.number(st.kills), UI.number(st.bossKills), UI.number(st.clears), UI.number(st.fails),
        UI.number(math.floor(st.goldEarned)), tostring(version), Tables.MAX_LEVEL, WIH.TICK))

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
