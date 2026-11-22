-- 전투력 계산과 모델 대응표 검사.
-- 실행: lua5.1 Test/test_power.lua

package.path = "./?.lua;" .. package.path
local T = require("Test.t")
local WIH = require("Test.engine").load()
local Power, Game, Heroes, Items, Inventory, Battle, Stats, HeroBuild, Models, Monsters, Tables, Runes = WIH.Power, WIH.Game, WIH.Heroes,
    WIH.Items, WIH.Inventory, WIH.Battle, WIH.Stats, WIH.HeroBuild, WIH.Models, WIH.Monsters, WIH.Tables, WIH.Runes

local function prepared(heroId, level)
    local s = Game.new("Horde", heroId, 0)
    local hero = Heroes.byId[heroId]
    s.heroes[heroId].level = level or 30
    Game.investActive(s, heroId, hero.skills[1])
    Game.investActive(s, heroId, hero.skills[2])
    Game.setBar(s, heroId, { hero.skills[1], hero.skills[2] })
    return s
end

T.case("방어도 식: 원작 식의 값과 상한", function()
    -- A² / (A² + (14L + 12)(A + 0.4D))
    T.near(Battle.armorReduction(100, 50, 10, true), 10000 / (10000 + 152 * 120), 1e-12)
    T.eq(Battle.armorReduction(0, 50, 10, true), 0)
    T.near(Battle.armorReduction(1e7, 10, 1, true), Stats.CAP_ARMOR_MELEE, 1e-12, "근접 상한 85%")
    T.near(Battle.armorReduction(1e7, 10, 1, false), Stats.CAP_ARMOR_RANGED, 1e-12, "원거리 상한 75%")
end)

T.case("전투력: 영웅 30명 모두 초당 피해가 나오고, 힐러는 초당 회복이 나온다", function()
    for _, hero in ipairs(Heroes.list) do
        local s = prepared(hero.id)
        local p = Power.measure(s, hero.id)
        T.ok(p.dps > 0, hero.name .. ": 초당 피해가 0")
        T.ok(p.ehp > 0 and p.ehp ~= math.huge, hero.name .. ": 유효 체력")
        T.near(p.power, p.dps * Power.WEIGHT_DPS + p.hps * Power.WEIGHT_HPS + p.ehp * Power.WEIGHT_EHP, 1e-9, "전투력 식")
        if hero.role == "healer" then T.ok(p.hps > 0, hero.name .. ": 힐러의 초당 회복이 0") end
    end
end)

T.case("전투력: 같은 상태면 같은 값(난수 고정), 장비와 스테이지에 따라 달라진다", function()
    local s = prepared("war_prot")
    local a, b = Power.measure(s, "war_prot"), Power.measure(s, "war_prot")
    T.eq(a.dps, b.dps); T.eq(a.ehp, b.ehp)
    -- 무기를 끼면 초당 피해가 오른다
    Inventory.add(s, Items.find("SWORD", 10, 3).id)
    Inventory.equip(s, "war_prot", 1)
    local withSword = Power.measure(s, "war_prot")
    T.ok(withSword.dps > a.dps * 2, string.format("무기 장착 뒤 초당 피해 %.2f → %.2f", a.dps, withSword.dps))
    -- 갑옷을 끼면 유효 체력이 오른다
    Inventory.add(s, Items.find("ARMOR", 10, 3).id)
    Inventory.equip(s, "war_prot", 1)
    local withArmor = Power.measure(s, "war_prot")
    T.ok(withArmor.ehp > withSword.ehp, "갑옷 장착 뒤 유효 체력이 오름")
    -- 기준 타격이 센 스테이지에서는 유효 체력이 다르게 나온다(같은 체력이라도 방어도의 효과가 달라진다)
    T.ok(Power.referenceHit(1309) > Power.referenceHit(1101))
    T.ok(Power.referenceHit(1110) == Tables.STAGES[1110].actBossFinal.atk, "레이드 자리의 기준 타격 = 액트 보스의 공격력")
    T.ok(Power.measure(s, "war_prot", 1309).ehp ~= withArmor.ehp)
end)

