-- 아이템, 인벤토리·장비, 상자 검사.
-- 실행: lua5.1 Test/test_items.lua

package.path = "./?.lua;" .. package.path
local T = require("Test.t")
local WIH = require("Test.engine").load()
local Items, ItemTable, Inventory, Chests, ChestTable, Materials = WIH.Items, WIH.ItemTable, WIH.Inventory, WIH.Chests, WIH.ChestTable, WIH.Materials
local Heroes, Stats, Game, Runes, Rng, Save, HeroBuild, Session, Tables = WIH.Heroes, WIH.Stats, WIH.Game, WIH.Runes, WIH.Rng, WIH.Save,
    WIH.HeroBuild, WIH.Session, WIH.Tables

local function newState(heroId)
    return Game.new("Alliance", heroId or "war_prot", 0)
end

T.case("아이템 표: 모든 종류가 곡선의 모든 (레벨, 등급)을 갖고, 능력치가 엔진에 있는 것이다", function()
    local count = 0
    for _, typeId in ipairs(Items.TYPE_ORDER) do
        local t = Items.TYPES[typeId]
        local rows = ItemTable.curves[t.curve]
        T.ok(rows and #rows > 0, typeId .. ": 곡선이 비어 있음")
        local n = 0
        for _, byGrade in pairs(Items.byType[typeId]) do
            for _, variants in pairs(byGrade) do
                for _, item in pairs(variants) do
                    n = n + 1
                    T.eq(Items.byId[item.id], item)
                    T.eq(item.slot, t.slot)
                    T.ok(Items.TIER_NAMES[item.level], "레벨대 이름이 없음: " .. item.level)
                    T.ok(Items.ALCHEMY_LEVEL[item.level], "연금 계수가 없음: " .. item.level)
                    local seen = {}
                    for _, mod in ipairs(item.mods) do
                        T.ok(Stats.defs[mod[1]], typeId .. ": 알 수 없는 능력치 " .. tostring(mod[1]))
                        T.ok(mod[2] >= 1 and mod[2] <= 3, "연산 값이 잘못됨")
                        T.ok(type(mod[3]) == "number" and mod[3] >= 0, "값이 잘못됨")
                        if not mod.base then
                            local key = mod[1] .. ":" .. mod[2]
                            T.ok(not seen[key], typeId .. ": 같은 (능력치, 연산)이 두 번 붙음")       -- [원작 규칙]
                            seen[key] = true
                        end
                    end
                    -- 고정 능력치 줄 수는 등급이 정한 수를 넘지 않는다.
                    local fixed = 0
                    for _, mod in ipairs(item.mods) do if not mod.base then fixed = fixed + 1 end end
                    T.ok(fixed <= Items.GRADES[item.grade].fixed, Items.name(item) .. ": 고정 능력치가 등급 한도보다 많음")
                end
            end
        end
        T.eq(n, #rows, typeId .. ": 아이템 수가 곡선의 줄 수와 다름")
        count = count + n
    end
    T.eq(count, Items.count)
    T.eq(#Items.TYPE_ORDER, 33)
    T.ok(count > 2500, "아이템 수: " .. count)
end)

T.case("아이템 표: 원작 검산값과 일치한다", function()
    -- 한손검 레벨 1 일반: 공격력 +1, 공격속도 +0.20. 레벨 50 고급: 공격력 119, 공격속도 +0.40 [원작 v1.3.0]
    local a = Items.find("SWORD", 1, 1)
    T.eq(a.mods[1][1], "AttackDamage"); T.eq(a.mods[1][3], 1)
    T.eq(a.mods[2][1], "AttackSpeed"); T.eq(a.mods[2][3], 20)
    local b = Items.find("SWORD", 50, 2)
    T.eq(b.mods[1][3], 119); T.eq(b.mods[2][3], 40)
    T.eq(b.mods[3][1], "AttackDamage"); T.eq(b.mods[3][2], Stats.INC); T.eq(b.mods[3][3], 424)
    -- 갑옷 레벨 90 우주: 방어도 21,862 [조사 보고서 3.3절]
    T.eq(Items.find("ARMOR", 90, 10).mods[1][3], 21862)
    -- 장신구에는 일반 등급이 없고 기본 능력치도 없다.
    T.eq(Items.find("RING", 1, 1), nil)
    T.ok(not Items.find("RING", 1, 2).mods[1].base)
end)

T.case("무기 종류: 영웅 30명의 주무기·보조무기가 모두 표에 있고, 공격속도 가산이 설계값과 같다", function()
    for _, hero in ipairs(Heroes.list) do
        local main, sub = Items.TYPES[hero.main], Items.TYPES[hero.sub]
        T.ok(main and main.slot == "MAIN", hero.name .. ": 주무기 종류가 표에 없음 " .. tostring(hero.main))
        T.ok(sub and sub.slot == "SUB", hero.name .. ": 보조무기 종류가 표에 없음 " .. tostring(hero.sub))
        -- 고급~불멸 등급(레벨 50)의 공격속도 가산 = 설계 문서의 종류별 값
        local item = Items.find(hero.main, 50, 2)
        T.eq(item.mods[2][3], Heroes.MAIN_WEAPONS[hero.main].speed, hero.name .. "의 주무기 공격속도 가산")
        -- 보조무기의 기본 능력치가 설계 표와 같다
        local s = Items.find(hero.sub, 1, 1)
        T.eq(s.mods[1][1], Heroes.SUB_WEAPONS[hero.sub].stat, hero.name .. "의 보조무기 기본 능력치")
        T.eq(s.mods[1][2], Heroes.SUB_WEAPONS[hero.sub].kind)
        T.ok(Items.usableBy(item, hero.id) and Items.usableBy(s, hero.id))
    end
    T.ok(not Items.usableBy(Items.find("STAFF", 1, 1), "war_prot"), "전사는 지팡이를 못 낌")
    T.ok(Items.usableBy(Items.find("HELMET", 1, 1), "mag_fire"), "방어구는 누구나 낌")
end)

T.case("인벤토리: 얻기, 장착, 교체, 해제", function()
    local s = newState("war_prot")
    T.eq(Inventory.capacity(s), 20)
    local sword1, sword2, staff = Items.find("SWORD", 1, 1), Items.find("SWORD", 1, 2), Items.find("STAFF", 1, 1)
    T.eq(Inventory.add(s, sword1.id), "inventory")
    Inventory.add(s, staff.id)
    Inventory.add(s, sword2.id)
    T.eq(Inventory.count(s), 3)
    local ok, why = Inventory.equip(s, "war_prot", 2)
    T.ok(not ok and why, "쓸 수 없는 무기는 거절: " .. tostring(why))
    T.ok(Inventory.equip(s, "war_prot", 1))
    T.eq(s.heroes.war_prot.gear.MAIN.id, sword1.id)
    T.eq(Inventory.count(s), 2)
    -- 교체: 끼고 있던 것이 그 자리로 돌아온다
    T.ok(Inventory.equip(s, "war_prot", 2))
    T.eq(s.heroes.war_prot.gear.MAIN.id, sword2.id)
    T.eq(s.inventory.items[2].id, sword1.id)
    T.eq(Inventory.count(s), 2)
    T.ok(Inventory.unequip(s, "war_prot", "MAIN"))
    T.eq(s.heroes.war_prot.gear.MAIN, nil)
    T.eq(Inventory.count(s), 3)
    T.ok(not Inventory.unequip(s, "war_prot", "MAIN"))
end)

T.case("인벤토리: 가득 차면 임시 보관함으로 가고, 자리가 나면 돌아온다", function()
    local s = newState("war_prot")
    local helmet = Items.find("HELMET", 1, 1)
    for _ = 1, 20 do T.eq(Inventory.add(s, helmet.id), "inventory") end
    T.eq(Inventory.add(s, helmet.id), "mail")
    T.eq(#s.mail, 1)
    T.ok(not Inventory.unequip(s, "war_prot", "HELMET"))
    -- 칸을 사면 임시 보관함의 것이 들어온다 [원작 비용: 21번째 칸 50골드]
    T.eq(Inventory.nextSlotCost(s), 50)
    s.gold = 49
    T.ok(not Inventory.buySlot(s))
    s.gold = 50
    T.ok(Inventory.buySlot(s))
    T.eq(s.gold, 0)
    T.eq(Inventory.capacity(s), 21)
    T.eq(#s.mail, 0)
    T.eq(Inventory.count(s), 21)
    -- 비용 계단 [원작]
    s.inventory.bought = 3;  T.eq(Inventory.nextSlotCost(s), 100)
    s.inventory.bought = 98; T.eq(Inventory.nextSlotCost(s), 10240000)
    s.inventory.bought = 240; T.eq(Inventory.nextSlotCost(s), nil)
end)

T.case("연금술: 골드 = 등급 기본 골드 × 레벨 계수 × 종류 계수, 잠근 아이템은 건너뛴다", function()
    local s = newState("war_prot")
    T.eq(Inventory.alchemyValue(s, Items.find("SWORD", 1, 1)), 10)
    T.eq(Inventory.alchemyValue(s, Items.find("SHIELD", 1, 2)), 60)          -- 30 × 1 × 2
    T.eq(Inventory.alchemyValue(s, Items.find("BOOTS", 5, 3)), 315)          -- 90 × 5 × 0.7
    T.eq(Inventory.alchemyValue(s, Items.find("AMULET", 90, 10)), math.floor(355607 * 1227 * 4 + 0.5))
    Inventory.add(s, Items.find("SWORD", 1, 1).id)
    Inventory.add(s, Items.find("SHIELD", 1, 2).id)
    Inventory.add(s, Items.find("BOOTS", 5, 3).id)
    Inventory.setLock(s, 2, true)
    local gold0 = s.gold
    local gold, n = Inventory.alchemy(s, { 1, 2, 3 })
    T.eq(n, 2); T.eq(gold, 325); T.eq(s.gold, gold0 + 325)
    T.eq(Inventory.count(s), 1)
    T.eq(s.inventory.items[1].lock, true)
end)

T.case("장비 능력치: 낀 장비가 전투 유닛의 능력치에 그대로 들어간다", function()
    local s = newState("war_prot")
    local bare = HeroBuild.makeUnit("war_prot", { gear = Inventory.gearSheet(s, "war_prot") })
    T.near(bare:get("AttackDamage"), 2, 1e-9)
    T.near(bare:get("AttackSpeed"), 0.80, 1e-9, "무기가 없으면 영웅 기본 공격속도만")
    Inventory.add(s, Items.find("SWORD", 1, 1).id)
    Inventory.equip(s, "war_prot", 1)
    Inventory.add(s, Items.find("SHIELD", 1, 1).id)
    Inventory.equip(s, "war_prot", 1)
    local u = HeroBuild.makeUnit("war_prot", { gear = Inventory.gearSheet(s, "war_prot") })
    T.near(u:get("AttackDamage"), 3, 1e-9)
    T.near(u:get("AttackSpeed"), 1.00, 1e-9)
    T.ok(u:get("BlockChance") > bare:get("BlockChance"), "방패의 막기 확률이 더해짐")
    -- 편성에 실리는 값도 같다
    local party = Game.buildParty(s)
    T.ok(party[1].gear ~= nil)
    local sess = Session.new(s, { seed = 3 })
    local hero = sess:startStage().heroes[1]
    T.near(hero:get("AttackDamage"), 3, 1e-9)
end)

T.case("상자 표: 가중치 합이 맞고, 모든 묶음이 어느 종류로도 실제 아이템이 된다", function()
    local partTypes = {}
    for _, typeId in ipairs(Items.TYPE_ORDER) do
        local slot = Items.TYPES[typeId].slot
        partTypes[slot] = partTypes[slot] or {}
        table.insert(partTypes[slot], typeId)
    end
    local n = 0
    for id, entries in pairs(ChestTable.tables) do
        local total = 0
        for _, e in ipairs(entries) do
            total = total + e[1]
            if e[2] == "MAT" then
                T.ok(Materials.defs[e[3]], "없는 재료: " .. tostring(e[3]))
            else
                for _, typeId in ipairs(partTypes[e[2]]) do
                    T.ok(Items.find(typeId, e[3], e[4]), string.format("표 %d: %s 레벨 %d 등급 %d 아이템이 없음", id, typeId, e[3], e[4]))
                end
            end
        end
        T.ok(math.abs(total - 1000000) < 200, "표 " .. id .. "의 가중치 합: " .. total)
        n = n + 1
    end
    T.eq(n, 42 + #WIH.ExpeditionTable.tables, "던전·레이드 42개 + 원정·낙스라마스")
    -- 던전 스테이지 108개에 일반·스테이지 상자 표와 충전 시간이 있다
    local stages = 0
    for key, st in pairs(Tables.STAGES) do
        local info = ChestTable.STAGE[key]
        T.ok(info, "스테이지 " .. key .. "의 상자 정보가 없음")
        if not st.actBoss then
            T.ok(ChestTable.tables[info.normal] and ChestTable.tables[info.boss] and info.cool > 0 and info.bossCool > 0)
            if not st.expedition then stages = stages + 1 end
        else
            T.ok(ChestTable.tables[info.raid])
        end
    end
    T.eq(stages, 108)
    T.eq(ChestTable.STAGE[1101].cool, 2); T.eq(ChestTable.STAGE[1209].bossCool, 5)      -- [원작]
end)

T.case("상자 개봉: 보유한 영웅이 쓰는 무기만 나오고, 부위 비율이 원작과 같다", function()
    local s = newState("war_prot")
    Game.addGold(s, 1000)
    Game.unlockHero(s, "mag_fire")
    s.inventory.bought = 240
    local rng = Rng.new(99)
    local counts, total = {}, 30000
    local tableId = ChestTable.STAGE[1101].normal
    for _ = 1, total do
        local r = Chests.roll(s, tableId, rng)
        T.ok(r and (r.item or r.material), "뽑기 결과가 없음")
        if r.item then
            counts[r.item.slot] = (counts[r.item.slot] or 0) + 1
            if r.item.slot == "MAIN" then T.ok(r.item.type == "SWORD" or r.item.type == "STAFF", "보유하지 않은 영웅의 무기: " .. r.item.type) end
            if r.item.slot == "SUB" then T.ok(r.item.type == "SHIELD" or r.item.type == "ORB", "보유하지 않은 영웅의 보조무기: " .. r.item.type) end
            T.eq(r.item.level, 1, "일반 1-1의 상자는 레벨 1 장비만")
        else
            counts.MAT = (counts.MAT or 0) + 1
        end
    end
    T.near(counts.MAIN / total, 0.4133, 0.012, "주무기 비율")        -- [원작 집계: 41.33%]
    T.near(counts.SUB / total, 0.0591, 0.006, "보조무기 비율")       -- 5.906%
    T.near((counts.HELMET + counts.ARMOR + counts.GLOVES + counts.BOOTS) / total, 0.4976, 0.012, "방어구 비율")   -- 49.76%
    T.near(counts.MAT / total, 0.03, 0.005, "재료 비율")
end)

T.case("상자 드롭: 확률, 획득 허용량, 보관 한도", function()
    local s = newState("war_prot")
    T.near(Chests.dropChance(s, "normal", 1101), 0.16, 1e-9)        -- [원작] 일반 1-1: 16%
    T.near(Chests.dropChance(s, "stage", 1101), 1.0, 1e-9)
    T.near(Chests.dropChance(s, "normal", 4309), 0.008, 1e-9)
    T.eq(Chests.cap(s, "normal"), 5)
    local rng = Rng.new(5)
    -- 스테이지 상자는 100%지만 허용량이 1뿐이라 연달아 두 개는 못 받는다.
    T.ok(Chests.tryDrop(s, "stage", 1101, rng))
    local ok, why = Chests.tryDrop(s, "stage", 1101, rng)
    T.ok(not ok); T.eq(why, "allowance")
    -- 2분이 지나면 허용량 1이 찬다(1-1의 충전 시간 2분).
    Chests.tick(s, 119, 1101, rng)
    T.ok(not Chests.tryDrop(s, "stage", 1101, rng))
    Chests.tick(s, 2, 1101, rng)
    T.ok(Chests.tryDrop(s, "stage", 1101, rng))
    T.eq(Chests.count(s, "stage"), 2)
    -- 허용량은 2까지만 쌓인다.
    Chests.tick(s, 3600, 1101, rng)
    T.near(s.chests.stage.allowance, 2, 1e-9)
    -- 보관 한도: 5개가 차면 더 받지 못하고 허용량은 그대로다.
    s.chests.stage.list = { 2, 2, 2, 2, 2 }
    ok, why = Chests.tryDrop(s, "stage", 1101, rng)
    T.ok(not ok); T.eq(why, "full")
    T.near(s.chests.stage.allowance, 2, 1e-9)
    -- 열면 아이템이 인벤토리로 온다.
    local before = Inventory.count(s)
    local result = Chests.open(s, "stage", rng)
    T.ok(result and (result.item or result.material))
    T.eq(Chests.count(s, "stage"), 4)
    if result.item then T.eq(Inventory.count(s), before + 1) else T.eq(s.materials[result.material], 1) end
    T.ok(not Chests.open(s, "normal", rng), "빈 보관함은 열 수 없음")
end)

T.case("상자 룬: 보관 한도, 드롭 확률, 자동 개봉이 실제로 적용된다", function()
    local s = newState("war_prot")
    local rng = Rng.new(7)
    T.eq(Chests.autoOpenTime(s, "normal"), nil, "룬이 없으면 자동 개봉이 없음")
    T.ok(not Chests.canOpenAll(s))
    -- 룬 표에서 해당 스탯의 노드를 찾아 직접 올린다(선행 조건은 이 시험의 관심사가 아니다).
    local function give(stat, levels)
        for key, node in pairs(WIH.RuneData.nodes) do
            if node.stat == stat then
                s.runes[key] = math.min(node.max, levels or node.max)
                return node
            end
        end
        error("룬이 없음: " .. stat)
    end
    give("MaxAmountNormalChest")
    T.ok(Chests.cap(s, "normal") > 5, "보관 한도 룬")
    give("DropChanceNormalChestPercent")
    T.ok(Chests.dropChance(s, "normal", 1101) > 0.16, "드롭 확률 룬")
    local node = give("UnlockAutoOpenNormalChest")
    T.eq(Chests.autoOpenTime(s, "normal"), node.value[1])
    T.eq(node.value[1], 300)        -- [원작] 일반 상자 자동 개봉 300초
    give("OpenOneTypeChestAllAtOnce")
    T.ok(Chests.canOpenAll(s))
    -- 자동 개봉: 300초가 지나면 하나가 열린다.
    s.chests.normal.list = { 1, 1 }
    local opened = 0
    Chests.tick(s, 299, 1101, rng, function() opened = opened + 1 end)
    T.eq(opened, 0)
    Chests.tick(s, 1, 1101, rng, function() opened = opened + 1 end)
    T.eq(opened, 1)
    T.eq(Chests.count(s, "normal"), 1)
    for stat in pairs({ MaxAmountNormalChest = 1, DropChanceNormalChestPercent = 1, UnlockAutoOpenNormalChest = 1, MaxInventorySlot = 1,
        CubeAlchemyGoldPercent = 1, OpenOneTypeChestAllAtOnce = 1 }) do
        T.eq(Runes.INACTIVE[stat], nil, stat .. ": 이제 쓰이므로 미적용 표에 없어야 함")
    end
end)

T.case("진행과의 연결: 첫 클리어 보상으로 시작 무기를 받고, 상자가 떨어진다", function()
    local s = newState("mag_fire")
    local events = { chest = 0, firstClear = 0 }
    local sess = Session.new(s, { seed = 21 })
    sess:addListener(function(ev, a)
        if ev == "chest" then events.chest = events.chest + 1 end
        if ev == "firstClear" then events.firstClear = events.firstClear + 1; events.item = a[1] end
    end)
    local t = 0
    while t < 1200 and (s.stage.cleared[1101] or 0) < 2 do sess:advance(1, 40); t = t + 1 end
    T.ok((s.stage.cleared[1101] or 0) >= 1, "1-1을 클리어함")
    T.eq(events.firstClear, 1, "첫 클리어 보상은 한 번만")
    T.eq(events.item.type, "STAFF"); T.eq(events.item.level, 1); T.eq(events.item.grade, 1)
    T.ok(events.chest >= 1, "상자가 떨어짐")
    T.eq(events.chest, Chests.count(s, "normal") + Chests.count(s, "stage"))
    local found = false
    for _, entry in ipairs(s.inventory.items) do if entry.id == events.item.id then found = true end end
    T.ok(found, "시작 무기가 인벤토리에 있음")
end)

T.case("저장: 형식 1의 저장을 2로 올리고, 잘못된 장비·아이템을 고친다", function()
    local s = newState("war_prot")
    local old = Save.deepCopy(s)
    old.schema, old.inventory, old.mail, old.chests, old.materials = 1, nil, nil, nil, nil
    old.heroes.war_prot.gear = nil
    local state, info = Save.load(old)
    T.ok(state, "불러오기 성공")
    T.eq(state.schema, 2)
    T.eq(info.status, "fixed")
    T.ok(type(state.inventory.items) == "table" and type(state.heroes.war_prot.gear) == "table" and state.chests.normal)
    -- 잘못된 내용
    local bad = Save.deepCopy(s)
    bad.inventory.items = { { id = 123 }, { id = Items.find("HELMET", 1, 1).id }, "x" }
    bad.heroes.war_prot.gear = { MAIN = { id = Items.find("STAFF", 1, 1).id }, HELMET = { id = Items.find("HELMET", 5, 2).id } }
    bad.chests.normal.list = { 1, 9999 }
    bad.materials = { [140001] = 3, [5] = 1 }
    state, info = Save.load(bad)
    T.ok(state)
    T.eq(#state.inventory.items, 1)
    T.eq(state.heroes.war_prot.gear.MAIN, nil, "쓸 수 없는 무기는 벗김")
    T.eq(#state.mail, 1, "벗긴 장비는 버리지 않고 임시 보관함으로")
    T.ok(state.heroes.war_prot.gear.HELMET ~= nil)
    T.eq(#state.chests.normal.list, 1)
    T.eq(state.materials[140001], 3); T.eq(state.materials[5], nil)
    -- 고친 뒤 다시 불러오면 고칠 것이 없다
    local again, info2 = Save.load(Save.deepCopy(state))
    T.eq(info2.status, "ok", table.concat(info2.notes, " / "))
end)

T.case("창고: 41칸에서 시작, 칸 비용은 원작 표, 페이지는 룬으로, 가득 차면 거절, 검증", function()
    local s = newState()
    s.gold = 1e9
    T.eq(Inventory.stashCapacity(s), 41)
    T.eq(Inventory.stashPages(s), 1)
    T.eq(Inventory.nextStashSlotCost(s), 100)
    local total = 0
    while Inventory.nextStashSlotCost(s) do
        total = total + Inventory.nextStashSlotCost(s)
        T.ok(Inventory.buyStashSlot(s))
    end
    T.eq(total, 66510300, "131칸까지 합계 [원작]")
    T.eq(Inventory.stashCapacity(s), 131)
    s.stash.slots = 41
    local id = Items.find("HELMET", 1, 1).id
    for _ = 1, 42 do
        Inventory.add(s, id)
    end
    for i = 1, 41 do T.eq(Inventory.toStash(s, 1), 1) end
    T.ok(not Inventory.toStash(s, 1), "1쪽이 가득 차고 다른 페이지가 없으면 거절")
    for key, node in pairs(WIH.RuneData.nodes) do if node.stat == "UnlockStashPageCount" then s.runes[key] = node.max end end
    T.eq(Inventory.stashPages(s), 4)
    T.eq(Inventory.toStash(s, 1), 2, "자리가 있는 다음 페이지로")
    -- 가방이 가득 차면 꺼낼 수 없다
    for _ = 1, Inventory.free(s) do Inventory.add(s, id) end
    T.ok(not Inventory.fromStash(s, 1, 1))
    s.inventory.items = {}
    T.ok(Inventory.fromStash(s, 1, 1))
    T.eq(#s.stash.pages[1], 40)
    -- 망가진 항목은 지운다
    s.stash.pages[3] = { { id = -5 }, { id = id } }
    local notes = {}
    Inventory.validate(s, notes)
    T.eq(#s.stash.pages[3], 1)
end)

if not T.report("test_items") then os.exit(1) end
