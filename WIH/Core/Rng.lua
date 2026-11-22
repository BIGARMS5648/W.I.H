-- 시드 기반 난수. 같은 시드면 같은 수열이 나온다.
-- Park-Miller 최소 표준 생성기(곱 48271, 법 2^31-1). 중간 곱이 2^53보다 작아 배정밀도에서 정확하다.

local _, WIH = ...
local Rng = WIH.module("Rng")

local M = 2147483647
local A = 48271

local methods = {}
methods.__index = methods

function Rng.new(seed)
    seed = math.floor(tonumber(seed) or 1)
    local state = seed % (M - 1)
    if state < 0 then state = state + (M - 1) end
    return setmetatable({ state = state + 1 }, methods)
end

function methods:next()
    self.state = (self.state * A) % M
    return self.state
end

-- [0, 1) 실수
function methods:float()
    return (self:next() - 1) / (M - 1)
end

-- lo 이상 hi 이하 정수
function methods:int(lo, hi)
    return lo + math.floor(self:float() * (hi - lo + 1))
end

-- 확률 p(0~1)로 참
function methods:chance(p)
    if p <= 0 then return false end
    if p >= 1 then return true end
    return self:float() < p
end

-- 가중치 목록에서 하나를 고른다. weights[i]는 0 이상의 수. 고른 위치를 돌려준다.
function methods:weighted(weights)
    local total = 0
    for i = 1, #weights do total = total + weights[i] end
    if total <= 0 then return nil end
    local r = self:float() * total
    local acc = 0
    for i = 1, #weights do
        acc = acc + weights[i]
        if r < acc then return i end
    end
    return #weights
end

return Rng