T.case("전투력: 상태가 바뀔 때만 다시 계산한다", function()
    local s = prepared("mag_fire")
    Power.clear()
    local a = Power.get(s, "mag_fire")
    T.eq(Power.get(s, "mag_fire"), a, "같은 상태면 저장해 둔 결과")
    s.heroes.mag_fire.level = 31
    local b = Power.get(s, "mag_fire")
    T.ok(b ~= a, "레벨이 바뀌면 다시 계산")
    Game.investPassive(s, "mag_fire", 1)
    T.ok(Power.get(s, "mag_fire") ~= b, "패시브가 바뀌면 다시 계산")
    local c = Power.get(s, "mag_fire")
    Inventory.add(s, Items.find("STAFF", 1, 1).id)
    Inventory.equip(s, "mag_fire", 1)
    T.ok(Power.get(s, "mag_fire") ~= c, "장비가 바뀌면 다시 계산")
    local d = Power.get(s, "mag_fire")
    s.gold = 1000; s.heroes.mag_fire.level = 31
    Runes.buy(s, 1)
    T.ok(Power.get(s, "mag_fire") ~= d, "룬이 바뀌면 다시 계산")
end)

T.case("유효 체력: 막기와 피해 감소가 반영되고, 전투의 식과 같은 값을 쓴다", function()
    local u = HeroBuild.makeUnit("war_prot", {})
    local hit = 50
    local expectedPerHit = hit * (1 - Battle.armorReduction(u:get("Armor"), hit, 5, true))
    local blocked = hit * 0.5 * (1 - Battle.armorReduction(u:get("Armor"), hit * 0.5, 5, true))
    local block = u:get("BlockChance")
    local want = u:get("MaxHp") * hit / ((1 - block) * expectedPerHit + block * blocked)
    T.near(Power.effectiveHp(u, 5, hit), want, 1e-6)
end)

