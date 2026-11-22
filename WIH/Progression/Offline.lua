-- 오프라인 보상: 게임을 꺼 두었던 시간에 대한 골드와 경험치. 상자와 아이템은 없다. [원작]
--   · 룬(오프라인 보상)을 찍어야 받는다. 최대 8시간분. 30일 넘게 비웠거나 시각이 거꾸로 갔으면 0. [원작]
--   · 기준은 접속을 끊을 때 돌던 던전의 스테이지 레벨. [추정: 단일 계열 출처]
--   · 골드 = 표의 처치당 골드 × 시간당 처치 수 × 시간 × (1 + 오프라인 골드 룬 %)
--     경험치도 같은 꼴이고, 영웅마다 레벨 차 페널티를 적용한다. 편성한 영웅 각자가 받는다.
--     [추정: 표의 처치 수가 "1시간당"이라는 것, 일반 골드·경험치 룬은 곱하지 않는다는 것]
-- 계산한 보상은 저장 데이터에 "받을 것"으로 넣어 두고, 사용자가 받기를 눌렀을 때 지급한다(창을 닫아도 사라지지 않는다).

local _, WIH = ...
local Tables = WIH.module("Tables")
local Level = WIH.module("Level")
local Game = WIH.module("Game")
local Offline = WIH.module("Offline")

Offline.MAX_SECONDS = 8 * 3600        -- [원작]
Offline.MIN_SECONDS = 60              -- [독자] 이보다 짧게 비운 것은 치지 않는다(화면 다시 불러오기 등)
Offline.GUARD_SECONDS = 30 * 86400    -- [원작] 약 30일 이상이면 0

function Offline.unlocked(state)
    return WIH.Runes.total(state, "UnlockOfflineReward") > 0
end

-- 자리를 비운 시간에 대한 보상을 계산한다. 없으면 nil과 사유.
function Offline.compute(state, now)
    if not Offline.unlocked(state) then return nil, "locked" end
    local saved = state.savedAt or 0
    local away = (now or 0) - saved
    if saved <= 0 or away < Offline.MIN_SECONDS then return nil, "short" end
    if away >= Offline.GUARD_SECONDS then return nil, "guard" end
    local seconds = math.min(away, Offline.MAX_SECONDS)
    local key = Game.currentStageKey(state)
    local stage = Tables.STAGES[key]
    local row = stage and Tables.OFFLINE[stage.level]
    if not row then return nil, "stage" end
    local hours = seconds / 3600
    local totals = WIH.Runes.totals(state)
    local gold = row[1] * row[3] * hours * (1 + (totals.OfflineRewardGoldPercent or 0) / 1000)
    local baseExp = row[2] * row[3] * hours * (1 + (totals.OfflineRewardExpPercent or 0) / 1000)
    local exp = {}
    for _, heroId in ipairs(state.party) do
        local h = state.heroes[heroId]
        if h then exp[heroId] = math.floor(baseExp * Level.expPenalty(h.level, stage.level)) end
    end
    return { away = away, seconds = seconds, stageKey = key, level = stage.level, gold = math.floor(gold), exp = exp }
end

-- 계산한 보상을 "받을 것"에 더한다.
function Offline.addPending(state, result)
    local p = state.offline
    if type(p) ~= "table" then
        p = { seconds = 0, gold = 0, exp = {} }
        state.offline = p
    end
    p.seconds = p.seconds + result.seconds
    p.gold = p.gold + result.gold
    p.stageKey = result.stageKey
    for heroId, amount in pairs(result.exp) do p.exp[heroId] = (p.exp[heroId] or 0) + amount end
    return p
end

function Offline.pending(state)
    local p = state.offline
    if type(p) ~= "table" or (p.gold or 0) <= 0 and next(p.exp or {}) == nil then return nil end
    return p
end

-- 받을 것을 지급한다. 돌려주는 값: { gold, levels = { [영웅] = {올리기 전 레벨, 뒤 레벨} } }
function Offline.claim(state)
    local p = Offline.pending(state)
    if not p then return nil end
    Game.addGold(state, p.gold)
    local levels = {}
    for heroId, amount in pairs(p.exp) do
        local h = state.heroes[heroId]
        if h then
            local before = h.level
            Game.addExp(state, heroId, amount)
            levels[heroId] = { before, h.level }
        end
    end
    state.offline = nil
    return { gold = p.gold, seconds = p.seconds, levels = levels, exp = p.exp }
end

-- 저장 데이터 검증
function Offline.validate(state)
    local p = state.offline
    if p == nil then return end
    if type(p) ~= "table" or type(p.gold) ~= "number" or p.gold ~= p.gold or p.gold < 0 or type(p.exp) ~= "table" then
        state.offline = nil
        return
    end
    if type(p.seconds) ~= "number" or p.seconds ~= p.seconds then p.seconds = 0 end
    for heroId, amount in pairs(p.exp) do
        if not state.heroes[heroId] or type(amount) ~= "number" or amount ~= amount or amount < 0 then p.exp[heroId] = nil end
    end
end

return Offline
