-- 유물·유물함 검사. 실행: lua5.1 Test/test_relics.lua

package.path = "./?.lua;" .. package.path
local T = require("Test.t")
local WIH = require("Test.engine").load()
local Relics, RelicTable, Game, Rng, Runes, Expeditions, HeroBuild, Battle, Sheet, Stats, Cube, Save =
    WIH.Relics, WIH.RelicTable, WIH.Game, WIH.Rng, WIH.Runes, WIH.Expeditions, WIH.HeroBuild, WIH.Battle, WIH.Sheet, WIH.Stats,
    WIH.Cube, WIH.Save

local function count(t) local n = 0; for _ in pairs(t) do n = n + 1 end; return n end

local function newState()
    local s = Game.new("Horde", "war_prot", 0)
    Relics.ensure(s)
    return s
end

-- 원정을 열어 유물 칸을 연다. hell = true면 지옥 강도 10까지 클리어한 것으로 둔다(2칸).
local function openSlots(s, hell)
    s.stage.cleared[Expeditions.keys[2][1]] = 1
    if hell then s.stage.cleared[Expeditions.keys[3][10]] = 1 end
end

-- 원하는 칸 색과 공명 수치를 가진 유물함을 만든다(시험용으로 굴린 뒤 고친다).
local function quiver(s, id, grade, slots, res)
    local q = Relics.makeReliquary(s, id, grade, Rng.new(3))
    if slots then for i, c in ipairs(slots) do q.slots[i] = c end end
    if res then q.res = res end
    return q
end

local function relicOf(color, double)
    for id, def in pairs(RelicTable.RELICS) do
        if def.color == color and def.double == (double or false) and def.stat:sub(1, 8) ~= "Decrease" then return id end
    end
end

