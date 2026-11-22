-- 유물과 유물함 [원작 1.3.0 구조와 수치]
--   · 유물함을 장착하면 고정 속성이 파티 전원에게 적용된다. 유물함의 칸(무작위 색)에 같은 색 유물을 끼우면(흰색은 아무 칸에나)
--     유물의 능력치도 파티 전원에게 적용된다.
--   · 공명: 유물함에 끼운 유물의 색 구성이 조건을 채우면 특수 효과가 발동한다(미완성 등급의 유물함은 공명 없음).
--     메아리 유물은 색을 셀 때 2개로 센다. 흰색 유물은 공명 조건의 색으로 세지 않는다 [추정].
--   · 얻기: 원정 상자에서 나오는 오염된 유물함·유물을 큐브의 기원에 바친다. 바꾸기: 조율(유물함은 칸 색, 유물은 수치를 다시 굴림).
--   · 장착 칸: 원정을 한 번 클리어하면 1칸, 지옥 원정 강도 10을 클리어하면 2칸. [원작]
--   · 공명 효과 62종 가운데 이 프로젝트의 엔진으로 옮긴 것은 아래 EFFECTS의 것이다. 나머지 유물함은 기원 결과에서 뺐다 [독자].
-- 저장 형태: state.relics = { items = { [uid] = 아이템 }, equipped = { uid, uid }, nextUid }
--   유물함 = { uid, kind = "RELIQUARY", id, grade, stats = { {stat, kind, value} }, slots = { 색... }, sockets = { [칸] = uid }, res, attune }
--   유물   = { uid, kind = "RELIC", id, grade, value, attune, holder = 유물함 uid }

local _, WIH = ...
local Stats = WIH.module("Stats")
local Sheet = WIH.module("Sheet")
local RelicTable = WIH.module("RelicTable")
local Relics = WIH.module("Relics")

local F, I, M = Stats.FLAT, Stats.INC, Stats.MORE
local COLORS = { "RED", "BLUE", "YELLOW", "PURPLE" }
Relics.COLOR_NAMES = { RED = "진홍", BLUE = "창공", YELLOW = "황금", PURPLE = "보랏빛", WHITE = "하얀" }
Relics.COLOR_RGB = { RED = { 0.86, 0.40, 0.36 }, BLUE = { 0.42, 0.62, 0.90 }, YELLOW = { 0.90, 0.78, 0.40 }, PURPLE = { 0.66, 0.48, 0.86 }, WHITE = { 0.88, 0.88, 0.90 } }

