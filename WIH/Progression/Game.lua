-- 게임 상태와 규칙: 새 게임, 영웅 해금, 편성, 스킬 트리 투자·환급, 장착 스킬, 스테이지 해금.
-- 상태는 순수한 표이며 그대로 SavedVariables에 저장된다(Save 모듈이 검증한다).
-- 모든 함수는 성공하면 true, 실패하면 false와 사유를 돌려준다. 화면은 사유를 그대로 보여 준다.

local _, WIH = ...
local Tables = WIH.module("Tables")
local Heroes = WIH.module("Heroes")
local SkillData = WIH.module("SkillData")
local Level = WIH.module("Level")
local Dungeons = WIH.module("Dungeons")
local Game = WIH.module("Game")

Game.SCHEMA = 2                  -- 2: 인벤토리, 장비, 상자, 재료가 생김
Game.START_GOLD = 100            -- [원작] 시작 골드
Game.HERO_UNLOCK_COST = 500      -- [원작] 영웅 해금 비용
Game.BASE_PARTY_SLOTS = 1        -- [원작] 편성 칸은 룬으로 늘린다
Game.MAX_PARTY_SLOTS = 5
Game.BASE_SKILL_SLOTS = 2        -- 결정 Q7: 기본 2칸 + 룬 2칸
Game.MAX_SKILL_SLOTS = 4

local function fail(reason) return false, reason end

local function newHero(heroId)
    local hero = Heroes.byId[heroId]
    local h = { unlocked = true, level = 1, exp = 0, active = {}, passive = {}, bar = {}, gear = {} }
    if hero.forms then h.form = hero.defaultForm end
    return h
end

-- 새 게임. faction = "Alliance" | "Horde", starter = 처음 고른 영웅
function Game.new(faction, starter, now)
    if faction ~= "Alliance" and faction ~= "Horde" then error("진영이 올바르지 않음: " .. tostring(faction)) end
    if not Heroes.byId[starter] then error("알 수 없는 영웅: " .. tostring(starter)) end
    local state = {
        schema = Game.SCHEMA,
        createdAt = now or 0, savedAt = now or 0,
        faction = faction,
        gold = Game.START_GOLD,
        heroes = { [starter] = newHero(starter) },
        party = { starter },
        unlocks = { partySlots = Game.BASE_PARTY_SLOTS, skillSlots = Game.BASE_SKILL_SLOTS },
        runes = {},
        stage = { difficulty = 1, section = 101, cleared = {}, bossIndex = {} },
        settings = { autoRetry = false, repeatMode = false, autoAdvance = true },     -- [추정] 실패하면 앞 스테이지로 물러나 쌓는다(원작 가이드)
        stats = { kills = 0, bossKills = 0, clears = 0, fails = 0, goldEarned = 0, playSeconds = 0 },
    }
    WIH.Inventory.ensure(state)
    WIH.Chests.ensure(state)
    WIH.Pets.ensure(state)
    if WIH.Relics then WIH.Relics.ensure(state) end
    WIH.Cube.ensure(state)
    WIH.Expeditions.ensure(state)
    return state
end

function Game.setFaction(state, faction)
    if faction ~= "Alliance" and faction ~= "Horde" then return fail("진영이 올바르지 않습니다.") end
    state.faction = faction
    return true
end

------------------------------------------------------------------------
-- 영웅과 편성
------------------------------------------------------------------------

function Game.unlockHero(state, heroId)
    if not Heroes.byId[heroId] then return fail("알 수 없는 영웅입니다.") end
    if state.heroes[heroId] and state.heroes[heroId].unlocked then return fail("이미 해금한 영웅입니다.") end
    if state.gold < Game.HERO_UNLOCK_COST then return fail("골드가 부족합니다.") end
    state.gold = state.gold - Game.HERO_UNLOCK_COST
    state.heroes[heroId] = newHero(heroId)
    return true
end

function Game.partySlots(state)
    local n = state.unlocks.partySlots or Game.BASE_PARTY_SLOTS
    if n > Game.MAX_PARTY_SLOTS then n = Game.MAX_PARTY_SLOTS end
    return n
end

