# 05. 영구 성장 시스템 — 룬·펫·유물·업적 및 기타 (TBH: Task Bar Hero 조사 보고서)

- 조사일: 2026-11-21 ~ 22. 대상: Steam app 3678970 《TBH: Task Bar Hero》.
- 목적: 원작의 **규칙과 수치**를 사실로서 기록한다(코드·아트·문장은 옮기지 않음. 효과 설명은 모두 본 문서의 한국어 풀이이며, 원문 툴팁이 아니다).
- 태그: **[확인]** = 공식 자료 / 게임 데이터 추출 기반 DB / 독립된 2개 이상 출처 일치, **[추정]** = 단일 비공식 출처 또는 추론, **[미확인]** = 찾지 못함.
- 표기: 비용은 골드(G). `k`=1,000, `M`=1,000,000 (정확한 값만 축약, 반올림 없음).

## 0. 먼저 읽을 것 — 버전 기준과 데이터 확보 수준

| 항목 | 값 | 근거 |
|---|---|---|
| 정식 출시 | 2026-05-27 (KST 14:00, ver 1.00.01) | [확인] Steam 공지 "Official Release Date Announcement"(2026-05-08), "Hotfix Update) 1.00.01"(2026-05-27) |
| 조사 시점 최신 버전 | **1.3.2** (2026-10-27 핫픽스). 이후 11-09 서버 장애 공지, 11-12 개인정보 유출 공지뿐이며 신규 클라이언트 버전 공지는 없음 | [확인] Steam 뉴스 API 전체 117건 열람 |
| 대형 업데이트 | 1.01.00(2026-07-22, 밸런스) → **1.02.00 Plaguelands(2026-09-08)** → **1.3.0 Halloween & Relic(2026-10-22)** | [확인] 동일 |
| 예고(미출시) | 11월: 던전 4종, 신규 스킬, 최대 레벨 상향, 신규 난이도 | [확인] "October & November Update Plans"(2026-09-30). 11-21 현재 출시 공지 없음 |

**이 문서의 수치가 어느 버전 것인지** (과거 규칙과 현재 규칙을 섞지 않기 위해 절마다 다시 표기한다):

| 시스템 | 확보한 데이터 | 버전 | 수준 |
|---|---|---|---|
| 룬 노드 전체(키·효과·레벨별 수치·레벨별 비용·선행·좌표) | taskbarhero.wiki 내장 JSON(`/data/rune_tree.json`, `/data/runes.json`, `/data/t/rune_levels.json`) 197개 노드 | **v1.00.17 (2026-06-20)** — 사이트가 "Wiki data current as of this patch"라고 명시. 1.02.00 이전 상태 | [확인] 노드 단위 전량 |
| 룬 스탯별 집계(노드 수, 레벨당 수치 합) | flex.shunshu-labo.org "TBH DBAPP" `tbh-data.json` (253개 노드, 50개 스탯 묶음) | **v1.03.00 (데이터 갱신 2026-10-23)** | [확인] 집계 수준만. 1.02.00 이후 추가된 56개 노드의 **노드별 비용·좌표·선행은 미확보** |
| 펫 | taskbarhero.wiki `/data/t/pets.json`, `/data/t/pet_stats.json`(8종) + shunshu DBAPP(10종) + 공식 패치노트 | v1.00.17 + v1.03.00 | [확인] |
| 유물·유물함·공명·조율·봉헌 확률 | shunshu DBAPP `tbh-data.json`(유물 36종×10등급, 유물함 62종, 등급별 풀, 조율 비용, 봉헌 가중치) + 공식 1.3.0/1.3.2 패치노트 | **v1.03.00** | [확인] (tbhindex.com 수치와 검색 요약 수준에서 일치) |
| 업적 | Steam 커뮤니티 업적 페이지 + Steam API 달성률(80개) | 2026-11-21 시점 | [확인] |
| 스탯 합산 공식 | taskbarhero.wiki /mechanics(디컴파일 기반), shunshu /mechanics | v1.00.17 / v1.03.00 | [확인] 두 사이트 일치 |

---

## 1. 룬(Rune) 시스템

### 1.1 기본 규칙

- **구조**: 하나의 큰 트리(시작 노드 1개에서 뻗는 방사형 격자). 노드는 "룬"이며 각 노드는 1~10레벨을 가진다. 같은 이름의 룬이 여러 노드로 반복된다(예: "확장의 룬"은 26개 노드). [확인] taskbarhero.wiki 룬 트리 데이터(v1.00.17): 노드 197개, 연결선 195개.
- **구매 재화**: **골드 단 하나**. 레벨 테이블의 비용 아이템 키가 663개 레벨 전부 `100001`(=Gold, 통화 테이블에 통화는 1종뿐, 초기 보유량 100G)이다. 시작 노드 "전쟁의 룬"의 비용이 정확히 100G라서 새 계정의 초기 골드로 바로 살 수 있다. [확인] `/data/t/rune_levels.json`, `/data/t/currencies.json`
- **비용 곡선**: 공식(수식)이 아니라 **노드·레벨마다 값이 박힌 테이블**이다. 한 노드 안에서는 대체로 등차(+10%씩 등), 가지를 따라 다음 노드로 갈수록 대략 ×1.3~×1.5씩 뛴다(예: 탐색/정복 사슬의 115번 이후는 노드마다 첫 레벨 비용이 약 1.5배). 표 1.5 참고. [확인]
- **선행 조건**: 각 노드는 부모 노드 1개(연결선)에 매달린다. 데이터에는 노드별 `PrevNodeRequiredLevel`(부모에게 요구하는 레벨) 필드가 있고, 197개 중 14개만 값이 있다(1이 11개, 5가 3개). 값이 비어 있는 183개 노드에서 부모를 "1레벨만 찍으면 되는지 / 최대 레벨까지 찍어야 하는지"는 데이터만으로는 확정되지 않는다. [확인: 필드 존재와 값] / [미확인: 빈 값의 기본 규칙]
- **적용 범위**: **계정(파티) 공통**. 전투 룬의 스탯 ID가 전부 `AllHero…`(전 영웅)이고, 게임 코드상 스탯 출처 분류명이 `AccountStatus`이다. 플레이테스트 0.01.04 패치노트에 "룬 보너스가 새로 추가한 캐릭터에 적용되지 않고 재시작해야 적용되던 문제 수정"이 있어, 모든 영웅에게 적용되는 것이 의도임이 확인된다. 영웅 개별 룬은 없다. [확인] taskbarhero.wiki /mechanics, Steam 공지 "Playtest Update - ver 0.01.04"(2026-04-30)
- **해금 시점**: 영웅 레벨 3에서 룬 메뉴가 열린다. [추정] ExitLag 가이드(검색 요약으로만 확인, 원문 미열람)
- **초기화(respec)**: **공식 초기화 기능의 존재를 확인하지 못했다.** [미확인]
  - 공식 패치노트 117건 전체에 룬 초기화·환급 언급이 없다. [확인]
  - Steam 토론 "Rune Reset"(2026-06-02): 이용자가 "룬을 초기화할 방법을 찾지 못했다, 초기화 아이템/기능을 달라"고 요청. [확인: 글 존재] → 출시 직후에는 초기화가 없었던 것으로 보인다. [추정]
  - 상충: ExitLag 가이드는 "트리는 전부 초기화 가능"이라 쓰고, 다른 팬 위키 FAQ는 "룬은 영구 업그레이드라 리스펙 대상이 아니다"라고 쓴다(둘 다 검색 요약으로만 확인). 설계 시에는 "초기화 없음(영구 구매)"을 원작 기본값으로 보고, 초기화는 독자 편의 기능으로 따로 판단하는 편이 안전하다.
  - 1.3.2 패치노트: "비정상 상황/조작으로 최대 레벨을 넘은 룬은 최대 레벨로 고정한다." [확인]
- **이벤트 상자 예외**: 할로윈 상자는 일반·역병 지대 상자와 별도 보관(일반 40개/보스 40개)이며 "룬 효과가 적용되지 않는다". [확인] 1.3.0 패치노트

### 1.2 버전별 노드 수 변화

| 시점 | 노드 수 | 근거 |
|---|---|---|
| 플레이테스트(2026-04~05) | 미확인 | 이미 웨이브 수 감소 룬("Rune of Shortening" = 단축의 룬), 상자 보관 룬, 연금 골드 룬이 있었음. [확인] 0.01.02~0.01.05 패치노트 |
| 출시~1.01.05 | **197** | [확인] taskbarhero.wiki(v1.00.17, 197노드), taskbarherowiki.com(v1.00.09, "197 runes"), taskbarhero.co(v1.00.09 기준·v1.00.13 보정, 스탯별 룬 개수 동일). 이 기간 패치노트에 룬 노드 추가 언급 없음 |
| 1.02.00 (09-08) | 공식: "역병 지대 관련 룬 노드 **27개** + 그 외 **17개**(상자 드롭률 증가, 웨이브 수 감소 등) 추가" | [확인] 패치노트 |
| 1.02.03 (09-14) | 공식: 역병 지대 일반 상자 드롭 확률 노드 1개 + 역병 지대 스테이지 보스 상자 드롭 확률 노드 1개 추가 | [확인] 패치노트 |
| 1.3.0 (10-22) | 공식: 오프라인 경험치 룬 3개 + 액트 보스 경험치 룬 2개 추가, 기존 액트 보스 경험치 룬 1개의 수치 +2,000 → +10,000/레벨 | [확인] 패치노트 |
| v1.03.00 데이터 | **253** | [확인] shunshu DBAPP 스탯별 노드 수 합 = 253, tbhindex.com 제목 "All 253"(검색 결과) |

- **불일치(숨기지 않고 기록)**: 공식 발표를 더하면 197+44+2+5 = **248**인데 v1.03.00 데이터는 **253**이다. 스탯별로 대조하면 비(非)역병 노드 증가분은 22개(=17+5)로 공식과 정확히 맞고, 역병 계열은 데이터상 34개로 공식(27+2=29)보다 5개 많다. 원인(공지의 계수 누락인지, 비공개/미노출 노드인지)은 [미확인].
- v1.00.17 데이터의 특이점 2개: (a) 노드 1133(액트 보스 상자 보관 +1, 5M)은 연결선이 없는 고립 노드다. 1.02.00 패치노트의 "액트 보스 상자 최대 보관량 증가 노드 중 하나가 보이지 않던 문제 수정"과 부합한다. (b) 노드 409(광분의 룬)는 MaxLevel=5인데 레벨 행이 10개 있다. 다른 DB(gamewith.ai, 검색 요약)가 표기한 "196개 해금 / 총 10,035,090,050 G"는 이 197개 데이터에서 1133(5,000,000)과 409의 6~10레벨(425,000)을 뺀 값과 정확히 일치한다(10,040,515,050 − 5,425,000). [확인: 산술 일치]

### 1.3 스탯(효과) 종류별 집계 — v1.00.17 스냅샷, 오른쪽 끝 열만 v1.03.00

- 39종 스탯, 24개 룬 이름. "최대 합계 효과"는 그 스탯의 모든 노드를 최대 레벨까지 올렸을 때의 합.
- 표시 스케일: 퍼센트형 스탯은 원시값÷10 = %(예: 원시 100 = 10%). 이 문서의 %는 모두 환산 후 값이다. 근거와 출처 간 불일치는 1.7 참고.

| 분류 | 스탯 ID | 룬 이름(한/영) | 노드 수 | 총 레벨 | 최대 합계 효과 | 총비용(골드) | v1.03.00 노드 수 |
|---|---|---|---|---|---|---|---|
| 전투 | AllHeroAttackDamage | 전쟁의 룬/Rune of War | 4 | 12 | +12 | 1,200,100 | 7 |
| 전투 | AllHeroArmor | 방패의 룬/Rune of the Shield | 3 | 18 | +90 | 478,500 | 5 |
| 전투 | AllHeroMoveSpeed | 질풍의 룬/Rune of the Gale | 5 | 19 | +44% | 11,262,500 | 6 |
| 전투 | AllHeroAttackDamagePercent | 전쟁의 룬/Rune of War | 3 | 20 | +60% | 3,548,000 | 4 |
| 전투 | AllHeroArmorPercent | 방패의 룬/Rune of the Shield | 2 | 10 | +35% | 1,373,000 | 3 |
| 전투 | AllHeroAttackSpeed | 광분의 룬/Rune of Frenzy | 3 | 13 | +21% | 3,886,000 | 4 |
| 경제·파밍 | AdditionalGoldStageBoss | 재물의 룬/Rune of Wealth | 7 | 33 | +43180 | 323,681,000 | 7 |
| 경제·파밍 | AdditionalExpStageBoss | 성장의 룬/Rune of Growth | 7 | 33 | +43080 | 323,658,300 | 7 |
| 경제·파밍 | IncreaseGoldAmount | 재물의 룬/Rune of Wealth | 7 | 33 | +190% | 175,118,000 | 7 |
| 경제·파밍 | IncreaseExpAmount | 성장의 룬/Rune of Growth | 7 | 33 | +190% | 175,129,500 | 7 |
| 경제·파밍 | DropChanceNormalChestPercent | 탐색의 룬/Rune of Exploration | 15 | 71 | +396% | 2,576,614,500 | 17 |
| 경제·파밍 | DropChanceStageBossChestPercent | 정복의 룬/Rune of Conquest | 14 | 68 | +760% | 3,863,893,300 | 16 |
| 경제·파밍 | AdditionalGold | 재물의 룬/Rune of Wealth | 2 | 6 | +6 | 15,001,000 | 2 |
| 경제·파밍 | AdditionalGoldNormalMonster | 재물의 룬/Rune of Wealth | 3 | 4 | +12 | 90,120,000 | 3 |
| 경제·파밍 | AdditionalGoldActBoss | 재물의 룬/Rune of Wealth | 3 | 15 | +262500 | 251,950,000 | 3 |
| 경제·파밍 | AdditionalExp | 성장의 룬/Rune of Growth | 2 | 6 | +26 | 30,001,000 | 2 |
| 경제·파밍 | AdditionalExpNormalMonster | 성장의 룬/Rune of Growth | 2 | 2 | +2 | 1,015,000 | 2 |
| 경제·파밍 | AdditionalExpActBoss | 성장의 룬/Rune of Growth | 3 | 13 | +12800 | 151,821,000 | 5 |
| 경제·파밍 | WaveCountReduction | 단축의 룬/Rune of Brevity | 1 | 1 | -1 | 20,000,000 | 3 |
| 경제·파밍 | CubeAlchemyGoldPercent | 연금의 룬/Rune of Alchemy | 4 | 14 | +85% | 34,093,000 | 5 |
| 경제·파밍 | CubeExpPercent | 조합의 룬/Rune of Forging | 4 | 16 | +80% | 30,135,000 | 5 |
| 경제·파밍 | OfflineRewardGoldPercent | 비축의 룬/Rune of Hoarding | 5 | 21 | +210% | 97,228,000 | 5 |
| 경제·파밍 | OfflineRewardExpPercent | 수련의 룬/Rune of Training | 5 | 21 | +210% | 97,303,000 | 8 |
| 편의·해금 | MaxInventorySlot | 확장의 룬/Rune of Expansion | 26 | 84 | +84 | 174,217,750 | 26 |
| 편의·해금 | UnlockArrangeSlotCount | 지휘의 룬/Rune of Command | 2 | 2 | +2 | 151,000 | 2 |
| 편의·해금 | UnlockSkillSlotCount | 각성의 룬/Rune of Awakening | 1 | 1 | +1 | 50,000 | 1 |
| 편의·해금 | OpenOneTypeChestAllAtOnce | 개방의 룬/Rune of Opening | 1 | 1 | 해금 | 500 | 1 |
| 편의·해금 | MaxAmountNormalChest | 수납의 룬/Rune of Containment | 15 | 15 | +15 | 64,171,000 | 15 |
| 편의·해금 | OpenAllTypeChestAllAtOnce | 개방의 룬/Rune of Opening | 1 | 1 | 해금 | 10,000 | 1 |
| 편의·해금 | MaxAmountActBossChest | 무한의 룬/Rune of Infinity | 10 | 10 | +10 | 485,150,000 | 10 |
| 편의·해금 | MaxAmountStageBossChest | 금고의 룬/Rune of the Vault | 13 | 13 | +13 | 601,030,000 | 13 |
| 편의·해금 | UnlockOfflineReward | 안식의 룬/Rune of Repose | 1 | 1 | 해금 | 100 | 1 |
| 편의·해금 | UnlockStashPageCount | 보관의 룬/Rune of Storage | 3 | 3 | +3 | 53,010,000 | 3 |
| 편의·해금 | UnlockAutoOpenNormalChest | 태엽의 룬/Rune of the Mainspring | 1 | 1 | 해금 | 10,000 | 1 |
| 편의·해금 | UnlockAutoOpenStageBossChest | 태엽의 룬/Rune of the Mainspring | 1 | 1 | 해금 | 200,000 | 1 |
| 편의·해금 | ReduceAutoOpenNormalChestTime | 윤활의 룬/Rune of Lubrication | 4 | 18 | -39초 | 187,030,000 | 4 |
| 편의·해금 | ReduceAutoOpenStageBossChestTime | 윤활의 룬/Rune of Lubrication | 4 | 18 | -75초 | 187,450,000 | 4 |
| 편의·해금 | ReduceAutoOpenActBossChestTime | 윤활의 룬/Rune of Lubrication | 2 | 6 | -6초 | 8,100,000 | 2 |
| 편의·해금 | UnlockAutoOpenActBossChest | 태엽의 룬/Rune of the Mainspring | 1 | 1 | 해금 | 1,000,000 | 1 |
| **합계** |  |  | **197** | **658** |  | **10,040,090,050** | **253** (역병 계열 34개 포함) |

분류별 요약(v1.00.17):

- **전투 능력치 룬(6종 스탯, 20개 노드, 약 2,175만 G)**: 전 영웅 공격력 +12(고정) / +60%(증가), 방어력 +90 / +35%, 공격속도 +21%, 이동속도 +44%. 트리 전체 비용의 0.2%에 불과하다 — 룬 트리의 무게중심은 전투가 아니라 파밍·편의 쪽에 있다.
- **경제·파밍 룬(17종 스탯)**: 골드/경험치 %와 고정 추가량, 상자 드롭 확률 계수, 오프라인 보상 %, 큐브(연금 골드·큐브 경험치) %, 웨이브 수 감소.
- **편의·해금 룬(16종 스탯)**: 인벤토리 슬롯(+84), 창고 페이지(+3), 상자 보관량(일반 +15, 스테이지 보스 +13, 액트 보스 +10), 영웅 슬롯(+2), 스킬 슬롯(+1), 오프라인 보상 해금, 상자 자동 열기 해금·대기시간 단축, 상자 일괄 열기.
- 참고로 팬 사이트의 분류는 제각각이다: taskbarherowiki.com은 필터 8종(Chests/Combat/Cube/EXP/Gold/Hero/Offline/Slots), tbhindex.com은 가지 3종(Battle/Exploration/Reward)으로 나눈다(후자는 검색 요약). 게임 데이터 자체에는 "분류" 필드가 없다. [확인: 데이터에 분류 필드 없음]

핵심 해금 노드(설계에 직접 쓰이는 것, v1.00.17):

