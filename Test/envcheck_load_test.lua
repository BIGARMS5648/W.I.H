-- 환경 점검 애드온을 WoW API 대역 위에서 불러와 주요 경로를 실행한다.
-- 실행: lua5.1 Test/envcheck_load_test.lua   (저장소 최상위에서)

package.path = "./?.lua;" .. package.path
local Stub = require("Test.wow_stub")
Stub.install(_G)

local function run(tocName)
    Stub.unknownCalls = {}
    Stub.eventFrames = {}      -- 앞선 실행에서 만든 이벤트 프레임을 버린다 (클라이언트를 새로 켠 상태)
    WIH_EnvCheckFrame = nil
    WIH_EnvCheckDB, WIH_EnvCheckCharDB = nil, nil
    local _, meta, files = Stub.loadAddon("WIH_EnvCheck", tocName, "WIH_EnvCheck")
    assert(meta.Interface == "16001", "Interface 번호가 16001이 아님")
    assert(#files == 1, "TOC의 파일 수가 예상과 다름")

    Stub.fire("ADDON_LOADED", "다른애드온")
    assert(WIH_EnvCheckDB == nil, "다른 애드온의 ADDON_LOADED에 반응함")
    Stub.fire("ADDON_LOADED", "WIH_EnvCheck")
    assert(type(WIH_EnvCheckDB) == "table" and WIH_EnvCheckDB.loads == 1, "저장 테이블 초기화 실패")
    Stub.fire("PLAYER_LOGIN")

    -- 슬래시 명령으로 창을 열고 점검을 실행한다.
    assert(SLASH_WIHCHECK1 == "/wihcheck")
    SlashCmdList.WIHCHECK("")
    local frame = WIH_EnvCheckFrame
    assert(frame and frame:IsShown(), "창이 열리지 않음")
    assert(WIH_EnvCheckDB.runs == 1, "점검이 실행되지 않음")
    local report = table.concat(WIH_EnvCheckDB.lastReport, "\n")
    assert(report:find("GetBuildInfo", 1, true), "보고서에 빌드 정보가 없음")
    assert(not report:find("시험용", 1, true), "캐릭터 이름이 가려지지 않음")
    assert(not report:find("Player-1234", 1, true), "GUID가 가려지지 않음")
    assert(not report:find("TEST KR1", 1, true), "서버 이름이 가려지지 않음")

    -- 창의 모든 버튼을 눌러 본다.
    local clicked = 0
    for _, child in ipairs({ frame:GetChildren() }) do
        if child.__kind == "Button" then
            child:Click()
            clicked = clicked + 1
        end
    end
    assert(clicked >= 5, "버튼 수가 예상보다 적음: " .. clicked)
    Stub.advance(5)

    -- 닫기 버튼으로 닫혔을 수 있으므로 다시 연다.
    if not frame:IsShown() then SlashCmdList.WIHCHECK("") end
    WIH_EnvCheck_OnCompartmentClick()   -- 닫힘
    WIH_EnvCheck_OnCompartmentClick()   -- 열림

    -- 전투 진입과 종료
    Stub.inCombat = true
    Stub.fire("PLAYER_REGEN_DISABLED")
    Stub.fire("ADDON_ACTION_BLOCKED", "WIH_EnvCheck", "Frame:Show()")
    Stub.inCombat = false
    Stub.fire("PLAYER_REGEN_ENABLED")
    assert(type(WIH_EnvCheckDB.lastCombat) == "table" and #WIH_EnvCheckDB.lastCombat >= 5, "전투 중 점검 기록이 없음")

    -- 저장 왕복: 로그아웃 뒤 같은 저장 테이블로 다시 불러온다.
    SlashCmdList.WIHCHECK("")
    SlashCmdList.WIHCHECK("")
    Stub.fire("PLAYER_LOGOUT")
    assert(WIH_EnvCheckDB.lastLogout, "로그아웃 시각이 기록되지 않음")
    local saved, savedChar = WIH_EnvCheckDB, WIH_EnvCheckCharDB
    Stub.eventFrames = {}
    WIH_EnvCheckFrame = nil
    Stub.loadAddon("WIH_EnvCheck", tocName, "WIH_EnvCheck")
    WIH_EnvCheckDB, WIH_EnvCheckCharDB = saved, savedChar
    Stub.fire("ADDON_LOADED", "WIH_EnvCheck")
    assert(WIH_EnvCheckDB.loads == 2, "두 번째 불러오기 횟수가 2가 아님")
    assert(WIH_EnvCheckDB.blobCheck and WIH_EnvCheckDB.blobCheck:find("100000", 1, true), "큰 데이터 왕복 확인 실패")
    assert(WIH_EnvCheckDB.blob == nil, "큰 데이터가 지워지지 않음")
    SlashCmdList.WIHCHECK("")
    local second = table.concat(WIH_EnvCheckDB.lastReport, "\n")
    assert(second:find("저장 왕복", 1, true), "두 번째 보고서에 저장 왕복 줄이 없음")
    assert(second:find("[전투]", 1, true), "두 번째 보고서에 전투 기록이 없음")

    for _, line in ipairs(WIH_EnvCheckDB.lastReport) do
        assert(not line:find("점검 단계 %d+ 중단"), "점검 단계가 오류로 중단됨: " .. line)
    end
    return second
end

local report = run("WIH_EnvCheck.toc")
run("WIH_EnvCheck_Camelot.toc")

if arg and arg[1] == "-v" then
    io.write(report, "\n")
end
local errors = 0
for line in report:gmatch("[^\n]+") do
    if line:find("^%[오류%]") then
        errors = errors + 1
        io.write("대역 환경의 오류 줄: ", line, "\n")
    end
end
io.write(string.format("envcheck_load_test: 통과 (보고서 %d줄, 대역에서의 오류 줄 %d개)\n",
    select(2, report:gsub("\n", "\n")) + 1, errors))
