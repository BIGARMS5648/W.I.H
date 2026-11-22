-- 레이드 3종: 원작의 액트 보스(각 액트의 10번 스테이지) 자리에 들어간다.
-- 원작의 액트 보스는 한 마리다. 여기서는 그 레이드의 보스 전원을 차례로 상대한다 [원작 구조 / 독자 확장].
--   · 마지막 보스의 체력·공격력 = 원작 액트 보스의 값(Tables.STAGES[키].actBossFinal). 앞의 보스들은 체력이 그 35% [독자].
--   · 보스 사이에 영웅의 체력과 재사용 시간은 이어진다.
--   · 보스의 패턴은 난이도가 오를 때마다 하나씩 늘어난다(일반 2개 → 고통 5개) [원작 구조]. 목록의 앞에서부터 쓴다.
-- 보스의 이름은 오리지널의 것이고, 패턴의 구성과 수치는 이 프로젝트의 설계다 [독자].
-- 한국어 이름은 기억에 의존해 적었으므로 클라이언트의 공식 표기와 대조해 검수해야 한다(docs/STATUS.md).

local _, WIH = ...
local Monsters = WIH.module("Monsters")
local Raids = WIH.module("Raids")

local boss, P = Monsters.boss, Monsters.P
local FIRE, COLD, LIGHT, CHAOS, PHYS = "Fire", "Cold", "Lightning", "Chaos", "Physical"

-- 레이드 체력 [독자]: 보스 전원의 체력 합 = 원작 액트 보스의 체력. 보스가 여럿이면 마지막 보스가 FINAL_SHARE를 갖고
-- 나머지 보스가 남은 몫을 똑같이 나눈다(오닉시아처럼 한 명이면 그 보스가 전부). 원작의 한 판과 잡는 데 드는 시간이 같아진다.
Raids.FINAL_SHARE = 0.5

-- 보스 순번 i(보스 n명 중)의 체력 몫
function Raids.hpShare(i, n)
    if n <= 1 then return 1 end
    if i == n then return Raids.FINAL_SHARE end
    return (1 - Raids.FINAL_SHARE) / (n - 1)
end
Raids.TOKEN = { 190001, 190002, 190003, 190004 }        -- 난이도별 입장 재료(원작의 영혼석 자리) [원작]
Raids.TOKEN_NAME = "용사의 증표"
Raids.TOKEN_STAGE = 9                                   -- 각 액트의 9번 스테이지를 처음 클리어하면 그 난이도의 증표 1개 [원작]

Raids.byAct = {}

local function raid(act, name, zone, bosses)
    local r = { act = act, name = name, zone = zone, bosses = {} }
    for i, b in ipairs(bosses) do
        local def = boss(b[1], b[2], b[3])
        def.raid = true
        r.bosses[i] = b[1]
    end
    Raids.byAct[act] = r
end

raid(1, "오닉시아의 둥지", "먼지진흙 습지대", {
    { "ony_onyxia", "오닉시아", { elem = FIRE, skills = {
        P.cleave("가르기", 200, 3),
        P.nova("화염 숨결", FIRE, 180, 9),
        P.zone("용암 분출", FIRE, 70, 260, 6, 11),
        P.adds("알 부화", 16, 4, "오닉시아의 새끼용", 2, 45),
        P.enrage("깊은 숨결", 0.4, 40),
    } } },
})