function Game.skillSlots(state)
    local n = state.unlocks.skillSlots or Game.BASE_SKILL_SLOTS
    if n > Game.MAX_SKILL_SLOTS then n = Game.MAX_SKILL_SLOTS end
    return n
end

-- 편성을 통째로 바꾼다. list = 영웅 ID 목록(순서 = 편성 순서, 1번이 선두)
function Game.setParty(state, list)
    if #list < 1 then return fail("편성에는 영웅이 한 명 이상 있어야 합니다.") end
    if #list > Game.partySlots(state) then return fail("편성 칸이 부족합니다.") end
    local seen = {}
    for _, id in ipairs(list) do
        local h = state.heroes[id]
        if not h or not h.unlocked then return fail("해금하지 않은 영웅이 있습니다.") end
        if seen[id] then return fail("같은 영웅을 두 번 넣을 수 없습니다.") end
        seen[id] = true
    end
    local party = {}
    for i, id in ipairs(list) do party[i] = id end
    state.party = party
    return true
end

-- 야성 드루이드의 형태
function Game.setForm(state, heroId, form)
    local hero, h = Heroes.byId[heroId], state.heroes[heroId]
    if not hero or not h or not hero.forms or not hero.forms[form] then return fail("형태를 바꿀 수 없는 영웅입니다.") end
    h.form = form
    return true
end

------------------------------------------------------------------------
-- 스킬 트리
-- 티어 t의 노드에 투자하려면 t보다 낮은 티어들에 투자한 포인트의 합이 t 이상이어야 한다. [추정: 원작은 "누적 포인트"]
------------------------------------------------------------------------

local function activeIndex(hero, skillId)
    for i, id in ipairs(hero.skills) do
        if id == skillId then return i end
    end
    return nil
end

function Game.spentPoints(state, heroId)
    local h = state.heroes[heroId]
    local n = 0
    for _, v in pairs(h.active) do n = n + v end
    for _, v in pairs(h.passive) do n = n + v end
    return n
end

function Game.freePoints(state, heroId)
    return Level.skillPoints(state.heroes[heroId].level) - Game.spentPoints(state, heroId)
end

-- 티어 tier보다 낮은 티어들에 투자한 포인트
local function pointsBelow(hero, h, tier)
    local n = 0
    for i, id in ipairs(hero.skills) do
        if Heroes.ACTIVE_TIERS[i] < tier then n = n + (h.active[id] or 0) end
    end
    for index = 1, #hero.passives do
        if Heroes.PASSIVE_TIERS[index] < tier then n = n + (h.passive[index] or 0) end
    end
    return n
end

-- 모든 투자가 티어 조건을 만족하는지
local function treeValid(hero, h)
    for i, id in ipairs(hero.skills) do
        if (h.active[id] or 0) > 0 and pointsBelow(hero, h, Heroes.ACTIVE_TIERS[i]) < Heroes.ACTIVE_TIERS[i] then return false end
    end
    for index = 1, #hero.passives do
        if (h.passive[index] or 0) > 0 and pointsBelow(hero, h, Heroes.PASSIVE_TIERS[index]) < Heroes.PASSIVE_TIERS[index] then
            return false
        end
    end
    return true
end
Game.treeValid = treeValid

-- 그 티어의 노드에 투자할 수 있는지(아래 티어들에 투자한 포인트가 티어 값 이상인지)
function Game.tierOpen(state, heroId, tier)
    local hero, h = Heroes.byId[heroId], state.heroes[heroId]
    if not hero or not h then return false end
    return pointsBelow(hero, h, tier) >= tier
end

function Game.investActive(state, heroId, skillId)
    local hero, h = Heroes.byId[heroId], state.heroes[heroId]
    if not hero or not h then return fail("해금하지 않은 영웅입니다.") end
    local i = activeIndex(hero, skillId)
    if not i then return fail("이 영웅의 스킬이 아닙니다.") end
    if Game.freePoints(state, heroId) < 1 then return fail("스킬 포인트가 부족합니다.") end
    local cur = h.active[skillId] or 0
    if cur >= Heroes.ACTIVE_MAX_BY_POINTS then return fail("포인트로는 5레벨까지만 올릴 수 있습니다.") end
    local tier = Heroes.ACTIVE_TIERS[i]
    if pointsBelow(hero, h, tier) < tier then return fail("이 티어는 누적 " .. tier .. "포인트부터 열립니다.") end
    h.active[skillId] = cur + 1
    return true
