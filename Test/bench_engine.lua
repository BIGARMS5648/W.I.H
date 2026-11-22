-- 엔진의 틱당 계산 비용 측정. 실행: lua5.1 Test/bench_engine.lua
-- 게임 내 환경 점검의 기준 측정(산술 100만 회 14.4ms 등)과 같은 측정을 여기서도 해서 배율을 추정한다.

package.path = "./?.lua;" .. package.path
local WIH = require("Test.engine").load()
local Battle, HeroBuild, Unit = WIH.Battle, WIH.HeroBuild, WIH.Unit

local function clock() return os.clock() * 1000 end

local t0 = clock()
local s = 0
for i = 1, 1000000 do s = s + (i % 7) * 0.5 end
local arith = clock() - t0
local function f(a, b) return a * b + 1 end
t0 = clock()
for i = 1, 500000 do s = f(i, 2) end
local calls = clock() - t0

local function scenario(monsters)
    local b = Battle.new({ seed = 5, stageLevel = 50 })
    local party = { { "war_prot", { 1, 2, 3, 4 } }, { "hun_bm", { 1, 2, 3, 4 } }, { "mag_fire", { 1, 2, 3, 4 } },
        { "tin_destroy", { 1, 2, 3, 4 } }, { "pri_holy", { 1, 2, 3, 4 } } }
    for rank, p in ipairs(party) do
        local hero = WIH.Heroes.byId[p[1]]
        local skills = {}
        for i, idx in ipairs(p[2]) do skills[i] = { hero.skills[idx], 5 } end
        local u = HeroBuild.spawn(b, p[1], { skills = skills, rank = rank, x = 0 })
        u.base.MaxHp = 1e9
        u:invalidate()
        u.hp = 1e9
    end
    for i = 1, monsters do
        b:addUnit(Unit.new({ name = "몹", team = 2, kind = "monster",
            base = { MaxHp = 1e9, AttackDamage = 5, AttackSpeed = 80, MovementSpeed = 150, CriticalDamage = 1000 },
            melee = i % 4 ~= 0, range = i % 4 ~= 0 and 150 or 800, x = 700 + i * 40 }))
    end
    b:run(10)                       -- 자리 잡기
    local ticks = 20 * 60
    local start = clock()
    for _ = 1, ticks do b:step() end
    return (clock() - start) / ticks, #b.units
end

io.write(string.format("기준 측정: 산술 100만 회 %.1f ms, 함수 호출 50만 회 %.1f ms\n", arith, calls))
for _, n in ipairs({ 5, 12, 21 }) do
    local perTick, units = scenario(n)
    io.write(string.format("영웅 5 + 몬스터 %2d (유닛 %2d): 틱당 %.3f ms → 초당(20틱) %.1f ms\n", n, units, perTick, perTick * 20))
end
