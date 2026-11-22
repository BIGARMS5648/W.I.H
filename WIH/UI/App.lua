-- 애드온의 진입점: 저장 불러오기, 연속 진행 구동, 명령어. WoW API를 쓰는 층이다.
-- 게임 내 확인(2026-11-22): ADDON_LOADED와 PLAYER_LOGOUT에서의 SavedVariables 읽기·쓰기, C_Timer, debugprofilestop 사용 가능.

local addonName, WIH = ...
local Game = WIH.module("Game")
local Save = WIH.module("Save")
local Session = WIH.module("Session")
local Runes = WIH.module("Runes")
local App = WIH.module("App")

App.state = nil          -- 진행 중인 게임 상태(없으면 진영 선택부터)
App.session = nil
App.loadInfo = nil       -- 저장을 불러온 결과 {status, notes}
App.readOnly = false     -- 더 새 버전의 저장을 만났을 때: 아무것도 덮어쓰지 않는다
App.lastErrors = {}
App.watchers = {}        -- 상태가 바뀌었을 때 알림을 받을 화면들
App.log = {}             -- 최근 진행 기록(문장). 사냥 띠와 기록 화면이 읽는다
App.lastLoot = nil       -- 가장 최근에 얻은 것의 표기
local LOG_LIMIT = 40

local function stageName(key)
    local n = key % 1000
    if n % 100 == 10 then
        local raid = WIH.Raids.byAct[math.floor(n / 100)]
        return raid and (raid.name .. " 레이드") or ""
    end
    local sec = WIH.Dungeons.sections[n]
    return sec and sec.name or ""
end
App.stageName = stageName