-- 구현한 공명 효과: [유물함 번호] = { 효과, 최소, 최대, 이름, 설명 형식 } (값의 단위는 효과마다 다르다: %는 퍼밀)
Relics.EFFECTS = {
    [790001] = { "stat", 50, 90, "끈기", "재사용 감소 +%s", stat = { "CooldownReduction", F } },
    [794029] = { "stat", 100, 200, "끈기", "재사용 감소 +%s", stat = { "CooldownReduction", F } },
    [797051] = { "stat", 1, 2, "대가", "모든 스킬 레벨 +%s", stat = { "AddAllSkillLevel", F }, raw = true },
    [790005] = { "execute", 50, 100, "처형자", "체력 %s 이하의 일반 몬스터 즉사" },
    [794023] = { "execute", 110, 150, "처형자", "체력 %s 이하의 일반 몬스터 즉사" },
    [795039] = { "execute", 160, 200, "처형자", "체력 %s 이하의 일반 몬스터 즉사" },
    [790006] = { "reflect", 1000, 2000, "거울", "막아낸 피해의 %s 반사" },
    [794030] = { "reflect", 3000, 5000, "거울", "막아낸 피해의 %s 반사" },
    [790007] = { "warding", 1, 1, "보루", "수호의 축복 %s레벨(화염·냉기·번개 저항)", raw = true },
    [794037] = { "warding", 3, 5, "보루", "수호의 축복 %s레벨(화염·냉기·번개 저항)", raw = true },
    [790008] = { "might", 1, 1, "힘", "힘의 축복 %s레벨(공격력 증가)", raw = true },
    [795038] = { "might", 3, 5, "힘", "힘의 축복 %s레벨(공격력 증가)", raw = true },
    [790009] = { "phoenix", 100, 200, "불사조", "영웅이 쓰러지면 체력 %s로 되살림(스테이지당 1회)" },
    [794024] = { "phoenix", 300, 500, "불사조", "영웅이 쓰러지면 체력 %s로 되살림(스테이지당 1회)" },
    [790011] = { "chaos", 50, 130, "공허", "준 피해의 %s만큼 추가 암흑 피해" },
    [797048] = { "chaos", 150, 300, "순수한 공허", "준 피해의 %s만큼 추가 암흑 피해" },
    [790013] = { "commander", 100, 250, "지휘관", "스테이지마다 무작위 영웅 1명의 최대 체력·주는 피해 +%s" },
    [794031] = { "commander", 100, 200, "지휘관", "스테이지마다 무작위 영웅 1명의 최대 체력·주는 피해 +%s" },
    [797059] = { "commander", 300, 500, "지휘관", "스테이지마다 무작위 영웅 1명의 최대 체력·주는 피해 +%s" },
    [790020] = { "twin", 300, 300, "쌍둥이", "투사체 +1, 대신 투사체 피해 -%s" },
    [794012] = { "emptySlot", 40, 80, "잊힌 왕", "빈 편성 칸 하나마다 주는 피해 +%s, 받는 피해 -%s" },
    [797049] = { "emptySlot", 90, 180, "잊힌 왕", "빈 편성 칸 하나마다 주는 피해 +%s, 받는 피해 -%s" },
    [794021] = { "vengeful", 200, 400, "복수", "영웅이 쓰러지면 남은 영웅의 주는 피해 +%s(10초)" },
    [794042] = { "vengeful", 500, 1000, "복수", "영웅이 쓰러지면 남은 영웅의 주는 피해 +%s(10초)" },
    [795034] = { "aura", 300, 700, "단죄", "영웅 주변의 적에게 초당 화염 피해 %s" },
    [797044] = { "vampire", 1500, 2000, "흡혈귀", "생명력 흡수 ×%s, 대신 초당 재생·타격·처치 회복 없음", mult = true },
    [790018] = { "igniteSpread", 0, 0, "잿불", "점화된 적이 죽으면 가장 가까운 적에게 점화" },
    [790017] = { "bleedSpread", 0, 0, "선혈", "출혈 중인 적이 죽으면 주변의 적에게 출혈" },
    [797047] = { "pureLight", 100, 200, "순수한 빛", "번개 치명타가 감전을 걸고, 감전된 적은 번개 피해를 %s 더 받음" },
    [797052] = { "resonator", 500, 500, "공명기", "장착한 다른 유물함의 공명 수치 +%s" },
}

local function fail(reason) return false, reason end

function Relics.ensure(state)
    if type(state.relics) ~= "table" then state.relics = {} end
    local r = state.relics
    if type(r.items) ~= "table" then r.items = {} end
    if type(r.equipped) ~= "table" then r.equipped = {} end
    if type(r.nextUid) ~= "number" then r.nextUid = 1 end
    return r
end

-- 유물 화면이 열렸는지, 장착 칸 수 [원작]
function Relics.unlocked(state)
    for d = 2, 4 do
        if WIH.Expeditions.highest(state, d) > 0 then return true end
    end
    return false
end

function Relics.slotCount(state)
    if not Relics.unlocked(state) then return 0 end
    if (state.stage.cleared[WIH.Expeditions.keys[3][10]] or 0) > 0 then return 2 end
    return 1
end

local function newUid(state)
    local uid = state.relics.nextUid
    state.relics.nextUid = uid + 1
    return uid
end

local function roll(rng, lo, hi)
    if hi <= lo then return lo end
    return rng:int(lo, hi)
end

