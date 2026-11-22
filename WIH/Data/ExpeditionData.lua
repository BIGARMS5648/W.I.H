-- 원정 3종(원작의 역병지대 자리)과 낙스라마스(원작의 오염된 액트 보스 자리)의 몬스터와 보스.
-- 수치의 기준은 원작 표(Data/ExpeditionTable.lua)이고, 여기 적힌 체력·공격력은 같은 곳 안에서의 상대적 세기다.
-- 이름은 오리지널의 것이고 보스 패턴은 이 프로젝트의 설계다 [독자]. 한국어 이름은 기억에 의존했으므로 검수가 필요하다.

local _, WIH = ...
local Monsters = WIH.module("Monsters")
local ExpeditionData = WIH.module("ExpeditionData")

local mob, boss, P = Monsters.mob, Monsters.boss, Monsters.P
local FIRE, COLD, LIGHT, CHAOS, PHYS = "Fire", "Cold", "Lightning", "Chaos", "Physical"

local function place(id, name, zone, mobs, bosses)
    local sec = { key = id, name = name, zone = zone, mobs = {}, bosses = {} }
    for i, m in ipairs(mobs) do
        mob(m[1], m[2], m[3], m[5])
        sec.mobs[i] = { id = m[1], weight = m[4] }
    end
    for i, b in ipairs(bosses) do
        local def = boss(b[1], b[2], b[3])
        def.raid = true
        sec.bosses[i] = b[1]
    end
    return sec
end

