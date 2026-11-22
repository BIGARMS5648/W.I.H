-- 룬: 골드로 사는 계정 공통 영구 성장. 구조와 수치는 원작 표(Data/Runes.lua)를 쓴다.
-- 수치는 레벨마다 더해진다(노드를 최대 레벨까지 올리면 그 노드의 value 합만큼). [추정: 조사 보고서의 "최대 합계"와 일치]

local _, WIH = ...
local Stats = WIH.module("Stats")
local Sheet = WIH.module("Sheet")
local RuneData = WIH.module("RuneData")
local Game = WIH.module("Game")
local Runes = WIH.module("Runes")

local nodes = RuneData.nodes

-- 원작 데이터의 고립 노드(1133)를 같은 계열의 규칙(키 앞자리 = 부모)에 따라 113에 잇는다. [추정]
-- 원작 1.02.00 패치노트: "액트 보스 상자 최대 보관량 증가 노드 중 하나가 보이지 않던 문제 수정"
if nodes[1133] and not nodes[1133].parent and nodes[113] then
    nodes[1133].parent, nodes[1133].req = 113, 1
end

-- 이 프로젝트가 더한 노드 [독자]: 편성 4·5번째 칸, 스킬 4번째 칸(결정 Q6, Q7). 비용은 밸런스 단계에서 조정한다.
nodes[90001] = { stat = "UnlockArrangeSlotCount", max = 1, parent = 24, req = 1, cost = { 5000000 }, value = { 1 }, custom = true }
nodes[90002] = { stat = "UnlockArrangeSlotCount", max = 1, parent = 90001, req = 1, cost = { 100000000 }, value = { 1 }, custom = true }
nodes[90003] = { stat = "UnlockSkillSlotCount", max = 1, parent = 27, req = 1, cost = { 3000000 }, value = { 1 }, custom = true }

-- 자식 목록
local children = {}
for key, node in pairs(nodes) do
    if node.parent then
        children[node.parent] = children[node.parent] or {}
        table.insert(children[node.parent], key)
    end
end
for _, list in pairs(children) do table.sort(list) end
Runes.children = children

Runes.UNLOCK_HERO_LEVEL = 3      -- [원작] 아무 영웅이나 레벨 3이 되면 룬 트리가 열린다

-- 스탯의 표시 이름과 단위. unit: "flat" 그대로 / "pct" 퍼밀을 %로 / "sec" 초 / "unlock" 해금
Runes.STATS = {
    AllHeroAttackDamage = { "전 영웅 공격력", "flat" },
    AllHeroAttackDamagePercent = { "전 영웅 공격력", "pct" },
    AllHeroArmor = { "전 영웅 방어도", "flat" },
    AllHeroArmorPercent = { "전 영웅 방어도", "pct" },
    AllHeroAttackSpeed = { "전 영웅 공격속도", "pct" },
    AllHeroMoveSpeed = { "전 영웅 이동속도", "pct" },
    IncreaseGoldAmount = { "골드 획득", "pct" },
    IncreaseExpAmount = { "경험치 획득", "pct" },
    AdditionalGold = { "처치당 추가 골드", "flat" },
    AdditionalExp = { "처치당 추가 경험치", "flat" },
    AdditionalGoldNormalMonster = { "일반 몬스터 추가 골드", "flat" },
    AdditionalExpNormalMonster = { "일반 몬스터 추가 경험치", "flat" },
    AdditionalGoldStageBoss = { "스테이지 보스 추가 골드", "flat" },
    AdditionalExpStageBoss = { "스테이지 보스 추가 경험치", "flat" },
    AdditionalGoldActBoss = { "레이드 보스 추가 골드", "flat" },
    AdditionalExpActBoss = { "레이드 보스 추가 경험치", "flat" },
    DropChanceNormalChestPercent = { "일반 상자 드롭 확률", "pct" },
    DropChanceStageBossChestPercent = { "스테이지 상자 드롭 확률", "pct" },
    WaveCountReduction = { "스테이지 웨이브 수 감소", "flat" },
    CubeAlchemyGoldPercent = { "연금술 골드", "pct" },
    CubeExpPercent = { "큐브 경험치", "pct" },
    OfflineRewardGoldPercent = { "오프라인 골드", "pct" },
    OfflineRewardExpPercent = { "오프라인 경험치", "pct" },
    MaxInventorySlot = { "인벤토리 칸", "flat" },
    UnlockArrangeSlotCount = { "편성 칸", "flat" },
    UnlockSkillSlotCount = { "스킬 칸", "flat" },
    UnlockOfflineReward = { "오프라인 보상", "unlock" },
    UnlockStashPageCount = { "보관함 쪽", "flat" },
    MaxAmountNormalChest = { "일반 상자 보관 한도", "flat" },
    MaxAmountStageBossChest = { "스테이지 상자 보관 한도", "flat" },
    MaxAmountActBossChest = { "레이드 상자 보관 한도", "flat" },
    UnlockAutoOpenNormalChest = { "일반 상자 자동 개봉", "unlock" },
    UnlockAutoOpenStageBossChest = { "스테이지 상자 자동 개봉", "unlock" },
    UnlockAutoOpenActBossChest = { "레이드 상자 자동 개봉", "unlock" },
    ReduceAutoOpenNormalChestTime = { "일반 상자 자동 개봉 시간 단축", "sec" },
    ReduceAutoOpenStageBossChestTime = { "스테이지 상자 자동 개봉 시간 단축", "sec" },
    ReduceAutoOpenActBossChestTime = { "레이드 상자 자동 개봉 시간 단축", "sec" },
    OpenOneTypeChestAllAtOnce = { "같은 종류 상자 일괄 개봉", "unlock" },
    OpenAllTypeChestAllAtOnce = { "모든 상자 일괄 개봉", "unlock" },
    -- 역병의 룬(원정 상자) [원작 1.2.0]
    DropChancePlagueNormalChestPercent = { "원정 일반 상자 드롭 확률", "pct" },
    DropChancePlagueStageBossChestPercent = { "원정 보스 상자 드롭 확률", "pct" },
    MaxAmountPlagueNormalChest = { "원정 일반 상자 보관 한도", "flat" },
    MaxAmountPlagueStageBossChest = { "원정 보스 상자 보관 한도", "flat" },
    MaxAmountPlagueActBossChest = { "낙스라마스 상자 보관 한도", "flat" },
    UnlockAutoOpenPlagueNormalChest = { "원정 일반 상자 자동 개봉", "unlock" },
    UnlockAutoOpenPlagueStageBossChest = { "원정 보스 상자 자동 개봉", "unlock" },
    UnlockAutoOpenPlagueActBossChest = { "낙스라마스 상자 자동 개봉", "unlock" },
    ReduceAutoOpenPlagueNormalChestTime = { "원정 일반 상자 자동 개봉 시간 단축", "sec" },
    ReduceAutoOpenPlagueStageBossChestTime = { "원정 보스 상자 자동 개봉 시간 단축", "sec" },
    ReduceAutoOpenPlagueActBossChestTime = { "낙스라마스 상자 자동 개봉 시간 단축", "sec" },
}

