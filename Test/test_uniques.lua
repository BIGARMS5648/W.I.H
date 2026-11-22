-- 장비 고유 능력치 검사. 실행: lua5.1 Test/test_uniques.lua

package.path = "./?.lua;" .. package.path
local T = require("Test.t")
local WIH = require("Test.engine").load()
local Uniques, UniqueTable, Items, Heroes, HeroBuild, Battle, Unit, Game, Inventory, Skills, SkillData =
    WIH.Uniques, WIH.UniqueTable, WIH.Items, WIH.Heroes, WIH.HeroBuild, WIH.Battle, WIH.Unit, WIH.Game, WIH.Inventory, WIH.Skills, WIH.SkillData

local function mob(b, x, hp, atk)
    local m = Unit.new({ name = "허수아비", team = 2, kind = "monster", base = { MaxHp = hp or 1e9, AttackDamage = atk or 0, MovementSpeed = 0, AttackSpeed = 100 },
        melee = true, range = 100, x = x or 60 })
    b:addUnit(m)
    return m
end

local function hero(b, id, mods, skills, x)
    local h = Heroes.byId[id]
    local list = {}
    for i, k in ipairs(skills or { 1, 2, 3, 4 }) do list[i] = { h.skills[k], 3 } end
    return HeroBuild.spawn(b, id, { skills = list, rank = 1, x = x or 0, uniques = mods })
end