| 기능 | 노드(키) | 비용 | 비고 |
|---|---|---|---|
| 영웅(편성) 슬롯 +1 → 파티 2인 | 지휘의 룬(21) | 1,000 | 시작 → 성장(20) → 21 |
| 영웅(편성) 슬롯 +1 → 파티 3인 | 지휘의 룬(24) | 150,000 | 경로 21 → 확장(22) → 확장(23) → 24. 23과 24는 데이터에 "부모 Lv1 요구"가 명시됨. tbhindex 집계 "지휘 2노드 합 151,000"과 일치 |
| 전 영웅 스킬 슬롯 +1 | 각성의 룬(27) | 50,000 | 경로 21 → 재물(25) → 성장(26) → 27. 26과 27은 "부모 Lv1 요구" 명시 |
| 오프라인 보상 해금 | 안식의 룬(11001) | 100 | 최대 8시간(28,800초)분 누적, 약 30일 이상 미접속 시 0(시계 조작 방지) — taskbarhero.wiki /mechanics [추정: 단일 출처] |
| 일반 상자 자동 열기 | 태엽의 룬(13002) | 10,000 | 기본 대기 300초(5분), 윤활의 룬으로 최대 −39초 |
| 스테이지 보스 상자 자동 열기 | 태엽의 룬(15001) | 200,000 | 기본 대기 600초(10분), 최대 −75초 |
| 액트 보스 상자 자동 열기 | 태엽의 룬(1902001) | 1,000,000 | 기본 대기 60초(1분), 최대 −6초 |
| 같은 종류 상자 일괄 열기(우클릭) | 개방의 룬(1021) | 500 | |
| 모든 종류 상자 일괄 열기(스페이스) | 개방의 룬(1055) | 10,000 | |
| 스테이지 웨이브 수 −1 | 단축의 룬(1171) | 20,000,000 | v1.03.00에서는 3개 노드(합 −3) |
| 창고 페이지 +1 ×3 | 보관의 룬(13001/16001/160011) | 10k / 3M / 50M | 합 53,010,000 (tbhindex 집계와 일치) |

### 1.4 트리 배치(좌표계)

- 좌표는 72단위 격자다. 아래 표의 "격자(x,y)"는 (x/72, −y/72)로 환산한 값이며 +y가 화면 위쪽이다. 범위: x −12~+21, y −6~+9. [확인] `/data/rune_tree.json`의 bounds(minX −864, maxX 1512, minY −648, maxY 432)
- 시작 노드 "전쟁의 룬"(키 1)이 (0,0). 위로 재물(10) → 확장 줄기(11~16), 아래로 성장(20) → 지휘(21).
- 재물(10)에서 동쪽으로 탐색/정복 사슬(101~128, 상자 드롭), 서쪽으로 재물 사슬(201~215, 골드). 성장(20)에서 서쪽으로 성장 사슬(301~315, 경험치), 동쪽으로 전투 사슬(401~414).
- 확장 줄기 꼭대기(16)에서 서쪽(1801~1808)·동쪽(1901~1908)으로 고가 확장 사슬이 뻗고, 거기에 오프라인 보상·자동 열기 단축 노드가 매달린다.
- 사슬형 가지는 "A 스탯 노드 → B 스탯 노드"가 번갈아 나오고(탐색↔정복, 골드%↔보스 골드, 경험치%↔보스 경험치), 일정 간격으로 곁가지(보관량, 큐브, 고정 추가량)가 붙는 구조다.

### 1.5 노드 전체 표 — **v1.00.17 (1.02.00 이전)**, 197개

- 출처: https://taskbarhero.wiki/runes (페이지 내장 JSON), 교차 확인: https://taskbarhero.wiki/data/t/rune_levels.json (663행). [확인]
- "레벨당 효과"는 1레벨당 증가량(모든 노드에서 레벨 간 동일). "선행(요구Lv)"의 괄호는 데이터에 명시된 부모 요구 레벨(없으면 비어 있음).
- **주의**: 이 표는 현재(1.3.x) 트리가 아니다. 현재 트리는 여기에 56개 노드가 더 있고, 액트 보스 경험치 노드 1개의 수치가 다르다(1.6 참고). 1.02.00~1.3.0에서 기존 노드의 비용·위치가 바뀌었는지는 [미확인]이다(스탯별 "레벨당 수치 합"은 변경 노드 1개를 빼면 v1.03.00과 일치하므로 수치는 유지된 것으로 보인다 [추정]).

**중앙 시작부** — 3개 노드

| 키 | 이름(한/영) | 스탯 ID | 레벨당 효과 | 최대Lv | 레벨별 비용(골드) | 합계 | 선행(요구Lv) | 격자(x,y) |
|---|---|---|---|---|---|---|---|---|
| 1 | 전쟁의 룬 / Rune of War | AllHeroAttackDamage | 전 영웅 공격력 +1 | 1 | 100 | 100 | 시작 노드 | (0,0) |
| 10 | 재물의 룬 / Rune of Wealth | AdditionalGoldStageBoss | 스테이지 보스 처치 골드 +10 | 3 | 200 / 300 / 500 | 1,000 | 1 | (0,1) |
| 20 | 성장의 룬 / Rune of Growth | AdditionalExpStageBoss | 스테이지 보스 처치 경험치 +10 | 3 | 200 / 300 / 500 | 1,000 | 1 | (0,-1) |

**남쪽 줄기: 지휘·각성(영웅/스킬 슬롯)** — 7개 노드

| 키 | 이름(한/영) | 스탯 ID | 레벨당 효과 | 최대Lv | 레벨별 비용(골드) | 합계 | 선행(요구Lv) | 격자(x,y) |
|---|---|---|---|---|---|---|---|---|
| 21 | 지휘의 룬 / Rune of Command | UnlockArrangeSlotCount | 영웅(편성) 슬롯 +1 | 1 | 1k | 1,000 | 20 | (0,-2) |
| 22 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 500 / 1k / 1.5k | 3,000 | 21 | (-1,-3) |
| 23 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 5 | 5k / 7k / 10k / 15k / 20k | 57,000 | 22 (Lv1) | (-1,-4) |
| 24 | 지휘의 룬 / Rune of Command | UnlockArrangeSlotCount | 영웅(편성) 슬롯 +1 | 1 | 150k | 150,000 | 23 (Lv1) | (-1,-5) |
| 25 | 재물의 룬 / Rune of Wealth | IncreaseGoldAmount | 처치 골드 +5% | 3 | 500 / 1k / 1.5k | 3,000 | 21 | (1,-3) |
| 26 | 성장의 룬 / Rune of Growth | IncreaseExpAmount | 경험치 획득 +5% | 3 | 5k / 7k / 10k | 22,000 | 25 (Lv1) | (1,-4) |
| 27 | 각성의 룬 / Rune of Awakening | UnlockSkillSlotCount | 전 영웅 스킬 슬롯 +1 | 1 | 50k | 50,000 | 26 (Lv1) | (1,-5) |

**북쪽 줄기: 확장·보관·자동 열기·오프라인** — 21개 노드

| 키 | 이름(한/영) | 스탯 ID | 레벨당 효과 | 최대Lv | 레벨별 비용(골드) | 합계 | 선행(요구Lv) | 격자(x,y) |
|---|---|---|---|---|---|---|---|---|
| 11 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 300 / 350 / 400 | 1,050 | 10 | (0,2) |
| 12 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 1k / 1.2k / 1.5k | 3,700 | 11 | (0,3) |
| 13 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 5k / 6k / 7k | 18,000 | 12 | (0,4) |
| 14 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 20k / 25k / 30k | 75,000 | 13 | (0,5) |
| 15 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 100k / 110k / 120k | 330,000 | 14 | (0,6) |
| 16 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 300k / 330k / 360k | 990,000 | 15 | (0,7) |
| 11001 | 안식의 룬 / Rune of Repose | UnlockOfflineReward | 오프라인 보상 해금 | 1 | 100 | 100 | 11 (Lv1) | (-1,2) |
| 11002 | 수납의 룬 / Rune of Containment | MaxAmountNormalChest | 일반 상자 최대 보관 +1 | 1 | 1k | 1,000 | 11 (Lv1) | (1,2) |
| 11003 | 금고의 룬 / Rune of the Vault | MaxAmountStageBossChest | 스테이지 보스 상자 최대 보관 +1 | 1 | 30k | 30,000 | 11002 | (2,3) |
| 11004 | 무한의 룬 / Rune of Infinity | MaxAmountActBossChest | 액트 보스 상자 최대 보관 +1 | 1 | 50k | 50,000 | 11003 | (3,4) |
| 13001 | 보관의 룬 / Rune of Storage | UnlockStashPageCount | 창고 페이지 +1 | 1 | 10k | 10,000 | 13 | (-1,4) |
| 13002 | 태엽의 룬 / Rune of the Mainspring | UnlockAutoOpenNormalChest | 일반 상자 자동 열기 해금(기본 대기 300초) | 1 | 10k | 10,000 | 13 (Lv1) | (1,4) |
| 15001 | 태엽의 룬 / Rune of the Mainspring | UnlockAutoOpenStageBossChest | 스테이지 보스 상자 자동 열기 해금(기본 대기 600초) | 1 | 200k | 200,000 | 15 (Lv1) | (1,6) |
| 15002 | 비축의 룬 / Rune of Hoarding | OfflineRewardGoldPercent | 오프라인 보상 골드 +10% | 3 | 50k / 75k / 100k | 225,000 | 15 | (-1,6) |
| 16001 | 보관의 룬 / Rune of Storage | UnlockStashPageCount | 창고 페이지 +1 | 1 | 3M | 3,000,000 | 16 | (0,8) |
| 110011 | 비축의 룬 / Rune of Hoarding | OfflineRewardGoldPercent | 오프라인 보상 골드 +10% | 3 | 500 / 1k / 1.5k | 3,000 | 11001 | (-2,2) |
| 110012 | 수련의 룬 / Rune of Training | OfflineRewardExpPercent | 오프라인 보상 경험치 +10% | 3 | 500 / 1k / 1.5k | 3,000 | 11001 | (-2,3) |
| 130021 | 윤활의 룬 / Rune of Lubrication | ReduceAutoOpenNormalChestTime | 일반 상자 자동 열기 대기 -3초 | 3 | 5k / 10k / 15k | 30,000 | 13002 | (2,5) |
| 150011 | 윤활의 룬 / Rune of Lubrication | ReduceAutoOpenStageBossChestTime | 스테이지 보스 상자 자동 열기 대기 -5초 | 3 | 100k / 150k / 200k | 450,000 | 15001 | (2,6) |
| 150021 | 수련의 룬 / Rune of Training | OfflineRewardExpPercent | 오프라인 보상 경험치 +10% | 3 | 75k / 100k / 125k | 300,000 | 15002 | (-2,6) |
| 160011 | 보관의 룬 / Rune of Storage | UnlockStashPageCount | 창고 페이지 +1 | 1 | 50M | 50,000,000 | 16001 | (1,8) |

**북동 가지: 탐색/정복(상자 드롭)·상자 보관** — 69개 노드

| 키 | 이름(한/영) | 스탯 ID | 레벨당 효과 | 최대Lv | 레벨별 비용(골드) | 합계 | 선행(요구Lv) | 격자(x,y) |
|---|---|---|---|---|---|---|---|---|
| 101 | 탐색의 룬 / Rune of Exploration | DropChanceNormalChestPercent | 일반 상자 드롭 확률 계수 +10% | 3 | 500 / 500 / 500 | 1,500 | 10 | (1,1) |
| 102 | 정복의 룬 / Rune of Conquest | DropChanceStageBossChestPercent | 스테이지 보스 상자 드롭 확률 계수 +20% | 3 | 1k / 1.1k / 1.2k | 3,300 | 101 | (2,1) |
| 103 | 탐색의 룬 / Rune of Exploration | DropChanceNormalChestPercent | 일반 상자 드롭 확률 계수 +7% | 5 | 3k / 3.3k / 3.6k / 3.9k / 4.2k | 18,000 | 102 | (3,1) |
| 104 | 정복의 룬 / Rune of Conquest | DropChanceStageBossChestPercent | 스테이지 보스 상자 드롭 확률 계수 +15% | 5 | 8k / 8.5k / 9k / 9.5k / 10k | 45,000 | 103 | (4,1) |
| 105 | 탐색의 룬 / Rune of Exploration | DropChanceNormalChestPercent | 일반 상자 드롭 확률 계수 +7% | 5 | 30k / 33k / 36k / 39k / 42k | 180,000 | 104 | (5,1) |
| 106 | 정복의 룬 / Rune of Conquest | DropChanceStageBossChestPercent | 스테이지 보스 상자 드롭 확률 계수 +15% | 5 | 45k / 48k / 51k / 54k / 57k | 255,000 | 105 | (5,2) |
| 107 | 탐색의 룬 / Rune of Exploration | DropChanceNormalChestPercent | 일반 상자 드롭 확률 계수 +5% | 5 | 60k / 65k / 70k / 75k / 80k | 350,000 | 106 | (5,3) |
| 108 | 정복의 룬 / Rune of Conquest | DropChanceStageBossChestPercent | 스테이지 보스 상자 드롭 확률 계수 +10% | 5 | 150k / 160k / 170k / 180k / 190k | 850,000 | 107 | (6,3) |
| 109 | 탐색의 룬 / Rune of Exploration | DropChanceNormalChestPercent | 일반 상자 드롭 확률 계수 +5% | 5 | 150k / 170k / 190k / 210k / 230k | 950,000 | 108 | (7,3) |
| 110 | 정복의 룬 / Rune of Conquest | DropChanceStageBossChestPercent | 스테이지 보스 상자 드롭 확률 계수 +10% | 5 | 250k / 450k / 650k / 850k / 1.05M | 3,250,000 | 109 | (8,3) |
| 111 | 탐색의 룬 / Rune of Exploration | DropChanceNormalChestPercent | 일반 상자 드롭 확률 계수 +5% | 5 | 500k / 550k / 600k / 650k / 700k | 3,000,000 | 110 | (8,4) |
| 112 | 정복의 룬 / Rune of Conquest | DropChanceStageBossChestPercent | 스테이지 보스 상자 드롭 확률 계수 +10% | 5 | 700k / 750k / 800k / 850k / 900k | 4,000,000 | 111 | (9,4) |
| 113 | 탐색의 룬 / Rune of Exploration | DropChanceNormalChestPercent | 일반 상자 드롭 확률 계수 +5% | 5 | 900k / 990k / 1.08M / 1.17M / 1.26M | 5,400,000 | 112 | (10,4) |
| 114 | 정복의 룬 / Rune of Conquest | DropChanceStageBossChestPercent | 스테이지 보스 상자 드롭 확률 계수 +10% | 5 | 1.3M / 1.4M / 1.5M / 1.6M / 1.7M | 7,500,000 | 113 | (10,5) |
| 115 | 탐색의 룬 / Rune of Exploration | DropChanceNormalChestPercent | 일반 상자 드롭 확률 계수 +5% | 5 | 1.95M / 2.1M / 2.25M / 2.4M / 2.55M | 11,250,000 | 114 | (11,5) |
| 116 | 정복의 룬 / Rune of Conquest | DropChanceStageBossChestPercent | 스테이지 보스 상자 드롭 확률 계수 +10% | 5 | 2.93M / 3.15M / 3.38M / 3.6M / 3.83M | 16,890,000 | 115 | (12,5) |
| 117 | 탐색의 룬 / Rune of Exploration | DropChanceNormalChestPercent | 일반 상자 드롭 확률 계수 +5% | 5 | 4.4M / 4.73M / 5.07M / 5.4M / 5.75M | 25,350,000 | 116 | (12,6) |
| 118 | 정복의 룬 / Rune of Conquest | DropChanceStageBossChestPercent | 스테이지 보스 상자 드롭 확률 계수 +10% | 5 | 6.6M / 7.1M / 7.61M / 8.1M / 8.63M | 38,040,000 | 117 | (13,6) |
| 119 | 탐색의 룬 / Rune of Exploration | DropChanceNormalChestPercent | 일반 상자 드롭 확률 계수 +5% | 5 | 9.9M / 10.65M / 11.42M / 12.15M / 12.95M | 57,070,000 | 118 | (14,6) |
| 120 | 정복의 룬 / Rune of Conquest | DropChanceStageBossChestPercent | 스테이지 보스 상자 드롭 확률 계수 +10% | 5 | 12.87M / 15.98M / 17.13M / 18.23M / 19.43M | 83,640,000 | 119 | (15,6) |
| 121 | 탐색의 룬 / Rune of Exploration | DropChanceNormalChestPercent | 일반 상자 드롭 확률 계수 +5% | 5 | 19.31M / 23.97M / 25.7M / 27.35M / 29.15M | 125,480,000 | 120 | (15,7) |
| 122 | 정복의 룬 / Rune of Conquest | DropChanceStageBossChestPercent | 스테이지 보스 상자 드롭 확률 계수 +10% | 5 | 28.97M / 35.96M / 38.55M / 41.03M / 43.73M | 188,240,000 | 121 | (16,7) |
| 123 | 탐색의 룬 / Rune of Exploration | DropChanceNormalChestPercent | 일반 상자 드롭 확률 계수 +5% | 5 | 43.46M / 53.94M / 57.83M / 61.55M / 65.6M | 282,380,000 | 122 | (17,7) |
| 124 | 정복의 룬 / Rune of Conquest | DropChanceStageBossChestPercent | 스테이지 보스 상자 드롭 확률 계수 +10% | 5 | 65.19M / 80.91M / 86.75M / 92.33M / 98.4M | 423,580,000 | 123 | (18,7) |
| 125 | 탐색의 룬 / Rune of Exploration | DropChanceNormalChestPercent | 일반 상자 드롭 확률 계수 +5% | 5 | 97.79M / 121.37M / 130.13M / 138.5M / 147.6M | 635,390,000 | 124 | (19,7) |
| 126 | 정복의 룬 / Rune of Conquest | DropChanceStageBossChestPercent | 스테이지 보스 상자 드롭 확률 계수 +10% | 5 | 146.69M / 182.06M / 195.2M / 207.75M / 221.4M | 953,100,000 | 125 | (19,8) |
| 127 | 탐색의 룬 / Rune of Exploration | DropChanceNormalChestPercent | 일반 상자 드롭 확률 계수 +5% | 5 | 220.04M / 273.09M / 292.8M / 311.63M / 332.1M | 1,429,660,000 | 126 | (20,8) |
| 128 | 정복의 룬 / Rune of Conquest | DropChanceStageBossChestPercent | 스테이지 보스 상자 드롭 확률 계수 +10% | 5 | 330.06M / 409.64M / 439.2M / 467.45M / 498.15M | 2,144,500,000 | 127 | (21,8) |
| 1021 | 개방의 룬 / Rune of Opening | OpenOneTypeChestAllAtOnce | 우클릭으로 같은 종류 상자 일괄 열기 | 1 | 500 | 500 | 102 | (2,0) |
| 1031 | 수납의 룬 / Rune of Containment | MaxAmountNormalChest | 일반 상자 최대 보관 +1 | 1 | 20k | 20,000 | 103 (Lv1) | (3,2) |
| 1051 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 5 | 30k / 33k / 36k / 39k / 42k | 180,000 | 105 | (6,1) |
| 1052 | 수납의 룬 / Rune of Containment | MaxAmountNormalChest | 일반 상자 최대 보관 +1 | 1 | 50k | 50,000 | 1051 | (7,1) |
| 1053 | 탐색의 룬 / Rune of Exploration | DropChanceNormalChestPercent | 일반 상자 드롭 확률 계수 +7% | 3 | 40k / 45k / 50k | 135,000 | 1051 (Lv5) | (6,2) |
| 1054 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 5 | 100k / 110k / 120k / 130k / 140k | 600,000 | 1052 | (7,2) |
| 1055 | 개방의 룬 / Rune of Opening | OpenAllTypeChestAllAtOnce | 스페이스 키로 모든 종류 상자 일괄 열기 | 1 | 10k | 10,000 | 1051 | (6,0) |
| 1056 | 무한의 룬 / Rune of Infinity | MaxAmountActBossChest | 액트 보스 상자 최대 보관 +1 | 1 | 100k | 100,000 | 1051 | (7,0) |
| 1061 | 수납의 룬 / Rune of Containment | MaxAmountNormalChest | 일반 상자 최대 보관 +1 | 1 | 100k | 100,000 | 106 | (4,2) |
| 1071 | 금고의 룬 / Rune of the Vault | MaxAmountStageBossChest | 스테이지 보스 상자 최대 보관 +1 | 1 | 500k | 500,000 | 107 (Lv1) | (4,3) |
| 1072 | 수납의 룬 / Rune of Containment | MaxAmountNormalChest | 일반 상자 최대 보관 +1 | 1 | 200k | 200,000 | 107 | (5,4) |
| 1091 | 수납의 룬 / Rune of Containment | MaxAmountNormalChest | 일반 상자 최대 보관 +1 | 1 | 300k | 300,000 | 109 | (7,4) |
| 1101 | 수납의 룬 / Rune of Containment | MaxAmountNormalChest | 일반 상자 최대 보관 +1 | 1 | 500k | 500,000 | 110 | (9,3) |
| 1102 | 금고의 룬 / Rune of the Vault | MaxAmountStageBossChest | 스테이지 보스 상자 최대 보관 +1 | 1 | 1M | 1,000,000 | 110 | (9,2) |
| 1111 | 금고의 룬 / Rune of the Vault | MaxAmountStageBossChest | 스테이지 보스 상자 최대 보관 +1 | 1 | 1.5M | 1,500,000 | 111 | (8,5) |
| 1121 | 수납의 룬 / Rune of Containment | MaxAmountNormalChest | 일반 상자 최대 보관 +1 | 1 | 1M | 1,000,000 | 112 | (9,5) |
| 1131 | 수납의 룬 / Rune of Containment | MaxAmountNormalChest | 일반 상자 최대 보관 +1 | 1 | 2M | 2,000,000 | 113 | (11,3) |
| 1132 | 금고의 룬 / Rune of the Vault | MaxAmountStageBossChest | 스테이지 보스 상자 최대 보관 +1 | 1 | 3M | 3,000,000 | 113 | (11,4) |
| 1133 | 무한의 룬 / Rune of Infinity | MaxAmountActBossChest | 액트 보스 상자 최대 보관 +1 ※연결선 없음(고립 노드) | 1 | 5M | 5,000,000 | 없음 | (10,3) |
| 1141 | 금고의 룬 / Rune of the Vault | MaxAmountStageBossChest | 스테이지 보스 상자 최대 보관 +1 | 1 | 5M | 5,000,000 | 114 | (9,6) |
| 1142 | 수납의 룬 / Rune of Containment | MaxAmountNormalChest | 일반 상자 최대 보관 +1 | 1 | 3M | 3,000,000 | 114 | (10,6) |
| 1161 | 수납의 룬 / Rune of Containment | MaxAmountNormalChest | 일반 상자 최대 보관 +1 | 1 | 5M | 5,000,000 | 116 | (13,4) |
| 1171 | 단축의 룬 / Rune of Brevity | WaveCountReduction | 스테이지 웨이브 수 -1 | 1 | 20M | 20,000,000 | 117 | (11,7) |
| 1172 | 금고의 룬 / Rune of the Vault | MaxAmountStageBossChest | 스테이지 보스 상자 최대 보관 +1 | 1 | 10M | 10,000,000 | 117 | (12,7) |
| 1181 | 금고의 룬 / Rune of the Vault | MaxAmountStageBossChest | 스테이지 보스 상자 최대 보관 +1 | 1 | 50M | 50,000,000 | 118 | (13,5) |
| 1182 | 무한의 룬 / Rune of Infinity | MaxAmountActBossChest | 액트 보스 상자 최대 보관 +1 | 1 | 30M | 30,000,000 | 118 | (13,7) |
| 1191 | 수납의 룬 / Rune of Containment | MaxAmountNormalChest | 일반 상자 최대 보관 +1 | 1 | 10M | 10,000,000 | 119 | (14,7) |
| 1201 | 수납의 룬 / Rune of Containment | MaxAmountNormalChest | 일반 상자 최대 보관 +1 | 1 | 15M | 15,000,000 | 120 | (15,5) |
| 1202 | 금고의 룬 / Rune of the Vault | MaxAmountStageBossChest | 스테이지 보스 상자 최대 보관 +1 | 1 | 70M | 70,000,000 | 120 | (16,5) |
| 1203 | 무한의 룬 / Rune of Infinity | MaxAmountActBossChest | 액트 보스 상자 최대 보관 +1 | 1 | 50M | 50,000,000 | 120 | (16,6) |
| 1221 | 금고의 룬 / Rune of the Vault | MaxAmountStageBossChest | 스테이지 보스 상자 최대 보관 +1 | 1 | 90M | 90,000,000 | 122 | (15,8) |
| 1222 | 무한의 룬 / Rune of Infinity | MaxAmountActBossChest | 액트 보스 상자 최대 보관 +1 | 1 | 60M | 60,000,000 | 122 | (16,8) |
| 1241 | 수납의 룬 / Rune of Containment | MaxAmountNormalChest | 일반 상자 최대 보관 +1 | 1 | 20M | 20,000,000 | 124 | (18,8) |
| 1251 | 금고의 룬 / Rune of the Vault | MaxAmountStageBossChest | 스테이지 보스 상자 최대 보관 +1 | 1 | 100M | 100,000,000 | 125 | (19,6) |
| 1252 | 무한의 룬 / Rune of Infinity | MaxAmountActBossChest | 액트 보스 상자 최대 보관 +1 | 1 | 70M | 70,000,000 | 125 | (20,6) |
| 1261 | 금고의 룬 / Rune of the Vault | MaxAmountStageBossChest | 스테이지 보스 상자 최대 보관 +1 | 1 | 120M | 120,000,000 | 126 | (18,9) |
| 1262 | 무한의 룬 / Rune of Infinity | MaxAmountActBossChest | 액트 보스 상자 최대 보관 +1 | 1 | 80M | 80,000,000 | 126 | (19,9) |
| 1281 | 금고의 룬 / Rune of the Vault | MaxAmountStageBossChest | 스테이지 보스 상자 최대 보관 +1 | 1 | 150M | 150,000,000 | 128 | (21,7) |
| 1282 | 무한의 룬 / Rune of Infinity | MaxAmountActBossChest | 액트 보스 상자 최대 보관 +1 | 1 | 90M | 90,000,000 | 128 | (21,9) |
| 11611 | 수납의 룬 / Rune of Containment | MaxAmountNormalChest | 일반 상자 최대 보관 +1 | 1 | 7M | 7,000,000 | 1161 | (13,3) |
| 12821 | 무한의 룬 / Rune of Infinity | MaxAmountActBossChest | 액트 보스 상자 최대 보관 +1 | 1 | 100M | 100,000,000 | 1282 | (21,6) |

