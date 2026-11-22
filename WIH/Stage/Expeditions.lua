-- 원정(원작의 역병지대)과 낙스라마스(원작의 오염된 액트 보스)의 규칙.
--   · 원정: 악몽 줄구룹, 지옥 안퀴라즈 폐허, 고통 안퀴라즈 사원. 그 난이도의 첫 레이드(1-10)를 클리어하면 열린다. [원작]
--     강도 1~20이 각각 한 스테이지이고 앞 강도를 클리어해야 다음 강도가 열린다. 강도가 몬스터를 강화한다(원작 표). [원작]
--     입장에 원정 보급품 30 이상이 필요하고, 원정에 있는 동안 분당 1씩 줄며 0이 되면 던전으로 돌아간다. 보급품은 원정 밖에서
--     10분에 1씩(접속하지 않은 동안에도) 차고, 큐브의 보급 전환으로 채운다. [원작 구조 / 독자: 수치]
--   · 낙스라마스: 그 난이도(악몽 이상)의 액트 레이드를 클리어하면 그 스테이지가 열린다. 입장에 오염된 증표 1개(원정 상자에서 나온다),
--     클리어했을 때만 쓴다. 보스를 차례로 상대한다(레이드와 같은 방식). [원작 구조]
-- 원정·낙스라마스 스테이지는 Tables.STAGES와 ChestTable에 등록해, 진행기와 상자 규칙이 던전·레이드와 같은 길로 다룬다.

local _, WIH = ...
local Tables = WIH.module("Tables")
local ChestTable = WIH.module("ChestTable")
local ExpeditionTable = WIH.module("ExpeditionTable")
local ExpeditionData = WIH.module("ExpeditionData")
local Raids = WIH.module("Raids")
local Expeditions = WIH.module("Expeditions")

Expeditions.SUPPLY_MAX = 100
Expeditions.SUPPLY_ENTRY = 30
Expeditions.SUPPLY_USE = 1 / 60          -- 초당 소모(분당 1)
Expeditions.SUPPLY_REGEN = 1 / 600       -- 초당 충전(10분당 1)
Expeditions.NAXX_TOKEN = { [2] = 190102, [3] = 190103, [4] = 190104 }
Expeditions.NAMES = { [2] = "줄구룹", [3] = "안퀴라즈 폐허", [4] = "안퀴라즈 사원" }

-- 상자 표를 ChestTable 뒤에 붙인다.
local offset = #ChestTable.tables
for i, entries in ipairs(ExpeditionTable.tables) do ChestTable.tables[offset + i] = entries end

Expeditions.keys = {}       -- [난이도][강도] = 스테이지 키
for d, list in pairs(ExpeditionTable.PLAGUE) do
    Expeditions.keys[d] = {}
    for n, e in pairs(list) do
        Expeditions.keys[d][n] = e.key
        Tables.STAGES[e.key] = {
            level = e.level, waves = e.waves, perWave = e.perWave, chest = e.chestPpm / 1000, bossChest = e.bossChestPpm / 1000,
            mob = e.mob, bossFinal = e.bossFinal, boost = ExpeditionTable.INTENSITY[n], difficulty = d,
            expedition = { difficulty = d, intensity = n }, section = ExpeditionData.EXPEDITIONS[d],
            bossRotation = n,
        }
        ChestTable.STAGE[e.key] = { normal = offset + e.normal, boss = offset + e.boss, cool = e.cool, bossCool = e.bossCool }
    end
end
Expeditions.naxxKeys = {}
for d, list in pairs(ExpeditionTable.NAXX) do
    Expeditions.naxxKeys[d] = {}
    for a, e in pairs(list) do
        Expeditions.naxxKeys[d][a] = e.key
        Tables.STAGES[e.key] = { level = e.level, actBoss = true, actBossFinal = e.final, difficulty = d, raid = ExpeditionData.NAXX[a],
            token = Expeditions.NAXX_TOKEN[d], naxx = { difficulty = d, stage = a } }
        ChestTable.STAGE[e.key] = { raid = offset + e.raid }
    end
