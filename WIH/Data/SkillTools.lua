-- 스킬 데이터 도구: 형태별 스킬 고르기, 레벨에 따라 변하는 수치 뽑기, 설명문 만들기, 데이터 검사.
-- 설명문의 {1}, {2}…는 "레벨에 따라 변하는 수치"를 정해진 순서로 세었을 때의 번호다.
-- 툴팁은 이 함수가 만든 문장을 쓰므로 표시 수치와 전투 수치가 같은 데이터에서 나온다.

local _, WIH = ...
local Stats = WIH.module("Stats")
local SkillData = WIH.module("SkillData")

local scaled = WIH.scaled

-- 영웅의 형태(야성 드루이드)에 맞는 스킬 정의를 돌려준다.
local resolved = {}
function SkillData.resolve(id, form)
    local def = SkillData.defs[id]
    if not def then return nil end
    if not def.forms then return def end
    form = form or "bear"
    local key = id .. ":" .. form
    local r = resolved[key]
    if not r then
        local src = def.forms[form]
        if not src then return nil end
        r = {}
        for k, v in pairs(src) do r[k] = v end
        r.id = key
        r.baseId = id
        r.form = form
        resolved[key] = r
    end
    return r
end

-- 레벨에 따라 변하는 값인지: {기본, 레벨당(0이 아님)} 또는 {values = {...}}
local function isScaling(v)
    if type(v) ~= "table" then return false end
    if v.values then return true end
    return type(v[1]) == "number" and type(v[2]) == "number" and v[2] ~= 0 and v[3] == nil
end

-- 효과 테이블을 정해진 키 순서로 훑는다(해시 순서에 의존하지 않기 위해).
local SCALAR_KEYS = { "coef", "pct", "flat", "hits", "attacks", "cleave", "extend", "absorb", "dotDouble", "dur" }
local NESTED_KEYS = { "redirect", "proc", "reflect", "lethal", "cond", "leech", "unit", "hot", "nextHit" }
local NESTED_SCALARS = { "pct", "chance", "coef", "shieldPct", "critMult", "critDmg", "mult", "count", "max" }
local CHILD_LISTS = { "apply", "effects", "enemy", "ally", "once", "onCrit", "onDodge", "onSpawn" }