end

function Game.investPassive(state, heroId, index)
    local hero, h = Heroes.byId[heroId], state.heroes[heroId]
    if not hero or not h then return fail("해금하지 않은 영웅입니다.") end
    local node = hero.passives[index]
    if not node then return fail("없는 패시브입니다.") end
    if Game.freePoints(state, heroId) < 1 then return fail("스킬 포인트가 부족합니다.") end
    local cur = h.passive[index] or 0
    if cur >= node.max then return fail("최대 레벨입니다.") end
    local tier = Heroes.PASSIVE_TIERS[index]
    if pointsBelow(hero, h, tier) < tier then return fail("이 티어는 누적 " .. tier .. "포인트부터 열립니다.") end
    h.passive[index] = cur + 1
    return true
end

-- 환급은 무료다. 환급한 뒤에도 남은 투자가 티어 조건을 만족해야 한다. [원작]
function Game.refundActive(state, heroId, skillId)
    local hero, h = Heroes.byId[heroId], state.heroes[heroId]
    if not hero or not h then return fail("해금하지 않은 영웅입니다.") end
    local cur = h.active[skillId] or 0
    if cur < 1 then return fail("투자한 포인트가 없습니다.") end
    h.active[skillId] = cur - 1
    if not treeValid(hero, h) then
        h.active[skillId] = cur
        return fail("상위 티어의 해금 조건이 깨져 환급할 수 없습니다.")
    end
    if h.active[skillId] == 0 then
        h.active[skillId] = nil
        for i = #h.bar, 1, -1 do
            if h.bar[i] == skillId then table.remove(h.bar, i) end
        end
    end
    return true
end

function Game.refundPassive(state, heroId, index)
    local hero, h = Heroes.byId[heroId], state.heroes[heroId]
    if not hero or not h then return fail("해금하지 않은 영웅입니다.") end
    local cur = h.passive[index] or 0
    if cur < 1 then return fail("투자한 포인트가 없습니다.") end
    h.passive[index] = cur - 1
    if not treeValid(hero, h) then
        h.passive[index] = cur
        return fail("상위 티어의 해금 조건이 깨져 환급할 수 없습니다.")
    end
    if h.passive[index] == 0 then h.passive[index] = nil end
    return true
end

function Game.resetTree(state, heroId)
    local h = state.heroes[heroId]
    if not h then return fail("해금하지 않은 영웅입니다.") end
    h.active, h.passive, h.bar = {}, {}, {}
    return true
end

-- 장착 스킬(우선순위 순). 1레벨 이상 투자한 액티브만.
function Game.setBar(state, heroId, list)
    local hero, h = Heroes.byId[heroId], state.heroes[heroId]
    if not hero or not h then return fail("해금하지 않은 영웅입니다.") end
    if #list > Game.skillSlots(state) then return fail("스킬 칸이 부족합니다.") end
    local seen = {}
    for _, id in ipairs(list) do
        if not activeIndex(hero, id) then return fail("이 영웅의 스킬이 아닙니다.") end
        if (h.active[id] or 0) < 1 then return fail("포인트를 투자하지 않은 스킬입니다.") end
        if seen[id] then return fail("같은 스킬을 두 번 장착할 수 없습니다.") end
        seen[id] = true
    end
    local bar = {}
    for i, id in ipairs(list) do bar[i] = id end
    h.bar = bar
    return true
end

------------------------------------------------------------------------
-- 전투용 편성 정보
------------------------------------------------------------------------

