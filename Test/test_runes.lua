-- 룬 데이터와 규칙의 검증. 실행: lua5.1 Test/test_runes.lua

package.path = "./?.lua;" .. package.path
local T = require("Test.t")
local WIH = require("Test.engine").load()
local Runes, RuneData, Game, Session, Save = WIH.Runes, WIH.RuneData, WIH.Game, WIH.Session, WIH.Save

T.case("룬 표: 원작 197노드 + 추가 3노드, 조사 보고서의 합계와 일치", function()
    local n, custom, cost, levels = 0, 0, 0, 0
    local sum = {}
    for key, node in pairs(RuneData.nodes) do
        n = n + 1
        T.eq(#node.cost, node.max, "비용 수 = 최대 레벨: " .. key)
        T.eq(#node.value, node.max)
        T.ok(Runes.STATS[node.stat], "표시 이름이 없는 스탯: " .. node.stat)
        if node.custom then
            custom = custom + 1
        else
            for i = 1, node.max do
                cost = cost + node.cost[i]
                levels = levels + 1
                sum[node.stat] = (sum[node.stat] or 0) + node.value[i]
            end
        end
        if key ~= RuneData.ROOT then T.ok(node.parent and RuneData.nodes[node.parent], "부모가 없는 노드: " .. key) end
    end
    T.eq(n, 200); T.eq(custom, 3)
    T.eq(levels, 658, "총 레벨 수")
    T.eq(cost, 10040090050, "전 노드 총비용")
    T.eq(sum.AllHeroAttackDamage, 12)
    T.eq(sum.AllHeroArmor, 90)
    T.eq(sum.AllHeroAttackDamagePercent, 600)
    T.eq(sum.IncreaseGoldAmount, 1900)
    T.eq(sum.MaxInventorySlot, 84)
    T.eq(sum.UnlockArrangeSlotCount, 2)
    T.eq(sum.UnlockSkillSlotCount, 1)
    T.eq(sum.OfflineRewardGoldPercent, 2100)
    T.eq(RuneData.nodes[RuneData.ROOT].cost[1], 100, "시작 노드는 시작 골드 100으로 살 수 있다")
end)

T.case("모든 노드가 시작 노드에서 이어진다", function()
    local reached, queue = { [RuneData.ROOT] = true }, { RuneData.ROOT }
    while #queue > 0 do
        local key = table.remove(queue)
        for _, child in ipairs(Runes.children[key] or {}) do
            if not reached[child] then
                reached[child] = true
                queue[#queue + 1] = child
            end
        end
    end
    for key in pairs(RuneData.nodes) do T.ok(reached[key], "닿을 수 없는 노드: " .. key) end
end)

T.case("구매 규칙: 트리 해금, 선행 노드, 골드, 최대 레벨", function()
    local s = Game.new("Alliance", "war_prot")
    local ok, why = Runes.buy(s, 1)
    T.eq(ok, false, "영웅 레벨 3 전에는 잠김"); T.ok(why)
    s.heroes.war_prot.level = 3
    T.eq(Runes.buy(s, 20), false, "앞의 룬을 먼저")
    T.eq(Runes.buy(s, 1), true)
    T.eq(s.gold, 0)
    T.eq(Runes.buy(s, 1), false, "최대 레벨")
    T.eq(Runes.buy(s, 20), false, "골드 부족")
    T.eq(Runes.buy(s, 999999), false)
    s.gold = 1e9
    T.eq(Runes.buy(s, 20), true)
    T.eq(Game.partySlots(s), 1)
    T.eq(Runes.buy(s, 21), true)
    T.eq(Game.partySlots(s), 2, "지휘의 룬: 편성 2칸")
end)

T.case("편성 5칸과 스킬 4칸까지 룬으로 열린다", function()
    local s = Game.new("Alliance", "war_prot")
    s.heroes.war_prot.level = 3
    s.gold = 1e12
    -- 필요한 노드를 뿌리부터 차례로 산다.
    local function buyPath(key)
        local path = {}
        while key do
            table.insert(path, 1, key)
            key = RuneData.nodes[key].parent
        end
        for _, k in ipairs(path) do
            while Runes.level(s, k) < (k == path[#path] and RuneData.nodes[k].max or 1) do
                local ok, why = Runes.buy(s, k)
                T.ok(ok, "구매 실패 " .. k .. ": " .. tostring(why))
            end
        end
    end
    buyPath(90002)
    buyPath(90003)
    T.eq(Game.partySlots(s), 5)
    T.eq(Game.skillSlots(s), 4)
end)

T.case("전투 룬은 전 영웅에게 적용되고, 골드·경험치 룬은 보상에 반영된다", function()
    local function play(buyAll)
        local s = Game.new("Alliance", "war_fury")
        s.heroes.war_fury.level = 3
        if buyAll then
            s.gold = 1e13
            local changed = true
            while changed do
                changed = false
                for key in pairs(RuneData.nodes) do
                    if Runes.canBuy(s, key) then
                        Runes.buy(s, key)
                        changed = true
                    end
                end
            end
            s.gold = 0
        end
        local session = Session.new(s, { seed = 8 })
        local strong = WIH.Sheet.new()
        WIH.Sheet.add(strong, "MaxHp", WIH.Stats.FLAT, 50000)
        WIH.Sheet.add(strong, "AttackDamage", WIH.Stats.FLAT, 100)
        session.account = strong
        s.settings.repeatMode = true
        session:advance(0.1, 10)
        local hero = session.runner.heroes[1]
        local ad, armor = hero:get("AttackDamage"), hero:get("Armor")
        local kills0 = s.stats.kills
        for _ = 1, 60 do session:advance(1, 100000) end
        return ad, armor, s.gold, s.stats.kills - kills0, s.heroes.war_fury, session.runner.waves, s
    end
    local ad0, armor0, gold0, kills0, hero0, waves0 = play(false)
    local ad1, armor1, gold1, kills1, hero1, waves1, s1 = play(true)
    -- 공격력: (1 + 100 + 12) × 1.6, 방어도: (35 + 90) × 1.35
    T.near(ad0, 101, 1e-6)
    T.near(ad1, (1 + 100 + 12) * 1.6, 1e-6)
    T.near(armor0, 35, 1e-6)
    T.near(armor1, (35 + 90) * 1.35, 1e-6)
    T.eq(waves1, waves0 - 1, "단축의 룬: 웨이브 수 −1")
    T.ok(gold1 / math.max(kills1, 1) > gold0 / math.max(kills0, 1) * 2.5, "골드 룬이 처치당 골드를 늘려야 함")
    T.ok(hero1.level >= hero0.level, "경험치 룬")
    for key, level in pairs(s1.runes) do T.eq(level, RuneData.nodes[key].max, "전부 최대 레벨") end
end)

T.case("저장 검증: 없는 룬과 최대 레벨을 넘은 룬을 바로잡고 칸 수를 다시 계산한다", function()
    local s = Game.new("Alliance", "war_prot")
    s.runes = { [1] = 9, [424242] = 1, [20] = 1, [21] = 1 }
    s.unlocks.partySlots = 5
    local state, info = Save.load(s)
    T.eq(info.status, "fixed")
    T.eq(state.runes[1], 1, "최대 레벨로 고정")
    T.eq(state.runes[424242], nil)
    T.eq(Game.partySlots(state), 2, "칸 수는 룬에서 다시 계산")
end)

if not T.report("test_runes") then os.exit(1) end
