-- 전투 한 판의 상태와 진행. 틱마다 효과 갱신 → 영역·소환물 → 각 유닛의 행동 순으로 처리한다.
-- 피해 계산 순서는 원작과 같다(docs/design/01-system-design.md 4.3, 4.4절).

local _, WIH = ...
local Stats = WIH.module("Stats")
local Rng = WIH.module("Rng")
local Battle = WIH.module("Battle")

local B = {}
B.__index = B
Battle.methods = B

local TICK = WIH.TICK
local MOVE_FACTOR = 0.25          -- [독자] 초당 이동 거리 = 이동속도 × 0.25
local DOT_INTERVAL = 0.5          -- [독자] 지속 피해·지속 회복의 틱 간격
local AURA_INTERVAL = 0.5         -- 오라 범위 재판정 간격
local REDIRECT_CAP = 0.6          -- [독자] 대신 받기로 줄일 수 있는 피해의 최대 비율
local TIE_RANGE = 30              -- [독자] 이 거리 안의 차이는 같은 거리로 보고 편성 순서로 대상을 정한다

-- 상태 이상 정의 [원작: 지속·효과·재적용 규칙 / 독자: 지속 피해 계수]
local STATUS = {
    Chill  = { dur = 4.0, reapply = "refresh", mods = { { "AttackSpeed", Stats.MORE, -300 }, { "MovementSpeed", Stats.MORE, -300 } } },
    Freeze = { dur = 1.5, reapply = "ignore", disable = true, cc = true },
    Ignite = { dur = 4.0, reapply = "ignore", mods = { { "TakenFire", Stats.FLAT, 200 } }, dot = { elem = "Fire", coef = 0.25 } },
    Shock  = { dur = 6.0, reapply = "refresh", mods = { { "TakenLightning", Stats.FLAT, 200 } }, dot = { elem = "Lightning", coef = 0.20 } },
    Bleed  = { dur = 7.0, reapply = "ignore", mods = { { "TakenPhysical", Stats.FLAT, 200 } }, dot = { elem = "Physical", coef = 0.15 } },
    Stun   = { dur = 2.0, reapply = "refresh", disable = true, cc = true, mods = { { "TakenAll", Stats.FLAT, 100 } } },
}
Battle.STATUS = STATUS

-- opts: seed, stageLevel, resistPenalty(영웅 쪽 원소 저항에서 빼는 값), onEvent(함수)
function Battle.new(opts)
    opts = opts or {}
    local b = setmetatable({
        time = 0,
        tickCount = 0,
        rng = Rng.new(opts.seed or 1),
        stageLevel = opts.stageLevel or 1,
        resistPenalty = opts.resistPenalty or 0,
        units = {},          -- 살아 있거나 부활을 기다리는 모든 유닛
        zones = {},          -- 지면 영역
        auras = {},          -- 상시 오라 {owner, radius, who, mods, redirect, ...}
        listeners = {},
        auraTimer = 0,
        reviveDelay = opts.reviveDelay or 15,     -- [독자]
        reviveHp = opts.reviveHp or 0.5,          -- [독자]
        autoRevive = opts.autoRevive ~= false,
    }, B)
    if opts.onEvent then b.listeners[1] = opts.onEvent end
    return b
end

function B:emit(event, a, b, c, d, e, f)
    local ls = self.listeners
    for i = 1, #ls do ls[i](event, a, b, c, d, e, f) end
end

