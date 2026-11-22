-- 밸런스 점검(검사 묶음에는 들어가지 않는다): 정해 둔 지점마다 "그 레벨대의 영웅과 장비"로 스테이지를 여러 번 돌려
-- 클리어 시간과 전멸 비율을 잰다. 원작 오프라인 보상표의 시간당 클리어 수(ClearCount)와 비교한다.
-- 사용: lua5.1 Test/sim_points.lua [판 수=6] [장비 등급=3]

package.path = "./?.lua;" .. package.path
local W = require("Test.engine").load()
local Game, Session, Heroes, Items, Tables, Dungeons = W.Game, W.Session, W.Heroes, W.Items, W.Tables, W.Dungeons

local RUNS = tonumber(arg[1]) or 6
local GRADE = tonumber(arg[2]) or 3
local GEAR_LEVELS = { 1, 5, 10, 15, 20, 30, 40, 50, 65, 80, 90 }
local PARTY = { "war_prot", "pri_holy", "mag_fire", "hun_mm", "rog_combat" }

-- { 난이도, 구간, 편성 인원, 영웅 레벨 = 스테이지 레벨 + 차이, 장비 등급(없으면 인자), 종류 = nil | "raid" | "exp" | "naxx", 강도·액트 }
-- 대표 장비 등급 [독자]: 일반 희귀, 악몽 전설, 지옥 불멸, 고통 아르카나
local POINTS = {
    { 1, 103, 1, 0, 2 }, { 1, 108, 2, 0, 2 }, { 1, 205, 2, 0, 3 }, { 1, 205, 3, 0, 3 }, { 1, 305, 3, 0, 3 }, { 1, 305, 4, 0, 3 },
    { 1, 309, 5, 0, 3 }, { 2, 105, 5, 0, 4 }, { 2, 305, 5, 0, 4 }, { 3, 105, 5, 0, 5 }, { 3, 305, 5, 0, 5 }, { 4, 105, 5, 0, 6 }, { 4, 305, 5, 0, 6 },
    { 1, 110, 2, 0, 2, "raid", 1 }, { 1, 210, 3, 0, 3, "raid", 2 }, { 1, 310, 5, 0, 3, "raid", 3 },
    { 2, 310, 5, 0, 4, "raid", 3 }, { 3, 310, 5, 0, 5, "raid", 3 }, { 4, 310, 5, 0, 6, "raid", 3 },
    { 2, 0, 5, 0, 4, "exp", 1 }, { 2, 0, 5, 0, 5, "exp", 10 }, { 3, 0, 5, 0, 5, "exp", 1 }, { 4, 0, 5, 0, 6, "exp", 1 }, { 4, 0, 5, 0, 7, "exp", 20 },
    { 2, 0, 5, 0, 4, "naxx", 1 }, { 4, 0, 5, 0, 7, "naxx", 3 },
    -- 원정·낙스라마스는 스테이지 레벨이 고정이라 더 강한 파티로 다시 온다: { ..., 장비 레벨 }
    { 2, 0, 5, 50, 6, "exp", 10, 90 }, { 3, 0, 5, 30, 7, "exp", 10, 90 }, { 4, 0, 5, 11, 9, "exp", 20, 90 },
    { 2, 0, 5, 60, 7, "naxx", 1, 90 }, { 4, 0, 5, 6, 10, "naxx", 3, 90 },
}

local function gearLevel(stageLevel)
    local best = 1
    for _, l in ipairs(GEAR_LEVELS) do if l <= stageLevel then best = l end end
    return best
end

local function dress(s, heroId, level)
    local h = s.heroes[heroId]
    h.gear = {}
    -- 고유 능력치가 없는 장비를 먼저 고르고, 그 자리에 그런 장비가 없으면 있는 것을 낀다
    for pass = 1, 2 do
        for _, item in pairs(Items.byId) do
            if item.level == level and item.grade == GRADE and (pass == 2 or not item.unique) and Items.usableBy(item, heroId) and not h.gear[item.slot] then
                h.gear[item.slot] = { id = item.id }
            end
        end
    end
end

