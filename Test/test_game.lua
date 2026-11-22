-- 게임 상태 규칙, 연속 진행, 저장 검증.
-- 실행: lua5.1 Test/test_game.lua

package.path = "./?.lua;" .. package.path
local T = require("Test.t")
local WIH = require("Test.engine").load()
local Game, Session, Save, Heroes, Tables, Level = WIH.Game, WIH.Session, WIH.Save, WIH.Heroes, WIH.Tables, WIH.Level
local Sheet, Stats = WIH.Sheet, WIH.Stats

T.case("새 게임: 시작 골드 100, 영웅 1명, 편성 1칸, 스킬 2칸, 첫 스테이지", function()
    local s = Game.new("Horde", "war_prot", 1000)
    T.eq(s.gold, 100)
    T.eq(s.faction, "Horde")
    T.eq(#s.party, 1)
    T.eq(Game.partySlots(s), 1)
    T.eq(Game.skillSlots(s), 2)
    T.eq(Game.currentStageKey(s), 1101)
    T.eq(s.heroes.war_prot.level, 1)
    local feral = Game.new("Alliance", "dru_feral")
    T.eq(feral.heroes.dru_feral.form, "bear")
    T.ok(not pcall(Game.new, "Neutral", "war_prot"))
end)

T.case("영웅 해금과 편성 규칙", function()
    local s = Game.new("Alliance", "war_prot")
    local ok, why = Game.unlockHero(s, "mag_fire")
    T.eq(ok, false, "골드 100으로는 해금 불가"); T.ok(why)
    s.gold = 1200
    T.eq(Game.unlockHero(s, "mag_fire"), true)
    T.eq(s.gold, 700)
    T.eq(Game.unlockHero(s, "mag_fire"), false, "중복 해금")
    T.eq(Game.unlockHero(s, "nobody"), false)
    T.eq(Game.setParty(s, { "war_prot", "mag_fire" }), false, "편성 칸 1개")
    s.unlocks.partySlots = 2
    T.eq(Game.setParty(s, { "war_prot", "mag_fire" }), true)
    T.eq(Game.setParty(s, { "mag_fire", "mag_fire" }), false, "같은 영웅 중복")
    T.eq(Game.setParty(s, { "war_prot", "pri_holy" }), false, "해금하지 않은 영웅")
    T.eq(Game.setParty(s, {}), false)
    T.eq(s.party[2], "mag_fire", "실패한 요청은 편성을 바꾸지 않는다")
end)

T.case("스킬 트리: 포인트, 티어 해금, 최대 레벨, 환급 제한", function()
    local s = Game.new("Alliance", "war_arms")
    local h = s.heroes.war_arms
    T.eq(Game.investActive(s, "war_arms", "arms_mortal_strike"), false, "레벨 1은 포인트 0")
    h.level = 31                                        -- 30포인트
    T.eq(Game.freePoints(s, "war_arms"), 30)
    for _ = 1, 5 do T.eq(Game.investActive(s, "war_arms", "arms_mortal_strike"), true) end
    T.eq(Game.investActive(s, "war_arms", "arms_mortal_strike"), false, "포인트로는 5레벨까지")
    T.eq(Game.investActive(s, "war_arms", "arms_rend"), false, "티어 10은 아래 티어에 10포인트가 있어야 열림")
    T.eq(Game.investActive(s, "war_arms", "fury_whirlwind"), false, "다른 영웅의 스킬")
    for _ = 1, 3 do T.eq(Game.investPassive(s, "war_arms", 1), true) end
    T.eq(Game.investPassive(s, "war_arms", 1), false, "패시브 최대 레벨 3")
    for _ = 1, 2 do Game.investPassive(s, "war_arms", 2) end     -- 아래 티어 합 10
    T.eq(Game.investActive(s, "war_arms", "arms_rend"), true, "이제 티어 10이 열림")
    T.eq(Game.spentPoints(s, "war_arms"), 11)
    -- 티어 0의 포인트를 빼면 티어 10의 조건(10)이 깨진다.
    local ok, why = Game.refundPassive(s, "war_arms", 2)
    T.eq(ok, false); T.ok(why:find("환급"))
    T.eq(h.passive[2], 2, "실패한 환급은 되돌린다")
    T.eq(Game.refundActive(s, "war_arms", "arms_rend"), true)
    T.eq(Game.refundPassive(s, "war_arms", 2), true)
    -- 장착
    T.eq(Game.setBar(s, "war_arms", { "arms_mortal_strike", "arms_charge" }), false, "투자하지 않은 스킬")
    Game.investActive(s, "war_arms", "arms_charge")
    T.eq(Game.setBar(s, "war_arms", { "arms_mortal_strike", "arms_charge" }), true)
    T.eq(Game.setBar(s, "war_arms", { "arms_mortal_strike", "arms_charge", "arms_rend" }), false, "스킬 칸 2개")
    -- 스킬을 0까지 환급하면 장착에서도 빠진다.
    T.eq(Game.refundActive(s, "war_arms", "arms_charge"), true)
    T.eq(#h.bar, 1)
    T.eq(Game.resetTree(s, "war_arms"), true)
    T.eq(Game.freePoints(s, "war_arms"), 30)
end)

T.case("스테이지 해금은 앞 스테이지 클리어로 열린다", function()
    local s = Game.new("Alliance", "war_prot")
    T.eq(Game.stageUnlocked(s, 1101), true)
    T.eq(Game.stageUnlocked(s, 1102), false)
    T.eq(Game.selectStage(s, 1, 102), false)
    Game.markCleared(s, 1101)
    T.eq(Game.selectStage(s, 1, 102), true)
    T.eq(Game.currentStageKey(s), 1102)
    T.eq(Game.selectStage(s, 1, 110), false, "레이드 자리는 이 선택으로 고를 수 없다")
    T.eq(Game.selectStage(s, 2, 101), false, "악몽은 일반 3-10을 클리어해야 열린다")
    T.eq(Game.previousStage(2101), 1310)
    T.eq(s.stage.bossIndex[1101], 2, "클리어할 때마다 다음 보스 차례")
end)

local function strongSession(state, seed)
    local sheet = Sheet.new()
    Sheet.add(sheet, "AttackDamage", Stats.FLAT, 400)
    Sheet.add(sheet, "MaxHp", Stats.FLAT, 40000)
    local session = Session.new(state, { seed = seed or 5 })
    session.account = sheet
    return session
end

T.case("연속 진행: 클리어하면 다음 스테이지로 넘어가고 보상이 바로 쌓인다", function()
    local s = Game.new("Alliance", "war_fury", 0)
    local session = strongSession(s)
    local events = {}
    session.listeners[1] = function(ev, a) events[#events + 1] = ev .. ":" .. tostring(a) end
    local simulated = 0
    while (s.stage.cleared[1103] or 0) == 0 and simulated < 3600 do
        session:advance(1, 100000)
        simulated = simulated + 1
    end
    T.ok((s.stage.cleared[1101] or 0) >= 1 and (s.stage.cleared[1102] or 0) >= 1 and (s.stage.cleared[1103] or 0) >= 1,
        "세 스테이지를 차례로 클리어해야 함")
    T.eq(Game.currentStageKey(s), 1104, "자동으로 다음 스테이지 선택")
    T.ok(s.gold > 100, "골드가 쌓여야 함")
    T.ok(s.heroes.war_fury.level > 1, "레벨이 올라야 함")
    T.ok(s.stats.kills > 30 and s.stats.clears == 3)
    T.ok(s.stats.playSeconds > 10)
    local leveled = false
    for _, e in ipairs(events) do if e:find("^levelUp") then leveled = true end end
    T.ok(leveled, "레벨업 이벤트")
end)

T.case("연속 진행: 반복 모드는 같은 스테이지에 머문다", function()
    local s = Game.new("Alliance", "war_fury")
    s.settings.repeatMode = true
    local session = strongSession(s)
    for _ = 1, 400 do session:advance(1, 100000) end
    T.ok((s.stage.cleared[1101] or 0) >= 3, "여러 번 클리어")
    T.eq(Game.currentStageKey(s), 1101)
    T.eq(s.stage.cleared[1102], nil)
end)

T.case("연속 진행: 실패하면 자동 재시도, 꺼져 있으면 이전 스테이지로", function()
    local s = Game.new("Alliance", "mag_fire")
    for key = 1101, 1104 do Game.markCleared(s, key) end
    Game.selectStage(s, 1, 105)
    s.heroes.mag_fire.level = 1
    T.eq(s.settings.autoRetry, false, "새 게임은 자동 재시도가 꺼져 있다(실패하면 물러나 쌓는다)")
    s.settings.autoRetry = true
    local session = Session.new(s, { seed = 3, tuning = { hp = 50, atk = 200 } })   -- 이길 수 없게 만든다
    for _ = 1, 120 do session:advance(1, 100000) end
    T.ok(s.stats.fails >= 1, "실패가 기록돼야 함")
    T.eq(Game.currentStageKey(s), 1105, "자동 재시도: 같은 스테이지")
    s.settings.autoRetry = false
    for _ = 1, 120 do session:advance(1, 100000) end
    T.ok(Game.currentStageKey(s) < 1105, "이전 스테이지로 내려감")
end)

T.case("연속 진행: 앞으로 물러났다가 돌아올 때 이미 깬 레이드는 건너뛴다", function()
    local s = Game.new("Alliance", "war_fury", 0)
    for key = 1101, 1110 do Game.markCleared(s, key) end
    Game.selectStage(s, 1, 109)
    local session = strongSession(s)
    for _ = 1, 600 do
        session:advance(1, 100000)
        if s.stage.section ~= 109 then break end
    end
    T.eq(Game.currentStageKey(s), 1201, "1-9를 깨면 이미 깬 1-10 레이드를 건너 2-1로")
    -- 레이드를 아직 깨지 않았으면 머문다
    local s2 = Game.new("Alliance", "war_fury", 0)
    for key = 1101, 1108 do Game.markCleared(s2, key) end
    Game.selectStage(s2, 1, 109)
    local session2 = strongSession(s2)
    local cleared = false
    session2.listeners[#session2.listeners + 1] = function(ev) if ev == "clear" then cleared = true end end
    for _ = 1, 600 do session2:advance(1, 100000); if cleared then break end end
    for _ = 1, 10 do session2:advance(1, 100000) end
    T.eq(Game.currentStageKey(s2), 1109, "깨지 않은 레이드 앞에서는 머문다")
end)

T.case("연속 진행: 틱 예산과 밀린 시간 상한", function()
    local s = Game.new("Alliance", "war_fury")
    local session = strongSession(s)
    T.eq(session:advance(1.0, 10), 10, "한 번에 최대 10틱")
    T.eq(session:advance(0, 1000), 10, "남은 0.5초분")
    T.eq(session:advance(1000, 1e9), 30 / WIH.TICK, "밀린 시간은 30초까지만")
end)

T.case("일반 난이도 3-9를 클리어하면 레이드 자리에서 멈춘다", function()
    local s = Game.new("Alliance", "war_fury")
    local key = 1101
    while key ~= 1109 do Game.markCleared(s, key); key = Tables.STAGES[key].next end
    Game.selectStage(s, 1, 109)
    local session = strongSession(s)
    local raid
    session.listeners[1] = function(ev, a) if ev == "raidUnlocked" then raid = a end end
    for _ = 1, 600 do
        session:advance(1, 100000)
        if raid then break end
    end
    T.eq(raid, 1110)
    T.eq(Game.currentStageKey(s), 1109, "레이드는 자동으로 들어가지 않는다")
end)

-- 저장 -------------------------------------------------------------------

T.case("저장: 정상 데이터는 그대로 통과한다", function()
    local s = Game.new("Horde", "war_prot", 123)
    s.heroes.war_prot.level = 12
    Game.investActive(s, "war_prot", "wprot_shield_slam")
    Game.setBar(s, "war_prot", { "wprot_shield_slam" })
    local copy = Save.deepCopy(s)
    local state, info = Save.load(copy)
    T.eq(info.status, "ok", table.concat(info.notes, " / "))
    T.eq(state.heroes.war_prot.level, 12)
    T.eq(state.heroes.war_prot.bar[1], "wprot_shield_slam")
end)

T.case("저장: 없으면 새 게임, 표가 아니거나 형식 번호가 없으면 손상, 더 새 버전은 건드리지 않는다", function()
    local state, info = Save.load(nil)
    T.eq(state, nil); T.eq(info.status, "new")
    state, info = Save.load("문자열")
    T.eq(info.status, "broken")
    state, info = Save.load({ faction = "Horde" })
    T.eq(info.status, "broken")
    local newer = Game.new("Horde", "war_prot")
    newer.schema = Game.SCHEMA + 1
    state, info = Save.load(newer)
    T.eq(state, nil); T.eq(info.status, "newer")
    T.eq(newer.schema, Game.SCHEMA + 1, "더 새 버전의 저장은 수정하지 않는다")
end)

T.case("저장: 망가진 값을 고치고 무엇을 고쳤는지 보고한다", function()
    local s = Game.new("Alliance", "mag_fire")
    s.gold = -50
    s.heroes.mag_fire.level = 999
    s.heroes.mag_fire.exp = 0 / 0                        -- NaN
    s.heroes.mag_fire.active = { fire_fireball = 99, arms_charge = 3 }
    s.heroes.mag_fire.passive = { [1] = 50, [77] = 2, x = 1 }
    s.heroes.mag_fire.bar = { "fire_fireball", "fire_fireball", "arms_charge" }
    s.heroes.ghost_hero = { level = 5 }
    s.heroes.war_prot = "문자열"
    s.party = { "ghost_hero", "mag_fire", "mag_fire" }
    s.stage = { difficulty = 9, section = 12345, cleared = { [42] = 3, [1101] = "x" } }
    s.unlocks = { partySlots = 99, skillSlots = -1 }
    s.settings = "none"
    s.stats = { kills = -5 }
    local state, info = Save.load(s)
    T.ok(state, "고쳐서 불러와야 함")
    T.eq(info.status, "fixed")
    T.ok(#info.notes >= 5, "고친 내용을 보고해야 함")
    T.eq(state.gold, 0)
    T.eq(state.heroes.mag_fire.level, 101)
    T.eq(state.heroes.mag_fire.exp, 0)
    T.eq(state.heroes.ghost_hero, nil)
    T.eq(state.heroes.war_prot, nil)
    T.eq(#state.party, 1); T.eq(state.party[1], "mag_fire")
    -- 편성 칸과 스킬 칸은 저장된 값이 아니라 룬에서 다시 계산한다(룬이 없으므로 기본값).
    T.eq(state.unlocks.partySlots, 1); T.eq(state.unlocks.skillSlots, 2)
    T.eq(Game.currentStageKey(state), 1101)
    T.eq(state.stage.cleared[42], nil)
    T.eq(state.settings.autoRetry, true)
    T.eq(state.stats.kills, 0)
    local h = state.heroes.mag_fire
    T.eq(h.active.arms_charge, nil)
    T.ok((h.active.fire_fireball or 0) <= 5)
    T.ok(Game.treeValid(Heroes.byId.mag_fire, h))
    T.ok(Game.spentPoints(state, "mag_fire") <= Level.skillPoints(h.level))
    -- 고친 뒤의 상태로 실제 진행이 된다.
    local session = Session.new(state, { seed = 1 })
    session:advance(5, 100000)
end)

T.case("저장: 포인트를 초과한 트리는 초기화된다", function()
    local s = Game.new("Alliance", "war_arms")
    s.heroes.war_arms.level = 3                           -- 2포인트
    s.heroes.war_arms.active = { arms_mortal_strike = 5, arms_execute = 5 }
    s.heroes.war_arms.bar = { "arms_mortal_strike" }
    local state, info = Save.load(s)
    T.eq(info.status, "fixed")
    T.eq(next(state.heroes.war_arms.active), nil)
    T.eq(#state.heroes.war_arms.bar, 0)
end)

T.case("저장: 영웅이 없거나 진영이 없으면 되살릴 수 없다", function()
    local s = Game.new("Alliance", "war_arms")
    s.heroes = {}
    local state, info = Save.load(s)
    T.eq(state, nil); T.eq(info.status, "broken")
    s = Game.new("Alliance", "war_arms")
    s.faction = nil
    state, info = Save.load(s)
    T.eq(state, nil); T.eq(info.status, "broken")
end)

T.case("저장: 형식 변환이 순서대로 적용된다", function()
    local old = Game.new("Alliance", "war_arms")
    local saved = Game.SCHEMA
    Game.SCHEMA = saved + 2
    Save.migrations[saved] = function(raw) raw.migratedA = true end
    Save.migrations[saved + 1] = function(raw) raw.migratedB = raw.migratedA end
    local state, info = Save.load(old)
    Game.SCHEMA = saved
    Save.migrations[saved], Save.migrations[saved + 1] = nil, nil
    T.ok(state and state.migratedA and state.migratedB)
    T.eq(state.schema, saved + 2)
    T.eq(info.status, "fixed")
end)

T.case("백업은 최근 3개만 남기고 원본과 분리된 사본이다", function()
    local backups = {}
    local s = Game.new("Alliance", "war_arms")
    for i = 1, 5 do
        s.gold = i
        backups = Save.pushBackup(backups, s, i)
    end
    T.eq(#backups, 3)
    T.eq(backups[1].data.gold, 5)
    T.eq(backups[3].data.gold, 3)
    s.heroes.war_arms.level = 50
    T.eq(backups[1].data.heroes.war_arms.level, 1, "백업은 깊은 복사")
end)

if not T.report("test_game") then os.exit(1) end