function B:addUnit(u)
    self.units[#self.units + 1] = u
    u.battle = self
    self.auraTimer = 0
    self:emit("spawn", u)
    return u
end

function B:removeUnit(u)
    local units = self.units
    for i = #units, 1, -1 do
        if units[i] == u then table.remove(units, i) end
    end
    u.alive = false
    self:emit("remove", u)
end

-- 한쪽 팀의 살아 있고 대상이 될 수 있는 유닛 목록
function B:living(team, out)
    out = out or {}
    local n = 0
    local units = self.units
    for i = 1, #units do
        local u = units[i]
        if u.alive and u.team == team and not u.noTarget then
            n = n + 1
            out[n] = u
        end
    end
    for i = n + 1, #out do out[i] = nil end
    return out
end

------------------------------------------------------------------------
-- 효과: 버프, 디버프, 상태 이상, 지속 피해·회복, 보호막
------------------------------------------------------------------------

-- e: id, src, kind, dur(초) 또는 attacks(기본 공격 횟수), mods, stacks, maxStacks, disable, untargetable,
--    dot = {elem, coef}  (틱당 계수), hot = {pct 또는 flat} (초당), amount(보호막), onExpire, triggers
function B:addEffect(dst, e)
    if not dst.alive then return nil end
    local old = dst:findEffect(e.id, e.perSource and e.src or nil)
    if old then
        if e.maxStacks and e.maxStacks > 1 then
            old.stacks = math.min((old.stacks or 1) + (e.addStacks or 1), e.maxStacks)
            old.expires = e.dur and (self.time + e.dur) or old.expires
            old.dot = e.dot or old.dot
            dst:invalidate()
            return old
        end
        self:removeEffect(dst, old, true)
    end
    e.stacks = e.stacks or 1
    if e.dur then e.expires = self.time + e.dur end
    if e.dot or e.hot then e.nextTick = self.time + DOT_INTERVAL end
    dst.effects[#dst.effects + 1] = e
    if e.triggers then
        for i = 1, #e.triggers do
            local t = e.triggers[i]
            dst:addTrigger(t[1], t[2])
        end
    end
    if e.mods then dst:invalidate() end
    self:emit("effect", dst, e, true)
    return e
end

function B:removeEffect(dst, e, silent)
    local effects = dst.effects
    for i = #effects, 1, -1 do
        if effects[i] == e then
            table.remove(effects, i)
            if e.triggers then
                for j = 1, #e.triggers do
                    dst:removeTrigger(e.triggers[j][1], e.triggers[j][2])
                end
            end
            if e.mods then dst:invalidate() end
            if not silent then
                if e.onExpire then e.onExpire(self, dst, e) end
                self:emit("effect", dst, e, false)
            end
            return true
        end
    end
    return false
end

function B:applyStatus(src, dst, name, durMult)
    local def = STATUS[name]
    if not def then error("알 수 없는 상태 이상: " .. tostring(name), 2) end
    if not dst.alive or dst.ccImmune and def.cc then return nil end
    local id = "status:" .. name
    local old = dst:findEffect(id)
    local dur = def.dur * (durMult or 1)
    if def.cc then
        if dst.isBoss then dur = dur * 0.5 end                      -- [독자] 보스는 행동 불가 지속 절반
        if dst.ccReduction then dur = dur * (1 - dst.ccReduction) end
        if dst.team == 1 then dur = dur * (1 - math.min(0.75, dst:get("CrowdControlDurationReduction"))) end
    end
    if old then
        if def.reapply == "ignore" then return old end
        old.expires = self.time + dur
        old.src = src
        return old
    end
    local e = { id = id, kind = "status", status = name, src = src, dur = dur, mods = def.mods, disable = def.disable }
    if def.dot then
        e.dot = { elem = def.dot.elem, coef = def.dot.coef }
    end
    return self:addEffect(dst, e)
end

-- 상태 이상 하나를 지운다(정화). 지웠으면 참.
function B:cleanse(dst)
    local effects = dst.effects
    for i = 1, #effects do
        local e = effects[i]
        if e.kind == "status" or e.harmful then
            self:removeEffect(dst, e)
            return true
        end
    end
    return false
end

function B:addShield(src, dst, amount, dur, id)
    if amount <= 0 or not dst.alive then return end
    self:addEffect(dst, { id = id or ("shield:" .. tostring(src and src.id)), kind = "shield", src = src,
        amount = amount, maxAmount = amount, dur = dur })
    if src then src.stats.shielded = src.stats.shielded + amount end
    self:emit("shield", src, dst, amount)
end

------------------------------------------------------------------------
-- 피해
------------------------------------------------------------------------

local function runTriggers(self, unit, event, a, b, c, d)
    local list = unit.triggers[event]
    if not list then return end
    for i = #list, 1, -1 do
        local h = list[i]
        if h then h(self, unit, a, b, c, d) end
    end
end
Battle.runTriggers = runTriggers

-- 공격자의 능력치로 타격 한 번의 피해를 계산해 대상에게 적용한다. 실제로 준 피해를 돌려준다.
-- spec: coef(배율), elem, melee/proj/aoe(전달 방식), canCrit, forceCrit, critDmgBonus, mult, isDot, isBasic, skill
function B:hit(src, dst, spec)
    if not dst.alive then return 0 end
    local off = src.statOwner or src
    local elem = spec.elem or "Physical"
    local rh = off.relic           -- 유물 공명이 거는 타격 규칙(Progression/Relics.lua). 없으면 nil
    local dmg = off:get("AttackDamage") * spec.coef
    dmg = dmg * (1 + off:get(elem .. "DamagePercent"))
    if rh then
        local elemental = elem == "Fire" or elem == "Cold" or elem == "Lightning"
        if rh.prism and elemental then           -- 처음 준 원소로 고정, 다른 원소는 주지 못한다
            if not rh.prismElem then rh.prismElem = elem end
            if elem ~= rh.prismElem then return 0 end
            dmg = dmg * (1 + rh.prism)
        end
        if rh.elemMult and rh.elemMult[elem] then dmg = dmg * rh.elemMult[elem] end
        if rh.twinborn and ((elem == "Cold" and dst:hasStatus("Ignite")) or (elem == "Fire" and dst:hasStatus("Chill"))) then
            dmg = dmg * (1 + rh.twinborn)
        end
        if rh.skillMult and spec.skill then dmg = dmg * rh.skillMult end
        if rh.convert and rh.convert[elem] then elem = "Chaos" end    -- 원래 원소의 피해 증가를 적용한 뒤 암흑으로
        if rh.corrupt and elem == "Chaos" then dmg = dmg * (1 + off:get("CriticalDamage") * rh.corrupt) end
    end
    if spec.melee then dmg = dmg * off:get("IncreaseMeleeDamage") end
    if spec.proj then dmg = dmg * off:get("IncreaseProjectileDamage") end
    if spec.aoe then dmg = dmg * off:get("IncreaseAreaOfEffectDamage") end
    if src.kind == "summon" then
        dmg = dmg * off:get("IncreaseSummonDamage") * src:get("DamageDealt")
    end
    dmg = dmg * off:get("DamageDealt")
    if spec.mult then dmg = dmg * spec.mult end
    -- 대상의 상태에 따른 피해 증가(유물) [원작 1.3.0 / 추정: 체력이 낮다 = 50% 이하]
    local fullHp = dst.hp >= dst:get("MaxHp") * 0.999
    if dst.isBoss then dmg = dmg * (1 + off:get("BossDamage")) end
    if fullHp then dmg = dmg * (1 + off:get("FullHpTargetDamage"))
    elseif dst:hpRatio() <= 0.5 then dmg = dmg * (1 + off:get("LowHpTargetDamage")) end

    local crit = false
    local canCrit = not spec.isDot and spec.canCrit ~= false
    -- 소환물은 주인의 치명타를 이어받지 않는다(동반자 공명이 있으면 이어받는다) [추정: 원작 유물 "Companion's Reliquary"]
    if src.kind == "summon" and not (rh and rh.summonCrit) then canCrit = false end
    if rh and rh.corrupt and elem == "Chaos" then canCrit = false end
    if canCrit then
        local chance = off:get("CriticalChance")
        if fullHp then chance = chance * (1 + off:get("FullHpTargetCriticalChance")) end
        if spec.critChanceMult then
            chance = chance * spec.critChanceMult
            if chance > 1 then chance = 1 end
        end
        local force = spec.forceCrit
        if rh and rh.onset and spec.skill then       -- 스테이지의 첫 공격 스킬은 확정 치명타
            if not rh.onsetSkill then rh.onsetSkill, rh.onsetUntil = spec.skill, self.time + 0.2 end
            if rh.onsetSkill == spec.skill and self.time <= rh.onsetUntil then force = true end
        end
        if force or self.rng:chance(chance) or (rh and rh.keen and self.rng:chance(chance)) then
            crit = true
            local bonus = spec.critDmgBonus or 0
            local frozen = rh and rh.icicle and dst:findEffect("status:Freeze")
            if frozen then bonus = bonus + rh.icicle end
            dmg = dmg * (off:get("CriticalDamage") + bonus)
            if frozen then self:removeEffect(dst, frozen) end       -- 치명타가 빙결을 깬다
        end
    end
    if not spec.isDot then
        dmg = dmg + off:get("DamageAddition") + off:get(elem .. "DamageAddition")
    end
    dmg = dmg * (1 + dst:get("TakenAll") + dst:get("Taken" .. elem))
    self.lastCrit = crit
    return self:receive(src, dst, dmg, elem, spec, crit)
end

-- 방어도에 의한 물리 피해 감소율 [원작]: A² / (A² + (14 × 스테이지 레벨 + 12) × (A + 0.4 × 피해)), 상한 근접 85% / 원거리 75%
function Battle.armorReduction(armor, dmg, stageLevel, melee)
    if armor <= 0 then return 0 end
    local k = 14 * stageLevel + 12
    local reduction = armor * armor / (armor * armor + k * (armor + 0.4 * dmg))
    local cap = melee and Stats.CAP_ARMOR_MELEE or Stats.CAP_ARMOR_RANGED
    if reduction > cap then reduction = cap end
    return reduction
end

-- 대상 쪽 계산: 대신 받기 → 회피 → 막기 → 방어도/저항 → 피해 감소 → 흡수 → 최소 1 → 보호막 → 체력
function B:receive(src, dst, dmg, elem, spec, crit)
    if not dst.alive then return 0 end
    spec = spec or {}

    if not spec.redirected and dst.team == 1 then
        dmg = self:redirect(src, dst, dmg, elem, spec)
    end

    local physical = elem == "Physical"
    local blocked = false
    if not spec.isDot and not spec.noAvoid then
        local dodge = physical and dst:get("DodgeChance") or dst:get("ElementalDodgeChance")
        if dodge > 0 and self.rng:chance(dodge) then
            self:emit("dodge", src, dst)
            runTriggers(self, dst, "onDodge", src, spec)
            return 0
        end
        local block = physical and dst:get("BlockChance") or dst:get("ElementalBlockChance")
        if block > 0 and self.rng:chance(block) then
            blocked = true
            dmg = dmg * (1 - (dst.blockReduce or 0.5))
        end
    end

    if physical then
        dmg = dmg * (1 - Battle.armorReduction(dst:get("Armor"), dmg, self.stageLevel, dst.melee))
    else
        local res = dst:get(elem .. "Resistance")
        local rule = dst.resistRule              -- 장비 고유 능력치: 가장 높은 원소 저항을 쓴다
        if rule and (elem ~= "Chaos" and rule == "unify" or elem == "Chaos" and rule == "chaos") then
            res = math.max(dst:get("FireResistance"), dst:get("ColdResistance"), dst:get("LightningResistance"))
        end
        if elem ~= "Chaos" then res = res + dst:get("AllElementalResistance") end
        if dst.team == 1 then res = res - self.resistPenalty end
        local maxRes = dst:get("Max" .. elem .. "Resistance")
        if elem ~= "Chaos" then maxRes = maxRes + dst:get("MaxAllElementalResistance") end
        if res > maxRes then res = maxRes end
        dmg = dmg * (1 - res / 100)
    end

    dmg = dmg * (1 - dst:get("DamageReduction"))
    if dst.team == 1 and dst:hpRatio() <= 0.5 then dmg = dmg * (1 - dst:get("LowHpDamageReduction")) end
    local elemReduction = dst:get(elem .. "DamageReduction")
    if elemReduction > Stats.CAP_DAMAGE_REDUCTION then elemReduction = Stats.CAP_DAMAGE_REDUCTION end
    dmg = dmg * (1 - elemReduction)

    if not spec.isDot then
        local absorb = dst:get("DamageAbsorption") + self:zoneAbsorb(dst)
        dmg = dmg - absorb
    end
    if dst.team == 1 and #self.zones > 0 then dmg = dmg * (1 - self:zoneDR(dst)) end
    if dst.hitCap then
        local cap = dst:get("MaxHp") * dst.hitCap
        if dmg > cap then dmg = cap end
    end
    if dmg < 1 then dmg = 1 end

    -- 보호막이 먼저 흡수한다. 만료가 가까운 것부터.
    local remaining = dmg
    local effects = dst.effects
    if #effects > 0 then
        for i = 1, #effects do
            local e = effects[i]
            if e.kind == "shield" and e.amount > 0 and remaining > 0 then
                local take = e.amount < remaining and e.amount or remaining
                e.amount = e.amount - take
                remaining = remaining - take
                if e.amount <= 0 then e.broken = true end
            end
        end
        for i = #effects, 1, -1 do
            local e = effects[i]
            if e.broken then self:removeEffect(dst, e) end
        end
    end

    dst.hp = dst.hp - remaining
    dst.stats.taken = dst.stats.taken + dmg
    local owner = src and (src.statOwner or src)
    if owner then owner.stats.dealt = owner.stats.dealt + dmg end
    self:emit("damage", src, dst, dmg, elem, crit, blocked)

    if src and src.alive ~= nil and not spec.isReflect then
        if blocked then runTriggers(self, dst, "onBlock", src, dmg, spec) end
        runTriggers(self, dst, "onHitTaken", src, dmg, spec, elem)
        local hooks = self.allyHitHooks
        if hooks then
            for i = 1, #hooks do
                local h = hooks[i]
                if h.team == dst.team and h.owner.alive then h.fn(self, dst, src, dmg, spec) end
            end
        end
        if not spec.isDot then
            -- 공격자 쪽 회복과 발동 효과
            local leech = owner:get("HpLeech") + (spec.leech or 0)
            if leech > 0 then self:selfHeal(owner, dmg * leech) end
            local perHit = owner:get("AddHpPerHit")
            if perHit > 0 then self:selfHeal(owner, perHit) end
            runTriggers(self, owner, "onDealDamage", dst, dmg, spec, crit)
        else
            runTriggers(self, owner, "onDotTick", dst, dmg, spec)
        end
    end

    if dst.hp <= 0 then self:lethal(src, dst, spec) end
    return dmg
end

-- 대신 받기(보호 오라). 줄어든 피해를 돌려준다.
function B:redirect(src, dst, dmg, elem, spec)
    local auras = self.auras
    local redirected = 0
    for i = 1, #auras do
        local a = auras[i]
        local r = a.redirect
        if r and a.owner.alive and redirected < REDIRECT_CAP then
            local owner = a.owner
            local applies = false
            local receiver = owner
            if r.mode == "allies" then
                applies = owner ~= dst and math.abs(owner.x - dst.x) <= a.radius
            elseif r.mode == "ranged" then
                applies = owner ~= dst and spec.proj and math.abs(owner.x - dst.x) <= a.radius
            elseif r.mode == "lowest" then
                applies = owner ~= dst and a.currentTarget == dst
            elseif r.mode == "toSummon" then
                receiver = a.currentSummon
                applies = owner == dst and receiver ~= nil and receiver.alive
            elseif r.mode == "share" then
                -- 받는 피해를 다른 파티원이 나눠 받는다(장비 고유 능력치)
                if owner == dst then
                    local others = {}
                    for _, o in ipairs(self.units) do
                        if o.alive and o.team == dst.team and o ~= dst and o.kind == "hero" then others[#others + 1] = o end
                    end
                    if #others > 0 then
                        local pct = r.pct
                        if redirected + pct > REDIRECT_CAP then pct = REDIRECT_CAP - redirected end
                        redirected = redirected + pct
                        for _, o in ipairs(others) do
                            self:receive(src, o, dmg * pct / #others, elem, { redirected = true, noAvoid = true, isDot = spec.isDot })
                        end
                    end
                end
            end
            if applies then
                local pct = r.pct
                if redirected + pct > REDIRECT_CAP then pct = REDIRECT_CAP - redirected end
                redirected = redirected + pct
                self:receive(src, receiver, dmg * pct, elem,
                    { redirected = true, noAvoid = true, isDot = spec.isDot, proj = spec.proj })
            end
        end
    end
    if redirected > 0 then dmg = dmg * (1 - redirected) end
    return dmg
end

-- 대상이 서 있는 흡수 영역(강철 방벽 등)의 타격당 흡수량 합
function B:zoneAbsorb(dst)
    local zones = self.zones
    local total = 0
    for i = 1, #zones do
        local z = zones[i]
        if z.absorb and z.team == dst.team and math.abs(z.x - dst.x) <= z.radius then
            total = total + z.absorb
        end
    end
    return total
end

-- 대상이 서 있는 아군 영역이 주는 피해 감소(장비 고유 능력치). 가장 큰 것 하나만.
function B:zoneDR(dst)
    local best = 0
    for i = 1, #self.zones do
        local z = self.zones[i]
        if z.dr and z.team == dst.team and math.abs(z.x - dst.x) <= z.radius and z.dr > best then best = z.dr end
    end
    return best > 0.75 and 0.75 or best
end

function B:lethal(src, dst, spec)
    if not dst.alive then return end
    -- 빈사 회피(최후의 저항, 생명 유지 시스템 등)
    local list = dst.triggers.onLethal
    if list then
        for i = 1, #list do
            if list[i](self, dst, src) then
                if dst.hp < 1 then dst.hp = 1 end
                return
            end
        end
    end
    local party = self.partyLethal
    if party then
        for i = 1, #party do
            if party[i](self, dst, src) then
                if dst.hp < 1 then dst.hp = 1 end
                return
            end
        end
    end
    self:kill(src, dst)
end

function B:kill(src, dst)
    if not dst.alive then return end
    dst.alive = false
    dst.hp = 0
    dst.stats.deaths = dst.stats.deaths + 1
    dst.diedAt = self.time
    -- 죽을 때 걸려 있던 상태 이상(처치 조건 효과가 본다)
    local had = {}
    for i = 1, #dst.effects do if dst.effects[i].status then had[dst.effects[i].status] = true end end
    dst.diedWith = had
    -- 효과 정리. onExpire는 부르지 않는다.
    for i = #dst.effects, 1, -1 do
        self:removeEffect(dst, dst.effects[i], true)
    end
    dst.auraMods = {}
    dst:invalidate()
    self.auraTimer = 0
    local owner = src and (src.statOwner or src)
    if owner and owner ~= dst then
        owner.stats.kills = owner.stats.kills + 1
        if owner.alive then
            local perKill = owner:get("AddHpPerKill")
            if perKill > 0 then self:selfHeal(owner, perKill) end
            runTriggers(self, owner, "onKill", dst)
        end
    end
    self:emit("death", dst, src)
    if dst.onDeath then dst.onDeath(self, dst, src) end
end

-- 회복. raw가 참이면 회복량 증가를 적용하지 않는다(흡혈, 재생 등).
function B:heal(src, dst, amount, raw)
    if not dst.alive or amount <= 0 then return 0 end
    if not raw and src then amount = amount * (src.statOwner or src):get("SkillHealIncrease") end
    local taken = dst:get("HealingTaken")
    if taken ~= 1 then
        if taken < 0 then taken = 0 end
        amount = amount * taken
    end
    local maxHp = dst:get("MaxHp")
    local before = dst.hp
    dst.hp = dst.hp + amount
    if dst.hp > maxHp then dst.hp = maxHp end
    local done = dst.hp - before
    if done > 0 then
        local owner = src and (src.statOwner or src)
        if owner then owner.stats.healed = owner.stats.healed + done end
        self:emit("heal", src, dst, done)
    end
    return done
end

-- 흡혈·타격 회복·처치 회복. 최대 체력을 넘친 양은 "overheal" 사건으로 알린다(맹세 공명).
function B:selfHeal(u, amount)
    if not u.alive or amount <= 0 then return 0 end
    local done = self:heal(u, u, amount, true)
    if amount - done > 1e-9 then self:emit("overheal", u, amount - done) end
    return done
end

function B:revive(dst, hpPct)
    if dst.alive then return false end
    dst.alive = true
    dst.diedAt = nil
    dst:invalidate()
    dst.hp = dst:get("MaxHp") * (hpPct or self.reviveHp)
    dst.attackCharge = 0.5
    dst.lock = 0
    dst.noTarget = dst.def and dst.def.noTarget or false
    dst.ccImmune = false
    dst.nextHit = nil
    self.auraTimer = 0
    local bonus = dst:get("OnReviveAttackDamage")
    if bonus > 0 then       -- 부활 직후 10초 동안 공격력 증가(유물) [추정: 지속시간]
        self:addEffect(dst, { id = "reviveFury", kind = "buff", dur = 10, mods = { { "AttackDamage", 2, bonus * 1000 } } })
    end
    self:emit("revive", dst)
    runTriggers(self, dst, "onRevive")
    return true
end

------------------------------------------------------------------------
-- 지면 영역
------------------------------------------------------------------------

-- z: owner, team(혜택 또는 피해를 받는 쪽은 tick 함수가 정한다), x, radius, dur, every(초), tick(함수), absorb, follow
function B:addZone(z)
    z.expires = self.time + z.dur
    z.next = self.time + (z.every or 1)
    self.zones[#self.zones + 1] = z
    self:emit("zone", z, true)
    return z
end

------------------------------------------------------------------------
-- 오라
------------------------------------------------------------------------

function B:addAura(a)
    self.auras[#self.auras + 1] = a
    self.auraTimer = 0
    return a
end

function B:removeAurasOf(owner)
    local auras = self.auras
    for i = #auras, 1, -1 do
        if auras[i].owner == owner or auras[i].holder == owner then table.remove(auras, i) end
    end
    self.auraTimer = 0
end

-- 오라의 범위 안 유닛에게 수정치를 다시 나눠 준다.
function B:refreshAuras()
    local units = self.units
    for i = 1, #units do
        local u = units[i]
        if #u.auraMods > 0 then
            u.auraMods = {}
            u.dirty = true
        end
    end
    local auras = self.auras
    for i = #auras, 1, -1 do
        local a = auras[i]
        local owner = a.owner
        if a.expires and a.expires <= self.time then
            table.remove(auras, i)
        elseif owner.alive then
            if a.update then a.update(self, a) end
            if a.mods then
                local ax = a.holder and a.holder.x or owner.x
                for j = 1, #units do
                    local u = units[j]
                    if u.alive then
                        local match = false
                        if a.who == "self" then
                            match = u == owner
                        elseif a.who == "allies" then
                            match = u.team == owner.team and (a.includeSummons or u.kind ~= "summon")
                        elseif a.who == "meleeAllies" then
                            match = u.team == owner.team and u.melee and u.kind ~= "summon"
                        elseif a.who == "summons" then
                            match = u.kind == "summon" and u.owner == owner
                        elseif a.who == "enemies" then
                            match = u.team ~= owner.team
                        end
                        if match and (a.who == "self" or a.who == "summons" or math.abs(u.x - ax) <= a.radius) then
                            local list = u.auraMods
                            for k = 1, #a.mods do list[#list + 1] = a.mods[k] end
                            u.dirty = true
                        end
                    end
                end
            end
        end
    end
end

------------------------------------------------------------------------
-- 틱 진행
------------------------------------------------------------------------

local function tickEffects(self, u)
    local effects = u.effects
    local now = self.time
    for i = #effects, 1, -1 do
        local e = effects[i]
        if e then
            if e.nextTick and now >= e.nextTick and u.alive then
                e.nextTick = e.nextTick + DOT_INTERVAL
                if e.dot then
                    local src = e.src
                    if src then
                        self:hit(src, u, { coef = e.dot.coef * (e.stacks or 1), elem = e.dot.elem, isDot = true,
                            canCrit = false, mult = e.dot.mult, skill = e.skill })
                    end
                elseif e.hot then
                    local amount
                    if e.hot.pct then
                        amount = u:get("MaxHp") * e.hot.pct * DOT_INTERVAL
                    else
                        amount = e.hot.flat * DOT_INTERVAL
                    end
                    self:heal(e.src, u, amount)
                end
            end
            if u.alive and e.expires and now >= e.expires and effects[i] == e then
                self:removeEffect(u, e)
            end
        end
    end
end

function B:step()
    self.time = self.time + TICK
    self.tickCount = self.tickCount + 1
    local now = self.time
    local units = self.units

    -- 1. 오라 재판정
    self.auraTimer = self.auraTimer - TICK
    if self.auraTimer <= 0 then
        self.auraTimer = AURA_INTERVAL
        self:refreshAuras()
    end

    -- 2. 효과 갱신, 재생, 소환물 수명, 자동 부활
    for i = 1, #units do
        local u = units[i]
        if u and u.alive then
            if #u.effects > 0 then tickEffects(self, u) end
            if u.alive then
                local regen = u:get("HpRegenPerSec")
                if regen > 0 and u.hp < u:get("MaxHp") then
                    u.hp = u.hp + regen * TICK
                    local m = u:get("MaxHp")
                    if u.hp > m then u.hp = m end
                end
                if u.expires and now >= u.expires then
                    u.alive = false
                    u.expired = true
                    self:emit("expire", u)
                end
            end
        elseif u and u.kind == "hero" and self.autoRevive and u.diedAt
            and now - u.diedAt >= self.reviveDelay * (1 - math.min(0.75, u:get("ReviveCooldownReduction"))) then
            self:revive(u)
        end
    end

    -- 3. 지면 영역
    local zones = self.zones
    for i = #zones, 1, -1 do
        local z = zones[i]
        if z.follow and z.follow.alive then z.x = z.follow.x end
        if now >= z.next then
            z.next = z.next + (z.every or 1)
            if z.tick then z.tick(self, z) end
        end
        if now >= z.expires or (z.owner and z.requireOwner and not z.owner.alive) then
            table.remove(zones, i)
            self:emit("zone", z, false)
        end
    end

    -- 4. 유닛 행동. 목록을 복사하지 않고, 도중에 추가된 유닛은 다음 틱부터 행동한다.
    local n = #units
    local act = WIH.AI and WIH.AI.act
    for i = 1, n do
        local u = units[i]
        if u and u.alive and act then
            if u.lock > 0 then
                u.lock = u.lock - TICK
            end
            act(self, u)
        end
    end

    -- 5. 수명이 끝났거나 죽은 소환물·몬스터 정리 (영웅은 부활을 위해 남긴다)
    for i = #units, 1, -1 do
        local u = units[i]
        if not u.alive and u.kind ~= "hero" then
            table.remove(units, i)
            if u.onRemove then u.onRemove(self, u) end
            self:removeAurasOf(u)
            self:emit("remove", u)
        end
    end
end

function B:run(seconds, stopFn)
    local ticks = math.floor(seconds / TICK + 0.5)
    for _ = 1, ticks do
        self:step()
        if stopFn and stopFn(self) then return true end
    end
    return false
end

-- 팀의 살아 있는 유닛 수(소환물 제외 여부 선택)
function B:count(team, heroesOnly)
    local n = 0
    local units = self.units
    for i = 1, #units do
        local u = units[i]
        if u.alive and u.team == team and (not heroesOnly or u.kind ~= "summon") then n = n + 1 end
    end
    return n
end

Battle.MOVE_FACTOR = MOVE_FACTOR
Battle.TIE_RANGE = TIE_RANGE
Battle.DOT_INTERVAL = DOT_INTERVAL

return Battle