**북서 가지: 재물(골드)·연금** — 24개 노드

| 키 | 이름(한/영) | 스탯 ID | 레벨당 효과 | 최대Lv | 레벨별 비용(골드) | 합계 | 선행(요구Lv) | 격자(x,y) |
|---|---|---|---|---|---|---|---|---|
| 201 | 재물의 룬 / Rune of Wealth | AdditionalGold | 추가 골드 +1 | 1 | 1k | 1,000 | 10 | (-1,1) |
| 202 | 재물의 룬 / Rune of Wealth | IncreaseGoldAmount | 처치 골드 +10% | 5 | 1k / 2k / 3k / 4k / 5k | 15,000 | 201 | (-2,1) |
| 203 | 재물의 룬 / Rune of Wealth | AdditionalGoldStageBoss | 스테이지 보스 처치 골드 +30 | 5 | 2k / 4k / 6k / 8k / 10k | 30,000 | 202 | (-3,1) |
| 204 | 재물의 룬 / Rune of Wealth | AdditionalGoldNormalMonster | 일반 몬스터 처치 골드 +1 | 1 | 20k | 20,000 | 203 | (-4,1) |
| 205 | 재물의 룬 / Rune of Wealth | AdditionalGoldActBoss | 액트 보스 처치 골드 +500 | 5 | 10k / 20k / 30k / 40k / 50k | 150,000 | 204 | (-5,1) |
| 206 | 재물의 룬 / Rune of Wealth | IncreaseGoldAmount | 처치 골드 +5% | 5 | 30k / 50k / 70k / 90k / 110k | 350,000 | 205 | (-5,2) |
| 207 | 재물의 룬 / Rune of Wealth | AdditionalGoldStageBoss | 스테이지 보스 처치 골드 +100 | 5 | 50k / 55k / 60k / 65k / 70k | 300,000 | 206 | (-5,3) |
| 208 | 재물의 룬 / Rune of Wealth | IncreaseGoldAmount | 처치 골드 +5% | 5 | 150k / 200k / 250k / 300k / 350k | 1,250,000 | 207 | (-6,3) |
| 209 | 재물의 룬 / Rune of Wealth | AdditionalGoldStageBoss | 스테이지 보스 처치 골드 +500 | 5 | 200k / 220k / 240k / 260k / 280k | 1,200,000 | 208 | (-7,3) |
| 210 | 재물의 룬 / Rune of Wealth | IncreaseGoldAmount | 처치 골드 +5% | 5 | 500k / 600k / 700k / 800k / 900k | 3,500,000 | 209 | (-8,3) |
| 211 | 재물의 룬 / Rune of Wealth | AdditionalGoldStageBoss | 스테이지 보스 처치 골드 +1000 | 5 | 700k / 750k / 850k / 900k / 950k | 4,150,000 | 210 | (-8,4) |
| 212 | 재물의 룬 / Rune of Wealth | IncreaseGoldAmount | 처치 골드 +5% | 5 | 2M / 3M / 4M / 5M / 6M | 20,000,000 | 211 | (-9,4) |
| 213 | 재물의 룬 / Rune of Wealth | AdditionalGoldStageBoss | 스테이지 보스 처치 골드 +2000 | 5 | 3M / 3.3M / 3.6M / 3.9M / 4.2M | 18,000,000 | 212 | (-10,4) |
| 214 | 재물의 룬 / Rune of Wealth | IncreaseGoldAmount | 처치 골드 +5% | 5 | 20M / 25M / 30M / 35M / 40M | 150,000,000 | 213 | (-11,4) |
| 215 | 재물의 룬 / Rune of Wealth | AdditionalGoldStageBoss | 스테이지 보스 처치 골드 +5000 | 5 | 50M / 55M / 60M / 65M / 70M | 300,000,000 | 214 | (-11,5) |
| 2031 | 연금의 룬 / Rune of Alchemy | CubeAlchemyGoldPercent | 큐브 연금 골드 +10% | 1 | 20k | 20,000 | 203 | (-3,2) |
| 2032 | 조합의 룬 / Rune of Forging | CubeExpPercent | 큐브 경험치 +4% | 5 | 10k / 15k / 20k / 25k / 30k | 100,000 | 2031 | (-3,3) |
| 2071 | 재물의 룬 / Rune of Wealth | AdditionalGoldNormalMonster | 일반 몬스터 처치 골드 +1 | 1 | 100k | 100,000 | 207 | (-4,4) |
| 2091 | 재물의 룬 / Rune of Wealth | AdditionalGoldActBoss | 액트 보스 처치 골드 +2000 | 5 | 300k / 330k / 360k / 390k / 420k | 1,800,000 | 209 | (-7,4) |
| 2111 | 재물의 룬 / Rune of Wealth | AdditionalGold | 추가 골드 +1 | 5 | 1M / 2M / 3M / 4M / 5M | 15,000,000 | 211 | (-8,5) |
| 2131 | 연금의 룬 / Rune of Alchemy | CubeAlchemyGoldPercent | 큐브 연금 골드 +10% | 3 | 5M / 7M / 10M | 22,000,000 | 213 | (-10,3) |
| 2132 | 조합의 룬 / Rune of Forging | CubeExpPercent | 큐브 경험치 +5% | 5 | 1M / 2M / 3M / 4M / 5M | 15,000,000 | 213 | (-11,3) |
| 2151 | 재물의 룬 / Rune of Wealth | AdditionalGoldNormalMonster | 일반 몬스터 처치 골드 +5 | 2 | 40M / 50M | 90,000,000 | 215 | (-10,6) |
| 2152 | 재물의 룬 / Rune of Wealth | AdditionalGoldActBoss | 액트 보스 처치 골드 +50000 | 5 | 30M / 40M / 50M / 60M / 70M | 250,000,000 | 2151 | (-9,6) |

**남서 가지: 성장(경험치)·조합** — 23개 노드

| 키 | 이름(한/영) | 스탯 ID | 레벨당 효과 | 최대Lv | 레벨별 비용(골드) | 합계 | 선행(요구Lv) | 격자(x,y) |
|---|---|---|---|---|---|---|---|---|
| 301 | 성장의 룬 / Rune of Growth | AdditionalExp | 추가 경험치 +1 | 1 | 1k | 1,000 | 20 | (-1,-1) |
| 302 | 성장의 룬 / Rune of Growth | IncreaseExpAmount | 경험치 획득 +10% | 5 | 500 / 1k / 1.5k / 2k / 2.5k | 7,500 | 301 | (-2,-1) |
| 303 | 성장의 룬 / Rune of Growth | AdditionalExpStageBoss | 스테이지 보스 처치 경험치 +10 | 5 | 1k / 1.2k / 1.4k / 1.7k / 2k | 7,300 | 302 | (-3,-1) |
| 304 | 성장의 룬 / Rune of Growth | AdditionalExpNormalMonster | 일반 몬스터 처치 경험치 +1 | 1 | 15k | 15,000 | 303 | (-4,-1) |
| 305 | 성장의 룬 / Rune of Growth | AdditionalExpActBoss | 액트 보스 처치 경험치 +100 | 3 | 6k / 7k / 8k | 21,000 | 304 | (-5,-1) |
| 306 | 성장의 룬 / Rune of Growth | IncreaseExpAmount | 경험치 획득 +5% | 5 | 30k / 50k / 70k / 90k / 110k | 350,000 | 305 | (-6,-1) |
| 307 | 성장의 룬 / Rune of Growth | AdditionalExpStageBoss | 스테이지 보스 처치 경험치 +100 | 5 | 50k / 55k / 60k / 65k / 70k | 300,000 | 306 | (-6,-2) |
| 308 | 성장의 룬 / Rune of Growth | IncreaseExpAmount | 경험치 획득 +5% | 5 | 150k / 200k / 250k / 300k / 350k | 1,250,000 | 307 | (-6,-3) |
| 309 | 성장의 룬 / Rune of Growth | AdditionalExpStageBoss | 스테이지 보스 처치 경험치 +500 | 5 | 200k / 220k / 240k / 260k / 280k | 1,200,000 | 308 | (-7,-3) |
| 310 | 성장의 룬 / Rune of Growth | IncreaseExpAmount | 경험치 획득 +5% | 5 | 500k / 600k / 700k / 800k / 900k | 3,500,000 | 309 | (-8,-3) |
| 311 | 성장의 룬 / Rune of Growth | AdditionalExpStageBoss | 스테이지 보스 처치 경험치 +1000 | 5 | 700k / 750k / 850k / 900k / 950k | 4,150,000 | 310 | (-9,-3) |
| 312 | 성장의 룬 / Rune of Growth | IncreaseExpAmount | 경험치 획득 +5% | 5 | 2M / 3M / 4M / 5M / 6M | 20,000,000 | 311 | (-9,-4) |
| 313 | 성장의 룬 / Rune of Growth | AdditionalExpStageBoss | 스테이지 보스 처치 경험치 +2000 | 5 | 3M / 3.3M / 3.6M / 3.9M / 4.2M | 18,000,000 | 312 | (-10,-4) |
| 314 | 성장의 룬 / Rune of Growth | IncreaseExpAmount | 경험치 획득 +5% | 5 | 20M / 25M / 30M / 35M / 40M | 150,000,000 | 313 | (-11,-4) |
| 315 | 성장의 룬 / Rune of Growth | AdditionalExpStageBoss | 스테이지 보스 처치 경험치 +5000 | 5 | 50M / 55M / 60M / 65M / 70M | 300,000,000 | 314 | (-11,-5) |
| 3031 | 조합의 룬 / Rune of Forging | CubeExpPercent | 큐브 경험치 +10% | 1 | 35k | 35,000 | 302 | (-3,-2) |
| 3032 | 연금의 룬 / Rune of Alchemy | CubeAlchemyGoldPercent | 큐브 연금 골드 +4% | 5 | 10k / 12k / 14k / 17k / 20k | 73,000 | 3031 | (-3,-3) |
| 3061 | 성장의 룬 / Rune of Growth | AdditionalExpActBoss | 액트 보스 처치 경험치 +500 | 5 | 300k / 330k / 360k / 390k / 420k | 1,800,000 | 306 | (-7,-1) |
| 3091 | 성장의 룬 / Rune of Growth | AdditionalExpNormalMonster | 일반 몬스터 처치 경험치 +1 | 1 | 1M | 1,000,000 | 309 | (-7,-4) |
| 3121 | 조합의 룬 / Rune of Forging | CubeExpPercent | 큐브 경험치 +5% | 5 | 1M / 2M / 3M / 4M / 5M | 15,000,000 | 312 | (-8,-5) |
| 3122 | 연금의 룬 / Rune of Alchemy | CubeAlchemyGoldPercent | 큐브 연금 골드 +5% | 5 | 2M / 2.2M / 2.4M / 2.6M / 2.8M | 12,000,000 | 3121 | (-8,-6) |
| 3151 | 성장의 룬 / Rune of Growth | AdditionalExp | 추가 경험치 +5 | 5 | 5M / 5.5M / 6M / 6.5M / 7M | 30,000,000 | 315 | (-12,-5) |
| 3152 | 성장의 룬 / Rune of Growth | AdditionalExpActBoss | 액트 보스 처치 경험치 +2000 | 5 | 10M / 20M / 30M / 40M / 50M | 150,000,000 | 315 | (-10,-6) |

**남동 가지: 전투(공격/방어/속도)** — 19개 노드

| 키 | 이름(한/영) | 스탯 ID | 레벨당 효과 | 최대Lv | 레벨별 비용(골드) | 합계 | 선행(요구Lv) | 격자(x,y) |
|---|---|---|---|---|---|---|---|---|
| 401 | 방패의 룬 / Rune of the Shield | AllHeroArmor | 전 영웅 방어력 +5 | 3 | 2k / 2.5k / 3k | 7,500 | 20 | (1,-1) |
| 402 | 질풍의 룬 / Rune of the Gale | AllHeroMoveSpeed | 전 영웅 이동속도 +3% (증가) | 3 | 5k / 5.5k / 6k | 16,500 | 401 | (2,-1) |
| 403 | 방패의 룬 / Rune of the Shield | AllHeroArmor | 전 영웅 방어력 +5 | 10 | 2k / 4k / 6k / 8k / 10k / 12k / 15k / 18k / 21k / 25k | 121,000 | 402 | (3,-1) |
| 404 | 질풍의 룬 / Rune of the Gale | AllHeroMoveSpeed | 전 영웅 이동속도 +2% (증가) | 5 | 20k / 22k / 24k / 27k / 30k | 123,000 | 403 | (4,-1) |
| 405 | 전쟁의 룬 / Rune of War | AllHeroAttackDamagePercent | 전 영웅 공격력 +2% (증가) | 10 | 15k / 20k / 25k / 30k / 35k / 40k / 50k / 60k / 70k / 80k | 425,000 | 404 | (5,-1) |
| 406 | 질풍의 룬 / Rune of the Gale | AllHeroMoveSpeed | 전 영웅 이동속도 +2% (증가) | 5 | 20k / 22k / 24k / 27k / 30k | 123,000 | 405 | (5,-2) |
| 407 | 방패의 룬 / Rune of the Shield | AllHeroArmorPercent | 전 영웅 방어력 +2% (증가) | 5 | 20k / 22k / 24k / 27k / 30k | 123,000 | 406 | (6,-2) |
| 408 | 전쟁의 룬 / Rune of War | AllHeroAttackDamagePercent | 전 영웅 공격력 +3% (증가) | 5 | 20k / 22k / 24k / 27k / 30k | 123,000 | 407 | (7,-2) |
| 409 | 광분의 룬 / Rune of Frenzy | AllHeroAttackSpeed | 전 영웅 공격속도 +1% (증가) ※레벨 데이터는 10행(6~10레벨: 75k/80k/85k/90k/95k) 존재하나 MaxLevel=5 | 5 | 50k / 55k / 60k / 65k / 70k | 300,000 | 408 | (7,-2.97) |
| 410 | 방패의 룬 / Rune of the Shield | AllHeroArmor | 전 영웅 방어력 +5 | 5 | 50k / 60k / 70k / 80k / 90k | 350,000 | 409 | (7,-4) |
| 411 | 전쟁의 룬 / Rune of War | AllHeroAttackDamage | 전 영웅 공격력 +1 | 5 | 80k / 100k / 120k / 140k / 160k | 600,000 | 410 | (8,-4) |
| 412 | 방패의 룬 / Rune of the Shield | AllHeroArmorPercent | 전 영웅 방어력 +5% (증가) | 5 | 150k / 200k / 250k / 300k / 350k | 1,250,000 | 411 | (9,-4) |
| 413 | 전쟁의 룬 / Rune of War | AllHeroAttackDamagePercent | 전 영웅 공격력 +5% (증가) | 5 | 200k / 400k / 600k / 800k / 1M | 3,000,000 | 412 | (10,-4) |
| 414 | 광분의 룬 / Rune of Frenzy | AllHeroAttackSpeed | 전 영웅 공격속도 +2% (증가) | 5 | 300k / 500k / 700k / 900k / 1.1M | 3,500,000 | 413 | (10,-5) |
| 4031 | 전쟁의 룬 / Rune of War | AllHeroAttackDamage | 전 영웅 공격력 +1 | 1 | 30k | 30,000 | 403 (Lv1) | (3,-2) |
| 4061 | 광분의 룬 / Rune of Frenzy | AllHeroAttackSpeed | 전 영웅 공격속도 +2% (증가) | 3 | 25k / 28k / 33k | 86,000 | 406 | (5,-3) |
| 4081 | 전쟁의 룬 / Rune of War | AllHeroAttackDamage | 전 영웅 공격력 +1 | 5 | 50k / 70k / 100k / 150k / 200k | 570,000 | 408 | (8,-2) |
| 4082 | 질풍의 룬 / Rune of the Gale | AllHeroMoveSpeed | 전 영웅 이동속도 +5% (증가) | 1 | 5M | 5,000,000 | 4081 | (9,-3) |
| 4101 | 질풍의 룬 / Rune of the Gale | AllHeroMoveSpeed | 전 영웅 이동속도 +2% (증가) | 5 | 1M / 1.1M / 1.2M / 1.3M / 1.4M | 6,000,000 | 410 | (7,-5) |

