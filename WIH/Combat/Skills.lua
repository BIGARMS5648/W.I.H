-- 스킬의 실행 상태와 효과 처리.
-- 스킬 데이터(Data/Skills_*.lua)는 선언형이다. 여기의 실행기가 효과 종류별로 처리한다.
-- 툴팁도 같은 데이터와 WIH.scaled로 수치를 만든다.

local _, WIH = ...
local Stats = WIH.module("Stats")
local Unit = WIH.module("Unit")
local Battle = WIH.module("Battle")
local T = WIH.module("Targeting")
local Skills = WIH.module("Skills")

local scaled = WIH.scaled
local TICK = WIH.TICK
local abs = math.abs
local runTriggers = Battle.runTriggers

local CAST_TIME = 0.3        -- [독자] 재사용 스킬의 시전 동작 시간(시전속도로 나눈다)
local CHAIN_RANGE = 450      -- [독자] 연쇄가 다음 대상을 찾는 거리
local ADJACENT_RANGE = 200   -- [독자] "옆의 적" 판정 거리

local exec = {}
Skills.exec = exec
Skills.special = {}          -- 이름으로 등록하는 특수 처리기(기계 슈트 등)

local function effLevel(u, slot)
    local owner = u.statOwner or u
    local lv = slot.level + owner:get("AddAllSkillLevel")
    if lv > 10 then lv = 10 end
    if lv < 1 then lv = 1 end
    return lv
end
Skills.effectiveLevel = effLevel

-- 수정치 목록을 현재 레벨의 숫자로 바꾼다.
local function resolveMods(mods, level)
    if not mods then return nil end
    local out = {}
    for i = 1, #mods do
        local m = mods[i]
        out[i] = { m[1], m[2], scaled(m[3], level) }
    end
    return out
end

local function areaRadius(u, r)
    return r * (u.statOwner or u):get("AreaOfEffect")
end

local function duration(u, d)
    return d * (u.statOwner or u):get("SkillDurationIncrease")
end

------------------------------------------------------------------------
-- 조건
------------------------------------------------------------------------

-- cond: { hpBelow = 0.5 } (자신), { targetHpBelow = 0.85 }, { enemies = 3, orBoss = true },
--       { alliesBelow = {n = 2, hp = 0.8} }, { avgHpBelow = 0.6 }, { targetStacks = {id, n} }, { summons = 2 }
function Skills.condition(b, u, cond, target)
    if not cond then return true end
    if cond.hpBelow and u:hpRatio() > cond.hpBelow then
        if not (cond.orBoss and select(2, T.countEnemies(b, u, 1600))) then return false end
    end
    if cond.targetHpBelow and (not target or target:hpRatio() > cond.targetHpBelow) then return false end
    if cond.enemies then
        local n, boss = T.countEnemies(b, u, cond.range or 1600)
        if n < cond.enemies and not (cond.orBoss and boss) then return false end
    end
    if cond.boss then
        local _, boss = T.countEnemies(b, u, 1600)
        if not boss then return false end
    end
    if cond.alliesBelow then
        local list = T.allies(b, u, u.x, nil, true)
        local n = 0
        for i = 1, #list do
            if list[i]:hpRatio() <= cond.alliesBelow.hp then n = n + 1 end
        end
        if n < cond.alliesBelow.n then return false end
    end
    if cond.avgHpBelow then
        local list = T.allies(b, u, u.x, nil, true)
        local sum = 0
        for i = 1, #list do sum = sum + list[i]:hpRatio() end
        if #list == 0 or sum / #list > cond.avgHpBelow then return false end
    end
    if cond.targetStacks then
        local e = target and target:findEffect(cond.targetStacks.id)
        if not e or (e.stacks or 1) < cond.targetStacks.n then return false end
    end
    if cond.summons then
        local n = 0
        for i = 1, #b.units do
            local o = b.units[i]
            if o.alive and o.kind == "summon" and o.owner == u then n = n + 1 end
        end
        if n < cond.summons and not (cond.orBoss and select(2, T.countEnemies(b, u, 1600))) then return false end
    end
    if cond.custom then return cond.custom(b, u, target) end
    return true
end

------------------------------------------------------------------------
-- 조건부 공격 보너스(동파, 계획된 살인 등)와 다음 타격 강화(냉혈, 소멸 등)
------------------------------------------------------------------------

local function applyBonuses(u, t, spec)
    local owner = u.statOwner or u
    local list = owner.condBonus
    if list then
        for i = 1, #list do
            local c = list[i]
            local ok = true
            if c.statusAny and not t:hasAnyStatus(c.statusAny) then ok = false end
            if c.fullHp and t:hpRatio() < 0.999 then ok = false end
            if ok then
                if c.critMult then spec.critChanceMult = (spec.critChanceMult or 1) * c.critMult end
                if c.critDmg then spec.critDmgBonus = (spec.critDmgBonus or 0) + c.critDmg end
                if c.mult then spec.mult = (spec.mult or 1) * c.mult end
            end
        end
    end