local function invest(s, id)
    local h, hero = s.heroes[id], Heroes.byId[id]
    for _ = 1, 200 do
        if Game.freePoints(s, id) <= 0 then break end
        local done = false
        for i = 1, 4 do
            local sk = hero.skills[i]
            if sk and not done and (h.active[sk] or 0) < math.max(1, math.floor(h.level / 10)) and Game.investActive(s, id, sk) then done = true end
        end
        for index = 1, 16 do if not done and Game.investPassive(s, id, index) then done = true end end
        if not done then break end
    end
    local bar = {}
    for i = 1, 4 do local sk = hero.skills[i]; if sk and (h.active[sk] or 0) > 0 then bar[#bar + 1] = sk end end
    Game.setBar(s, id, bar)
end

io.write(string.format("장비 등급 %s, 지점마다 %d판\n", Items.GRADES[GRADE].name, RUNS))
io.write("지점            | 인원 | Lv | 장비 | 클리어 | 전멸 | 평균 클리어 시간 | 원작 기준(분) | 처치/분\n")
for _, p in ipairs(POINTS) do
    local d, sec, n, diff = p[1], p[2], p[3], p[4]
    GRADE = p[5] or tonumber(arg[2]) or 3
    local kind, which = p[6], p[7]
    local key = Dungeons.stageKey(d, sec)
    if kind == "raid" then key = W.Raids.key(d, which)
    elseif kind == "exp" then key = W.Expeditions.keys[d][which]
    elseif kind == "naxx" then key = W.Expeditions.naxxKeys[d][which] end
    local stage = Tables.STAGES[key]
    local level = math.max(1, math.min(101, stage.level + diff))
    local s = Game.new("Horde", PARTY[1], 0)
    s.gold = 1e12
    s.unlocks.partySlots = 5
    s.unlocks.skillSlots = 4
    for i = 1, n do
        local id = PARTY[i]
        if not s.heroes[id] then s.heroes[id] = Game.newHero and Game.newHero(id) or nil; if not s.heroes[id] then Game.unlockHero(s, id) end end
        s.heroes[id].level = level
    end
    local list = {}
    for i = 1, n do list[i] = PARTY[i] end
    s.party = list
    local gearLv = p[8] or gearLevel(stage.level)
    for _, id in ipairs(list) do dress(s, id, gearLv); invest(s, id) end
    s.stage.difficulty, s.stage.section = d, (sec > 0 and sec or 101)
    if kind == "raid" or kind == "naxx" then s.stage.raidKey = key; s.materials[stage.token] = 99 end
    if kind == "exp" then s.stage.expedition = key end
    s.settings.repeatMode = true
    s.settings.autoRetry = true
    local sess = Session.new(s, { seed = 7 + sec })
    local clears, fails, t, started, times, kills = 0, 0, 0, 0, {}, 0
    failNotes = {}
    sess:addListener(function(ev)
        if ev == "stageStart" then started = t end
        if ev == "clear" then clears = clears + 1; times[#times + 1] = t - started end
        if ev == "fail" then
            fails = fails + 1
            local r = sess.runner
            if r then
                local b = r.boss
                local where = r.phase == "boss" and string.format("보스 %s 체력 %.0f%%", b and b.name or "?", b and b.hp / b:get("MaxHp") * 100 or -1)
                    or string.format("웨이브 %d/%d", r.wave, r.waves)
                failNotes[where] = (failNotes[where] or 0) + 1
            end
        end
        if ev == "kill" then kills = kills + 1 end
    end)
    while clears + fails < RUNS and t < 3600 * 3 do
        sess:advance(1, 40)
        t = t + 1
        s.supply = 100
        if kind == "raid" or kind == "naxx" then s.stage.raidKey = key; s.materials[stage.token] = 99 end
    end
    local avg = 0
    for _, x in ipairs(times) do avg = avg + x end
    avg = #times > 0 and avg / #times or 0
    local off = Tables.OFFLINE[math.min(#Tables.OFFLINE, stage.level)]
    local ref = off and off.clears and (60 / off.clears) or (off and off[4] and 60 / off[4]) or 0
    local label = kind == "raid" and ("레이드 " .. which) or (kind == "exp" and ("원정 강도 " .. which)) or (kind == "naxx" and ("낙스 " .. which))
        or (math.floor(sec / 100) .. "-" .. (sec % 100))
    io.write(string.format("%s %-11s| %4d | %2d | %3d %s | %6d | %4d | %10.1f분 | %10.1f | %6.1f\n", Tables.DIFFICULTY_NAMES[d], label,
        n, level, gearLv, Items.GRADES[GRADE].name, clears, fails, avg / 60, ref, kills / (t / 60)))
    for where, c in pairs(failNotes) do io.write("      전멸 위치: " .. where .. " × " .. c .. "\n") end
end
