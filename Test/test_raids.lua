-- 레이드(액트 보스 자리) 검사.
-- 실행: lua5.1 Test/test_raids.lua

package.path = "./?.lua;" .. package.path
local T = require("Test.t")
local WIH = require("Test.engine").load()
local Raids, Monsters, Tables, Runner, Battle, Sheet, Stats, HeroBuild, Skills = WIH.Raids, WIH.Monsters, WIH.Tables, WIH.Runner, WIH.Battle,
    WIH.Sheet, WIH.Stats, WIH.HeroBuild, WIH.Skills
local Game, Session, Chests, Save, Runes, ChestTable = WIH.Game, WIH.Session, WIH.Chests, WIH.Save, WIH.Runes, WIH.ChestTable

local function strongSheet(hp, atk)
    local s = Sheet.new()
    Sheet.add(s, "MaxHp", Stats.FLAT, hp or 1e7)
    Sheet.add(s, "AttackDamage", Stats.FLAT, atk or 1e5)
    return s
end

T.case("레이드 데이터: 3종, 보스 19명, 보스마다 패턴 5개", function()
    local count = 0
    local expect = { 1, 10, 8 }
    for act = 1, 3 do
        local raid = Raids.byAct[act]
        T.ok(raid and raid.name, "액트 " .. act .. "의 레이드가 없음")
        T.eq(#raid.bosses, expect[act], raid.name .. "의 보스 수")
        for _, id in ipairs(raid.bosses) do
            local def = Monsters.defs[id]
            T.ok(def and def.isBoss and def.raid, id .. ": 레이드 보스로 등록되지 않음")
            T.eq(#def.skills, 5, def.name .. "의 패턴 수")
            for _, s in ipairs(def.skills) do
                T.ok(s.name and s.desc and #s.desc > 0, def.name .. ": 패턴 설명이 없음")
                for _, eff in ipairs(s.effects) do T.ok(Skills.exec[eff.type], def.name .. ": 알 수 없는 효과 " .. tostring(eff.type)) end
            end
            count = count + 1
        end
        for d = 1, 4 do
            local key = Raids.key(d, act)
            T.ok(Tables.STAGES[key] and Tables.STAGES[key].actBoss and Tables.STAGES[key].actBossFinal, "원작 표에 없는 레이드 키 " .. key)
            T.ok(ChestTable.STAGE[key] and ChestTable.tables[ChestTable.STAGE[key].raid], "레이드 상자 표가 없음 " .. key)
        end
    end
    T.eq(count, 19)
    T.eq(Raids.skillCount(1), 2); T.eq(Raids.skillCount(4), 5)
    for d = 1, 4 do T.eq(WIH.Materials.defs[Raids.TOKEN[d]].kind, "SOULSTONE") end
end)

T.case("레이드 보스 19명: 고통 난이도의 패턴 5개가 모두 발동한다", function()
    local never = {}
    for act = 1, 3 do
        local stage = Tables.STAGES[Raids.key(4, act)]
        for _, id in ipairs(Raids.byAct[act].bosses) do
            local def = Monsters.defs[id]
            local b = Battle.new({ seed = 5, stageLevel = stage.level })
            local tough = strongSheet(1e9, 1)
            for rank, heroId in ipairs({ "war_prot", "pri_holy", "mag_fire", "rog_combat", "hun_mm" }) do
                HeroBuild.spawn(b, heroId, { rank = rank, x = -(rank - 1) * 20, account = tough })
            end
            local boss = Runner.spawnMonster(b, def, { hp = 1e9, atk = stage.actBossFinal.atk, gold = 0, exp = 0 }, 600, nil, 5)
            T.eq(#boss.skills, 5)
            local cast = {}
            b.listeners[1] = function(ev, u, s) if ev == "cast" and u == boss then cast[s.id] = true end end
            b:run(60)
            if boss.alive then boss.hp = boss:get("MaxHp") * 0.15 end
            b:run(60)
            for _, s in ipairs(def.skills) do
                if not cast[s.id] then never[#never + 1] = def.name .. " - " .. s.name end
            end
        end
    end
    T.eq(#never, 0, "발동하지 않은 패턴: " .. table.concat(never, ", "))
end)

T.case("레이드 진행: 보스가 차례로 나오고, 마지막 보스는 원작 액트 보스의 체력이며, 보상 총량이 원작과 같다", function()
    for act = 1, 3 do
        local key = Raids.key(1, act)
        local final = Tables.STAGES[key].actBossFinal
        local order, golds, exps, hps = {}, 0, 0, {}
        local runner = Runner.new({ raidKey = key, seed = 3, account = strongSheet(),
            party = { { heroId = "war_prot" }, { heroId = "pri_holy" }, { heroId = "mag_fire" } },
            onEvent = function(ev, a, b)
                if ev == "boss" then
                    order[#order + 1] = a.name
                    hps[#hps + 1] = a:get("MaxHp")
                    T.eq(#a.skills, 2, a.name .. ": 일반 난이도의 패턴은 2개")
                elseif ev == "kill" and a.isBoss then
                    golds, exps = golds + b.gold, exps + b.exp
                end
            end })
        local battle = runner.battle
        local res = runner:run(3600)
        T.eq(res, "clear", Raids.byAct[act].name)
        T.eq(runner.battle, battle, "보스가 바뀌어도 같은 전투가 이어진다")
        T.eq(#order, #Raids.byAct[act].bosses)
        for i, id in ipairs(Raids.byAct[act].bosses) do T.eq(order[i], Monsters.defs[id].name, "보스 순서") end
        local sum = 0
        for _, hp in ipairs(hps) do sum = sum + hp end
        T.near(sum, final.hp, 1e-6, "보스 체력 합 = 원작 액트 보스")
        T.near(hps[#hps], final.hp * (#hps > 1 and Raids.FINAL_SHARE or 1), 1e-6, "마지막 보스의 몫")
        T.near(golds, final.gold, 1e-6, "골드 총량 = 원작")
        T.near(exps, final.exp, 1e-6, "경험치 총량 = 원작")
    end
end)

T.case("레이드 규칙: 던전을 다 깨야 열리고, 증표가 있어야 하며, 클리어하면 다음 액트가 열린다", function()
    local s = Game.new("Horde", "war_prot", 0)
    local ok, why = Game.canStartRaid(s, 1, 1)
    T.ok(not ok and why, "던전을 깨기 전에는 잠김: " .. tostring(why))
    -- 1-9 직전까지 깬 것으로 두고 1-9를 실제로 클리어한다.
    for n = 1, 8 do s.stage.cleared[1100 + n] = 1 end
    T.ok(Game.selectStage(s, 1, 109))
    local sess = Session.new(s, { seed = 9 })
    sess.account = strongSheet()
    local events = {}
    sess:addListener(function(ev, a, b, c) events[ev] = (events[ev] or 0) + 1; events["last_" .. ev] = { a, b, c } end)
    local t = 0
    while (s.stage.cleared[1109] or 0) < 1 and t < 3000 do sess:advance(1, 40); t = t + 1 end
    T.eq(s.stage.cleared[1109], 1, "1-9 클리어")
    T.eq(Game.raidTokens(s, 1), 1, "1-9 첫 클리어로 증표 1개")
    T.eq(events.token, 1)
    T.ok((events.raidUnlocked or 0) >= 1, "레이드가 열렸다는 알림")
    T.eq(s.stage.section, 109, "레이드가 남아 있으면 다음 액트로 넘어가지 않음")
    T.ok(not Game.stageUnlocked(s, 1201), "레이드를 깨기 전에는 액트 2가 잠겨 있음")
    -- 레이드 시작
    T.ok(Game.canStartRaid(s, 1, 1))
    T.ok(not Game.canStartRaid(s, 2, 1), "다른 난이도의 레이드는 잠겨 있음")
    T.ok(Game.startRaid(s, 1, 1))
    T.eq(s.stage.raidKey, 1110)
    local runner = sess:startStage()
    T.ok(runner.raid and sess.inRaid)
    local chestsBefore = Chests.count(s, "raid")
    t = 0
    while sess.inRaid and (s.stage.cleared[1110] or 0) < 1 and t < 3000 do sess:advance(1, 40); t = t + 1 end
    T.eq(s.stage.cleared[1110], 1, "레이드 클리어")
    T.eq(Game.raidTokens(s, 1), 0, "클리어하면 증표 1개를 씀")
    T.eq(Chests.count(s, "raid"), chestsBefore + 1, "레이드 상자 1개")
    T.eq(events.raidClear, 1)
    T.eq(s.stage.raidKey, nil)
    T.eq(s.stage.section, 201, "처음 클리어하면 다음 액트의 첫 던전으로 넘어감")
    T.ok(Game.stageUnlocked(s, 1201))
    -- 레이드 상자를 열면 아이템이나 재료가 나온다.
    local result = Chests.open(s, "raid", WIH.Rng.new(4))
    T.ok(result and (result.item or result.material))
    -- 증표가 없으면 다시 갈 수 없다.
    ok, why = Game.canStartRaid(s, 1, 1)
    T.ok(not ok and why:find("증표"), tostring(why))
end)

T.case("레이드 실패: 증표를 쓰지 않고 하던 던전으로 돌아간다", function()
    local s = Game.new("Horde", "pri_holy", 0)
    for n = 1, 9 do s.stage.cleared[1100 + n] = 1 end
    Game.selectStage(s, 1, 103)
    s.materials[Raids.TOKEN[1]] = 2
    T.ok(Game.startRaid(s, 1, 1))
    local sess = Session.new(s, { seed = 2 })
    local fails = 0
    sess:addListener(function(ev) if ev == "fail" then fails = fails + 1 end end)
    local t = 0
    while fails < 1 and t < 3000 do sess:advance(1, 40); t = t + 1 end
    T.eq(fails, 1, "레벨 1 영웅 혼자서는 실패함")
    T.eq(Game.raidTokens(s, 1), 2, "실패하면 증표가 그대로")
    T.eq(s.stage.raidKey, nil)
    T.eq(s.stage.cleared[1110], nil)
    for _ = 1, 5 do sess:advance(1, 40) end
    T.ok(sess.runner and not sess.runner.raid, "하던 던전으로 돌아옴")
    T.eq(sess.stageKey, 1103)
    -- 던전을 고르면 예약한 레이드는 취소된다.
    Game.startRaid(s, 1, 1)
    Game.selectStage(s, 1, 102)
    T.eq(s.stage.raidKey, nil)
end)

T.case("레이드 상자와 룬, 저장", function()
    local s = Game.new("Horde", "war_prot", 0)
    T.eq(Chests.cap(s, "raid"), 5)
    -- 보관함이 가득 차면 새 상자는 그 자리에서 열린다(잃지 않는다).
    s.chests.raid.list = { 10, 10, 10, 10, 10 }
    s.inventory.bought = 100
    local how, result = Chests.giveRaid(s, 1110, WIH.Rng.new(8))
    T.eq(how, "opened"); T.ok(result and (result.item or result.material))
    T.eq(Chests.count(s, "raid"), 5)
    for _, stat in ipairs({ "AdditionalGoldActBoss", "AdditionalExpActBoss", "MaxAmountActBossChest", "UnlockAutoOpenActBossChest" }) do
        T.eq(Runes.INACTIVE[stat], nil, stat .. ": 이제 쓰이므로 미적용 표에 없어야 함")
    end
    -- 레이드 보스의 골드에는 레이드용 룬이 적용된다.
    local totals = { AdditionalGoldActBoss = 100 }
    T.near(Runes.goldFor(totals, 50, "raid"), 150, 1e-9)
    -- 저장: 열리지 않은 레이드가 예약돼 있으면 지운다.
    local bad = Save.deepCopy(s)
    bad.stage.raidKey = 1110
    local state = Save.load(bad)
    T.eq(state.stage.raidKey, nil)
    local good = Save.deepCopy(s)
    for n = 1, 9 do good.stage.cleared[1100 + n] = 1 end
    good.stage.raidKey = 1110
    state = Save.load(good)
    T.eq(state.stage.raidKey, 1110)
end)

if not T.report("test_raids") then os.exit(1) end