end

-- 다음 타격 스킬 강화를 꺼내 쓴다. 쓸 것이 있으면 spec에 반영한다.
local function consumeNext(u, spec, isSkill)
    local n = u.nextHit
    if not n or (n.skillOnly and not isSkill) then return end
    if n.forceCrit then spec.forceCrit = true end
    if n.critDmg then spec.critDmgBonus = (spec.critDmgBonus or 0) + n.critDmg end
    if n.mult then spec.mult = (spec.mult or 1) * n.mult end
    n.count = n.count - 1
    if n.count <= 0 then u.nextHit = nil end
end

------------------------------------------------------------------------
-- 효과 실행기
------------------------------------------------------------------------

local scratch = {}

-- 피해. eff: elem, melee/proj/aoe, coef, hits, area = {r, at}, chain = {n, falloff}, adjacent = {n, pct},
--   forceCrit, execute(잃은 체력 비율만큼 최대 +execute), bonusIf = {status, hpBelow, mult}, leech,
--   perStack = {id, consume}, apply = {효과 목록}, resetOnKill, summonHit(소환물이 대신 타격)
function exec.damage(b, u, eff, L, ctx)
    local target = ctx.target
    local source = u
    if eff.summonHit then
        source = ctx.slot.summonUnit
        if not source or not source.alive then return end
    end
    local owner = u.statOwner or u
    local coef = scaled(eff.coef, L) / 100
    local elem = eff.elem or u.basicElem
    local hits = scaled(eff.hits or 1, L)
    if not eff.area and not eff.noMultistrike then
        hits = hits + owner:get("Multistrike")
    end
    if eff.proj and eff.multiProj then
        hits = hits + owner:get("ProjectileCount")
    end

    local targets, n
    if eff.area then
        local cx
        if eff.area.at == "self" then cx = u.x
        elseif ctx.point then cx = ctx.point
        elseif target then cx = target.x
        else return end
        targets, n = T.enemiesAround(b, u, cx, areaRadius(u, eff.area.r), scratch)
        -- 실행 중 목록이 바뀔 수 있으므로 복사한다.
        local copy = {}
        for i = 1, n do copy[i] = targets[i] end
        targets = copy
    else
        if not target or not target.alive then return end
        targets, n = { target }, 1
    end

    local killed = false
    for i = 1, n do
        local t = targets[i]
        for _ = 1, hits do
            if not t.alive then break end
            local spec = { coef = coef, elem = elem, melee = eff.melee, proj = eff.proj,
                aoe = eff.area ~= nil or eff.aoe, forceCrit = eff.forceCrit, leech = eff.leech,
                skill = ctx.slot and ctx.slot.def, mult = ctx.mult }
            if eff.execute then
                spec.mult = (spec.mult or 1) * (1 + (1 - t:hpRatio()) * eff.execute)
            end
            if eff.bonusIf then
                local c = eff.bonusIf
                local ok = true
                if c.status and not t:hasStatus(c.status) then ok = false end
                if c.hpBelow and t:hpRatio() > c.hpBelow then ok = false end
                if ok then spec.mult = (spec.mult or 1) * c.mult end
            end
            if eff.perStack then
                local e = t:findEffect(eff.perStack.id)
                local stacks = e and (e.stacks or 1) or 0
                if stacks == 0 then break end
                spec.coef = coef * stacks
            end
            applyBonuses(source, t, spec)
            consumeNext(owner, spec, true)
            local wasAlive = t.alive
            b:hit(source, t, spec)
            if wasAlive and not t.alive then killed = true end
        end
        if eff.apply and t.alive then
            ctx.target = t
            Skills.runEffects(b, u, eff.apply, L, ctx)
        end
    end
    ctx.target = target

    if eff.adjacent and target then
        local list, m = T.enemiesAround(b, u, target.x, ADJACENT_RANGE, scratch)
        local done = 0
        for i = 1, m do
            local t = list[i]
            if t ~= target and done < eff.adjacent.n then
                done = done + 1
                b:hit(source, t, { coef = coef * eff.adjacent.pct, elem = elem, melee = eff.melee, proj = eff.proj })
            end
        end
    end

    if eff.chain and target then
        local hit = { [target] = true }
        local last = target
        local c = coef
        for _ = 2, eff.chain.n do
            c = c * (1 - eff.chain.falloff)
            local best, bestD
            for i = 1, #b.units do
                local o = b.units[i]
                if o.team ~= u.team and o.alive and not o.noTarget and not hit[o] then
                    local d = abs(o.x - last.x)
                    if d <= CHAIN_RANGE and (not best or d < bestD) then best, bestD = o, d end
                end
            end
            if not best then break end
            hit[best] = true
            last = best
            b:hit(source, best, { coef = c, elem = elem, proj = eff.proj, aoe = true })
            if eff.apply and best.alive then
                ctx.target = best
                Skills.runEffects(b, u, eff.apply, L, ctx)
            end
        end
        ctx.target = target
    end

    if killed and eff.resetOnKill and ctx.slot then
        ctx.slot.charge = ctx.slot.def.act.cd or 0
    end
