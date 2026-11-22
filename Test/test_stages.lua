-- 던전 데이터와 스테이지 진행기의 검증.
-- 실행: lua5.1 Test/test_stages.lua [-v]

package.path = "./?.lua;" .. package.path
local T = require("Test.t")
local WIH = require("Test.engine").load()
local Tables, Monsters, Dungeons, Runner = WIH.Tables, WIH.Monsters, WIH.Dungeons, WIH.Runner
local Battle, HeroBuild, Heroes, Skills, Stats, Sheet = WIH.Battle, WIH.HeroBuild, WIH.Heroes, WIH.Skills, WIH.Stats, WIH.Sheet
local verbose = arg and arg[1] == "-v"

local function member(heroId, level, picks, form)
    local hero = Heroes.byId[heroId]
    picks = picks or { 1, 2, 3, 4 }
    local ids = {}
    for i, idx in ipairs(picks) do ids[i] = hero.skills[idx] end
    local active, passive = HeroBuild.autoAllocate(hero, level - 1, ids)
    local skills = {}
    for _, id in ipairs(ids) do
        if active[id] then skills[#skills + 1] = { id, active[id] } end
    end
    return { heroId = heroId, form = form, level = level, exp = 0, passivePoints = passive, skills = skills }
end

T.case("던전 27구간: 구간마다 몬스터 4종 이상과 보스 1명 이상, 네 난이도의 스테이지 표와 연결", function()
    T.eq(#Dungeons.order, 27)
    local names = {}
    for _, key in ipairs(Dungeons.order) do
        local sec = Dungeons.sections[key]
        T.ok(#sec.mobs >= 4, sec.name .. ": 일반 몬스터가 4종 미만")
        T.ok(#sec.bosses >= 1, sec.name .. ": 보스 없음")
        T.ok(not names[sec.name], "구간 이름 중복: " .. sec.name)
        names[sec.name] = true
        for diff = 1, 4 do
            local stage = Tables.STAGES[Dungeons.stageKey(diff, key)]
            T.ok(stage and not stage.actBoss, sec.name .. ": 스테이지 표에 없음")
        end
        for _, m in ipairs(sec.mobs) do
            local def = Monsters.defs[m.id]
            T.ok(def and not def.isBoss and m.weight > 0)
            T.ok(def.hp >= 15 and def.hp <= 320 and def.atk >= 8 and def.atk <= 25, def.name .. ": 원작 범위 밖의 기본 능력치")
        end
        for _, id in ipairs(sec.bosses) do
            local def = Monsters.defs[id]
            T.ok(def and def.isBoss, "보스 정의 없음: " .. id)
            T.ok(def.skills and #def.skills >= 1, def.name .. ": 고유 패턴이 없음")
        end
    end
    -- 액트 보스 자리(x-10)는 레이드가 쓴다.
    for diff = 1, 4 do
        for act = 1, 3 do T.ok(Tables.STAGES[diff * 1000 + act * 100 + 10].actBoss) end
    end
end)

T.case("보스 스킬 데이터: 효과 종류와 능력치가 올바르고 설명문이 있다", function()
    for id, def in pairs(Monsters.defs) do
        for _, s in ipairs(def.skills or {}) do
            T.ok(s.name and s.desc and #s.desc > 0, id .. ": 스킬 설명 없음")
            T.ok(s.act and (s.act.type == "cd" or s.act.type == "count"), id .. ": 발동 방식")
            for _, eff in ipairs(s.effects) do
                T.ok(Skills.exec[eff.type], id .. ": 알 수 없는 효과 " .. tostring(eff.type))
                for _, m in ipairs(eff.mods or {}) do T.ok(Stats.defs[m[1]], id .. ": 알 수 없는 능력치 " .. tostring(m[1])) end
            end
        end
    end
end)

-- 보스 하나를 버티는 시험 파티와 싸우게 한다. 보스의 모든 패턴이 실제로 발동하는지 본다.
local function fightBoss(def, stageLevel, seconds, seed)
    local b = Battle.new({ seed = seed or 1, stageLevel = stageLevel })
    local tough = Sheet.new()
    Sheet.add(tough, "MaxHp", Stats.FLAT, 1e7)
    Sheet.add(tough, "AttackDamage", Stats.FLAT, 1)
    local ids = { "war_prot", "pri_holy", "mag_fire", "rog_combat", "hun_mm" }
    local heroes = {}
    for rank, id in ipairs(ids) do
        heroes[rank] = HeroBuild.spawn(b, id, { rank = rank, x = -(rank - 1) * 20, account = tough })
    end
    local boss = Runner.spawnMonster(b, def, stageLevel, 600, { 2500, 5000, 3000, 6000 })
    local cast = {}
    b.listeners[1] = function(ev, u, s) if ev == "cast" and u == boss then cast[s.id] = true end end
    b:run(seconds * 0.5)
    -- 체력 조건이 붙은 패턴(격노, 자가 회복)을 위해 체력을 낮춘다.
    if boss.alive then boss.hp = boss:get("MaxHp") * 0.2 end
    b:run(seconds * 0.5)
    return boss, cast, heroes
end

T.case("보스 149명: 전투에서 오류 없이 싸우고 모든 패턴이 발동한다", function()
    local never, count = {}, 0
    for _, key in ipairs(Dungeons.order) do
        local sec = Dungeons.sections[key]
        local level = Tables.STAGES[Dungeons.stageKey(1, key)].level
        for _, id in ipairs(sec.bosses) do
            local def = Monsters.defs[id]
            local ok, boss, cast, heroes = pcall(fightBoss, def, level, 120, 3)
            if not ok then error(def.name .. ": " .. tostring(boss)) end
            count = count + 1
            for _, s in ipairs(def.skills) do
                if not cast[s.id] then never[#never + 1] = def.name .. " - " .. s.name end
            end
            local hurt = false
            for _, h in ipairs(heroes) do if h.stats.taken > 0 then hurt = true end end
            T.ok(hurt, def.name .. ": 영웅에게 피해를 주지 못함")
        end
    end
    T.eq(count, 149)
    T.eq(#never, 0, "발동하지 않은 보스 패턴: " .. table.concat(never, ", "))
end)

T.case("스테이지 진행: 웨이브를 모두 잡고 보스를 잡으면 클리어, 보상이 처치 수와 맞는다", function()
    local strong = Sheet.new()
    Sheet.add(strong, "AttackDamage", Stats.FLAT, 500)
    Sheet.add(strong, "MaxHp", Stats.FLAT, 50000)
    local r = Runner.new({ difficulty = 1, section = 103, seed = 4, account = strong,
        party = { member("war_prot", 20), member("mag_fire", 20), member("pri_holy", 20) } })
    local waves, bossSeen = 0, false
    r.listeners[1] = function(ev) if ev == "wave" then waves = waves + 1 elseif ev == "boss" then bossSeen = true end end
    local result, time = r:run(1800)
    T.eq(result, "clear")
    local stage = Tables.STAGES[1103]
    T.eq(waves, stage.waves)
    T.ok(bossSeen)
    T.eq(r.totals.kills, stage.waves * stage.perWave + 1, "처치 수 = 웨이브 × 웨이브당 수 + 보스")
    T.eq(r.totals.bossKills, 1)
    T.ok(r.totals.gold > 0 and r.totals.exp[1] > 0)
    T.ok(time > 5 and time < 1800)
end)

T.case("스테이지 진행: 약한 파티는 전멸해 실패한다", function()
    local r = Runner.new({ difficulty = 4, section = 309, seed = 4, party = { member("mag_fire", 1) } })
    local result = r:run(600)
    T.eq(result, "fail")
end)

T.case("스테이지 진행: 같은 시드는 같은 결과", function()
    local function go(seed)
        local strong = Sheet.new()
        Sheet.add(strong, "AttackDamage", Stats.FLAT, 60)
        Sheet.add(strong, "MaxHp", Stats.FLAT, 3000)
        local r = Runner.new({ difficulty = 1, section = 105, seed = seed, account = strong,
            party = { member("pal_prot", 15), member("rog_assa", 15), member("sha_resto", 15) } })
        local result, time = r:run(1800)
        return result .. string.format(":%.2f:%.3f:%d", time, r.totals.gold, r.totals.kills)
    end
    T.eq(go(9), go(9))
    T.ok(go(9) ~= go(10))
end)

T.case("경험치: 영웅마다 레벨 차 페널티가 따로 적용된다", function()
    local strong = Sheet.new()
    Sheet.add(strong, "AttackDamage", Stats.FLAT, 300)
    Sheet.add(strong, "MaxHp", Stats.FLAT, 20000)
    -- 구간 101의 스테이지 레벨은 1. 레벨 1 영웅은 전액, 레벨 40 영웅은 크게 깎인다.
    local r = Runner.new({ difficulty = 1, section = 101, seed = 2, account = strong,
        party = { member("war_prot", 1), member("mag_fire", 40) } })
    T.eq(r:run(900), "clear")
    T.ok(r.totals.exp[1] > 0)
    T.ok(r.totals.exp[2] < r.totals.exp[1] * 0.2, "고레벨 영웅의 경험치가 깎이지 않음")
end)

if verbose then
    io.write("\n  장비 없는 파티로 일반 난이도 앞부분을 돌려 본 결과(밸런스 조정 전)\n")
    io.write(string.format("  %-34s %-6s %-8s %8s %8s\n", "구간", "레벨", "결과", "시간(초)", "처치"))
    for _, key in ipairs({ 101, 102, 103, 104, 105 }) do
        local level = Tables.STAGES[Dungeons.stageKey(1, key)].level
        local heroLevel = math.max(1, level + 1)
        local r = Runner.new({ difficulty = 1, section = key, seed = 7,
            party = { member("war_prot", heroLevel), member("mag_fire", heroLevel), member("pri_holy", heroLevel) } })
        local result, time = r:run(1200)
        io.write(string.format("  %-34s %-6d %-8s %8.0f %8d\n", Dungeons.sections[key].name, level, result, time, r.totals.kills))
    end
end

if not T.report("test_stages") then os.exit(1) end
