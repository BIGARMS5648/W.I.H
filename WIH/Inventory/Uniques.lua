-- 고유 능력치: 원작에서 아르카나 이상 일부 장비(116개)에 하나씩 고정으로 붙는 특수 효과. [원작 v1.3.0: 붙는 장비와 수치]
--   · 원작의 고유 능력치는 대부분 "특정 직업의 특정 스킬"을 바꾼다. 이 프로젝트의 영웅과 스킬은 원작과 다르므로,
--     스킬을 가리키는 것은 **착용한 영웅의 같은 순번 스킬**(원작 스킬 번호의 순번)에 건다. 원작이 스킬 이름으로 가리키는 것은
--     같은 성격의 스킬(첫 재사용 공격 스킬, 첫 광역 공격 스킬, 그 원소의 공격 스킬 등)에 건다. [독자]
--   · 원작 43종을 이 엔진이 다루는 일반 규칙 약 25가지로 옮겼다. 원작 설명이 확인되지 않은 수치는 [추정]이다.
-- 데이터: Data/UniqueTable.lua(원작 그대로의 종류와 인자). 이 파일은 해석과 적용을 맡는다.

local _, WIH = ...
local Stats = WIH.module("Stats")
local Sheet = WIH.module("Sheet")
local Items = WIH.module("Items")
local UniqueTable = WIH.module("UniqueTable")
local Uniques = WIH.module("Uniques")

local F, I = Stats.FLAT, Stats.INC
local ELEM_NAMES = { Physical = "물리", Fire = "화염", Cold = "냉기", Lightning = "번개", Chaos = "암흑" }
local STATUS_NAMES = { Chill = "냉각", Freeze = "빙결", Ignite = "점화", Shock = "감전", Bleed = "출혈", Stun = "기절" }

-- 원작 스킬 번호 → 순번(1~6). 순번 자리가 0이거나 번호가 작으면 "모든 스킬"
local function idx(key)
    key = tonumber(key) or 0
    if key < 1000 then return "all" end
    local i = math.floor(key / 100) % 100
    return i == 0 and "all" or i
end