**최북단 서쪽 가지: 확장 + 오프라인 보상** — 14개 노드

| 키 | 이름(한/영) | 스탯 ID | 레벨당 효과 | 최대Lv | 레벨별 비용(골드) | 합계 | 선행(요구Lv) | 격자(x,y) |
|---|---|---|---|---|---|---|---|---|
| 1801 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 1M / 1.2M / 1.4M | 3,600,000 | 16 | (-1,7) |
| 1802 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 1.3M / 1.56M / 1.82M | 4,680,000 | 1801 | (-2,7) |
| 1803 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 1.69M / 2,030,000 / 2.37M | 6,090,000 | 1802 | (-3,7) |
| 1804 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 2.2M / 2.64M / 3.08M | 7,920,000 | 1803 | (-4,7) |
| 1805 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 2.86M / 3.43M / 4M | 10,290,000 | 1804 | (-5,7) |
| 1806 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 3.72M / 4.46M / 5.2M | 13,380,000 | 1805 | (-6,7) |
| 1807 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 4.84M / 5.8M / 6.76M | 17,400,000 | 1806 | (-7,7) |
| 1808 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 6.29M / 7.54M / 8.79M | 22,620,000 | 1807 | (-8,7) |
| 180201 | 비축의 룬 / Rune of Hoarding | OfflineRewardGoldPercent | 오프라인 보상 골드 +10% | 5 | 1M / 1.2M / 1.4M / 1.6M / 1.8M | 7,000,000 | 1802 | (-2,8) |
| 180301 | 수련의 룬 / Rune of Training | OfflineRewardExpPercent | 오프라인 보상 경험치 +10% | 5 | 1M / 1.2M / 1.4M / 1.6M / 1.8M | 7,000,000 | 1803 | (-3,8) |
| 180401 | 비축의 룬 / Rune of Hoarding | OfflineRewardGoldPercent | 오프라인 보상 골드 +10% | 5 | 5M / 5.5M / 6M / 6.5M / 7M | 30,000,000 | 1804 | (-4,6) |
| 180501 | 수련의 룬 / Rune of Training | OfflineRewardExpPercent | 오프라인 보상 경험치 +10% | 5 | 5M / 5.5M / 6M / 6.5M / 7M | 30,000,000 | 1805 | (-5,6) |
| 180601 | 비축의 룬 / Rune of Hoarding | OfflineRewardGoldPercent | 오프라인 보상 골드 +10% | 5 | 10M / 11M / 12M / 13M / 14M | 60,000,000 | 1806 | (-6,8) |
| 180701 | 수련의 룬 / Rune of Training | OfflineRewardExpPercent | 오프라인 보상 경험치 +10% | 5 | 10M / 11M / 12M / 13M / 14M | 60,000,000 | 1807 | (-7,8) |

**최북단 동쪽 가지: 확장 + 자동 열기 단축** — 17개 노드

| 키 | 이름(한/영) | 스탯 ID | 레벨당 효과 | 최대Lv | 레벨별 비용(골드) | 합계 | 선행(요구Lv) | 격자(x,y) |
|---|---|---|---|---|---|---|---|---|
| 1901 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 1M / 1.2M / 1.4M | 3,600,000 | 16 | (1,7) |
| 1902 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 1.3M / 1.56M / 1.82M | 4,680,000 | 1901 | (2,7) |
| 1903 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 1.69M / 2,030,000 / 2.37M | 6,090,000 | 1902 | (3,7) |
| 1904 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 2.2M / 2.64M / 3.08M | 7,920,000 | 1903 | (4,7) |
| 1905 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 2.86M / 3.43M / 4M | 10,290,000 | 1904 | (5,7) |
| 1906 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 3.72M / 4.46M / 5.2M | 13,380,000 | 1905 | (6,7) |
| 1907 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 4.84M / 5.8M / 6.76M | 17,400,000 | 1906 | (7,7) |
| 1908 | 확장의 룬 / Rune of Expansion | MaxInventorySlot | 인벤토리 슬롯 +1 | 3 | 6.29M / 7.54M / 8.79M | 22,620,000 | 1907 | (8,7) |
| 190301 | 윤활의 룬 / Rune of Lubrication | ReduceAutoOpenNormalChestTime | 일반 상자 자동 열기 대기 -2초 | 5 | 1M / 1.2M / 1.4M / 1.6M / 1.8M | 7,000,000 | 1903 | (3,6) |
| 190302 | 윤활의 룬 / Rune of Lubrication | ReduceAutoOpenStageBossChestTime | 스테이지 보스 상자 자동 열기 대기 -4초 | 5 | 1M / 1.2M / 1.4M / 1.6M / 1.8M | 7,000,000 | 1903 | (4,6) |
| 190401 | 윤활의 룬 / Rune of Lubrication | ReduceAutoOpenActBossChestTime | 액트 보스 상자 자동 열기 대기 -1초 | 3 | 1.5M / 2M / 2.5M | 6,000,000 | 1904 | (4,8) |
| 190501 | 윤활의 룬 / Rune of Lubrication | ReduceAutoOpenNormalChestTime | 일반 상자 자동 열기 대기 -2초 | 5 | 5M / 5.5M / 6M / 6.5M / 7M | 30,000,000 | 1905 | (5,6) |
| 190502 | 윤활의 룬 / Rune of Lubrication | ReduceAutoOpenStageBossChestTime | 스테이지 보스 상자 자동 열기 대기 -4초 | 5 | 5M / 5.5M / 6M / 6.5M / 7M | 30,000,000 | 1905 | (6,6) |
| 1902001 | 태엽의 룬 / Rune of the Mainspring | UnlockAutoOpenActBossChest | 액트 보스 상자 자동 열기 해금(기본 대기 60초) | 1 | 1M | 1,000,000 | 1902 | (2,8) |
| 1905011 | 윤활의 룬 / Rune of Lubrication | ReduceAutoOpenNormalChestTime | 일반 상자 자동 열기 대기 -2초 | 5 | 25M / 27.5M / 30M / 32.5M / 35M | 150,000,000 | 190501 (Lv5) | (5,5) |
| 1905021 | 윤활의 룬 / Rune of Lubrication | ReduceAutoOpenStageBossChestTime | 스테이지 보스 상자 자동 열기 대기 -4초 | 5 | 25M / 27.5M / 30M / 32.5M / 35M | 150,000,000 | 190502 (Lv5) | (6,5) |
| 19020011 | 윤활의 룬 / Rune of Lubrication | ReduceAutoOpenActBossChestTime | 액트 보스 상자 자동 열기 대기 -1초 | 3 | 500k / 700k / 900k | 2,100,000 | 1902001 | (3,8) |

### 1.6 1.02.00 ~ 1.3.0에서 추가·변경된 노드 — **v1.03.00**, 집계 수준

v1.03.00 DB의 스탯별 집계(노드 수, "레벨당 수치"의 노드 합, 총 레벨)를 v1.00.17 노드 표와 대조해 얻은 증가분이다. [확인: 두 데이터의 차이 계산] / 노드별 비용·좌표·선행은 [미확인].

| 스탯 ID | 룬 이름 | v1.00.17 노드 | v1.03.00 노드 | 추가 노드 | 추가분 "레벨당 수치" 합(원시→표시) | 추가 레벨 수 |
|---|---|---|---|---|---|---|
| AdditionalExpActBoss | Rune of Growth | 3 | 5 | +2 | 7000 → 7000 | 10 |
| AllHeroArmor | Rune of the Shield | 3 | 5 | +2 | 10 → 10 | 10 |
| AllHeroArmorPercent | Rune of the Shield | 2 | 3 | +1 | 20 → 2% | 5 |
| AllHeroAttackDamage | Rune of War | 4 | 7 | +3 | 4 → 4 | 15 |
| AllHeroAttackDamagePercent | Rune of War | 3 | 4 | +1 | 20 → 2% | 5 |
| AllHeroAttackSpeed | Rune of Frenzy | 3 | 4 | +1 | 20 → 2% | 5 |
| AllHeroMoveSpeed | Rune of the Gale | 5 | 6 | +1 | 10 → 1% | 5 |
| CubeAlchemyGoldPercent | Rune of Alchemy | 4 | 5 | +1 | 20 → 2% | 5 |
| CubeExpPercent | Rune of Forging | 4 | 5 | +1 | 20 → 2% | 5 |
| DropChanceNormalChestPercent | Rune of Exploration | 15 | 17 | +2 | 100 → 10% | 10 |
| DropChanceStageBossChestPercent | Rune of Conquest | 14 | 16 | +2 | 200 → 20% | 10 |
| DropChancePlagueNormalChestPercent | Plague Rune of Exploration | 0 | 4 | +4 | 500 → 50% | 20 |
| DropChancePlagueStageBossChestPercent | Plague Rune of Conquest | 0 | 3 | +3 | 1100 → 110% | 15 |
| OfflineRewardExpPercent | Rune of Training | 5 | 8 | +3 | 150 → 15% | 15 |
| WaveCountReduction | Rune of Brevity | 1 | 3 | +2 | 2 → 2 | 12 |
| MaxAmountPlagueNormalChest | Plague Rune of Containment | 0 | 5 | +5 | 5 → 5 | 30 |
| MaxAmountPlagueStageBossChest | Plague Rune of the Vault | 0 | 5 | +5 | 5 → 5 | 30 |
| MaxAmountPlagueActBossChest | Plague Rune of Infinity | 0 | 5 | +5 | 5 → 5 | 30 |
| UnlockAutoOpenPlagueNormalChest | Plague Rune of the Mainspring | 0 | 1 | +1 | 600 → 600 | 6 |
| UnlockAutoOpenPlagueStageBossChest | Plague Rune of the Mainspring | 0 | 1 | +1 | 1200 → 1200 | 6 |
| UnlockAutoOpenPlagueActBossChest | Plague Rune of the Mainspring | 0 | 1 | +1 | 120 → 120 | 6 |
| ReduceAutoOpenPlagueNormalChestTime | Plague Rune of Lubrication | 0 | 3 | +3 | 12 → 12 | 15 |
| ReduceAutoOpenPlagueStageBossChestTime | Plague Rune of Lubrication | 0 | 3 | +3 | 24 → 24 | 15 |
| ReduceAutoOpenPlagueActBossChestTime | Plague Rune of Lubrication | 0 | 3 | +3 | 3 → 3 | 15 |

- "추가분 레벨당 수치 합"은 새 노드들의 1레벨당 수치를 노드끼리 더한 값이다(예: 전 영웅 공격력% 새 노드 1개 = 레벨당 2%, 5레벨 → 합 10%). 보관량·자동 열기 해금·웨이브 감소 노드는 노드당 1레벨이다(shunshu DB의 "총 레벨" 집계는 1레벨 노드를 6으로 세는 표기 특성이 있어 그 열은 다레벨 노드에만 유효하다).
- 액트 보스 경험치: 기존 노드 1개가 +2,000 → +10,000/레벨로 바뀌었다(공식). v1.00.17 표에서 +2,000/레벨인 노드는 3152뿐이므로 이 노드로 보인다 [추정]. 그 변경을 반영하면 새 노드 2개의 레벨당 수치 합은 7,000이다.
- 오프라인 경험치: 새 노드 3개, 각 5레벨, 합 레벨당 15%(노드당 5% 추정) → 최대 +75%p 추가.
- 역병 지대 전용 자동 열기 기본 대기: 일반 600초(10분), 스테이지 보스 1,200초(20분), 액트 보스 120초(2분) — 일반 지역의 2배. 단축 합계: 일반 −60초, 스테이지 보스 −120초, 액트 보스 −15초(각 3노드×5레벨). [확인: shunshu 원시값] tbhindex 표기(−60s/−120s/−15s, 검색 요약)와 일치.
- 역병 지대 상자 드롭 확률 계수: 일반 상자 4노드×5레벨 합 +250%, 스테이지 보스 상자 3노드×5레벨 합 +550%. [확인: shunshu 원시 500/1100 ×5레벨÷10] 일반 쪽은 tbhindex "250% at max"와 일치.

tbhindex.com(v1.3.0 데이터마인이라고 자칭, Cloudflare 차단으로 직접 열람 실패 — 아래 수치는 **검색 엔진 요약으로만** 확인) [추정]:

| 묶음 | 노드 수 | 최대 레벨 | 최대 합계 | 전부 올리는 비용 |
|---|---|---|---|---|
| 전쟁의 룬(전 영웅 공격력 고정) | 7 | 5 | +32 | 1,216,200,100 → 신규 3노드 몫 약 1,215,000,000 |
| 전쟁의 룬(전 영웅 공격력 %) | 4 | 10 | 70% | 73,548,000 → 신규 1노드 몫 70,000,000 |
| 재물의 룬(처치 골드 %) | 7 | 5 | – | 175,118,000 (v1.00.17 표와 동일 = 변동 없음) |
| 탐색의 룬(일반 상자 드롭 계수) | 17 | – | – | 약 61억 |
| 단축의 룬(웨이브 수) | 3 | 1 | −3 | 670,000,000 → 신규 2노드 몫 650,000,000 |
| 역병 수납의 룬(역병 일반 상자 보관) | 5 | 1 | +5 | 771,000,000 |
| 역병 금고의 룬(역병 스테이지 보스 상자 보관) | 5 | 1 | +5 | 1,565,000,000 |
| 역병 무한의 룬(역병 액트 보스 상자 보관) | 5 | 1 | +5 | 2,540,000,000 |
| 역병 탐색의 룬(역병 일반 상자 드롭 계수) | 4 | 5 | 250% | 4,715,000,000 |
| 역병 태엽의 룬(역병 상자 자동 열기 해금 3종) | 3 | 1 | – | 노드당 30,000,000 ~ 150,000,000(액트 보스 150M) |
| 역병 윤활의 룬 | 9(3종×3) | 5 | 위 참조 | 한 종류 약 23.5억 |
| **트리 전체(253노드)** | 253 | | | **50,046,840,050** (v1.00.17의 197노드 10,040,515,050 대비 약 5배) |

- 위 표에서 v1.00.17 표로 검산 가능한 항목(지휘 151,000 / 각성 50,000 / 보관 53,010,000 / 처치 골드% 175,118,000 / 전쟁% 기존분 3,548,000)은 모두 일치했다. 따라서 tbhindex 수치의 신뢰도는 높다고 보지만, 원문을 직접 열람하지 못했으므로 [추정]으로 둔다.

### 1.7 수치 표시 스케일과 출처 간 불일치

- 게임 데이터의 퍼센트형 수치는 1/1000 단위(permille)다. 원시 100 = 10%. taskbarhero.wiki는 12개 룬 스탯(처치 골드%, 경험치%, 오프라인 골드/경험치%, 전 영웅 방어력%/공격력%/공격속도/이동속도, 큐브 연금 골드%/경험치%, 상자 드롭 계수 2종)을 ÷10 해서 표시한다. [확인: 사이트 스크립트]
- 독립 검증: 펫 "박쥐"의 원시값 150이 여러 매체와 공식 표기에서 "+15% EXP"로 나온다. 같은 스탯·같은 스케일이므로 룬도 ÷10이 맞다. taskbarhero.wiki /mechanics도 "오프라인 보상 골드/경험치 룬은 각 +10%, 합연산"이라 적는다. 플레이테스트 0.01.01 패치노트에 "펫 보유 효과가 실제 적용값의 10배 이상으로 표시되던 문제 수정"이 있어, 표시 배율 혼동이 개발 측에도 있었음을 알 수 있다. [확인]
- **불일치**: gamewith.ai와 taskbarheroguide.com은 같은 노드를 "+100%/레벨"(÷10 미적용)로 표기한다(검색 요약). 예: 비축의 룬 110011을 "최대 +300%"로 적은 곳과 "+30%"로 적은 곳이 공존한다. 다수 출처와 위 검증에 따라 **+10%/레벨이 맞다**고 판단한다.
- tbh.city의 단축의 룬 표기 "wave count +1"은 부호 오류로 보인다(다른 출처 전부 −1).

---

## 2. 펫(Pet) 시스템

### 2.1 규칙 요약

- 펫은 **전투에 참여하지 않는다**. 효과는 전부 파밍 보너스(경험치, 처치 골드, 상자 드롭 확률 계수)이며 전투 스탯·자동 줍기 같은 기능형 펫은 없다. [확인] 펫 스탯 테이블(11행)에 등장하는 스탯이 4종뿐(IncreaseExpAmount, IncreaseGoldAmount, DropChanceNormalChestPercent, DropChanceStageBossChestPercent)
- **보유 효과만 있고 장착 효과는 없다**: 해금한 펫의 효과는 그 펫을 편성(배치)하지 않아도 항상 적용되며, 모든 보유 펫의 효과가 동시에 중첩된다. [확인] 플레이테스트 0.01.04 패치노트 "펫을 배치하지 않아도 보유 효과가 적용된다는 안내를 펫 설명에 추가", shunshu DBAPP·Mobalytics(검색 요약) 일치
- 편성(Formation) UI에서 펫을 골라 화면에 데리고 다닐 수 있다(외형). 동시에 배치 가능한 수는 [미확인](1마리로 보임 [추정]).
- **펫 레벨/성장 없음**: 펫 테이블 필드는 키·이름·설명·스탯 키·해금 조건·파라미터 2개뿐이고 레벨·경험치·등급 필드가 없다. **등급(희귀도) 구분도 없다.** [확인] `/data/t/pets.json`
- 획득 경로 3종: (1) 특정 몬스터 누적 처치(`KillMonster`), (2) DLC "Supporter Pack"(Steam appid 4427390, 출시가 $3.99, 펫 3종), (3) 기간 한정 이벤트(역시 누적 처치). 부화·뽑기·상점 구매(게임 내 재화)는 없다. [확인]
- 적용 범위: 계정 공통(스탯이 전부 계정 단위 파밍 스탯). [확인]

### 2.2 펫 전체 표 — v1.03.00 기준 10종 (앞 8종은 v1.00.17부터 동일)

