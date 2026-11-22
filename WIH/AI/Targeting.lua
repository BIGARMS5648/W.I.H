-- 대상 선정. [독자 설계] 원작의 대상 선정 규칙은 공개 자료로 확인되지 않았다.
-- 위협 수준은 없다. 몬스터는 가장 가까운 상대를 고르고, 거리가 비슷하면 편성 순서가 앞인 쪽을 고른다.
-- 다른 규칙으로 바꾸려면 이 모듈의 함수만 교체하면 된다.

local _, WIH = ...
local Battle = WIH.module("Battle")
local T = WIH.module("Targeting")

local TIE = Battle.TIE_RANGE
local abs = math.abs

local function targetable(u)
    return u.alive and not u.noTarget
end

-- 가장 가까운 적. 거리 차이가 TIE 이하면 rank가 작은(앞에 선) 쪽.
function T.nearestEnemy(b, u, maxDist)
    local units = b.units
    local best, bestD
    for i = 1, #units do
        local o = units[i]
        if o.team ~= u.team and targetable(o) then
            local d = abs(o.x - u.x)
            if not maxDist or d <= maxDist then
                if not best then
                    best, bestD = o, d
                elseif d < bestD - TIE then
                    best, bestD = o, d
                elseif d <= bestD + TIE and o.rank < best.rank then
                    best = o
                    if d < bestD then bestD = d end
                end
            end
        end
    end
    return best, bestD
end

-- 조건에 맞는 적 가운데 key 함수 값이 가장 큰(또는 작은) 유닛
local function extremeEnemy(b, u, maxDist, key, wantMax)
    local units = b.units
    local best, bestV
    for i = 1, #units do
        local o = units[i]
        if o.team ~= u.team and targetable(o) and (not maxDist or abs(o.x - u.x) <= maxDist) then
            local v = key(o)
            if not best or (wantMax and v > bestV) or (not wantMax and v < bestV) then
                best, bestV = o, v
            end
        end
    end
    return best
end

function T.highestHpEnemy(b, u, maxDist)
    return extremeEnemy(b, u, maxDist, function(o) return o.hp end, true)
end

function T.lowestHpRatioEnemy(b, u, maxDist)
    return extremeEnemy(b, u, maxDist, function(o) return o:hpRatio() end, false)
end

-- 편성상 가장 뒤에 있는 적(후열 저격용): 시전자에게서 가장 먼 적
function T.farthestEnemy(b, u, maxDist)
    return extremeEnemy(b, u, maxDist, function(o) return abs(o.x - u.x) end, true)
end

-- x를 중심으로 반경 r 안의 적(시전자 기준)을 out에 담는다.
function T.enemiesAround(b, u, x, r, out)
    out = out or {}
    local n = 0
    local units = b.units
    for i = 1, #units do
        local o = units[i]
        if o.team ~= u.team and targetable(o) and abs(o.x - x) <= r then
            n = n + 1
            out[n] = o
        end
    end
    for i = n + 1, #out do out[i] = nil end
    return out, n
end

-- 사거리 안에서 반경 r 안에 적이 가장 많이 모인 지점의 중심 유닛
function T.densestEnemy(b, u, maxDist, r)
    local units = b.units
    local best, bestN, bestD
    for i = 1, #units do
        local o = units[i]
        if o.team ~= u.team and targetable(o) and (not maxDist or abs(o.x - u.x) <= maxDist) then
            local n = 0
            for j = 1, #units do
                local p = units[j]
                if p.team ~= u.team and targetable(p) and abs(p.x - o.x) <= r then n = n + 1 end
            end
            local d = abs(o.x - u.x)
            if not best or n > bestN or (n == bestN and d < bestD) then
                best, bestN, bestD = o, n, d
            end
        end
    end
    return best, bestN or 0
end

-- 아군(자신 포함) 중 체력 비율이 가장 낮은 유닛. heroesOnly면 소환물 제외. filter(유닛)이 거짓이면 제외.
function T.lowestHpAlly(b, u, heroesOnly, filter)
    local units = b.units
    local best, bestR
    for i = 1, #units do
        local o = units[i]
        if o.team == u.team and o.alive and (not heroesOnly or o.kind ~= "summon") and not o.noHeal
            and (not filter or filter(o)) then
            local r = o:hpRatio()
            if not best or r < bestR then best, bestR = o, r end
        end
    end
    return best, bestR
end

function T.deadAlly(b, u)
    local units = b.units
    for i = 1, #units do
        local o = units[i]
        if o.team == u.team and not o.alive and o.kind == "hero" then return o end
    end
    return nil
end

function T.highestAttackAlly(b, u)
    local units = b.units
    local best, bestV
    for i = 1, #units do
        local o = units[i]
        if o.team == u.team and o.alive and o.kind ~= "summon" then
            local v = o:get("AttackDamage") * o:get("AttackSpeed")
            if not best or v > bestV then best, bestV = o, v end
        end
    end
    return best
end

-- 아군 목록(자신 포함). radius가 있으면 그 안만.
function T.allies(b, u, x, radius, heroesOnly, out)
    out = out or {}
    local n = 0
    local units = b.units
    for i = 1, #units do
        local o = units[i]
        if o.team == u.team and o.alive and (not heroesOnly or o.kind ~= "summon") and not o.noHeal
            and (not radius or abs(o.x - x) <= radius) then
            n = n + 1
            out[n] = o
        end
    end
    for i = n + 1, #out do out[i] = nil end
    return out, n
end

function T.countEnemies(b, u, maxDist)
    local units = b.units
    local n, boss = 0, false
    for i = 1, #units do
        local o = units[i]
        if o.team ~= u.team and targetable(o) and (not maxDist or abs(o.x - u.x) <= maxDist) then
            n = n + 1
            if o.isBoss then boss = true end
        end
    end
    return n, boss
end

-- 스킬 데이터의 대상 규칙 이름 → 유닛
function T.pick(b, u, rule, range, radius)
    if rule == nil or rule == "nearest" then
        return T.nearestEnemy(b, u, range)
    elseif rule == "highestHpEnemy" then
        return T.highestHpEnemy(b, u, range)
    elseif rule == "lowestHpEnemy" then
        return T.lowestHpRatioEnemy(b, u, range)
    elseif rule == "farthest" then
        return T.farthestEnemy(b, u, range)
    elseif rule == "cluster" then
        return (T.densestEnemy(b, u, range, radius or 300))
    elseif rule == "lowestHpAlly" then
        return (T.lowestHpAlly(b, u, false))
    elseif rule == "lowestHpHero" then
        return (T.lowestHpAlly(b, u, true))
    elseif rule == "deadAlly" then
        return T.deadAlly(b, u)
    elseif rule == "highestAdAlly" then
        return T.highestAttackAlly(b, u)
    elseif rule == "self" then
        return u
    end
    error("알 수 없는 대상 규칙: " .. tostring(rule))
end

return T