-- 유물함 만들기: 고정 속성(풀에서 서로 다른 것), 칸 색, 공명 수치
function Relics.makeReliquary(state, id, grade, rng)
    local def = RelicTable.RELIQUARIES[id]
    local g = def and def.grades[grade]
    if not g then return nil end
    local item = { uid = newUid(state), kind = "RELIQUARY", id = id, grade = grade, stats = {}, slots = {}, sockets = {}, attune = 0 }
    local pool, used = RelicTable.POOL[grade], {}
    for _ = 1, g[2] do
        local tries = 0
        local pick
        repeat
            pick = rng:int(1, #pool)
            tries = tries + 1
        until not used[pick] or tries > 20
        used[pick] = true
        local p = pool[pick]
        item.stats[#item.stats + 1] = { p[1], p[2], roll(rng, p[3], p[4]) }
    end
    for i = 1, g[1] do item.slots[i] = COLORS[rng:int(1, #COLORS)] end
    local eff = Relics.EFFECTS[id]
    if eff then item.res = roll(rng, eff[2], eff[3]) end
    state.relics.items[item.uid] = item
    return item
end

function Relics.makeRelic(state, id, grade, rng)
    local def = RelicTable.RELICS[id]
    if not def then return nil end
    local range = def.range[grade]
    local item = { uid = newUid(state), kind = "RELIC", id = id, grade = grade, value = roll(rng, range[1], range[2]), attune = 0 }
    state.relics.items[item.uid] = item
    return item
end

-- 오염된 유물함·유물을 기원에 바친 결과 [원작 가중치, 구현하지 않은 공명의 유물함은 뺌]
function Relics.offer(state, materialId, rng)
    local rows = RelicTable.OFFER[materialId]
    if not rows then return nil end
    local isQuiver = math.floor(materialId / 1000) == 161
    local list, total = {}, 0
    for _, row in ipairs(rows) do
        local ids = {}
        for _, id in ipairs(row[3]) do
            if not isQuiver or (Relics.EFFECTS[id] and RelicTable.RELIQUARIES[id].grades[row[1]]) then ids[#ids + 1] = id end
        end
        if #ids > 0 then
            local wgt = row[2] * #ids / #row[3]
            list[#list + 1] = { row[1], wgt, ids }
            total = total + wgt
        end
    end
    local r = rng:float() * total
    local pick = list[#list]
    for _, e in ipairs(list) do
        r = r - e[2]
        if r < 0 then pick = e; break end
    end
    local id = pick[3][rng:int(1, #pick[3])]
    if isQuiver then return Relics.makeReliquary(state, id, pick[1], rng) end
    return Relics.makeRelic(state, id, pick[1], rng)
end

-- 큐브의 기원: 오염된 유물함·유물 재료 1개 + 골드 → 유물함·유물 1개 [추정: 수수료 10골드, 단일 출처]
Relics.OFFER_FEE = 10
function Relics.isOfferMaterial(id)
    return RelicTable.OFFER[id] ~= nil
end

function Relics.offerMaterial(state, materialId, rng)
    if not RelicTable.OFFER[materialId] then return fail("기원에 쓸 수 없는 재료입니다.") end
    if (state.materials[materialId] or 0) < 1 then return fail("재료가 없습니다.") end
    if state.gold < Relics.OFFER_FEE then return fail("골드가 부족합니다.") end
    Relics.ensure(state)
    state.gold = state.gold - Relics.OFFER_FEE
    state.materials[materialId] = state.materials[materialId] - 1
    if state.materials[materialId] <= 0 then state.materials[materialId] = nil end
    local item = Relics.offer(state, materialId, rng)
    return { relic = item }
end

-- 기원 결과의 등급별 확률(구현하지 않은 공명의 유물함을 뺀 뒤): { [등급] = 확률 }
function Relics.offerOdds(materialId)
    local rows = RelicTable.OFFER[materialId]
    if not rows then return {} end
    local isQuiver = math.floor(materialId / 1000) == 161
    local by, total = {}, 0
    for _, row in ipairs(rows) do
        local n = 0
        for _, id in ipairs(row[3]) do
            if not isQuiver or (Relics.EFFECTS[id] and RelicTable.RELIQUARIES[id].grades[row[1]]) then n = n + 1 end
        end
        local wgt = row[2] * n / #row[3]
        by[row[1]] = (by[row[1]] or 0) + wgt
        total = total + wgt
    end
    for g, w in pairs(by) do by[g] = w / total end
    return by
end

-- 장착: 유물함을 칸(1~2)에 둔다. 같은 유물함이 다른 칸에 있으면 옮긴다.
function Relics.equip(state, slot, uid)
    local r = state.relics
    if slot < 1 or slot > Relics.slotCount(state) then return fail("열리지 않은 칸입니다.") end
    local item = uid and r.items[uid]
    if uid and (not item or item.kind ~= "RELIQUARY") then return fail("유물함을 골라 주세요.") end
    for i = 1, 2 do if r.equipped[i] == uid then r.equipped[i] = nil end end
    r.equipped[slot] = uid
    return true
end

-- 유물을 유물함의 칸에 끼운다. 색이 같아야 하고 흰색은 아무 칸에나.
function Relics.socket(state, quiverUid, index, relicUid)
    local r = state.relics
    local q, relic = r.items[quiverUid], r.items[relicUid]
    if not q or q.kind ~= "RELIQUARY" then return fail("유물함을 골라 주세요.") end
    if not relic or relic.kind ~= "RELIC" then return fail("유물을 골라 주세요.") end
    local color = q.slots[index]
    if not color then return fail("없는 칸입니다.") end
    local rc = RelicTable.RELICS[relic.id].color
    if rc ~= "WHITE" and rc ~= color then return fail(Relics.COLOR_NAMES[color] .. " 칸에는 " .. Relics.COLOR_NAMES[color] .. " 유물이나 하얀 유물만 끼울 수 있습니다.") end
    -- 다른 곳에 끼워져 있으면 뺀다
    if relic.holder then Relics.unsocketRelic(state, relic) end
    local old = q.sockets[index] and r.items[q.sockets[index]]
    if old then old.holder = nil end
    q.sockets[index] = relicUid
    relic.holder = quiverUid
    return true
end

function Relics.unsocketRelic(state, relic)
    local q = relic.holder and state.relics.items[relic.holder]
    if q then
        for i, uid in pairs(q.sockets) do if uid == relic.uid then q.sockets[i] = nil end end
    end
    relic.holder = nil
end

function Relics.unsocket(state, quiverUid, index)
    local q = state.relics.items[quiverUid]
    local uid = q and q.sockets[index]
    if not uid then return fail("빈 칸입니다.") end
    local relic = state.relics.items[uid]
    if relic then relic.holder = nil end
    q.sockets[index] = nil
    return true
end

-- 유물함의 공명 조건 충족 여부: 색 개수(메아리는 2개)
function Relics.colorCounts(state, q)
    local counts = {}
    for _, uid in pairs(q.sockets) do
        local relic = state.relics.items[uid]
        local def = relic and RelicTable.RELICS[relic.id]
        if def and def.color ~= "WHITE" then counts[def.color] = (counts[def.color] or 0) + (def.double and 2 or 1) end
    end
    return counts
end

function Relics.resonating(state, q)
    local def = RelicTable.RELIQUARIES[q.id]
    local g = def.grades[q.grade]
    if not g or g[3] or not Relics.EFFECTS[q.id] then return false end
    local counts = Relics.colorCounts(state, q)
    for color, n in pairs(def.cond) do
        if (counts[color] or 0) < n then return false end
    end
    return true
end

-- 지금 발동 중인 공명 효과 목록: { { kind, value, item } }
function Relics.activeEffects(state)
    local list, boost = {}, 1
    local r = state.relics
    if not r then return list end
    for i = 1, 2 do
        local q = r.equipped[i] and r.items[r.equipped[i]]
        if q and Relics.resonating(state, q) and Relics.EFFECTS[q.id][1] == "resonator" then boost = boost + q.res / 1000 end
    end
    for i = 1, Relics.slotCount(state) do
        local q = r.equipped[i] and r.items[r.equipped[i]]
        if q and Relics.resonating(state, q) then
            local eff = Relics.EFFECTS[q.id]
            if eff[1] ~= "resonator" then
                local value = q.res
                if not eff.raw then value = value * boost end
                list[#list + 1] = { eff[1], value, q, eff }
            end
        end
    end
    return list
end

-- 능력치 한 줄을 시트에 넣는다(유물 전용 능력치는 엔진의 능력치로 바꾼다). 골드는 계정 합계(addTotals)로 간다.
-- 기본값이 0인 유물 전용 능력치의 "% 증가"는 그대로 더한다(0에 곱하면 0이 되므로). [원작 표기: Increased]
local ADD_AS_FLAT = { BossDamage = true, FullHpTargetDamage = true, LowHpTargetDamage = true, FullHpTargetCriticalChance = true, OnReviveAttackDamage = true }

local function addStat(sheet, stat, kind, v)
    if kind == I and ADD_AS_FLAT[stat] then kind = F end
    if stat == "AttackAndCastSpeed" then
        Sheet.add(sheet, "AttackSpeed", kind, v); Sheet.add(sheet, "CastSpeed", kind, v)
    elseif stat:sub(1, 8) == "Decrease" then
        local base = stat:sub(9)
        if base == "AttackDamage" then Sheet.add(sheet, "AttackDamage", I, -v) else Sheet.add(sheet, base, F, -v) end
    elseif stat == "GoldAmount" then
        return
    elseif stat == "WaveStartMovementSpeed" then
        Sheet.add(sheet, "MovementSpeed", kind, v)                -- [근사: 웨이브 시작 직후만이 아니라 늘]
    elseif stat == "OnHitDamageReduction" then
        Sheet.add(sheet, "DamageReduction", F, math.floor(v / 2))  -- [근사: 맞은 뒤 잠시 → 늘 절반]
    elseif Stats.defs[stat] then
        Sheet.add(sheet, stat, kind, v)
    end
end

-- 장착한 유물함과 끼운 유물의 능력치 줄을 차례로 넘긴다: fn(능력치, 연산, 값)
local function eachLine(state, fn)
    local r = state.relics
    if not r then return end
    for i = 1, Relics.slotCount(state) do
        local q = r.equipped[i] and r.items[r.equipped[i]]
        if q then
            for _, s in ipairs(q.stats) do fn(s[1], s[2], s[3]) end
            for _, uid in pairs(q.sockets) do
                local relic = r.items[uid]
                local def = relic and RelicTable.RELICS[relic.id]
                if def then fn(def.stat, def.kind, relic.value) end
            end
        end
    end
end

-- 계정 합계에 더하는 것: 처치당 골드
function Relics.addTotals(state, totals)
    eachLine(state, function(stat, _, v)
        if stat == "GoldAmount" then totals.AdditionalGold = (totals.AdditionalGold or 0) + v end
    end)
    return totals
end

-- 비어 있는 편성 칸 수(열린 칸 기준) [추정: 잠긴 칸은 세지 않는다]
function Relics.emptySlots(state)
    local open = (state.unlocks and state.unlocks.partySlots) or WIH.Game.MAX_PARTY_SLOTS
    return math.max(0, open - #state.party)
end

-- 파티 전원에게 적용되는 시트(고정 속성 + 끼운 유물 + 능력치형 공명)
function Relics.sheet(state)
    local sheet = Sheet.new()
    if not state.relics then return sheet end
    eachLine(state, function(stat, kind, v) addStat(sheet, stat, kind, v) end)
    local empty = Relics.emptySlots(state)
    for _, e in ipairs(Relics.activeEffects(state)) do
        local kind, v, eff = e[1], e[2], e[4]
        if kind == "stat" then
            Sheet.add(sheet, eff.stat[1], eff.stat[2], v)
        elseif kind == "might" then
            Sheet.add(sheet, "AttackDamage", M, 500 + (v - 1) * 100)          -- [원작] 힘의 축복 1레벨 +50%, 레벨당 +10%p(곱연산)
        elseif kind == "warding" then
            for _, res in ipairs({ "FireResistance", "ColdResistance", "LightningResistance" }) do Sheet.add(sheet, res, F, 10 + (v - 1) * 5) end
        elseif kind == "twin" then
            Sheet.add(sheet, "ProjectileCount", F, 1)
            Sheet.add(sheet, "IncreaseProjectileDamage", M, -v)
        elseif kind == "emptySlot" and empty > 0 then
            Sheet.add(sheet, "DamageDealt", F, v * empty)
            Sheet.add(sheet, "TakenAll", F, -v * empty)
        elseif kind == "vampire" then
            Sheet.add(sheet, "HpLeech", M, v - 1000)
            for _, st in ipairs({ "HpRegenPerSec", "AddHpPerHit", "AddHpPerKill" }) do Sheet.add(sheet, st, M, -1000) end
        end
    end
    return sheet
end

-- 전투에 걸리는 공명 효과(사건에 반응하는 것)를 단다.
function Relics.install(battle, heroes, state)
    local active = Relics.activeEffects(state)
    if #active == 0 then return end
    local on = {}
    for _, e in ipairs(active) do on[e[1]] = math.max(on[e[1]] or 0, e[2]) end
    -- 지휘관: 무작위 영웅 1명
    local leader
    local function lead(h)
        battle:addEffect(h, { id = "relic:commander", kind = "buff", dur = 1e9, mods = { { "MaxHp", I, on.commander }, { "DamageDealt", F, on.commander } } })
    end
    if on.commander and #heroes > 0 then
        leader = heroes[battle.rng:int(1, #heroes)]
        lead(leader)
        leader.hp = leader:get("MaxHp")
        leader.relicLeader = true
    end
    -- 단죄: 영웅 주변 초당 화염 피해
    if on.aura then
        for _, h in ipairs(heroes) do
            battle:addZone({ owner = h, team = 1, x = h.x, radius = 300, dur = 1e9, every = 1, follow = h, hidden = true, isRelic = true,
                tick = function(b)
                    if not h.alive then return end
                    for _, u in ipairs(b.units) do
                        if u.team == 2 and u.alive and math.abs(u.x - h.x) <= 300 then
                            b:hit(h, u, { elem = "Fire", coef = on.aura / 1000, aoe = true, canCrit = false, relic = true })
                        end
                    end
                end })
        end
    end
    local phoenixUsed, busy = false, false
    battle.listeners[#battle.listeners + 1] = function(ev, a, b, c, d, e, f)
        if busy then return end
        if ev == "damage" then
            local src, dst, dmg, elem, crit, blocked = a, b, c, d, e, f
            if not dst then return end
            busy = true
            local owner = src and (src.statOwner or src)
            if on.execute and dst.team == 2 and dst.alive and not dst.isBoss and dst:hpRatio() <= on.execute / 1000 then
                battle:kill(src, dst)
            end
            if on.reflect and blocked and dst.team == 1 and src and src.alive and src.team == 2 then
                battle:receive(dst, src, dmg * on.reflect / 1000, "Physical", { noAvoid = true, isReflect = true, relic = true })
            end
            if on.chaos and owner and owner.team == 1 and dst.team == 2 and dst.alive and dmg > 0 then
                battle:receive(src, dst, dmg * on.chaos / 1000, "Chaos", { noAvoid = true, isReflect = true, relic = true })
            end
            if on.pureLight and owner and owner.team == 1 and dst.team == 2 and dst.alive and elem == "Lightning" and crit then
                battle:applyStatus(src, dst, "Shock")
                battle:addEffect(dst, { id = "relic:pureLight", kind = "debuff", dur = 6, mods = { { "TakenLightning", F, on.pureLight } } })
            end
            busy = false
        elseif ev == "revive" then
            if a == leader then lead(a) end
        elseif ev == "effect" and c and b and b.status and a and a.team == 2 then
            if b.status == "Ignite" then a.relicIgnite = b.expires or 0 end
            if b.status == "Bleed" then a.relicBleed = b.expires or 0 end
        elseif ev == "death" then
            local dst, src = a, b
            busy = true
            if dst.kind == "hero" then
                if on.phoenix and not phoenixUsed then
                    phoenixUsed = true
                    battle:revive(dst, on.phoenix / 1000)
                end
                if on.vengeful then
                    for _, h in ipairs(heroes) do
                        if h.alive and h ~= dst then
                            battle:addEffect(h, { id = "relic:vengeful", kind = "buff", dur = 10, mods = { { "DamageDealt", F, on.vengeful } } })
                        end
                    end
                end
            elseif dst.team == 2 then
                local spread = (on.igniteSpread and dst.relicIgnite and dst.relicIgnite > battle.time) and "Ignite"
                    or ((on.bleedSpread and dst.relicBleed and dst.relicBleed > battle.time) and "Bleed") or nil
                if spread then
                    local best, bestD
                    for _, u in ipairs(battle.units) do
                        if u.team == 2 and u.alive and u ~= dst then
                            local dd = math.abs(u.x - dst.x)
                            if not bestD or dd < bestD then best, bestD = u, dd end
                        end
                    end
                    if best and bestD <= 300 then battle:applyStatus(src or dst, best, spread) end
                end
            end
            busy = false
        end
    end
end

-- 조율: 유물함은 칸 색을, 유물은 수치를 다시 굴린다. 비용 = 기본 + 증가분 × min(횟수, 상한) [원작]
function Relics.attuneCost(item)
    local t = RelicTable.ATTUNE[item.kind][item.grade]
    return t[1] + t[2] * math.min(item.attune or 0, t[3])
end

function Relics.attune(state, uid, rng)
    local item = state.relics.items[uid]
    if not item then return fail("유물을 골라 주세요.") end
    local cost = Relics.attuneCost(item)
    if state.gold < cost then return fail("골드가 부족합니다.") end
    state.gold = state.gold - cost
    item.attune = (item.attune or 0) + 1
    if item.kind == "RELIQUARY" then
        for i = 1, #item.slots do item.slots[i] = COLORS[rng:int(1, #COLORS)] end
        -- 색이 맞지 않게 된 유물은 뺀다
        for i, ruid in pairs(item.sockets) do
            local relic = state.relics.items[ruid]
            local c = relic and RelicTable.RELICS[relic.id].color
            if c and c ~= "WHITE" and c ~= item.slots[i] then
                relic.holder = nil
                item.sockets[i] = nil
            end
        end
    else
        local range = RelicTable.RELICS[item.id].range[item.grade]
        item.value = roll(rng, range[1], range[2])
    end
    return true, cost
end

-- 팔기(연금술): 등급 기본 골드 × 12 [독자: 재료와 같은 셈]
function Relics.sell(state, uid)
    local r = state.relics
    local item = r.items[uid]
    if not item then return fail("유물을 골라 주세요.") end
    for i = 1, 2 do if r.equipped[i] == uid then return fail("장착한 유물함은 팔 수 없습니다.") end end
    if item.kind == "RELIQUARY" then
        for _, ruid in pairs(item.sockets) do if r.items[ruid] then r.items[ruid].holder = nil end end
    else
        Relics.unsocketRelic(state, item)
    end
    r.items[uid] = nil
    local gold = WIH.Items.GRADES[item.grade].gold * 12
    WIH.Game.addGold(state, gold)
    return true, gold
end

-- 목록: kind = "RELIQUARY" | "RELIC". 장착한 것 → 등급 높은 것 → 번호 순.
function Relics.list(state, kind)
    local r = Relics.ensure(state)
    local out = {}
    for _, item in pairs(r.items) do if item.kind == kind then out[#out + 1] = item end end
    local equipped = {}
    for i = 1, 2 do if r.equipped[i] then equipped[r.equipped[i]] = i end end
    table.sort(out, function(a, b)
        local ea, eb = equipped[a.uid] or (a.holder and 3) or 9, equipped[b.uid] or (b.holder and 3) or 9
        if ea ~= eb then return ea < eb end
        if a.grade ~= b.grade then return a.grade > b.grade end
        if a.id ~= b.id then return a.id < b.id end
        return a.uid < b.uid
    end)
    return out
end

function Relics.equippedSlot(state, uid)
    for i = 1, 2 do if state.relics.equipped[i] == uid then return i end end
end

-- 빈 칸 자동 채우기: 공명 조건에 필요한 색을 먼저, 등급이 높은 유물부터. 끼운 수를 돌려준다.
function Relics.autoFill(state, quiverUid)
    local r = state.relics
    local q = r.items[quiverUid]
    if not q or q.kind ~= "RELIQUARY" then return 0 end
    local need = {}
    for color, n in pairs(RelicTable.RELIQUARIES[q.id].cond) do need[color] = n end
    for color, n in pairs(Relics.colorCounts(state, q)) do if need[color] then need[color] = need[color] - n end end
    local free = {}
    for _, item in ipairs(Relics.list(state, "RELIC")) do
        if not item.holder then free[#free + 1] = item end
    end
    local filled = 0
    for i, color in ipairs(q.slots) do
        if not q.sockets[i] then
            local best, bestScore
            for k, item in ipairs(free) do
                local def = RelicTable.RELICS[item.id]
                if def.color == color or def.color == "WHITE" then
                    local score = item.grade * 10
                    if def.color == color and (need[color] or 0) > 0 then score = score + 1000 + (def.double and 1 or 0) end
                    if def.color == "WHITE" then score = score - 5 end
                    if not bestScore or score > bestScore then best, bestScore = k, score end
                end
            end
            if best then
                local item = table.remove(free, best)
                Relics.socket(state, q.uid, i, item.uid)
                local def = RelicTable.RELICS[item.id]
                if need[def.color] then need[def.color] = need[def.color] - (def.double and 2 or 1) end
                filled = filled + 1
            end
        end
    end
    return filled
end

-- 파티 전원에게 적용 중인 유물 능력치의 표기 줄(같은 능력치·연산은 합친다)과 발동 중인 공명
function Relics.summaryLines(state)
    local order, sum = {}, {}
    eachLine(state, function(stat, kind, v)
        local key = stat .. "#" .. kind
        if not sum[key] then sum[key] = { stat, kind, 0 }; order[#order + 1] = key end
        sum[key][3] = sum[key][3] + v
    end)
    local lines = {}
    for _, key in ipairs(order) do
        local e = sum[key]
        lines[#lines + 1] = Relics.statText(e[1], e[2], e[3])
    end
    local effects = {}
    for _, e in ipairs(Relics.activeEffects(state)) do effects[#effects + 1] = Relics.effectText(e[3]) end
    return lines, effects
end

-- 장착 상태가 바뀌었는지 알아보는 문자열(전투력 캐시의 열쇠)
function Relics.signature(state)
    local r = state.relics
    if not r then return "r" end
    local parts = { "r", Relics.slotCount(state) }
    for i = 1, 2 do
        local q = r.equipped[i] and r.items[r.equipped[i]]
        if q then
            parts[#parts + 1] = q.uid .. ":" .. table.concat(q.slots, "")
            for k = 1, #q.slots do
                local relic = q.sockets[k] and r.items[q.sockets[k]]
                parts[#parts + 1] = relic and (relic.uid .. "=" .. relic.value) or "-"
            end
        end
    end
    return table.concat(parts, ",")
end

-- 표기
function Relics.name(item)
    if item.kind == "RELIC" then
        local def = RelicTable.RELICS[item.id]
        return Relics.COLOR_NAMES[def.color] .. " 유물" .. (def.double and " · 메아리" or "")
    end
    local eff = Relics.EFFECTS[item.id]
    return (eff and eff[4] or "이름 없는") .. "의 유물함"
end

function Relics.statText(stat, kind, v)
    if stat == "AttackAndCastSpeed" then return "공격·시전 속도 +" .. (v / 10) .. "% 증가" end
    if stat == "GoldAmount" then return "처치당 골드 +" .. v end
    if stat == "WaveStartMovementSpeed" then return "이동속도 +" .. (v / 10) .. "% 증가" end
    if stat == "OnHitDamageReduction" then return "피해 감소 +" .. (math.floor(v / 2) / 10) .. "%" end
    if stat:sub(1, 8) == "Decrease" then
        local base = stat:sub(9)
        local label = Stats.defs[base] and Stats.defs[base].label or base
        return base == "AttackDamage" and (label .. " -" .. (v / 10) .. "%") or (label .. " -" .. v)
    end
    return WIH.Items.modText({ stat, kind, v })
end

function Relics.effectText(item)
    local eff = Relics.EFFECTS[item.id]
    if not eff then return "공명 효과 없음" end
    local v = item.res or eff[2]
    local shown
    if eff.raw then shown = tostring(v)
    elseif eff.mult then shown = string.format("%.2f", v / 1000)
    else shown = (v / 10) .. "%" end
    return string.format(eff[5], shown, shown)
end

function Relics.condText(item)
    local def = RelicTable.RELIQUARIES[item.id]
    local parts = {}
    for _, c in ipairs({ "RED", "BLUE", "YELLOW", "PURPLE" }) do
        if def.cond[c] then parts[#parts + 1] = Relics.COLOR_NAMES[c] .. " " .. def.cond[c] end
    end
    return table.concat(parts, " · ")
end

-- 저장 데이터 검증
function Relics.validate(state)
    local r = Relics.ensure(state)
    for uid, item in pairs(r.items) do
        local ok = type(item) == "table" and item.uid == uid and (item.kind == "RELIC" and RelicTable.RELICS[item.id]
            or item.kind == "RELIQUARY" and RelicTable.RELIQUARIES[item.id] and RelicTable.RELIQUARIES[item.id].grades[item.grade])
        if not ok then r.items[uid] = nil end
    end
    for _, item in pairs(r.items) do
        if item.kind == "RELIQUARY" then
            for i, ruid in pairs(item.sockets) do
                local relic = r.items[ruid]
                if not relic or relic.kind ~= "RELIC" or relic.holder ~= item.uid then item.sockets[i] = nil end
            end
        elseif item.holder and not r.items[item.holder] then
            item.holder = nil
        end
    end
    for i = 1, 2 do
        local uid = r.equipped[i]
        if uid and (not r.items[uid] or r.items[uid].kind ~= "RELIQUARY") then r.equipped[i] = nil end
    end
end

return Relics