end
-- 레이드의 입장 재료를 스테이지에 적어 둔다(진행이 레이드와 낙스라마스를 같은 길로 다루도록).
for key, stage in pairs(Tables.STAGES) do
    if stage.actBoss and not stage.token then stage.token = Raids.TOKEN[math.floor(key / 1000)] end
end

local function fail(reason) return false, reason end

function Expeditions.ensure(state)
    if type(state.supply) ~= "number" or state.supply ~= state.supply then state.supply = Expeditions.SUPPLY_MAX end
    if state.supply < 0 then state.supply = 0 elseif state.supply > Expeditions.SUPPLY_MAX then state.supply = Expeditions.SUPPLY_MAX end
end

function Expeditions.unlocked(state, d)
    return ExpeditionTable.PLAGUE[d] ~= nil and (state.stage.cleared[Raids.key(d, 1)] or 0) > 0
end

function Expeditions.intensityUnlocked(state, d, n)
    if not Expeditions.unlocked(state, d) or not Expeditions.keys[d][n] then return false end
    if n == 1 then return true end
    return (state.stage.cleared[Expeditions.keys[d][n - 1]] or 0) > 0
end

function Expeditions.naxxUnlocked(state, d, a)
    return Expeditions.naxxKeys[d] ~= nil and Expeditions.naxxKeys[d][a] ~= nil and (state.stage.cleared[Raids.key(d, a)] or 0) > 0
end

-- 스테이지가 열렸는지(원정·낙스라마스 키일 때)
function Expeditions.stageUnlocked(state, key)
    local s = Tables.STAGES[key]
    if s.expedition then return Expeditions.intensityUnlocked(state, s.expedition.difficulty, s.expedition.intensity) end
    if s.naxx then return Expeditions.naxxUnlocked(state, s.naxx.difficulty, s.naxx.stage) end
    return nil
end

function Expeditions.highest(state, d)
    local best = 0
    for n = 1, 20 do
        if (state.stage.cleared[Expeditions.keys[d][n]] or 0) > 0 then best = n end
    end
    return best
end

function Expeditions.start(state, d, n)
    if not Expeditions.unlocked(state, d) then return fail("그 난이도의 첫 레이드를 클리어해야 열립니다.") end
    if not Expeditions.intensityUnlocked(state, d, n) then return fail("앞 강도를 클리어해야 열립니다.") end
    if state.supply < Expeditions.SUPPLY_ENTRY then return fail("원정 보급품이 " .. Expeditions.SUPPLY_ENTRY .. " 이상 있어야 합니다.") end
    state.stage.expedition = Expeditions.keys[d][n]
    state.stage.raidKey = nil
    return true
end

function Expeditions.leave(state)
    state.stage.expedition = nil
end

function Expeditions.startNaxx(state, d, a)
    if not Expeditions.naxxUnlocked(state, d, a) then return fail("그 난이도의 액트 " .. a .. " 레이드를 클리어해야 열립니다.") end
    local token = Expeditions.NAXX_TOKEN[d]
    if (state.materials[token] or 0) < 1 then return fail(WIH.Materials.name(token) .. "가 없습니다. 원정 상자에서 나옵니다.") end
    state.stage.raidKey = Expeditions.naxxKeys[d][a]
    state.stage.expedition = nil
    return true
end

-- 보급품: 원정에 있으면 줄고, 아니면 찬다.
function Expeditions.tick(state, dt, inExpedition)
    if inExpedition then
        state.supply = math.max(0, state.supply - dt * Expeditions.SUPPLY_USE)
    elseif state.supply < Expeditions.SUPPLY_MAX then
        state.supply = math.min(Expeditions.SUPPLY_MAX, state.supply + dt * Expeditions.SUPPLY_REGEN)
    end
end

-- 저장 데이터 검증
function Expeditions.validate(state)
    Expeditions.ensure(state)
    local key = state.stage.expedition
    if key ~= nil then
        local s = Tables.STAGES[key]
        if not s or not s.expedition or not Expeditions.intensityUnlocked(state, s.expedition.difficulty, s.expedition.intensity) then
            state.stage.expedition = nil
        end
    end
end

return Expeditions