-- 원작 종류 → 이 프로젝트의 규칙
local NORMAL = {
    SkillCooldownReduce = function(p) return { kind = "skillCd", idx = idx(p[1]), pct = p[2] } end,
    CrossbowTurretCooldown = function(p) return { kind = "skillCd", idx = "summon", pct = p[1] } end,
    ChargeTrapExplosiveCooldown = function() return { kind = "skillCd", idx = "trap", pct = 0.5 } end,             -- [추정: 원작 인자 0]
    ExplosiveBoltHalf = function(p) return { kind = "skillHalf", idx = "firstCdAttack", cd = p[1], power = p[2] } end,
    SanctuaryHalf = function(p) return { kind = "skillHalf", idx = "firstCd", cd = p[1], power = p[2] } end,
    SkillBaseAttackCountReduce = function(p) return { kind = "skillCount", idx = idx(p[1]), n = p[2] } end,
    GroundSlamRockBaseAttackReduce = function(p) return { kind = "skillCount", idx = "firstCount", n = p[1] } end,
    SkillMultiStrikeCountUp = function(p) return { kind = "skillHits", idx = idx(p[1]), n = p[2] } end,
    SkillProjectileCountUp = function(p) return { kind = "skillHits", idx = idx(p[1]), n = p[2], proj = true } end,
    SkillElementChange = function(p) return { kind = "skillElem", idx = idx(p[1]), elem = p[2] } end,
    SkillTrapAddAmount = function(p) return { kind = "trapMax", idx = idx(p[1]), n = p[2] } end,
    CrossbowTurretAddAmount = function(p) return { kind = "summonMax", idx = "summon", n = p[1] } end,
    BaseAttackCastFrostBolt = function(p) return { kind = "basicCast", idx = idx(p[2]), chance = p[1] } end,
    BaseAttackCastExplosiveBolt = function(p) return { kind = "basicCast", idx = idx(p[2]), chance = p[1] } end,
    SkillRangeUp = function(p) return { kind = "skillRange", idx = idx(p[1]), pct = p[2] } end,
    SkillLifeStealUp = function(p) return { kind = "skillLeech", idx = idx(p[1]), mult = p[2] } end,
    StatValueUp = function(p) return { kind = "stat", stat = p[1] } end,
    ShieldChargeKillCooldown = function() return { kind = "killReset", idx = "firstCdAttack" } end,
    WrathOfHeavenKillCooldown = function() return { kind = "killReset", idx = "firstAoe" } end,
    IceOrbFreezeToCold = function(p) return { kind = "skillStatus", idx = "elem:Cold", status = "Chill", chance = 1, mult = 1 + p[1] } end,
    SorcererLightningShock = function() return { kind = "skillStatus", idx = "elem:Lightning", status = "Shock", chance = 1 } end,
    WhirlwindFireIgnite = function() return { kind = "skillStatus", idx = "firstAoe", status = "Ignite", chance = 1, elem = "Fire" } end,
    AxeSpinBleedingChance = function(p) return { kind = "skillStatus", idx = "firstAoe", status = "Bleed", chance = p[1] } end,
    SkewerShotBleedingStrike = function(p) return { kind = "skillVsStatus", idx = "firstCdAttack", status = "Bleed", pct = p[1] } end,
    SnowstormEnhanceFrozenEnemy = function(p) return { kind = "skillVsStatus", idx = "elem:Cold", status = "Freeze", pct = p[1] } end,
    ArrowRainCriticalCooldown = function(p) return { kind = "critCdr", idx = "firstAoe", sec = p[1] } end,
    WrathOfHeavenHeal = function() return { kind = "skillHeal", idx = "firstAoe", pct = 0.1 } end,                  -- [독자: 수치]
    AxeSpinBleedKillDurationUp = function(p) return { kind = "bleedKillExtend", sec = p[1] } end,
    SlayerLowHpAttackSpeed = function(p) return { kind = "lowHpAS", per = p[1] } end,
    FlameHydraBerserk = function(p) return { kind = "summonFrenzy", as = p[2] } end,                                 -- [근사]
    AegisFieldAbsorbUp = function(p) return { kind = "zoneAbsorb", pct = (tonumber(p[1]) or 0) / 1000 } end,
    AegisFieldFollowOwner = function() return { kind = "zoneFollow" } end,
    SanctuaryDamageReduce = function(p) return { kind = "zoneDR", pct = p[1] } end,
    BlessingOfWardingElementBlock = function(p) return { kind = "partyStat", stat = { "ElementalBlockChance", F, p[1] * 1000 } } end,
    TakeAllyDamageInstead = function(p) return { kind = "redirect", pct = p[1] } end,
    ShareTakenDamageToParty = function(p) return { kind = "share", pct = p[1] } end,
    SingleHitDamageCap = function(p) return { kind = "hitCap", pct = p[1] } end,
    BlockDamageReductionUp = function(p) return { kind = "blockReduce", pct = p[1] } end,
    ChaosResistFromHighestElement = function() return { kind = "resist", rule = "chaos" } end,
    ElementResistUnifyToHighest = function() return { kind = "resist", rule = "unify" } end,
    WaveMoveFastestPartyMember = function() return { kind = "pace", rule = "fastest" } end,
    WaveMoveAveragePartyMember = function() return { kind = "pace", rule = "average" } end,
    WaveMoveSlowestPartyExcludeSelf = function() return { kind = "pace", rule = "exceptSelf" } end,
}
Uniques.NORMAL = NORMAL

