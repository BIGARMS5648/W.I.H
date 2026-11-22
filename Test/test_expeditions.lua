-- 원정과 낙스라마스 검사. 실행: lua5.1 Test/test_expeditions.lua

package.path = "./?.lua;" .. package.path
local T = require("Test.t")
local WIH = require("Test.engine").load()
local Expeditions, ExpeditionTable, ExpeditionData, Tables, Runner, Monsters, Game, Session, Raids, Chests, ChestTable, Sheet, Stats, Battle, HeroBuild =
    WIH.Expeditions, WIH.ExpeditionTable, WIH.ExpeditionData, WIH.Tables, WIH.Runner, WIH.Monsters, WIH.Game, WIH.Session, WIH.Raids,
    WIH.Chests, WIH.ChestTable, WIH.Sheet, WIH.Stats, WIH.Battle, WIH.HeroBuild

local function strong()
    local s = Sheet.new()
    Sheet.add(s, "MaxHp", Stats.FLAT, 1e10)
    Sheet.add(s, "AttackDamage", Stats.FLAT, 1e7)
    return s
end

T.case("원정 표: 60 스테이지, 강도 표, 몬스터 평균이 원작 값과 같다(강도 적용 전)", function()
    T.eq(#ExpeditionTable.INTENSITY, 20)
    T.eq(ExpeditionTable.INTENSITY[1][1], 1500); T.eq(ExpeditionTable.INTENSITY[20][2], 5000)       -- [원작]
    for d = 2, 4 do
        local sec = ExpeditionData.EXPEDITIONS[d]
        for n = 1, 20 do
            local key = Expeditions.keys[d][n]
            local st = Tables.STAGES[key]
            T.ok(st and st.expedition and st.section == sec, "스테이지 " .. key)
            T.eq(st.level, ({ 40, 65, 90 })[d - 1])
            T.ok(ChestTable.tables[ChestTable.STAGE[key].normal] and ChestTable.tables[ChestTable.STAGE[key].boss])
            -- 평균은 원작 × 강도
            local w, hp = 0, 0
            for _, m in ipairs(sec.mobs) do
                local v = Runner.mobValues(st, sec, Monsters.defs[m.id])
                w, hp = w + m.weight, hp + v.hp * m.weight
            end
            T.near(hp / w / (st.mob.hp * (1 + ExpeditionTable.INTENSITY[n][1] / 1000)), 1, 1e-9)
        end
    end
    T.near(Tables.STAGES[Expeditions.keys[4][1]].chest, 0.6, 1e-9, "고통 원정 일반 상자 0.06% [원작]")
end)

T.case("원정 보스: 강도에 따라 돌아가며 나오고, 강도 20은 마지막 보스", function()
    local sec = ExpeditionData.EXPEDITIONS[2]
    local seen = {}
    for n = 1, 20 do
        local r = Runner.new({ stageKey = Expeditions.keys[2][n], seed = 1, party = { { heroId = "war_prot" } } })
        r.wave = r.waves
        r:spawnBoss()
        seen[n] = r.boss.def.id
    end
    T.eq(seen[20], sec.bosses[#sec.bosses])
    T.eq(seen[1], sec.bosses[1])
    T.ok(seen[2] ~= seen[1])
end)

T.case("원정·낙스라마스 보스 전원: 패턴이 모두 발동한다", function()
    local never, count = {}, 0
    local function fight(def, level)
        local b = Battle.new({ seed = 4, stageLevel = level })
        for rank, id in ipairs({ "war_prot", "pri_holy", "mag_fire", "rog_combat", "hun_mm" }) do
            HeroBuild.spawn(b, id, { rank = rank, x = -(rank - 1) * 20, account = (function() local sh = Sheet.new(); Sheet.add(sh, "MaxHp", Stats.FLAT, 1e9); return sh end)() })
        end
        local boss = Runner.spawnMonster(b, def, { hp = 1e9, atk = 50, gold = 0, exp = 0 }, 600, nil, 5)
        local cast = {}
        b.listeners[1] = function(ev, u, s) if ev == "cast" and u == boss then cast[s.id] = true end end
        b:run(60)
        boss.hp = boss:get("MaxHp") * 0.04
        b:run(60)
        for _, s in ipairs(def.skills) do if not cast[s.id] then never[#never + 1] = def.name .. " - " .. s.name end end
        count = count + 1
    end
    for d = 2, 4 do for _, id in ipairs(ExpeditionData.EXPEDITIONS[d].bosses) do fight(Monsters.defs[id], 60) end end
    for a = 1, 3 do for _, id in ipairs(ExpeditionData.NAXX[a].bosses) do fight(Monsters.defs[id], 80) end end
    T.eq(count, 8 + 6 + 8 + 6 + 7 + 2)
    T.eq(#never, 0, "발동하지 않은 패턴: " .. table.concat(never, ", "))
end)

T.case("원정 진행: 열림 조건, 보급품, 강도 진행, 상자, 보급품이 떨어지면 돌아옴", function()
    local s = Game.new("Horde", "war_prot", 0)
    local ok, why = Expeditions.start(s, 2, 1)
    T.ok(not ok and why:find("레이드"), tostring(why))
    s.stage.cleared[Raids.key(2, 1)] = 1
    T.ok(Expeditions.unlocked(s, 2))
    T.ok(not Expeditions.intensityUnlocked(s, 2, 2), "강도 2는 강도 1을 깨야 열림")
    s.supply = 10
    ok, why = Expeditions.start(s, 2, 1)
    T.ok(not ok and why:find("보급품"))
    s.supply = 100
    T.ok(Expeditions.start(s, 2, 1))
    local sess = Session.new(s, { seed = 5 })
    sess.account = strong()
    local runner = sess:startStage()
    T.ok(sess.inExpedition and runner.stage.expedition, "원정이 시작됨")
    T.eq(runner.difficulty, 2)
    local t = 0
    while (s.stage.cleared[Expeditions.keys[2][1]] or 0) < 1 and t < 3000 do sess:advance(1, 40); t = t + 1 end
    T.ok((s.stage.cleared[Expeditions.keys[2][1]] or 0) >= 1, "강도 1 클리어")
    T.ok(Expeditions.intensityUnlocked(s, 2, 2))
    T.ok(s.supply < 100, "보급품이 줄어듦: " .. s.supply)
    for _ = 1, 5 do sess:advance(1, 40) end
    T.eq(s.stage.expedition, Expeditions.keys[2][2], "자동 진행으로 강도 2로")
    -- 보급품이 떨어지면 다음 스테이지에서 던전으로
    s.supply = 0
    local left = false
    sess:addListener(function(ev) if ev == "supplyOut" then left = true end end)
    sess:startStage()
    T.ok(left and not sess.inExpedition and s.stage.expedition == nil, "보급품이 떨어지면 원정에서 나옴")
    -- 원정 밖에서는 찬다
    Expeditions.tick(s, 600, false)
    T.near(s.supply, 1, 1e-9, "10분에 1")
end)

T.case("낙스라마스: 열림 조건, 오염된 증표, 보스 연속, 클리어 시에만 증표 소모", function()
    local s = Game.new("Horde", "war_prot", 0)
    local ok, why = Expeditions.startNaxx(s, 2, 1)
    T.ok(not ok)
    s.stage.cleared[Raids.key(2, 1)] = 1
    ok, why = Expeditions.startNaxx(s, 2, 1)
    T.ok(not ok and why:find("증표"), tostring(why))
    s.materials[190102] = 1
    T.ok(Expeditions.startNaxx(s, 2, 1))
    local sess = Session.new(s, { seed = 7 })
    sess.account = strong()
    local runner = sess:startStage()
    T.ok(sess.inRaid and runner.raid == ExpeditionData.NAXX[1])
    T.eq(runner.waves, 6, "거미·역병 지구 보스 6명")
    local key = Expeditions.naxxKeys[2][1]
    local t = 0
    while (s.stage.cleared[key] or 0) < 1 and t < 5000 do sess:advance(1, 40); t = t + 1 end
    T.eq(s.stage.cleared[key], 1, "클리어")
    T.eq(s.materials[190102], nil, "오염된 증표를 씀")
    T.eq(Chests.count(s, "praid"), 1, "낙스라마스 상자 1개(원정 보관함)")
    T.eq(Chests.count(s, "raid"), 0, "레이드 보관함에는 들어가지 않는다")
end)

local Rng = WIH.Rng
T.case("원정 상자: 따로 보관하고, 역병의 룬을 받고, 허용량은 원정에 있을 때만 찬다", function()
    local s = Game.new("Horde", "war_prot", 0)
    local key = Expeditions.keys[2][1]
    T.eq(Chests.kindFor(key, false), "pnormal")
    T.eq(Chests.kindFor(key, true), "pstage")
    T.eq(Chests.kindFor(1101, false), "normal")
    T.eq(Chests.raidKind(Expeditions.naxxKeys[2][1]), "praid")
    T.eq(Chests.raidKind(Raids.key(2, 1)), "raid")
    -- 룬: 원정 상자에는 역병의 룬만, 일반 지역 상자에는 일반 룬만
    local base = Chests.dropChance(s, "pnormal", key)
    for k, node in pairs(WIH.RuneData.nodes) do
        if node.stat == "DropChancePlagueNormalChestPercent" or node.stat == "MaxAmountPlagueNormalChest" then s.runes[k] = node.max end
    end
    T.near(Chests.dropChance(s, "pnormal", key) / base, 3.5, 1e-9, "역병 탐색의 룬 +250%")
    T.near(Chests.dropChance(s, "normal", key), base, 1e-12, "일반 상자 확률은 그대로")
    T.eq(Chests.cap(s, "pnormal"), Chests.BASE_CAP + 5)
    T.eq(Chests.cap(s, "normal"), Chests.BASE_CAP)
    -- 허용량
    s.chests.pnormal.allowance, s.chests.normal.allowance = 0, 0
    Chests.tick(s, 600, 1101, Rng.new(1))
    T.eq(s.chests.pnormal.allowance, 0, "일반 지역에서는 원정 상자 허용량이 차지 않는다")
    T.ok(s.chests.normal.allowance > 0)
    s.chests.normal.allowance = 0
    Chests.tick(s, 600, key, Rng.new(1))
    T.ok(s.chests.pnormal.allowance > 0, "원정에서는 찬다")
    T.eq(s.chests.normal.allowance, 0, "원정에서는 일반 지역 상자 허용량이 차지 않는다")
    -- 실제 진행: 원정에서 처치하면 원정 보관함으로
    s.stage.cleared[Raids.key(2, 1)] = 1
    s.supply = 100
    T.ok(Expeditions.start(s, 2, 1))
    local session = Session.new(s, { seed = 5 })
    session.account = strong()
    for _ = 1, 600 do session:advance(1, 100000) end
    T.ok(Chests.count(s, "pnormal") + Chests.count(s, "pstage") > 0, "원정 상자가 쌓인다")
    T.eq(Chests.count(s, "normal") + Chests.count(s, "stage"), 0, "일반 지역 보관함에는 들어가지 않는다")
end)

if not T.report("test_expeditions") then os.exit(1) end
