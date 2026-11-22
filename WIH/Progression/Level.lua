-- 영웅 레벨, 경험치, 레벨 차 페널티, 스테이지 레벨에 따른 몬스터 수치.

local _, WIH = ...
local Tables = WIH.module("Tables")
local Level = WIH.module("Level")

local floor, log, abs, max = math.floor, math.log, math.abs, math.max

Level.MAX = Tables.MAX_LEVEL

-- 레벨 n에서 다음 레벨까지 필요한 경험치. 최대 레벨이면 nil.
function Level.expToNext(level)
    return Tables.EXP[level]
end

-- 그 레벨까지 얻은 스킬 포인트. 레벨업마다 1이므로 101레벨에서 100이다. [추정: 원작 출처가 N과 N−1로 갈림]
function Level.skillPoints(level)
    return level - 1
end

-- state = {level, exp}. 경험치를 더하고 오른 레벨 수를 돌려준다. 최대 레벨에서는 경험치가 쌓이지 않는다.
function Level.addExp(state, amount)
    if amount <= 0 then return 0 end
    local gained = 0
    state.exp = state.exp + amount
    while true do
        local need = Tables.EXP[state.level]
        if not need then
            state.exp = 0
            break
        end
        if state.exp < need then break end
        state.exp = state.exp - need
        state.level = state.level + 1
        gained = gained + 1
    end
    return gained
end

-- 영웅 레벨과 스테이지 레벨의 차이에 따른 경험치 배율(0.01 ~ 1).
-- [원작: 두 팬 사이트가 게임 코드에서 복원한 식이 서로 일치. 공식 수식은 아님] research/01 2.4절
function Level.expPenalty(heroLevel, stageLevel)
    local h, s = heroLevel, stageLevel
    local d = abs(h - s)
    local i = log(h + 1) / 10 + 1
    local r, a, o
    if h >= s then
        r, a, o = 0.5, floor(2 * i), floor(5 * i)
    else
        r, a, o = 0.4, floor(5 * i), floor(6 * i)
    end
    if d <= a then return 1 end
    if d <= a + o then
        local x = (d - a) / o
        return max(1 - (1 - r) * x * x, 0.01)
    end
    return max(r * (0.01 / r) ^ ((d - a - o) / max(h / 3, 1)), 0.01)
end

-- 0.5를 짝수 쪽으로 보내는 반올림 [추정: 원작 표시값과 맞는 방식]
local function roundHalfEven(x)
    local f = floor(x)
    local diff = x - f
    if diff > 0.5 then return f + 1 end
    if diff < 0.5 then return f end
    if f % 2 == 0 then return f end
    return f + 1
end
Level.round = roundHalfEven

-- 기본값과 스테이지 레벨로 몬스터의 실제 수치를 구한다. [원작] 값 = round(기본값 × 배율 ÷ 1000)
-- base = {hp, atk, gold, exp}
function Level.monsterValues(base, stageLevel)
    local m = Tables.STAGE_LEVEL[stageLevel]
    if not m then error("스테이지 레벨 범위 밖: " .. tostring(stageLevel), 2) end
    return roundHalfEven(base.hp * m[2] / 1000), roundHalfEven(base.atk * m[1] / 1000),
        roundHalfEven(base.gold * m[3] / 1000), roundHalfEven(base.exp * m[4] / 1000)
end

return Level