-- 아직 이 효과를 쓰는 시스템이 들어오지 않은 스탯. 살 수는 있지만(뒤의 룬을 여는 조건이므로) 지금은 효과가 없다.
-- 해당 시스템을 구현할 때 여기서 지운다. 화면은 이 표를 보고 "미적용"을 표시한다.
Runes.INACTIVE = {}

-- 수치의 표기: "+10", "+5%", "-3초", "해금"
function Runes.valueText(stat, value)
    local info = Runes.STATS[stat]
    local unit = info and info[2] or "flat"
    local function num(v)
        if v == math.floor(v) then return tostring(v) end
        return (string.format("%.1f", v))
    end
    if unit == "pct" then return "+" .. num(value / 10) .. "%" end
    if unit == "sec" then return "-" .. num(value) .. "초" end
    if unit == "unlock" then return "해금" end
    if stat == "WaveCountReduction" then return "-" .. num(value) end
    return "+" .. num(value)
end

function Runes.label(stat)
    local info = Runes.STATS[stat]
    return info and info[1] or stat
end

local function fail(reason) return false, reason end

function Runes.level(state, key)
    return (state.runes and state.runes[key]) or 0
end

function Runes.treeUnlocked(state)
    for _, h in pairs(state.heroes) do
        if h.level >= Runes.UNLOCK_HERO_LEVEL then return true end
    end
    return false
end

-- 다음 레벨의 비용. 최대 레벨이면 nil.
function Runes.nextCost(state, key)
    local node = nodes[key]
    if not node then return nil end
    return node.cost[Runes.level(state, key) + 1]
end

-- 살 수 있는지와, 못 사면 그 사유
function Runes.canBuy(state, key)
    local node = nodes[key]
    if not node then return fail("없는 룬입니다.") end
    if not Runes.treeUnlocked(state) then return fail("영웅 한 명이 레벨 " .. Runes.UNLOCK_HERO_LEVEL .. "이 되면 열립니다.") end
    local level = Runes.level(state, key)
    if level >= node.max then return fail("최대 레벨입니다.") end
    if node.parent and Runes.level(state, node.parent) < (node.req or 1) then
        return fail("앞의 룬을 " .. (node.req or 1) .. "레벨 이상 올려야 합니다.")
    end
    if state.gold < node.cost[level + 1] then return fail("골드가 부족합니다.") end
    return true
end

