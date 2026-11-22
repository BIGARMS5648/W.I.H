-- 전투 유닛(영웅, 몬스터, 소환물)의 상태와 능력치 조회.

local _, WIH = ...
local Stats = WIH.module("Stats")
local Sheet = WIH.module("Sheet")
local Unit = WIH.module("Unit")

local U = {}
U.__index = U
Unit.methods = U

local nextId = 0

-- spec:
--   name, team(1 = 영웅 쪽, 2 = 몬스터 쪽), kind("hero" | "monster" | "summon"), isBoss
--   base   : 능력치 기본 정수값 {AttackDamage = 2, MaxHp = 130, ...}
--   static : 전투 중 바뀌지 않는 수정치 시트(장비, 패시브, 룬 등)
--   melee, range, rank(편성 순서. 작을수록 앞), x
--   owner  : 소환물의 주인. 공격 능력치는 주인의 것을 쓴다
function Unit.new(spec)
    nextId = nextId + 1
    local u = setmetatable({
        id = nextId,
        name = spec.name or ("unit" .. nextId),
        team = spec.team or 2,
        kind = spec.kind or "monster",
        isBoss = spec.isBoss or false,
        base = spec.base or {},
        static = spec.static or Sheet.new(),
        dyn = Sheet.new(),
        cache = {},
        dirty = false,
        melee = spec.melee and true or false,
        range = spec.range or 150,
        rank = spec.rank or 99,
        x = spec.x or 0,
        owner = spec.owner,
        statOwner = spec.owner,
        def = spec.def,
        alive = true,
        effects = {},        -- 버프, 디버프, 상태 이상, 지속 피해·회복, 보호막
        auraMods = {},       -- 오라가 주는 수정치 목록 (Battle이 주기적으로 다시 채운다)
        triggers = {},       -- 이벤트별 처리 함수 목록
        skills = {},         -- 장착 스킬의 실행 상태
        attackCharge = 1,    -- 기본 공격 충전량. 틱마다 공격속도만큼 차고 1이 되면 공격한다
        lock = 0,            -- 행동 불가 시간(시전 동작)
        basicElem = spec.basicElem or "Physical",
        basicDelivery = spec.basicDelivery or (spec.melee and "melee" or "proj"),
        basicArea = spec.basicArea,
        expires = spec.expires,
        cheatUsed = {},
        stats = { dealt = 0, taken = 0, healed = 0, shielded = 0, kills = 0, deaths = 0 },
    }, U)
    u.hp = u:get("MaxHp")
    return u
end

-- 능력치의 실제 값. 상한을 적용한다.
function U:get(stat)
    if self.dirty then self:rebuild() end
    local v = self.cache[stat]
    if v ~= nil then return v end
    v = Sheet.value(stat, self.base[stat], self.static, self.dyn)
    if stat == "CriticalChance" then
        if v > Stats.CAP_CRIT then v = Stats.CAP_CRIT elseif v < 0 then v = 0 end
    elseif stat == "CooldownReduction" then
        if v > Stats.CAP_COOLDOWN_REDUCTION then v = Stats.CAP_COOLDOWN_REDUCTION end
    elseif stat == "DamageReduction" then
        if v > Stats.CAP_DAMAGE_REDUCTION then v = Stats.CAP_DAMAGE_REDUCTION end
    elseif stat == "DodgeChance" then
        local cap = self:get("MaxDodgeChance")
        if v > cap then v = cap end
    elseif stat == "ElementalDodgeChance" then
        local cap = self:get("MaxElementalDodgeChance")
        if v > cap then v = cap end
    elseif stat == "BlockChance" then
        local cap = self:get("MaxBlockChance")
        if v > cap then v = cap end
    elseif stat == "ElementalBlockChance" then
        local cap = self:get("MaxElementalBlockChance")
        if v > cap then v = cap end
    elseif stat == "MovementSpeed" then
        local cap = (self.base.MovementSpeed or 0) * Stats.CAP_MOVE_MULT
        if cap > 0 and v > cap then v = cap end
        if v < 0 then v = 0 end
    elseif stat == "AttackSpeed" or stat == "CastSpeed" then
        if v < 0.05 then v = 0.05 end
    end
    self.cache[stat] = v
    return v
end

-- 공격 능력치는 소환물이면 주인의 값을 쓴다.
function U:off(stat)
    local o = self.statOwner
    if o then return o:get(stat) end
    return self:get(stat)
end

function U:invalidate()
    self.dirty = true
end

-- 효과와 오라의 수정치로 변동 시트를 다시 만든다.
function U:rebuild()
    self.dirty = false
    local dyn = self.dyn
    Sheet.clear(dyn)
    local effects = self.effects
    for i = 1, #effects do
        local e = effects[i]
        local mods = e.mods
        if mods then
            local stacks = e.stacks or 1
            for j = 1, #mods do
                local m = mods[j]
                Sheet.add(dyn, m[1], m[2], m[3] * stacks)
            end
        end
    end
    local auraMods = self.auraMods
    for i = 1, #auraMods do
        local m = auraMods[i]
        Sheet.add(dyn, m[1], m[2], m[3])
    end
    self.cache = {}
    local maxHp = self:get("MaxHp")
    if self.hp and self.hp > maxHp then self.hp = maxHp end
end

function U:hpRatio()
    local m = self:get("MaxHp")
    if m <= 0 then return 0 end
    return self.hp / m
end

function U:findEffect(id, src)
    local effects = self.effects
    for i = 1, #effects do
        local e = effects[i]
        if e.id == id and (src == nil or e.src == src) then return e, i end
    end
    return nil
end

function U:hasStatus(name)
    return self:findEffect("status:" .. name) ~= nil
end

function U:hasAnyStatus(names)
    for i = 1, #names do
        if self:hasStatus(names[i]) then return true end
    end
    return false
end

-- 행동 불가(빙결, 기절) 여부
function U:isDisabled()
    local effects = self.effects
    for i = 1, #effects do
        if effects[i].disable then return true end
    end
    return false
end

function U:isUntargetable()
    local effects = self.effects
    for i = 1, #effects do
        if effects[i].untargetable then return true end
    end
    return false
end

-- 남은 보호막 총량
function U:shieldTotal()
    local total = 0
    local effects = self.effects
    for i = 1, #effects do
        local e = effects[i]
        if e.kind == "shield" then total = total + e.amount end
    end
    return total
end

function U:addTrigger(event, handler)
    local list = self.triggers[event]
    if not list then
        list = {}
        self.triggers[event] = list
    end
    list[#list + 1] = handler
    return handler
end

function U:removeTrigger(event, handler)
    local list = self.triggers[event]
    if not list then return end
    for i = #list, 1, -1 do
        if list[i] == handler then table.remove(list, i) end
    end
end

return Unit
