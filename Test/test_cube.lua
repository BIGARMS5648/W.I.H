-- 큐브 검사. 실행: lua5.1 Test/test_cube.lua

package.path = "./?.lua;" .. package.path
local T = require("Test.t")
local WIH = require("Test.engine").load()
local Cube, CubeTable, Items, Inventory, Materials, Game, Rng, Stats, Save = WIH.Cube, WIH.CubeTable, WIH.Items, WIH.Inventory,
    WIH.Materials, WIH.Game, WIH.Rng, WIH.Stats, WIH.Save

local function newState()
    local s = Game.new("Horde", "war_prot", 0)
    s.inventory.bought = 240
    s.gold = 1e9
    return s
end

T.case("큐브 표: 레벨 경험치, 레시피, 결과 표가 모두 실제 아이템·재료를 가리킨다", function()
    T.eq(#CubeTable.LEVEL_EXP, 99)
    T.eq(CubeTable.LEVEL_EXP[1], 15); T.eq(CubeTable.LEVEL_EXP[99], 10511250)      -- [원작]
    local sum = 0
    for i = 1, 19 do sum = sum + CubeTable.LEVEL_EXP[i] end
    T.eq(sum, 106055, "Lv20까지 누적 경험치 [원작 검산값]")
    for id, entries in pairs(CubeTable.tables) do
        for _, e in ipairs(entries) do
            if e[2] == "MAT" then
                T.ok(Materials.defs[e[3]], "표 " .. id .. ": 없는 재료 " .. e[3])
            elseif e[2] == "MAIN" or e[2] == "SUB" then
                T.ok(Items.find("SWORD", e[3], e[4]) or Items.find("SHIELD", e[3], e[4]), "표 " .. id .. ": 무기 레벨 " .. e[3] .. " 등급 " .. e[4])
            else
                local typeId = ({ HELMET = "HELMET", ARMOR = "ARMOR", GLOVES = "GLOVES", BOOTS = "BOOTS", AMULET = "AMULET", EARRING = "EARRING", RING = "RING", BRACER = "BRACER" })[e[2]]
                T.ok(Items.find(typeId, e[3], e[4]), string.format("표 %d: %s 레벨 %d 등급 %d", id, e[2], e[3], e[4]))
            end
        end
    end
    for id, mods in pairs(CubeTable.MODS) do
        for group, list in pairs(mods) do
            for _, c in ipairs(list) do T.ok(Stats.defs[c[1]], "재료 " .. id .. ": 알 수 없는 능력치 " .. c[1]) end
        end
    end
    for id, def in pairs(Materials.defs) do T.ok(def.name and def.icon, "재료 " .. id .. "의 이름") end
    -- 합성 등급 확률 [원작 + 1.3.0 변경]
    local odds = Cube.gradeOdds(5)
    T.near(odds[2][2], 0.8, 1e-3, "불멸 → 아르카나 80%")
    T.near(Cube.gradeOdds(6)[2][2], 0.5, 1e-3, "아르카나 → 초월 50%")
    T.near(Cube.gradeOdds(1)[1][2], 100000 / 105000, 1e-9, "일반은 실패 없이 한 등급 위 95.2%")
    T.eq(Cube.gradeOdds(10), nil, "우주는 합성 불가")
end)

T.case("큐브 경험치: 레벨 근접도와 레벨업 [원작 식]", function()
    -- 큐브 Lv20일 때: 아이템 Lv20 100%, Lv15 약 88%, Lv30 80%, Lv1 0.08% [조사 보고서의 검산값]
    T.near(Cube.levelMatch(20, 20), 1, 1e-9)
    T.near(Cube.levelMatch(20, 15), 0.88, 0.01)
    T.near(Cube.levelMatch(20, 30), 0.80, 0.01)
    T.ok(Cube.levelMatch(20, 1) < 0.002)
    local s = newState()
    T.eq(s.cube.level, 1)
    T.eq(Cube.addExp(s, 15 + 40), 2)
    T.eq(s.cube.level, 3)
end)

T.case("레시피 해금: 큐브 레벨과 비용", function()
    local s = newState()
    local craft = Cube.find("CRAFTING", 1)
    local ok, why = Cube.unlock(s, craft)
    T.ok(not ok and why:find("큐브 레벨"), tostring(why))
    s.cube.level = 5
    T.ok(Cube.unlock(s, craft))
    T.eq(s.gold, 1e9 - 100)
    T.ok(Cube.unlocked(s, craft))
    T.ok(Cube.unlocked(s, Cube.find("ALCHEMY")), "연금술은 처음부터 열림")
    T.ok(Cube.unlocked(s, Cube.find("SYNTHESIS", 1)), "합성 1단계는 처음부터 열림")
    s.cube.level = 20
    T.ok(Cube.unlock(s, Cube.find("OFFERING")))
    for _, r in ipairs(Cube.recipes) do if r.kind == "OFFERING" then T.ok(Cube.unlocked(s, r), "기원은 한 번에 모두 열림") end end
end)

T.case("합성: 같은 등급 9개 → 무작위 1개, 등급은 내려가지 않고 레벨은 단계의 범위 안", function()
    local s = newState()
    local rng = Rng.new(3)
    local up, total = 0, 0
    for _ = 1, 200 do
        s.inventory.items = {}
        for i = 1, 9 do Inventory.add(s, Items.find(i % 2 == 0 and "SWORD" or "HELMET", 1, 1).id) end
        local idx = {}
        for i = 1, 9 do idx[i] = i end
        local r = Cube.synthesize(s, 1, idx, rng)
        T.ok(r and r.item, "결과가 장비")
        T.ok(r.item.grade >= 2, "일반 9개는 실패하지 않음")
        T.ok(r.item.level <= 1, "평균 레벨 1이면 결과도 레벨 1")
        T.ok(Cube.GEAR_GROUP[r.item.slot] ~= "ACCESSORY", "장비 합성에서 장신구는 나오지 않음")
        T.eq(#s.inventory.items, 1)
        if r.item.grade == 3 then up = up + 1 end
        total = total + 1
    end
    T.ok(up > 0 and up < 30, "대성공(두 등급 위)은 드물게: " .. up)
    -- 규칙 위반
    s.inventory.items = {}
    for i = 1, 8 do Inventory.add(s, Items.find("SWORD", 1, 1).id) end
    Inventory.add(s, Items.find("SWORD", 1, 2).id)
    local idx = {}
    for i = 1, 9 do idx[i] = i end
    local ok, why = Cube.synthesize(s, 1, idx, rng)
    T.ok(not ok and why:find("같은 등급"))
    s.inventory.items[9] = { id = Items.find("RING", 1, 1 + 1).id }
    for i = 1, 8 do s.inventory.items[i] = { id = Items.find("SWORD", 1, 2).id } end
    ok, why = Cube.synthesize(s, 1, idx, rng)
    T.ok(not ok and why:find("장신구"))
    ok, why = Cube.synthesize(s, 2, idx, rng)
    T.ok(not ok and why:find("열리지"), "열리지 않은 단계")
    T.ok(s.cube.exp > 0 or s.cube.level > 1, "합성은 큐브 경험치를 줌")
end)

T.case("재료 합성과 제작", function()
    local s = newState()
    local rng = Rng.new(9)
    s.materials[140001], s.materials[140002] = 5, 4
    local r = Cube.synthesizeMaterials(s, { { 140001, 5 }, { 140002, 4 } }, rng)
    T.ok(r and r.material, "결과가 재료")
    T.ok(Materials.defs[r.material].grade >= 2, "한 등급 위")
    T.eq(s.materials[140001], nil); T.eq(s.materials[140002], nil)
    -- 제작
    local ok, why = Cube.craft(s, "MAIN", 1, rng)
    T.ok(not ok and why:find("열리지"))
    s.cube.level = 5
    Cube.unlock(s, Cube.find("CRAFTING", 1))
    ok, why = Cube.craft(s, "MAIN", 1, rng)
    T.ok(not ok and why:find("모자"), tostring(why))
    local need = Cube.craftCost("MAIN", 1)
    for _, m in ipairs(need) do s.materials[m[1]] = m[2] * 30 end
    local grades = {}
    for _ = 1, 30 do
        local res = Cube.craft(s, "MAIN", 1, rng)
        T.ok(res and res.item and res.item.slot == "MAIN" and res.item.level <= 10, "1단계 제작: 레벨 1~10 주무기")
        T.eq(res.item.type, "SWORD", "보유한 영웅의 무기 종류만")
        grades[res.item.grade] = true
    end
    T.ok(not grades[1], "제작으로는 일반 등급이 나오지 않음 [원작]")
end)

T.case("장식·세공·각인과 제거: 등급별 칸 수, 능력치가 전투 시트에 들어간다", function()
    local s = newState()
    local rng = Rng.new(5)
    s.cube.level = 30
    for _, k in ipairs({ "DECORATION", "ENGRAVING", "INSCRIPTION", "EXTRACTION" }) do T.ok(Cube.unlock(s, Cube.find(k))) end
    Inventory.add(s, Items.find("SWORD", 30, 6).id)           -- 아르카나: 장식 2, 세공 1, 각인 1
    local entry = s.inventory.items[1]
    s.materials[110001], s.materials[120001], s.materials[130001] = 5, 5, 5
    T.ok(Cube.attach(s, entry, 110001, rng)); T.ok(Cube.attach(s, entry, 110001, rng))
    local ok, why = Cube.attach(s, entry, 110001, rng)
    T.ok(not ok and why:find("칸"), "장식 칸은 2개")
    T.ok(Cube.attach(s, entry, 120001, rng))
    T.ok(not Cube.attach(s, entry, 120001, rng), "세공 칸은 1개")
    local line = Cube.attach(s, entry, 130001, rng)
    T.ok(line and Stats.defs[line.stat])
    T.eq(#entry.added, 4)
    T.eq(s.materials[110001], 3)
    -- 일반 등급 장비에는 칸이 없다
    Inventory.add(s, Items.find("SWORD", 1, 1).id)
    ok = Cube.attach(s, s.inventory.items[2], 110001, rng)
    T.ok(not ok)
    -- 전투 시트에 들어간다
    Inventory.equip(s, "war_prot", 1)
    local sheet = Inventory.gearSheet(s, "war_prot")
    local u = WIH.HeroBuild.makeUnit("war_prot", { gear = sheet })
    local first = entry.added[1]
    local plain = WIH.HeroBuild.makeUnit("war_prot", { gear = (function() local sh = WIH.Sheet.new(); for _, m in ipairs(Items.byId[entry.id].mods) do WIH.Sheet.add(sh, m[1], m[2], m[3]) end; return sh end)() })
    T.ok(u:get(first.stat) ~= plain:get(first.stat) or first.value == 0, "붙인 능력치가 반영됨: " .. first.stat)
    -- 제거: 비용을 내고 지운다
    local gold = s.gold
    local cost = Cube.extractCost(entry.added[1])
    T.ok(Cube.extract(s, entry, 1))
    T.eq(s.gold, gold - cost)
    T.eq(#entry.added, 3)
    -- 저장 검증: 망가진 줄은 지운다
    entry.added[#entry.added + 1] = { kind = "NOPE", stat = "AttackDamage", value = 1 }
    local state = Save.load(Save.deepCopy(s))
    T.eq(#state.heroes.war_prot.gear.MAIN.added, 3)
end)

T.case("기원: 주화와 수수료로 무작위 아이템", function()
    local s = newState()
    local rng = Rng.new(11)
    s.cube.level = 20
    Cube.unlock(s, Cube.find("OFFERING"))
    s.materials[160005] = 20
    local gold = s.gold
    local got = 0
    for _ = 1, 20 do
        local r = Cube.offering(s, 160005, rng)
        T.ok(r and (r.item or r.material))
        got = got + 1
    end
    T.eq(s.materials[160005], nil)
    T.eq(s.gold, gold - 410 * 20, "불멸 주화 수수료 410 [원작]")
    T.ok(not Cube.offering(s, 160005, rng), "주화가 없으면 안 됨")
end)

T.case("연금술: 골드와 큐브 경험치, 높은 레벨 장비 제한", function()
    local s = newState()
    Inventory.add(s, Items.find("SWORD", 1, 2).id)
    Inventory.add(s, Items.find("SWORD", 30, 2).id)
    local gold, n, ups, skipped = Cube.alchemy(s, { 1, 2 })
    T.eq(n, 1); T.eq(skipped, 1, "큐브 Lv1에서 레벨 30 장비는 연금술 불가(21레벨 초과)")
    T.eq(gold, 30)
    T.ok(s.cube.exp > 0 or s.cube.level > 1)
    local g2 = Cube.alchemyMaterial(s, 140001, 1)
    T.ok(not g2, "없는 재료")
    s.materials[140001] = 3
    local g3 = Cube.alchemyMaterial(s, 140001)
    T.eq(g3, 10 * 12 * 3, "재료 연금술: 등급 기본 골드 × 12 [원작]")
end)

if not T.report("test_cube") then os.exit(1) end