end

-- 치유 대상 목록: "target", "all", "chain"
local function healTargets(b, u, eff, ctx)
    if eff.who == "all" then
        local list = T.allies(b, u, u.x, eff.radius and areaRadius(u, eff.radius) or nil, not eff.includeSummons, {})
        return list
    elseif eff.who == "self" then
        return { u }
    elseif eff.who == "chain" then
        local list = T.allies(b, u, u.x, nil, true, {})
        table.sort(list, function(a, c) return a:hpRatio() < c:hpRatio() end)
        local out = {}
        for i = 1, math.min(eff.chain.n, #list) do out[i] = list[i] end
        return out
    end
    if ctx.target and ctx.target.alive then return { ctx.target } end
    return {}
end

-- 치유. eff: pct(대상 최대 체력 %), flat, coef(시전자 공격력 %), who, chain = {n, falloff}, hot = {dur, pct | flat}
function exec.heal(b, u, eff, L, ctx)
    local list = healTargets(b, u, eff, ctx)
    local falloff = 1
    for i = 1, #list do
        local t = list[i]
        local amount = 0
        if eff.pct then amount = amount + t:get("MaxHp") * scaled(eff.pct, L) / 100 end
        if eff.flat then amount = amount + scaled(eff.flat, L) end
        if eff.coef then amount = amount + (u.statOwner or u):get("AttackDamage") * scaled(eff.coef, L) / 100 end
        if amount > 0 then b:heal(u, t, amount * falloff) end
        if eff.hot then
            local h = eff.hot
            b:addEffect(t, { id = "hot:" .. (ctx.slot and ctx.slot.def.id or "?"), kind = "hot", src = u,
                dur = duration(u, h.dur), perSource = true,
                hot = { pct = h.pct and scaled(h.pct, L) / 100 * falloff, flat = h.flat and scaled(h.flat, L) * falloff } })
        end
        if eff.who == "chain" then falloff = falloff * (1 - eff.chain.falloff) end
    end
end

-- 보호막. eff: pct(대상 최대 체력 %), dur, who
function exec.shield(b, u, eff, L, ctx)
    local list = healTargets(b, u, eff, ctx)
    for i = 1, #list do
        local t = list[i]
        b:addShield(u, t, t:get("MaxHp") * scaled(eff.pct, L) / 100, eff.dur and duration(u, eff.dur) or nil,
            "shield:" .. (ctx.slot and ctx.slot.def.id or "?") .. ":" .. u.id)
    end
end

local function buffTargets(b, u, eff, ctx)
    local who = eff.who or "self"
    if who == "self" then return { u } end
    if who == "target" then
        if ctx.target and ctx.target.alive then return { ctx.target } end
        return {}
    end
    if who == "allies" then
        return T.allies(b, u, u.x, eff.radius and areaRadius(u, eff.radius) or nil, not eff.includeSummons, {})
    end
    if who == "summons" then
        local out = {}
        for i = 1, #b.units do
            local o = b.units[i]
            if o.alive and o.kind == "summon" and o.owner == u then out[#out + 1] = o end
        end
        return out
    end
    if who == "enemies" then
        local cx = eff.at == "self" and u.x or (ctx.target and ctx.target.x) or u.x
        local list = T.enemiesAround(b, u, cx, areaRadius(u, eff.radius or 300), {})
        return list
    end
    if who == "highestAdAlly" then
        local t = T.highestAttackAlly(b, u)
        return t and { t } or {}
    end
    error("알 수 없는 버프 대상: " .. tostring(who))
end

-- 버프·디버프. eff: who, radius, dur 또는 attacks, mods, id, maxStacks,
--   nextHit = {count, forceCrit, critDmg, mult, skillOnly}, cleave = pct, untargetable, ccImmune, harmful
function exec.buff(b, u, eff, L, ctx)
    local list = buffTargets(b, u, eff, ctx)
    local id = eff.id or ("buff:" .. (ctx.slot and ctx.slot.def.id or "?") .. ":" .. (ctx.effIndex or 0))
    for i = 1, #list do
        local t = list[i]
        local e = { id = id, kind = eff.harmful and "debuff" or "buff", src = u, harmful = eff.harmful,
            mods = resolveMods(eff.mods, L), maxStacks = eff.maxStacks, perSource = eff.perSource }
        if eff.dur then
            e.dur = eff.harmful and scaled(eff.dur, L) or duration(u, scaled(eff.dur, L))
        end
        if eff.attacks then e.attacksLeft = scaled(eff.attacks, L) end
        if eff.cleave then e.cleave = scaled(eff.cleave, L) / 100 end
        if eff.untargetable then
            t.noTarget = true
            e.onExpire = function(_, unit) unit.noTarget = false end
        end
        if eff.ccImmune then
            t.ccImmune = true
            e.onExpire = function(_, unit) unit.ccImmune = false end
        end
        b:addEffect(t, e)
        if eff.nextHit then
            local n = eff.nextHit
            t.nextHit = { count = scaled(n.count or 1, L), forceCrit = n.forceCrit, skillOnly = n.skillOnly,
                critDmg = n.critDmg and scaled(n.critDmg, L) / 100, mult = n.mult and (1 + scaled(n.mult, L) / 100) }
        end
    end
end

exec.debuff = function(b, u, eff, L, ctx)
    if eff.who == nil then eff.who = "target" end
    eff.harmful = true
    return exec.buff(b, u, eff, L, ctx)
end

-- 상태 이상. eff: status, area = {r, at}
function exec.status(b, u, eff, L, ctx)
    if eff.area then
        local cx = eff.area.at == "self" and u.x or (ctx.target and ctx.target.x)
        if not cx then return end
        local list, n = T.enemiesAround(b, u, cx, areaRadius(u, eff.area.r), {})
        for i = 1, n do b:applyStatus(u, list[i], eff.status) end
    elseif ctx.target and ctx.target.alive then
        b:applyStatus(u, ctx.target, eff.status)
    end
end

-- 부착형 지속 피해. eff: elem, coef(초당 %), dur, maxStacks, id, stacks(한 번에 쌓는 수)
function exec.dot(b, u, eff, L, ctx)
    local t = ctx.target
    if not t or not t.alive then return end
    local perTick = scaled(eff.coef, L) / 100 * Battle.DOT_INTERVAL
    local mult = (u.statOwner or u).dotMult
    b:addEffect(t, { id = eff.id or ("dot:" .. (ctx.slot and ctx.slot.def.id or "?")), kind = "dot", src = u,
        harmful = true, dur = scaled(eff.dur, L), perSource = true, maxStacks = eff.maxStacks,
        addStacks = eff.stacks, stacks = eff.stacks or 1,
        dot = { elem = eff.elem or "Chaos", coef = perTick, mult = mult }, skill = ctx.slot and ctx.slot.def })
end

-- 지면 영역. eff: r, dur, every, at("self" | "target" | "cluster"), follow, absorb,
--   enemy = {효과 목록(영역 안 적 각각에게)}, ally = {효과 목록(영역 안 아군 각각에게)}
function exec.zone(b, u, eff, L, ctx)
    local cx = u.x
    if eff.at ~= "self" and ctx.target then cx = ctx.target.x end
    local slot = ctx.slot
    local z = { owner = u, team = u.team, x = cx, radius = areaRadius(u, eff.r), dur = duration(u, scaled(eff.dur, L)),
        every = eff.every or 1, follow = eff.follow and u or nil, absorb = eff.absorb and scaled(eff.absorb, L) or nil,
        name = slot and slot.def.name, requireOwner = eff.requireOwner }
    z.tick = function(battle, zone)
        if not u.alive and not eff.persist then return end
        local zctx = { slot = slot, point = zone.x, zone = zone }
        if eff.enemy then
            local list, n = T.enemiesAround(battle, u, zone.x, zone.radius, {})
            for i = 1, n do
                if list[i].alive then
                    zctx.target = list[i]
                    Skills.runEffects(battle, u, eff.enemy, L, zctx)
                end
            end
        end
        if eff.ally then
            local list = T.allies(battle, u, zone.x, zone.radius, not eff.includeSummons, {})
            for i = 1, #list do
                zctx.target = list[i]
                Skills.runEffects(battle, u, eff.ally, L, zctx)
            end
        end
        if eff.once then
            zctx.target = nil
            Skills.runEffects(battle, u, eff.once, L, zctx)
        end
    end
    b:addZone(z)
    if eff.immediate then z.tick(b, z) end
end

-- 덫. eff: r(감지·폭발 반경), max, dur, effects(폭발 시 중심 유닛 기준으로 실행)
function exec.trap(b, u, eff, L, ctx)
    local slot = ctx.slot
    slot.traps = slot.traps or {}
    local traps = slot.traps
    for i = #traps, 1, -1 do
        if traps[i].done then table.remove(traps, i) end
    end
    if #traps >= (eff.max or 1) then
        traps[1].expires = b.time
        traps[1].done = true
        table.remove(traps, 1)
    end
    -- 가장 가까운 적과 시전자 사이, 적의 진로에 놓는다.
    local target = ctx.target or T.nearestEnemy(b, u)
    local x = target and (target.x + u.x) / 2 or (u.x + 300)
    if target and abs(target.x - u.x) < 400 then x = target.x end
    local z = { owner = u, team = u.team, x = x, radius = areaRadius(u, eff.r), dur = eff.dur or 30, every = 0.1,
        name = slot.def.name, isTrap = true }
    z.tick = function(battle, zone)
        if zone.done then return end
        local list, n = T.enemiesAround(battle, u, zone.x, zone.radius * 0.5, {})
        if n > 0 then
            zone.done = true
            zone.expires = battle.time
            Skills.runEffects(battle, u, eff.effects, L, { slot = slot, target = list[1], point = zone.x })
        end
    end
    traps[#traps + 1] = z
    b:addZone(z)
end

-- 소환. eff.unit: name, kind("follower" | "turret"), hpPct, interval, coef, elem, melee, range, area, dur, max,
--   moveSpeed, front(주인 바로 앞에 선다). eff.permanent면 상시 유지하고 죽으면 respawn초 뒤 다시 소환.
local function spawnSummon(b, u, eff, L, slot)
    local s = eff.unit
    local owner = u
    local maxHp = owner:get("MaxHp") * (s.hpPct or 100) / 100
    local follower = s.kind == "follower"
    local summon = Unit.new({
        name = s.name, team = owner.team, kind = "summon", owner = owner, def = s,
        base = { MaxHp = maxHp, AttackSpeed = 100 / s.interval, MovementSpeed = s.moveSpeed or (follower and 950 or 0),
            Armor = owner:get("Armor"), CastSpeed = 100, CriticalDamage = 1000, DamageDealt = 1000 },
        melee = s.melee, range = s.range or (s.melee and 130 or 900),
        rank = follower and (owner.rank - 0.5) or (owner.rank + 0.2),
        x = owner.x + (follower and 20 or 0),
        basicElem = s.elem or "Physical", basicDelivery = s.melee and "melee" or "proj",
        basicArea = s.area,
    })
    summon.basicCoef = scaled(s.coef, L) / 100
    summon.sumKind = s.kind
    summon.skillId = slot.def.id
    summon.ignoreRank = not follower
    if s.dur then summon.expires = b.time + duration(u, s.dur) end
    if s.noTarget then summon.noTarget = true end
    b:addUnit(summon)
    return summon
end

function exec.summon(b, u, eff, L, ctx)
    local slot = ctx.slot
    slot.summons = slot.summons or {}
    local list = slot.summons
    for i = #list, 1, -1 do
        if not list[i].alive then table.remove(list, i) end
    end
    local max = scaled(eff.unit.max or 1, L) + ((u.summonBonus and u.summonBonus[slot.def.id]) or 0)
    while #list >= max do
        local old = table.remove(list, 1)
        old.alive = false
        old.expired = true
    end
    local summon = spawnSummon(b, u, eff, L, slot)
    list[#list + 1] = summon
    slot.summonUnit = summon
    if eff.onSpawn then
        Skills.runEffects(b, u, eff.onSpawn, L, { slot = slot, target = ctx.target, point = ctx.target and ctx.target.x })
    end
    if eff.permanent then
        summon.onDeath = function(battle)
            slot.respawnAt = battle.time + (eff.respawn or 20)
        end
    end
    return summon
end

-- 부활. eff: pct, all
function exec.revive(b, u, eff, L, ctx)
    local pct = scaled(eff.pct, L) / 100
    if eff.all then
        for i = 1, #b.units do
            local o = b.units[i]
            if o.team == u.team and o.kind == "hero" and not o.alive then b:revive(o, pct) end
        end
    elseif ctx.target and not ctx.target.alive then
        b:revive(ctx.target, pct)
    end
end

-- 상태 이상 제거. eff: who("target" | "allies"), radius
function exec.cleanse(b, u, eff, _, ctx)
    local list = buffTargets(b, u, { who = eff.who or "target", radius = eff.radius }, ctx)
    for i = 1, #list do b:cleanse(list[i]) end
end

-- 대상에게 돌진하거나 대상 뒤로 이동한다. eff: behind
function exec.dash(_, u, eff, _, ctx)
    local t = ctx.target
    if not t then return end
    local dir = (t.x >= u.x) and 1 or -1
    if eff.behind then
        u.x = t.x + dir * u.range * 0.5
    else
        u.x = t.x - dir * u.range * 0.8
    end
end

-- 자신의 다른 재사용 스킬 하나를 즉시 준비시킨다(남은 시간이 가장 긴 것).
function exec.refresh(_, u, _, _, ctx)
    local best, bestLeft
    for i = 1, #u.skills do
        local s = u.skills[i]
        if s ~= ctx.slot and s.def.act.type == "cd" then
            local left = s.def.act.cd - s.charge
            if left > 0 and (not best or left > bestLeft) then best, bestLeft = s, left end
        end
    end
    if best then best.charge = best.def.act.cd end
end

-- 이름으로 등록한 특수 처리
function exec.special(b, u, eff, L, ctx)
    local fn = Skills.special[eff.name]
    if not fn then error("등록되지 않은 특수 효과: " .. tostring(eff.name)) end
    return fn(b, u, eff, L, ctx)
end

function Skills.runEffects(b, u, effects, L, ctx)
    for i = 1, #effects do
        local eff = effects[i]
        local fn = exec[eff.type]
        if not fn then error("알 수 없는 효과 종류: " .. tostring(eff.type)) end
        ctx.effIndex = i
        fn(b, u, eff, L, ctx)
    end
end

------------------------------------------------------------------------
-- 오라와 발동 효과(장착하는 동안 유지)
------------------------------------------------------------------------

-- aura: who, radius, mods, redirect = {mode, pct}, proc = {chance, effects}, reflect = {elem, coef, on, max},
--   onCrit = {효과 목록}, onDodge = {효과 목록}, lethal = {pct, shieldPct, party}, cond = {statusAny, fullHp, critMult, critDmg, mult},
--   leech = {pct, dotOnly, party, elem}, dotDouble = 확률
local function installAura(b, u, slot, eff, L)
    local def = slot.def
    if eff.mods or eff.redirect then
        local a = { owner = u, who = eff.who or "allies", radius = eff.radius and areaRadius(u, eff.radius) or 1200,
            mods = resolveMods(eff.mods, L), skill = def, includeSummons = eff.includeSummons }
        if eff.redirect then
            a.redirect = { mode = eff.redirect.mode, pct = scaled(eff.redirect.pct, L) / 100 }
            if eff.redirect.mode == "lowest" then
                a.update = function(battle, aura)
                    aura.currentTarget = T.lowestHpAlly(battle, u, true, function(o) return o ~= u end)
                end
            elseif eff.redirect.mode == "toSummon" then
                a.update = function(battle, aura)
                    aura.currentSummon = nil
                    for i = 1, #battle.units do
                        local o = battle.units[i]
                        if o.alive and o.kind == "summon" and o.owner == u and o.sumKind == "follower" then
                            aura.currentSummon = o
                            break
                        end
                    end
                end
            end
        end
        b:addAura(a)
    end
    if eff.proc then
        local chance = scaled(eff.proc.chance, L) / 100
        u:addTrigger("onBasicAttack", function(battle, unit, target)
            if target.alive and battle.rng:chance(chance) then
                Skills.runEffects(battle, unit, eff.proc.effects, L, { slot = slot, target = target })
            end
        end)
    end
    if eff.reflect then
        local r = eff.reflect
        local coef = scaled(r.coef, L) / 100
        local function reflect(battle, unit, attacker, _, spec)
            if not attacker or not attacker.alive or attacker.team == u.team then return end
            if spec and (spec.isDot or spec.isReflect) then return end
            if r.meleeOnly and not (spec and spec.melee) then return end
            if not u.alive then return end
            if unit ~= u and abs(unit.x - u.x) > (eff.radius or 600) then return end
            battle:hit(u, attacker, { coef = coef, elem = r.elem, isReflect = true, canCrit = false })
        end
        if r.allies then
            b.allyHitHooks = b.allyHitHooks or {}
            b.allyHitHooks[#b.allyHitHooks + 1] = { team = u.team, fn = reflect, owner = u }
        else
            u:addTrigger(r.on == "block" and "onBlock" or "onHitTaken", reflect)
        end
    end
    if eff.onCrit then
        u:addTrigger("onDealDamage", function(battle, unit, target, _, _, crit)
            if crit and target.alive then
                Skills.runEffects(battle, unit, eff.onCrit, L, { slot = slot, target = target })
            end
        end)
    end
    if eff.onDodge then
        u:addTrigger("onDodge", function(battle, unit, attacker)
            if attacker and attacker.alive then
                Skills.runEffects(battle, unit, eff.onDodge, L, { slot = slot, target = attacker })
            end
        end)
    end
    if eff.cond then
        local owner = u
        owner.condBonus = owner.condBonus or {}
        local c = eff.cond
        owner.condBonus[#owner.condBonus + 1] = { statusAny = c.statusAny, fullHp = c.fullHp,
            critMult = c.critMult and (1 + scaled(c.critMult, L) / 100),
            critDmg = c.critDmg and scaled(c.critDmg, L) / 100,
            mult = c.mult and (1 + scaled(c.mult, L) / 100) }
    end
    if eff.leech then
        local pct = scaled(eff.leech.pct, L) / 100
        local function leech(battle, unit, _, dmg, spec)
            if eff.leech.elem and (not spec or spec.elem ~= eff.leech.elem) then return end
            local amount = dmg * pct
            if eff.leech.party then
                local list = T.allies(battle, unit, unit.x, nil, true, {})
                for i = 1, #list do battle:heal(unit, list[i], amount / #list, true) end
            else
                battle:heal(unit, unit, amount, true)
            end
        end
        if not eff.leech.dotOnly then u:addTrigger("onDealDamage", leech) end
        u:addTrigger("onDotTick", leech)
    end
    if eff.dotDouble then
        -- 지속 피해 틱이 일정 확률로 2배: 기대값으로 반영한다.
        u.dotMult = 1 + scaled(eff.dotDouble, L) / 100
    end
    if eff.lethal then
        local l = eff.lethal
        local key = def.id
        local function save(battle, unit)
            if unit.cheatUsed[key] then return false end
            if not u.alive and unit ~= u then return false end
            unit.cheatUsed[key] = true
            if l.pct then unit.hp = unit:get("MaxHp") * scaled(l.pct, L) / 100 else unit.hp = 1 end
            if l.shieldPct then
                battle:addShield(u, unit, unit:get("MaxHp") * scaled(l.shieldPct, L) / 100, l.shieldDur or 3,
                    "shield:" .. key)
            end
            battle:emit("cheatDeath", unit, slot.def)
            return true
        end
        if l.party then
            b.partyLethal = b.partyLethal or {}
            b.partyLethal[#b.partyLethal + 1] = function(battle, unit)
                if unit.team ~= u.team or unit.kind ~= "hero" then return false end
                return save(battle, unit)
            end
        else
            u:addTrigger("onLethal", save)
        end
    end
    if eff.special then
        local fn = Skills.special[eff.special]
        if not fn then error("등록되지 않은 특수 효과: " .. tostring(eff.special)) end
        fn(b, u, eff, L, { slot = slot, install = true })
    end
end

------------------------------------------------------------------------
-- 장착, 충전, 시전
------------------------------------------------------------------------

-- 유닛에 스킬을 장착한다. 오라와 상시 소환은 바로 적용된다.
function Skills.equip(b, u, def, level)
    local slot = { def = def, level = level or 1, charge = def.act.cd or 0, count = 0 }
    u.skills[#u.skills + 1] = slot
    local L = effLevel(u, slot)
    if def.act.type == "aura" then
        for i = 1, #def.effects do
            local eff = def.effects[i]
            if eff.type == "aura" then
                installAura(b, u, slot, eff, L)
            elseif eff.type == "summon" then
                exec.summon(b, u, eff, L, { slot = slot })
            elseif eff.type == "zone" then
                exec.zone(b, u, eff, L, { slot = slot })
            else
                error("오라 스킬에 쓸 수 없는 효과: " .. tostring(eff.type) .. " (" .. def.id .. ")")
            end
        end
    end
    return slot
end

-- 스킬 하나를 실행한다(조건과 대상은 호출하는 쪽이 확인했다고 본다).
function Skills.cast(b, u, slot, target)
    local def = slot.def
    local L = effLevel(u, slot)
    local ctx = { slot = slot, target = target }
    b:emit("cast", u, def, target)
    Skills.runEffects(b, u, def.effects, L, ctx)
    u.stats.casts = (u.stats.casts or 0) + 1
end

local function skillRange(u, def)
    local r = def.range or (u.range + 50)
    return r * (u.statOwner or u):get("SkillRangeExpansion")
end

-- 대상 규칙에 따라 대상을 찾고 사용 조건을 확인한다. 쓸 수 있으면 대상을 돌려준다.
function Skills.findTarget(b, u, slot)
    local def = slot.def
    local rule = def.target
    local target
    if rule == "none" then
        target = u
    elseif rule == "lowestHpAlly" or rule == "lowestHpHero" or rule == "deadAlly" or rule == "highestAdAlly"
        or rule == "self" then
        if def.targetFilter then
            target = T.lowestHpAlly(b, u, true, function(o) return def.targetFilter(b, u, o) end)
        else
            target = T.pick(b, u, rule)
        end
    else
        target = T.pick(b, u, rule, skillRange(u, def), def.clusterRadius)
    end
    if not target then return nil end
    if not Skills.condition(b, u, def.cond, target) then return nil end
    return target
end

-- 매 틱: 재사용 충전, 상시 소환의 재소환, 준비된 재사용 스킬 사용. 스킬을 썼으면 참.
function Skills.update(b, u, canCast)
    local skills = u.skills
    if #skills == 0 then return false end
    local rate
    for i = 1, #skills do
        local slot = skills[i]
        local act = slot.def.act
        if act.type == "cd" then
            if slot.charge < act.cd then
                if not rate then
                    local owner = u.statOwner or u
                    rate = owner:get("CastSpeed") / (1 - owner:get("CooldownReduction"))
                end
                slot.charge = slot.charge + TICK * rate
            end
        elseif slot.respawnAt and b.time >= slot.respawnAt then
            slot.respawnAt = nil
            for j = 1, #slot.def.effects do
                local eff = slot.def.effects[j]
                if eff.type == "summon" and eff.permanent then
                    exec.summon(b, u, eff, effLevel(u, slot), { slot = slot })
                end
            end
        end
    end
    if canCast == false or u.lock > 0 then return false end
    for i = 1, #skills do
        local slot = skills[i]
        local act = slot.def.act
        if act.type == "cd" and slot.charge >= act.cd - 1e-9 then
            local target = Skills.findTarget(b, u, slot)
            if target then
                slot.charge = 0
                Skills.cast(b, u, slot, target)
                u.lock = CAST_TIME / (u.statOwner or u):get("CastSpeed")
                return true
            end
        end
    end
    return false
end

-- 기본 공격 한 번. 연속 타격, 추가 투사체, 광역 기본 공격, "N타" 스킬, 발동 효과를 처리한다.
function Skills.basicAttack(b, u, target)
    local owner = u.statOwner or u
    local coef = u.basicCoef or 1
    local delivery = u.basicDelivery
    local melee, proj = delivery == "melee", delivery == "proj"
    local hits = 1 + (u.kind ~= "summon" and owner:get("Multistrike") or 0)
    b:emit("attack", u, target)

    local cleave
    for i = 1, #u.effects do
        if u.effects[i].cleave then cleave = u.effects[i].cleave end
    end

    for _ = 1, hits do
        if not target.alive then break end
        local spec = { coef = coef, elem = u.basicElem, melee = melee, proj = proj, isBasic = true,
            aoe = u.basicArea ~= nil }
        applyBonuses(u, target, spec)
        consumeNext(owner, spec, false)
        if u.basicArea then
            local list, n = T.enemiesAround(b, u, target.x, areaRadius(u, u.basicArea), {})
            for i = 1, n do
                b:hit(u, list[i], { coef = coef, elem = u.basicElem, melee = melee, proj = proj, aoe = true, isBasic = true })
            end
        else
            b:hit(u, target, spec)
        end
        if cleave then
            local list, n = T.enemiesAround(b, u, target.x, ADJACENT_RANGE, {})
            for i = 1, n do
                if list[i] ~= target then
                    b:hit(u, list[i], { coef = coef * cleave, elem = u.basicElem, melee = melee, proj = proj })
                    break
                end
            end
        end
    end

    if proj and u.kind ~= "summon" then
        local extra = owner:get("ProjectileCount")
        if extra > 0 then
            local list, n = T.enemiesAround(b, u, target.x, 600, {})
            local sent = 0
            for i = 1, n do
                if sent >= extra then break end
                if list[i] ~= target then
                    sent = sent + 1
                    b:hit(u, list[i], { coef = coef, elem = u.basicElem, proj = true, isBasic = true })
                end
            end
            while sent < extra and target.alive do
                sent = sent + 1
                b:hit(u, target, { coef = coef, elem = u.basicElem, proj = true, isBasic = true })
            end
        end
    end

    -- 공격 횟수로 유지되는 버프(질풍 등) 소모
    for i = #u.effects, 1, -1 do
        local e = u.effects[i]
        if e.attacksLeft then
            e.attacksLeft = e.attacksLeft - 1
            if e.attacksLeft <= 0 then b:removeEffect(u, e) end
        end
    end

    runTriggers(b, u, "onBasicAttack", target)

    -- "기본공격 N회마다" 스킬
    local skills = u.skills
    for i = 1, #skills do
        local slot = skills[i]
        local act = slot.def.act
        if act.type == "count" then
            slot.count = slot.count + 1
            local need = act.n - owner:get("BaseAttackCountReduction")
            if need < 1 then need = 1 end
            if slot.count >= need then
                local t = Skills.findTarget(b, u, slot)
                if t then
                    slot.count = 0
                    Skills.cast(b, u, slot, t)
                end
            end
        end
    end
end

Skills.CAST_TIME = CAST_TIME
Skills.resolveMods = resolveMods
Skills.installAura = installAura

return Skills