function Runes.buy(state, key)
    local ok, why = Runes.canBuy(state, key)
    if not ok then return false, why end
    local node = nodes[key]
    local level = Runes.level(state, key)
    state.gold = state.gold - node.cost[level + 1]
    state.runes = state.runes or {}
    state.runes[key] = level + 1
    Runes.apply(state)
    return true
end

-- 룬만의 스탯별 합계
function Runes.ownTotals(state)
    local totals = {}
    for key, level in pairs(state.runes or {}) do
        local node = nodes[key]
        if node then
            local sum = 0
            for i = 1, math.min(level, node.max) do sum = sum + node.value[i] end
            totals[node.stat] = (totals[node.stat] or 0) + sum
        end
    end
    return totals
end

-- 계정 공통 합계: 룬 + 펫. 골드·경험치·상자 계산은 모두 이 합계를 쓴다.
function Runes.totals(state)
    local totals = Runes.ownTotals(state)
    if WIH.Pets then WIH.Pets.addTotals(state, totals) end
    if WIH.Relics then WIH.Relics.addTotals(state, totals) end
    return totals
end

function Runes.total(state, stat)
    return Runes.totals(state)[stat] or 0
end

-- 룬의 해금 효과를 상태에 반영한다(편성 칸, 스킬 칸).
function Runes.apply(state)
    local totals = Runes.ownTotals(state)
    state.unlocks.partySlots = math.min(Game.MAX_PARTY_SLOTS, Game.BASE_PARTY_SLOTS + (totals.UnlockArrangeSlotCount or 0))
    state.unlocks.skillSlots = math.min(Game.MAX_SKILL_SLOTS, Game.BASE_SKILL_SLOTS + (totals.UnlockSkillSlotCount or 0))
    return totals
end

-- 전투에 들어가는 계정 공통 수정치 시트 [원작: 룬의 출처 분류는 AccountStatus, 고정값은 Flat, %는 Increased]
function Runes.sheet(state)
    local totals = Runes.totals(state)
    local sheet = Sheet.new()
    local function add(stat, kind, v) if v and v ~= 0 then Sheet.add(sheet, stat, kind, v) end end
    add("AttackDamage", Stats.FLAT, totals.AllHeroAttackDamage)
    add("AttackDamage", Stats.INC, totals.AllHeroAttackDamagePercent)
    add("Armor", Stats.FLAT, totals.AllHeroArmor)
    add("Armor", Stats.INC, totals.AllHeroArmorPercent)
    add("AttackSpeed", Stats.INC, totals.AllHeroAttackSpeed)
    add("MovementSpeed", Stats.INC, totals.AllHeroMoveSpeed)
    add("IncreaseExpAmount", Stats.INC, totals.IncreaseExpAmount)
    add("AdditionalExp", Stats.FLAT, totals.AdditionalExp)
    if WIH.Relics then Sheet.merge(sheet, WIH.Relics.sheet(state)) end    -- 유물: 파티 전원 [원작]
    return sheet, totals
end

-- 처치 보상의 골드: (기본 + 고정 추가) × (1 + 골드 획득 %). [독자: 적용 순서는 원작에서 확인되지 않음]
function Runes.goldFor(totals, baseGold, kind)
    local flat = totals.AdditionalGold or 0
    if kind == "boss" then flat = flat + (totals.AdditionalGoldStageBoss or 0)
    elseif kind == "raid" then flat = flat + (totals.AdditionalGoldActBoss or 0)
    else flat = flat + (totals.AdditionalGoldNormalMonster or 0) end
    return (baseGold + flat) * (1 + (totals.IncreaseGoldAmount or 0) / 1000)
end

-- 처치 보상의 경험치에 더하는 대상별 고정 추가량(전체 공통 추가량과 %는 영웅의 능력치로 들어간다)
function Runes.extraExpFor(totals, kind)
    if kind == "boss" then return totals.AdditionalExpStageBoss or 0 end
    if kind == "raid" then return totals.AdditionalExpActBoss or 0 end
    return totals.AdditionalExpNormalMonster or 0
end

-- 저장 데이터 검증: 없는 노드와 범위를 벗어난 레벨을 고친다. 고친 수를 돌려준다.
function Runes.validate(state)
    local fixed = 0
    if type(state.runes) ~= "table" then
        state.runes = {}
        return 0
    end
    for key, level in pairs(state.runes) do
        local node = nodes[key]
        if not node or type(level) ~= "number" or level ~= level or level < 1 then
            state.runes[key] = nil
            fixed = fixed + 1
        elseif level > node.max or level ~= math.floor(level) then
            state.runes[key] = math.min(node.max, math.floor(level))      -- [원작 1.3.2] 최대 레벨을 넘은 룬은 최대 레벨로
            fixed = fixed + 1
        end
    end
    return fixed
end

return Runes