-- 원정: 난이도 2(악몽) 줄구룹, 3(지옥) 안퀴라즈 폐허, 4(고통) 안퀴라즈 사원
-- 스테이지 보스는 강도에 따라 보스 목록을 차례로 돈다. 강도 20은 마지막 보스다.
ExpeditionData.EXPEDITIONS = {
    [2] = place("zg", "줄구룹", "가시덤불 골짜기", {
        { "zg_berserker", "굴루바시 광전사", "berserk", 1000 },
        { "zg_shadowhunter", "하카리 그림자사냥꾼", "archer", 800, { elem = CHAOS } },
        { "zg_bat", "굴루바시 박쥐", "swarm", 700 },
        { "zg_witchdoctor", "하카리 의술사", "caster", 700, { elem = CHAOS } },
        { "zg_razzashi", "라자시 독사", "fast", 900, { elem = CHAOS } },
        { "zg_axe", "굴루바시 도끼투척병", "soldier", 800 },
    }, {
        { "zg_venoxis", "대사제 베녹시스", { range = 800, elem = CHAOS, skills = { P.dot("독사의 맹독", CHAOS, 60, 8, 8), P.nova("독성 구름", CHAOS, 150, 10), P.adds("독사 부르기", 16, 3, "라자시 독사", 3, 50), P.heal("신성한 기운", 10, 14), P.enrage("독사의 형상", 0.5, 40) } } },
        { "zg_jeklik", "대여사제 제클릭", { elem = FIRE, skills = { P.adds("박쥐 떼", 14, 4, "굴루바시 박쥐", 2, 40), P.zone("불타는 기름", FIRE, 80, 240, 6, 10), P.status("공포의 비명", "Stun", 16, 60, 3000), P.heal("치유의 주문", 12, 15, 0.5), P.enrage("박쥐의 형상", 0.5, 40) } } },
        { "zg_marli", "대여사제 말리", { range = 800, elem = CHAOS, skills = { P.bolt("독침", CHAOS, 260, 5), P.adds("거미 부화", 15, 4, "새끼 거미", 2, 45), P.dot("말리의 독", CHAOS, 50, 10, 9), P.status("거미줄", "Stun", 14, 60, nil, PHYS, "farthest"), P.enrage("거미의 형상", 0.5, 40) } } },
        { "zg_thekal", "대사제 테칼", { skills = { P.cleave("가르기", 220, 3), P.status("힘껏 내려치기", "Stun", 14, 150, nil, PHYS, "nearest"), P.adds("광신자 부르기", 18, 2, "하카리 광신자", 5, 80), P.frenzy("호랑이의 광기", 12, 6, 60), P.enrage("호랑이의 형상", 0.5, 50) } } },
        { "zg_arlokk", "대여사제 아를로크", { skills = { P.wound("살쾡이 발톱", 10, 8, 40, 200), P.adds("표범 부르기", 15, 3, "줄구룹 표범", 3, 60), P.weaken("숨어 기다리기", 16, 6, 25), P.bolt("그림자 화살", CHAOS, 260, 6, "lowestHpEnemy"), P.enrage("표범의 형상", 0.5, 50) } } },
        { "zg_mandokir", "혈군주 만도키르", { skills = { P.cleave("휩쓸기", 230, 3), P.smash("처형", 380, 9), P.frenzy("광기", 12, 6, 60), P.status("위협의 외침", "Stun", 16, 60, 3000), P.enrage("피의 분노", 0.3, 60) } } },
        { "zg_jindo", "주술사 진도", { range = 800, elem = CHAOS, skills = { P.curse("환영의 저주", 14, 8, 30), P.adds("주술 토템", 16, 2, "그림자 토템", 3, 60, 1.4, true), P.bolt("그림자 화살", CHAOS, 280, 5), P.drain("영혼 흡수", CHAOS, 220, 10), P.heal("치유의 토템", 10, 14, 0.6) } } },
        { "zg_hakkar", "영혼착취자 학카르", { elem = CHAOS, skills = { P.drain("피의 흡수", CHAOS, 260, 8), P.nova("타락한 피", CHAOS, 200, 9), P.curse("광기의 저주", 14, 8, 30), P.status("정신 지배", "Stun", 16, 80, nil, CHAOS, "random"), P.enrage("신의 분노", 0.25, 60, 30) } } },
    }),
    [3] = place("aq20", "안퀴라즈 폐허", "실리더스", {
        { "aq20_warrior", "실리시드 전사", "soldier", 1000 },
        { "aq20_swarmguard", "하이브아라 일벌", "swarm", 800 },
        { "aq20_stinger", "하이브아라 쏘는벌", "fast", 800, { elem = CHAOS } },
        { "aq20_obsidian", "흑요석 파괴자", "tank", 500 },
        { "aq20_soldier", "안퀴라즈 병사", "stalker", 900 },
        { "aq20_mage", "안퀴라즈 신비술사", "caster", 600, { elem = LIGHT } },
    }, {
        { "aq20_kurinnaxx", "쿠린낙스", { skills = { P.wound("필사의 상처", 8, 10, 50, 200), P.zone("모래 폭풍", PHYS, 80, 260, 6, 10), P.cleave("가르기", 200, 3), P.frenzy("광란", 14, 6, 50), P.enrage("격노", 0.3, 40) } } },
        { "aq20_rajaxx", "장군 라작스", { skills = { P.adds("군단 부르기", 12, 4, "안퀴라즈 병사", 4, 70), P.nova("천둥 울림", LIGHT, 170, 9), P.smash("일격", 300, 8), P.weaken("위협의 외침", 15, 6, 25), P.enrage("마지막 군단", 0.3, 50) } } },
        { "aq20_moam", "모암", { elem = LIGHT, skills = { P.nova("마나 폭발", LIGHT, 200, 11), P.adds("마나 악령", 18, 3, "마나 악령", 4, 70, 1.4, true), P.guard("돌로 굳기", 16, 6, 70), P.drain("마나 흡수", LIGHT, 220, 9), P.enrage("넘치는 마나", 0.3, 50) } } },
        { "aq20_buru", "먹보 부루", { hp = 320, skills = { P.smash("짓밟기", 320, 8), P.adds("부루의 알", 16, 3, "부루의 알", 2, 30), P.frenzy("추격", 12, 6, 60), P.nova("알 폭발", PHYS, 160, 13), P.enrage("광포", 0.2, 80) } } },
        { "aq20_ayamiss", "사냥꾼 아야미스", { range = 800, elem = CHAOS, skills = { P.bolt("독침 사격", CHAOS, 280, 5, "farthest"), P.adds("유충 부르기", 15, 4, "하이브아라 유충", 2, 40), P.dot("마비 독", CHAOS, 60, 8, 9), P.status("거미줄 그물", "Stun", 14, 60, nil, PHYS, "random"), P.enrage("광란", 0.3, 50, 30) } } },
        { "aq20_ossirian", "무적의 오시리안", { hp = 360, skills = { P.cleave("가르기", 240, 3), P.status("전쟁 발구르기", "Stun", 14, 120, 300), P.curse("약화의 저주", 14, 8, 30), P.zone("모래 회오리", PHYS, 90, 260, 6, 9), P.enrage("수정의 힘", 0.4, 60, 30) } } },
    }),
    [4] = place("aq40", "안퀴라즈 사원", "실리더스", {
        { "aq40_anubisath", "아누비사스 수호병", "tank", 600, { elem = FIRE } },
        { "aq40_reaver", "실리시드 파괴자", "brute", 700 },
        { "aq40_templar", "황혼의 기사", "soldier", 900, { elem = LIGHT } },
        { "aq40_drone", "베클로르 일벌", "swarm", 800 },
        { "aq40_obsidian", "흑요석 무효화자", "stalker", 800, { elem = CHAOS } },
        { "aq40_prophet", "황혼의 예언자", "caster", 600, { elem = CHAOS } },
    }, {
        { "aq40_skeram", "예언자 스케람", { range = 800, elem = LIGHT, skills = { P.bolt("비전 폭발", LIGHT, 280, 5), P.status("정신 지배", "Stun", 16, 60, nil, CHAOS, "random"), P.adds("분신", 18, 2, "스케람의 분신", 8, 70, 1.3, true), P.nova("지진", PHYS, 150, 11), P.enrage("마지막 예언", 0.25, 50) } } },
        { "aq40_bug", "왕실 곤충 무리", { skills = { P.adds("왕실 곤충", 14, 3, "왕실 일벌", 4, 60), P.dot("독 구름", CHAOS, 70, 8, 9), P.smash("돌진", 300, 8), P.heal("곤충의 치유", 10, 12, 0.5), P.enrage("복수", 0.3, 60) } } },
        { "aq40_sartura", "전투감시병 사르투라", { skills = { P.cleave("소용돌이", 260, 3), P.adds("왕실 근위병", 16, 3, "사르투라의 근위병", 5, 80), P.frenzy("광폭", 12, 6, 60), P.status("기절", "Stun", 14, 100, 300), P.enrage("격노", 0.25, 60) } } },
        { "aq40_fankriss", "불굴의 판크리스", { skills = { P.wound("필사의 상처", 8, 10, 50, 220), P.adds("부화", 13, 4, "베클로르 일벌", 3, 50), P.dot("구멍 파기", PHYS, 70, 8, 10, "random"), P.smash("내려치기", 320, 9), P.enrage("격노", 0.3, 50) } } },
        { "aq40_viscidus", "비시디우스", { elem = CHAOS, skills = { P.nova("독 화살", CHAOS, 190, 8), P.status("얼어붙음", "Freeze", 15, 80, 3000, COLD), P.adds("독 방울", 16, 4, "비시디우스의 방울", 3, 40), P.zone("독성 웅덩이", CHAOS, 90, 260, 6, 10), P.enrage("녹아내림", 0.3, 50) } } },
        { "aq40_huhuran", "왕녀 후후란", { elem = CHAOS, skills = { P.dot("와이번 쐐기", CHAOS, 80, 8, 9, "random"), P.nova("독성 분출", CHAOS, 210, 9), P.frenzy("광란", 12, 6, 60), P.wound("독 침", 10, 8, 50), P.enrage("광포", 0.3, 80) } } },
        { "aq40_twins", "쌍둥이 황제", { elem = LIGHT, skills = { P.bolt("비전 폭발", LIGHT, 300, 5), P.smash("어퍼컷", 320, 8), P.adds("벌레 부르기", 16, 4, "변이 벌레", 3, 50), P.curse("쌍둥이의 저주", 14, 8, 30), P.enrage("광폭", 0.3, 60, 30) } } },
        { "aq40_cthun", "쑨", { elem = CHAOS, skills = { P.bolt("눈의 광선", CHAOS, 320, 4), P.nova("어둠의 시선", CHAOS, 240, 9), P.adds("눈 촉수", 14, 4, "눈 촉수", 4, 60, 1.2, true), P.status("집어삼킴", "Stun", 16, 120, nil, CHAOS, "random"), P.enrage("고대 신의 분노", 0.25, 60, 30) } } },
    }),
}

