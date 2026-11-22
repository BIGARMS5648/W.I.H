-- 진행 시뮬레이션(검사 묶음에는 들어가지 않는다): 단순한 규칙으로 플레이했을 때 시간에 따라 어디까지 가는지 본다.
-- 규칙: 상자는 바로 열고, 칸마다 (레벨, 등급)이 가장 높은 장비를 끼고 나머지는 판다. 스킬 포인트는 첫 액티브 둘을 1레벨씩 배운 뒤
--       패시브를 앞에서부터 채운다. 룬은 효과가 있는 것 중 가장 싼 것부터 산다. 편성 칸이 비면 영웅을 해금해 채운다.
--       전멸이 이어지면 이전 던전으로 내려가 반복하고, 레벨이 오르면 다시 올라간다. 증표가 있으면 레이드에 도전한다.
-- 사용: lua5.1 Test/sim_progress.lua [분=120] [첫 영웅=war_prot] [씨앗=11]

package.path = "./?.lua;" .. package.path
local W = require("Test.engine").load()
local Game, Session, Heroes, Runes, RuneData = W.Game, W.Session, W.Heroes, W.Runes, W.RuneData
local Inventory, Chests, Items, Tables, Dungeons, Raids = W.Inventory, W.Chests, W.Items, W.Tables, W.Dungeons, W.Raids

local minutes = tonumber(arg[1]) or 120
local starter = arg[2] or "war_prot"
local seed = tonumber(arg[3]) or 11
-- 편성에 넣을 순서: 탱커, 힐러, 딜러 둘, 딜러
local RECRUIT = { "war_prot", "pri_holy", "mag_fire", "hun_mm", "rog_combat" }

local s = Game.new("Horde", starter, 0)
local sess = Session.new(s, { seed = seed })
local lootRng = W.Rng.new(seed + 1)
local recentFails, recentClears = 0, 0
sess:addListener(function(ev)
    if ev == "fail" then recentFails = recentFails + 1 end
    if ev == "clear" then recentClears = recentClears + 1 end
end)

local function invest()
    for id, h in pairs(s.heroes) do
        local hero = Heroes.byId[id]
        for _ = 1, 60 do
            if Game.freePoints(s, id) <= 0 then break end
            local done = false
            for i = 1, 2 do
                if not done and (h.active[hero.skills[i]] or 0) < 1 and Game.investActive(s, id, hero.skills[i]) then done = true end
            end
            for index = 1, 16 do
                if not done and Game.investPassive(s, id, index) then done = true end
            end
            if not done then break end
        end
        if #h.bar == 0 then
            local bar = {}
            for i = 1, 2 do if (h.active[hero.skills[i]] or 0) > 0 then bar[#bar + 1] = hero.skills[i] end end
            if #bar > 0 then Game.setBar(s, id, bar) end
        end
    end
end

local function buyRunes()
    for _ = 1, 30 do
        local best, bestCost
        for key, node in pairs(RuneData.nodes) do
            if Runes.canBuy(s, key) then
                local cost = Runes.nextCost(s, key)
                -- 편성 칸으로 가는 길목과 효과가 있는 룬만 산다.
                if (not Runes.INACTIVE[node.stat]) and (not bestCost or cost < bestCost) then best, bestCost = key, cost end
            end
        end
        if not best then return end
        Runes.buy(s, best)
    end
end

local function recruit()
    while #s.party < Game.partySlots(s) do
        local pick
        for _, id in ipairs(RECRUIT) do
            local inParty = false
            for _, p in ipairs(s.party) do if p == id then inParty = true end end
            if not inParty then pick = id; break end
        end
        if not pick then return end
        if not s.heroes[pick] and not Game.unlockHero(s, pick) then return end
        local list = {}
        for i, id in ipairs(s.party) do list[i] = id end
        list[#list + 1] = pick
        -- 탱커가 앞에 서게 정렬
        local order = { tank = 1, melee = 2, summoner = 3, ranged = 4, healer = 5 }
        table.sort(list, function(a, b) return (order[Heroes.byId[a].role] or 9) < (order[Heroes.byId[b].role] or 9) end)
        if not Game.setParty(s, list) then return end
    end
end

local function loot()
    for _, kind in ipairs(Chests.KINDS) do
        while Chests.count(s, kind) > 0 do Chests.open(s, kind, lootRng) end
    end
    local changed = true
    while changed do
        changed = false
        for _, heroId in ipairs(s.party) do
            for index, entry in ipairs(s.inventory.items) do
                local item = Items.byId[entry.id]
                if Items.usableBy(item, heroId) then
                    local cur = Inventory.equipped(s, heroId, item.slot)
                    if not cur or item.level * 100 + item.grade > cur.level * 100 + cur.grade then
                        Inventory.equip(s, heroId, index)
                        changed = true
                        break
                    end
                end
            end
        end
    end
    local all = {}
    for i = 1, Inventory.count(s) do all[i] = i end
    Inventory.alchemy(s, all)
end

-- 전멸이 이어지면 한 단계 내려가고, 클리어가 이어지면 가장 높이 열린 곳으로 올라간다.
local function chooseStage()
    if s.stage.raidKey then return end
    if recentFails >= 3 and recentClears == 0 then
        local prev = Game.previousStage(Game.currentStageKey(s))
        while prev and Tables.STAGES[prev].actBoss do prev = Game.previousStage(prev) end
        if prev then
            Game.selectStage(s, math.floor(prev / 1000), prev % 1000)
            s.settings.repeatMode = true
            sess:startStage()
        end
    elseif recentClears >= 3 and recentFails == 0 and s.settings.repeatMode then
        s.settings.repeatMode = false
    end
    recentFails, recentClears = 0, 0
    -- 레이드: 증표가 있고 열려 있으면 도전
    local d = s.stage.difficulty
    local act = math.floor(s.stage.section / 100)
    if Game.canStartRaid(s, d, act) and (s.stage.cleared[Raids.key(d, act)] or 0) == 0 then
        Game.startRaid(s, d, act)
        sess:startStage()
    end
end

io.write(string.format("첫 영웅 %s, %d분, 씨앗 %d\n", Heroes.byId[starter].name, minutes, seed))
io.write("  분 | 편성(레벨)                 | 골드    | 룬 | 클리어/전멸 | 연 상자 | 현재 위치\n")
for m = 1, minutes do
    for _ = 1, 60 do sess:advance(1, 40) end
    loot(); invest(); buyRunes(); recruit()
    if m % 3 == 0 then chooseStage() end
    if m % 10 == 0 or m == minutes then
        local runes = 0
        for _, lv in pairs(s.runes) do runes = runes + lv end
        local party = {}
        for _, id in ipairs(s.party) do party[#party + 1] = string.format("%s%d", Heroes.byId[id].name:sub(1, 6), s.heroes[id].level) end
        local where = Tables.DIFFICULTY_NAMES[s.stage.difficulty] .. " " .. math.floor(s.stage.section / 100) .. "-" .. (s.stage.section % 100)
            .. " " .. Dungeons.sections[s.stage.section].name
        io.write(string.format("%4d | %-26s | %7d | %2d | %4d / %-4d | %5d | %s\n", m, table.concat(party, " "), s.gold, runes,
            s.stats.clears, s.stats.fails, s.stats.chestsOpened or 0, where))
    end
end
