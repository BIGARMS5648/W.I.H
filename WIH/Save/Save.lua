-- 저장 데이터의 형식 변환과 검증. 저장 자체는 클라이언트가 SavedVariables로 한다.
-- 불러온 표가 망가져 있어도 오류를 내지 않고, 고칠 수 있는 것은 고치고 무엇을 고쳤는지 보고한다.

local _, WIH = ...
local Tables = WIH.module("Tables")
local Heroes = WIH.module("Heroes")
local Dungeons = WIH.module("Dungeons")
local Game = WIH.module("Game")
local Save = WIH.module("Save")

Save.BACKUPS = 3

-- 형식 버전별 변환 함수. migrations[n]은 n → n+1.
Save.migrations = {}

-- 1 → 2: 인벤토리, 장비, 상자, 재료가 생겼다. 빈 표를 만들어 준다.
Save.migrations[1] = function(raw)
    if type(raw.heroes) == "table" then
        for _, h in pairs(raw.heroes) do
            if type(h) == "table" and type(h.gear) ~= "table" then h.gear = {} end
        end
    end
    if type(raw.inventory) ~= "table" then raw.inventory = { items = {}, bought = 0 } end
    if type(raw.mail) ~= "table" then raw.mail = {} end
    if type(raw.materials) ~= "table" then raw.materials = {} end
end

local function isNumber(v)
    return type(v) == "number" and v == v and v ~= math.huge and v ~= -math.huge
end

local function isInt(v)
    return isNumber(v) and v == math.floor(v)
end

-- 값을 깊은 복사한다(백업용). 함수와 순환 참조는 저장 데이터에 없다고 본다.
local function deepCopy(v, depth)
    if type(v) ~= "table" then return v end
    depth = depth or 0
    if depth > 20 then return nil end
    local out = {}
    for k, x in pairs(v) do out[k] = deepCopy(x, depth + 1) end
    return out
end
Save.deepCopy = deepCopy

local function clampInt(v, lo, hi, default)
    if not isNumber(v) then return default end
    v = math.floor(v)
    if v < lo then return lo end
    if v > hi then return hi end
    return v
end

