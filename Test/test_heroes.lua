-- 영웅과 스킬 데이터의 검증.
-- 실행: lua5.1 Test/test_heroes.lua [-v]

package.path = "./?.lua;" .. package.path
local T = require("Test.t")
local WIH = require("Test.engine").load()

local Stats, Unit, Battle, Skills = WIH.Stats, WIH.Unit, WIH.Battle, WIH.Skills
local Heroes, SkillData, HeroBuild = WIH.Heroes, WIH.SkillData, WIH.HeroBuild
local verbose = arg and arg[1] == "-v"

local function monster(over)
    local spec = { name = "시험 몬스터", team = 2, kind = "monster",
        base = { MaxHp = 5000, AttackDamage = 6, AttackSpeed = 100, MovementSpeed = 600, CriticalDamage = 1000 },
        melee = true, range = 150, x = 1200, rank = 1 }
    for k, v in pairs(over or {}) do
        if k == "base" then for s, val in pairs(v) do spec.base[s] = val end else spec[k] = v end
    end
    return Unit.new(spec)
end

-- 영웅의 형태 목록(야성 드루이드는 둘)
local function formsOf(hero)
    if hero.forms then
        local out = {}
        for form in pairs(hero.forms) do out[#out + 1] = form end
        table.sort(out)
        return out
    end
    return { false }
end

T.case("영웅 30명과 직업 10개", function()
    T.eq(#Heroes.list, 30)
    local perClass = {}
    for _, h in ipairs(Heroes.list) do
        perClass[h.class] = (perClass[h.class] or 0) + 1
        T.ok(Heroes.CLASSES[h.class], "알 수 없는 직업: " .. tostring(h.class))
        T.ok(Heroes.ROLES[h.role], "알 수 없는 역할: " .. tostring(h.role))
        T.ok(Heroes.MAIN_WEAPONS[h.main], h.id .. ": 주무기 종류 없음 " .. tostring(h.main))
        T.ok(Heroes.SUB_WEAPONS[h.sub], h.id .. ": 보조무기 종류 없음 " .. tostring(h.sub))
    end
    for _, class in ipairs(Heroes.CLASS_ORDER) do T.eq(perClass[class], 3, class) end
    for _, w in pairs(Heroes.SUB_WEAPONS) do T.ok(Stats.defs[w.stat], "보조무기 능력치 없음: " .. w.stat) end
end)

T.case("영웅마다 액티브 6개와 패시브 16개, 스킬 ID 중복 없음", function()
    local seen = {}
    for _, h in ipairs(Heroes.list) do
        T.eq(#h.skills, 6, h.id .. " 액티브 수")
        T.eq(#h.passives, 16, h.id .. " 패시브 수")
        for _, id in ipairs(h.skills) do
            T.ok(SkillData.defs[id], h.id .. ": 정의되지 않은 스킬 " .. id)
            T.ok(not seen[id], "여러 영웅이 같은 스킬을 씀: " .. id)
            seen[id] = h.id
        end
        local maxPoints = 0
        for i, node in ipairs(h.passives) do
            T.ok(Stats.defs[node.stat], h.id .. " 패시브 " .. i .. ": 능력치 없음 " .. tostring(node.stat))
            T.ok(node.per ~= 0 and node.max >= 1, h.id .. " 패시브 " .. i .. ": 수치가 0")
            maxPoints = maxPoints + node.max
        end
        -- 트리를 다 채우는 데 드는 포인트가 가진 포인트(100)보다 커야 선택이 생긴다.
        T.ok(maxPoints + 6 * Heroes.ACTIVE_MAX_BY_POINTS > 100, h.id .. ": 트리가 너무 작음")
    end
    local n = 0
    for _ in pairs(SkillData.defs) do n = n + 1 end
    T.eq(n, 180, "스킬 정의 수")
    T.eq((function() local c = 0 for _ in pairs(seen) do c = c + 1 end return c end)(), 180, "영웅이 쓰는 스킬 수")
end)

T.case("스킬 데이터 검사: 효과 종류, 능력치, 설명문, 레벨에 따른 변화", function()
    local problems = SkillData.validate()
    T.eq(#problems, 0, table.concat(problems, "\n      "))
end)

T.case("모든 스킬의 설명문 수치가 레벨 1 → 10에서 달라진다", function()
    for _, h in ipairs(Heroes.list) do
        for _, form in ipairs(formsOf(h)) do
            for _, id in ipairs(h.skills) do
                local def = SkillData.resolve(id, form or nil)
                local a, b = SkillData.describe(def, 1), SkillData.describe(def, 10)
                T.ok(a ~= b, def.id .. ": 레벨 1과 10의 설명문이 같음")
                T.ok(not a:find("{", 1, true), def.id .. ": 채워지지 않은 자리 표시")
            end
        end
    end
end)

-- 영웅 하나를 스킬 네 개씩 두 묶음으로 나눠 실제 전투에 넣는다.
local function runHero(hero, form, skillIds, level, seconds, seed)
    local b = Battle.new({ seed = seed or 3, stageLevel = 5 })
    local skills = {}
    for i, id in ipairs(skillIds) do skills[i] = { id, level } end
    local casts = {}
    b.listeners[1] = function(ev, a, def) if ev == "cast" and def then casts[def.baseId or def.id] = true end end
    -- 레벨 1 기본 공격력(1~2)으로는 60초 안에 적의 체력을 의미 있게 깎지 못하므로 시험용 공격력을 준다.
    local power = WIH.Sheet.new()
    WIH.Sheet.add(power, "AttackDamage", Stats.FLAT, 60)
    local u = HeroBuild.spawn(b, hero.id, { form = form or nil, skills = skills, rank = 2, x = 0, account = power })
    -- 맞아 줄 동료(체력이 깎여야 치유·생존 스킬이 발동한다)와 쓰러진 동료
    local front = HeroBuild.spawn(b, hero.id == "war_prot" and "pal_prot" or "war_prot", { rank = 1, x = 50 })
    local fallen = HeroBuild.spawn(b, "mag_fire", { rank = 3, x = -100 })
    front.base.MaxHp = 3000
    front:invalidate()
    front.hp = 3000
    for i = 1, 4 do b:addUnit(monster({ x = 900 + i * 60 })) end
    b:addUnit(monster({ x = 1300, isBoss = true, base = { MaxHp = 60000, AttackDamage = 15 } }))
    b:addUnit(monster({ x = 1500, melee = false, range = 800, base = { AttackDamage = 4 } }))
    b:run(2)
    b:kill(nil, fallen)
    u.hp = u:get("MaxHp") * 0.3
    front.hp = front:get("MaxHp") * 0.25
    b:run(seconds)
    return b, u, casts
end

T.case("모든 스킬을 레벨 1, 5, 10으로 전투에서 실행해도 오류가 없고 실제로 발동한다", function()
    local never = {}
    for _, h in ipairs(Heroes.list) do
        for _, form in ipairs(formsOf(h)) do
            local used = {}
            for _, level in ipairs({ 1, 5, 10 }) do
                for _, group in ipairs({ { 1, 2, 3, 4 }, { 5, 6, 1, 2 }, { 3, 4, 5, 6 } }) do
                    local ids = {}
                    for i, idx in ipairs(group) do ids[i] = h.skills[idx] end
                    local ok, b, _, casts = pcall(runHero, h, form, ids, level, 60, 10 + level)
                    if not ok then error(h.id .. " (" .. tostring(form) .. ") 레벨 " .. level .. ": " .. tostring(b)) end
                    for id in pairs(casts) do used[id] = true end
                end
            end
            for _, id in ipairs(h.skills) do
                local def = SkillData.resolve(id, form or nil)
                if def.act.type ~= "aura" and not used[id] then
                    never[#never + 1] = h.name .. (form and ("(" .. form .. ")") or "") .. " " .. def.name
                end
            end
        end
    end
    T.eq(#never, 0, "한 번도 발동하지 않은 스킬: " .. table.concat(never, ", "))
end)

T.case("자동 투자: 티어 해금 순서를 지키고 포인트를 넘기지 않는다", function()
    for _, h in ipairs(Heroes.list) do
        local chosen = { h.skills[1], h.skills[2], h.skills[4], h.skills[6] }
        for _, total in ipairs({ 0, 5, 30, 100 }) do
            local active, passive, spent = HeroBuild.autoAllocate(h, total, chosen)
            T.ok(spent <= total, h.id .. ": 포인트 초과")
            local sum = 0
            for _, v in pairs(active) do
                T.ok(v <= Heroes.ACTIVE_MAX_BY_POINTS)
                sum = sum + v
            end
            for index, v in pairs(passive) do
                T.ok(v <= h.passives[index].max)
                sum = sum + v
            end
            T.eq(sum, spent)
            if total == 100 then T.ok(spent >= 95, h.id .. ": 100포인트를 거의 다 써야 함 (" .. spent .. ")") end
        end
    end
end)

-- 허수아비 상대 화력 측정(밸런스 조정 전의 출발값 확인용)
local function measure(hero, form, seconds, enemies)
    local b = Battle.new({ seed = 21, stageLevel = 50 })
    local chosen = { hero.skills[1], hero.skills[2], hero.skills[3], hero.skills[4], hero.skills[5], hero.skills[6] }
    local active, passive = HeroBuild.autoAllocate(hero, 100, chosen)
    -- 장착 4칸: 피해에 기여하는 순서를 모르므로 앞의 네 개와 뒤의 네 개 중 높은 쪽을 쓴다.
    local best = 0
    for _, pick in ipairs({ { 1, 2, 3, 4 }, { 1, 2, 5, 6 }, { 3, 4, 5, 6 }, { 1, 3, 5, 6 }, { 2, 4, 5, 6 }, { 1, 2, 4, 6 } }) do
        local bb = Battle.new({ seed = 21, stageLevel = 50 })
        local skills = {}
        for i, idx in ipairs(pick) do skills[i] = { hero.skills[idx], active[hero.skills[idx]] or 5 } end
        local u = HeroBuild.spawn(bb, hero.id, { form = form or nil, skills = skills, passivePoints = passive, x = 0 })
        for i = 1, enemies do
            bb:addUnit(Unit.new({ name = "허수아비", team = 2, kind = "monster", isBoss = enemies == 1,
                base = { MaxHp = 1e12, AttackSpeed = 100, MovementSpeed = 0, CriticalDamage = 1000 },
                range = 0, x = math.min(u.range, 600) * 0.8 + (i - 1) * 40 }))
        end
        bb:run(seconds)
        local total = 0
        for _, o in ipairs(bb.units) do
            if o.team == 2 then total = total + (1e12 - o.hp) end
        end
        if total / seconds > best then best = total / seconds end
    end
    return best
end

T.case("화력 측정이 동작한다(모든 영웅의 초당 피해가 0보다 큼)", function()
    local rows = {}
    for _, h in ipairs(Heroes.list) do
        for _, form in ipairs(formsOf(h)) do
            local single = measure(h, form, 60, 1)
            local multi = measure(h, form, 30, 3)
            T.ok(single > 0, h.id .. ": 단일 대상 피해가 0")
            rows[#rows + 1] = { name = h.name .. (form and (" " .. h.forms[form].name) or ""), role = h.forms and h.forms[form].role or h.role,
                single = single, multi = multi }
        end
    end
    if verbose then
        io.write("\n  레벨 101, 100포인트 자동 투자, 장비 없음, 스테이지 레벨 50 기준 초당 피해\n")
        io.write(string.format("  %-28s %-10s %12s %12s\n", "영웅", "역할", "단일(60초)", "3대상(30초)"))
        table.sort(rows, function(a, c) return a.single > c.single end)
        for _, r in ipairs(rows) do
            io.write(string.format("  %-28s %-10s %12.1f %12.1f\n", r.name, Heroes.ROLES[r.role], r.single, r.multi))
        end
    end
end)

if not T.report("test_heroes") then os.exit(1) end