T.case("모델 대응표: 영웅 30명과 보스 전원에 번호가 있고, 일반 몬스터는 유형별 대체가 있다", function()
    for _, hero in ipairs(Heroes.list) do
        for _, faction in ipairs({ "Alliance", "Horde" }) do
            local c = Models.heroCandidates(hero.id, faction)
            T.ok(#c >= 1 and type(c[1]) == "number", hero.name .. " " .. faction .. ": 모델 후보가 없음")
        end
    end
    T.eq(Models.heroCandidates("war_prot", "Horde")[1], Models.HEROES.war_prot[2], "진영에 맞는 번호가 첫 후보")
    T.eq(Models.heroCandidates("dru_feral", "Alliance", "bear")[1], Models.FORMS.bear, "형태가 있으면 형태의 모델이 첫 후보")
    local bosses, mobs = 0, 0
    for id, def in pairs(Monsters.defs) do
        local c = Models.candidates({ kind = "monster", def = def }, "Horde")
        T.ok(#c >= 1, def.name .. ": 모델 후보가 없음")
        if def.isBoss then
            bosses = bosses + 1
            T.ok(Models.MONSTERS[id], def.name .. ": 보스의 모델 번호가 없음")
        else
            mobs = mobs + 1
        end
    end
    T.eq(bosses, 168 + 37, "던전·레이드 168 + 원정·낙스라마스 37"); T.eq(mobs, 135 + 18)
    for id in pairs(Models.MONSTERS) do T.ok(Monsters.defs[id], "없는 몬스터 ID: " .. id) end
    -- 소환물: 주인의 직업에 따른 모델
    local owner = { def = Heroes.byId.hun_bm }
    T.eq(Models.candidates({ kind = "summon", owner = owner }, "Horde")[1], Models.SUMMONS.HUNTER)
end)

T.case("겉모습 대응표: 영웅 30명의 종족, 직업·단계별 옷, 무기 종류별 겉모습이 빠짐없이 있다", function()
    local Looks = WIH.Looks
    for _, hero in ipairs(Heroes.list) do
        local pair = Looks.RACE[hero.id]
        T.ok(pair and #pair == 2, hero.name .. ": 종족이 없음")
        for i = 1, 2 do
            T.ok(pair[i][1] >= 1 and pair[i][1] <= 11 and (pair[i][2] == 0 or pair[i][2] == 1), hero.name .. ": 종족·성별 값")
        end
        T.ok(Looks.ARMOR_CLASS[hero.class], hero.name .. ": 방어구 계열이 없음")
        for tier = 1, 6 do
            local set = Looks.set(hero.class, tier)
            T.ok(set and set.chest and set.legs and set.hands and set.feet, hero.name .. ": 단계 " .. tier .. "의 옷이 모자람")
        end
        T.ok(Looks.WEAPONS[hero.main] and #Looks.WEAPONS[hero.main] == 6, hero.name .. ": 주무기의 겉모습이 없음")
    end
    for level in pairs(Items.ALCHEMY_LEVEL) do T.ok(Looks.TIER[level], "아이템 레벨 " .. level .. "의 겉모습 단계가 없음") end
end)

T.case("겉모습: 낀 장비에 따라 달라지고, 형태가 있는 영웅은 형태의 모델을 쓴다", function()
    local Looks = WIH.Looks
    local s = Game.new("Alliance", "mag_fire", 0)
    local bare = Looks.forHero(s, "mag_fire")
    T.eq(bare.race, 1); T.eq(bare.sex, 0)
    T.eq(table.concat(bare.items, ","), "56,55", "맨몸이면 기본 옷(로브와 신발)")
    Inventory.add(s, Items.find("STAFF", 65, 4).id); Inventory.equip(s, "mag_fire", 1)
    local withStaff = Looks.forHero(s, "mag_fire")
    T.ok(withStaff.key ~= bare.key)
    T.eq(withStaff.items[#withStaff.items], Looks.WEAPONS.STAFF[5], "레벨 65 지팡이의 겉모습")
    Inventory.add(s, Items.find("ARMOR", 30, 2).id); Inventory.equip(s, "mag_fire", 1)
    local set = Looks.set("MAGE", 3)
    local dressed = Looks.forHero(s, "mag_fire")
    T.eq(dressed.items[1], set.chest); T.eq(dressed.items[2], set.shoulder); T.eq(dressed.items[3], set.legs)
    -- 투구·장갑·신발은 그 칸에 낀 것의 단계를 따른다
    Inventory.add(s, Items.find("HELMET", 90, 5).id); Inventory.equip(s, "mag_fire", 1)
    Inventory.add(s, Items.find("GLOVES", 50, 2).id); Inventory.equip(s, "mag_fire", 1)
    local full = Looks.forHero(s, "mag_fire")
    local has = {}
    for _, id in ipairs(full.items) do has[id] = true end
    T.ok(has[Looks.set("MAGE", 6).head], "레벨 90 투구의 겉모습")
    T.ok(has[Looks.set("MAGE", 4).hands], "레벨 50 장갑의 겉모습")
    -- 장신구와 보주는 겉모습에 나타나지 않는다
    local before = Looks.forHero(s, "mag_fire").key
    Inventory.add(s, Items.find("ORB", 50, 2).id); Inventory.equip(s, "mag_fire", 1)
    Inventory.add(s, Items.find("RING", 50, 2).id); Inventory.equip(s, "mag_fire", 1)
    T.eq(Looks.forHero(s, "mag_fire").key, before)
    -- 방패는 보이고, 보조 무기는 왼손에 든다
    local w = Game.new("Horde", "war_fury", 0)
    Inventory.add(w, Items.find("OFFHAND", 30, 2).id); Inventory.equip(w, "war_fury", 1)
    T.eq(Looks.forHero(w, "war_fury").offhand, Looks.WEAPONS.OFFHAND[3])
    T.eq(Looks.forHero(w, "war_fury").race, 8, "호드의 분노 전사는 트롤")
    -- 야성 드루이드는 형태의 모델
    local d = Game.new("Alliance", "dru_feral", 0)
    T.eq(Looks.forHero(d, "dru_feral"), nil)
    -- 해금하지 않은 영웅도 기본 옷차림을 볼 수 있다
    T.ok(Looks.forHero(s, "war_prot") ~= nil)
end)

if not T.report("test_power") then os.exit(1) end