-- 영웅 한 명의 상태를 검증한다. 고친 내용은 notes에 적는다.
local function validateHero(heroId, h, notes)
    local hero = Heroes.byId[heroId]
    local function note(text) notes[#notes + 1] = hero.name .. ": " .. text end
    h.unlocked = true
    local level = clampInt(h.level, 1, Tables.MAX_LEVEL, 1)
    if level ~= h.level then note("레벨을 " .. level .. "(으)로 바로잡음") end
    h.level = level
    local need = Tables.EXP[level]
    if not isNumber(h.exp) or h.exp < 0 then
        note("경험치를 0으로 바로잡음")
        h.exp = 0
    elseif need and h.exp >= need then
        h.exp = need - 1
        note("경험치가 레벨 요구량을 넘어 바로잡음")
    elseif not need then
        h.exp = 0
    end

    if type(h.active) ~= "table" then h.active = {} end
    if type(h.passive) ~= "table" then h.passive = {} end
    if type(h.bar) ~= "table" then h.bar = {} end
    local own = {}
    for _, id in ipairs(hero.skills) do own[id] = true end
    for id, v in pairs(h.active) do
        if not own[id] then
            h.active[id] = nil
            note("이 영웅의 것이 아닌 스킬 투자를 지움")
        else
            local fixed = clampInt(v, 0, Heroes.ACTIVE_MAX_BY_POINTS, 0)
            if fixed ~= v then note("스킬 레벨을 바로잡음") end
            h.active[id] = fixed > 0 and fixed or nil
        end
    end
    for index, v in pairs(h.passive) do
        local node = isInt(index) and hero.passives[index]
        if not node then
            h.passive[index] = nil
            note("없는 패시브 투자를 지움")
        else
            local fixed = clampInt(v, 0, node.max, 0)
            if fixed ~= v then note("패시브 레벨을 바로잡음") end
            h.passive[index] = fixed > 0 and fixed or nil
        end
    end
    -- 포인트 초과 또는 티어 조건 위반이면 트리를 초기화한다(포인트는 돌려받는다).
    local spent = 0
    for _, v in pairs(h.active) do spent = spent + v end
    for _, v in pairs(h.passive) do spent = spent + v end
    if spent > level - 1 or not Game.treeValid(hero, h) then
        h.active, h.passive, h.bar = {}, {}, {}
        note("스킬 트리가 규칙에 맞지 않아 초기화함(포인트는 그대로)")
    end
    local bar, seen = {}, {}
    for _, id in ipairs(h.bar) do
        if own[id] and (h.active[id] or 0) > 0 and not seen[id] and #bar < Game.MAX_SKILL_SLOTS then
            bar[#bar + 1] = id
            seen[id] = true
        end
    end
    if #bar ~= #h.bar then note("장착 스킬을 바로잡음") end
    h.bar = bar
    if hero.forms then
        if not hero.forms[h.form] then h.form = hero.defaultForm end
    else
        h.form = nil
    end
end

-- 상태를 검증하고 고친다. 고친 내용의 목록을 돌려준다. 되살릴 수 없으면 nil.
function Save.validate(state)
    local notes = {}
    if type(state) ~= "table" then return nil end
    if state.faction ~= "Alliance" and state.faction ~= "Horde" then
        return nil      -- 진영이 없으면 진영 선택부터 다시 해야 한다
    end
    if not isNumber(state.gold) or state.gold < 0 then
        state.gold = 0
        notes[#notes + 1] = "골드를 0으로 바로잡음"
    end
    if not isNumber(state.createdAt) then state.createdAt = 0 end
    if not isNumber(state.savedAt) then state.savedAt = 0 end

    if type(state.heroes) ~= "table" then return nil end
    local count = 0
    for heroId, h in pairs(state.heroes) do
        if not Heroes.byId[heroId] or type(h) ~= "table" then
            state.heroes[heroId] = nil
            notes[#notes + 1] = "알 수 없는 영웅 기록을 지움: " .. tostring(heroId)
        else
            validateHero(heroId, h, notes)
            count = count + 1
        end
    end
    if count == 0 then return nil end

    if type(state.unlocks) ~= "table" then state.unlocks = {} end
    local Runes = WIH.Runes
    if Runes then
        local fixedRunes = Runes.validate(state)
        if fixedRunes > 0 then notes[#notes + 1] = "룬 기록 " .. fixedRunes .. "건을 바로잡음" end
        Runes.apply(state)       -- 편성 칸과 스킬 칸은 룬에서 다시 계산한다
    else
        state.unlocks.partySlots = clampInt(state.unlocks.partySlots, Game.BASE_PARTY_SLOTS, Game.MAX_PARTY_SLOTS, Game.BASE_PARTY_SLOTS)
        state.unlocks.skillSlots = clampInt(state.unlocks.skillSlots, Game.BASE_SKILL_SLOTS, Game.MAX_SKILL_SLOTS, Game.BASE_SKILL_SLOTS)
    end
    for _, h in pairs(state.heroes) do
        while #h.bar > state.unlocks.skillSlots do table.remove(h.bar) end
    end
    WIH.Inventory.validate(state, notes)
    WIH.Chests.validate(state, notes)

    local party, seen = {}, {}
    if type(state.party) == "table" then
        for _, id in ipairs(state.party) do
            if state.heroes[id] and not seen[id] and #party < state.unlocks.partySlots then
                party[#party + 1] = id
                seen[id] = true
            end
        end
    end
    if #party == 0 then
        -- 편성이 비었으면 레벨이 가장 높은 영웅을 넣는다.
        local best
        for id, h in pairs(state.heroes) do
            if not best or h.level > state.heroes[best].level or (h.level == state.heroes[best].level and id < best) then best = id end
        end
        party[1] = best
        notes[#notes + 1] = "편성이 비어 있어 영웅 한 명을 넣음"
    elseif type(state.party) ~= "table" or #party ~= #state.party then
        notes[#notes + 1] = "편성을 바로잡음"
    end
    state.party = party

    if type(state.stage) ~= "table" then state.stage = {} end
    local st = state.stage
    if type(st.cleared) ~= "table" then st.cleared = {} end
    if type(st.bossIndex) ~= "table" then st.bossIndex = {} end
    for key, v in pairs(st.cleared) do
        if not Tables.STAGES[key] or not isNumber(v) or v < 0 then st.cleared[key] = nil end
    end
    for key, v in pairs(st.bossIndex) do
        if not Tables.STAGES[key] or not isInt(v) or v < 1 then st.bossIndex[key] = nil end
    end
    st.difficulty = clampInt(st.difficulty, 1, 4, 1)
    if not Dungeons.sections[st.section] then st.section = 101 end
    if not Game.stageUnlocked(state, Dungeons.stageKey(st.difficulty, st.section)) then
        st.difficulty, st.section = 1, 101
        notes[#notes + 1] = "열리지 않은 스테이지가 선택돼 있어 첫 스테이지로 옮김"
    end

    if type(state.settings) ~= "table" then state.settings = {} end
    local set = state.settings
    if type(set.autoRetry) ~= "boolean" then set.autoRetry = true end
    if type(set.repeatMode) ~= "boolean" then set.repeatMode = false end
    if type(set.autoAdvance) ~= "boolean" then set.autoAdvance = true end

    if type(state.stats) ~= "table" then state.stats = {} end
    for _, k in ipairs({ "kills", "bossKills", "clears", "fails", "goldEarned", "playSeconds", "chestsOpened" }) do
        if not isNumber(state.stats[k]) or state.stats[k] < 0 then state.stats[k] = 0 end
    end
    return notes
end

-- 불러오기. raw = SavedVariables에서 읽은 표(또는 nil).
-- 돌려주는 값: state(없으면 nil), info = { status = "new" | "ok" | "fixed" | "broken" | "newer", notes = {...} }
function Save.load(raw)
    if raw == nil then return nil, { status = "new", notes = {} } end
    if type(raw) ~= "table" then return nil, { status = "broken", notes = { "저장 데이터가 표가 아님" } } end
    local schema = raw.schema
    if not isInt(schema) or schema < 1 then return nil, { status = "broken", notes = { "저장 형식 번호가 없음" } } end
    if schema > Game.SCHEMA then
        -- 더 새 버전의 애드온이 만든 저장: 건드리지 않는다.
        return nil, { status = "newer", notes = { "더 새로운 버전의 저장 데이터(" .. schema .. ")" } }
    end
    local notes = {}
    while schema < Game.SCHEMA do
        local step = Save.migrations[schema]
        if not step then return nil, { status = "broken", notes = { "형식 " .. schema .. "에서 변환할 방법이 없음" } } end
        local ok, err = pcall(step, raw)
        if not ok then return nil, { status = "broken", notes = { "형식 변환 실패: " .. tostring(err) } } end
        schema = schema + 1
        raw.schema = schema
        notes[#notes + 1] = "저장 형식을 " .. schema .. "(으)로 변환함"
    end
    local ok, fixes = pcall(Save.validate, raw)
    if not ok then return nil, { status = "broken", notes = { "검증 중 오류: " .. tostring(fixes) } } end
    if not fixes then return nil, { status = "broken", notes = { "되살릴 수 없는 저장 데이터" } } end
    for i = 1, #fixes do notes[#notes + 1] = fixes[i] end
    return raw, { status = #notes > 0 and "fixed" or "ok", notes = notes }
end

-- 백업 목록 맨 앞에 사본을 넣고 오래된 것을 버린다.
function Save.pushBackup(backups, state, now)
    if type(backups) ~= "table" then backups = {} end
    table.insert(backups, 1, { at = now or 0, data = deepCopy(state) })
    while #backups > Save.BACKUPS do table.remove(backups) end
    return backups
end

return Save
