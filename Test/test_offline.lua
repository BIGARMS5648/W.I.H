-- 오프라인 보상 검사. 실행: lua5.1 Test/test_offline.lua

package.path = "./?.lua;" .. package.path
local T = require("Test.t")
local WIH = require("Test.engine").load()
local Offline, Game, Tables, Runes, Level, Save = WIH.Offline, WIH.Game, WIH.Tables, WIH.Runes, WIH.Level, WIH.Save

local function unlockedState()
    local s = Game.new("Horde", "war_prot", 1000)
    for key, node in pairs(WIH.RuneData.nodes) do
        if node.stat == "UnlockOfflineReward" then s.runes[key] = 1 end
    end
    s.savedAt = 100000
    return s
end

T.case("오프라인 보상: 룬이 없으면 없고, 너무 짧거나 30일 넘게 비우면 없다", function()
    local s = Game.new("Horde", "war_prot", 1000)
    s.savedAt = 100000
    local r, why = Offline.compute(s, 100000 + 3600)
    T.eq(r, nil); T.eq(why, "locked")
    s = unlockedState()
    T.ok(Offline.unlocked(s))
    r, why = Offline.compute(s, 100000 + 30)
    T.eq(r, nil); T.eq(why, "short")
    r, why = Offline.compute(s, 100000 + 31 * 86400)
    T.eq(r, nil); T.eq(why, "guard")
    r, why = Offline.compute(s, 100000 - 500)
    T.eq(r, nil, "시각이 거꾸로 가면 없음")
    T.eq(Runes.INACTIVE.UnlockOfflineReward, nil, "이제 쓰이므로 미적용 표에 없어야 함")
end)

T.case("오프라인 보상: 표의 값 × 시간, 최대 8시간, 룬의 % 반영", function()
    local s = unlockedState()
    -- 일반 1-1(스테이지 레벨 1): 표 = 처치당 골드 1, 경험치 1, 시간당 180처치 [원작]
    local row = Tables.OFFLINE[1]
    T.eq(row[1], 1); T.eq(row[3], 180)
    local r = Offline.compute(s, 100000 + 2 * 3600)
    T.eq(r.seconds, 7200)
    T.eq(r.gold, 360)
    T.eq(r.exp.war_prot, 360, "레벨 1 영웅, 스테이지 레벨 1: 페널티 없음")
    -- 8시간 상한
    r = Offline.compute(s, 100000 + 20 * 3600)
    T.eq(r.seconds, 8 * 3600)
    T.eq(r.gold, 1440)
    -- 룬: 오프라인 골드 +10%씩
    for key, node in pairs(WIH.RuneData.nodes) do
        if node.stat == "OfflineRewardGoldPercent" and not s.runes[key] and r.bonusDone == nil then
            s.runes[key] = 2
            r.bonusDone = node.value[1] + node.value[2]
        end
    end
    local r2 = Offline.compute(s, 100000 + 20 * 3600)
    T.eq(r2.gold, math.floor(1440 * (1 + r.bonusDone / 1000)), "골드 룬 반영")
    -- 높은 스테이지: 표의 값이 커진다
    s.stage.cleared[1101] = 1
    for n = 1, 8 do s.stage.cleared[1100 + n] = 1 end
    Game.selectStage(s, 1, 109)
    local level = Tables.STAGES[1109].level
    local r3 = Offline.compute(s, 100000 + 3600)
    T.eq(r3.level, level)
    T.ok(r3.gold > r2.gold / 8, "스테이지가 높으면 시간당 보상이 큼")
    -- 영웅 레벨이 스테이지보다 한참 낮으면 경험치 페널티
    local full = Tables.OFFLINE[level][2] * Tables.OFFLINE[level][3]
    T.eq(r3.exp.war_prot, math.floor(full * Level.expPenalty(1, level)))
    T.ok(r3.exp.war_prot < full, "레벨 차 페널티가 적용됨")
end)

T.case("오프라인 보상: 받기 전까지 남아 있고, 받으면 골드와 레벨이 오른다", function()
    local s = unlockedState()
    local r = Offline.compute(s, 100000 + 8 * 3600)
    Offline.addPending(s, r)
    T.ok(Offline.pending(s), "받을 것이 있음")
    local gold = s.gold
    -- 저장하고 다시 불러와도 남아 있다
    local state = Save.load(Save.deepCopy(s))
    T.ok(Offline.pending(state), "저장 뒤에도 남아 있음")
    -- 한 번 더 쌓인다
    Offline.addPending(state, r)
    T.eq(Offline.pending(state).gold, r.gold * 2)
    local out = Offline.claim(state)
    T.eq(out.gold, r.gold * 2)
    T.eq(state.gold, gold + r.gold * 2)
    T.ok(state.heroes.war_prot.level > 1, "경험치로 레벨이 오름: " .. state.heroes.war_prot.level)
    T.eq(out.levels.war_prot[1], 1)
    T.eq(Offline.pending(state), nil, "받은 뒤에는 없음")
    T.eq(Offline.claim(state), nil)
    -- 망가진 기록은 지운다
    s.offline = { gold = -5, exp = {} }
    Offline.validate(s)
    T.eq(s.offline, nil)
end)

if not T.report("test_offline") then os.exit(1) end