T.case("원작 표: 유물 36종 × 10등급, 유물함 62종, 조율 비용", function()
    T.eq(count(RelicTable.RELICS), 36)
    T.eq(count(RelicTable.RELIQUARIES), 62)
    for id, def in pairs(RelicTable.RELICS) do
        T.eq(#def.range, 10, "유물 " .. id)
        T.ok(Relics.COLOR_NAMES[def.color], "색 " .. id)
    end
    T.eq(#RelicTable.POOL, 10)
    T.eq(RelicTable.ATTUNE.RELIQUARY[1][1], 100); T.eq(RelicTable.ATTUNE.RELIC[10][2], 7320000)     -- [원작]
    for id in pairs(Relics.EFFECTS) do T.ok(RelicTable.RELIQUARIES[id], "공명 효과의 유물함이 표에 있음: " .. id) end
end)

T.case("장착 칸: 원정 첫 클리어 1칸, 지옥 강도 10 클리어 2칸", function()
    local s = newState()
    T.eq(Relics.slotCount(s), 0)
    T.ok(not Relics.unlocked(s))
    openSlots(s)
    T.eq(Relics.slotCount(s), 1)
    openSlots(s, true)
    T.eq(Relics.slotCount(s), 2)
    local q = quiver(s, 790008, 5)
    T.ok(Relics.equip(s, 1, q.uid))
    T.ok(Relics.equip(s, 2, q.uid))
    T.eq(s.relics.equipped[1], nil, "같은 유물함은 한 칸에만")
    T.eq(s.relics.equipped[2], q.uid)
    s.stage.cleared[Expeditions.keys[3][10]] = nil
    T.ok(not Relics.equip(s, 2, q.uid), "닫힌 칸")
end)

T.case("유물함 생성: 등급의 칸 수·고정 속성 수, 수치가 범위 안", function()
    local s = newState()
    local rng = Rng.new(11)
    for id, def in pairs(RelicTable.RELIQUARIES) do
        for g, row in pairs(def.grades) do
            local q = Relics.makeReliquary(s, id, g, rng)
            T.eq(#q.slots, row[1], "칸 수 " .. id .. "/" .. g)
            T.eq(#q.stats, row[2], "고정 속성 수 " .. id .. "/" .. g)
            local names = {}
            for _, st in ipairs(q.stats) do
                T.ok(not names[st[1]], "고정 속성이 겹치지 않음 " .. id)
                names[st[1]] = true
            end
            local eff = Relics.EFFECTS[id]
            if eff then T.ok(q.res >= eff[2] and q.res <= eff[3], "공명 수치 범위 " .. id) end
        end
    end
    for id, def in pairs(RelicTable.RELICS) do
        for g = 1, 10 do
            local r = Relics.makeRelic(s, id, g, rng)
            T.ok(r.value >= def.range[g][1] and r.value <= def.range[g][2], "유물 수치 범위 " .. id)
        end
    end
end)

T.case("끼우기: 색이 맞아야 하고 하얀 유물은 아무 칸에나, 메아리는 2개로 센다", function()
    local s = newState()
    local q = quiver(s, 790008, 5, { "RED", "RED", "BLUE" })
    local red = Relics.makeRelic(s, relicOf("RED"), 5, Rng.new(1))
    local blue = Relics.makeRelic(s, relicOf("BLUE"), 5, Rng.new(1))
    local white = Relics.makeRelic(s, relicOf("WHITE"), 5, Rng.new(1))
    T.ok(not Relics.socket(s, q.uid, 1, blue.uid), "빨간 칸에 파란 유물은 안 됨")
    T.ok(Relics.socket(s, q.uid, 1, red.uid))
    T.ok(Relics.socket(s, q.uid, 3, white.uid), "하얀 유물은 파란 칸에도")
    T.eq(red.holder, q.uid)
    T.ok(not Relics.resonating(s, q), "빨강 1개로는 공명하지 않음(조건 빨강 3)")
    -- 메아리 빨강(2개로 셈) + 빨강 = 3
    local echo = Relics.makeRelic(s, 710009, 5, Rng.new(1))
    T.ok(RelicTable.RELICS[710009].double)
    T.ok(Relics.socket(s, q.uid, 2, echo.uid))
    T.eq(Relics.colorCounts(s, q).RED, 3)
    T.ok(Relics.resonating(s, q), "메아리를 2개로 세어 공명")
    -- 다른 유물함으로 옮기면 원래 자리는 빈다
    local q2 = quiver(s, 790008, 5, { "RED", "RED", "RED" })
    T.ok(Relics.socket(s, q2.uid, 1, echo.uid))
    T.eq(q.sockets[2], nil)
    T.ok(not Relics.resonating(s, q))
    -- 미완성 등급은 공명하지 않는다
    local low = quiver(s, 790008, 3, { "RED", "RED" })
    T.ok(RelicTable.RELIQUARIES[790008].grades[3][3], "3등급은 미완성")
    T.ok(Relics.socket(s, low.uid, 1, red.uid))
    T.ok(not Relics.resonating(s, low))
end)

T.case("능력치: 장착한 유물함의 고정 속성과 유물이 파티 전원의 시트에 들어간다", function()
    local s = newState()
    openSlots(s)
    local q = quiver(s, 790001, 5, { "RED", "RED", "BLUE" })
    q.stats = { { "AttackDamage", Stats.INC, 300 }, { "AttackAndCastSpeed", Stats.INC, 100 } }
    local boss = Relics.makeRelic(s, 710006, 5, Rng.new(1)); boss.value = 150          -- 보스 피해 +15%
    local gold = nil
    for id, def in pairs(RelicTable.RELICS) do if def.stat == "GoldAmount" then gold = id end end
    T.ok(Relics.socket(s, q.uid, 1, boss.uid))
    local before = HeroBuild.makeUnit("war_prot", { account = Runes.sheet(s) })
    T.ok(Relics.equip(s, 1, q.uid))
    local after = HeroBuild.makeUnit("war_prot", { account = Runes.sheet(s) })
    T.near(after:get("AttackDamage") / before:get("AttackDamage"), 1.3, 1e-6, "공격력 30% 증가")
    T.near(after:get("AttackSpeed") / before:get("AttackSpeed"), 1.1, 1e-6, "공격·시전 속도 → 공격 속도")
    T.near(after:get("CastSpeed") / before:get("CastSpeed"), 1.1, 1e-6, "공격·시전 속도 → 시전 속도")
    T.near(after:get("BossDamage"), 0.15, 1e-9, "기본값 0인 유물 능력치의 % 증가는 더한다")
    -- 메아리 유물의 대가: 저항 감소
    local echo = Relics.makeRelic(s, 710009, 5, Rng.new(1))
    T.ok(Relics.socket(s, q.uid, 2, echo.uid))
    local u = HeroBuild.makeUnit("war_prot", { account = Runes.sheet(s) })
    T.eq(u:get("FireResistance") - before:get("FireResistance"), -echo.value)
    -- 골드 유물은 계정 합계로
    if gold then
        local g = Relics.makeRelic(s, gold, 5, Rng.new(1))
        local q3 = quiver(s, 790001, 5, { RelicTable.RELICS[gold].color, "RED", "RED" })
        q3.stats = {}
        T.ok(Relics.socket(s, q3.uid, 1, g.uid))
        openSlots(s, true)
        T.ok(Relics.equip(s, 2, q3.uid))
        T.eq(Runes.totals(s).AdditionalGold or 0, g.value)
    end
    -- 장착을 풀면 사라진다
    Relics.equip(s, 1, nil)
    local off = HeroBuild.makeUnit("war_prot", { account = Runes.sheet(s) })
    T.near(off:get("AttackDamage"), before:get("AttackDamage"), 1e-6)
end)

T.case("공명: 힘의 축복·끈기·빈 칸", function()
    local s = newState()
    openSlots(s)
    s.party = { "war_prot" }
    s.unlocks.partySlots = 5
    local function sheetAfter(q)
        s.relics.equipped[1] = q.uid
        return HeroBuild.makeUnit("war_prot", { account = Runes.sheet(s) })
    end
    local base = HeroBuild.makeUnit("war_prot", { account = Runes.sheet(s) })
    local might = quiver(s, 790008, 5, { "RED", "RED", "RED" }); might.stats = {}
    for i = 1, 3 do Relics.socket(s, might.uid, i, Relics.makeRelic(s, 710001, 1, Rng.new(1)).uid) end
    local u = sheetAfter(might)
    local relicInc = 0
    for _, uid in pairs(might.sockets) do relicInc = relicInc + s.relics.items[uid].value end
    T.ok(Relics.resonating(s, might))
    T.near(u:get("AttackDamage") / base:get("AttackDamage"), (1 + relicInc / 1000) * 1.5, 1e-6, "힘의 축복 1레벨 = 50% 곱연산 [원작]")
    -- 빈 편성 칸(열린 5칸 중 1칸 사용 → 4칸 빔)
    local king = quiver(s, 794012, 6, { "RED", "BLUE", "YELLOW", "PURPLE" }, 50); king.stats = {}
    local cond = RelicTable.RELIQUARIES[794012].cond
    local i = 0
    for color, n in pairs(cond) do
        for _ = 1, n do
            i = i + 1
            king.slots[i] = color
            T.ok(Relics.socket(s, king.uid, i, Relics.makeRelic(s, relicOf(color), 6, Rng.new(1)).uid))
        end
    end
    T.ok(Relics.resonating(s, king), "잊힌 왕 공명")
    local k = sheetAfter(king)
    T.near(k:get("DamageDealt") / base:get("DamageDealt"), 1 + 0.05 * 4, 1e-9, "주는 피해 +20%(영웅 보정 계수와 곱해진다)")
    T.near(k:get("TakenAll") - base:get("TakenAll"), -0.05 * 4, 1e-9)
end)

-- 시험 전투: 영웅 1명과 몬스터 1마리
local function duel(s, monsterHp, seed)
    local b = Battle.new({ seed = seed or 1, stageLevel = 10, autoRevive = false })
    local hero = HeroBuild.spawn(b, "war_prot", { account = Runes.sheet(s), rank = 1, x = 0 })
    local mob = WIH.Unit.new({ name = "허수아비", team = 2, kind = "monster", base = { MaxHp = monsterHp, AttackDamage = 0, MovementSpeed = 0, AttackSpeed = 1 },
        static = Sheet.new(), melee = true, range = 100, x = 50 })
    mob.hp = monsterHp
    b:addUnit(mob)
    Relics.install(b, { hero }, s)
    return b, hero, mob
end

local function resonate(s, id, grade, res)
    local def = RelicTable.RELIQUARIES[id]
    local q = quiver(s, id, grade, nil, res)
    q.stats = {}
    local i = 0
    for color, n in pairs(def.cond) do
        for _ = 1, n do
            i = i + 1
            q.slots[i] = color
            assert(Relics.socket(s, q.uid, i, Relics.makeRelic(s, relicOf(color), grade, Rng.new(1)).uid))
        end
    end
    assert(Relics.resonating(s, q), "공명하지 않음: " .. id)
    s.relics.equipped[1] = q.uid
    return q
end

T.case("공명(전투): 처형자는 체력이 낮은 일반 몬스터를 즉사시키고 보스는 제외", function()
    local s = newState()
    openSlots(s)
    resonate(s, 790005, 5, 100)                       -- 체력 10% 이하
    local b, hero, mob = duel(s, 1000)
    mob.hp = 120
    b:receive(hero, mob, 30, "Physical", { noAvoid = true })
    T.ok(not mob.alive, "90 → 9% → 즉사")
    local b2, hero2, boss = duel(s, 1000)
    boss.isBoss = true
    boss.hp = 120
    b2:receive(hero2, boss, 30, "Physical", { noAvoid = true })
    T.ok(boss.alive, "보스는 즉사하지 않음")
end)

T.case("공명(전투): 불사조는 한 번 되살리고, 공허는 추가 암흑 피해", function()
    local s = newState()
    openSlots(s)
    resonate(s, 790009, 5, 200)
    local b, hero = duel(s, 1000)
    b:kill(nil, hero)
    T.ok(hero.alive, "되살아남")
    T.near(hero.hp / hero:get("MaxHp"), 0.2, 1e-6)
    b:kill(nil, hero)
    T.ok(not hero.alive, "스테이지당 1회")

    local s2 = newState()
    openSlots(s2)
    resonate(s2, 790011, 5, 100)
    local b2, hero2, mob = duel(s2, 1e9)
    local seen = {}
    b2.listeners[#b2.listeners + 1] = function(ev, src, dst, dmg, elem) if ev == "damage" and dst == mob then seen[#seen + 1] = { dmg, elem } end end
    b2:receive(hero2, mob, 1000, "Physical", { noAvoid = true })
    T.eq(#seen, 2)
    local by = {}
    for _, e in ipairs(seen) do by[e[2]] = e[1] end
    T.ok(by.Chaos and by.Physical, "물리 + 암흑")
    T.ok(by.Chaos > 0 and by.Chaos <= by.Physical * 0.1 + 1e-6, "준 피해의 10% 이하(저항 적용)")
end)

T.case("기원: 오염된 재료 → 투입 등급 이상의 유물함·유물, 구현한 공명만", function()
    local s = newState()
    local rng = Rng.new(5)
    T.ok(not Cube.offering(s, 161003, rng), "기원 레시피가 닫혀 있음")
    s.cube.unlocked[Cube.recipeKey and Cube.recipeKey(Cube.find("OFFERING")) or "OFFERING"] = true
    if not Cube.unlocked(s, Cube.find("OFFERING")) then
        s.gold = 1e9; s.cube.level = 100
        assert(Cube.unlock(s, Cube.find("OFFERING")))
    end
    s.materials[161003] = 30
    s.materials[162004] = 30
    s.gold = 1e6
    local quivers, relics = 0, 0
    for _ = 1, 30 do
        local r = Cube.offering(s, 161003, rng)
        T.ok(r and r.relic and r.relic.kind == "RELIQUARY")
        T.ok(r.relic.grade >= 3, "투입 등급 이상")
        T.ok(Relics.EFFECTS[r.relic.id], "구현한 공명의 유물함")
        quivers = quivers + 1
        local r2 = Cube.offering(s, 162004, rng)
        T.ok(r2 and r2.relic and r2.relic.kind == "RELIC" and r2.relic.grade >= 4)
        relics = relics + 1
    end
    T.eq(s.materials[161003], nil)
    T.eq(s.gold, 1e6 - 60 * Relics.OFFER_FEE)
    T.eq(count(s.relics.items), 60)
    local sum = 0
    for _, p in pairs(Relics.offerOdds(161003)) do sum = sum + p end
    T.near(sum, 1, 1e-9)
    T.ok(Relics.offerOdds(162004)[4] > 0.5, "대부분 같은 등급")
    T.ok(WIH.Chests.resultText({ relic = s.relics.items[1] or select(2, next(s.relics.items)) }) ~= "")
end)

T.case("조율: 비용 = 기본 + 증가 × min(횟수, 19), 유물함은 칸 색을 다시 굴리고 맞지 않는 유물은 뺀다", function()
    local s = newState()
    s.gold = 1e9
    local q = quiver(s, 790008, 5, { "RED", "RED", "RED" })
    local r = Relics.makeRelic(s, relicOf("RED"), 5, Rng.new(1))
    T.ok(Relics.socket(s, q.uid, 1, r.uid))
    T.eq(Relics.attuneCost(q), 9450)
    local rng = Rng.new(8)
    local spent = 0
    for n = 1, 25 do
        local ok, cost = Relics.attune(s, q.uid, rng)
        T.ok(ok)
        T.eq(cost, 9450 + 11340 * math.min(n - 1, 19))
        spent = spent + cost
        if q.slots[1] ~= "RED" then T.eq(q.sockets[1], nil, "색이 바뀌면 빠짐"); T.eq(r.holder, nil) end
    end
    T.eq(s.gold, 1e9 - spent)
    local ok = Relics.attune(s, r.uid, rng)
    T.ok(ok)
    local range = RelicTable.RELICS[r.id].range[5]
    T.ok(r.value >= range[1] and r.value <= range[2])
    s.gold = 0
    T.ok(not Relics.attune(s, r.uid, rng), "골드 부족")
end)

T.case("팔기와 저장 검증", function()
    local s = newState()
    openSlots(s)
    local q = quiver(s, 790008, 5, { "RED", "RED", "RED" })
    local r = Relics.makeRelic(s, relicOf("RED"), 5, Rng.new(1))
    Relics.socket(s, q.uid, 1, r.uid)
    Relics.equip(s, 1, q.uid)
    T.ok(not Relics.sell(s, q.uid), "장착한 유물함은 못 판다")
    local gold = s.gold
    T.ok(Relics.sell(s, r.uid))
    T.eq(q.sockets[1], nil)
    T.ok(s.gold > gold)
    -- 망가진 기록
    s.relics.items[999] = { uid = 999, kind = "RELIC", id = 1 }
    s.relics.items[998] = { uid = 998, kind = "RELIC", id = 710001, grade = 1, value = 1, holder = 12345 }
    q.sockets[2] = 777
    s.relics.equipped[2] = 31337
    Relics.validate(s)
    T.eq(s.relics.items[999], nil)
    T.eq(s.relics.items[998].holder, nil)
    T.eq(q.sockets[2], nil)
    T.eq(s.relics.equipped[2], nil)
    T.eq(s.relics.equipped[1], q.uid)
    -- 불러오기 검증을 통과하고 유물이 그대로 남는다
    local back, info = Save.load(s)
    T.ok(back, info.status)
    T.eq(back.relics.equipped[1], q.uid)
    T.eq(back.relics.items[q.uid].kind, "RELIQUARY")
end)

if not T.report("test_relics") then os.exit(1) end