| 키 | 이름(한/영) | 해금 조건 | 효과(원시값 → 표시) | 추가 시점 |
|---|---|---|---|---|
| 1001 | 박쥐 / Bat | 박쥐(몬스터 10031) 5,000마리 처치 | 일반 상자 드롭 확률 계수 100 → +10%, 경험치 150 → +15% | 출시 |
| 1002 | 감시자 / Watcher | 거대 파리(20051) 5,000마리 처치 | 처치 골드 150 → +15% | 출시 |
| 1003 | 불타는 해골 / Burning Skeleton | 불의 정령(20091) 5,000마리 처치 | 스테이지 보스 상자 드롭 확률 계수 100 → +10% | 출시 |
| 1004 | 파란 골렘 / Blue Golem | 지옥의 골렘(30091) 5,000마리 처치 | 일반 상자 드롭 확률 계수 150 → +15% | 출시 |
| 1005 | 검은 정령 / Dark Spirit | 유령(30051) 5,000마리 처치 | 스테이지 보스 상자 드롭 확률 계수 150 → +15% | 출시 |
| 6001 | 검 / Sword | Supporter Pack DLC 보유 | 경험치 150 → +15% | 출시 |
| 6002 | 나비 / Butterfly | Supporter Pack DLC 보유 | 처치 골드 100 → +10% | 출시 |
| 6003 | 드래곤 / Dragon | Supporter Pack DLC 보유 | 일반 상자 드롭 확률 계수 200 → +20%, 처치 골드 150 → +15%, 경험치 200 → +20% | 출시 |
| 2001 | Pumpkin Candy | 할로윈 이벤트 스테이지의 Jack-o' Skeleton Warrior(5000102) 500마리 처치 | 처치 골드 +1% | 1.3.0 (이벤트 종료 2026-11-11 23:59 UTC, 이후 획득 불가) |
| 2002 | Pumpkin Ghost | 같은 스테이지의 Jack-o'-Lantern Ghost(5000103) 500마리 처치 | 경험치 +1% | 1.3.0 (동일) |

- 출처: https://taskbarhero.wiki/pets (내장 `/data/t/pets.json`, `/data/t/pet_stats.json`, v1.00.17), https://flex.shunshu-labo.org/en/tbh/pet/ (v1.03.00), 1.3.0 패치노트. 세 출처 수치 일치. [확인] (할로윈 펫 2종의 한국어 공식 명칭은 [미확인])
- 펫 스탯 테이블의 모드 타입은 전부 `FLAT`. [확인]
- 전 펫 보유 시 합계: 경험치 +51%, 처치 골드 +41%, 일반 상자 드롭 계수 +45%, 스테이지 보스 상자 드롭 계수 +25%. 무과금(DLC·이벤트 제외) 합계: 경험치 +15%, 골드 +15%, 일반 상자 +25%, 스테이지 보스 상자 +25%. [확인: 표의 합산]
- 대표 파밍 스테이지(taskbarhero.wiki 계산, v1.00.17): 박쥐 = 1-7 City Outskirts, 감시자 = 2-5 Scorching Dunes, 불타는 해골 = 2-8 Sacred Tomb, 파란 골렘 = 3-6 Burning Ravine, 검은 정령 = 3-4 Frozen Glacier Cavern. [추정: 사이트 계산값]
- 업적 "Friend of the Night"(박쥐 펫 해금)이 있다(5절).

---

## 3. 유물(Relic) 시스템 — **1.3.0(2026-10-22) 추가, 수치는 v1.03.00**

용어: 이 문서에서는 Relic = 유물, Reliquary = 유물함, Resonance = 공명, Attunement = 조율, Offering = 봉헌(큐브 레시피)으로 적는다. 한국어 클라이언트의 공식 번역어는 [미확인].

### 3.1 구조 [확인 — 공식 1.3.0 패치노트]

- **해금**: 역병 지대(Plaguelands)를 1회 이상 클리어하면 유물 UI가 열린다. (게임 내 잠금 문구 기준으로는 Nightmare 역병 지대 클리어 — shunshu·Steam 가이드 [확인: 2개 출처])
- **유물함(Reliquary)**: 장착하는 "받침"이다. 등급마다 무작위 **고유 능력치(Inherent Stats)**가 붙고, 그 효과는 **파티원 전원**에게 적용된다. Uncommon 이상은 무작위 색의 **유물 슬롯**을 가진다.
- **유물(Relic)**: 유물함의 슬롯에 끼운다. 유물 종류마다 정해진 고유 능력치 1개를 가지며 역시 **파티원 전원**에게 적용된다. 유물에는 색이 있고 **같은 색 슬롯에만** 들어간다. **흰색 유물은 어떤 색 슬롯에도** 들어간다.
- **공명(Resonance)**: 일부 유물함에는 공명 효과가 있다. 그 유물함에 끼운 유물의 색 구성이 조건(예: 빨강 2 + 파랑 1)을 만족하면 발동하고, 파티원 전원에게 특수 효과를 준다.
- **획득**: 역병 지대 보물 상자와 "오염된 액트 보스" 보물 상자에서 일정 확률로 **오염된 유물함 / 오염된 유물**(재료 아이템)이 나온다. 이것을 큐브의 **봉헌** 레시피에 넣으면 무작위 유물함/유물이 된다.
- **합성**: 유물함과 유물 모두 큐브의 합성(Synthesis) 레시피로 합성할 수 있다.
- **조율(Attunement)**: 1.3.0에서 추가된 큐브 레시피. 골드를 써서 유물함은 **슬롯 색을 재추첨**(모든 색 동일 확률), 유물은 **고유 능력치 수치를 범위 안에서 재추첨**한다. 비용은 아이템별로 시도할 때마다 오르다가 상한에서 멈춘다.

보충 [확인 — shunshu 가이드, Steam 가이드(Killdozer), 업적 목록이 서로 일치]:

- **장착 수**: 유물함은 **최대 2개** 장착. 두 번째 장착 칸은 "Hell 역병 지대 – 역병 강도 10" 클리어로 열린다. 업적 "Double Resonance"(공명 효과 2개 동시 발동)가 이를 뒷받침한다.
- 공명 조건은 **유물함 단위로** 센다(다른 유물함에 끼운 유물은 합산하지 않음 — shunshu. Steam 가이드는 "게임 내에서 확인하라"고 유보) [추정].
- 봉헌으로 얻은 유물함/유물은 **거래 불가**(오염된 재료 상태일 때는 Steam 장터 거래 가능 — 장터에 "Contaminated Relic (Arcana)" 등 등록 확인).
- 유물 색은 5종: 빨강(Crimson), 파랑(Azure), 노랑(Golden), 보라(Violet), 흰색(White). 색과 등급은 독립이다.
- 한 유물함의 최대 슬롯은 8(Cosmic). 업적 "Reliquary Complete"(8슬롯 전부 장착).

### 3.2 유물함 등급별 슬롯 수·고유 능력치 수·능력치 풀

- 고유 능력치는 아래 9종 풀에서 등급별 범위로 무작위 추첨된다(풀은 모든 유물함 공통, 풀의 행 가중치는 동일). 조율로는 바뀌지 않는다(조율은 슬롯 색만). [확인] shunshu `relicPools`, Steam 가이드
- 표의 수치는 표시값(%) 범위. 원시값은 표시값×10(저항 2종은 원시값=표시값).

| 등급 | 유물 슬롯 수 | 고유 능력치 줄 수 | 공격력 증가(%) (AttackDamage:ADDITIVE) | 최대 HP 증가(%) (MaxHp:ADDITIVE) | 치명타 피해(+%p) (CriticalDamage:FLAT) | 공격·시전 속도 증가(%) (AttackAndCastSpeed:ADDITIVE) | 재사용 대기시간 감소(+%) (CooldownReduction:FLAT) | 모든 원소 저항(+%) (AllElementalResistance:FLAT) | 혼돈 저항(+%) (ChaosResistance:FLAT) | 피해 감소(+%) (DamageReduction:FLAT) | 이동속도 증가(%) (MovementSpeed:ADDITIVE) |
|---|---|---|---|---|---|---|---|---|---|---|---|
| Common | 0 | 1 | 5~10 | 5~8 | 10~15 | 4~5 | 3~5 | 4~8 | 10~20 | 3~5 | 10~20 |
| Uncommon | 1 | 1 | 10~15 | 8~11 | 15~20 | 5~6 | 3.5~5.5 | 6~10 | 13~23 | 3.5~5.5 | 13~23 |
| Rare | 2 | 1 | 15~20 | 11~14 | 20~25 | 6~7 | 4~6 | 8~12 | 17~27 | 4~6 | 16~26 |
| Legendary | 3 | 1 | 20~25 | 14~17 | 25~30 | 7~9 | 4.5~6.5 | 10~14 | 20~30 | 4.5~6.5 | 18~28 |
| Immortal | 3 | 2 | 25~30 | 17~20 | 30~35 | 9~11 | 5~7 | 12~16 | 23~33 | 5~7 | 21~31 |
| Arcana | 4 | 2 | 30~35 | 20~25 | 35~40 | 11~13 | 5.5~7.5 | 14~18 | 27~37 | 5.5~7.5 | 24~34 |
| Beyond | 5 | 2 | 35~40 | 25~30 | 40~45 | 13~15 | 6~8 | 16~20 | 30~40 | 6~8 | 27~37 |
| Celestial | 6 | 2 | 40~45 | 30~35 | 50~60 | 15~17 | 6.5~8.5 | 18~22 | 33~43 | 6.5~8.5 | 29~39 |
| Divine | 7 | 2 | 45~50 | 35~40 | 60~70 | 17~20 | 7~9 | 20~25 | 37~47 | 7~9 | 32~42 |
| Cosmic | 8 | 3 | 50~55 | 40~50 | 70~80 | 20~25 | 7.5~9.5 | 25~30 | 40~50 | 7.5~9.5 | 35~45 |

- 슬롯 수/능력치 줄 수: Legendary와 Immortal은 슬롯이 같고(3) 능력치 줄 수만 1→2로 늘어난다. 3줄은 Cosmic뿐. [확인] shunshu 등급 데이터, Steam 가이드 서술 일치
- 모드 타입: `ADDITIVE` = "증가(Increased) %" 풀에 합산, `FLAT` = 해당 스탯에 그대로 가산(7절).

### 3.3 유물 36종(색별) × 10등급 = 360변형

- 수치는 등급별 **표시값 범위**(추첨 범위, 조율로 재추첨). % 스탯은 원시값÷10, 저항류는 원시값 그대로, 초당 HP 재생은 원시값÷100, 고정값 스탯은 그대로.
- 색별 개수: 빨강 9, 파랑 7, 노랑 10, 보라 8, 흰색 2. [확인] shunshu DBAPP, tbhindex(검색 요약: Red 90 / Blue 70 / Yellow 100 / Purple 80 / White 20 = 360), Steam 가이드 일치
- "Echo" 유물(색마다 1종, 총 5종)은 공명 조건을 셀 때 **2개로 계산**되는 대신 페널티 능력치를 가진다(빨강=화염 저항 감소, 파랑=냉기, 노랑=번개, 보라=혼돈, 흰색=공격력 감소). 페널티는 등급이 오를수록 줄고 Cosmic에서 0이 된다. Echo의 2개 계산은 능력치를 2배로 만들지 않는다.

| ID | 이름 | 색 | 고유 능력치(스탯ID:모드) | Common | Uncommon | Rare | Legendary | Immortal | Arcana | Beyond | Celestial | Divine | Cosmic | 비고 |
|---|---|---|---|---|---|---|---|---|---|---|---|---|---|---|
| 710001 | Crimson Relic - Blade | 빨강(Crimson) | 공격력 증가(%) (AttackDamage:ADDITIVE) | 2~6 | 3~8 | 4.5~10 | 6~12.5 | 7.5~15 | 9~17.5 | 10.5~20 | 12~23 | 13~25.5 | 14~28 |  |
| 710002 | Crimson Relic - Fang | 빨강(Crimson) | 체력 100% 적 대상 치명타 확률 계수 증가(%) (FullHpTargetCriticalChance:ADDITIVE) | 10~32.5 | 15~42.5 | 25~52.5 | 32.5~67.5 | 40~80 | 47.5~95 | 57.5~107.5 | 65~122.5 | 70~137.5 | 75~150 |  |
| 710003 | Crimson Relic - Horn | 빨강(Crimson) | 치명타 피해(+%p) (CriticalDamage:FLAT) | 4~13 | 6~17 | 9~21 | 13~27 | 16~32 | 19~37 | 22~43 | 26~49 | 28~55 | 30~60 |  |
| 710004 | Crimson Relic - Pulse | 빨강(Crimson) | 공격·시전 속도 증가(%) (AttackAndCastSpeed:ADDITIVE) | 2~6 | 2.5~7 | 3~8 | 3.5~9 | 4.5~10 | 5~11 | 5.5~12 | 6~13 | 6.5~14 | 7~15 |  |
| 710005 | Crimson Relic - Ash | 빨강(Crimson) | 화염 저항(+%) (FireResistance:FLAT) | 5~15 | 6~17 | 8~20 | 10~23 | 12~26 | 14~29 | 16~32 | 18~35 | 20~38 | 22~40 |  |
| 710006 | Crimson Relic - Spear | 빨강(Crimson) | 보스 대상 피해 증가(%) (BossDamage:ADDITIVE) | 2.5~7.5 | 4~10 | 5.5~12.5 | 7.5~15.5 | 9.5~19 | 11.5~22 | 13~25 | 15~29 | 16.5~32 | 17.5~35 |  |
| 710007 | Crimson Relic - Dawn | 빨강(Crimson) | 체력 100% 적 대상 피해 증가(%) (FullHpTargetDamage:ADDITIVE) | 2.5~7.5 | 4~10 | 5.5~12.5 | 7.5~15.5 | 9.5~19 | 11.5~22 | 13~25 | 15~29 | 16.5~32 | 17.5~35 |  |
| 710008 | Crimson Relic - Scythe | 빨강(Crimson) | 저체력 적 대상 피해 증가(%) (LowHpTargetDamage:ADDITIVE) | 2.5~7.5 | 4~10 | 5.5~12.5 | 7.5~15.5 | 9.5~19 | 11.5~22 | 13~25 | 15~29 | 16.5~32 | 17.5~35 |  |
| 710009 | Crimson Relic - Echo | 빨강(Crimson) | 화염 저항 감소(-%) [페널티] (DecreaseFireResistance:FLAT) | 40~50 | 35~45 | 30~40 | 25~35 | 20~30 | 15~25 | 10~20 | 5~12 | 3~6 | 0 | 공명 판정 시 2개로 계산(Echo) |
| 720001 | Azure Relic - Hourglass | 파랑(Azure) | 재사용 대기시간 감소(+%) (CooldownReduction:FLAT) | 1~4 | 1~5 | 2~6 | 2~7 | 3~8 | 3~9 | 4~10 | 4~11 | 5~12 | 6~13 |  |
| 720002 | Azure Relic - Gale | 파랑(Azure) | 이동속도 증가(%) (MovementSpeed:ADDITIVE) | 2~6 | 2.5~7 | 3~8 | 3.5~9 | 4.5~10 | 5~11 | 5.5~12 | 6~13 | 6.5~14 | 7~15 |  |
| 720003 | Azure Relic - Vortex | 파랑(Azure) | 효과 범위 증가(%) (AreaOfEffect:ADDITIVE) | 2.5~8 | 3.5~9.5 | 4~10.5 | 4.5~12 | 6~13.5 | 6.5~14.5 | 7.5~16 | 8~17.5 | 8.5~18.5 | 9.5~20 |  |
| 720004 | Azure Relic - Constellation | 파랑(Azure) | 스킬 지속시간 증가(%) (SkillDurationIncrease:ADDITIVE) | 2.5~8 | 3.5~9.5 | 4~10.5 | 4.5~12 | 6~13.5 | 6.5~14.5 | 7.5~16 | 8~17.5 | 8.5~18.5 | 9.5~20 |  |
| 720005 | Azure Relic - Snowflake | 파랑(Azure) | 냉기 저항(+%) (ColdResistance:FLAT) | 5~15 | 6~17 | 8~20 | 10~23 | 12~26 | 14~29 | 16~32 | 18~35 | 20~38 | 22~40 |  |
| 720006 | Azure Relic - Sail | 파랑(Azure) | 웨이브 시작 후 이동속도 증가(%) (WaveStartMovementSpeed:ADDITIVE) | 2.5~8 | 3.5~9.5 | 4~10.5 | 4.5~12 | 6~13.5 | 6.5~14.5 | 7.5~16 | 8~17.5 | 8.5~18.5 | 9.5~20 |  |
| 720007 | Azure Relic - Echo | 파랑(Azure) | 냉기 저항 감소(-%) [페널티] (DecreaseColdResistance:FLAT) | 40~50 | 35~45 | 30~40 | 25~35 | 20~30 | 15~25 | 10~20 | 5~12 | 3~6 | 0 | 공명 판정 시 2개로 계산(Echo) |
| 730001 | Golden Relic - Heart | 노랑(Golden) | 최대 HP 증가(%) (MaxHp:ADDITIVE) | 2.5~8 | 3.5~9.5 | 4~10.5 | 4.5~12 | 6~13.5 | 6.5~14.5 | 7.5~16 | 8~17.5 | 8.5~18.5 | 9.5~20 |  |
| 730002 | Golden Relic - Shield | 노랑(Golden) | 막기 확률(+%) (BlockChance:FLAT) | 2~6 | 3~8 | 4~10 | 5~12 | 6~14 | 8~16 | 9~18 | 10~20 | 12~23 | 13~25 |  |
| 730003 | Golden Relic - Halo | 노랑(Golden) | 원소 막기 확률(+%) (ElementalBlockChance:FLAT) | 2~6 | 3~8 | 4~10 | 5~12 | 6~14 | 8~16 | 9~18 | 10~20 | 12~23 | 13~25 |  |
| 730004 | Golden Relic - Rampart | 노랑(Golden) | 피해 감소(+%) (DamageReduction:FLAT) | 0.8~2.5 | 1~3.2 | 1.2~3.8 | 1.9~4.4 | 2.5~5 | 3.2~6.2 | 3.8~6.9 | 4.4~8.2 | 4.8~8.8 | 5~10 |  |
| 730005 | Golden Relic - Broken Chain | 노랑(Golden) | 군중제어 지속시간 감소(+%) (CrowdControlDurationReduction:FLAT) | 2~6 | 3~8 | 4~10 | 5~12 | 6~14 | 8~16 | 9~18 | 10~20 | 12~23 | 13~25 | 봉헌 결과 풀에 없음(DB 기준) |
| 730006 | Golden Relic - Coin | 노랑(Golden) | 처치 시 골드(+고정값) (GoldAmount:FLAT) | 4~12 | 6~16 | 8~20 | 10~24 | 12~28 | 16~32 | 18~36 | 20~40 | 24~46 | 26~50 |  |
| 730007 | Golden Relic - Thunderbolt | 노랑(Golden) | 번개 저항(+%) (LightningResistance:FLAT) | 5~15 | 6~17 | 8~20 | 10~23 | 12~26 | 14~29 | 16~32 | 18~35 | 20~38 | 22~40 |  |
| 730008 | Golden Relic - Scale | 노랑(Golden) | 피격 시 일시적 받는 피해 감소(+%) (OnHitDamageReduction:FLAT) | 1.7~5 | 2~6.3 | 2.5~7.5 | 3.8~8.8 | 5~10 | 6.3~12.5 | 7.5~13.8 | 8.8~16.3 | 9.5~17.5 | 10~20 |  |
| 730009 | Golden Relic - Anchor | 노랑(Golden) | 저체력 시 받는 피해 감소(+%) (LowHpDamageReduction:FLAT) | 1.7~5 | 2~6.3 | 2.5~7.5 | 3.8~8.8 | 5~10 | 6.3~12.5 | 7.5~13.8 | 8.8~16.3 | 9.5~17.5 | 10~20 |  |
| 730010 | Golden Relic - Echo | 노랑(Golden) | 번개 저항 감소(-%) [페널티] (DecreaseLightningResistance:FLAT) | 40~50 | 35~45 | 30~40 | 25~35 | 20~30 | 15~25 | 10~20 | 5~12 | 3~6 | 0 | 공명 판정 시 2개로 계산(Echo) |
| 740001 | Violet Relic - Moon | 보라(Violet) | 초당 HP 재생(+고정값) (HpRegenPerSec:FLAT) | 8~24 | 12~32 | 16~40 | 20~48 | 24~56 | 32~64 | 36~72 | 40~80 | 48~92 | 52~100 |  |
| 740002 | Violet Relic - Skull | 보라(Violet) | 처치 시 HP 회복(+고정값) (AddHpPerKill:FLAT) | 4~12 | 6~16 | 8~20 | 10~24 | 12~28 | 16~32 | 18~36 | 20~40 | 24~46 | 26~50 |  |
| 740003 | Violet Relic - Shadow | 보라(Violet) | 회피 확률(+%) (DodgeChance:FLAT) | 2~6 | 3~8 | 4~10 | 5~12 | 6~14 | 8~16 | 9~18 | 10~20 | 12~23 | 13~25 |  |
| 740004 | Violet Relic - Mirage | 보라(Violet) | 원소 회피 확률(+%) (ElementalDodgeChance:FLAT) | 2~6 | 3~8 | 4~10 | 5~12 | 6~14 | 8~16 | 9~18 | 10~20 | 12~23 | 13~25 |  |
| 740005 | Violet Relic - Mist | 보라(Violet) | 혼돈 저항(+%) (ChaosResistance:FLAT) | 4~11 | 5~13 | 6~15 | 8~17 | 9~20 | 11~22 | 12~24 | 14~26 | 15~29 | 17~30 |  |
| 740006 | Violet Relic - Butterfly | 보라(Violet) | 부활 대기시간 감소(+%) (ReviveCooldownReduction:FLAT) | 1~4 | 1~5 | 2~6 | 2~7 | 3~8 | 3~9 | 4~10 | 4~11 | 5~12 | 6~13 |  |
| 740007 | Violet Relic - Feather | 보라(Violet) | 부활 시 일시적 공격력 증가(%) (OnReviveAttackDamage:ADDITIVE) | 10~20 | 11~24 | 13~28 | 15~33 | 18~38 | 21~44 | 25~51 | 29~59 | 34~68 | 40~80 |  |
| 740008 | Violet Relic - Echo | 보라(Violet) | 혼돈 저항 감소(-%) [페널티] (DecreaseChaosResistance:FLAT) | 40~50 | 35~45 | 30~40 | 25~35 | 20~30 | 15~25 | 10~20 | 5~12 | 3~6 | 0 | 공명 판정 시 2개로 계산(Echo) |
| 750001 | White Relic - Crystal | 흰색(White) | 모든 원소 저항(+%) (AllElementalResistance:FLAT) | 3~8 | 3~9 | 4~11 | 5~12 | 7~13 | 7~15 | 8~16 | 9~17 | 11~19 | 12~20 |  |
| 750002 | White Relic - Echo | 흰색(White) | 공격력 감소(-%) [페널티] (DecreaseAttackDamage:FLAT) | 20~30 | 18~27 | 16~24 | 14~21 | 12~18 | 10~15 | 7~12 | 4~8 | 2~4 | 0 | 공명 판정 시 2개로 계산(Echo) |

