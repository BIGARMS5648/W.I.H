-- W.I.H: 네임스페이스와 공용 상수.
-- 엔진 파일은 WoW API를 쓰지 않는다. 게임 밖 Lua 5.1에서도 같은 파일을 그대로 불러온다.

local addonName, WIH = ...
WIH = WIH or {}

WIH.name = addonName or "WIH"
WIH.version = "0.1.0"

-- 엔진의 고정 틱 길이(초). [독자 설계] 원작의 틱 길이는 확인되지 않았다.
WIH.TICK = 0.05

-- 하위 모듈 테이블을 만들거나 돌려준다.
function WIH.module(name)
    local m = WIH[name]
    if not m then
        m = {}
        WIH[name] = m
    end
    return m
end

-- 레벨에 따라 선형으로 커지는 값. {기본, 레벨당} 또는 숫자.
function WIH.scaled(v, level)
    if type(v) == "table" then
        if v.values then
            -- 레벨별 값을 직접 나열한 경우(선형이 아닌 스킬)
            local lv = level or 1
            if lv > #v.values then lv = #v.values end
            return v.values[lv]
        end
        return v[1] + (v[2] or 0) * ((level or 1) - 1)
    end
    return v
end

return WIH