-- 아이템마다 고유 능력치를 붙인다(같은 곡선을 쓰는 이 프로젝트의 장비 종류 모두).
Uniques.byItem = {}
Uniques.unknown = {}
do
    local byCurve = {}
    for typeId, t in pairs(Items.TYPES) do
        byCurve[t.curve] = byCurve[t.curve] or {}
        table.insert(byCurve[t.curve], typeId)
    end
    for _, row in ipairs(UniqueTable.items) do
        local curve, level, grade, variant, key, params = row[1], row[2], row[3], row[4], row[5], row[6]
        local make = NORMAL[key]
        if make then
            for _, typeId in ipairs(byCurve[curve] or {}) do
                local item = Items.find(typeId, level, grade, variant)
                if item then
                    local mod = make(params)
                    mod.source = key
                    Uniques.byItem[item.id] = mod
                    item.unique = mod
                end
            end
        else
            Uniques.unknown[#Uniques.unknown + 1] = key
        end
    end
end

------------------------------------------------------------------------
-- 표기
------------------------------------------------------------------------

local function has(def, t)
    for _, eff in ipairs(def.effects or {}) do if eff.type == t then return true end end
    return false
end

local function pct(v) return string.format("%g%%", (tonumber(v) or 0) * 100) end

-- 스킬을 가리키는 말. heroId를 주면 그 영웅의 스킬 이름으로.
local function skillWord(mod, heroId)
    local i = mod.idx
    if type(i) == "number" then
        local hero = heroId and WIH.Heroes.byId[heroId]
        local def = hero and hero.skills[i] and WIH.SkillData.resolve(hero.skills[i])
        return def and ("'" .. def.name .. "'") or (i .. "번째 스킬")
    end
    if i == "all" then return "모든 스킬" end
    if i == "summon" then return "소환 스킬" end
    if i == "trap" then return "덫 스킬" end
    if i == "firstCdAttack" then return "첫 재사용 공격 스킬" end
    if i == "firstCd" then return "첫 재사용 스킬" end
    if i == "firstCount" then return "첫 기본 공격 횟수 스킬" end
    if i == "firstAoe" then return "첫 광역 공격 스킬" end
    if type(i) == "string" and i:sub(1, 5) == "elem:" then return ELEM_NAMES[i:sub(6)] .. " 공격 스킬" end
    return "스킬"
end

-- 그 영웅에게 효과가 있는지(가리키는 스킬이 그 성격인지). heroId가 없으면 참.
function Uniques.applies(mod, heroId)
    local hero = heroId and WIH.Heroes.byId[heroId]
    if not hero or type(mod.idx) ~= "number" then return true end
    local id = hero.skills[mod.idx]
    local def = id and WIH.SkillData.resolve(id)
    if not def then return false end
    local k = mod.kind
    if k == "skillCd" or k == "skillHalf" then return def.act.type == "cd" end
    if k == "skillCount" then return def.act.type == "count" end
    if k == "trapMax" then return has(def, "trap") end
    if k == "skillHits" or k == "skillElem" or k == "basicCast" or k == "skillLeech" then return WIH.Skills.isAttack(def) end
    return true
end

function Uniques.text(mod, heroId)
    local t = Uniques.describe(mod, heroId)
    if not Uniques.applies(mod, heroId) then t = t .. " (이 영웅에게는 효과 없음)" end
    return t
end

function Uniques.describe(mod, heroId)
    local k, s = mod.kind, skillWord(mod, heroId)
    if k == "skillCd" then return s .. " 재사용 대기 -" .. pct(mod.pct) end
    if k == "skillHalf" then return s .. " 재사용 대기 -" .. pct(mod.cd) .. ", 대신 위력 -" .. pct(mod.power) end
    if k == "skillCount" then return s .. "에 필요한 기본 공격 -" .. mod.n .. "회" end
    if k == "skillHits" then return s .. (mod.proj and " 투사체 +" or " 연속 공격 +") .. mod.n end
    if k == "skillElem" then return s .. "의 피해가 " .. ELEM_NAMES[mod.elem] .. " 피해로 바뀐다" end
    if k == "trapMax" then return s .. " 최대 설치 수 +" .. mod.n end
    if k == "summonMax" then return s .. " 최대 소환 수 +" .. mod.n end
    if k == "basicCast" then return "기본 공격 때 " .. pct(mod.chance) .. " 확률로 " .. s .. " 발동" end
    if k == "skillRange" then return s .. " 사거리 +" .. pct(mod.pct) end
    if k == "skillLeech" then return s .. "의 생명력 흡수 +" .. pct(mod.mult) end
    if k == "stat" then return WIH.Items.modText(mod.stat) end
    if k == "killReset" then return s .. "로 적을 처치하면 재사용 대기 초기화" end
    if k == "skillStatus" then
        return s .. (mod.elem and (" 피해가 " .. ELEM_NAMES[mod.elem] .. "로 바뀌고") or "") .. " 적중 시 " .. pct(mod.chance) .. " 확률로 "
            .. STATUS_NAMES[mod.status] .. (mod.mult and (", 피해 +" .. pct(mod.mult - 1)) or "")
    end
    if k == "skillVsStatus" then return STATUS_NAMES[mod.status] .. " 상태의 적에게 " .. s .. " 피해 +" .. pct(mod.pct) end
    if k == "critCdr" then return s .. "이 치명타를 내면 재사용 대기 -" .. mod.sec .. "초" end
    if k == "skillHeal" then return s .. "이 준 피해의 " .. pct(mod.pct) .. "만큼 체력이 가장 낮은 아군 회복" end
    if k == "bleedKillExtend" then return "출혈 중인 적을 처치하면 자신에게 걸린 강화 효과 +" .. mod.sec .. "초" end
    if k == "lowHpAS" then return "잃은 체력 1%당 공격속도 +" .. pct(mod.per) end
    if k == "summonFrenzy" then return "소환물 공격속도 +" .. pct(mod.as) end
    if k == "zoneAbsorb" then return "자신이 만든 보호 영역의 흡수량 +" .. pct(mod.pct) end
    if k == "zoneFollow" then return "자신이 만든 영역이 자신을 따라다닌다" end
    if k == "zoneDR" then return "자신이 만든 영역 안의 아군이 받는 피해 -" .. pct(mod.pct) end
    if k == "partyStat" then return "파티 전원 " .. WIH.Items.modText(mod.stat) end
    if k == "redirect" then return "주변 아군이 받는 피해의 " .. pct(mod.pct) .. "를 대신 받는다" end
    if k == "share" then return "받는 피해의 " .. pct(mod.pct) .. "를 다른 파티원이 나눠 받는다" end
    if k == "hitCap" then return "한 번에 최대 체력의 " .. pct(mod.pct) .. "를 넘는 피해를 받지 않는다" end
    if k == "blockReduce" then return "막기에 성공하면 피해 -" .. pct(mod.pct) end
    if k == "resist" then return mod.rule == "chaos" and "암흑 저항 = 가장 높은 원소 저항" or "화염·냉기·번개 저항 = 그중 가장 높은 값" end
    if k == "pace" then
        return mod.rule == "fastest" and "파티가 가장 빠른 파티원의 속도로 이동" or (mod.rule == "average" and "파티가 평균 속도로 이동"
            or "파티가 자신을 뺀 가장 느린 파티원의 속도로 이동")
    end
    return "고유 능력치"
end

------------------------------------------------------------------------
-- 적용
------------------------------------------------------------------------

-- 영웅이 낀 장비의 고유 능력치 목록
function Uniques.collect(state, heroId)
    local h = state.heroes[heroId]
    local out = {}
    if not h or not h.gear then return out end
    for _, slot in ipairs(Items.SLOTS) do
        local entry = h.gear[slot]
        local mod = entry and Uniques.byItem[entry.id]
        if mod then out[#out + 1] = mod end
    end
    return out
end

-- 능력치형(장비 시트로 들어간다)
function Uniques.addToSheet(sheet, mod)
    if mod.kind == "stat" then Sheet.add(sheet, mod.stat[1], mod.stat[2], mod.stat[3]) end
end

local function damageElems(def)
    local out = {}
    for _, eff in ipairs(def.effects or {}) do
        if eff.type == "damage" or eff.type == "dot" then out[eff.elem or "?"] = true end
        if eff.type == "zone" then for _, e in ipairs(eff.enemy or {}) do if e.type == "damage" or e.type == "dot" then out[e.elem or "?"] = true end end end
    end
    return out
end

local function isAoe(def)
    for _, eff in ipairs(def.effects or {}) do
        if eff.type == "damage" and (eff.area or eff.line) then return true end
        if eff.type == "zone" and eff.enemy then return true end
        if eff.type == "channel" then return true end
    end
    return false
end


-- 착용한 영웅의 스킬 칸 가운데 규칙이 가리키는 것
function Uniques.slots(u, which)
    local out, Skills = {}, WIH.Skills
    local hero = u.heroId and WIH.Heroes.byId[u.heroId]
    for _, slot in ipairs(u.skills) do
        local def = slot.def
        local ok = false
        if type(which) == "number" then
            local id = hero and hero.skills[which]
            local want = id and WIH.SkillData.resolve(id, u.form)
            ok = want ~= nil and (def == want or def.id == want.id or def.id == id)
        elseif which == "all" then ok = true
        elseif which == "summon" then ok = has(def, "summon")
        elseif which == "trap" then ok = has(def, "trap")
        elseif which == "firstCdAttack" then ok = def.act.type == "cd" and Skills.isAttack(def)
        elseif which == "firstCd" then ok = def.act.type == "cd"
        elseif which == "firstCount" then ok = def.act.type == "count"
        elseif which == "firstAoe" then ok = Skills.isAttack(def) and isAoe(def)
        elseif type(which) == "string" and which:sub(1, 5) == "elem:" then ok = Skills.isAttack(def) and damageElems(def)[which:sub(6)] == true
        end
        if ok then
            out[#out + 1] = slot
            if type(which) == "string" and which:sub(1, 5) == "first" then break end
        end
    end
    return out
end

-- 전투 유닛에 고유 능력치를 건다(스킬을 장착한 뒤에 부른다).
function Uniques.install(b, u, mods)
    for _, mod in ipairs(mods or {}) do
        local k = mod.kind
        for _, slot in ipairs(mod.idx and Uniques.slots(u, mod.idx) or {}) do
            local x = slot.unique or {}
            slot.unique = x
            if k == "skillCd" and slot.cd then
                slot.cd = slot.cd * (1 - mod.pct); if slot.charge > slot.cd then slot.charge = slot.cd end
            elseif k == "skillHalf" then
                if slot.cd then slot.cd = slot.cd * (1 - mod.cd); if slot.charge > slot.cd then slot.charge = slot.cd end end
                x.power = (x.power or 1) * (1 - mod.power)
            elseif k == "skillCount" then x.countReduce = (x.countReduce or 0) + mod.n
            elseif k == "skillHits" then x.extraHits = (x.extraHits or 0) + mod.n
            elseif k == "skillElem" then x.elem = mod.elem
            elseif k == "trapMax" then x.trapBonus = (x.trapBonus or 0) + mod.n
            elseif k == "summonMax" then
                u.summonBonus = u.summonBonus or {}
                u.summonBonus[slot.def.id] = (u.summonBonus[slot.def.id] or 0) + mod.n
            elseif k == "basicCast" then
                u.uniqueBasicCast = u.uniqueBasicCast or {}
                table.insert(u.uniqueBasicCast, { slot = slot, chance = mod.chance })
            elseif k == "skillRange" then x.range = (x.range or 1) * (1 + mod.pct)
            elseif k == "skillLeech" then x.leech = (x.leech or 0) + mod.mult
            elseif k == "killReset" then x.killReset = true
            elseif k == "skillStatus" then
                x.status = { status = mod.status, chance = mod.chance }
                if mod.elem then x.elem = mod.elem end
                if mod.mult then x.mult = (x.mult or 1) * mod.mult end
            elseif k == "skillVsStatus" then x.vs = { status = mod.status, mult = 1 + mod.pct }
            elseif k == "critCdr" then x.critCdr = (x.critCdr or 0) + mod.sec
            elseif k == "skillHeal" then x.heal = (x.heal or 0) + mod.pct
            end
        end
        if k == "lowHpAS" then u.uniqueLowHpAS = (u.uniqueLowHpAS or 0) + mod.per
        elseif k == "summonFrenzy" then u.uniqueSummonAS = (u.uniqueSummonAS or 0) + mod.as
        elseif k == "zoneAbsorb" then u.uniqueZoneAbsorb = (u.uniqueZoneAbsorb or 0) + mod.pct
        elseif k == "zoneFollow" then u.uniqueZoneFollow = true
        elseif k == "zoneDR" then u.uniqueZoneDR = (u.uniqueZoneDR or 0) + mod.pct
        elseif k == "bleedKillExtend" then u.uniqueBleedExtend = (u.uniqueBleedExtend or 0) + mod.sec
        elseif k == "hitCap" then u.hitCap = math.min(u.hitCap or 1, mod.pct)
        elseif k == "blockReduce" then u.blockReduce = math.max(u.blockReduce or 0.5, mod.pct)
        elseif k == "resist" then u.resistRule = mod.rule
        elseif k == "redirect" then
            b:addAura({ owner = u, radius = 3000, who = "none", redirect = { mode = "allies", pct = mod.pct }, unique = true })
        elseif k == "share" then
            b:addAura({ owner = u, radius = 3000, who = "none", redirect = { mode = "share", pct = mod.pct }, unique = true })
        elseif k == "pace" then
            b.paceRule = mod.rule
            b.paceOwner = u
        end
    end
end

-- 파티 전체에 거는 것(파티 능력치), 사건에 반응하는 것
function Uniques.installParty(b, heroes)
    local any = false
    for _, h in ipairs(heroes) do
        for _, mod in ipairs(h.uniques or {}) do
            if mod.kind == "partyStat" then
                for _, o in ipairs(heroes) do
                    b:addEffect(o, { id = "unique:party:" .. mod.stat[1], kind = "buff", dur = 1e9, mods = { mod.stat } })
                end
            end
        end
        if h.uniqueLowHpAS or h.uniqueSummonAS or h.uniqueBleedExtend then any = true end
    end
    if not any then return end
    -- 체력이 낮을수록 공격속도(0.5초마다 다시 잰다)
    for _, h in ipairs(heroes) do
        if h.uniqueLowHpAS then
            local e = b:addEffect(h, { id = "unique:lowHpAS", kind = "buff", dur = 1e9, mods = { { "AttackSpeed", I, 0 } } })
            b:addZone({ owner = h, team = 1, x = h.x, radius = 0, dur = 1e9, every = 0.5, hidden = true, follow = h,
                tick = function()
                    if not h.alive or not e then return end
                    local missing = (1 - h:hpRatio()) * 100
                    e.mods[1][3] = missing * h.uniqueLowHpAS * 1000
                    h:invalidate()
                end })
        end
    end
    b.listeners[#b.listeners + 1] = function(ev, a, c)
        if ev == "spawn" and a.kind == "summon" and a.owner and a.owner.uniqueSummonAS then
            b:addEffect(a, { id = "unique:summonAS", kind = "buff", dur = 1e9, mods = { { "AttackSpeed", I, a.owner.uniqueSummonAS * 1000 } } })
        elseif ev == "death" and a.team == 2 and c then
            local killer = c.statOwner or c
            if killer.uniqueBleedExtend and a.diedWith and a.diedWith.Bleed then
                for _, e in ipairs(killer.effects) do
                    if e.kind == "buff" and e.expires and e.dur and e.dur < 1e8 then e.expires = e.expires + killer.uniqueBleedExtend end
                end
            end
        end
    end
end

-- 검증용: 원작 종류가 모두 옮겨졌는지
function Uniques.coverage()
    local kinds, items = {}, 0
    for _, row in ipairs(UniqueTable.items) do kinds[row[5]] = true end
    for _ in pairs(Uniques.byItem) do items = items + 1 end
    return kinds, items
end

return Uniques