- 흰색 유물의 "아무 슬롯에나 장착 가능"이 공명 조건에서 "아무 색으로나 계산"을 뜻하는지는 [미확인](Steam 가이드가 명시적으로 유보).

### 3.4 유물함 62종과 공명 효과(62개 행, 데이터상 유물함 변형 총 382개)

- "존재 등급"은 그 유물함이 나오는 등급 범위, "공명 발동 가능 등급"은 그보다 낮은 등급이 "Unfinished(미완성) 유물함"으로 표시되어 공명 효과가 없는 경계다. 같은 이름이라도 ID가 다르면 조건과 수치가 다르다(높은 등급대의 것이 조건이 까다롭고 효과가 크다).
- 효과 수치의 범위(예: 5~9%)는 유물함 개체마다 그 범위 안에서 정해지는 값이다 [추정: 범위의 추첨 시점은 미확인].
- 등급대별 개수: Common부터 18종, Immortal부터 20종, Arcana부터 5종, Celestial부터 19종 → 변형 수 18×10 + 20×6 + 5×5 + 19×3 = 382. [확인] shunshu 데이터 계산 = tbhindex "382 Reliquaries"(검색 요약)
- tbhindex는 공명 효과를 63개로 센다(검색 요약). 본 데이터는 62행이다. 차이 1의 원인은 [미확인].

| ID | 이름 | 존재 등급 | 공명 발동 가능 등급 | 공명 조건(색×개수) | 공명 효과(mod ID) |
|---|---|---|---|---|---|
| 790001 | Relentless Reliquary | Common~Cosmic | Rare 이상 | 파랑×2 | 재사용 대기시간 감소(+%) 5~9 (`StatValueUp`) |
| 790002 | Frostfire Reliquary | Common~Cosmic | Legendary 이상 | 빨강×2 + 파랑×1 | 빙결된 몬스터가 화염 피해를 받으면 빙결이 풀리고 점화가 걸림 (`FrozenFireIgnite`) |
| 790003 | Hunter's Reliquary | Common~Cosmic | Legendary 이상 | 파랑×2 + 노랑×1 | 덫 폭발 시 10~20% 확률로 같은 자리에 같은 덫 1개 추가 설치(추가된 덫은 재복제 없음) (`TrapDuplicateChance`) |
| 790004 | Onset Reliquary | Common~Cosmic | Rare 이상 | 빨강×2 | 스테이지 시작 후 각 파티원의 첫 공격 스킬이 확정 치명타 (`FirstSkillGuaranteedCrit`) |
| 790005 | Executioner's Reliquary | Common~Cosmic | Legendary 이상 | 빨강×2 + 보라×1 | HP 5~10% 이하의 일반 몬스터 즉사 (`ExecuteLowHpNormalMonster`) |
| 790006 | Mirror Reliquary | Common~Cosmic | Rare 이상 | 노랑×2 | 막아낸 피해의 100~200% 반사 (`BlockReflectDamage`) |
| 790007 | Bulwark Reliquary | Common~Cosmic | Legendary 이상 | 노랑×3 | 전 파티원에게 레벨 1 수호의 축복(Blessing of Warding) 발동 (`ApplyBlessingLevel:40501`) |
| 790008 | Might Reliquary | Common~Cosmic | Legendary 이상 | 빨강×3 | 전 파티원에게 레벨 1 힘의 축복(Blessing of Might) 발동 (`ApplyBlessingLevel:40201`) |
| 790009 | Phoenix Reliquary | Common~Cosmic | Legendary 이상 | 빨강×2 + 노랑×1 | 파티원 사망 시 HP 10~20%로 부활(스테이지당 1회) (`ReviveFallenAlly`) |
| 790010 | Oath Reliquary | Common~Cosmic | Legendary 이상 | 노랑×2 + 보라×1 | 최대 HP를 넘는 흡혈·처치 회복량의 50~150%만큼 주변 몬스터에 번개 피해 (`OverhealLightningDamage`) |
| 790011 | Void Reliquary | Common~Cosmic | Legendary 이상 | 보라×3 | 모든 스킬이 가한 피해의 5~13%만큼 추가 혼돈 피해 (`SkillExtraChaosDamage`) |
| 790013 | Commander's Reliquary | Common~Cosmic | Legendary 이상 | 빨강×1 + 노랑×2 | 스테이지 시작 시 무작위 파티원 1명이 리더가 되어 10~25% 커지고, 커진 비율만큼 최대 HP·피해 증가(파티 2명 이상일 때만) (`RandomLeaderBuff`) |
| 790015 | Tranquil Reliquary | Common~Cosmic | Legendary 이상 | 파랑×4 | 파티의 재사용 대기시간 감소가 적용되지 않는 대신, 그 감소 1%당 스킬 피해 2% 증가 (`CooldownReductionToSkillDamage`) |
| 790017 | Sanguine Reliquary | Common~Cosmic | Legendary 이상 | 빨강×2 + 보라×2 | 출혈 중인 몬스터가 죽으면 남은 지속시간만큼 주변 몬스터에 출혈 전이 (`BleedSpreadOnDeath`) |
| 790018 | Ember Reliquary | Common~Cosmic | Legendary 이상 | 빨강×4 | 점화된 몬스터가 죽으면 가장 가까운 몬스터에 점화 새로 부여 (`IgniteSpreadOnDeath`) |
| 790020 | Twin Reliquary | Common~Cosmic | Legendary 이상 | 파랑×2 + 노랑×2 | 투사체 스킬의 투사체 +1, 대신 투사체 피해 30% 감소 (`ProjectileCountUpDamageDown`) |
| 790022 | Hunter's Reliquary | Common~Cosmic | Legendary 이상 | 빨강×1 + 노랑×2 | 덫 폭발 시 30~50% 확률로 같은 자리에 같은 덫 1개 추가 설치(추가된 덫은 재복제 없음) (`TrapDuplicateChance`) |
| 790028 | Icicle Reliquary | Common~Cosmic | Legendary 이상 | 파랑×3 | 빙결된 몬스터 대상 치명타 피해 50~100% 증가, 대신 치명타 시 빙결 해제 (`FrozenTargetCritDamageUp`) |
| 794012 | Forgotten King's Reliquary | Immortal~Cosmic | Immortal 이상 | 빨강×1 + 파랑×1 + 노랑×1 | 빈 파티 슬롯 1칸당 주는 피해 4~8% 증가·받는 피해 4~8% 감소 (`EmptySlotBonus`) |
| 794014 | Swift Reliquary | Immortal~Cosmic | Immortal 이상 | 빨강×1 + 파랑×3 | 몬스터 처치 시 전 파티원 이동속도 1% 증가(5초), 최대 30~50중첩(스테이지 종료 또는 5초 경과 시 전부 소멸) (`KillStackPartyMoveSpeed`) |
| 794019 | Chain Reaction Reliquary | Immortal~Cosmic | Arcana 이상 | 빨강×3 + 파랑×2 | 점화된 몬스터가 감전되면 폭발하여 반경 300 내 몬스터에 200% 화염 피해 (`IgniteShockExplosion`) |
| 794021 | Vengeful Reliquary | Immortal~Cosmic | Immortal 이상 | 빨강×3 + 노랑×1 | 파티원 사망 시 생존 파티원의 피해 20~40% 증가(10초) (`AllyDeathAttackBuff`) |
| 794023 | Executioner's Reliquary | Immortal~Cosmic | Arcana 이상 | 빨강×3 + 보라×2 | HP 11~15% 이하의 일반 몬스터 즉사 (`ExecuteLowHpNormalMonster`) |
| 794024 | Phoenix Reliquary | Immortal~Cosmic | Arcana 이상 | 빨강×3 + 노랑×2 | 파티원 사망 시 HP 30~50%로 부활(스테이지당 1회) (`ReviveFallenAlly`) |
| 794025 | Black Flame Reliquary | Immortal~Cosmic | Arcana 이상 | 빨강×2 + 보라×3 | 화염 피해를 혼돈 피해로 전환 (`ElementConvertToChaos`) |
| 794026 | Black Frost Reliquary | Immortal~Cosmic | Arcana 이상 | 파랑×2 + 보라×3 | 냉기 피해를 혼돈 피해로 전환 (`ElementConvertToChaos`) |
| 794027 | Black Lightning Reliquary | Immortal~Cosmic | Arcana 이상 | 노랑×2 + 보라×3 | 번개 피해를 혼돈 피해로 전환 (`ElementConvertToChaos`) |
| 794029 | Relentless Reliquary | Immortal~Cosmic | Arcana 이상 | 파랑×4 | 재사용 대기시간 감소(+%) 10~20 (`StatValueUp`) |
| 794030 | Mirror Reliquary | Immortal~Cosmic | Arcana 이상 | 파랑×2 + 노랑×3 | 막아낸 피해의 300~500% 반사 (`BlockReflectDamage`) |
| 794031 | Commander's Reliquary | Immortal~Cosmic | Arcana 이상 | 빨강×3 + 노랑×2 | 스테이지 시작 시 무작위 파티원 1명이 리더가 되어 10~20% 커지고, 커진 비율만큼 최대 HP·피해 증가(파티 2명 이상일 때만) (`RandomLeaderBuff`) |
| 794032 | Bitter Cold Reliquary | Immortal~Cosmic | Arcana 이상 | 파랑×5 | 모든 냉기 피해가 냉각(Chill) 부여, 대신 화염 피해 50% 감소 (`ColdCausesChillFireDamageDown`) |
| 794033 | Oath Reliquary | Immortal~Cosmic | Arcana 이상 | 노랑×5 | 최대 HP를 넘는 흡혈·처치 회복량의 200~500%만큼 주변 몬스터에 번개 피해 (`OverhealLightningDamage`) |
| 794035 | Companion's Reliquary | Immortal~Cosmic | Arcana 이상 | 파랑×2 + 노랑×4 | 소환수가 소환자의 치명타 확률을 이어받아 치명타 가능 (`SummonUseOwnerCritChance`) |
| 794036 | Corrupt Reliquary | Immortal~Cosmic | Arcana 이상 | 보라×5 | 모든 혼돈 피해가 총 치명타 피해 수치의 20~40%만큼 증가, 대신 혼돈 피해는 치명타 불가 (`ChaosDamageCritConvert`) |
| 794037 | Bulwark Reliquary | Immortal~Cosmic | Arcana 이상 | 노랑×4 + 보라×2 | 전 파티원에게 레벨 3~5 수호의 축복(Blessing of Warding) 발동 (`ApplyBlessingLevel:40501`) |
| 794040 | Swift Reliquary | Immortal~Cosmic | Arcana 이상 | 빨강×2 + 파랑×4 | 몬스터 처치 시 전 파티원 이동속도 1% 증가(5초), 최대 60~100중첩(스테이지 종료 또는 5초 경과 시 전부 소멸) (`KillStackPartyMoveSpeed`) |
| 794041 | Keen Reliquary | Immortal~Cosmic | Arcana 이상 | 빨강×4 + 파랑×2 | 비치명타 피해를 준 몬스터에게 주는 다음 피해가 치명타가 아니면 치명타 판정 1회 추가 (`NonCritRerollCrit`) |
| 794042 | Vengeful Reliquary | Immortal~Cosmic | Arcana 이상 | 보라×4 + 노랑×2 | 파티원 사망 시 생존 파티원의 피해 50~100% 증가(10초) (`AllyDeathAttackBuff`) |
| 795016 | Prism Reliquary | Arcana~Cosmic | Arcana 이상 | 빨강×1 + 파랑×1 + 노랑×1 + 보라×1 | 스테이지 진입 후 처음 준 원소 피해의 속성으로 고정: 해당 원소 피해 30~50% 증가, 다른 원소 피해는 불가 (`ElementLock`) |
| 795034 | Condemnation Reliquary | Arcana~Cosmic | Arcana 이상 | 빨강×2 + 파랑×2 + 노랑×2 + 보라×2 | 주변 몬스터에 초당 30~70% 화염 피해 (`AuraFireDamagePerSecond`) |
| 795038 | Might Reliquary | Arcana~Cosmic | Arcana 이상 | 빨강×4 + 노랑×1 | 전 파티원에게 레벨 3~5 힘의 축복(Blessing of Might) 발동 (`ApplyBlessingLevel:40201`) |
| 795039 | Executioner's Reliquary | Arcana~Cosmic | Arcana 이상 | 빨강×3 + 보라×3 | HP 16~20% 이하의 일반 몬스터 즉사 (`ExecuteLowHpNormalMonster`) |
| 795043 | Prism Reliquary | Arcana~Cosmic | Arcana 이상 | 빨강×2 + 파랑×2 + 노랑×1 + 보라×1 | 스테이지 진입 후 처음 준 원소 피해의 속성으로 고정: 해당 원소 피해 30~50% 증가, 다른 원소 피해는 불가 (`ElementLock`) |
| 797044 | Vampire's Reliquary | Celestial~Cosmic | Celestial 이상 | 빨강×2 + 보라×5 | 흡혈 1.5~2배, 대신 초당 HP 재생·타격 시 회복·처치 시 회복 비활성(프리스트 치유 스킬은 예외) (`LifestealDoubleDisableOtherHeal`) |
| 797045 | Pure Flame Reliquary | Celestial~Cosmic | Celestial 이상 | 빨강×7 | 모든 화염 피해가 점화 부여, 점화 피해 100% 증가 (`FireDamageAlwaysIgnite`) |
| 797046 | Pure Frost Reliquary | Celestial~Cosmic | Celestial 이상 | 파랑×7 | HP 25~30% 이하의 빙결된 몬스터가 물리 피해를 받으면 즉사(보스는 기준치가 50%로 축소) (`FrozenPhysicalExecute`) |
| 797047 | Pure Light Reliquary | Celestial~Cosmic | Celestial 이상 | 노랑×7 | 번개 피해가 치명타일 때 감전 부여, 감전된 적은 번개 피해 10~20% 추가로 받음 (`LightningCritShock`) |
| 797048 | Pure Void Reliquary | Celestial~Cosmic | Celestial 이상 | 보라×7 | 모든 스킬이 가한 피해의 15~30%만큼 추가 혼돈 피해 (`SkillExtraChaosDamage`) |
| 797049 | Forgotten King's Reliquary | Celestial~Cosmic | Celestial 이상 | 빨강×2 + 파랑×2 + 노랑×2 + 보라×2 | 빈 파티 슬롯 1칸당 주는 피해 9~18% 증가·받는 피해 9~18% 감소 (`EmptySlotBonus`) |
| 797050 | Twinborn Reliquary | Celestial~Cosmic | Celestial 이상 | 빨강×4 + 파랑×4 | 점화된 적 대상 냉기 피해 25~50% 증가, 냉각된 적 대상 화염 피해 25~50% 증가 (`IgniteChillCrossDamage`) |
| 797051 | Master's Reliquary | Celestial~Cosmic | Celestial 이상 | 빨강×2 + 파랑×2 + 노랑×2 + 보라×1 | 모든 스킬 레벨(+) 1~2 (`StatValueUp`) |
| 797052 | Resonator Reliquary | Celestial~Cosmic | Celestial 이상 | 빨강×1 + 파랑×1 + 노랑×2 + 보라×2 | 장착한 다른 유물함의 공명 효과 수치 50% 증가 (`ResonanceValueUp`) |
| 797053 | Rampant Reliquary | Celestial~Cosmic | Celestial 이상 | 빨강×4 + 파랑×2 + 노랑×4 | 기사(Knight)의 공격 스킬 재사용 대기시간 제거, 대신 스킬 사용마다 최대 HP의 10~50% 소모 (`NoCooldownMaxHpCost`) |
| 797054 | Rampant Reliquary | Celestial~Cosmic | Celestial 이상 | 빨강×4 + 파랑×4 + 보라×2 | 레인저(Ranger)의 공격 스킬 재사용 대기시간 제거, 대신 스킬 사용마다 최대 HP의 10~50% 소모 (`NoCooldownMaxHpCost`) |
| 797055 | Rampant Reliquary | Celestial~Cosmic | Celestial 이상 | 빨강×4 + 파랑×2 + 보라×4 | 소서러(Sorcerer)의 공격 스킬 재사용 대기시간 제거, 대신 스킬 사용마다 최대 HP의 10~50% 소모 (`NoCooldownMaxHpCost`) |
| 797057 | Rampant Reliquary | Celestial~Cosmic | Celestial 이상 | 빨강×4 + 노랑×2 + 보라×4 | 헌터(Hunter)의 공격 스킬 재사용 대기시간 제거, 대신 스킬 사용마다 최대 HP의 10~50% 소모 (`NoCooldownMaxHpCost`) |
| 797058 | Rampant Reliquary | Celestial~Cosmic | Celestial 이상 | 빨강×4 + 파랑×2 + 보라×4 | 슬레이어(Slayer)의 공격 스킬 재사용 대기시간 제거, 대신 스킬 사용마다 최대 HP의 10~50% 소모 (`NoCooldownMaxHpCost`) |
| 797059 | Commander's Reliquary | Celestial~Cosmic | Celestial 이상 | 빨강×4 + 노랑×3 | 스테이지 시작 시 무작위 파티원 1명이 리더가 되어 30~50% 커지고, 커진 비율만큼 최대 HP·피해 증가(파티 2명 이상일 때만) (`RandomLeaderBuff`) |
| 797060 | Rampant Reliquary | Celestial~Cosmic | Celestial 이상 | 빨강×4 + 파랑×4 + 노랑×2 | 기사(Knight)의 공격 스킬이 기본 공격 횟수 누적 없이 발동, 대신 스킬 사용마다 최대 HP의 10~50% 소모 (`NoBaseAttackCountMaxHpCost`) |
| 797061 | Rampant Reliquary | Celestial~Cosmic | Celestial 이상 | 빨강×4 + 파랑×2 + 보라×4 | 레인저(Ranger)의 공격 스킬이 기본 공격 횟수 누적 없이 발동, 대신 스킬 사용마다 최대 HP의 10~50% 소모 (`NoBaseAttackCountMaxHpCost`) |
| 797062 | Rampant Reliquary | Celestial~Cosmic | Celestial 이상 | 빨강×4 + 노랑×4 + 보라×2 | 헌터(Hunter)의 공격 스킬이 기본 공격 횟수 누적 없이 발동, 대신 스킬 사용마다 최대 HP의 10~50% 소모 (`NoBaseAttackCountMaxHpCost`) |
| 797063 | Rampant Reliquary | Celestial~Cosmic | Celestial 이상 | 빨강×4 + 파랑×4 + 보라×2 | 슬레이어(Slayer)의 공격 스킬이 기본 공격 횟수 누적 없이 발동, 대신 스킬 사용마다 최대 HP의 10~50% 소모 (`NoBaseAttackCountMaxHpCost`) |