T.case("원작 표: 고유 능력치가 붙은 장비 116개, 종류 43가지가 모두 옮겨졌다", function()
    T.eq(#UniqueTable.items, 116)
    local kinds, items = Uniques.coverage()
    local n = 0
    for k in pairs(kinds) do n = n + 1; T.ok(Uniques.NORMAL[k], "옮기지 않은 종류: " .. k) end
    T.eq(n, 43)
    T.eq(#Uniques.unknown, 0)
    T.ok(items >= 116, "이 프로젝트의 장비에 붙은 수: " .. items)
    for id, mod in pairs(Uniques.byItem) do
        local item = Items.byId[id]
        T.ok(item.grade >= 6, "아르카나 이상에만 붙는다 [원작]")
        T.ok(Uniques.text(mod) ~= "고유 능력치", "설명문: " .. mod.source)
    end
end)

T.case("스킬 규칙: 재사용 감소, 기본 공격 횟수 감소, 연속 공격, 원소 변경, 기본 공격 중 발동", function()
    -- 무기 전사: 2번 돌진(재사용), 1번 필사의 일격(기본 공격 횟수)
    local b = Battle.new({ seed = 1, stageLevel = 10 })
    local plain = hero(b, "war_arms", nil, { 1, 2 })
    local b2 = Battle.new({ seed = 1, stageLevel = 10 })
    local u = hero(b2, "war_arms", { { kind = "skillCd", idx = 2, pct = 0.3 }, { kind = "skillCount", idx = 1, n = 1 },
        { kind = "skillHits", idx = 1, n = 1 }, { kind = "skillElem", idx = 1, elem = "Fire" } }, { 1, 2 })
    T.near(u.skills[2].cd, plain.skills[2].cd * 0.7, 1e-9, "재사용 대기 -30%")
    T.eq(u.skills[1].unique.countReduce, 1)
    T.eq(u.skills[1].unique.extraHits, 1)
    local m = mob(b2)
    local seen = {}
    b2.listeners[#b2.listeners + 1] = function(ev, src, dst, dmg, elem) if ev == "damage" and dst == m then seen[elem] = (seen[elem] or 0) + 1 end end
    Skills.cast(b2, u, u.skills[1], m)
    T.ok((seen.Fire or 0) >= 2, "필사의 일격이 화염 피해로, 한 번 더 친다")
    -- 기본 공격 중 확률 발동(100%)
    local b3 = Battle.new({ seed = 1, stageLevel = 10 })
    local v = hero(b3, "war_arms", { { kind = "basicCast", idx = 2, chance = 1 } }, { 1, 2 })
    local m3 = mob(b3)
    local casts = 0
    b3.listeners[#b3.listeners + 1] = function(ev, a, def) if ev == "cast" and a == v and def == v.skills[2].def then casts = casts + 1 end end
    Skills.basicAttack(b3, v, m3)
    T.eq(casts, 1, "기본 공격 때 스킬 발동")
end)

T.case("설명문: 그 영웅의 스킬 이름, 효과가 없는 영웅이면 알려 준다", function()
    local mod = { kind = "skillCd", idx = 2, pct = 0.3 }
    T.ok(Uniques.text(mod, "war_arms"):find("'" .. SkillData.resolve(Heroes.byId.war_arms.skills[2]).name .. "'"))
    local trap = { kind = "trapMax", idx = 4, n = 2 }
    T.ok(Uniques.text(trap, "war_arms"):find("효과 없음"), "전사의 4번 스킬은 덫이 아니다")
    T.ok(not Uniques.text(mod):find("효과 없음"))
end)

T.case("방어 규칙: 한 번에 받는 피해 상한, 피해 나눠 받기, 막기 감소, 저항 통일", function()
    local b = Battle.new({ seed = 1, stageLevel = 10 })
    local u = hero(b, "war_prot", { { kind = "hitCap", pct = 0.5 } }, {})
    local m = mob(b)
    b:receive(m, u, 1e7, "Physical", { noAvoid = true })
    T.ok(u.alive and u.hp >= u:get("MaxHp") * 0.5 - 1e-6, "최대 체력의 50%를 넘는 피해를 받지 않는다")
    -- 나눠 받기
    local b2 = Battle.new({ seed = 1, stageLevel = 10 })
    local tank = hero(b2, "war_prot", { { kind = "share", pct = 0.3 } }, {}, 0)
    local mate = hero(b2, "pri_holy", nil, {}, -40)
    local m2 = mob(b2)
    local mateHp = mate.hp
    b2:receive(m2, tank, 100, "Fire", { noAvoid = true })
    T.ok(mate.hp < mateHp, "다른 파티원이 일부를 받는다")
    -- 막기 감소, 저항 통일
    local b3 = Battle.new({ seed = 1, stageLevel = 10 })
    local w = hero(b3, "war_prot", { { kind = "blockReduce", pct = 0.75 }, { kind = "resist", rule = "unify" } }, {})
    T.eq(w.blockReduce, 0.75)
    w.static.flat.FireResistance = 60; w.static.flat.ColdResistance = 0; w:invalidate()
    local m3 = mob(b3)
    local d1 = b3:receive(m3, w, 100, "Cold", { noAvoid = true })
    local d2 = b3:receive(m3, w, 100, "Fire", { noAvoid = true })
    T.near(d1, d2, 1e-6, "냉기 저항 = 가장 높은 원소 저항(화염)")
end)

T.case("파티 이동: 멀리 있는 적에게는 가장 느린 파티원의 속도로, 고유 능력치로 가장 빠른 속도로", function()
    local function race(mods)
        local b = Battle.new({ seed = 1, stageLevel = 10 })
        local fast = hero(b, "war_arms", mods, {}, 0)
        local slow = hero(b, "mag_fire", nil, {}, -40)
        fast.rank, slow.rank = 1, 2
        mob(b, 3000)
        b:run(1)
        return fast.x, fast:get("MovementSpeed"), slow:get("MovementSpeed")
    end
    local x, msFast, msSlow = race(nil)
    T.ok(msFast > msSlow, "전사가 마법사보다 빠르다")
    T.near(x, msSlow * 0.25 * 1, 2, "가장 느린 파티원의 속도로 간다 [원작]")
    local x2 = race({ { kind = "pace", rule = "fastest" } })
    T.near(x2, msFast * 0.25 * 1, 2, "가장 빠른 파티원의 속도로")
end)

T.case("장비를 끼면 영웅에게 고유 능력치가 들어간다(능력치형은 장비 시트로)", function()
    local s = Game.new("Horde", "war_prot", 0)
    local found
    for id, mod in pairs(Uniques.byItem) do
        if mod.kind == "stat" and mod.stat[1] == "MaxHp" and mod.stat[2] == 1 and Items.byId[id].slot == "ARMOR" then found = Items.byId[id] end
    end
    T.ok(found, "최대 체력 고정 고유 능력치 갑옷")
    local before = HeroBuild.makeUnit("war_prot", { gear = Inventory.gearSheet(s, "war_prot") }):get("MaxHp")
    s.heroes.war_prot.gear.ARMOR = { id = found.id }
    local after = HeroBuild.makeUnit("war_prot", { gear = Inventory.gearSheet(s, "war_prot") }):get("MaxHp")
    local base = 0
    for _, m in ipairs(found.mods) do if m[1] == "MaxHp" and m[2] == 1 then base = base + m[3] end end
    T.near(after - before, base + found.unique.stat[3], 1e-6, "고유 능력치의 최대 체력이 더해진다")
    -- 스킬형은 전투 유닛에
    local entry = Game.heroEntry(s, "war_prot")
    T.eq(#entry.uniques, 1)
end)

T.case("고유 장비 전부: 쓸 수 있는 영웅이 실제로 끼고(장비 시트·전투 유닛) 싸워도 오류가 없다", function()
    local n = 0
    for id in pairs(Uniques.byItem) do
        local item = Items.byId[id]
        for _, h in ipairs(Heroes.list) do
            if Items.usableBy(item, h.id) then
                local s = Game.new("Horde", h.id, 0)
                s.heroes[h.id].gear[item.slot] = { id = id }
                local entry = Game.heroEntry(s, h.id)
                local b = Battle.new({ seed = 2, stageLevel = 30 })
                local list = {}
                for i = 1, 4 do list[i] = { h.skills[i], 3 } end
                local u = HeroBuild.spawn(b, h.id, { skills = list, gear = entry.gear, uniques = entry.uniques, rank = 1, x = 0 })
                Uniques.installParty(b, { u })
                for i = 1, 3 do mob(b, 300 + i * 40, 3000, 3) end
                b:run(8)
                n = n + 1
                break
            end
        end
    end
    T.ok(n >= 150, "끼워 본 장비 수: " .. n)
end)

if not T.report("test_uniques") then os.exit(1) end
