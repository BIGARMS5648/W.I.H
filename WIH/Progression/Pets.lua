-- 펫: 전투에 참여하지 않고, 가지고 있기만 하면 파밍 보너스를 주는 계정 공통 성장. [원작]
--   · 효과는 경험치, 처치 골드, 일반 상자·스테이지 상자의 드롭 확률뿐이다. 보유한 펫의 효과가 모두 겹친다. 레벨과 등급은 없다.
--   · 효과 수치 10종은 원작 그대로다(1,000 = 100%).
--   · 얻는 조건: 원작은 특정 몬스터 5,000마리 처치(5종), 유료 추가 묶음(3종), 기간 한정 행사(2종)다.
--     이 프로젝트는 유료·행사분도 게임 안에서 얻게 한다(결정 D4). 그 조건은 이 프로젝트가 정했다 [독자].
--   · 동행 펫 하나를 골라 사냥 띠에 데리고 다닐 수 있다. 겉모습일 뿐 효과와는 무관하다. [원작: 편성 배치는 외형용]
-- 저장 형태: state.pets = { owned = { [펫] = true }, kills = { [몬스터] = 수 }, follow = 동행 펫 }

local _, WIH = ...
local Monsters = WIH.module("Monsters")
local Pets = WIH.module("Pets")

-- cond: { kind = "kill", monster = 몬스터 ID, count } | { kind = "raid", act, count } | { kind = "stat", stat, count }
-- npc = 사냥 띠에 보여 줄 모델의 생물 번호(기억에 의존. 나오지 않으면 표시하지 않는다)
Pets.list = {
    { id = "bat", name = "동굴 박쥐", npc = 1512, mods = { DropChanceNormalChestPercent = 100, IncreaseExpAmount = 150 },
        cond = { kind = "kill", monster = "rfk_bat", count = 5000 } },
    { id = "scarab", name = "모래 풍뎅이", npc = 7269, mods = { IncreaseGoldAmount = 150 },
        cond = { kind = "kill", monster = "zf_scarab", count = 5000 } },
    { id = "ember", name = "불씨 정령", npc = 2760, mods = { DropChanceStageBossChestPercent = 100 },
        cond = { kind = "kill", monster = "brd_elemental", count = 5000 } },
    { id = "construct", name = "작은 피조물", npc = 2671, mods = { DropChanceNormalChestPercent = 150 },
        cond = { kind = "kill", monster = "sch_construct", count = 5000 } },
    { id = "wisp", name = "엘드레스의 넋", npc = 3569, mods = { DropChanceStageBossChestPercent = 150 },
        cond = { kind = "kill", monster = "dmw_ghost", count = 5000 } },
    -- 원작의 유료 추가 묶음 3종 → 레이드 클리어 횟수 [독자]
    { id = "whelp_red", name = "붉은 새끼용", npc = 1042, mods = { IncreaseExpAmount = 150 },
        cond = { kind = "raid", act = 1, count = 10 } },
    { id = "corehound", name = "새끼 심장부 사냥개", npc = 11671, mods = { IncreaseGoldAmount = 100 },
        cond = { kind = "raid", act = 2, count = 10 } },
    { id = "whelp_black", name = "검은 새끼용", npc = 441, mods = { DropChanceNormalChestPercent = 200, IncreaseGoldAmount = 150, IncreaseExpAmount = 200 },
        cond = { kind = "raid", act = 3, count = 10 } },
    -- 원작의 기간 한정 행사 2종 → 누적 기록 [독자]
    { id = "pumpkin", name = "호박 초롱", npc = 2671, mods = { IncreaseGoldAmount = 10 },
        cond = { kind = "stat", stat = "bossKills", count = 500 } },
    { id = "ghostling", name = "꼬마 유령", npc = 3569, mods = { IncreaseExpAmount = 10 },
        cond = { kind = "stat", stat = "chestsOpened", count = 500 } },
}
Pets.byId = {}
local tracked = {}       -- 처치 수를 세야 하는 몬스터
for _, pet in ipairs(Pets.list) do
    Pets.byId[pet.id] = pet
    if pet.cond.kind == "kill" then
        assert(Monsters.defs[pet.cond.monster], "펫 조건의 몬스터가 없음: " .. pet.cond.monster)
        tracked[pet.cond.monster] = true
    end
