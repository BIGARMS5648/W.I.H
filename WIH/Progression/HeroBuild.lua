-- 영웅의 저장 상태(레벨, 트리 투자, 장착 스킬, 장비 시트)로 전투 유닛을 만든다.

local _, WIH = ...
local Stats = WIH.module("Stats")
local Sheet = WIH.module("Sheet")
local Unit = WIH.module("Unit")
local Skills = WIH.module("Skills")
local Heroes = WIH.module("Heroes")
local SkillData = WIH.module("SkillData")
local HeroBuild = WIH.module("HeroBuild")

-- 영웅의 형태를 반영한 기본 능력치와 사거리
function HeroBuild.baseOf(hero, form)
    if hero.forms then
        local f = hero.forms[form or hero.defaultForm]
        return f.base, f.range, f.role
    end
    return hero.base, hero.range, hero.role
end

-- 패시브 투자를 시트에 더한다. passivePoints[칸 번호] = 투자한 포인트
function HeroBuild.addPassives(sheet, hero, passivePoints)
    if not passivePoints then return end
    for index, points in pairs(passivePoints) do
        local node = hero.passives[index]
        if node and points > 0 then
            if points > node.max then points = node.max end
            Sheet.add(sheet, node.stat, node.kind, node.per * points)
        end
    end
end

-- 시험과 시뮬레이션용 자동 투자: 고른 액티브를 Lv5까지 올리고 남는 포인트를 낮은 티어의 패시브부터 채운다.
-- 돌려주는 값: activeLevels[스킬 ID] = 레벨, passivePoints[칸] = 포인트, 쓴 포인트
function HeroBuild.autoAllocate(hero, totalPoints, chosenSkills)
    local left = totalPoints
    local spent = 0
    local activeLevels, passivePoints = {}, {}
    local chosen = {}
    for i = 1, #chosenSkills do chosen[chosenSkills[i]] = true end
    for tier = 0, 70, 10 do
        if spent < tier then break end
        for i = 1, #hero.skills do
            if Heroes.ACTIVE_TIERS[i] == tier and chosen[hero.skills[i]] and left > 0 then
                local n = math.min(Heroes.ACTIVE_MAX_BY_POINTS, left)
                activeLevels[hero.skills[i]] = n
                left, spent = left - n, spent + n
            end
        end
        for index = 1, #hero.passives do
            if Heroes.PASSIVE_TIERS[index] == tier and left > 0 then
                local n = math.min(hero.passives[index].max, left)
                passivePoints[index] = n
                left, spent = left - n, spent + n
            end
        end
    end
    return activeLevels, passivePoints, spent
end

-- 전투 유닛 생성.
-- opts: form, passivePoints, skills = { {id, level}, ... }(최대 4개, 우선순위 순), gear(시트), account(시트),
--       rank, x, weaponSpeed(주무기 공격속도 가산. 없으면 기본 무기 값)
function HeroBuild.spawn(b, heroId, opts)
    opts = opts or {}
    local u = HeroBuild.makeUnit(heroId, opts)
    b:addUnit(u)
    if opts.skills then
        for i = 1, math.min(#opts.skills, opts.maxSlots or 4) do
            local s = opts.skills[i]
            local def = SkillData.resolve(s[1] or s.id, u.form)
            if not def then error("알 수 없는 스킬: " .. tostring(s[1] or s.id)) end
            Skills.equip(b, u, def, s[2] or s.level or 1)
        end
    end
    return u
end

-- 전투에 넣지 않은 유닛을 만든다. 영웅 화면의 능력치 표시도 이 유닛에서 읽는다(전투와 같은 계산).
function HeroBuild.makeUnit(heroId, opts)
    opts = opts or {}
    local hero = Heroes.byId[heroId]
    if not hero then error("알 수 없는 영웅: " .. tostring(heroId)) end
    local form = hero.forms and (opts.form or hero.defaultForm) or nil
    local base, range, role = HeroBuild.baseOf(hero, form)

    local unitBase = {}
    for stat, v in pairs(base) do unitBase[stat] = v end

    local static = Sheet.new()
    HeroBuild.addPassives(static, hero, opts.passivePoints)
    if opts.gear then
        Sheet.merge(static, opts.gear)
    else
        -- 장비가 없는 시험용: 기본 무기의 공격속도 가산만 준다.
        local speed = opts.weaponSpeed or Heroes.MAIN_WEAPONS[hero.main].speed
        Sheet.add(static, "AttackSpeed", Stats.FLAT, speed)
    end
    if opts.account then Sheet.merge(static, opts.account) end
    -- 영웅별 화력 보정 [독자: Data/HeroTuning.lua]
    local tuning = WIH.HeroTuning and WIH.HeroTuning.damage
    local factor = tuning and (tuning[heroId .. (form and (":" .. form) or "")] or tuning[heroId])
    if factor and factor ~= 1 then Sheet.add(static, "DamageDealt", Stats.MORE, (factor - 1) * 1000) end

    local melee = range <= 200
    local u = Unit.new({
        name = hero.name, team = 1, kind = "hero", def = hero, base = unitBase, static = static,
        melee = melee, range = range, rank = opts.rank or 1, x = opts.x or 0,
        basicElem = hero.basicElem, basicDelivery = melee and "melee" or "proj",
    })
    u.heroId = heroId
    u.form = form
    u.role = role
    return u
end

return HeroBuild