- "Rampant" 계열은 영웅 전용이다(헌터·슬레이어용은 해당 DLC 영웅 보유 시에만 봉헌 풀에 들어감 — 봉헌 가중치 행에 영웅 키 501/601 조건이 붙어 있음). [확인: shunshu 봉헌 데이터]
- "Resonator"(공명기)는 다른 장착 유물함의 공명 수치를 50% 올린다 → 유물함 2개 장착을 전제한 메타 효과.

### 3.5 봉헌(Offering) 결과 등급 확률 — v1.03.00

- 레시피: 오염된 유물함(또는 오염된 유물) 1개 + 골드 10 → 무작위 유물함(유물) 1개. [추정: Steam 가이드가 "레시피 표에 10 gold"라고 기술, 단일 출처]
- 결과는 **투입 등급 이상**에서만 나온다. 아래는 shunshu 봉헌 가중치(총합 약 1억)를 등급별로 합산한 백분율이다. [확인: 데이터 추출 DB 1곳 + Steam 가이드의 "같은 등급 또는 상위 등급" 서술 일치]

오염된 유물함 → 유물함 (DLC 영웅 전용 행 제외):

| 투입 등급 ↓ / 결과 등급 → | Common | Uncommon | Rare | Legendary | Immortal | Arcana | Beyond | Celestial | Divine | Cosmic |
|---|---|---|---|---|---|---|---|---|---|---|
| Common | 64.4903% | 25.0053% | 7.5016% | 2.1432% | 0.6960% | 0.1402% | 0.0210% | 0.0021% | 0.0001% | 0.0000% |
| Uncommon | – | 67.7724% | 23.0151% | 6.5754% | 2.1354% | 0.4302% | 0.0645% | 0.0066% | 0.0004% | 0.0000% |
| Rare | – | – | 70.5159% | 21.0441% | 6.8342% | 1.3768% | 0.2065% | 0.0210% | 0.0013% | 0.0001% |
| Legendary | – | – | – | 77.0065% | 18.6188% | 3.7510% | 0.5626% | 0.0573% | 0.0036% | 0.0002% |
| Immortal | – | – | – | – | 80.0570% | 17.0993% | 2.5649% | 0.2613% | 0.0165% | 0.0009% |
| Arcana | – | – | – | – | – | 84.4794% | 13.9992% | 1.4263% | 0.0903% | 0.0047% |
| Beyond | – | – | – | – | – | – | 88.0510% | 11.2026% | 0.7091% | 0.0373% |
| Celestial | – | – | – | – | – | – | – | 91.4526% | 8.1203% | 0.4271% |
| Divine | – | – | – | – | – | – | – | – | 94.9248% | 5.0752% |
| Cosmic | – | – | – | – | – | – | – | – | – | 100.0000% |

오염된 유물 → 유물:

| 투입 등급 ↓ / 결과 등급 → | Common | Uncommon | Rare | Legendary | Immortal | Arcana | Beyond | Celestial | Divine | Cosmic |
|---|---|---|---|---|---|---|---|---|---|---|
| Common | 64.4765% | 25.0000% | 7.5000% | 2.1428% | 0.7142% | 0.1428% | 0.0214% | 0.0021% | 0.0001% | 0.0000% |
| Uncommon | – | 67.7280% | 23.0000% | 6.5711% | 2.1901% | 0.4380% | 0.0657% | 0.0066% | 0.0004% | 0.0000% |
| Rare | – | – | 70.3685% | 21.0000% | 6.9993% | 1.3999% | 0.2100% | 0.0210% | 0.0013% | 0.0001% |
| Legendary | – | – | – | 76.5692% | 19.0000% | 3.8000% | 0.5700% | 0.0570% | 0.0036% | 0.0002% |
| Immortal | – | – | – | – | 80.1780% | 17.0000% | 2.5500% | 0.2550% | 0.0161% | 0.0009% |
| Arcana | – | – | – | – | – | 84.5067% | 14.0000% | 1.4000% | 0.0886% | 0.0047% |
| Beyond | – | – | – | – | – | – | 88.2671% | 11.0000% | 0.6963% | 0.0366% |
| Celestial | – | – | – | – | – | – | – | 91.5792% | 8.0000% | 0.4208% |
| Divine | – | – | – | – | – | – | – | – | 95.0000% | 5.0000% |
| Cosmic | – | – | – | – | – | – | – | – | – | 100.0000% |

- 유물의 색별 가중치(같은 등급 안): 빨강 합 ≈ 노랑 합 ≈ 파랑 합 ≈ 보라 합(각 약 15.5%p 비중), 흰색 합은 그 1/6. 즉 색은 4색이 거의 균등하고 흰색만 희귀하다. [확인: 가중치 계산]
- 노랑 유물 "Golden Relic - Broken Chain"은 데이터에는 있으나 봉헌 결과 풀에 없다(획득 경로 [미확인]).
- 드롭처 요약(shunshu 드롭 테이블 분석 [추정]): 오염된 유물은 역병 지대 일반 상자, 오염된 유물함은 스테이지 상자에서 나오고, 출현 빈도는 난이도보다 **역병 강도**에 좌우된다(강도 16~20이 1~5의 약 2배). 난이도는 주로 재료의 등급을 바꾼다. Torment 오염된 액트 보스 상자는 대체로 Immortal 이상을 준다. 상자별 절대 확률은 본 조사 범위 밖(드롭/경제 문서 참조).

### 3.6 조율(Attunement) 비용 — v1.03.00

- n번째 시도 비용 = 첫 비용 + 회당 증가 × min(이전 시도 횟수, 19). 즉 20번째 시도부터 상한 고정. 시도 횟수는 **아이템 개체에 누적**된다. [확인] shunshu `relicAttunement`(base/inc/max=19), tbhindex 표(검색 요약: Legendary 유물함 2,700 / +3,240 / 상한 64,260 등 5개 등급 수치 일치), Steam 가이드의 모형 C(m)=b+d×min(m,19) 일치
- 유물의 비용은 같은 등급 유물함의 정확히 절반.

| 등급 | 유물함: 첫 비용 | 유물함: 회당 증가 | 유물함: 상한(20회차~) | 유물: 첫 비용 | 유물: 회당 증가 | 유물: 상한(20회차~) |
|---|---|---|---|---|---|---|
| Common | 100 | +120 | 2,380 | 50 | +60 | 1,190 |
| Uncommon | 300 | +360 | 7,140 | 150 | +180 | 3,570 |
| Rare | 900 | +1,080 | 21,420 | 450 | +540 | 10,710 |
| Legendary | 2,700 | +3,240 | 64,260 | 1,350 | +1,620 | 32,130 |
| Immortal | 9,450 | +11,340 | 224,910 | 4,725 | +5,670 | 112,455 |
| Arcana | 35,900 | +43,080 | 854,420 | 17,950 | +21,540 | 427,210 |
| Beyond | 144,000 | +172,800 | 3,427,200 | 72,000 | +86,400 | 1,713,600 |
| Celestial | 603,000 | +723,600 | 14,351,400 | 301,500 | +361,800 | 7,175,700 |
| Divine | 2,650,000 | +3,180,000 | 63,070,000 | 1,325,000 | +1,590,000 | 31,535,000 |
| Cosmic | 12,200,000 | +14,640,000 | 290,360,000 | 6,100,000 | +7,320,000 | 145,180,000 |

- 유물함 조율: 슬롯 색 전체 재추첨, 색은 균등 확률(공식). 색 가짓수를 5로 본 팬 계산(슬롯 1칸이 특정 색일 확률 1/5)은 [추정] — 슬롯 색에 흰색이 포함되는지 [미확인].
- 유물 조율: 고유 능력치 수치만 재추첨(종류·색·등급 불변).
- 업적 "Master of Attunement": 같은 유물/유물함을 10회 조율.

### 3.7 1.3.x 핫픽스에서 바뀐 유물 규칙 [확인 — 1.3.2 패치노트(2026-10-27)]

- "혼돈 저항이 최고 원소 저항 값으로 고정된다"는 장비 특수 속성이 켜져 있어도 유물의 혼돈 저항 페널티(보라 Echo)가 적용되던 문제 수정 → 그 속성이 있으면 유물 페널티가 무시된다.
- 일부 유물의 고정 능력치 소수점 표시 오류 수정(최대치 미만인데 최대치처럼 보이던 문제) → 유물 수치는 소수점 단위로 추첨된다.

---

## 4. 파티(그룹) 공통 보너스

- 1.3.0 관련 기사(jeu.video 등)의 "group bonus / bonus de groupe"는 **별도의 시스템 이름이 아니다.** 공식 패치노트의 문장 "파티원의 전반적인 능력을 강화하는 유물 시스템 추가", "유물함/유물의 고유 능력치 효과는 모든 파티원에게 적용", "공명 효과는 모든 파티원에게 특수 능력치 부여"를 옮긴 표현이다. [확인] 1.3.0 패치노트 원문 대조(jeu.video 기사 자체는 접근 차단으로 원문 미열람, 검색 요약만)
- 따라서 "파티 전체에 적용되는 보너스 체계"는 다음 4층이다.

| 층 | 적용 대상 | 내용 | 도입 |
|---|---|---|---|
| 룬 | 계정의 모든 영웅 | 전 영웅 공격력/방어력/공격속도/이동속도, 파밍 보너스, 슬롯·편의 해금 | 출시 |
| 펫 보유 효과 | 계정 | 경험치·골드·상자 드롭 계수 | 출시 |
| 유물함 고유 능력치 + 유물 고유 능력치 | 현재 파티원 전원 | 공격력%, 최대 HP%, 치명타 피해, 공격·시전 속도, 재사용 대기시간 감소, 저항, 피해 감소, 이동속도 등 | 1.3.0 |
| 유물함 공명 효과 | 현재 파티원 전원(일부는 특정 영웅 전용) | 조건부 특수 규칙(즉사, 반사, 원소 전환, 축복 자동 발동 등) | 1.3.0 |