-- 영웅 한 명을 전투에 넣을 때 쓰는 정보(장착 스킬, 패시브, 장비 시트). 편성과 전투력 계산이 같이 쓴다.
function Game.heroEntry(state, heroId)
    local h = state.heroes[heroId]
    local slots = Game.skillSlots(state)
    local skills = {}
    for i = 1, math.min(#h.bar, slots) do
        local id = h.bar[i]
        skills[#skills + 1] = { id, h.active[id] or 1 }
    end
    return { heroId = heroId, form = h.form, level = h.level, passivePoints = h.passive, skills = skills,
        heroState = h, gear = WIH.Inventory.gearSheet(state, heroId) }
end

function Game.buildParty(state)
    local party = {}
    for rank, heroId in ipairs(state.party) do
        party[rank] = Game.heroEntry(state, heroId)
    end
    return party
end

------------------------------------------------------------------------
-- 스테이지
------------------------------------------------------------------------

local previousKey
local function buildPrevious()
    previousKey = {}
    for key, s in pairs(Tables.STAGES) do
        if s.next then previousKey[s.next] = key end
    end
end

function Game.previousStage(key)
    if not previousKey then buildPrevious() end
    return previousKey[key]
end

-- 스테이지가 열렸는지: 첫 스테이지이거나 바로 앞 스테이지를 클리어했을 때. [원작]
function Game.stageUnlocked(state, key)
    if not Tables.STAGES[key] then return false end
    if WIH.Expeditions then
        local special = WIH.Expeditions.stageUnlocked(state, key)
        if special ~= nil then return special end
    end
    if key == 1101 then return true end
    local prev = Game.previousStage(key)
    return prev ~= nil and (state.stage.cleared[prev] or 0) > 0
end

function Game.currentStageKey(state)
    return Dungeons.stageKey(state.stage.difficulty, state.stage.section)
end

function Game.selectStage(state, difficulty, section)
    local key = Dungeons.stageKey(difficulty, section)
    local s = Tables.STAGES[key]
    if not s or s.actBoss or not Dungeons.sections[section] then return fail("선택할 수 없는 스테이지입니다.") end
    if not Game.stageUnlocked(state, key) then return fail("아직 열리지 않은 스테이지입니다.") end
    state.stage.difficulty, state.stage.section = difficulty, section
    state.stage.raidKey = nil        -- 던전을 고르면 예약했거나 진행 중인 레이드·원정은 그만둔다
    state.stage.expedition = nil
    return true
end

-- 레이드(액트 보스 자리). 입장에는 그 난이도의 증표 1개가 필요하고, 클리어했을 때만 소모된다. [원작 구조 / 추정: 소모 시점]
function Game.raidTokens(state, difficulty)
    local id = WIH.Raids.TOKEN[difficulty]
    return id and state.materials and state.materials[id] or 0
end

function Game.canStartRaid(state, difficulty, act)
    local key = WIH.Raids.key(difficulty, act)
    local stage = Tables.STAGES[key]
    if not stage or not stage.actBoss or not WIH.Raids.byAct[act] then return fail("없는 레이드입니다.") end
    if not Game.stageUnlocked(state, key) then return fail("이 액트의 던전을 모두 클리어해야 열립니다.") end
    if Game.raidTokens(state, difficulty) < 1 then return fail(WIH.Raids.TOKEN_NAME .. "가 없습니다.") end
    return true, key
end

-- 레이드를 예약한다. 다음에 시작하는 스테이지가 레이드가 된다(화면은 바로 다시 시작시킨다).
function Game.startRaid(state, difficulty, act)
    local ok, key = Game.canStartRaid(state, difficulty, act)
    if not ok then return false, key end
    state.stage.raidKey = key
    state.stage.expedition = nil
    return true, key
end

function Game.markCleared(state, key)
    state.stage.cleared[key] = (state.stage.cleared[key] or 0) + 1
    state.stage.bossIndex[key] = (state.stage.bossIndex[key] or 1) + 1
    state.stats.clears = state.stats.clears + 1
end

-- 영웅에게 경험치를 주고 오른 레벨 수를 돌려준다.
function Game.addExp(state, heroId, amount)
    local h = state.heroes[heroId]
    if not h then return 0 end
    return Level.addExp(h, amount)
end

function Game.addGold(state, amount)
    if amount <= 0 then return end
    state.gold = state.gold + amount
    state.stats.goldEarned = state.stats.goldEarned + amount
end

return Game
