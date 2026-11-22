-- 데이터만으로 표현하기 어려운 스킬의 특수 처리. 스킬 데이터에서 이름으로 부른다.

local _, WIH = ...
local Skills = WIH.module("Skills")
local T = WIH.module("Targeting")

local scaled = WIH.scaled
local special = Skills.special

-- 기계 슈트(기갑 땜장이). 내구도는 체력보다 먼저 깎이는 보호막이고, 탑승 중에만 수정치가 붙는다.
-- 내구도가 0이 되면 파손되어 remount초 뒤 다시 탑승한다. eff: pct(최대 체력 %), mods, remount
function special.suit(b, u, eff, L, ctx)
    local slot = ctx.slot
    local pct = scaled(eff.pct, L) / 100
    local mods = Skills.resolveMods(eff.mods, L)
    local function mount(ratio)
        local maxAmount = u:get("MaxHp") * pct
        u.suit = b:addEffect(u, { id = "suit", kind = "shield", src = u, suit = true,
            amount = maxAmount * (ratio or 1), maxAmount = maxAmount, mods = mods,
            onExpire = function(battle, unit)
                unit.suit = nil
                unit.suitBrokenAt = battle.time
                battle:emit("suit", unit, false)
            end })
        u.suitBrokenAt = nil
        b:emit("suit", u, true)
    end
    u.suitMount = mount
    mount(1)
    u:addTrigger("onRevive", function()
        u.suit = nil
        mount(1)
    end)
    b:addZone({ owner = u, team = u.team, x = u.x, radius = 0, dur = 1e9, every = 0.5, follow = u, hidden = true,
        name = slot.def.name,
        tick = function(battle)
            if u.alive and not u.suit and u.suitBrokenAt and battle.time - u.suitBrokenAt >= (eff.remount or 20) then
                mount(1)
            end
        end })
end

-- 긴급 수리. eff: pct(내구도 최대치의 %), remountRatio(파손 상태에서 다시 탈 때의 내구도 비율)
function special.suitRepair(_, u, eff, L)
    if u.suit then
        local s = u.suit
        s.amount = s.amount + s.maxAmount * scaled(eff.pct, L) / 100
        if s.amount > s.maxAmount then s.amount = s.maxAmount end
    elseif u.suitMount then
        u.suitMount(eff.remountRatio or 0.5)
    end
end

-- 연쇄 폭발. 자신의 포탑·로봇이 각자 가장 가까운 적에게 같은 폭탄을 pct 비율의 피해로 던진다.
-- eff: coef, pct, r, elem
function special.bombEcho(b, u, eff, L)
    local coef = scaled(eff.coef, L) / 100 * (eff.pct or 0.5)
    local sources = {}
    for i = 1, #b.units do
        local o = b.units[i]
        if o.alive and o.kind == "summon" and o.owner == u then sources[#sources + 1] = o end
    end
    for i = 1, #sources do
        local o = sources[i]
        local t = T.nearestEnemy(b, o, o.range)
        if t then
            local list, n = T.enemiesAround(b, u, t.x, eff.r * u:get("AreaOfEffect"), {})
            for j = 1, n do
                b:hit(o, list[j], { coef = coef, elem = eff.elem or "Fire", aoe = true })
            end
        end
    end
end

-- 치료 드론. every초마다 체력 비율이 가장 낮은 아군(below 이하)을 회복한다. 대상이 fastBelow 이하면 fastEvery초 주기.
-- eff: pct, every, fastEvery, below, fastBelow
function special.drone(b, u, eff, L, ctx)
    local slot = ctx.slot
    local pct = scaled(eff.pct, L) / 100
    local nextAt = b.time + eff.every
    b:addZone({ owner = u, team = u.team, x = u.x, radius = 0, dur = 1e9, every = 0.25, follow = u, isDrone = true,
        name = slot.def.name,
        tick = function(battle)
            if not u.alive or battle.time < nextAt then return end
            local t, ratio = T.lowestHpAlly(battle, u, true)
            if t and ratio <= (eff.below or 0.9) then
                battle:heal(u, t, t:get("MaxHp") * pct)
                battle:emit("drone", u, t)
                if ratio <= (eff.fastBelow or 0.35) then
                    nextAt = battle.time + (eff.fastEvery or eff.every)
                else
                    nextAt = battle.time + eff.every
                end
            end
        end })
end

return special
