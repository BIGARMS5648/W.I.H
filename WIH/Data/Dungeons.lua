-- 오리지널 던전 20개를 27개 구간으로 나눈 스테이지 데이터.
-- 구간 키 = 액트 × 100 + 번호(101 ~ 309). 스테이지 레벨·웨이브 수·상자 드롭률은 Data/Tables.lua(원작 값)에서 온다.
-- 몬스터와 보스의 이름은 오리지널의 것이고, 능력치 배치와 보스 패턴은 이 프로젝트의 설계다 [독자].
-- 여기 적힌 체력·공격력은 "던전 안에서의 상대적 세기"다. 실제 수치는 진행기(Stage/Runner.lua)가 원작의 그 스테이지
-- 평균값에 맞춰 정한다(설계 문서 9.2.1절).
-- 한국어 이름은 기억에 의존해 적었으므로 클라이언트의 공식 표기와 대조해 검수해야 한다(docs/STATUS.md).

local _, WIH = ...
local Monsters = WIH.module("Monsters")
local Dungeons = WIH.module("Dungeons")

local mob, boss, P = Monsters.mob, Monsters.boss, Monsters.P

Dungeons.sections = {}
Dungeons.order = {}

-- mobs = { {id, 이름, 기본형, 가중치, 옵션}, ... }, bosses = { {id, 이름, 옵션}, ... }
local function dungeon(key, name, zone, mobs, bosses)
    local sec = { key = key, name = name, zone = zone, mobs = {}, bosses = {} }
    for i, m in ipairs(mobs) do
        mob(m[1], m[2], m[3], m[5])
        sec.mobs[i] = { id = m[1], weight = m[4] }
    end
    for i, b in ipairs(bosses) do
        boss(b[1], b[2], b[3])
        sec.bosses[i] = b[1]
    end
    Dungeons.sections[key] = sec
    Dungeons.order[#Dungeons.order + 1] = key
end

local FIRE, COLD, LIGHT, CHAOS = "Fire", "Cold", "Lightning", "Chaos"

------------------------------------------------------------------------
-- 액트 1
------------------------------------------------------------------------
dungeon(101, "성난불길 협곡", "오그리마", {
    { "rfc_trogg", "성난불길 트로그", "grunt", 1000 },
    { "rfc_shaman", "성난불길 주술사", "caster", 600, { elem = FIRE } },
    { "rfc_cultist", "이글거리는 칼날단 이교도", "fast", 800 },
    { "rfc_warlock", "이글거리는 칼날단 흑마법사", "caster", 500, { elem = CHAOS } },
    { "rfc_elemental", "용암 정령", "soldier", 400, { elem = FIRE } },
}, {
    { "rfc_oggleflint", "오글플린트", { skills = { P.cleave("휩쓸기", 150, 4) } } },
    { "rfc_taragaman", "굶주린 타라가만", { elem = FIRE, skills = { P.nova("화염 회오리", FIRE, 110, 10), P.smash("올려치기", 220, 8) } } },
    { "rfc_jergosh", "기원사 제르고쉬", { range = 800, elem = FIRE, skills = { P.dot("제물", FIRE, 40, 6, 7), P.weaken("약화의 저주", 15, 6, 15) } } },
    { "rfc_bazzalan", "바잘란", { skills = { P.dot("맹독", CHAOS, 35, 8, 8, "nearest"), P.frenzy("악마의 광기", 14, 5, 40) } } },
})

dungeon(102, "통곡의 동굴", "불모의 땅", {
    { "wc_raptor", "변이된 랩터", "stalker", 900 },
    { "wc_druid", "송곳니의 드루이드", "caster", 600, { elem = LIGHT } },
    { "wc_ooze", "동굴 진흙괴물", "tank", 400, { elem = CHAOS } },
    { "wc_viper", "변이된 독사", "fast", 800, { elem = CHAOS } },
    { "wc_bat", "동굴 박쥐", "swarm", 600 },
}, {
    { "wc_anacondra", "여군주 아나콘드라", { range = 800, elem = LIGHT, skills = { P.bolt("번개 화살", LIGHT, 200, 5), P.status("수면", "Stun", 14, 50, nil, LIGHT, "random") } } },
    { "wc_cobrahn", "군주 코브란", { range = 800, elem = LIGHT, skills = { P.dot("맹독", CHAOS, 40, 8, 9), P.bolt("번개 화살", LIGHT, 200, 6) } } },
    { "wc_pythas", "군주 피타스", { range = 800, elem = LIGHT, skills = { P.bolt("번개 화살", LIGHT, 210, 5), P.heal("치유의 손길", 12, 12) } } },
    { "wc_skum", "스컴", { skills = { P.nova("연쇄 번개", LIGHT, 130, 9) } } },
    { "wc_serpentis", "군주 서펜티스", { range = 800, elem = LIGHT, skills = { P.bolt("번개 화살", LIGHT, 220, 5), P.heal("치유의 손길", 15, 14) } } },
    { "wc_verdan", "영생의 베르단", { hp = 260, skills = { P.smash("대지 가르기", 260, 9), P.status("땅 울림", "Stun", 16, 120, 300) } } },
    { "wc_mutanus", "걸신들린 무타누스", { hp = 230, skills = { P.status("천둥소리", "Stun", 13, 100, 300, LIGHT), P.enrage("광포화", 0.3, 40) } } },
})

dungeon(103, "죽음의 폐광", "서부 몰락지대", {
    { "dm_miner", "데피아즈단 광부", "grunt", 1000 },
    { "dm_overseer", "데피아즈단 감독관", "soldier", 600 },
    { "dm_evoker", "데피아즈단 요술사", "caster", 600, { elem = FIRE } },
    { "dm_pirate", "데피아즈단 해적", "stalker", 700 },
    { "dm_gunner", "데피아즈단 총잡이", "archer", 500 },
}, {
    { "dm_rhahkzor", "라크조르", { hp = 240, skills = { P.smash("라크조르의 강타", 240, 8) } } },
    { "dm_sneed", "스니드의 벌목기", { hp = 250, skills = { P.cleave("톱날 베기", 160, 4), P.status("공포의 굉음", "Stun", 16, 80, 300) } } },
    { "dm_gilnid", "기르니드", { range = 800, elem = FIRE, skills = { P.dot("용암 뿌리기", FIRE, 45, 6, 8), P.zone("쏟아진 쇳물", FIRE, 40, 250, 6, 14) } } },
    { "dm_smite", "미스터 스마이트", { hp = 230, skills = { P.status("스마이트의 쿵쿵", "Stun", 14, 150, 300), P.enrage("무기 교체", 0.5, 30, 30) } } },
    { "dm_greenskin", "선장 그린스킨", { skills = { P.cleave("회전베기", 170, 3), P.wound("독 묻은 작살", 12, 6, 30) } } },
    { "dm_vancleef", "에드윈 밴클리프", { as = 110, skills = { P.adds("블랙가드 소환", 18, 2, "데피아즈단 블랙가드", 4, 60), P.frenzy("난도질", 12, 6, 50), P.enrage("최후의 발악", 0.25, 40) } } },
})

dungeon(104, "그림자송곳니 성채", "은빛소나무 숲", {
    { "sfk_worg", "그림자송곳니 늑대", "stalker", 900 },
    { "sfk_worgen", "그림자송곳니 늑대인간", "soldier", 800 },
    { "sfk_ghost", "고통받는 관리", "grunt", 700, { elem = CHAOS } },
    { "sfk_mage", "그림자송곳니 마법사", "caster", 500, { elem = CHAOS } },
    { "sfk_bat", "흡혈박쥐", "swarm", 600 },
}, {
    { "sfk_razorclaw", "도살자 칼날발톱", { as = 110, skills = { P.wound("도살", 10, 6, 30), P.frenzy("피의 광기", 14, 5, 40) } } },
    { "sfk_silverlaine", "남작 실버레인", { elem = CHAOS, skills = { P.curse("베일의 어둠", 14, 8, 15), P.adds("늑대인간 소환", 20, 2, "굶주린 늑대인간", 4, 60) } } },
    { "sfk_springvale", "사령관 스프링베일", { skills = { P.guard("신의 보호막", 18, 5, 60), P.smash("정의의 망치", 230, 8, LIGHT), P.heal("성스러운 빛", 10, 14, 0.6) } } },
    { "sfk_odo", "눈먼 감시자 오도", { as = 100, skills = { P.frenzy("울부짖는 분노", 12, 6, 60), P.enrage("광포화", 0.3, 35) } } },
    { "sfk_fenrus", "파멸의 펜루스", { as = 110, skills = { P.dot("독니", CHAOS, 45, 8, 8, "nearest"), P.cleave("물어뜯기", 150, 4) } } },
    { "sfk_nandos", "늑대왕 난도스", { skills = { P.adds("늑대 부르기", 15, 3, "피에 굶주린 늑대", 3, 45), P.smash("할퀴기", 220, 8) } } },
    { "sfk_arugal", "대마법사 아루갈", { range = 800, elem = CHAOS, skills = { P.bolt("공허의 화살", CHAOS, 260, 5), P.nova("아루갈의 저주", CHAOS, 120, 12), P.status("천둥충격", "Stun", 16, 100, 300, LIGHT) } } },
})

dungeon(105, "검은심연 나락", "잿빛 골짜기", {
    { "bfd_naga", "검은심연 미르미돈", "soldier", 900 },
    { "bfd_siren", "검은심연 세이렌", "caster", 600, { elem = COLD } },
    { "bfd_acolyte", "황혼의 수행사제", "caster", 500, { elem = CHAOS } },
    { "bfd_turtle", "아쿠마이 무는거북", "tank", 500 },
    { "bfd_murloc", "검은심연 멀록", "fast", 800 },
}, {
    { "bfd_ghamoora", "가무라", { hp = 280, skills = { P.status("진동", "Stun", 14, 120, 300) } } },
    { "bfd_sarevess", "여군주 사레베스", { range = 800, elem = COLD, skills = { P.bolt("갈래 번개", LIGHT, 200, 6), P.status("서리 회오리", "Freeze", 15, 80, 300, COLD) } } },
    { "bfd_gelihast", "겔리하스트", { as = 100, skills = { P.cleave("그물 휘두르기", 150, 4), P.adds("멀록 부르기", 16, 3, "검은심연 멀록", 3, 40) } } },
    { "bfd_serrakis", "늙은 세라키스", { hp = 240, skills = { P.wound("깊은 상처", 11, 6, 35), P.frenzy("광란", 16, 6, 40) } } },
    { "bfd_kelris", "황혼의 군주 켈리스", { range = 800, elem = CHAOS, skills = { P.bolt("정신 분열", CHAOS, 250, 6), P.status("수면", "Stun", 15, 60, nil, CHAOS, "random") } } },
    { "bfd_akumai", "아쿠마이", { hp = 280, elem = CHAOS, skills = { P.nova("독구름", CHAOS, 130, 11), P.enrage("광포한 분노", 0.3, 40, 20) } } },
})

dungeon(106, "스톰윈드 지하감옥", "스톰윈드", {
    { "stk_prisoner", "데피아즈단 죄수", "grunt", 1000 },
    { "stk_convict", "데피아즈단 수감자", "stalker", 800 },
    { "stk_insurgent", "데피아즈단 반란자", "soldier", 700 },
    { "stk_inmate", "데피아즈단 재소자", "berserk", 500 },
}, {
    { "stk_targorr", "무시무시한 타고르", { as = 100, skills = { P.frenzy("광기", 12, 6, 50), P.enrage("격노", 0.4, 35) } } },
    { "stk_kam", "캄 딥퓨리", { skills = { P.smash("방패 가격", 230, 8), P.guard("방패 방벽", 16, 5, 50) } } },
    { "stk_hamhock", "햄혹", { range = 800, elem = LIGHT, skills = { P.nova("연쇄 번개", LIGHT, 130, 9), P.frenzy("피의 욕망", 18, 6, 40) } } },
    { "stk_bazil", "바질 스레드", { skills = { P.status("연막탄", "Stun", 14, 80, 300), P.wound("급소 찌르기", 10, 6, 30) } } },
    { "stk_dextren", "덱스트렌 워드", { skills = { P.status("위협의 외침", "Stun", 15, 60, 300), P.cleave("강타", 170, 4) } } },
})

dungeon(107, "놈리건", "던 모로", {
    { "gno_leper", "문둥병 노움", "fast", 1000, { elem = CHAOS } },
    { "gno_invader", "방사능 침입자", "grunt", 800, { elem = CHAOS } },
    { "gno_sentry", "기계화 경비병", "tank", 500 },
    { "gno_tank", "기계 전차", "brute", 400, { elem = FIRE } },
    { "gno_bomb", "걸어다니는 폭탄", "berserk", 500, { elem = FIRE, area = 200 } },
}, {
    { "gno_grubbis", "그루비스", { skills = { P.adds("바실리스크 부르기", 18, 1, "칠흑의 바실리스크", 8, 80), P.cleave("휩쓸기", 160, 4) } } },
    { "gno_fallout", "방사성 폐기물", { hp = 260, elem = CHAOS, skills = { P.nova("방사능 구름", CHAOS, 120, 9), P.dot("방사능 화살", CHAOS, 45, 8, 8) } } },
    { "gno_electrocutioner", "기계화 문지기 6000", { hp = 250, elem = LIGHT, skills = { P.nova("연쇄 번개", LIGHT, 140, 8), P.status("과전류", "Shock", 12, 120, nil, LIGHT) } } },
    { "gno_pummeler", "고철 압축기 9-60", { hp = 260, as = 100, skills = { P.smash("압착", 260, 8), P.frenzy("과부하", 15, 6, 50) } } },
    { "gno_thermaplugg", "기계박사 텔마플러그", { hp = 280, skills = { P.adds("폭탄 투하", 12, 2, "걸어다니는 폭탄", 2, 150, 2.0), P.status("전기 충격", "Stun", 15, 100, 300, LIGHT), P.smash("강철 주먹", 240, 9) } } },
})

dungeon(108, "가시덩굴 우리", "불모의 땅", {
    { "rfk_defender", "가시덩굴 수호병", "soldier", 900 },
    { "rfk_geomancer", "가시덩굴 대지술사", "caster", 600, { elem = LIGHT } },
    { "rfk_boar", "가시덩굴 전투멧돼지", "stalker", 800 },
    { "rfk_priest", "죽음의머리 사제", "caster", 400, { elem = CHAOS } },
    { "rfk_bat", "우리 박쥐", "swarm", 500 },
}, {
    { "rfk_jargba", "죽음의 예언자 잘그바", { range = 800, elem = CHAOS, skills = { P.bolt("어둠의 화살", CHAOS, 230, 5), P.status("정신 지배", "Stun", 16, 50, nil, CHAOS, "random") } } },
    { "rfk_ramtusk", "대군주 램터스크", { hp = 240, skills = { P.status("전투의 외침", "Stun", 16, 60, 300), P.cleave("꿰뚫기", 180, 4) } } },
    { "rfk_agathelos", "흉포한 아가테로스", { as = 110, skills = { P.frenzy("광란", 12, 6, 60), P.smash("돌진", 230, 9) } } },
    { "rfk_halmgar", "대지부름꾼 할름가르", { range = 800, elem = LIGHT, skills = { P.adds("대지의 정령 소환", 16, 2, "대지의 정령", 4, 60), P.nova("연쇄 번개", LIGHT, 120, 10) } } },
    { "rfk_charlga", "서슬깃 차를가", { range = 800, elem = LIGHT, skills = { P.nova("연쇄 화살", LIGHT, 130, 8), P.heal("치유의 물결", 14, 12), P.dot("순결한 불꽃", FIRE, 40, 6, 10) } } },
})

dungeon(109, "붉은십자군 수도원: 묘지", "티리스팔 숲", {
    { "smg_torturer", "붉은십자군 고문관", "soldier", 800 },
    { "smg_acolyte", "붉은십자군 수행사제", "caster", 600, { elem = LIGHT } },
    { "smg_spirit", "울부짖는 혼령", "fast", 800, { elem = CHAOS } },
    { "smg_ghoul", "굶주린 구울", "tank", 500 },
}, {
    { "smg_vishas", "심문관 비샤스", { range = 800, elem = CHAOS, skills = { P.dot("어둠의 권능: 고통", CHAOS, 50, 8, 7), P.bolt("정신 분열", CHAOS, 220, 6) } } },
    { "smg_thalnos", "혈법사 탈노스", { range = 800, elem = FIRE, skills = { P.nova("화염 회오리", FIRE, 130, 9), P.bolt("화염 충격", FIRE, 240, 6), P.drain("생명력 흡수", CHAOS, 150, 12) } } },
})

------------------------------------------------------------------------
-- 액트 2
------------------------------------------------------------------------
dungeon(201, "붉은십자군 수도원: 도서관", "티리스팔 숲", {
    { "sml_hound", "붉은십자군 추적견", "stalker", 800 },
    { "sml_beastmaster", "붉은십자군 야수조련사", "archer", 500 },
    { "sml_adept", "붉은십자군 신도", "caster", 600, { elem = LIGHT } },
    { "sml_monk", "붉은십자군 수도사", "fast", 800 },
    { "sml_diviner", "붉은십자군 예언자", "caster", 400, { elem = FIRE } },
}, {
    { "sml_loksey", "사냥개조련사 록시", { skills = { P.adds("추적견 풀기", 16, 3, "붉은십자군 추적견", 3, 50), P.frenzy("피의 욕망", 14, 6, 40) } } },
    { "sml_doan", "신비술사 도안", { range = 800, elem = LIGHT, skills = { P.nova("신비한 폭발", LIGHT, 140, 7), P.guard("신비한 보호막", 20, 5, 70), P.status("변이", "Stun", 16, 40, nil, LIGHT, "random") } } },
})

dungeon(202, "붉은십자군 수도원: 무기고", "티리스팔 숲", {
    { "sma_soldier", "붉은십자군 병사", "soldier", 900 },
    { "sma_defender", "붉은십자군 방어병", "tank", 600 },
    { "sma_myrmidon", "붉은십자군 근위병", "brute", 500 },
    { "sma_evoker", "붉은십자군 기원사", "caster", 500, { elem = FIRE } },
}, {
    { "sma_herod", "헤로드", { hp = 280, skills = { P.cleave("소용돌이", 170, 3), P.enrage("격노", 0.5, 40, 20), P.smash("돌진", 230, 10) } } },
})

dungeon(203, "붉은십자군 수도원: 대성당", "티리스팔 숲", {
    { "smc_champion", "붉은십자군 용사", "brute", 600 },
    { "smc_abbot", "붉은십자군 대수도원장", "caster", 500, { elem = LIGHT } },
    { "smc_wizard", "붉은십자군 마법사", "caster", 600, { elem = FIRE } },
    { "smc_centurion", "붉은십자군 백부장", "soldier", 800 },
    { "smc_chaplain", "붉은십자군 군목", "grunt", 700 },
}, {
    { "smc_fairbanks", "종교재판관 페어뱅크스", { range = 800, elem = CHAOS, skills = { P.curse("피의 저주", 14, 8, 15), P.status("수면", "Stun", 15, 50, nil, CHAOS, "random"), P.heal("치유", 12, 13) } } },
    { "smc_mograine", "붉은십자군 사령관 모그레인", { hp = 260, skills = { P.smash("성전사의 일격", 250, 7, LIGHT), P.guard("신의 보호막", 20, 5, 70), P.status("심판의 망치", "Stun", 16, 100) } } },
    { "smc_whitemane", "종교재판관 화이트메인", { range = 800, elem = LIGHT, skills = { P.bolt("성스러운 일격", LIGHT, 250, 5), P.heal("치유", 20, 14, 0.5), P.status("깊은 잠", "Stun", 22, 40, 3000, LIGHT) } } },
})

dungeon(204, "가시덩굴 구릉", "불모의 땅", {
    { "rfd_skeleton", "얼어붙은 해골", "grunt", 900, { elem = COLD } },
    { "rfd_necro", "죽음의머리 강령술사", "caster", 600, { elem = CHAOS } },
    { "rfd_warrior", "가시덩굴 전사", "soldier", 800 },
    { "rfd_spider", "무덤 거미", "stalker", 700, { elem = CHAOS } },
    { "rfd_ghoul", "썩은 구울", "tank", 500 },
}, {
    { "rfd_tutenkash", "투텐카쉬", { as = 110, elem = CHAOS, skills = { P.dot("맹독", CHAOS, 50, 8, 8, "nearest"), P.status("거미줄", "Freeze", 14, 60, nil, CHAOS, "random") } } },
    { "rfd_mordresh", "불꽃눈 모르드레쉬", { range = 800, elem = FIRE, skills = { P.nova("화염 회오리", FIRE, 140, 8), P.bolt("화염구", FIRE, 250, 5) } } },
    { "rfd_glutton", "먹보", { hp = 280, skills = { P.wound("질병의 손길", 11, 6, 40), P.enrage("광란", 0.5, 30, 30) } } },
    { "rfd_ragglesnout", "넝마주둥이", { range = 800, elem = CHAOS, skills = { P.dot("어둠의 권능: 고통", CHAOS, 50, 8, 8), P.heal("치유", 15, 13), P.status("정신 지배", "Stun", 18, 40, nil, CHAOS, "random") } } },
    { "rfd_amnennar", "혹한의 암네나르", { range = 800, elem = COLD, skills = { P.bolt("얼음 화살", COLD, 260, 5), P.status("서리 회오리", "Freeze", 14, 90, 300, COLD), P.adds("서리 망령 소환", 20, 2, "서리 망령", 4, 60) } } },
})

dungeon(205, "울다만", "황야의 땅", {
    { "uld_dwarf", "어둠괴철로단 약탈자", "soldier", 800 },
    { "uld_shadowcaster", "어둠괴철로단 암흑술사", "caster", 600, { elem = CHAOS } },
    { "uld_trogg", "바위턱 트로그", "grunt", 900 },
    { "uld_golem", "대지의 수호자", "tank", 500 },
    { "uld_bat", "동굴 박쥐", "swarm", 500 },
}, {
    { "uld_revelosh", "레벨로쉬", { range = 800, elem = LIGHT, skills = { P.bolt("번개 화살", LIGHT, 240, 5), P.nova("연쇄 번개", LIGHT, 130, 9) } } },
    { "uld_ironaya", "아이로나야", { hp = 280, skills = { P.status("전투 발구르기", "Stun", 14, 120, 300), P.smash("대지의 강타", 260, 8) } } },
    { "uld_obsidian", "흑요석 파수꾼", { hp = 300, skills = { P.guard("주문 반사", 18, 6, 60), P.adds("흑요석 파편", 22, 2, "흑요석 파편", 4, 60) } } },
    { "uld_keeper", "고대의 바위 문지기", { hp = 280, skills = { P.status("모래 폭풍", "Stun", 16, 80, 300), P.cleave("휩쓸기", 170, 4) } } },
    { "uld_galgann", "갈간 파이어해머", { elem = FIRE, skills = { P.nova("화염 회오리", FIRE, 140, 8), P.dot("불꽃 채찍", FIRE, 50, 6, 9, "nearest") } } },
    { "uld_grimlok", "그림로크", { range = 800, elem = LIGHT, skills = { P.nova("연쇄 화살", LIGHT, 130, 8), P.frenzy("피의 욕망", 16, 6, 40), P.status("오그라드는 저주", "Chill", 14, 60, 3000, CHAOS) } } },
    { "uld_archaedas", "아카에다스", { hp = 320, skills = { P.status("대지의 격동", "Stun", 15, 140, 3000), P.adds("대지의 수호자 깨우기", 18, 2, "대지의 수호자", 5, 70), P.enrage("고대의 분노", 0.33, 40) } } },
})

dungeon(206, "줄파락", "타나리스", {
    { "zf_troll", "모래분노 광전사", "soldier", 900 },
    { "zf_witchdoctor", "모래분노 의술사", "caster", 500, { elem = LIGHT } },
    { "zf_axethrower", "모래분노 도끼투척병", "archer", 700 },
    { "zf_scarab", "풍뎅이", "swarm", 600 },
    { "zf_basilisk", "모래분노 바실리스크", "tank", 500 },
}, {
    { "zf_antusul", "안투술", { skills = { P.adds("사울 부르기", 16, 3, "안투술의 하수인", 4, 55), P.heal("치유의 물결", 14, 12), P.status("대지의 손아귀", "Freeze", 16, 60, 300) } } },
    { "zf_theka", "순교자 데카", { skills = { P.dot("열병", CHAOS, 50, 10, 9), P.smash("강타", 240, 8) } } },
    { "zf_zumrah", "의술사 줌라", { range = 800, elem = CHAOS, skills = { P.bolt("어둠의 화살", CHAOS, 250, 5), P.adds("좀비 일으키기", 14, 3, "줄파락 좀비", 3, 50), P.heal("치유의 물결", 12, 14) } } },
    { "zf_nekrum", "네크룸 거트츄어", { hp = 280, skills = { P.wound("열병", 11, 8, 40), P.cleave("휩쓸기", 170, 4) } } },
    { "zf_sezzziz", "어둠의 사제 세즈지즈", { range = 800, elem = CHAOS, skills = { P.bolt("어둠의 화살", CHAOS, 260, 5), P.heal("치유", 18, 12, 0.6), P.status("영혼의 절규", "Stun", 18, 40, 3000, CHAOS) } } },
    { "zf_ukorz", "족장 우코르즈 샌드스칼프", { hp = 280, as = 100, skills = { P.cleave("넓게 휘두르기", 180, 3), P.enrage("격노", 0.3, 40, 30), P.adds("루즐루 부르기", 30, 1, "루즐루", 20, 120) } } },
    { "zf_gahzrilla", "가즈릴라", { hp = 320, elem = COLD, skills = { P.nova("가즈릴라의 강타", COLD, 150, 9), P.status("얼음 못", "Freeze", 15, 100, 300, COLD) } } },
})

dungeon(207, "마라우돈: 외곽 동굴", "잊혀진 땅", {
    { "mar_ooze", "독성 진흙괴물", "tank", 500, { elem = CHAOS } },
    { "mar_satyr", "썩은가지 사티로스", "stalker", 800 },
    { "mar_lasher", "뒤틀린 채찍꾼", "grunt", 900 },
    { "mar_creeper", "덩굴 괴물", "caster", 600, { elem = CHAOS } },
    { "mar_hydra", "새끼 히드라", "soldier", 600, { elem = COLD } },
}, {
    { "mar_noxxion", "녹시온", { hp = 280, elem = CHAOS, skills = { P.nova("독구름", CHAOS, 130, 8), P.adds("녹시온의 자손", 18, 3, "녹시온의 자손", 3, 50) } } },
    { "mar_razorlash", "칼날채찍", { as = 110, skills = { P.cleave("휘감기", 170, 3), P.wound("찌르기", 11, 6, 35) } } },
    { "mar_vyletongue", "군주 바일텅", { range = 800, skills = { P.bolt("일제 사격", "Physical", 220, 5, "farthest"), P.status("연막", "Stun", 16, 40, nil, CHAOS, "random") } } },
    { "mar_celebras", "저주받은 셀레브라스", { range = 800, elem = LIGHT, skills = { P.bolt("천벌", LIGHT, 250, 5), P.status("휘감는 뿌리", "Freeze", 14, 60, nil, LIGHT, "random"), P.adds("타락한 자연의 군대", 20, 3, "타락한 나무정령", 3, 50) } } },
})

dungeon(208, "마라우돈: 대지노래 폭포", "잊혀진 땅", {
    { "mar_rock", "바위 정령", "tank", 600 },
    { "mar_rumbler", "지축을 울리는 자", "brute", 500 },
    { "mar_thresher", "원시 탈곡어", "stalker", 800, { elem = COLD } },
    { "mar_primordial", "원시 진흙괴물", "grunt", 900, { elem = CHAOS } },
    { "mar_caster", "대지노래 예언자", "caster", 500, { elem = LIGHT } },
}, {
    { "mar_landslide", "산사태", { hp = 320, skills = { P.status("짓밟기", "Stun", 14, 140, 300), P.smash("대지의 강타", 270, 8) } } },
    { "mar_gizlock", "땜장이 기즐록", { range = 800, elem = FIRE, skills = { P.bolt("폭탄", FIRE, 240, 5), P.zone("화염 방사", FIRE, 50, 250, 6, 12), P.status("연막탄", "Stun", 18, 40, nil, "Physical", "random") } } },
    { "mar_rotgrip", "썩은아귀", { hp = 300, as = 100, skills = { P.wound("찢어발기기", 10, 8, 40), P.frenzy("광란", 14, 6, 50) } } },
    { "mar_theradras", "공주 테라드라스", { hp = 340, skills = { P.nova("먼지 폭풍", "Physical", 140, 9), P.status("추방의 굉음", "Stun", 16, 120, 3000), P.smash("바위 강타", 280, 8), P.enrage("대지의 분노", 0.3, 35) } } },
})

dungeon(209, "아탈학카르 신전", "슬픔의 늪", {
    { "st_troll", "아탈라이 전사", "soldier", 900 },
    { "st_priest", "아탈라이 사제", "caster", 600, { elem = CHAOS } },
    { "st_dragonkin", "녹색 용혈족", "brute", 500 },
    { "st_whelp", "풋내기 녹색용", "swarm", 600, { elem = CHAOS } },
    { "st_mummy", "미라가 된 아탈라이", "tank", 500 },
}, {
    { "st_alarion", "아탈알라리온", { hp = 320, skills = { P.status("땅 울림", "Stun", 14, 130, 3000), P.cleave("휩쓸기", 180, 4) } } },
    { "st_dreamscythe", "드림사이드", { elem = CHAOS, skills = { P.nova("산성 숨결", CHAOS, 150, 8), P.status("날개 후려치기", "Stun", 16, 80, 300) } } },
    { "st_weaver", "위버", { elem = CHAOS, skills = { P.nova("산성 숨결", CHAOS, 150, 8), P.wound("부식성 독", 12, 8, 35) } } },
    { "st_avatar", "학카르의 화신", { hp = 300, elem = CHAOS, skills = { P.drain("피의 착취", CHAOS, 180, 9, "random"), P.curse("혀의 저주", 15, 8, 20), P.adds("학카르의 핏빛 수호자", 20, 2, "핏빛 수호자", 4, 60) } } },
    { "st_jammalan", "예언자 잠말란", { range = 800, elem = CHAOS, skills = { P.nova("대지 가르기 토템", FIRE, 140, 9), P.heal("치유의 물결", 16, 12), P.status("육체 변형", "Stun", 18, 40, nil, CHAOS, "random") } } },
    { "st_eranikus", "에라니쿠스의 사령", { hp = 340, elem = CHAOS, skills = { P.nova("산성 숨결", CHAOS, 160, 8), P.status("깊은 잠", "Stun", 18, 40, 3000, CHAOS), P.smash("전투 발구르기", 260, 9) } } },
})

------------------------------------------------------------------------
-- 액트 3
------------------------------------------------------------------------
dungeon(301, "검은바위 나락", "검은바위 산", {
    { "brd_dwarf", "분노의모루단 경비병", "soldier", 900 },
    { "brd_golem", "전투 골렘", "brute", 500 },
    { "brd_elemental", "불의 정령", "caster", 600, { elem = FIRE } },
    { "brd_rifleman", "분노의모루단 저격병", "archer", 600 },
    { "brd_emissary", "황혼의망치단 사절", "caster", 400, { elem = CHAOS } },
    { "brd_hound", "핏빛 사냥개", "stalker", 700, { elem = FIRE } },
}, {
    { "brd_gerstahn", "대심문관 게르스탄", { range = 800, elem = CHAOS, skills = { P.dot("어둠의 권능: 고통", CHAOS, 55, 8, 7), P.status("영혼의 절규", "Stun", 16, 40, 3000, CHAOS), P.guard("어둠의 보호막", 20, 5, 50) } } },
    { "brd_roccor", "군주 록코르", { hp = 300, skills = { P.status("대지 충격", "Stun", 13, 120, nil), P.nova("땅 울림", "Physical", 120, 10) } } },
    { "brd_grebmar", "사냥개조련사 그렙마르", { skills = { P.adds("핏빛 사냥개 풀기", 16, 3, "핏빛 사냥개", 3, 55), P.wound("깊은 상처", 11, 6, 35) } } },
    { "brd_loregrain", "화염술사 로어그레인", { elem = FIRE, skills = { P.nova("화염 충격", FIRE, 140, 8), P.dot("용암 채찍", FIRE, 55, 6, 9, "nearest"), P.adds("불타는 토템", 20, 1, "불타는 토템", 3, 90, 1.0, true) } } },
    { "brd_incendius", "불의 군주 인센디우스", { hp = 280, elem = FIRE, skills = { P.nova("불의 폭풍", FIRE, 150, 8), P.curse("원소의 저주", 15, 8, 20, FIRE) } } },
    { "brd_angerforge", "사령관 앵거포지", { hp = 300, as = 100, skills = { P.cleave("휩쓸기", 180, 3), P.enrage("격노", 0.3, 40, 30), P.adds("의무병 호출", 25, 2, "분노의모루단 의무병", 4, 50) } } },
    { "brd_argelmach", "골렘 군주 아젤마크", { range = 800, elem = LIGHT, skills = { P.nova("연쇄 번개", LIGHT, 150, 8), P.adds("골렘 가동", 22, 2, "분노의 골렘", 6, 80), P.guard("번개 보호막", 18, 6, 40) } } },
    { "brd_flamelash", "사절 플레임래쉬", { elem = FIRE, as = 110, skills = { P.dot("불꽃 채찍", FIRE, 60, 6, 6, "nearest"), P.adds("불타는 영혼", 14, 3, "불타는 영혼", 2, 60) } } },
    { "brd_magmus", "마그무스", { hp = 320, elem = FIRE, skills = { P.nova("불타는 대지", FIRE, 150, 9), P.status("전투 발구르기", "Stun", 14, 130, 300) } } },
    { "brd_thaurissan", "제왕 다그란 타우릿산", { hp = 320, skills = { P.smash("타우릿산의 손", 280, 7), P.status("타우릿산의 화신", "Stun", 16, 100, nil, FIRE, "random"), P.nova("화염 폭발", FIRE, 140, 11), P.enrage("제왕의 분노", 0.25, 40) } } },
})

dungeon(302, "검은바위 첨탑 하층", "검은바위 산", {
    { "lbrs_orc", "피투성이도끼 전사", "soldier", 900 },
    { "lbrs_ogre", "뾰족바위 오우거", "brute", 500 },
    { "lbrs_troll", "뾰족바위 도끼투척병", "archer", 600 },
    { "lbrs_warlock", "피투성이도끼 소환사", "caster", 500, { elem = CHAOS } },
    { "lbrs_spider", "첨탑 거미", "swarm", 600, { elem = CHAOS } },
}, {
    { "lbrs_omokk", "대영주 오모크", { hp = 320, skills = { P.status("기절시키기", "Stun", 14, 150, nil), P.cleave("휩쓸기", 180, 3), P.enrage("광포화", 0.3, 40) } } },
    { "lbrs_voshgajin", "어둠사냥꾼 보쉬가진", { range = 800, elem = CHAOS, skills = { P.curse("피의 저주", 14, 8, 20), P.status("주술", "Stun", 16, 40, nil, CHAOS, "random"), P.bolt("어둠의 화살", CHAOS, 250, 5) } } },
    { "lbrs_voone", "대장군 부네", { as = 110, skills = { P.wound("죽음의 일격", 10, 6, 40), P.smash("올려치기", 240, 7), P.frenzy("눈속임", 16, 5, 40) } } },
    { "lbrs_smolderweb", "여왕 불그물거미", { as = 110, elem = CHAOS, skills = { P.dot("어미의 젖", CHAOS, 60, 10, 8, "nearest"), P.adds("새끼거미", 14, 4, "첨탑 새끼거미", 2, 45) } } },
    { "lbrs_urok", "우로크 둠하울", { hp = 320, skills = { P.status("위협의 외침", "Stun", 16, 60, 3000), P.cleave("강타", 190, 3) } } },
    { "lbrs_zigris", "병참장교 지그리스", { range = 800, skills = { P.bolt("사격", "Physical", 260, 4, "farthest"), P.status("마취 화살", "Stun", 14, 60, nil, "Physical", "random") } } },
    { "lbrs_halycon", "할리콘", { as = 110, skills = { P.wound("찢어발기기", 10, 6, 35), P.frenzy("광란", 12, 6, 50) } } },
    { "lbrs_gizrul", "기즈룰", { as = 110, skills = { P.dot("치명적인 물어뜯기", CHAOS, 60, 6, 7, "nearest"), P.frenzy("광기", 12, 6, 60), P.enrage("새끼를 잃은 분노", 0.5, 30) } } },
    { "lbrs_wyrmthalak", "대군주 웜타라크", { hp = 320, skills = { P.nova("연쇄 번개", LIGHT, 150, 8), P.status("짓밟기", "Stun", 15, 120, 300), P.adds("증원 요청", 25, 2, "뾰족바위 전투대장", 6, 80) } } },
})

dungeon(303, "혈투의 전장: 동쪽", "페랄라스", {
    { "dme_treant", "뒤틀린 나무정령", "brute", 500 },
    { "dme_satyr", "야생 사티로스", "stalker", 800 },
    { "dme_lasher", "썩은가지 채찍꾼", "grunt", 900 },
    { "dme_imp", "야생의 임프", "caster", 600, { elem = FIRE } },
    { "dme_hound", "야생의 사냥개", "fast", 700 },
}, {
    { "dme_zevrim", "제브림 쏜후프", { range = 800, elem = CHAOS, skills = { P.drain("희생", CHAOS, 200, 10, "random"), P.nova("강렬한 고통", CHAOS, 130, 8) } } },
    { "dme_hydrospawn", "히드로스폰", { hp = 320, elem = COLD, skills = { P.nova("해일", COLD, 150, 8), P.adds("히드로스폰의 정령", 18, 2, "히드로스폰의 정령", 4, 60) } } },
    { "dme_lethtendris", "레스텐드리스", { range = 800, elem = CHAOS, skills = { P.bolt("어둠의 화살", CHAOS, 260, 4), P.dot("제물", FIRE, 55, 6, 8), P.curse("혀의 저주", 15, 8, 20) } } },
    { "dme_alzzin", "칼날바람 알진", { hp = 320, as = 110, skills = { P.wound("찢어발기기", 10, 8, 40), P.status("가시덤불", "Bleed", 9, 120, 300), P.nova("자연의 격노", LIGHT, 140, 10), P.enrage("야생의 분노", 0.3, 35) } } },
})

dungeon(304, "혈투의 전장: 서쪽", "페랄라스", {
    { "dmw_ghost", "엘드레스 유령", "grunt", 900, { elem = LIGHT } },
    { "dmw_surge", "마나 폭주", "caster", 600, { elem = LIGHT } },
    { "dmw_ancient", "돌처럼 굳은 고대정령", "tank", 500 },
    { "dmw_spectre", "엘드레스 망령", "stalker", 700, { elem = CHAOS } },
    { "dmw_remnant", "마나 잔재", "swarm", 600, { elem = LIGHT } },
}, {
    { "dmw_tendris", "텐드리스 워프우드", { hp = 340, skills = { P.status("짓밟기", "Stun", 13, 130, 300), P.status("휘감기", "Freeze", 16, 60, 3000, LIGHT), P.adds("고대정령 수호자", 22, 2, "나무껍질 수호병", 5, 70) } } },
    { "dmw_illyanna", "일리아나 레이븐오크", { range = 800, skills = { P.bolt("일제 사격", "Physical", 240, 4, "farthest"), P.nova("화살비", "Physical", 130, 9), P.adds("페라 부르기", 30, 1, "페라", 15, 110) } } },
    { "dmw_kalendris", "마법학자 칼렌드리스", { range = 800, elem = CHAOS, skills = { P.bolt("정신 분열", CHAOS, 270, 5), P.dot("어둠의 권능: 고통", CHAOS, 60, 8, 8), P.status("정신 지배", "Stun", 18, 40, nil, CHAOS, "random") } } },
    { "dmw_immolthar", "이몰타르", { hp = 340, skills = { P.wound("감염된 이빨", 10, 8, 40), P.adds("이몰타르의 눈", 16, 2, "이몰타르의 눈", 3, 70, 1.0, true), P.enrage("광포화", 0.3, 40, 30) } } },
    { "dmw_tortheldrin", "왕자 토르텔드린", { as = 110, skills = { P.cleave("소용돌이", 190, 3), P.nova("신비한 작렬", LIGHT, 140, 9), P.status("소환", "Stun", 16, 60, nil, LIGHT, "farthest") } } },
})

dungeon(305, "혈투의 전장: 북쪽", "페랄라스", {
    { "dmn_brute", "고르독 야수", "brute", 600 },
    { "dmn_mage", "고르독 마법사", "caster", 500, { elem = FIRE } },
    { "dmn_reaver", "고르독 파괴자", "soldier", 800 },
    { "dmn_hyena", "고르독 하이에나", "stalker", 700 },
    { "dmn_warlock", "고르독 흑마법사", "caster", 400, { elem = CHAOS } },
}, {
    { "dmn_moldar", "경비병 몰다르", { hp = 320, skills = { P.smash("방패 가격", 250, 7), P.frenzy("광란", 16, 6, 50), P.cleave("내려찍기", 180, 4) } } },
    { "dmn_stomper", "천둥발 크리그", { hp = 320, skills = { P.status("전투 발구르기", "Stun", 13, 140, 300), P.enrage("격노", 0.3, 40) } } },
    { "dmn_fengus", "경비병 펜구스", { hp = 320, skills = { P.smash("방패 가격", 250, 7), P.cleave("내려찍기", 180, 4) } } },
    { "dmn_slipkik", "경비병 슬립킥", { hp = 320, skills = { P.smash("방패 가격", 250, 7), P.frenzy("광란", 16, 6, 50) } } },
    { "dmn_kromcrush", "대장 크롬크러쉬", { hp = 340, skills = { P.status("위협의 외침", "Stun", 16, 60, 3000), P.cleave("필사의 가르기", 190, 3), P.adds("증원 요청", 25, 2, "고르독 약탈자", 5, 80) } } },
    { "dmn_chorush", "관찰자 초루쉬", { range = 800, elem = LIGHT, skills = { P.bolt("번개 화살", LIGHT, 260, 5), P.nova("연쇄 번개", LIGHT, 140, 9), P.heal("치유의 물결", 14, 12) } } },
    { "dmn_gordok", "왕 고르독", { hp = 360, skills = { P.smash("필사의 일격", 290, 7), P.status("전투 발구르기", "Stun", 14, 130, 300), P.wound("올려치기", 12, 8, 40), P.enrage("광전사의 격노", 0.3, 40, 30) } } },
})

dungeon(306, "스칼로맨스", "서부 역병지대", {
    { "sch_skeleton", "되살아난 해골", "grunt", 900 },
    { "sch_necro", "스칼로맨스 강령술사", "caster", 600, { elem = CHAOS } },
    { "sch_student", "스칼로맨스 수습생", "caster", 500, { elem = COLD } },
    { "sch_ghoul", "역병 걸린 구울", "tank", 500, { elem = CHAOS } },
    { "sch_construct", "되살아난 피조물", "brute", 400 },
}, {
    { "sch_kirtonos", "사자 키르토노스", { as = 110, elem = CHAOS, skills = { P.nova("날개 후려치기", "Physical", 140, 9), P.curse("혀의 저주", 15, 8, 20), P.status("장악", "Stun", 16, 80, nil, CHAOS, "random") } } },
    { "sch_jandice", "잔다이스 바로브", { range = 800, elem = CHAOS, skills = { P.adds("환영", 14, 4, "잔다이스의 환영", 1, 50), P.curse("피의 저주", 16, 8, 20) } } },
    { "sch_rattlegore", "들창어금니", { hp = 340, skills = { P.status("전투 발구르기", "Stun", 13, 140, 300), P.smash("연타", 270, 6) } } },
    { "sch_rasfrost", "서리속삭임 라스", { range = 800, elem = COLD, skills = { P.bolt("얼음 화살", COLD, 270, 4), P.status("얼음 무덤", "Freeze", 13, 80, nil, COLD, "random"), P.guard("얼음 보호막", 20, 5, 60) } } },
    { "sch_malicia", "조교 말리시아", { range = 800, elem = CHAOS, skills = { P.dot("부패", CHAOS, 60, 8, 7), P.heal("소생", 14, 12), P.status("수면", "Stun", 16, 40, nil, CHAOS, "random") } } },
    { "sch_krastinov", "학자 테올렌 크라스티노브", { hp = 320, as = 100, skills = { P.wound("가르기", 9, 8, 40), P.enrage("광란", 0.5, 35, 30), P.cleave("등 찌르기", 180, 3) } } },
    { "sch_polkelt", "현자 폴켈트", { elem = CHAOS, skills = { P.nova("독구름", CHAOS, 150, 8), P.dot("부식성 산", CHAOS, 60, 8, 9) } } },
    { "sch_ravenian", "라베니안", { hp = 340, skills = { P.cleave("가르기", 190, 3), P.status("짓밟기", "Stun", 14, 120, 300), P.wound("분쇄", 12, 8, 40) } } },
    { "sch_alexei", "군주 알렉세이 바로브", { elem = CHAOS, skills = { P.dot("제물", FIRE, 60, 8, 8), P.curse("부정의 오라", 12, 10, 20, CHAOS) } } },
    { "sch_gandling", "암흑스승 간들링", { range = 800, elem = CHAOS, skills = { P.bolt("신비한 화살", LIGHT, 280, 4), P.curse("암흑스승의 저주", 15, 8, 25), P.status("어둠의 차원문", "Stun", 14, 40, nil, CHAOS, "random"), P.adds("되살아난 수호병", 18, 3, "되살아난 수호병", 3, 60) } } },
})

dungeon(307, "스트라솔름: 붉은십자군 지구", "동부 역병지대", {
    { "stl_gallant", "붉은십자군 용감한 기사", "soldier", 900 },
    { "stl_priest", "붉은십자군 사제", "caster", 500, { elem = LIGHT } },
    { "stl_sorcerer", "붉은십자군 마술사", "caster", 600, { elem = FIRE } },
    { "stl_crusader", "붉은십자군 성전사", "tank", 500 },
    { "stl_skeleton", "해골 수호병", "grunt", 800 },
}, {
    { "stl_malown", "우체국장 말로운", { as = 110, elem = CHAOS, skills = { P.status("공포", "Stun", 14, 60, nil, CHAOS, "random"), P.curse("약화의 저주", 15, 8, 20), P.wound("등 찌르기", 10, 6, 35) } } },
    { "stl_unforgiven", "용서받지 못한 자", { elem = COLD, skills = { P.status("서리 회오리", "Freeze", 13, 90, 300, COLD), P.adds("복수의 유령", 16, 3, "복수의 유령", 3, 55) } } },
    { "stl_timmy", "잔혹한 티미", { hp = 340, as = 110, skills = { P.wound("탐욕스러운 발톱", 9, 8, 40), P.enrage("광란", 0.5, 35, 40) } } },
    { "stl_willey", "포병대장 윌리", { range = 800, skills = { P.bolt("사격", "Physical", 270, 4, "farthest"), P.zone("포격", FIRE, 60, 250, 6, 10), P.adds("붉은십자군 소총병", 20, 2, "붉은십자군 소총병", 3, 70, 1.2, true) } } },
    { "stl_galford", "기록관 갈포드", { range = 800, elem = FIRE, skills = { P.bolt("불덩이 작렬", FIRE, 300, 6), P.dot("타오르는 바람", FIRE, 60, 6, 8), P.nova("화염 회오리", FIRE, 140, 10) } } },
    { "stl_balnazzar", "발나자르", { hp = 360, elem = CHAOS, skills = { P.bolt("정신 분열", CHAOS, 290, 5), P.status("영혼의 절규", "Stun", 15, 60, 3000, CHAOS), P.cleave("가르기", 190, 3), P.status("수면", "Stun", 18, 40, nil, CHAOS, "random") } } },
})

dungeon(308, "스트라솔름: 언데드 지구", "동부 역병지대", {
    { "stu_ghoul", "굶주린 구울", "tank", 600 },
    { "stu_bat", "역병 박쥐", "swarm", 600, { elem = CHAOS } },
    { "stu_spitter", "독액 뿜는 자", "caster", 600, { elem = CHAOS } },
    { "stu_banshee", "통곡하는 밴시", "caster", 500, { elem = COLD } },
    { "stu_abomination", "누더기 공포병", "brute", 400 },
    { "stu_crypt", "지하마귀", "stalker", 700, { elem = CHAOS } },
}, {
    { "stu_anastari", "남작부인 아나스타리", { range = 800, elem = CHAOS, skills = { P.status("밴시의 울음", "Stun", 13, 120, 3000, CHAOS), P.curse("밴시의 저주", 15, 8, 20), P.status("빙의", "Stun", 20, 40, nil, CHAOS, "random") } } },
    { "stu_nerubenkan", "네룹엔칸", { as = 110, elem = CHAOS, skills = { P.dot("지하마귀 딱정벌레", CHAOS, 60, 8, 8), P.status("거미줄 감싸기", "Freeze", 14, 60, nil, CHAOS, "random"), P.adds("네루비안 부화", 16, 3, "네루비안 새끼", 2, 50) } } },
    { "stu_maleki", "냉혈한 말레키", { range = 800, elem = COLD, skills = { P.bolt("얼음 화살", COLD, 280, 4), P.status("얼음 무덤", "Freeze", 13, 80, nil, COLD, "random"), P.drain("생명력 흡수", CHAOS, 200, 10) } } },
    { "stu_magistrate", "집정관 바르실라스", { hp = 340, elem = FIRE, skills = { P.dot("타오르는 바람", FIRE, 65, 6, 6, "nearest"), P.status("지배", "Stun", 18, 40, nil, CHAOS, "random"), P.enrage("격노", 0.3, 40) } } },
    { "stu_ramstein", "먹보 람스타인", { hp = 380, skills = { P.status("짓밟기", "Stun", 13, 140, 300), P.smash("기절시키기", 290, 7) } } },
    { "stu_rivendare", "남작 리븐데어", { hp = 360, elem = CHAOS, skills = { P.nova("부정의 오라", CHAOS, 110, 5), P.cleave("필사의 일격", 200, 3), P.wound("죽음의 서약", 14, 8, 50), P.adds("해골 일으키기", 22, 4, "해골 하수인", 2, 50) } } },
})

dungeon(309, "검은바위 첨탑 상층", "검은바위 산", {
    { "ubrs_elite", "검은손 정예병", "soldier", 900 },
    { "ubrs_summoner", "검은손 소환사", "caster", 500, { elem = FIRE } },
    { "ubrs_dragonspawn", "분노날개 용혈족", "brute", 500, { elem = FIRE } },
    { "ubrs_whelp", "검은 새끼용", "swarm", 700, { elem = FIRE } },
    { "ubrs_assassin", "검은손 암살자", "stalker", 600 },
    { "ubrs_pyromancer", "검은손 화염술사", "caster", 400, { elem = FIRE } },
}, {
    { "ubrs_emberseer", "불의 수호자 엠버시어", { hp = 340, elem = FIRE, skills = { P.nova("화염 회오리", FIRE, 160, 7), P.bolt("불덩이 작렬", FIRE, 300, 7), P.enrage("풀려난 불길", 0.4, 30) } } },
    { "ubrs_solakar", "솔라카르 플레임리스", { elem = FIRE, skills = { P.adds("부화", 12, 4, "검은 새끼용", 2, 50), P.status("위협의 외침", "Stun", 16, 60, 3000) } } },
    { "ubrs_gyth", "기스", { hp = 360, elem = FIRE, skills = { P.nova("화염 숨결", FIRE, 170, 8), P.status("얼어붙는 숨결", "Chill", 14, 120, 3000, COLD), P.wound("부식성 산", 12, 8, 40) } } },
    { "ubrs_rend", "대족장 렌드 블랙핸드", { hp = 340, as = 110, skills = { P.cleave("소용돌이", 200, 3), P.wound("필사의 일격", 10, 8, 50), P.frenzy("광란", 14, 6, 50), P.enrage("격노", 0.3, 40) } } },
    { "ubrs_beast", "괴수", { hp = 380, elem = FIRE, skills = { P.nova("화염 폭발", FIRE, 160, 8), P.status("공포의 포효", "Stun", 14, 60, 3000), P.smash("돌진", 280, 9), P.dot("제물", FIRE, 60, 6, 10) } } },
    { "ubrs_drakkisath", "사령관 드라키사스", { hp = 400, elem = FIRE, skills = { P.cleave("가르기", 210, 3), P.dot("화염 일격", FIRE, 70, 8, 7, "nearest"), P.status("소환", "Stun", 16, 60, nil, FIRE, "random"), P.enrage("용군단의 분노", 0.25, 40, 20) } } },
})

-- 구간 키 → 원작 스테이지 표의 키(난이도 포함)
function Dungeons.stageKey(difficulty, sectionKey)
    return difficulty * 1000 + sectionKey
end

return Dungeons
