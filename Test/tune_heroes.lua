-- 영웅별 화력 보정 계수를 정한다(검사 묶음에는 들어가지 않는다). 결과는 WIH/Data/HeroTuning.lua 에 쓴다.
-- 방법: 보정 없이 허수아비 화력을 잰다(Test/test_heroes.lua와 같은 조건: 스테이지 레벨 50, 장비 없음,
--       스킬 점수 100과 40 두 경우, 단일 대상 60초 × 0.6 + 3대상 30초 × 0.4). 역할 묶음(딜러 / 탱커 / 힐러)마다
--       중앙값을 목표로 계수 = 목표 ÷ 측정값(두 경우의 기하 평균)을 구하고 0.4~2.5로 묶는다. [독자]
-- 사용: lua5.1 Test/tune_heroes.lua [-n] (-n이면 파일을 쓰지 않고 표만 보인다)

package.path = "./?.lua;" .. package.path
local W = require("Test.engine").load()
local Heroes, HeroBuild, Battle, Unit = W.Heroes, W.HeroBuild, W.Battle, W.Unit
local dry = arg and arg[1] == "-n"
W.HeroTuning.damage = {}         -- 보정 없이 잰다

local function formsOf(hero)
    if not hero.forms then return { false } end
    local out = {}
    for form in pairs(hero.forms) do out[#out + 1] = form end
    table.sort(out)
    return out
end

local function measure(hero, form, seconds, enemies, points)
    local chosen = { hero.skills[1], hero.skills[2], hero.skills[3], hero.skills[4], hero.skills[5], hero.skills[6] }
    local active, passive = HeroBuild.autoAllocate(hero, points, chosen)
    local best = 0
    for _, pick in ipairs({ { 1, 2, 3, 4 }, { 1, 2, 5, 6 }, { 3, 4, 5, 6 }, { 1, 3, 5, 6 }, { 2, 4, 5, 6 }, { 1, 2, 4, 6 } }) do
        local b = Battle.new({ seed = 21, stageLevel = 50 })
        local skills = {}
        for i, idx in ipairs(pick) do skills[i] = { hero.skills[idx], math.max(1, active[hero.skills[idx]] or 1) } end
        local u = HeroBuild.spawn(b, hero.id, { form = form or nil, skills = skills, passivePoints = passive, x = 0 })
        for i = 1, enemies do
            b:addUnit(Unit.new({ name = "허수아비", team = 2, kind = "monster", isBoss = enemies == 1,
                base = { MaxHp = 1e12, AttackSpeed = 100, MovementSpeed = 0, CriticalDamage = 1000 },
                range = 0, x = math.min(u.range, 600) * 0.8 + (i - 1) * 40 }))
        end
        b:run(seconds)
        local total = 0
        for _, o in ipairs(b.units) do if o.team == 2 then total = total + (1e12 - o.hp) end end
        if total / seconds > best then best = total / seconds end
    end
    return best
end

local GROUP = { melee = "dps", ranged = "dps", summoner = "dps", tank = "tank", healer = "healer" }
local rows, byGroup = {}, { dps = {}, tank = {}, healer = {} }
for _, h in ipairs(Heroes.list) do
    for _, form in ipairs(formsOf(h)) do
        local role = h.forms and h.forms[form].role or h.role
        local v = {}
        for _, pts in ipairs({ 100, 40 }) do v[#v + 1] = measure(h, form, 60, 1, pts) * 0.6 + measure(h, form, 30, 3, pts) * 0.4 end
        local key = h.id .. (form and (":" .. form) or "")
        local row = { key = key, name = h.name .. (form and (" " .. h.forms[form].name) or ""), group = GROUP[role], v = v }
        rows[#rows + 1] = row
        table.insert(byGroup[row.group], row)
    end
end

local function median(list, i)
    local vals = {}
    for _, r in ipairs(list) do vals[#vals + 1] = r.v[i] end
    table.sort(vals)
    local n = #vals
    return n % 2 == 1 and vals[(n + 1) / 2] or (vals[n / 2] + vals[n / 2 + 1]) / 2
end

local out = {}
for group, list in pairs(byGroup) do
    local m100, m40 = median(list, 1), median(list, 2)
    for _, r in ipairs(list) do
        local f = math.sqrt((m100 / r.v[1]) * (m40 / r.v[2]))
        if f < 0.4 then f = 0.4 elseif f > 2.5 then f = 2.5 end
        r.factor = math.floor(f * 100 + 0.5) / 100
    end
end
table.sort(rows, function(a, b) return a.key < b.key end)
io.write(string.format("%-24s %-6s %10s %10s %6s\n", "영웅", "묶음", "100점", "40점", "계수"))
for _, r in ipairs(rows) do
    io.write(string.format("%-24s %-6s %10.1f %10.1f %6.2f\n", r.key, r.group, r.v[1], r.v[2], r.factor))
end
if dry then return end
local lines = {
    "-- 영웅별 화력 보정 계수 [독자]. Test/tune_heroes.lua 가 만든 파일이므로 직접 고치지 않는다.",
    "-- 영웅의 모든 피해(기본 공격, 스킬, 지속 피해, 소환물)에 곱한다. 역할 묶음(딜러·탱커·힐러)의 중앙값에 맞춘 값이다.",
    "",
    "local _, WIH = ...",
    'local HeroTuning = WIH.module("HeroTuning")',
    "",
    "HeroTuning.damage = {",
}
for _, r in ipairs(rows) do lines[#lines + 1] = string.format('    ["%s"] = %.2f,', r.key, r.factor) end
lines[#lines + 1] = "}"
lines[#lines + 1] = ""
lines[#lines + 1] = "return HeroTuning"
lines[#lines + 1] = ""
local f = assert(io.open("WIH/Data/HeroTuning.lua", "w"))
f:write(table.concat(lines, "\n"))
f:close()
print("WIH/Data/HeroTuning.lua 를 썼다")