raid(2, "화산 심장부", "검은바위 산", {
    { "mc_lucifron", "루시프론", { elem = CHAOS, skills = {
        P.dot("파멸의 예언", CHAOS, 50, 8, 10),
        P.curse("루시프론의 저주", 14, 8, 25),
        P.bolt("암흑 충격", CHAOS, 240, 6),
        P.adds("수호병 호출", 18, 2, "화염걸음 수호병", 4, 80),
        P.weaken("지배의 손길", 16, 6, 20),
    } } },
    { "mc_magmadar", "마그마다르", { elem = FIRE, skills = {
        P.frenzy("광란", 12, 5, 60),
        P.status("공포의 포효", "Stun", 16, 80, 3000),
        P.zone("용암 폭탄", FIRE, 80, 240, 6, 9),
        P.nova("용암 숨결", FIRE, 170, 10),
        P.enrage("격노", 0.3, 40),
    } } },
    { "mc_gehennas", "게헨나스", { range = 800, elem = CHAOS, skills = {
        P.zone("불의 비", FIRE, 80, 280, 6, 8),
        P.wound("게헨나스의 저주", 14, 10, 60),
        P.bolt("암흑 화살", CHAOS, 260, 5),
        P.adds("병사 호출", 18, 2, "화염걸음 병사", 4, 80),
        P.curse("암흑 취약", 16, 8, 20, CHAOS),
    } } },
    { "mc_garr", "가르", { elem = FIRE, skills = {
        P.adds("불꽃의 하수인", 14, 3, "불꽃의 하수인", 5, 70),
        P.smash("용암 주먹", 260, 8, FIRE),
        P.nova("폭발", FIRE, 150, 12),
        P.weaken("마력 억제", 16, 6, 20),
        P.enrage("분리의 분노", 0.5, 30),
    } } },
    { "mc_geddon", "남작 게돈", { elem = FIRE, skills = {
        P.nova("지옥불", FIRE, 200, 9),
        P.dot("살아있는 폭탄", FIRE, 90, 6, 11),
        P.zone("불타는 대지", FIRE, 70, 260, 8, 13),
        P.status("점화", "Ignite", 10, 120, 3000, FIRE),
        P.enrage("최후의 폭발", 0.2, 60),
    } } },
    { "mc_shazzrah", "샤즈라", { range = 800, elem = LIGHT, skills = {
        P.nova("비전 폭발", LIGHT, 190, 7),
        P.bolt("점멸 강타", LIGHT, 280, 6, "farthest"),
        P.curse("샤즈라의 저주", 14, 8, 30, LIGHT),
        P.guard("마법 보호막", 16, 5, 50),
        P.frenzy("마력 가속", 14, 6, 50),
    } } },
    { "mc_sulfuron", "설퍼론 사자", { elem = FIRE, skills = {
        P.adds("사제 호출", 15, 4, "화염걸음 사제", 4, 60, 1.4, true),
        P.heal("암흑 치유", 8, 12, 0.6),
        P.smash("불꽃 창", 270, 7, FIRE),
        P.weaken("위압의 외침", 14, 6, 20),
        P.frenzy("고무", 16, 8, 40),
    } } },
    { "mc_golemagg", "초열의 골레마그", { elem = FIRE, skills = {
        P.smash("용암 강타", 300, 7, FIRE),
        P.dot("용암 분사", FIRE, 60, 10, 8, "nearest"),
        P.adds("심장부 맹견", 16, 2, "심장부 맹견", 6, 90),
        P.nova("지진", PHYS, 170, 11),
        P.enrage("골레마그의 신념", 0.2, 50, 30),
    } } },
    { "mc_majordomo", "청지기 이그젝큐투스", { elem = FIRE, skills = {
        P.adds("정예병 호출", 14, 4, "화염걸음 정예병", 5, 80),
        P.guard("피해 보호막", 14, 6, 60),
        P.bolt("화염 작렬", FIRE, 280, 6),
        P.status("화형", "Ignite", 12, 150, nil, FIRE, "random"),
        P.heal("용암 치유", 10, 14, 0.5),
    } } },
    { "mc_ragnaros", "라그나로스", { elem = FIRE, skills = {
        P.smash("설퍼라스의 일격", 320, 7, FIRE),
        P.nova("라그나로스의 분노", FIRE, 220, 10),
        P.zone("용암 폭발", FIRE, 100, 280, 6, 8),
        P.adds("불꽃의 아들", 20, 6, "불꽃의 아들", 3, 70),
        P.enrage("불의 군주", 0.25, 50, 20),
    } } },
})