end

local STAT_TEXT = {
    IncreaseExpAmount = "경험치 획득", IncreaseGoldAmount = "처치 골드",
    DropChanceNormalChestPercent = "일반 상자 드롭 확률", DropChanceStageBossChestPercent = "스테이지 상자 드롭 확률",
}

function Pets.ensure(state)
    if type(state.pets) ~= "table" then state.pets = {} end
    local p = state.pets
    if type(p.owned) ~= "table" then p.owned = {} end
    if type(p.kills) ~= "table" then p.kills = {} end
    return p
end

function Pets.owned(state, id)
    return state.pets ~= nil and state.pets.owned[id] == true
end

-- 조건의 진행: 현재 값, 필요한 값
function Pets.progress(state, pet)
    local c = pet.cond
    local have = 0
    if c.kind == "kill" then
        have = state.pets.kills[c.monster] or 0
    elseif c.kind == "raid" then
        for d = 1, 4 do have = have + (state.stage.cleared[WIH.Raids.key(d, c.act)] or 0) end
    elseif c.kind == "stat" then
        have = state.stats[c.stat] or 0
    end
    return math.min(have, c.count), c.count
end

function Pets.conditionText(pet)
    local c = pet.cond
    if c.kind == "kill" then return Monsters.defs[c.monster].name .. " " .. c.count .. "마리 처치" end
    if c.kind == "raid" then return WIH.Raids.byAct[c.act].name .. " " .. c.count .. "회 클리어(난이도 무관)" end
    if c.stat == "bossKills" then return "보스 " .. c.count .. "마리 처치" end
    return "상자 " .. c.count .. "개 열기"
end

function Pets.effectText(pet)
    local parts = {}
    for _, stat in ipairs({ "IncreaseExpAmount", "IncreaseGoldAmount", "DropChanceNormalChestPercent", "DropChanceStageBossChestPercent" }) do
        local v = pet.mods[stat]
        if v then parts[#parts + 1] = STAT_TEXT[stat] .. " +" .. (v / 10) .. "%" end
    end
    return table.concat(parts, ", ")
end

-- 조건을 채운 펫을 얻는다. 새로 얻은 펫의 목록을 돌려준다.
function Pets.check(state)
    Pets.ensure(state)
    local got
    for _, pet in ipairs(Pets.list) do
        if not state.pets.owned[pet.id] then
            local have, need = Pets.progress(state, pet)
            if have >= need then
                state.pets.owned[pet.id] = true
                got = got or {}
                got[#got + 1] = pet
            end
        end
    end
    return got
end

-- 몬스터를 잡았을 때: 조건에 쓰이는 몬스터만 센다.
function Pets.onKill(state, monsterId)
    if not tracked[monsterId] then return end
    local kills = state.pets.kills
    kills[monsterId] = (kills[monsterId] or 0) + 1
end

-- 보유한 펫의 효과를 합계 표에 더한다(룬의 합계와 같은 단위).
function Pets.addTotals(state, totals)
    local p = state.pets
    if type(p) ~= "table" or type(p.owned) ~= "table" then return totals end
    for _, pet in ipairs(Pets.list) do
        if p.owned[pet.id] then
            for stat, v in pairs(pet.mods) do totals[stat] = (totals[stat] or 0) + v end
        end
    end
    return totals
end

function Pets.setFollow(state, id)
    if id ~= nil and not Pets.owned(state, id) then return false, "아직 얻지 못한 펫입니다." end
    state.pets.follow = id
    return true
end

-- 저장 데이터 검증
function Pets.validate(state)
    local p = Pets.ensure(state)
    for id in pairs(p.owned) do
        if not Pets.byId[id] then p.owned[id] = nil end
    end
    for id, n in pairs(p.kills) do
        if not tracked[id] or type(n) ~= "number" or n ~= n or n < 0 then p.kills[id] = nil end
    end
    if p.follow ~= nil and not p.owned[p.follow] then p.follow = nil end
end

return Pets