function App.addLog(line)
    local log = App.log
    log[#log + 1] = line
    while #log > LOG_LIMIT do table.remove(log, 1) end
end

-- 진행 이벤트를 기록 문장으로 바꾼다.
local function record(ev, a, b, c)
    local Chests, Items = WIH.Chests, WIH.Items
    if ev == "boss" and a then
        App.addLog("보스 등장: " .. a.name)
    elseif ev == "clear" then
        App.addLog("|cff70b880클리어|r  " .. stageName(a))
    elseif ev == "fail" then
        App.addLog("|cffd06058전멸|r  " .. stageName(a))
    elseif ev == "levelUp" then
        App.addLog(WIH.Heroes.byId[a].name .. " 레벨 " .. b)
    elseif ev == "firstClear" then
        local names = {}
        for _, item in ipairs(a) do names[#names + 1] = Items.name(item) end
        App.lastLoot = table.concat(names, ", ")
        App.addLog("|cffd9b05e첫 클리어 보상|r  " .. App.lastLoot .. "  (가방에서 장착하세요)")
    elseif ev == "chest" then
        App.addLog(Chests.NAMES[a] .. "를 얻었습니다.")
    elseif ev == "loot" then
        App.lastLoot = Chests.resultText(b)
        App.addLog(Chests.NAMES[a] .. " 자동 개봉: " .. App.lastLoot)
    elseif ev == "token" then
        App.addLog("|cffd9b05e" .. WIH.Raids.TOKEN_NAME .. "|r 1개를 얻었습니다. 스테이지 화면에서 레이드에 도전할 수 있습니다.")
    elseif ev == "raidClear" then
        if b == "opened" then App.lastLoot = Chests.resultText(c) end
        App.addLog("|cffd9b05e레이드 클리어|r  레이드 상자를 " .. (b == "opened" and ("바로 열었습니다: " .. App.lastLoot) or "받았습니다."))
    elseif ev == "pet" then
        App.addLog("|cffd9b05e새 펫|r  " .. a.name .. "  (" .. WIH.Pets.effectText(a) .. ")")
    elseif ev == "raidUnlocked" then
        local act = math.floor(a % 1000 / 100)
        App.addLog("이 액트의 던전을 모두 돌파했습니다. 다음으로 가려면 스테이지 화면에서 |cffd9b05e" .. WIH.Raids.byAct[act].name .. "|r 레이드를 클리어해야 합니다.")
    end
end

local function now()
    if GetServerTime then return GetServerTime() end
    return time()
end
App.now = now

function App.notify(tag)
    for i = 1, #App.watchers do
        local ok, err = pcall(App.watchers[i], tag)
        if not ok then WIH.UI.reportError(err) end
    end
end

local function startSession()
    local seed = (now() % 100000) + 1
    App.session = Session.new(App.state, { seed = seed })
    App.session:addListener(function(ev, a, b, c)
        if ev ~= "battle" and ev ~= "kill" and ev ~= "wave" and ev ~= "stageStart" then
            local ok, err = pcall(record, ev, a, b, c)
            if not ok then WIH.UI.reportError(err) end
        end
        if ev == "levelUp" or ev == "clear" or ev == "fail" or ev == "stageStart" or ev == "raidUnlocked"
            or ev == "chest" or ev == "loot" or ev == "firstClear" or ev == "raidClear" or ev == "token" or ev == "pet" then
            App.notify(ev)
        end
    end)
end

-- 새 게임을 시작한다(진영과 첫 영웅 선택 뒤).
function App.newGame(faction, starter)
    if App.readOnly then return false, "더 새로운 버전의 저장 데이터가 있어 새 게임을 만들 수 없습니다." end
    App.state = Game.new(faction, starter, now())
    WIH_DB = App.state
    startSession()
    App.notify("newGame")
    return true
end

-- 편성·스킬을 바꾼 뒤 현재 스테이지를 다시 시작해 바로 적용한다.
function App.restartStage()
    if App.session then
        App.session:startStage()
        App.notify("stageStart")
    end
end

-- 전체 초기화: 현재 저장을 백업에 넣고 진영 선택으로 돌아간다.
function App.resetAll()
    if App.readOnly then return false end
    if App.state then
        WIH_DB_BACKUP = Save.pushBackup(WIH_DB_BACKUP, App.state, now())
    end
    App.state, App.session = nil, nil
    App.log, App.lastLoot = {}, nil
    WIH_DB = nil
    App.notify("reset")
    return true
end

-- 백업에서 되돌린다. index = 1이 가장 최근.
function App.restoreBackup(index)
    if App.readOnly or type(WIH_DB_BACKUP) ~= "table" then return false, "백업이 없습니다." end
    local entry = WIH_DB_BACKUP[index]
    if not entry then return false, "백업이 없습니다." end
    local state, info = Save.load(Save.deepCopy(entry.data))
    if not state then return false, "백업을 불러올 수 없습니다." end
    if App.state then WIH_DB_BACKUP = Save.pushBackup(WIH_DB_BACKUP, App.state, now()) end
    App.state = state
    WIH_DB = state
    App.loadInfo = info
    startSession()
    App.notify("restore")
    return true
end

local function onLoaded()
    local raw = WIH_DB
    local before = raw ~= nil and Save.deepCopy(raw) or nil
    local state, info = Save.load(raw)
    App.loadInfo = info
    if info.status == "newer" then
        App.readOnly = true
        return
    end
    if info.status == "broken" or info.status == "fixed" then
        -- 손대기 전의 저장본을 백업에 남긴다.
        if before ~= nil then
            if type(WIH_DB_BACKUP) ~= "table" then WIH_DB_BACKUP = {} end
            table.insert(WIH_DB_BACKUP, 1, { at = now(), data = before, reason = info.status })
            while #WIH_DB_BACKUP > Save.BACKUPS do table.remove(WIH_DB_BACKUP) end
        end
    end
    if state then
        App.state = state
        WIH_DB = state
        Runes.apply(state)
        -- 자리를 비운 시간의 보상. 같은 시간을 두 번 치지 않도록 바로 저장 시각을 지금으로 옮긴다.
        local reward = WIH.Offline.compute(state, now())
        if reward then WIH.Offline.addPending(state, reward) end
        state.savedAt = now()
        startSession()
    else
        WIH_DB = nil
    end
end

local driver = CreateFrame("Frame")
driver:RegisterEvent("ADDON_LOADED")
driver:RegisterEvent("PLAYER_LOGOUT")
driver:SetScript("OnEvent", function(_, event, arg1)
    if event == "ADDON_LOADED" then
        if arg1 ~= addonName then return end
        local ok, err = pcall(onLoaded)
        if not ok then
            App.loadInfo = { status = "broken", notes = { "불러오는 중 오류: " .. tostring(err) } }
            WIH.UI.reportError(err)
        end
        App.loaded = true
        App.notify("loaded")
    elseif event == "PLAYER_LOGOUT" then
        if App.state and not App.readOnly then
            App.state.savedAt = now()
            WIH_DB = App.state
        end
    end
end)

-- 프레임마다 지난 시간만큼 진행한다. 한 프레임의 틱 수에 상한을 둔다.
local NORMAL_TICKS = 4       -- 평소: 60fps에서 프레임당 1틱 미만이므로 충분
local CATCHUP_TICKS = 24     -- 밀렸을 때(로딩 화면 뒤 등)
driver:SetScript("OnUpdate", function(_, elapsed)
    local session = App.session
    if not session or App.paused then return end
    local limit = (session.acc > 1) and CATCHUP_TICKS or NORMAL_TICKS
    local ok, err = pcall(session.advance, session, elapsed, limit)
    if not ok then
        -- 같은 오류가 프레임마다 반복되지 않게 멈추고 알린다.
        App.paused = true
        WIH.UI.reportError(err)
        App.notify("error")
    end
end)

-- /wih : 메뉴 창을 여닫는다.  /wih 띠 : 사냥 띠를 보이거나 숨긴다.
SLASH_WIH1 = "/wih"
SlashCmdList["WIH"] = function(msg)
    msg = type(msg) == "string" and msg:lower() or ""
    if (msg:find("띠") or msg:find("strip")) and WIH.Strip then
        WIH.Strip.toggleHidden()
    elseif WIH.Main then
        WIH.Main.toggle()
    end
end

function WIH_OnCompartmentClick()
    if WIH.Main then WIH.Main.toggle() end
end

return App
