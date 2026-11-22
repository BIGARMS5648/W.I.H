-- 능력치 수정치 묶음(시트)과 합산.

local _, WIH = ...
local Stats = WIH.module("Stats")
local Sheet = WIH.module("Sheet")

local FLAT, INC, MORE = Stats.FLAT, Stats.INC, Stats.MORE

function Sheet.new()
    return { flat = {}, inc = {}, more = {} }
end

-- 수정치 하나를 더한다. value는 데이터의 정수 단위(Increased와 More는 퍼밀).
function Sheet.add(sheet, stat, kind, value)
    if not Stats.defs[stat] then
        error("정의되지 않은 능력치: " .. tostring(stat), 2)
    end
    if kind == FLAT then
        sheet.flat[stat] = (sheet.flat[stat] or 0) + value
    elseif kind == INC then
        sheet.inc[stat] = (sheet.inc[stat] or 0) + value
    elseif kind == MORE then
        sheet.more[stat] = (sheet.more[stat] or 1) * (1 + value / 1000)
    else
        error("알 수 없는 연산 종류: " .. tostring(kind), 2)
    end
end

-- mods = { {stat, kind, value}, ... }. value가 {기본, 레벨당}이면 level로 계산한다.
function Sheet.addMods(sheet, mods, level, mult)
    for i = 1, #mods do
        local m = mods[i]
        local v = WIH.scaled(m[3], level)
        if mult then v = v * mult end
        Sheet.add(sheet, m[1], m[2], v)
    end
end

function Sheet.merge(dst, src)
    for stat, v in pairs(src.flat) do dst.flat[stat] = (dst.flat[stat] or 0) + v end
    for stat, v in pairs(src.inc) do dst.inc[stat] = (dst.inc[stat] or 0) + v end
    for stat, v in pairs(src.more) do dst.more[stat] = (dst.more[stat] or 1) * v end
end

function Sheet.clear(sheet)
    sheet.flat, sheet.inc, sheet.more = {}, {}, {}
end

-- 시트 둘(고정, 변동)과 기본값으로 최종 실제 값을 구한다.
function Sheet.value(stat, baseRaw, a, b)
    local d = Stats.defs[stat]
    local flat = (baseRaw or d.base) + (a.flat[stat] or 0)
    local inc = a.inc[stat] or 0
    local more = a.more[stat] or 1
    if b then
        flat = flat + (b.flat[stat] or 0)
        inc = inc + (b.inc[stat] or 0)
        more = more * (b.more[stat] or 1)
    end
    return flat * (1 + inc / 1000) * more / d.scale
end

return Sheet