-- 낙스라마스: 스테이지 1~3(원작의 액트 1~3 자리), 보스를 차례로 상대한다(레이드와 같은 방식)
local function naxx(stage, name, bosses)
    local r = { act = stage, name = name, zone = "낙스라마스", bosses = {} }
    for i, b in ipairs(bosses) do
        local def = boss(b[1], b[2], b[3])
        def.raid = true
        r.bosses[i] = b[1]
    end
    return r
end

ExpeditionData.NAXX = {
    naxx(1, "낙스라마스: 거미·역병 지구", {
        { "nx_anubrekhan", "아눕레칸", { skills = { P.zone("메뚜기 떼", PHYS, 100, 260, 6, 10), P.adds("지하 군단", 16, 3, "지하 군단 전사", 4, 70), P.cleave("가르기", 220, 3), P.status("메뚜기 떼의 공포", "Stun", 16, 60, 3000), P.enrage("광폭", 0.25, 60) } } },
        { "nx_faerlina", "귀부인 팰리나", { range = 800, elem = CHAOS, skills = { P.nova("독화살 일제 사격", CHAOS, 200, 9), P.zone("불의 비", FIRE, 90, 260, 6, 10), P.adds("숭배자", 16, 3, "낙스라마스 숭배자", 4, 70), P.frenzy("광란", 14, 6, 60), P.enrage("광폭", 0.25, 60) } } },
        { "nx_maexxna", "맥스나", { elem = CHAOS, skills = { P.status("거미줄 감싸기", "Stun", 14, 80, nil, PHYS, "farthest"), P.nova("거미줄 분사", CHAOS, 170, 11), P.adds("새끼 거미", 15, 5, "맥스나의 새끼", 2, 40), P.wound("마비 독", 10, 10, 70), P.enrage("광란", 0.3, 60) } } },
        { "nx_noth", "역병술사 노스", { range = 800, elem = CHAOS, skills = { P.curse("역병술사의 저주", 14, 10, 30), P.adds("해골 전사 소환", 14, 4, "역병 걸린 전사", 4, 70), P.bolt("점멸", CHAOS, 260, 6, "farthest"), P.dot("역병", CHAOS, 70, 8, 9), P.enrage("광폭", 0.25, 60) } } },
        { "nx_heigan", "부정한 자 헤이건", { elem = CHAOS, skills = { P.zone("역병 분출", CHAOS, 120, 300, 6, 8), P.nova("부패의 열병", CHAOS, 180, 10), P.dot("열병", CHAOS, 70, 8, 9), P.weaken("부정의 기운", 16, 8, 25), P.enrage("춤추는 역병", 0.4, 50) } } },
        { "nx_loatheb", "로데브", { elem = CHAOS, skills = { P.nova("버섯 포자", CHAOS, 200, 9), P.wound("부패의 손길", 8, 12, 80, 200), P.curse("필연의 운명", 12, 10, 40), P.adds("포자", 14, 3, "로데브의 포자", 2, 30), P.enrage("광폭", 0.25, 60) } } },
    }),
    naxx(2, "낙스라마스: 군사·피조물 지구", {
        { "nx_razuvious", "교관 라주비어스", { skills = { P.smash("분쇄의 일격", 360, 8), P.nova("방해의 외침", PHYS, 200, 9), P.adds("수련생", 16, 2, "죽음의 기사 수련생", 6, 80), P.wound("깊은 상처", 10, 8, 50), P.enrage("광폭", 0.25, 60) } } },
        { "nx_gothik", "영혼 착취자 고딕", { range = 800, elem = CHAOS, skills = { P.adds("망자 소환", 12, 4, "되살아난 망자", 4, 70), P.bolt("그림자 화살", CHAOS, 280, 5), P.drain("영혼 흡수", CHAOS, 240, 10), P.curse("수확", 14, 8, 30), P.enrage("광폭", 0.25, 60) } } },
        { "nx_horsemen", "4기사단", { elem = CHAOS, skills = { P.nova("징표", CHAOS, 190, 8), P.bolt("성스러운 광휘", FIRE, 280, 5), P.smash("공허의 일격", 340, 8, CHAOS), P.zone("메테오", FIRE, 110, 260, 6, 9), P.enrage("기사단의 분노", 0.3, 60, 30) } } },
        { "nx_patchwerk", "패치워크", { hp = 360, skills = { P.smash("증오의 일격", 400, 6), P.frenzy("광란", 12, 6, 60), P.cleave("휩쓸기", 220, 3), P.wound("살덩이 찢기", 10, 8, 50), P.enrage("광폭", 0.05, 100) } } },
        { "nx_grobbulus", "그라불루스", { elem = CHAOS, skills = { P.dot("돌연변이 주입", CHAOS, 90, 8, 9, "random"), P.zone("독 구름", CHAOS, 100, 260, 8, 10), P.adds("진흙 떼", 15, 4, "역병 진흙", 2, 40), P.cleave("독액 분사", 200, 3, CHAOS), P.enrage("광폭", 0.25, 60) } } },
        { "nx_gluth", "글루스", { skills = { P.wound("필사의 상처", 8, 10, 60, 220), P.adds("좀비 먹이", 12, 5, "좀비 구울", 2, 40), P.status("공포의 포효", "Stun", 16, 60, 3000), P.frenzy("광란", 12, 6, 60), P.enrage("섬멸", 0.2, 80) } } },
        { "nx_thaddius", "타디우스", { elem = LIGHT, skills = { P.nova("극성 변환", LIGHT, 220, 9), P.bolt("연쇄 번개", LIGHT, 280, 6), P.status("감전", "Shock", 14, 100, 3000, LIGHT), P.adds("스탈라그와 퓨젠", 20, 2, "타디우스의 하수인", 6, 80), P.enrage("광폭", 0.25, 60) } } },
    }),
    naxx(3, "낙스라마스: 서리고룡 둥지", {
        { "nx_sapphiron", "사피론", { elem = COLD, skills = { P.nova("서리 숨결", COLD, 260, 10), P.status("얼음 무덤", "Freeze", 14, 100, nil, COLD, "random"), P.zone("눈보라", COLD, 110, 300, 6, 9), P.dot("생명 흡수", COLD, 80, 8, 9), P.enrage("광폭", 0.25, 60) } } },
        { "nx_kelthuzad", "켈투자드", { range = 800, elem = COLD, skills = { P.bolt("서리 화살", COLD, 320, 4), P.nova("서리 화살 일제 사격", COLD, 220, 8), P.status("서리 덫", "Freeze", 14, 100, 300, COLD), P.adds("리치왕의 수호병", 16, 3, "얼음왕관 수호병", 5, 80), P.drain("영혼 분리", CHAOS, 280, 10) } } },
    }),
}

return ExpeditionData