- 파티 구성 자체에 따른 시너지 보너스(직업 조합 보너스, 진형 보너스 등)는 찾지 못했다. [미확인] 다만 유물함 공명 중 "빈 파티 슬롯 1칸당 피해 증가/받는 피해 감소"(Forgotten King's), "무작위 리더 강화(파티 2명 이상)"(Commander's)처럼 파티 인원을 조건으로 삼는 효과는 있다. [확인]
- 영웅 스킬 중 파티 버프(프리스트의 축복류, 슬레이어의 Commander's Cry 등)는 스킬 문서 소관.

---

## 5. 업적 / 도감 / 칭호 / 마일스톤

- **Steam 업적 80개**(출시 시 56개 + 1.3.0에서 24개 추가: 역병 지대 15, 부식 1, 유물 8). [확인] Steam 업적 페이지·API, 1.3.0 패치노트("Added 24 new Plaguelands achievements"), probonk "Achievements 56 goals"(1.3.0 이전 스냅샷)
- **업적 달성 보상(골드·스탯·아이템)은 확인되지 않았다.** 공식 패치노트 어디에도 업적 보상 언급이 없고, 데이터 사이트의 45개 테이블에 업적 보상 테이블이 없다. 영구 보너스를 주는 시스템이 아니라 Steam 업적으로만 기능하는 것으로 보인다. [추정: 부재 증거]
- 도감(컬렉션), 칭호 시스템: 찾지 못함. [미확인] (데이터 테이블 목록에 해당 테이블 없음)
- 통계(Statistics) UI: 1.02.00에서 추가. 각종 플레이 기록 열람용이며 보상 언급 없음. [확인]
- 숨김 업적 없음(80개 모두 공개). [확인]

| API ID | 이름(영문) | 달성 조건 | 전 세계 달성률(2026-11-21 조회) | 추가 시점 |
|---|---|---|---|---|
| 100001 | Hero Out of the Taskbar | 스테이지 1-1 최초 클리어 | 100.0% | 출시(1.00.x) |
| 100002 | TBH, This Game Slaps | 스테이지 1-10 최초 클리어 | 97.2% | 출시(1.00.x) |
| 100003 | Still Not Off the Clock | 스테이지 2-10 최초 클리어 | 84.2% | 출시(1.00.x) |
| 100004 | Normal? That's Boring. | Normal 난이도 최초 클리어 | 78.0% | 출시(1.00.x) |
| 100005 | The Nightmare Begins | Nightmare 난이도 최초 클리어 | 70.8% | 출시(1.00.x) |
| 100006 | Hell? Better Than Monday. | Hell 난이도 최초 클리어 | 59.8% | 출시(1.00.x) |
| 101001 | Gone Without a Trace | 몬스터 1,000마리 처치 | 100.0% | 출시(1.00.x) |
| 101002 | I Was Just Idling... | 몬스터 10,000마리 처치 | 97.2% | 출시(1.00.x) |
| 101003 | Monsters? What Monsters? | 몬스터 100,000마리 처치 | 82.3% | 출시(1.00.x) |
| 102001 | Package Delivered~ | 일반 상자 10개 열기 | 100.0% | 출시(1.00.x) |
| 102002 | A Gift from the Boss | 스테이지 보스 상자 10개 열기 | 100.0% | 출시(1.00.x) |
| 102003 | The Big Boss's Treasure | 액트 보스 상자 10개 열기 | 80.6% | 출시(1.00.x) |
| 103001 | Starlit Gear | Arcana 등급 장비 최초 획득 | 81.0% | 출시(1.00.x) |
| 103002 | Gear Beyond Limits | Beyond 등급 장비 최초 획득 | 71.6% | 출시(1.00.x) |
| 103003 | Heaven-Sent Gear | Celestial 등급 장비 최초 획득 | 55.3% | 출시(1.00.x) |
| 103004 | Blessed by the Divine | Divine 등급 장비 최초 획득 | 41.1% | 출시(1.00.x) |
| 103005 | Chosen by the Cosmos | Cosmic 등급 장비 최초 획득 | 36.1% | 출시(1.00.x) |
| 104001 | First Paycheck | 골드 1,000 획득 | 81.7% | 출시(1.00.x) |
| 104002 | Millionaire Dreams | 골드 1,000,000 획득 | 61.8% | 출시(1.00.x) |
| 104003 | Overflowing Vault | 골드 100,000,000 획득 | 42.6% | 출시(1.00.x) |
| 105001 | Beak Mask On | 역병 지대 스테이지 최초 클리어 | 8.5% | 1.3.0 |
| 105002 | Apprentice Hunter (Nightmare) | Nightmare 역병 지대를 역병 강도 5로 클리어 | 3.0% | 1.3.0 |
| 105003 | Plague Hunter (Nightmare) | Nightmare 역병 지대를 역병 강도 10로 클리어 | 2.2% | 1.3.0 |
| 105004 | Plague Slayer (Nightmare) | Nightmare 역병 지대를 역병 강도 15로 클리어 | 1.9% | 1.3.0 |
| 105005 | Bane of the Plague (Nightmare) | Nightmare 역병 지대를 역병 강도 20로 클리어 | 1.4% | 1.3.0 |
| 105006 | Apprentice Hunter (Hell) | Hell 역병 지대를 역병 강도 5로 클리어 | 4.0% | 1.3.0 |
| 105007 | Plague Hunter (Hell) | Hell 역병 지대를 역병 강도 10로 클리어 | 2.9% | 1.3.0 |
| 105008 | Plague Slayer (Hell) | Hell 역병 지대를 역병 강도 15로 클리어 | 1.6% | 1.3.0 |
| 105009 | Bane of the Plague (Hell) | Hell 역병 지대를 역병 강도 20로 클리어 | 1.0% | 1.3.0 |
| 105010 | Apprentice Hunter (Torment) | Torment 역병 지대를 역병 강도 5로 클리어 | 3.0% | 1.3.0 |
| 105011 | Plague Hunter (Torment) | Torment 역병 지대를 역병 강도 10로 클리어 | 1.6% | 1.3.0 |
| 105012 | Plague Slayer (Torment) | Torment 역병 지대를 역병 강도 15로 클리어 | 1.1% | 1.3.0 |
| 105013 | Bane of the Plague (Torment) | Torment 역병 지대를 역병 강도 20로 클리어 | 0.6% | 1.3.0 |
| 105014 | Source Eliminated | 오염된 액트 보스 처치 | 0.7% | 1.3.0 |
| 105015 | Plague Doctor | 역병 지대에서 몬스터 10,000마리 처치 | 5.5% | 1.3.0 |
| 110001 | Alchemy 101 | 연금으로 골드 1,000 획득 | 61.6% | 출시(1.00.x) |
| 110002 | The Philosopher's Stone | 연금으로 골드 1,000,000 획득 | 40.3% | 출시(1.00.x) |
| 111001 | Tasted the Power of Synthesis | Uncommon 등급 아이템 합성 최초 성공 | 100.0% | 출시(1.00.x) |
| 111002 | Hey, Not Bad! | Rare 등급 아이템 합성 최초 성공 | 93.6% | 출시(1.00.x) |
| 111003 | Legends Are Made, Not Born | Legendary 등급 아이템 합성 최초 성공 | 79.1% | 출시(1.00.x) |
| 111004 | Recipe for Immortality | Immortal 등급 아이템 합성 최초 성공 | 61.9% | 출시(1.00.x) |
| 112001 | A Decorative Awakening | 1티어 이상 장식 옵션 최초 적용 | 68.2% | 출시(1.00.x) |
| 112002 | Decoration is an Art | 5티어 이상 장식 옵션 최초 적용 | 42.5% | 출시(1.00.x) |
| 113001 | Baby Steps in Engraving | 1티어 이상 각인 옵션 최초 적용 | 50.4% | 출시(1.00.x) |
| 113002 | Outshining Jewels | 5티어 이상 각인 옵션 최초 적용 | 35.0% | 출시(1.00.x) |
| 114001 | Let's Try Inscribing | 1티어 이상 명문 옵션 최초 적용 | 27.0% | 출시(1.00.x) |
| 114002 | Etched into the Soul | 5티어 이상 명문 옵션 최초 적용 | 16.5% | 출시(1.00.x) |
| 115001 | First Wish | 봉헌 최초 성공 | 45.7% | 출시(1.00.x) |
| 116001 | Accessory Workshop: OPEN! | Common 이상 장신구 제작 최초 성공 | 60.0% | 출시(1.00.x) |
| 116002 | The Immortal Artisan | Immortal 이상 장신구 제작 최초 성공 | 46.7% | 출시(1.00.x) |
| 117001 | Essence Extracted | 추출 최초 성공 | 45.4% | 출시(1.00.x) |
| 118001 | Embrace the Blight | 부식(Corrosion) 최초 수행 | 5.2% | 1.3.0 |
| 119001 | Horroric Cube | 큐브 레벨 10 달성 | 65.5% | 출시(1.00.x) |
| 119002 | Decubed Cain | 큐브 레벨 50 달성 | 39.3% | 출시(1.00.x) |
| 120001 | Rookie Merchant | 무역선에 아이템 최초 등록 | 69.6% | 출시(1.00.x) |
| 121001 | Friend of the Night | 박쥐 펫 해금 | 85.4% | 출시(1.00.x) |
| 122001 | Hero's First Awakening | 영웅 레벨 10 최초 달성 | 100.0% | 출시(1.00.x) |
| 122002 | Still Warming Up | 영웅 레벨 20 최초 달성 | 85.4% | 출시(1.00.x) |
| 122003 | Getting the Hang of It | 영웅 레벨 30 최초 달성 | 70.4% | 출시(1.00.x) |
| 122004 | Half-Legend | 영웅 레벨 50 최초 달성 | 58.8% | 출시(1.00.x) |
| 122005 | Unleashed Potential | 영웅 레벨 60 최초 달성 | 49.8% | 출시(1.00.x) |
| 122006 | Almost There | 영웅 레벨 70 최초 달성 | 44.4% | 출시(1.00.x) |
| 122007 | Legend of the Taskbar | 영웅 레벨 80 최초 달성 | 39.1% | 출시(1.00.x) |
| 123001 | The Sacred Calling | 프리스트 영웅 해금 | 70.6% | 출시(1.00.x) |
| 124001 | Seal Broken | 오염된 유물함 봉헌으로 유물함 최초 획득 | 3.8% | 1.3.0 |
| 124002 | Awaken the Relic | 유물함에 유물 최초 장착 | 3.8% | 1.3.0 |
| 124003 | First Resonance | 공명 효과 최초 발동 | 1.7% | 1.3.0 |
| 124004 | Double Resonance | 공명 효과 2개 동시 발동 | 1.0% | 1.3.0 |
| 124005 | Reliquary Complete | 유물함 8슬롯 전부에 유물 장착 | 0.0% | 1.3.0 |
| 124006 | First Attunement | 조율 최초 성공 | 3.6% | 1.3.0 |
| 124007 | Master of Attunement | 같은 유물/유물함을 10회 조율 | 2.6% | 1.3.0 |
| 124008 | Relic Restorer | 유물 합성 최초 성공 | 2.6% | 1.3.0 |
| 131001 | Heroes Never Walk Alone | 영웅 4명을 레벨 50 이상으로 육성 | 18.2% | 출시(1.00.x) |
| 131002 | Solo Shift in Hell | Hell 3-10 솔로 클리어 | 11.0% | 출시(1.00.x) |
| 131003 | Two's Company | Torment 3-10을 2인 파티로 클리어 | 8.5% | 출시(1.00.x) |
| 131004 | Obsession? No, Dedication. | 같은 아이템에 명문 100회 시도 | 0.5% | 출시(1.00.x) |
| 131005 | The Perfectionist | 장착 장비 전부의 장식/각인/명문 완성(2/2/2 슬롯 아이템 기준) | 0.5% | 출시(1.00.x) |
| 131006 | In the Blink of an Eye | 아무 스테이지나 10초 이내 클리어 | 47.5% | 출시(1.00.x) |
| 131007 | ...Wait, I'm the Only One Left? | 3인 파티에서 2명이 죽은 상태로 Normal 3-10 액트 보스 클리어 | 5.8% | 출시(1.00.x) |
| 131008 | Like a Ghost | 피격 없이 Nightmare 3-10 액트 보스 클리어 | 17.2% | 출시(1.00.x) |

---

## 6. 그 밖의 영구(계정) 성장 시스템

| 시스템 | 범위 | 내용 | 상태 |
|---|---|---|---|
| **프레스티지/환생** | – | **없음.** taskbarhero.wiki /mechanics: "레벨은 1~100 고정 테이블, 프레스티지·환생 시스템 없음". 공식 공지에도 언급 없음 | [확인: 데이터 기반 사이트 진술 + 공식 부재] |
| 계정 레벨 | – | 별도 계정 레벨 없음(영웅 레벨과 큐브 레벨뿐) | [추정: 테이블 목록에 없음] |
| **큐브 레벨** | 계정 | 1~100, 레벨별 필요 경험치 테이블(1레벨 15 → 99레벨 10,511,250). 아이템을 큐브 레시피로 소모해 경험치 획득. 레시피·등급 해금 관문(예: Immortal 합성 = 큐브 10, Celestial 합성 = 큐브 50, 봉헌 = 큐브 20). 연금/부식에 넣을 수 있는 아이템 레벨 ≤ 큐브 레벨+21(1.02.00~). 업적: 큐브 10, 50 | [확인] `/data/t/cube_levels.json`, 1.02.00 패치노트. 상세는 제작 문서 |
| 영웅 레벨 | 영웅별 | 1~100 테이블(100레벨 필요 경험치 1,997,771,834). 업적은 80까지. "최대 레벨 상향"이 11월 예고됨 → 현재 실제 상한은 영웅 문서 참조 | [확인: 테이블] |
| 영웅 특성(Attribute) 포인트 | 영웅별 | 영웅당 패시브/액티브 노드 묶음 8단(투자 포인트 0/10/…/70에서 다음 단 해금). 계정 공통 아님 | [확인] `/data/t/attributes.json`(132행), `attribute_groups.json`. 상세는 영웅 문서 |
| 영웅 슬롯·스킬 슬롯 | 계정 | 룬으로 해금(파티 최대 3인, 스킬 슬롯 +1) | [확인] 1절 |
| 인벤토리·창고·상자 보관량 | 계정 | 룬(인벤토리 +84, 창고 페이지 +3, 상자 보관) + DLC(Extra Stash 3탭 $2.99, Material Stash, Trade Ship DLC의 추가 무역선 슬롯). 인벤토리/창고/보관함 칸별 해금 비용 테이블 존재 | [확인] 공식 공지, `/data/t/inventory.json` 등 |
| 스킨/외형 | 영웅별 | 1.02.00 추가. 일러스트·스프라이트·애니메이션만 변경, 능력치 언급 없음 | [확인] 패치노트 |
| 별자리·유산·각성 등 기타 트리 | – | 찾지 못함 | [미확인] |
| 시즌 | – | Dev Note #1(2026-08-19)이 "시즌 1 업데이트"를 예고. 내용·초기화 여부 | [미확인] |

---

## 7. 전투 계산에서의 적용 단계(버킷)

### 7.1 스탯 합산 공식 [확인 — 두 독립 사이트 일치]

```
최종값 = (기본값 + Σ Flat) × (1 + Σ Increased%) × Π(1 + More%)
```

- Flat(고정 가산) → Increased(= 데이터의 `ADDITIVE`, 전부 합산 후 한 번 곱함) → More(= `MULTIPLICATIVE`, 각각 따로 곱함).
- 출처: taskbarhero.wiki /mechanics("디컴파일한 게임 코드에서 복원", v1.00.17), flex.shunshu-labo.org /en/tbh/mechanics/ "How Stats Stack"(v1.03.00). 게임 내 문구로는 "+10" = Flat, "10% Increased" = Increased, "10% More" = More.
- 수정치 출처 8종(코드 열거형, 적용 순서): Base → Item → Attribute → Passive → **AccountStatus(룬)** → StatusEffect → BuffSkill → Environment. [확인] taskbarhero.wiki /mechanics. 유물·펫이 어느 출처로 분류되는지는 [미확인](v1.00.17 코드 기준 목록이라 유물 없음).

### 7.2 시스템별 버킷

| 시스템 | 스탯 | 버킷 | 근거 |
|---|---|---|---|
| 룬 | 전 영웅 공격력 +N (AllHeroAttackDamage) | 공격력 **Flat** | [추정] taskbarhero.wiki 세이브 분석기의 매핑(제3자 재구현) |
| 룬 | 전 영웅 공격력 % (…Percent) | 공격력 **Increased**(원시/1000) | [추정] 동일. 게임 내 효과 문구가 "…% 증가(Increased)" 형식인 점과 부합 |
| 룬 | 전 영웅 방어력 +N / % | 방어력 Flat / Increased | [추정] 동일 |
| 룬 | 전 영웅 공격속도 %, 이동속도 % | 각각 Increased | [추정] 동일 |
| 룬·펫 | 경험치 %, 처치 골드 % | 기준 100%에 전부 **합연산**: 배율 = 1 + (룬 합 + 펫 합) | [추정] 동일 매핑(둘 다 FLAT로 기준값 1.0에 가산). 펫 스탯의 모드가 FLAT인 것은 [확인] |
| 룬 | 추가 골드/경험치 +N (전체/일반 몬스터/스테이지 보스/액트 보스) | 처치당 고정 가산(대상 종류별) | [추정] 스탯명과 매핑. 고정 가산분에 % 배율이 곱해지는지 [미확인] |
| 룬·펫 | 상자 드롭 확률 계수 % | 스테이지 기본 드롭률(1/1000 단위 확률값)에 곱하는 계수에 합산 | [추정] taskbarhero.wiki /mechanics "Percent 룬은 드롭률에 곱해진다" + 효과 문구 "확률 계수 증가" |
| 룬 | 오프라인 보상 골드/경험치 % | 오프라인 보상에만 적용, 합연산(+10%/레벨) | [추정] taskbarhero.wiki /mechanics |
| 룬 | 큐브 연금 골드 % | 연금 골드 = 기본값 × (1 + 보너스) | [추정] Steam 가이드. 처치 골드 %와는 별개 스탯 [확인: 스탯 ID 분리] |
| 유물함/유물 | `…:ADDITIVE` 스탯(공격력%, 최대 HP%, 공격·시전 속도%, 이동속도%, 효과 범위%, 보스 피해% 등) | 해당 스탯의 **Increased** 합산 | [확인: 데이터의 모드 타입] / 룬·장비의 Increased와 같은 풀인지 [추정] |
| 유물함/유물 | `…:FLAT` 스탯(치명타 피해 +%p, 재사용 대기시간 감소, 저항, 피해 감소, 막기/회피 확률, 고정 회복 등) | 해당 스탯에 그대로 가산 | [확인: 데이터의 모드 타입] |
| 유물함 공명 | 특수 규칙(mod ID) | 버킷이 아닌 개별 규칙. 예: "재사용 대기시간 감소 1%당 스킬 피해 2% 증가로 전환", "투사체 +1 / 투사체 피해 −30%" | [확인: 효과 정의] / 내부 합산 위치 [미확인] |
| 공명기(Resonator) | 다른 유물함 공명 수치 ×1.5 | 공명 수치에 대한 승수 | [확인: 효과 정의] |

- 상한 관련(다른 문서 소관이지만 유물 선택에 영향): 방어력 피해 감소 상한 75%(근접 영웅은 1.01.00부터 85%), 재사용 대기시간 감소·저항·회피·막기에 상한 존재, 치명타 확률은 1.2.5부터 100% 상한 표시. [확인] 1.01.00/1.2.5 패치노트, taskbarhero.wiki /mechanics
- 저항은 선형(1포인트 = 해당 원소 피해 1% 감소, 음수면 피해 증가)이라 Echo 유물의 저항 페널티는 받는 피해에 직접 반영된다. [확인] taskbarhero.wiki /mechanics, 1.01.00 패치노트("음수 저항이 0과 같은 피해를 주던 문제 수정")

---

## 8. 시스템별 추가·변경 패치 연표

| 날짜(UTC 기준 공지일) | 버전 | 내용 | 출처 |
|---|---|---|---|
| 2025-10 ~ 2026-03 | 데모 0.00.03~0.00.20 | 데모 운영(룬·펫 관련 변경 공지 없음) | Steam 뉴스 |
| 2026-04-27 | 플레이테스트 0.01.01 | 펫 보유 효과가 실제의 10배 이상으로 표시되던 문제 수정 | Steam 뉴스 |
| 2026-04-28 | 0.01.02 | 룬 스탯 합계 표시 오류 수정, 성장의 룬 등 경험치 룬 설명 수정(고정 증가를 %로 잘못 표기), 룬 위치 겹침 수정 | 〃 |
| 2026-04-29 | 0.01.03 | 스테이지 보스 상자 보관 룬 구매 불가 수정 | 〃 |
| 2026-04-30 | 0.01.04 | "펫은 배치하지 않아도 보유 효과 적용" 안내 추가, 스테이지 보스 골드 룬 미적용 수정, 룬 보너스가 새 캐릭터에 미적용되던 문제 수정, 연금 골드 룬 표시 수정 | 〃 |
| 2026-05-02 | 0.01.05 | 웨이브 수 감소 룬 보유 시 액트 보스 웨이브가 2번 나오던 문제 수정 | 〃 |
| 2026-05-27 | **1.00.01 정식 출시** | 룬 197노드, 펫 8종(무료 5 + Supporter Pack 3), 업적 56개 | Steam 뉴스, DB |
| 2026-05-28 ~ 07-02 | 1.00.02 ~ 1.00.22 | 업적 미달성 버그 수정 다수(1-1 클리어, Arcana 획득, 무역선), 룬 UI 버그 수정. 규칙 변경 없음 | 〃 |
| 2026-07-22 | 1.01.00 | 밸런스 패치(영웅 패시브·몬스터·방어력 상한). 룬/펫 변경 없음 | 〃 |
| 2026-09-08 | **1.02.00 Plaguelands** | 룬 노드 44개 추가(역병 27 + 기타 17), 룬 UI 최대 축소 배율 확대, 보이지 않던 액트 보스 상자 보관 노드 수정, 통계 UI, 외형 시스템 | 〃 |
| 2026-09-14 | 1.02.03 | 역병 지대 일반 상자/스테이지 보스 상자 드롭 확률 룬 노드 각 1개 추가 | 〃 |
| 2026-10-22 | **1.3.0 Halloween & Relic** | 유물 시스템(유물함·유물·공명), 큐브 조율 레시피, 할로윈 펫 2종, 업적 24개, 오프라인 경험치 룬 3개·액트 보스 경험치 룬 2개 추가, 액트 보스 경험치 룬 1개 +2,000→+10,000/레벨 | 〃 |
| 2026-10-26 | 1.3.1 | UI 핫픽스(규칙 변경 없음) | 〃 |
| 2026-10-27 | 1.3.2 | 유물 혼돈 저항 페널티 예외 수정, 유물 소수점 표시 수정, 최대 레벨 초과 룬 고정 | 〃 |
| 2026-11 (예고) | 미출시 | 던전 4종, 신규 스킬, 최대 레벨 상향, 신규 난이도 | "October & November Update Plans" |

---

## (a) 출처 목록과 신뢰도 평가

| 출처 | URL | 버전/시점 | 신뢰도 | 비고 |
|---|---|---|---|---|
| Steam 공식 공지(뉴스 API, 117건 전량) | https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=3678970&count=200&maxlength=0 | 2025-10-14 ~ 2026-11-12 | **최상(공식)** | 규칙은 서술형, 수치표는 거의 없음 |
| 〃 미러(읽기 편함) | https://taskbarhero.wiki/news/halloween-relic-update-ver-1-3-0 외 | 최근 30건 | 최상 | 원문 그대로 |
| Steam 업적 | https://steamcommunity.com/stats/3678970/achievements/ , https://api.steampowered.com/ISteamUserStats/GetGlobalAchievementPercentagesForApp/v2/?gameid=3678970 | 2026-11-21 | 최상 | 80개 |
| taskbarhero.wiki (TBH Wiki) | https://taskbarhero.wiki/runes , /pets , /mechanics , /database ; 원시 JSON `/data/rune_tree.json`, `/data/runes.json`, `/data/t/<table>.json` | **v1.00.17** (사이트 명시) | 높음(게임 파일 추출 45개 테이블) — **단 구버전** | 역병·유물 없음. taskbarhero.top은 같은 사이트의 복제 |
| flex.shunshu-labo.org TBH DBAPP | https://flex.shunshu-labo.org/en/tbh/ ; 원시 JSON `/wp-content/themes/shunshu/tbh/data/tbh-data.json` | **v1.03.00** (2026-10-23 갱신) | 높음(유물·봉헌·조율 전량) | 룬은 스탯별 집계만 |
| flex.shunshu-labo.org 가이드 | https://flex.shunshu-labo.org/en/task-bar-hero/2616/ , /2624/ | 2026-10-22 | 중상 | 유물함 2개 장착, 해금 조건 |
| Steam 가이드 "Killdozer's TBH Encyclopedia" | https://steamcommunity.com/sharedfiles/filedetails/?id=3809950323 | 1.3.0 이후 | 중상 | 유물/조율 서술이 DB와 일치. Rune Tree·Achievements 절은 "COMING SOON" |
| tbhindex.com | https://tbhindex.com/wiki/runes , /wiki/relics , /wiki/reliquaries | v1.3.0 자칭 | 높음으로 추정 — **직접 열람 실패**(Cloudflare 봇 차단, 브라우저로도 불가). 검색 요약 수치만 사용 | 253노드 노드별 수치를 가진 유일한 곳으로 보임 |
| taskbarherowiki.com | https://taskbarherowiki.com/runes | v1.00.09 | 중(구버전) | 197 runes |
| taskbarhero.co (TASKBAR HERO ATLAS) | https://taskbarhero.co/mechanics | v1.00.09 기준, v1.00.13 보정 | 중(구버전) | 스탯별 룬 개수 일치 |
| taskbarheroatlas.com | https://taskbarheroatlas.com/runes/ | 1.3.2 추적 | 중 | 공식 공지 재정리, 수치표 없음 |
| probonk.com | https://probonk.com/tbh-task-bar-hero/ | 197노드 시점 | 중(구버전) | 업적 56 |
| gamewith.ai, taskbarheroguide.com, tbh.city, ExitLag, Mobalytics, GamesRadar 등 | (검색 결과로만) | 혼재 | 낮음~중 | 접근 차단 또는 미열람. 표시 스케일 불일치 사례 있음 |

## (b) 미확인으로 남은 중요 항목

1. **1.02.00 이후 추가된 룬 56노드의 노드별 데이터**(비용 곡선, 최대 레벨, 좌표, 선행 관계). 스탯별 합계와 일부 묶음 총비용만 확보. 원천은 tbhindex.com(차단). 공식 발표 합계(248)와 데이터(253)의 5노드 차이 원인.
2. **룬 선행 조건의 기본 규칙**(부모 요구 레벨이 비어 있는 183노드: 1레벨이면 되는가, 최대 레벨이어야 하는가).
3. **룬 초기화(respec) 기능의 존재·비용·환급률.** 공식 언급 없음, 팬 출처 상충.
4. 룬 메뉴 해금 조건(영웅 레벨 3)의 1차 확인.
5. 펫 동시 배치 수, 할로윈 펫의 한국어 명칭, 향후 이벤트 펫 재획득 가능 여부.
6. 유물: 공명 조건이 유물함 2개 사이에서 합산되는지, 흰색 유물의 공명 색 계산, 유물함 슬롯 색에 흰색이 나오는지, 공명 효과 범위 수치의 결정 시점, 유물/유물함 **합성 레시피의 투입 수·성공률**, 오염된 유물/유물함의 상자별 드롭 확률, "Golden Relic - Broken Chain"의 획득 경로, 공명 효과 수(62 vs 63).
7. 유물·펫 수정치가 코드의 어느 출처(ModSource)로 분류되는지, 룬의 고정 추가 골드/경험치에 % 배율이 곱해지는지.
8. 업적 보상 유무(없는 것으로 보이나 게임 내 확인 필요), 도감·칭호 시스템 유무.
9. 한국어 클라이언트의 공식 용어(유물/유물함/공명/조율 등).
10. 11월 예고 업데이트(최대 레벨 상향, 신규 난이도)와 "시즌 1"이 영구 성장에 미칠 영향.