local function visit(eff, out, level)
    for i = 1, #SCALAR_KEYS do
        local v = eff[SCALAR_KEYS[i]]
        if isScaling(v) then out[#out + 1] = { value = scaled(v, level), kind = SCALAR_KEYS[i] } end
    end
    if eff.mods then
        for i = 1, #eff.mods do
            local m = eff.mods[i]
            if isScaling(m[3]) then
                local raw = scaled(m[3], level)
                local shown
                if m[2] == Stats.FLAT then
                    local d = Stats.defs[m[1]]
                    if d.scale == 1000 then shown = raw / 10          -- 퍼밀 → %
                    elseif d.scale == 100 then shown = raw / 100
                    elseif d.scale == 10 then shown = raw / 10
                    else shown = raw end
                else
                    shown = raw / 10                                   -- Increased, More: 퍼밀 → %
                end
                out[#out + 1] = { value = math.abs(shown), kind = "mod", stat = m[1] }
            end
        end
    end
    for i = 1, #NESTED_KEYS do
        local t = eff[NESTED_KEYS[i]]
        if type(t) == "table" then
            for j = 1, #NESTED_SCALARS do
                local v = t[NESTED_SCALARS[j]]
                if isScaling(v) then out[#out + 1] = { value = scaled(v, level), kind = NESTED_KEYS[i] } end
            end
            if t.effects then
                for j = 1, #t.effects do visit(t.effects[j], out, level) end
            end
        end
    end
    for i = 1, #CHILD_LISTS do
        local list = eff[CHILD_LISTS[i]]
        if type(list) == "table" then
            for j = 1, #list do visit(list[j], out, level) end
        end
    end
end

-- 레벨에 따라 변하는 수치 목록. 재사용 시간이 레벨에 따라 변하면 마지막에 붙는다.
function SkillData.values(def, level)
    local out = {}
    for i = 1, #def.effects do visit(def.effects[i], out, level) end
    if isScaling(def.act.cd) then out[#out + 1] = { value = scaled(def.act.cd, level), kind = "cd" } end
    return out
end

local function fmt(v)
    if math.abs(v - math.floor(v + 0.5)) < 1e-6 then
        return tostring(math.floor(v + 0.5))
    end
    return (string.format("%.2f", v):gsub("0+$", ""):gsub("%.$", ""))
end
SkillData.formatNumber = fmt

-- 발동 방식의 한 줄 표기
function SkillData.activation(def, level)
    local act = def.act
    if act.type == "count" then
        return "기본 공격 " .. act.n .. "회마다"
    elseif act.type == "cd" then
        return "재사용 " .. fmt(scaled(act.cd, level or 1)) .. "초"
    elseif act.type == "aura" then
        return "상시"
    end
    return ""
end

-- 설명문. {n} 자리를 현재 레벨의 수치로 바꾼다.
function SkillData.describe(def, level)
    local vals = SkillData.values(def, level or 1)
    local text = def.desc or ""
    text = text:gsub("{(%d+)}", function(n)
        local v = vals[tonumber(n)]
        if not v then return "{?" .. n .. "}" end
        return fmt(v.value)
    end)
    return text
end

-- 데이터 검사. 문제 목록을 돌려준다(없으면 빈 표).
function SkillData.validate()
    local problems = {}
    local Skills = WIH.Skills
    local function checkEffects(id, effects, path)
        for i = 1, #effects do
            local eff = effects[i]
            local where = id .. " " .. path .. "[" .. i .. "]"
            if not Skills.exec[eff.type] and not (eff.type == "aura") then
                problems[#problems + 1] = where .. ": 알 수 없는 효과 종류 " .. tostring(eff.type)
            end
            if eff.mods then
                for j = 1, #eff.mods do
                    if not Stats.defs[eff.mods[j][1]] then
                        problems[#problems + 1] = where .. ": 알 수 없는 능력치 " .. tostring(eff.mods[j][1])
                    end
                end
            end
            if eff.status and not WIH.Battle.STATUS[eff.status] then
                problems[#problems + 1] = where .. ": 알 수 없는 상태 이상 " .. tostring(eff.status)
            end
            if eff.type == "special" and not Skills.special[eff.name] then
                problems[#problems + 1] = where .. ": 등록되지 않은 특수 효과 " .. tostring(eff.name)
            end
            if eff.special and not Skills.special[eff.special] then
                problems[#problems + 1] = where .. ": 등록되지 않은 특수 효과 " .. tostring(eff.special)
            end
            for _, key in ipairs(CHILD_LISTS) do
                if type(eff[key]) == "table" then checkEffects(id, eff[key], path .. "." .. key) end
            end
            if eff.proc and eff.proc.effects then checkEffects(id, eff.proc.effects, path .. ".proc") end
        end
    end
    local function checkDef(def)
        local id = def.id
        if not def.name then problems[#problems + 1] = id .. ": 이름 없음" end
        if not def.desc then problems[#problems + 1] = id .. ": 설명 없음" end
        if not def.act or not (def.act.type == "cd" or def.act.type == "count" or def.act.type == "aura") then
            problems[#problems + 1] = id .. ": 발동 방식이 올바르지 않음"
        end
        if def.act and def.act.type ~= "aura" and not def.target then
            problems[#problems + 1] = id .. ": 대상 규칙 없음"
        end
        checkEffects(id, def.effects or {}, "effects")
        -- 레벨이 올라도 변하는 수치가 하나도 없으면 무의미한 성장이다.
        local v1, v10 = SkillData.values(def, 1), SkillData.values(def, 10)
        local changed = false
        for i = 1, #v1 do
            if v1[i].value ~= v10[i].value then changed = true end
        end
        if not changed then problems[#problems + 1] = id .. ": 스킬 레벨에 따라 변하는 수치가 없음" end
        local text = SkillData.describe(def, 1)
        if text:find("{?", 1, true) then problems[#problems + 1] = id .. ": 설명문의 자리 표시가 수치와 맞지 않음" end
        local used = 0
        for n in (def.desc or ""):gmatch("{(%d+)}") do
            if tonumber(n) > used then used = tonumber(n) end
        end
        if used < #v1 then
            problems[#problems + 1] = id .. ": 레벨에 따라 변하는 수치 " .. #v1 .. "개 중 설명문에 " .. used .. "개만 나옴"
        end
    end
    for id, def in pairs(SkillData.defs) do
        if def.forms then
            for form in pairs(def.forms) do checkDef(SkillData.resolve(id, form)) end
        else
            checkDef(def)
        end
    end
    table.sort(problems)
    return problems
end

return SkillData
