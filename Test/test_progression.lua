-- 레벨·경험치·원작 수치 표의 검증.
-- 실행: lua5.1 Test/test_progression.lua

package.path = "./?.lua;" .. package.path
local T = require("Test.t")
local WIH = require("Test.engine").load()
local Tables, Level = WIH.Tables, WIH.Level

T.case("원작 표의 크기와 대표값", function()
    T.eq(#Tables.EXP, 100)
    T.eq(Tables.MAX_LEVEL, 101)
    T.eq(Tables.EXP[1], 30)
    T.eq(Tables.EXP[100], 1997771834)
    local sum = 0
    for i = 1, 100 do sum = sum + Tables.EXP[i] end
    T.eq(sum, 42291336533, "1 → 101 합계 (조사 보고서의 값)")
    T.ok(Tables.EXP[43] < Tables.EXP[40], "레벨 40~43 구간은 원작대로 줄어든다")
    T.eq(#Tables.STAGE_LEVEL, 170)
    T.eq(#Tables.OFFLINE, 116)
    local n, extra = 0, 0
    for _, st in pairs(Tables.STAGES) do
        if st.expedition or st.naxx then extra = extra + 1 else n = n + 1 end
    end
    T.eq(n, 120, "원작 일반 지역 스테이지")
    T.eq(extra, 60 + 9, "원정 60(난이도 3 × 강도 20) + 낙스라마스 9")
end)

T.case("스테이지 구조: 난이도 4 × 액트 3 × 10, 한 줄로 이어진다", function()
    local key, count, bosses = 1101, 0, 0
    while key do
        local s = Tables.STAGES[key]
        T.ok(s, "스테이지 없음: " .. tostring(key))
        count = count + 1
        if s.actBoss then
            bosses = bosses + 1
            T.eq(key % 100, 10, "액트 보스는 x-10")
        else
            T.ok(s.waves >= 10 and s.waves <= 31 and s.perWave >= 1 and s.perWave <= 21, "웨이브 범위: " .. key)
            T.ok(s.boss[2] >= 3000 and s.boss[2] <= 6000, "스테이지 보스 체력 배율 3~6배")
        end
        key = s.next
    end
    T.eq(count, 120)
    T.eq(bosses, 12)
    T.eq(Tables.STAGES[1101].level, 1)
    T.eq(Tables.STAGES[2101].level, 33)
    T.eq(Tables.STAGES[3101].level, 53)
    T.eq(Tables.STAGES[4101].level, 78)
    T.eq(Tables.STAGES[4310].level, 95)
    T.eq(Tables.STAGES[1101].chest, 160, "일반 1-1 상자 드롭률 16%")
    T.eq(Tables.STAGES[4309].chest, 8, "고통 0.8%")
end)

T.case("몬스터 수치 = round(기본값 × 배율 ÷ 1000): 조사 보고서의 검산 예와 일치", function()
    local hp, atk, gold, exp = Level.monsterValues({ hp = 50, atk = 10, gold = 10, exp = 10 }, 1)
    T.eq(hp, 5); T.eq(atk, 1); T.eq(gold, 1); T.eq(exp, 1)
    hp, atk, gold, exp = Level.monsterValues({ hp = 65, atk = 25, gold = 30, exp = 30 }, 95)
    T.eq(hp, 24913); T.eq(atk, 6140); T.eq(gold, 1190); T.eq(exp, 23478)
    hp = Level.monsterValues({ hp = 1050, atk = 0, gold = 0, exp = 0 }, 12)
    T.eq(hp, 1544, "일반 1-10 액트 보스")
    T.eq(Level.round(4.5), 4)
    T.eq(Level.round(1.5), 2)
    T.eq(Level.round(2.4999), 2)
end)

T.case("경험치와 레벨업", function()
    local s = { level = 1, exp = 0 }
    T.eq(Level.addExp(s, 29), 0)
    T.eq(Level.addExp(s, 1), 1)
    T.eq(s.level, 2); T.eq(s.exp, 0)
    T.eq(Level.addExp(s, 150 + 500 + 10), 2, "한 번에 여러 레벨")
    T.eq(s.level, 4); T.eq(s.exp, 10)
    T.eq(Level.skillPoints(1), 0)
    T.eq(Level.skillPoints(101), 100)
    local top = { level = 100, exp = 0 }
    Level.addExp(top, 5e9)
    T.eq(top.level, 101)
    T.eq(top.exp, 0, "최대 레벨에서는 경험치가 쌓이지 않는다")
    T.eq(Level.expToNext(101), nil)
    T.eq(Level.addExp(top, 1e9), 0)
end)

T.case("레벨 차 경험치 페널티: 조사 보고서의 표와 일치", function()
    -- 영웅 레벨 30. (스테이지 레벨 − 영웅 레벨) → 배율(%)
    local expect30 = { [-15] = 3, [-12] = 10, [-10] = 23, [-8] = 50, [-6] = 78, [-4] = 94, [-2] = 100, [0] = 100,
        [5] = 100, [8] = 96, [10] = 85, [12] = 66, [15] = 28, [20] = 4 }
    for diff, pct in pairs(expect30) do
        T.near(Level.expPenalty(30, 30 + diff) * 100, pct, 0.6, "영웅 30, 차이 " .. diff)
    end
    local expect100 = { [-20] = 14, [-15] = 25, [-10] = 44, [-8] = 63, [-6] = 84, [-4] = 96, [8] = 99, [10] = 92, [12] = 77,
        [15] = 40, [20] = 23 }
    for diff, pct in pairs(expect100) do
        T.near(Level.expPenalty(100, 100 + diff) * 100, pct, 0.6, "영웅 100, 차이 " .. diff)
    end
    T.near(Level.expPenalty(10, 30), 0.01, 1e-9, "바닥값 1%")
    for h = 1, 101 do
        for s = 1, 116 do
            local p = Level.expPenalty(h, s)
            T.ok(p >= 0.01 and p <= 1, "범위 벗어남")
        end
    end
end)

if not T.report("test_progression") then os.exit(1) end