raid(3, "검은날개 둥지", "검은바위 산", {
    { "bwl_razorgore", "폭군 서슬송곳니", { elem = FIRE, skills = {
        P.cleave("가르기", 210, 3),
        P.nova("전쟁 발구르기", PHYS, 150, 10),
        P.bolt("불덩이 연발", FIRE, 260, 6),
        P.adds("용혈족 호출", 16, 3, "검은날개 용혈족", 5, 80),
        P.status("제압", "Stun", 15, 100, nil, PHYS, "nearest"),
    } } },
    { "bwl_vaelastrasz", "타락한 밸라스트라즈", { elem = FIRE, skills = {
        P.nova("화염 숨결", FIRE, 210, 8),
        P.dot("불타는 아드레날린", FIRE, 110, 8, 9),
        P.cleave("가르기", 220, 3, FIRE),
        P.frenzy("타락의 정수", 12, 6, 60),
        P.enrage("타오르는 생명", 0.3, 60),
    } } },
    { "bwl_lashlayer", "용기대장 래쉬레이어", { skills = {
        P.wound("필사의 일격", 9, 8, 50, 220),
        P.cleave("가르기", 220, 3),
        P.smash("후려치기", 300, 8),
        P.status("폭발 파동", "Stun", 14, 120, 300, FIRE),
        P.frenzy("광기", 15, 6, 50),
    } } },
    { "bwl_firemaw", "화염아귀", { elem = FIRE, skills = {
        P.nova("암흑 불길", FIRE, 190, 8),
        P.dot("화염 강타", FIRE, 60, 10, 6, "nearest"),
        P.smash("날개 후려치기", 260, 9),
        P.curse("화염 취약", 14, 8, 30, FIRE),
        P.enrage("용의 격노", 0.3, 40),
    } } },
    { "bwl_ebonroc", "에본로크", { elem = CHAOS, skills = {
        P.nova("암흑 불길", CHAOS, 190, 8),
        P.drain("에본로크의 그림자", CHAOS, 220, 9, "nearest"),
        P.smash("날개 후려치기", 260, 9),
        P.wound("그림자 낙인", 12, 8, 50),
        P.enrage("용의 격노", 0.3, 40),
    } } },
    { "bwl_flamegor", "플레임고르", { elem = FIRE, skills = {
        P.nova("암흑 불길", FIRE, 190, 8),
        P.frenzy("광란", 10, 5, 70),
        P.smash("날개 후려치기", 260, 9),
        P.zone("화염 채찍", FIRE, 80, 260, 6, 11),
        P.enrage("용의 격노", 0.3, 40),
    } } },
    { "bwl_chromaggus", "크로마구스", { elem = COLD, skills = {
        P.nova("서리 화상", COLD, 200, 9),
        P.nova("소각", FIRE, 200, 13),
        P.status("혈족의 고통: 청동", "Stun", 14, 80, nil, PHYS, "random"),
        P.curse("혈족의 고통", 15, 10, 25),
        P.frenzy("광란", 12, 6, 60),
    } } },
    { "bwl_nefarian", "네파리안", { elem = CHAOS, skills = {
        P.nova("암흑 불길", CHAOS, 230, 9),
        P.bolt("암흑 화살", CHAOS, 300, 5),
        P.status("위협의 포효", "Stun", 16, 80, 3000),
        P.adds("해골 용혈족", 18, 6, "해골 용혈족", 3, 70),
        P.enrage("용군단의 군주", 0.2, 50, 30),
    } } },
})

-- 난이도에 따른 보스 패턴 수 [원작 구조]: 일반 2, 악몽 3, 지옥 4, 고통 5
function Raids.skillCount(difficulty)
    return math.min(5, difficulty + 1)
end

function Raids.key(difficulty, act)
    return difficulty * 1000 + act * 100 + 10
end

return Raids
