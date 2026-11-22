-- 유닛 한 틱의 행동: 재사용 충전 → 스킬 → 기본 공격 → 이동.
-- 편성 순서 규칙 [독자]: 영웅 쪽 유닛은 자기보다 앞 순서(rank가 작은)인 살아 있는 아군을 앞질러 가지 못한다.
-- 몬스터는 가장 가까운 상대를 치므로, 맨 앞에 선 유닛이 공격을 받는다.

local _, WIH = ...
local Battle = WIH.module("Battle")
local Skills = WIH.module("Skills")
local T = WIH.module("Targeting")
local AI = WIH.module("AI")

local TICK = WIH.TICK
local MOVE_FACTOR = Battle.MOVE_FACTOR
local READY = 1 - 1e-9   -- 부동소수점 누적 오차 허용
local MELEE_STOP = 100   -- [독자] 영웅 쪽 근접 유닛이 대상에게 붙는 거리

-- 대상에게 붙을 거리. 영웅 쪽 근접 유닛은 사거리와 상관없이 같은 거리까지 붙는다. 그래야 사거리가 짧은
-- 근접 영웅도 선두와 같은 자리에 서서 공격할 수 있고, 몬스터의 대상은 편성 순서로 정해진다.
local function stopDistance(u, range)
    local stop = range * 0.9
    if u.team == 1 and u.melee and stop > MELEE_STOP then stop = MELEE_STOP end
    return stop
end

-- 파티 이동 [원작]: 적에게 다가가는 동안(멀리 있을 때) 영웅은 가장 느린 파티원의 속도로 함께 움직인다.
-- 장비 고유 능력치가 규칙을 바꾼다(가장 빠른 / 평균 / 자신을 뺀 가장 느린).
local PACE_DISTANCE = 400      -- [독자] 이보다 멀리 있는 적에게 다가갈 때만 파티 속도를 쓴다
local function partyPace(b)
    if b.paceTick == b.tickCount then return b.pace end
    b.paceTick = b.tickCount
    local rule, owner = b.paceRule or "slowest", b.paceOwner
    local lo, hi, sum, n = nil, nil, 0, 0
    for _, o in ipairs(b.units) do
        if o.alive and o.kind == "hero" and not (rule == "exceptSelf" and o == owner) then
            local ms = o:get("MovementSpeed")
            lo = (not lo or ms < lo) and ms or lo
            hi = (not hi or ms > hi) and ms or hi
            sum, n = sum + ms, n + 1
        end
    end
    if n == 0 then b.pace = nil
    elseif rule == "fastest" then b.pace = hi
    elseif rule == "average" then b.pace = sum / n
    else b.pace = lo end
    return b.pace
end

local function move(b, u, target, stop)
    local ms = u:get("MovementSpeed")
    if u.kind == "hero" and math.abs(target.x - u.x) > PACE_DISTANCE then
        local pace = partyPace(b)
        if pace and ms > 0 then ms = pace end
    end
    local speed = ms * MOVE_FACTOR * TICK
    if speed <= 0 then return end
    local dir = target.x > u.x and 1 or -1
    local goal = target.x - dir * stop
    local nx = u.x + dir * speed
    if (dir > 0 and nx > goal) or (dir < 0 and nx < goal) then nx = goal end
    if u.team == 1 and dir > 0 and not u.ignoreRank then
        local units = b.units
        for i = 1, #units do
            local o = units[i]
            if o ~= u and o.team == 1 and o.alive and not o.ignoreRank and o.rank < u.rank and nx > o.x then
                nx = o.x
            end
        end
        if nx < u.x then nx = u.x end
    end
    if nx ~= u.x then
        u.x = nx
        u.moving = true
    end
end

function AI.act(b, u)
    if u.custom then return u.custom(b, u) end
    u.moving = false

    local disabled = false
    local effects = u.effects
    for i = 1, #effects do
        if effects[i].disable then
            disabled = true
            break
        end
    end

    if Skills.update(b, u, not disabled) then return end
    if disabled then return end
    -- 공격 충전: 공격속도가 도중에 바뀌어도 남은 시간에 바로 반영된다.
    if u.attackCharge < 1 then
        u.attackCharge = u.attackCharge + TICK * u:get("AttackSpeed")
    end
    if u.lock > 0 then return end

    local target, dist
    local focus = u.focusTarget
    if focus and focus.alive and not focus.noTarget then
        target, dist = focus, math.abs(focus.x - u.x)
    else
        target, dist = T.nearestEnemy(b, u)
    end
    if not target then return end
    local range = u.range
    if u.kind == "hero" then range = range * u:get("SkillRangeExpansion") end
    if dist <= range and u.attackCharge >= READY then
        u.attackCharge = u.attackCharge - 1
        if u.attackCharge < 0 then u.attackCharge = 0 end
        Skills.basicAttack(b, u, target)
    end
    -- 사거리 안이어도 정해진 거리까지는 계속 붙는다.
    local stop = stopDistance(u, range)
    if dist > stop + 0.5 and target.alive then
        move(b, u, target, stop)
    end
end

return AI
