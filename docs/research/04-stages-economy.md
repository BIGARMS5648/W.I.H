# 04. 스테이지·난이도·몬스터, 골드 경제, 오프라인 보상, 패치 연대기

- 대상: 《TBH: Task Bar Hero》 (Steam app 3678970, 개발 Tesseract Studio / Nugem Studio, 배급 Nugem Studio)
- 조사 시점: 2026-11-21 ~ 11-22. 이 문서의 "현재"는 **Ver 1.3.2 (2026-10-27 배포)** 를 뜻한다.
- 목적: 독립 구현 설계를 위한 **규칙·수치의 사실 기록**. 원작의 코드·아트·문장은 옮기지 않았고, 표의 수치는 공개 자료(공식 공지, 게임 데이터 추출 기반 팬 DB)에 실린 값을 그대로 적었다.

## 0. 읽는 법

### 0.1 태그
- **[확인]** 공식 자료(Steam 공지·스토어), 게임 데이터 추출 기반 DB, 또는 서로 독립된 2개 이상 출처의 일치.
- **[추정]** 단일 비공식 출처이거나 데이터로부터의 추론.
- **[미확인]** 찾지 못함.

### 0.2 버전 기준 (가장 중요)
이 문서의 수치는 기준 버전이 서로 다른 두 데이터 스냅샷과 공식 공지를 겹쳐서 만들었다. 표마다 기준 버전을 적었다.

| 약칭 | 출처 | 데이터 기준 버전 | 쓰임 |
|---|---|---|---|
| **W** | taskbarhero.wiki (`/data/t/*.json`, `/data/stages/*.json`, `/data/boxes/*.json`) — 게임 파일 추출 테이블 45종 | 사이트 자체 표기 **v1.00.17 (2026-06-20)**. Plaguelands·유물 없음 | 스테이지 120개, 스테이지 레벨 배율표, 몬스터 기본값, 상자 테이블, 오프라인 보상표, 룬 비용, 레벨 표 |
| **F** | flex.shunshu-labo.org "TBH DBAPP" (`tbh-data.json`, data version 3.1.0, updated 2026-10-23) | 사이트 자체 표기 **v1.03.00** (1.3.0) | Plaguelands 60스테이지, 오염된 액트 보스, 이벤트 스테이지, 1.3.0 시점 몬스터 공격력, 상자 쿨다운, 난이도별 저항 페널티, 역병 강도 표 |
| **S** | Steam 공지 전문 117건 (`ISteamNews/GetNewsForApp`, 2025-10-14 ~ 2026-11-12) | 각 공지의 버전 | 패치 연대기, 규칙 변경 이력, 온라인 기능 |

- W와 F를 기계적으로 대조한 결과, **일반 지역 120개 스테이지의 레벨·웨이브 수·웨이브당 몬스터 수·보스·몬스터 구성·상자 드롭률은 1.00.17과 1.3.0 사이에 한 건도 달라지지 않았다**(불일치 0건). 스테이지 레벨 배율표(1~170)와 레벨업 경험치 표(1~100)도 두 스냅샷이 완전히 같다. 따라서 이 항목들은 "1.3.x 현재값"으로 보아도 된다. **[확인]**
- 달라진 것: 몬스터 **공격력**(1.01.00, 1.2.0에서 하향), 상자 **쿨다운**, 룬 노드 수, 그리고 1.2.0 이후 추가된 콘텐츠 전부.
- 원 데이터 표기 규칙: 게임 테이블은 대부분 **정수 고정소수점**을 쓴다. 배율·확률은 1000 = 1배 = 100%(‰), 영웅 공격 속도·이동 등은 100 = 1.0 식이다. 아래에서 "‰ 표기"라고 쓴 것은 이 뜻이다.

---

## 1. 패치 연대기

### 1.1 요약
- **출시일: 2026-05-27** (Steam 스토어 `release_date` "May 27, 2026"; 공지상 KST 14:00 예정이 QA 문제로 4시간 늦춰져 18:00 KST = 09:00 UTC에 시작). **[확인]** (S, https://store.steampowered.com/api/appdetails?appids=3678970)
- **얼리 액세스가 아니다.** 스토어 장르는 Casual / Indie / RPG / Free To Play이고 Early Access 표시가 없다. 기본 게임 무료(F2P) + DLC. **[확인]**
- 출시 전 단계: 데모(ver 0.00.03 ~ 0.00.20, 2025-10 ~ 2026-03, 2026-04-26 종료·데이터 삭제) → 플레이테스트(ver 0.01.01 ~ 0.01.06, 2026-04-27 ~ 05-03, 데이터 삭제) → 정식 출시(1.00.00). 출시일은 2026-04-01 → 04-15 → "4월 중" → 05-27로 세 번 밀렸다. **[확인]** (S)
- **현재 최신 버전: Ver 1.3.2, 2026-10-27 04:31 UTC 공지.** 이후 2026-11-12까지의 공지는 서버 장애·개인정보 유출 안내뿐이고 새 버전은 없다(11-22 조회 기준). **[확인]** (S)
- 버전 표기는 `1.00.NN` → `1.01.NN` → `1.02.NN` 형식이었다가 1.2.4부터 `1.2.N`, `1.3.N` 형식으로 바뀌었다(같은 계열). **[확인]**
- 9월 30일 공지의 11월 예정분("던전 & 엔드게임 콘텐츠 업데이트: 신규 던전 4종, 신규 스킬, 최대 레벨 상향, 신규 난이도")은 11-22 현재 **미배포**. **[확인]**

### 1.2 버전별 표 (날짜는 Steam 공지 게시 시각 UTC)

| 날짜(UTC) | 버전 | 구분 | 주요 내용 (규칙에 영향 있는 것 위주) |
|---|---|---|---|
| 2025-10-15 ~ 2026-03-24 | 0.00.03 ~ 0.00.20 | 데모 | 데모 소규모 업데이트 15회. 2026-01-30에 "Act 1~3 + 난이도 시스템, 교역선(Trading Ship), 13개 언어, F2P + 유료 DLC(추가 클래스 2종 등)"로 출시 내용 예고 |
| 2026-04-27 ~ 05-02 | 0.01.01 ~ 0.01.06 | 플레이테스트 | 전투 밸런스 대규모 조정. 0.01.03: 방어도 공식 조정, "Hell 이후 상자 드롭률이 과도하게 낮던 문제" 수정. 0.01.05: 웨이브 수 감소 룬 보유 시 액트 보스 웨이브가 두 번 나오던 문제 수정 |
| 2026-05-27 | 1.00.00 | **정식 출시** | F2P. DLC: Priest(무료), Hunter·Slayer(각 $4.99), Supporter Pack(펫 3종, $3.99), Extra Stash 3탭($2.99), OST($4.99) |
| 05-27 | 1.00.01 | 핫픽스 | 치트 감지 시 경고 후 종료(영구 제재 = 게임은 가능, 마켓 거래 불가). Soulstone 등급 수정 |
| 05-28 | 1.00.02 / 1.00.03 | 핫픽스 | DLC 영웅을 캐릭터 생성 화면에서 선택 가능, 1-1 클리어 업적 수정, 장신구 교체 시 아이템 소실 수정 |
| 05-29 | 1.00.04 | 핫픽스 | "유효하지 않은 Soulstone을 들고 액트 보스에 무한 도전" 수정 |
| 05-30 | 1.00.05 | 긴급 | 동시접속 급증으로 Steam 아이템 서버 장애 → 큐브의 Alchemy/Crafting/Decoration/Engraving/Inscription/Offering 일시 차단 |
| 05-30 | 1.00.06 | 긴급 | 차단 해제, 상자·큐브 응답 속도 임시 개선. (05-31 재차 차단, "상자 드롭률이 크게 낮아졌다"는 보고 → Steam 측 호출 제한 추정이라고 공지) |
| 06-01 | 1.00.07 | 정책 변경 | **아이템 리셋 & 마켓 정책 변경**: 교역선은 큐브 Lv10부터, 장비는 Legendary 이상만 거래(재료는 전 등급 거래), Lv 25·35·45·55·60·70·75·85·90 장비와 Type B 장비 삭제, 지역 레벨별 상자 매핑 변경(§5.4), 합성·제작 레벨 구간 변경 |
| 06-02 ~ 06-03 | 1.00.08 / 1.00.09 | 핫픽스 | 1.00.09: Normal 3-8~Nightmare 1-8(스테이지 레벨 30~39) 상자에 Nightmare Soulstone 확률 추가, Nightmare 3-5~Hell 2-4(50~64)에 Hell Soulstone 추가. 서버 부하로 "상자 획득 최소 요청 간격"을 일시 증가 |
| 06-07 | (버전 미표기) | 핫픽스 | 상자가 나오지 않던 문제 수정, 상자 획득 요청을 모았다가 한꺼번에 지급하는 임시 로직. 06-08 Steam 마켓 신규 등록 일시 중단 |
| 06-15 | **1.00.12** | 구조 변경 | **서버 이전**: 핵심 데이터 처리를 개발사 서버로 이전, 서버 무응답 시 게임 종료, 일반/스테이지 보스 상자 최소 획득 시간 단축, 우편함 새로고침 쿨다운 10초→5초, 미구매 DLC 캐릭터 장비는 합성 결과에서 제외, 보유 상자는 우편함으로 이동 |
| 06-15 ~ 06-20 | 1.00.13 ~ 1.00.17 | 핫픽스 | 1.00.14: 스테이지 변경 시 상자를 더 빨리 얻던 문제 수정. 1.00.15: 피해 감소 상한 75%가 제대로 적용되지 않던 문제 수정. 1.00.17: 비정상 스테이지 변경 감지 시 일정 시간 스테이지 변경 차단 (**W 데이터 기준 버전**) |
| 06-22 ~ 06-25 | 1.00.18 ~ 1.00.21 | 핫픽스 | 1.00.19: 최대 이동 속도 제한 오류 수정. 1.00.21(06-25): **Steam 마켓 재개** — 등록 슬롯 4개, 슬롯당 신규 등록 쿨다운 8시간, 상위 3등급(Celestial/Divine/Cosmic) 등록 임시 제한 |
| 07-02 | 1.00.22 / 1.00.23 | 업데이트 | 서버 장애 보상(기념 주화 70개/7일), 우편함을 General/Reward 탭으로 분리, 교역선 슬롯 +5 DLC, Offering 레시피 해금 큐브 Lv20→10 |
| 07-03 ~ 07-15 | 1.00.24 ~ 1.00.28 | 핫픽스 | 1.00.24: 전 스테이지 일반/스테이지 상자 최소 획득 쿨다운 소폭 단축. 1.00.25: 우편 반복 수령 1분 대기. 1.00.26: 상자 획득 관련 보안 취약점 수정. 07-10: 개발 로드맵 공지(이미지) |
| 07-22 | **1.01.00** | 밸런스 | 상위 3등급 거래 재개. **원거리 물리 몬스터 공격력 −25%, 원거리 속성 몬스터 공격력 −40%**, 근접 영웅(Knight/Priest/Slayer) 방어도 물리 피해 감소 상한 75%→85%, 음수 저항이 0과 같게 처리되던 버그 수정, 영웅 패시브·이동 속도 조정 |
| 07-22 ~ 08-11 | 1.01.01 ~ 1.01.05 | 핫픽스 | 07-25 서버 장애·전체 아이템 소실 사고 → 복구·보상. 1.01.05: 세이브 24시간마다 백업(30일 보관), 상자 자동 열기 타이머 수정 |
| 09-08 | **1.02.00** | 콘텐츠 | **Plaguelands(역병지대)**, Lv90 아이템, 신규 고유 옵션, 통계 UI, 룬 44개 추가(역병 관련 27 + 기타 17), 외형(스킨) 시스템, 액트 보스 상자 구성 표준화, 무기 공격 속도 조정, 일부 속성 몬스터 공격력 하향, Corrosion 레시피 |
| 09-08 | 1.02.01 / 1.02.02 | 핫픽스 | Plaguelands 진행도 초기화 버그 수정 등 |
| 09-14 | 1.02.03 | 밸런스 | Plaguelands 상자 드롭 확률 룬 노드 2종 추가, Plaguelands 상자 최소 쿨다운 단축(§5.4) |
| 09-16 | 1.2.4 | 핫픽스 | **상자 획득 규칙 개편**: 획득 후 무조건 대기 폐지, "기간당 획득 가능 총량" 방식만 남김(§5.4) |
| 09-21 ~ 09-22 | 1.2.5 ~ 1.2.8 | 소규모 | 1.2.5: 재료 아이템 5개까지 중첩, Dusk Wanderer 스킨 유료 전환, Credits 메뉴 |
| 10-22 | **1.3.0** | 콘텐츠 | **유물(Relic)·성유물함(Reliquary)**, Attunement 레시피, 할로윈 이벤트(~11-11 23:59 UTC), Plaguelands 개선·업적 24개, 일반 지역 상자 대기 시간 단축, Material Stash DLC, 오프라인 EXP 룬 3개·액트 보스 EXP 룬 2개 추가, Steam 연결 불안정 시에도 플레이 가능(교역선·우편함만 제한) |
| 10-26 | 1.3.1 | 핫픽스 | UI 수정, 게임 내 배너를 Steam 웹 브라우저로 열도록 변경 |
| 10-27 | **1.3.2** | 핫픽스 (최신) | 로그인 시스템 개선, 할로윈 티켓은 해당 난이도 것만 드롭, 인벤토리가 가득 차도 재료 소모로 칸이 비면 합성 가능, 유물 Chaos 저항 페널티 버그 수정, 룬 레벨 상한 초과분 강제 보정 |
| 11-09 / 11-12 | – | 공지 | 429 오류 서버 장애(해결) / 외부 게임 서버 서비스 관리 도구 취약점으로 인한 개인정보 유출 통지(2026-10-17 ~ 11-08) |

출처: https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=3678970&count=300&maxlength=0 (전문), https://store.steampowered.com/news/app/3678970 , 미러 https://taskbarhero.wiki/news (최근 30건). 빠진 번호(1.00.10, 1.00.11, 1.01.03)는 공지 제목에 버전이 없어 특정하지 못했다. **[미확인]**

### 1.3 "과거 규칙"과 "현재 규칙"을 섞기 쉬운 지점
| 주제 | 과거 | 현재(1.3.2) | 바뀐 버전 |
|---|---|---|---|
| 상자 생성 방식 | 클라이언트가 Steam 인벤토리 서비스에 직접 요청 | 개발사 서버가 쿨다운·보상 검증 | 1.00.12 |
| 상자 쿨다운(일반 지역, 지역 Lv15+) | 일반 5분 / 스테이지 보스 7분(1.00.17 데이터) → 4분 / 6분 | **3분 / 5분** | 1.00.24, 1.3.0 |
| 상자 "획득 후 무조건 대기" | 있음 | 없음(기간당 총량 방식) | 1.2.4 |
| 근접 영웅 방어도 감소 상한 | 75% | 85% (원거리 영웅은 75%) | 1.01.00 |
| 원거리 몬스터 공격력 | 기본값 | 물리 −25%, 속성 −40%, 일부 추가 하향 | 1.01.00, 1.2.0 |
| 장비 레벨 구간 | 1,5,10,…,90 (5단위) | 1,5,10,15,20,30,40,50,65,80 + (1.2.0에서 재도입된) 90 | 1.00.07, 1.02.00 |
| 교역선 해금 | 처음부터 | 큐브 Lv10 | 1.00.07 |
| 최상위 콘텐츠 | Torment 3-10 | Torment Plaguelands 강도 20 + 오염된 액트 보스 | 1.02.00 |

---

## 2. 스테이지 구조

### 2.1 전체 구조 [확인]
- **3개 액트 × 10개 스테이지 × 4개 난이도 = 120개 스테이지.** 액트마다 x-1 ~ x-9는 일반 스테이지(`STAGETYPE=NORMAL`), x-10은 액트 보스 스테이지(`ACTBOSS`). 즉 일반 108개 + 액트 보스 12개. (W `stages` 테이블 120행, F 동일, Steam 스토어 설명 "3 Acts and 4 difficulty tiers")
- 스테이지 키 = `난이도(1~4)` `액트(1~3)` `번호(01~10)`. 예: 1101 = Normal 1-1, 4310 = Torment 3-10.
- 액트 1: Pasture → Shadow Meadow → Wasteland → Eerie Canyon → Burning Village Entrance → Rumstreet Square → City Outskirts → Cemetery → Cursed Land → **Throne of Darkness**(보스 Skeleton King)
- 액트 2: Oasis Road → Sandstorm Valley → Desert Underground Cave → Bug Nest → Scorching Dunes → Sunset Ruins → Midnight Sands → Sacred Tomb → Pharaoh's Crypt → **Pharaoh's Underchannel**(보스 Desert Overlord)
- 액트 3: Snowbound Outpost → Frozen Battlefield → Glacial Cave Entrance → Frozen Glacier Cavern → Hell Gate → Burning Ravine → Plains of Torment → Citadel of Ruin → Core of the Abyss → **Hell Command Chamber**(보스 Archon Morkar)
- 난이도가 올라가도 스테이지 이름·배경은 같고, **스테이지 레벨·웨이브 수·웨이브당 몬스터 수·몬스터 구성 가중치**가 달라진다.
- 1.2.0 이후 별도 스테이지 타입: `PLAGUE`(60개), `CONTAMINACTBOSS`(9개), `EVENT`(3개, 기간 한정). F 기준 스테이지 총 192개. §2.6~2.8.

### 2.2 스테이지 하나의 구성 [확인: W·F 일치]
- 필드: `StageLevel`, `WaveAmount`(웨이브 수), `WaveMonsterAmount`(웨이브당 몬스터 수), `Monsters`("몬스터키_가중치" 목록), `BossMonsterKey` + 보스 배율 4종 + `BossScale`(3 = 크기 3배), 상자 2종의 아이템 키와 드롭률, `FirstClearDropKey`, `NextStageKey`.
- 일반 몬스터 처치 수 = 웨이브 수 × 웨이브당 수. 여기에 **스테이지 보스 1마리**가 더해진다. 보스는 전용 몬스터가 아니라 **일반 몬스터 종을 배율로 강화한 개체**다(예: Normal 1-1의 보스는 Goblin Thief에 공격 ×2, HP ×3, 골드 ×2, EXP ×3).
- 각 웨이브의 몬스터는 `Monsters` 가중치에 따른 **가중 무작위**로 뽑힌다(가중치 합 대비 비율이 출현 확률).
- 범위(일반 스테이지):

| 난이도 | 스테이지 레벨 | 웨이브 수 | 웨이브당 몬스터 | 클리어당 처치 수(보스 제외) |
|---|---|---|---|---|
| Normal | 1 ~ 31 (액트 보스 12/22/32) | 10 ~ 18 | 1 ~ 11 | 10 ~ 198 |
| Nightmare | 33 ~ 52 | 20 ~ 23 | 10 ~ 15 | 200 ~ 345 |
| Hell | 53 ~ 77 | 24 ~ 27 | 15 ~ 18 | 360 ~ 486 |
| Torment | 78 ~ 95 | 29 ~ 31 | 18 ~ 21 | 522 ~ 651 |

- 액트 보스 스테이지는 웨이브·일반 몬스터·상자 드롭률 필드가 비어 있고 보스 한 마리와 액트 보스 상자만 있다. 입장에 **그 난이도의 Soulstone 1개**(`SoulstoneItemKey` 190001~190004, `SoulstoneAmount` 1)가 필요하다. **[확인]**
- 보스가 "마지막 웨이브에 섞여 나오는지, 웨이브가 모두 끝난 뒤 따로 나오는지"는 데이터에 없다. **[미확인]**
- 웨이브 사이에는 파티가 다음 웨이브 지점까지 걸어간다. 이때 **파티 전체가 가장 느린 구성원의 이동 속도**로 움직인다(F 메카닉 설명). 1.2.0 공식 고유 옵션에 "웨이브 사이 이동을 파티 평균/가장 빠른/자신 제외 가장 느린 구성원 속도로" 바꾸는 장화가 있어 기본 규칙과 맞는다. **[확인]**
- 웨이브 수 감소 룬(Rune of Brevity, `WaveCountReduction`): 1.00.17에는 노드 1개(비용 20,000,000골드, −1웨이브). 1.2.0에서 "웨이브 수 감소 룬" 추가, F 기준 합계 −3웨이브(노드 3개). **[확인]**

### 2.3 120개 스테이지 전체 표 (W 1.00.17 기준. 1.3.0과 구조 동일. 보스 HP·ATK와 골드·EXP는 W의 계산값 = §4.1 공식)
주의: 보스 ATK는 1.00.17 기본 공격력 기준이다. 1.01.00·1.2.0에서 공격력이 내려간 몬스터(§4.3)가 보스인 스테이지는 현재 값이 더 낮다. HP·골드·EXP는 영향이 없다.

| Key | 난이도 | 스테이지 | 이름 | Lv | 웨이브 | 웨이브당 수 | 처치 수 | 골드/클리어 | EXP/클리어 | 스테이지 보스 (HP / ATK) | 일반상자 드롭률 | 보스상자 드롭률 | 상자 쿨다운(분) 1.00.17→1.3.0 |
|---|---|---|---|---:|---:|---:|---:|---:|---:|---|---:|---:|---|
| 1101 | Normal | 1-1 | Pasture | 1 | 10 | 1 | 10 | 14 | 16 | Goblin Thief (12 / 2) | 16.0% | 100.0% | 3/3→2/2 |
| 1102 | Normal | 1-2 | Shadow Meadow | 2 | 11 | 2 | 22 | 53 | 49 | Goblin Shaman (30 / 5) | 16.0% | 100.0% | 3/3→2/2 |
| 1103 | Normal | 1-3 | Wasteland | 3 | 11 | 3 | 33 | 95 | 74 | Orc (84 / 5) | 16.0% | 100.0% | 3/3→2/2 |
| 1104 | Normal | 1-4 | Eerie Canyon | 5 | 12 | 3 | 36 | 197 | 292 | Orc Warrior (150 / 10) | 12.0% | 100.0% | 3/3→2/3 |
| 1105 | Normal | 1-5 | Burning Village Entrance | 6 | 12 | 4 | 48 | 356 | 748 | Elite Orc (405 / 12) | 12.0% | 80.0% | 3/3→2/3 |
| 1106 | Normal | 1-6 | Rumstreet Square | 7 | 12 | 5 | 60 | 453 | 1,168 | Skeleton (180 / 18) | 8.0% | 80.0% | 3/3→2/3 |
| 1107 | Normal | 1-7 | City Outskirts | 8 | 12 | 6 | 72 | 327 | 1,522 | Skeleton Warrior (390 / 21) | 8.0% | 60.0% | 3/3→2/3 |
| 1108 | Normal | 1-8 | Cemetery | 10 | 13 | 6 | 78 | 607 | 2,702 | Skeleton Archer (204 / 24) | 3.0% | 40.0% | 3/5→2/4 |
| 1109 | Normal | 1-9 | Cursed Land | 11 | 13 | 7 | 91 | 1,006 | 5,987 | Elite Orc (1,188 / 21) | 3.0% | 40.0% | 3/5→2/4 |
| 1110 | Normal | 1-10 | Throne of Darkness | 12 | – | – | 1 | 325 | 133 | **액트 보스** Skeleton King (1,544 / 24) | – | 액트보스 상자 930101 | – |
| 1201 | Normal | 2-1 | Oasis Road | 13 | 14 | 7 | 98 | 935 | 7,416 | Ratfolk Berserker (888 / 24) | 3.0% | 40.0% | 3/5→2/4 |
| 1202 | Normal | 2-2 | Sandstorm Valley | 14 | 14 | 7 | 98 | 1,228 | 10,032 | Ratfolk Warrior (540 / 24) | 3.0% | 40.0% | 3/5→2/4 |
| 1203 | Normal | 2-3 | Desert Underground Cave | 15 | 14 | 7 | 98 | 1,277 | 11,752 | Cobra (1,080 / 30) | 2.5% | 30.0% | 5/7→3/5 |
| 1204 | Normal | 2-4 | Bug Nest | 16 | 15 | 7 | 105 | 1,437 | 15,155 | Venom Insect (1,098 / 42) | 2.5% | 30.0% | 5/7→3/5 |
| 1205 | Normal | 2-5 | Scorching Dunes | 17 | 15 | 7 | 105 | 1,365 | 15,336 | Homunculus (3,432 / 30) | 2.5% | 30.0% | 5/7→3/5 |
| 1206 | Normal | 2-6 | Sunset Ruins | 18 | 15 | 8 | 120 | 2,586 | 35,250 | Ghoul (8,058 / 39) | 2.5% | 30.0% | 5/7→3/5 |
| 1207 | Normal | 2-7 | Midnight Sands | 19 | 15 | 8 | 120 | 2,683 | 35,557 | Plague Rat (4,668 / 42) | 2.5% | 30.0% | 5/7→3/5 |
| 1208 | Normal | 2-8 | Sacred Tomb | 20 | 16 | 8 | 128 | 2,157 | 30,552 | Kobold Guard (4,464 / 42) | 2.0% | 20.0% | 5/7→3/5 |
| 1209 | Normal | 2-9 | Pharaoh's Crypt | 21 | 16 | 8 | 128 | 3,884 | 58,597 | Mummy (14,928 / 39) | 2.0% | 20.0% | 5/7→3/5 |
| 1210 | Normal | 2-10 | Pharaoh's Underchannel | 22 | – | – | 1 | 850 | 281 | **액트 보스** Desert Overlord (20,294 / 62) | – | 액트보스 상자 930201 | – |
| 1301 | Normal | 3-1 | Snowbound Outpost | 23 | 16 | 8 | 128 | 2,954 | 50,045 | Ratfolk Berserker (5,610 / 42) | 2.0% | 20.0% | 5/7→3/5 |
| 1302 | Normal | 3-2 | Frozen Battlefield | 24 | 16 | 8 | 128 | 3,084 | 44,825 | Ratfolk Warrior (2,952 / 36) | 2.0% | 20.0% | 5/7→3/5 |
| 1303 | Normal | 3-3 | Glacial Cave Entrance | 25 | 17 | 9 | 153 | 4,278 | 56,320 | Cobra (5,202 / 45) | 2.0% | 20.0% | 5/7→3/5 |
| 1304 | Normal | 3-4 | Frozen Glacier Cavern | 26 | 17 | 9 | 153 | 4,592 | 59,428 | Venom Insect (4,746 / 60) | 2.0% | 20.0% | 5/7→3/5 |
| 1305 | Normal | 3-5 | Hell Gate | 27 | 17 | 9 | 153 | 4,619 | 69,836 | Homunculus (13,434 / 45) | 2.0% | 20.0% | 5/7→3/5 |
| 1306 | Normal | 3-6 | Burning Ravine | 28 | 17 | 9 | 153 | 9,087 | 176,366 | Ghoul (28,986 / 57) | 2.0% | 20.0% | 5/7→3/5 |
| 1307 | Normal | 3-7 | Plains of Torment | 29 | 17 | 10 | 170 | 9,581 | 171,264 | Plague Rat (15,558 / 60) | 2.0% | 20.0% | 5/7→3/5 |
| 1308 | Normal | 3-8 | Citadel of Ruin | 30 | 18 | 10 | 180 | 16,076 | 279,866 | Kobold Guard (13,914 / 60) | 2.0% | 20.0% | 5/7→3/5 |
| 1309 | Normal | 3-9 | Core of the Abyss | 31 | 18 | 11 | 198 | 16,054 | 296,901 | Mummy (43,788 / 54) | 2.0% | 20.0% | 5/7→3/5 |
| 1310 | Normal | 3-10 | Hell Command Chamber | 32 | – | – | 1 | 1,875 | 64 | **액트 보스** Archon Morkar (77,698 / 76) | – | 액트보스 상자 930301 | – |
| 2101 | Nightmare | 1-1 | Pasture | 33 | 20 | 10 | 200 | 10,157 | 181,935 | Ratfolk Berserker (14,838 / 57) | 1.5% | 15.0% | 5/7→3/5 |
| 2102 | Nightmare | 1-2 | Shadow Meadow | 34 | 20 | 10 | 200 | 12,353 | 219,150 | Ratfolk Warrior (7,470 / 54) | 1.5% | 15.0% | 5/7→3/5 |
| 2103 | Nightmare | 1-3 | Wasteland | 35 | 20 | 11 | 220 | 14,504 | 237,759 | Cobra (12,630 / 66) | 1.5% | 15.0% | 5/7→3/5 |
| 2104 | Nightmare | 1-4 | Eerie Canyon | 35 | 21 | 11 | 231 | 15,219 | 272,558 | Venom Insect (10,332 / 84) | 1.5% | 15.0% | 5/7→3/5 |
| 2105 | Nightmare | 1-5 | Burning Village Entrance | 36 | 21 | 12 | 252 | 20,248 | 363,822 | Homunculus (28,338 / 63) | 1.5% | 15.0% | 5/7→3/5 |
| 2106 | Nightmare | 1-6 | Rumstreet Square | 37 | 21 | 12 | 252 | 24,524 | 452,341 | Ghoul (59,358 / 81) | 1.5% | 15.0% | 5/7→3/5 |
| 2107 | Nightmare | 1-7 | City Outskirts | 38 | 21 | 13 | 273 | 15,327 | 261,872 | Plague Rat (31,002 / 87) | 1.5% | 15.0% | 5/7→3/5 |
| 2108 | Nightmare | 1-8 | Cemetery | 39 | 21 | 13 | 273 | 21,010 | 369,567 | Kobold Guard (27,036 / 90) | 1.5% | 15.0% | 5/7→3/5 |
| 2109 | Nightmare | 1-9 | Cursed Land | 40 | 22 | 13 | 286 | 30,705 | 558,921 | Mummy (83,100 / 81) | 1.5% | 15.0% | 5/7→3/5 |
| 2110 | Nightmare | 1-10 | Throne of Darkness | 40 | – | – | 1 | 3,055 | 1,339 | **액트 보스** Skeleton King (125,184 / 112) | – | 액트보스 상자 930401 | – |
| 2201 | Nightmare | 2-1 | Oasis Road | 41 | 22 | 13 | 286 | 23,150 | 434,998 | Ratfolk Berserker (25,458 / 87) | 1.5% | 15.0% | 5/7→3/5 |
| 2202 | Nightmare | 2-2 | Sandstorm Valley | 41 | 22 | 13 | 286 | 28,760 | 533,408 | Ratfolk Warrior (11,880 / 78) | 1.5% | 15.0% | 5/7→3/5 |
| 2203 | Nightmare | 2-3 | Desert Underground Cave | 42 | 22 | 13 | 286 | 28,671 | 519,485 | Cobra (19,788 / 99) | 1.5% | 15.0% | 5/7→3/5 |
| 2204 | Nightmare | 2-4 | Bug Nest | 42 | 22 | 13 | 286 | 27,696 | 516,123 | Venom Insect (16,194 / 126) | 1.5% | 15.0% | 5/7→3/5 |
| 2205 | Nightmare | 2-5 | Scorching Dunes | 43 | 22 | 13 | 286 | 24,475 | 457,877 | Homunculus (43,794 / 93) | 1.5% | 15.0% | 5/7→3/5 |
| 2206 | Nightmare | 2-6 | Sunset Ruins | 43 | 22 | 13 | 286 | 36,788 | 699,465 | Ghoul (85,686 / 117) | 1.5% | 15.0% | 5/7→3/5 |
| 2207 | Nightmare | 2-7 | Midnight Sands | 44 | 22 | 14 | 308 | 37,097 | 718,190 | Plague Rat (44,268 / 123) | 1.5% | 15.0% | 5/7→3/5 |
| 2208 | Nightmare | 2-8 | Sacred Tomb | 44 | 22 | 14 | 308 | 30,488 | 574,538 | Kobold Guard (36,216 / 123) | 1.5% | 15.0% | 5/7→3/5 |
| 2209 | Nightmare | 2-9 | Pharaoh's Crypt | 45 | 23 | 14 | 322 | 49,669 | 940,584 | Mummy (110,400 / 111) | 1.5% | 15.0% | 5/7→3/5 |
| 2210 | Nightmare | 2-10 | Pharaoh's Underchannel | 45 | – | – | 1 | 3,955 | 2,066 | **액트 보스** Desert Overlord (138,002 / 220) | – | 액트보스 상자 930451 | – |
| 2301 | Nightmare | 3-1 | Snowbound Outpost | 46 | 23 | 14 | 322 | 32,180 | 613,794 | Ratfolk Berserker (33,558 / 120) | 1.5% | 15.0% | 5/7→3/5 |
| 2302 | Nightmare | 3-2 | Frozen Battlefield | 47 | 23 | 14 | 322 | 37,269 | 648,367 | Ratfolk Warrior (16,476 / 114) | 1.5% | 15.0% | 5/7→3/5 |
| 2303 | Nightmare | 3-3 | Glacial Cave Entrance | 48 | 23 | 14 | 322 | 36,122 | 515,227 | Cobra (27,216 / 144) | 1.5% | 15.0% | 5/7→3/5 |
| 2304 | Nightmare | 3-4 | Frozen Glacier Cavern | 49 | 23 | 14 | 322 | 37,310 | 516,395 | Venom Insect (23,376 / 198) | 1.5% | 15.0% | 5/7→3/5 |
| 2305 | Nightmare | 3-5 | Hell Gate | 50 | 23 | 14 | 322 | 36,342 | 564,358 | Homunculus (62,634 / 147) | 1.5% | 15.0% | 5/7→3/5 |
| 2306 | Nightmare | 3-6 | Burning Ravine | 50 | 23 | 14 | 322 | 63,843 | 1,273,382 | Ghoul (122,538 / 183) | 1.5% | 15.0% | 5/7→3/5 |
| 2307 | Nightmare | 3-7 | Plains of Torment | 51 | 23 | 15 | 345 | 59,037 | 1,124,588 | Plague Rat (62,748 / 195) | 1.5% | 15.0% | 5/7→3/5 |
| 2308 | Nightmare | 3-8 | Citadel of Ruin | 51 | 23 | 15 | 345 | 100,690 | 1,921,231 | Kobold Guard (51,336 / 195) | 1.5% | 15.0% | 5/7→3/5 |
| 2309 | Nightmare | 3-9 | Core of the Abyss | 52 | 23 | 15 | 345 | 103,101 | 1,976,858 | Mummy (155,172 / 180) | 1.5% | 15.0% | 5/7→3/5 |
| 2310 | Nightmare | 3-10 | Hell Command Chamber | 52 | – | – | 1 | 5,425 | 206 | **액트 보스** Archon Morkar (273,542 / 280) | – | 액트보스 상자 930501 | – |
| 3101 | Hell | 1-1 | Pasture | 53 | 24 | 15 | 360 | 51,079 | 988,623 | Ratfolk Berserker (46,788 / 192) | 1.0% | 10.0% | 5/7→3/5 |
| 3102 | Hell | 1-2 | Shadow Meadow | 54 | 24 | 15 | 360 | 60,903 | 1,170,450 | Ratfolk Warrior (22,800 / 180) | 1.0% | 10.0% | 5/7→3/5 |
| 3103 | Hell | 1-3 | Wasteland | 55 | 25 | 15 | 375 | 66,083 | 1,164,770 | Cobra (37,380 / 234) | 1.0% | 10.0% | 5/7→3/5 |
| 3104 | Hell | 1-4 | Eerie Canyon | 56 | 25 | 15 | 375 | 68,729 | 1,328,027 | Venom Insect (31,878 / 321) | 1.0% | 10.0% | 5/7→3/5 |
| 3105 | Hell | 1-5 | Burning Village Entrance | 57 | 25 | 15 | 375 | 82,041 | 1,584,417 | Homunculus (84,852 / 240) | 1.0% | 10.0% | 5/7→3/5 |
| 3106 | Hell | 1-6 | Rumstreet Square | 58 | 25 | 15 | 375 | 96,573 | 1,892,717 | Ghoul (172,758 / 321) | 1.0% | 10.0% | 5/7→3/5 |
| 3107 | Hell | 1-7 | City Outskirts | 59 | 25 | 16 | 400 | 58,001 | 1,054,570 | Plague Rat (87,828 / 342) | 1.0% | 10.0% | 5/7→3/5 |
| 3108 | Hell | 1-8 | Cemetery | 59 | 25 | 16 | 400 | 75,656 | 1,405,140 | Kobold Guard (71,856 / 342) | 1.0% | 10.0% | 5/7→3/5 |
| 3109 | Hell | 1-9 | Cursed Land | 60 | 25 | 16 | 400 | 103,600 | 1,979,938 | Mummy (215,700 / 309) | 1.0% | 10.0% | 5/7→3/5 |
| 3110 | Hell | 1-10 | Throne of Darkness | 60 | – | – | 1 | 7,405 | 5,141 | **액트 보스** Skeleton King (324,934 / 426) | – | 액트보스 상자 930601 | – |
| 3201 | Hell | 2-1 | Oasis Road | 61 | 26 | 16 | 416 | 79,836 | 1,563,697 | Ratfolk Berserker (64,608 / 333) | 1.0% | 10.0% | 5/7→3/5 |
| 3202 | Hell | 2-2 | Sandstorm Valley | 62 | 26 | 16 | 416 | 103,117 | 2,004,270 | Ratfolk Warrior (31,284 / 315) | 1.0% | 10.0% | 5/7→3/5 |
| 3203 | Hell | 2-3 | Desert Underground Cave | 63 | 26 | 16 | 416 | 100,935 | 1,917,335 | Cobra (50,976 / 405) | 1.0% | 10.0% | 5/7→3/5 |
| 3204 | Hell | 2-4 | Bug Nest | 64 | 26 | 16 | 416 | 115,018 | 2,245,262 | Venom Insect (43,218 / 558) | 1.0% | 10.0% | 5/7→3/5 |
| 3205 | Hell | 2-5 | Scorching Dunes | 65 | 26 | 16 | 416 | 87,928 | 1,719,030 | Homunculus (114,384 / 420) | 1.0% | 10.0% | 5/7→3/5 |
| 3206 | Hell | 2-6 | Sunset Ruins | 66 | 26 | 16 | 416 | 133,893 | 2,647,588 | Ghoul (231,618 / 564) | 1.0% | 10.0% | 5/7→3/5 |
| 3207 | Hell | 2-7 | Midnight Sands | 67 | 26 | 17 | 442 | 151,787 | 3,038,796 | Plague Rat (117,132 / 609) | 1.0% | 10.0% | 5/7→3/5 |
| 3208 | Hell | 2-8 | Sacred Tomb | 68 | 26 | 17 | 442 | 135,956 | 2,665,158 | Kobold Guard (99,072 / 654) | 1.0% | 10.0% | 5/7→3/5 |
| 3209 | Hell | 2-9 | Pharaoh's Crypt | 69 | 26 | 17 | 442 | 173,430 | 3,411,442 | Mummy (295,728 / 600) | 1.0% | 10.0% | 5/7→3/5 |
| 3210 | Hell | 2-10 | Pharaoh's Underchannel | 69 | – | – | 1 | 10,015 | 12,090 | **액트 보스** Desert Overlord (388,618 / 1,411) | – | 액트보스 상자 930651 | – |
| 3301 | Hell | 3-1 | Snowbound Outpost | 70 | 27 | 17 | 459 | 113,277 | 2,235,564 | Ratfolk Berserker (88,098 / 645) | 1.0% | 10.0% | 5/7→3/5 |
| 3302 | Hell | 3-2 | Frozen Battlefield | 71 | 27 | 17 | 459 | 130,944 | 2,340,638 | Ratfolk Warrior (42,432 / 609) | 1.0% | 10.0% | 5/7→3/5 |
| 3303 | Hell | 3-3 | Glacial Cave Entrance | 72 | 27 | 17 | 459 | 122,607 | 1,773,865 | Cobra (68,796 / 786) | 1.0% | 10.0% | 5/7→3/5 |
| 3304 | Hell | 3-4 | Frozen Glacier Cavern | 73 | 27 | 17 | 459 | 124,927 | 1,756,566 | Venom Insect (58,044 / 1,077) | 1.0% | 10.0% | 5/7→3/5 |
| 3305 | Hell | 3-5 | Hell Gate | 74 | 27 | 17 | 459 | 119,777 | 1,889,616 | Homunculus (152,886 / 807) | 1.0% | 10.0% | 5/7→3/5 |
| 3306 | Hell | 3-6 | Burning Ravine | 75 | 27 | 17 | 459 | 226,667 | 4,630,287 | Ghoul (308,166 / 1,086) | 1.0% | 10.0% | 5/7→3/5 |
| 3307 | Hell | 3-7 | Plains of Torment | 76 | 27 | 18 | 486 | 246,185 | 4,826,469 | Plague Rat (155,148 / 1,167) | 1.0% | 10.0% | 5/7→3/5 |
| 3308 | Hell | 3-8 | Citadel of Ruin | 76 | 27 | 18 | 486 | 340,398 | 6,681,695 | Kobold Guard (126,936 / 1,167) | 1.0% | 10.0% | 5/7→3/5 |
| 3309 | Hell | 3-9 | Core of the Abyss | 77 | 27 | 18 | 486 | 341,907 | 6,744,244 | Mummy (377,472 / 1,068) | 1.0% | 10.0% | 5/7→3/5 |
| 3310 | Hell | 3-10 | Hell Command Chamber | 77 | – | – | 1 | 12,675 | 496 | **액트 보스** Archon Morkar (738,008 / 1,885) | – | 액트보스 상자 930701 | – |
| 4101 | Torment | 1-1 | Pasture | 78 | 29 | 18 | 522 | 169,698 | 3,360,511 | Ratfolk Berserker (112,038 / 1,149) | 0.8% | 8.0% | 5/7→3/5 |
| 4102 | Torment | 1-2 | Shadow Meadow | 79 | 29 | 18 | 522 | 200,236 | 3,943,012 | Ratfolk Warrior (53,772 / 1,089) | 0.8% | 8.0% | 5/7→3/5 |
| 4103 | Torment | 1-3 | Wasteland | 80 | 29 | 18 | 522 | 205,863 | 3,710,264 | Cobra (86,880 / 1,425) | 0.8% | 8.0% | 5/7→3/5 |
| 4104 | Torment | 1-4 | Eerie Canyon | 81 | 29 | 18 | 522 | 211,377 | 4,173,826 | Venom Insect (73,056 / 2,004) | 0.8% | 8.0% | 5/7→3/5 |
| 4105 | Torment | 1-5 | Burning Village Entrance | 82 | 29 | 18 | 522 | 249,394 | 4,918,952 | Homunculus (191,802 / 1,548) | 0.8% | 8.0% | 5/7→3/5 |
| 4106 | Torment | 1-6 | Rumstreet Square | 83 | 29 | 18 | 522 | 289,163 | 5,759,076 | Ghoul (385,386 / 2,154) | 0.8% | 8.0% | 5/7→3/5 |
| 4107 | Torment | 1-7 | City Outskirts | 84 | 29 | 19 | 551 | 169,720 | 3,142,282 | Plague Rat (193,428 / 2,406) | 0.8% | 8.0% | 5/7→3/5 |
| 4108 | Torment | 1-8 | Cemetery | 84 | 29 | 19 | 551 | 221,963 | 4,199,981 | Kobold Guard (158,256 / 2,406) | 0.8% | 8.0% | 5/7→3/5 |
| 4109 | Torment | 1-9 | Cursed Land | 85 | 29 | 19 | 551 | 300,781 | 5,836,831 | Mummy (469,200 / 2,283) | 0.8% | 8.0% | 5/7→3/5 |
| 4110 | Torment | 1-10 | Throne of Darkness | 85 | – | – | 1 | 15,655 | 9,234 | **액트 보스** Skeleton King (706,810 / 3,135) | – | 액트보스 상자 930851 | – |
| 4201 | Torment | 2-1 | Oasis Road | 86 | 30 | 19 | 570 | 227,900 | 4,529,051 | Ratfolk Berserker (138,858 / 2,574) | 0.8% | 8.0% | 5/7→3/5 |
| 4202 | Torment | 2-2 | Sandstorm Valley | 86 | 30 | 19 | 570 | 284,730 | 5,623,910 | Ratfolk Warrior (64,800 / 2,271) | 0.8% | 8.0% | 5/7→3/5 |
| 4203 | Torment | 2-3 | Desert Underground Cave | 87 | 30 | 19 | 570 | 276,909 | 5,346,294 | Cobra (104,436 / 3,087) | 0.8% | 8.0% | 5/7→3/5 |
| 4204 | Torment | 2-4 | Bug Nest | 87 | 30 | 19 | 570 | 303,677 | 6,001,997 | Venom Insect (85,446 / 3,942) | 0.8% | 8.0% | 5/7→3/5 |
| 4205 | Torment | 2-5 | Scorching Dunes | 88 | 30 | 19 | 570 | 228,174 | 4,515,204 | Homunculus (223,884 / 3,111) | 0.8% | 8.0% | 5/7→3/5 |
| 4206 | Torment | 2-6 | Sunset Ruins | 88 | 30 | 19 | 570 | 340,851 | 6,798,582 | Ghoul (438,036 / 3,888) | 0.8% | 8.0% | 5/7→3/5 |
| 4207 | Torment | 2-7 | Midnight Sands | 89 | 30 | 20 | 600 | 377,843 | 7,647,552 | Plague Rat (219,498 / 4,410) | 0.8% | 8.0% | 5/7→3/5 |
| 4208 | Torment | 2-8 | Sacred Tomb | 89 | 30 | 20 | 600 | 279,321 | 5,536,560 | Kobold Guard (179,586 / 4,410) | 0.8% | 8.0% | 5/7→3/5 |
| 4209 | Torment | 2-9 | Pharaoh's Crypt | 90 | 30 | 20 | 600 | 414,376 | 8,226,663 | Mummy (531,600 / 4,446) | 0.8% | 8.0% | 5/7→3/5 |
| 4210 | Torment | 2-10 | Pharaoh's Underchannel | 90 | – | – | 1 | 17,680 | 21,595 | **액트 보스** Desert Overlord (800,810 / 12,206) | – | 액트보스 상자 930901 | – |
| 4301 | Torment | 3-1 | Snowbound Outpost | 91 | 31 | 20 | 620 | 266,824 | 5,313,457 | Ratfolk Berserker (157,080 / 5,400) | 0.8% | 8.0% | 5/7→3/5 |
| 4302 | Torment | 3-2 | Frozen Battlefield | 91 | 31 | 20 | 620 | 299,968 | 5,411,717 | Ratfolk Warrior (73,302 / 4,764) | 0.8% | 8.0% | 5/7→3/5 |
| 4303 | Torment | 3-3 | Glacial Cave Entrance | 92 | 31 | 20 | 620 | 371,796 | 6,231,262 | Cobra (117,966 / 6,996) | 0.8% | 8.0% | 5/7→3/5 |
| 4304 | Torment | 3-4 | Frozen Glacier Cavern | 92 | 31 | 20 | 620 | 275,875 | 3,901,359 | Venom Insect (96,516 / 8,940) | 0.8% | 8.0% | 5/7→3/5 |
| 4305 | Torment | 3-5 | Hell Gate | 93 | 31 | 20 | 620 | 342,359 | 5,669,127 | Homunculus (252,522 / 7,596) | 0.8% | 8.0% | 5/7→3/5 |
| 4306 | Torment | 3-6 | Burning Ravine | 93 | 31 | 20 | 620 | 532,413 | 10,829,771 | Ghoul (494,058 / 9,492) | 0.8% | 8.0% | 5/7→3/5 |
| 4307 | Torment | 3-7 | Plains of Torment | 94 | 31 | 21 | 651 | 606,351 | 12,331,017 | Plague Rat (247,218 / 11,814) | 0.8% | 8.0% | 5/7→3/5 |
| 4308 | Torment | 3-8 | Citadel of Ruin | 94 | 31 | 21 | 651 | 722,023 | 14,286,398 | Kobold Guard (202,266 / 11,814) | 0.8% | 8.0% | 5/7→3/5 |
| 4309 | Torment | 3-9 | Core of the Abyss | 95 | 31 | 21 | 651 | 725,194 | 14,378,080 | Mummy (597,900 / 12,525) | 0.8% | 8.0% | 5/7→3/5 |
| 4310 | Torment | 3-10 | Hell Command Chamber | 95 | – | – | 1 | 19,830 | 783 | **액트 보스** Archon Morkar (1,360,608 / 24,558) | – | 액트보스 상자 930901 | – |

원본: https://taskbarhero.wiki/data/t/stages.json , https://taskbarhero.wiki/data/stages/{키}.json , https://taskbarhero.wiki/stages

### 2.4 진행 방식
- **자동 전투·자동 진행**: 영웅이 스스로 싸우며 웨이브를 넘긴다(스토어 설명 "Your adventure keeps going automatically"). **[확인]**
- **해금 순서**: `NextStageKey`가 1101 → … → 1110 → 1201 → … → 1310 → **2101**(Nightmare 1-1) → … → 4310(끝) 한 줄로 이어진다. 즉 **다음 난이도는 직전 난이도의 3-10(액트 보스) 클리어로 열린다.** 1.3.0 공지 "액트 보스에 처음 도전해 클리어하면 반복 모드가 켜져 있어도 다음 난이도로 넘어간다"와 일치. **[확인]**
- **반복 모드(repeat mode)**: 같은 스테이지를 계속 도는 토글이 있다(1.3.0 공지 문구, 할로윈 스테이지의 "클리어 후 자동 재시도"). 팬 가이드는 "Auto-Retry 토글"과 포털을 통한 클리어한 스테이지 재방문을 설명한다. **[확인: 존재]** / 토글의 정확한 동작(끄면 다음 스테이지로 자동 이동하는지)은 **[추정]** (https://taskbarhero.co/beginner-guide/)
- **포털 UI**: 스테이지·난이도·Plaguelands·이벤트 스테이지 선택 화면. **[확인]** (S 1.02.00, 1.3.0)
- **액트 보스 도전**: Soulstone 필요. 보스전 중 "탈출 포털"이 있어 중도 이탈 가능(1.3.0 버그 수정 문구). "Soulstone은 클리어에 성공했을 때만 소모되어 실패한 도전은 무료"라는 설명은 팬 사이트 한 곳뿐이다. **[추정]** (https://taskbarhero.co/stages/)
- **Soulstone 획득처**: ① 각 난이도 x-9 첫 클리어 보상(Normal은 `FirstClearDropKey` 9200220 → Stage Boss Box 6(#920022) → Soulstone - Normal 100%; 다른 난이도는 9200320/9200420/9200520로 같은 패턴) ② 스테이지 보스 상자·액트 보스 상자의 낮은 확률(예: Stage Boss Box 4에서 0.079%) ③ 큐브 Offering. **[확인: ①②는 W 데이터]**
- **첫 클리어 보상**: 1-1은 `FirstClearDropKey` 9200010 → Stage Boss Box 1·2·3(×4) = 시작 무기류(각 상자 100% 고정 1종). x-9는 Soulstone. 그 외 스테이지는 없음. **[확인]**
- **파티**: 영웅 6종(Knight, Ranger, Sorcerer, Priest[무료 DLC], Hunter·Slayer[유료 DLC]), 영웅 해금 비용 각 500골드. 편성 슬롯은 1칸에서 시작해 룬 "Rune of Command" 2개(1,000골드 / 150,000골드)로 +1씩, **최대 3인 파티**. 업적에 "2인 파티로 Torment 3-10", "3인 파티" 문구가 있다. **[확인]** (W `heroes`, `rune_levels`; Steam 업적)
- **사망·부활·실패**:
  - 공식 문구로 확인되는 것: 영웅에게 "정상 부활 시간(normal revival time)"이 있고(1.01.00: 파티 해산 후 재배치로 그보다 빨리 되살리던 문제 수정, 1.01.01: 죽은 파티원이 부활하지 않던 문제 수정), Priest에 Resurrection 스킬이 있으며, "전투 패배(battle defeat)" 상태가 존재한다(1.02.00). 사망 로그도 있다. **[확인]**
  - 일본어 공략(flex.shunshu-labo.org, 2026-10-29)은 뒷줄 영웅이 죽는 것을 "주회가 멈추는 사고"로 다루고, 대책으로 Priest의 Resurrection과 "불사조 성유물함의 공명 효과(파티원이 쓰러졌을 때 **스테이지마다 1회** 부활)"를 든다. 즉 **스테이지 진행 중에는 죽은 영웅이 저절로 되살아나지 않고, 부활은 스테이지 단위(다음 스테이지 시작 또는 재시작 시)로 일어나는 것**으로 읽힌다. **[추정]** (https://flex.shunshu-labo.org/task-bar-hero/2634/)
  - 한국어 가이드(games.gg, 검색 요약으로만 확인)는 "자동 재시도를 켜 두면 스테이지에서 실패해도 개입 없이 계속 재도전한다", "막히면 이전 스테이지로 물러나도 페널티가 없다"고 설명한다. 즉 **전멸 = 그 스테이지 실패 → (자동 재시도 시) 같은 스테이지 재도전, 재화·경험치 손실 페널티는 없음**으로 보인다. **[추정]**
  - 부활 대기 시간(초), 전멸 판정 직후의 정확한 흐름은 **[미확인]**.
- **시스템 해금**: 룬 트리와 큐브가 초반 스테이지 진행으로 열린다는 설명(팬 가이드: "스테이지 레벨 3에서 룬 트리, 레벨 4에서 큐브")이 있다. **[추정]** (https://taskbarhero.co/beginner-guide/)
- **스테이지 변경 제한**: 비정상적인 스테이지 변경이 감지되면 일정 시간 변경이 막힌다(1.00.17). 상자 타이머 악용 방지 목적의 서버 규칙. **[확인]**

### 2.5 지역 레벨과 영웅 레벨의 차이 페널티
- 공식 용어 "Region Level penalty"가 존재하며 EXP에 적용된다(1.3.0: "오프라인 보상 EXP에 지역 레벨 페널티가 적용되지 않던 문제 수정"). **[확인: 존재]**
- 곡선: taskbarherowiki.com이 "게임 코드에서 역산, 실측 1% 이내"라며 제시한 값(Lv30 영웅 예): 스테이지 레벨이 영웅보다 2 낮으면 100%, 4 낮으면 94%, 6 낮으면 78%, 8 낮으면 50%, 10 낮으면 23%, 12 낮으면 10%, 15 낮으면 3%. 영웅이 스테이지보다 낮을 때도 페널티가 있으나 "훨씬 완만"하다고만 적혀 있다. 식 자체는 공개되지 않았다. **[추정]** (https://taskbarherowiki.com/farm , 데이터 기준 v1.00.09)
- 같은 계열 사이트의 요약: "영웅 레벨이 지역 레벨보다 6 이상 높으면 EXP 감소". **[추정]** (https://taskbarhero.co/mechanics/)

### 2.6 Plaguelands(역병지대) — 1.02.00 추가 [확인: S + F]
- **입장**: 포털 UI에서 Nightmare/Hell/Torment 각각의 Plaguelands 선택. **해당 난이도 1-10 클리어**로 해금. 일반 지역에서 들어가려면 **Contamination(오염도) 30 이상** 필요.
- **Contamination**: Plaguelands에 머무는 동안 소모되고 0이 되면 일반 지역으로 강제 귀환. **온라인·오프라인 모두 시간에 따라 재충전**. 큐브의 Corrosion 레시피로 아이템을 넣어 얻거나(Alchemy와 같은 방식, 골드 대신 오염도), Plaguelands에서 낮은 확률로 나오는 Plague Fruit(등급 Rare~Beyond 5종)을 Corrosion에 넣어 얻는다. 큐브 레벨보다 21레벨 넘게 높은 아이템은 Corrosion·Alchemy에 쓸 수 없다. 체류 **시간**에 비례해 줄어든다(클리어 횟수가 아님). Corrosion 환산 예시(일본어 공략 실측, 1.2.x): Lv80 Rare 방어구 = 오염도 3, Lv80 Rare 아뮬렛 = 12, Lv80 Common 브레이서 = 6, Lv15 Rare 장신구 = 15, Lv5 Uncommon 장신구 = 6, Lv20 Uncommon / Rare 장신구 = 8 / 12 — 장신구가 방어구의 약 4배. **[추정: 단일 출처 실측]** (https://flex.shunshu-labo.org/task-bar-hero/2540/) **분당 소모량·시간당 충전량·최대치 수치는 찾지 못했다. [미확인]**
- **구조**: 난이도마다 **역병 강도(Plague Intensity) 1~20**이 각각 하나의 스테이지다(60개). 낮은 강도를 클리어해야 다음 강도 도전 가능(개발 노트: "하위 단계를 클리어하면 다음 단계 자격"). 스테이지 레벨은 강도와 무관하게 **Nightmare 40 / Hell 65 / Torment 90 고정**이고, 강도는 별도 배율로 몬스터를 강화한다.

역병 강도별 몬스터 강화(F `mechanics.plague`, 1.3.0. 원 수치는 ‰: 예 강도 1 = HP +1500‰):

| 역병 강도 | 몬스터 최대 HP | 공격력 | 이동 속도 |
|---:|---:|---:|---:|
| 1 | +150% (×2.5) | +5% | +60% |
| 2 | +300% (×4) | +10% | +70% |
| 3 | +500% (×6) | +15% | +80% |
| 4 | +750% (×8.5) | +20% | +90% |
| 5 | +1000% (×11) | +25% | +100% |
| 6 | +1500% (×16) | +40% | +118% |
| 7 | +2050% (×21.5) | +55% | +136% |
| 8 | +2600% (×27) | +70% | +154% |
| 9 | +3200% (×33) | +85% | +172% |
| 10 | +3800% (×39) | +100% | +190% |
| 11 | +5000% (×51) | +130% | +202% |
| 12 | +6300% (×64) | +160% | +214% |
| 13 | +7700% (×78) | +190% | +226% |
| 14 | +9200% (×93) | +220% | +238% |
| 15 | +10800% (×109) | +250% | +250% |
| 16 | +14400% (×145) | +300% | +258% |
| 17 | +18500% (×186) | +350% | +266% |
| 18 | +23500% (×236) | +400% | +274% |
| 19 | +30500% (×306) | +450% | +282% |
| 20 | +40500% (×406) | +500% | +290% |

  - 이 배율이 스테이지 레벨 배율에 **곱해지는지 더해지는지**는 F가 "+N%"로만 표기한다. 곱연산으로 보는 것이 자연스럽다. **[추정]**
  - 같은 사이트의 2026-09-12 공략 글도 인게임 표기로 "강도 6: 적 HP 1500%, 공격력 40% / 강도 11: HP 5000%, 공격력 130%"를 적어 표와 일치한다. 같은 글은 "강도 6은 속성 페널티가 없다", "스테이지 난이도가 오르면 속성 저항에 페널티가 붙는다"고 하여 **높은 역병 강도에는 난이도 페널티와 별개의 추가 저항 페널티**가 있음을 시사한다. 수치는 **[미확인]**. (https://flex.shunshu-labo.org/task-bar-hero/2550/)
- 강도별 웨이브 구성과 몬스터 풀(F 1.3.0):

| 강도 | NM(Lv40) 웨이브×수 | Hell(Lv65) 웨이브×수 | Torment(Lv90) 웨이브×수 | 스테이지 보스 | 몬스터 구성 (Torment 기준, 2010004는 Torment에만) |
|---:|---|---|---|---|---|
| 1 | 17×15 | 19×18 | 22×21 | Ratfolk Berserker | Slime, Goblin, Goblin Thief, Bat, Goblin Shaman |
| 2 | 17×15 | 19×18 | 22×21 | Ratfolk Warrior | Orc, Orc Warrior, Elite Orc, Skeleton, Skeleton Archer |
| 3 | 17×15 | 19×18 | 22×21 | Cobra | Skeleton Warrior, Scorpion, Ratfolk Warrior, Plague Rat, Burning Hell Priest |
| 4 | 17×15 | 19×18 | 22×21 | Venom Insect | Ratfolk Berserker, Cobra, Venom Insect, Venom Lord, Frozen Hell Priest |
| 5 | 17×15 | 19×18 | 22×21 | Homunculus | Giant Fly, Kobold Guard, Kobold Slinger, Homunculus, Electric Hell Priest, 2010001, 2010004 |
| 6 | 18×16 | 20×19 | 23×22 | Ghoul | Ghoul, Fire Elemental, Mummy, Tick, Goblin Shaman, 2010001, 2010004 |
| 7 | 18×16 | 20×19 | 23×22 | Plague Rat | Gremlin, Geonid, Fallen Angel's Helm, Yeti, Skeleton Archer, 2010001, 2010004 |
| 8 | 18×16 | 20×19 | 23×22 | Kobold Guard | Dragon Hatchling, Snow Mountain Warrior, Snow Mountain Archer, Snow Mountain Guard, Burning Hell Priest, 2010001, 2010003, 2010004 |
| 9 | 18×16 | 20×19 | 23×22 | Mummy | Snow Mountain Mage, Ghost, Lava Being, Blood Priest, Frozen Hell Priest, 2010001, 2010003, 2010004 |
| 10 | 18×16 | 20×19 | 23×22 | Ghoul | Demon Soldier, Demon Legion Commander, Demon Shocktrooper, Burning Piglet, Electric Hell Priest, 2010001, 2010003, 2010004 |
| 11 | 19×17 | 21×20 | 24×23 | Ratfolk Berserker | Hell Golem, Slime, Goblin, Goblin Thief, Goblin Shaman, 2010001, 2010002, 2010003, 2010004 |
| 12 | 19×17 | 21×20 | 24×23 | Ratfolk Warrior | Bat, Orc, Orc Warrior, Elite Orc, Skeleton Archer, Chaos Hell Priest, 2010001, 2010002, 2010003, 2010004 |
| 13 | 19×17 | 21×20 | 24×23 | Cobra | Skeleton, Skeleton Warrior, Scorpion, Ratfolk Warrior, Burning Hell Priest, 2010001, 2010002, 2010003, 2010004 |
| 14 | 19×17 | 21×20 | 24×23 | Venom Insect | Plague Rat, Ratfolk Berserker, Cobra, Venom Insect, Frozen Hell Priest, Chaos Hell Priest, 2010001, 2010002, 2010003, 2010004 |
| 15 | 19×17 | 21×20 | 24×23 | Homunculus | Venom Lord, Giant Fly, Kobold Guard, Kobold Slinger, Electric Hell Priest, 2010001, 2010002, 2010003, 2010004 |
| 16 | 20×18 | 22×21 | 25×24 | Ghoul | Homunculus, Ghoul, Fire Elemental, Mummy, Goblin Shaman, Chaos Hell Priest, 2010001, 2010002, 2010003, 2010004 |
| 17 | 20×18 | 22×21 | 25×24 | Plague Rat | Tick, Gremlin, Geonid, Fallen Angel's Helm, Skeleton Archer, 2010001, 2010002, 2010003, 2010004 |
| 18 | 20×18 | 22×21 | 25×24 | Kobold Guard | Yeti, Dragon Hatchling, Snow Mountain Warrior, Snow Mountain Archer, Burning Hell Priest, Chaos Hell Priest, 2010001, 2010002, 2010003, 2010004 |
| 19 | 20×18 | 22×21 | 25×24 | Mummy | Snow Mountain Guard, Snow Mountain Mage, Ghost, Lava Being, Frozen Hell Priest, 2010001, 2010002, 2010003, 2010004 |
| 20 | 20×18 | 22×21 | 25×24 | Ghoul | Blood Priest, Demon Soldier, Demon Legion Commander, Demon Shocktrooper, Electric Hell Priest, Chaos Hell Priest, 2010001, 2010002, 2010003, 2010004 |

  - 몬스터 키 2010001 ~ 2010004는 F의 몬스터 목록에 이름·능력치가 없다. 개발 노트의 "역병으로 변이한 몬스터(plague-mutated monsters)"에 해당하는 것으로 보인다. **[추정]** / 이름·능력치 **[미확인]**
  - 스테이지 보스 배율은 일반 지역 Nightmare 이상과 같다(공격 ×3, HP ×6, 골드 ×3, EXP ×6).
- **보상**: 상자가 일반 지역보다 덜 나오지만 일반 지역에 없는 초고등급(Celestial 이상)이 나오고 고등급 확률이 높다(공식). 상자 드롭률(F): 일반 상자 Nightmare 0.14% / Hell 0.10% / Torment 0.06%(처치당), 스테이지 보스 상자 4% / 3% / 2%. 쿨다운 일반 4분 / 보스 6분(1.3.0). Plaguelands 상자는 일반 지역 상자와 **별도 보관**이고 보관량·자동 열기는 전용 룬 노드로 얻는다.
- 스테이지 툴팁의 "일반 지역 대비 획득 확률"(F가 옮긴 인게임 표기, 대표 구간):

- **Nightmare Plaguelands - Plague Intensity 1** (`201201`): Equipment Drop Chance • Immortal: 200% Increased • Arcana: 400% Increased • Beyond: 400% Increased • Celestial: New • Divine: New • Cosmic: New Materials Drop Chance • Immortal: 399% Increased • Arcana: New • Beyond: New • Celestial: New Contaminated Item Drop Chance • Common+ Relic: New • Common+ Relic Box: New • Legendary Fruit: New
- **Nightmare Plaguelands - Plague Intensity 10** (`201210`): Equipment Drop Chance • Immortal: 320% Increased • Arcana: 625% Increased • Beyond: 625% Increased • Celestial: 407% Increased • Divine: 406% Increased • Cosmic: 405% Increased Materials Drop Chance • Immortal: 623% Increased • Arcana: 45% Increased • Beyond: 45% Increased • Celestial: 250% Increased • Divine: 101% Increased Contaminated Item Drop Chance • Soulstone: 114% Increased • Common+ Relic: 33.3% Increased • Common+ Relic Box: 47.4% Increased • Immortal Fruit: New
- **Nightmare Plaguelands - Plague Intensity 20** (`201220`): Equipment Drop Chance • Immortal: 443% Increased • Arcana: 875% Increased • Beyond: 875% Increased • Celestial: 1557% Increased • Divine: 1553% Increased • Cosmic: 17853% Increased Materials Drop Chance • Immortal: 873% Increased • Arcana: 95% Increased • Beyond: 95% Increased • Celestial: 749% Increased • Divine: 385% Increased • Cosmic: 1% Increased Contaminated Item Drop Chance • Soulstone: 400% Increased • Common+ Relic: 100% Increased • Common+ Relic Box: 100% Increased • Beyond Fruit: New
- **Hell Plaguelands - Plague Intensity 1** (`201301`): Equipment Drop Chance • Immortal: 166% Increased • Arcana: 400% Increased • Beyond: 400% Increased • Celestial: New • Divine: New • Cosmic: New Materials Drop Chance • Immortal: 306% Increased • Arcana: 306% Increased • Beyond: New • Celestial: New Contaminated Item Drop Chance • Uncommon+ Relic: New • Uncommon+ Relic Box: New • Legendary Fruit: New
- **Hell Plaguelands - Plague Intensity 20** (`201320`): Equipment Drop Chance • Immortal: 380% Increased • Arcana: 875% Increased • Beyond: 875% Increased • Celestial: 1558% Increased • Divine: 1557% Increased • Cosmic: 16288% Increased Materials Drop Chance • Immortal: 424% Increased • Arcana: 423% Increased • Beyond: 29% Increased • Celestial: 462% Increased • Divine: 325% Increased • Cosmic: 334% Increased Contaminated Item Drop Chance • Soulstone: 400% Increased • Uncommon+ Relic: 100% Increased • Uncommon+ Relic Box: 100% Increased • Beyond Fruit: New
- **Torment Plaguelands - Plague Intensity 1** (`201401`): Equipment Drop Chance • Immortal: 135% Increased • Arcana: 400% Increased • Beyond: 400% Increased • Celestial: New • Divine: New • Cosmic: New Materials Drop Chance • Immortal: 194% Increased • Arcana: 194% Increased • Beyond: New • Celestial: New Contaminated Item Drop Chance • Rare+ Relic: New • Rare+ Relic Box: New • Legendary Fruit: New
- **Torment Plaguelands - Plague Intensity 10** (`201410`): Equipment Drop Chance • Immortal: 229% Increased • Arcana: 625% Increased • Beyond: 625% Increased • Celestial: 408% Increased • Divine: 407% Increased • Cosmic: 507% Increased Materials Drop Chance • Immortal: 231% Increased • Arcana: 231% Increased • Beyond: 13% Increased • Celestial: 173% Increased • Divine: 110% Increased Contaminated Item Drop Chance • Soulstone: 114% Increased • Rare+ Relic: 33.3% Increased • Rare+ Relic Box: 47.4% Increased • Immortal Fruit: New
- **Torment Plaguelands - Plague Intensity 20** (`201420`): Equipment Drop Chance • Immortal: 327% Increased • Arcana: 875% Increased • Beyond: 875% Increased • Celestial: 1558% Increased • Divine: 1555% Increased • Cosmic: 21383% Increased Materials Drop Chance • Immortal: 257% Increased • Arcana: 258% Increased • Beyond: 22% Increased • Celestial: 431% Increased • Divine: 309% Increased • Cosmic: 312% Increased Contaminated Item Drop Chance • Soulstone: 400% Increased • Rare+ Relic: 100% Increased • Rare+ Relic Box: 100% Increased • Beyond Fruit: New

- **Contaminated Soulstone / 오염된 액트 보스**: 강도 6 이상에서 Contaminated Soulstone(난이도별 3종)을 얻어 오염된 액트 보스에 도전. 해당 스테이지는 그 액트의 보스를 Nightmare 이상에서 잡으면 열린다. 스테이지 9개(난이도 3 × 액트 3), 레벨은 원래 액트 보스와 같음(40/45/52, 60/69/77, 85/90/95). 기본 능력치는 §4.3 표의 109xx/209xx/309xx.
- 1.02.03에서 Plaguelands 상자 드롭 확률 룬 2종 추가, 1.3.0에서 드롭 확률 상향(Nightmare 일반 1.75배, Hell 일반 2.5배·보스 1.5배, Torment 일반 3배·보스 1.66배 — "이전 대비" 상대값) 및 업적 24개 추가.

### 2.7 이벤트 스테이지: Jack-o'-Lantern Canyon — 1.3.0, 기간 한정(~2026-11-11 23:59 UTC) [확인: S + F]
- Nightmare/Hell/Torment 3종. 해당 난이도 3-10 클리어 시 입장 가능, 입장마다 그 난이도의 Jack-o's Ticket 1장 소모(티켓은 이벤트 기간 중 일반·Plaguelands 상자에서 낮은 확률).
- 스테이지 레벨 39 / 59 / 84, 15웨이브 × 13 / 16 / 19마리. 입장 1회당 Halloween 상자 최대 10개 + 보스 처치 시 보스 상자 1개. 전용 보관함(일반 40 / 보스 40), 룬 효과 미적용. 티켓이 있으면 자동 재시도 설정 가능.
- 이벤트 펫 2종(전용 몬스터 500마리 처치로 획득).

### 2.8 예고됐으나 아직 없는 것 [확인: 공지상 계획]
- "던전 4종", "신규 난이도", "최대 레벨 상향", "신규 스킬"(2026-09-30 공지, 11월 목표). "시즌 1"(2026-08-19 개발 노트에 "9월 업데이트 이후 가능한 빨리"). 11-22 현재 미배포.

---

## 3. 난이도

### 3.1 단계와 명칭 [확인]
- **Normal / Nightmare / Hell / Torment** 4단계(데이터 열거형 `NORMAL, NIGHTMARE, HELL, TORMENT`). 한국어 현지화 명칭은 이 조사에서 확인하지 않았다. **[미확인]**
- 해금: 직전 난이도 3-10 클리어(§2.4).

### 3.2 난이도별 "배율"은 따로 없다 — 스테이지 레벨이 전부 [확인]
- 데이터에 난이도 전용 체력·공격력 배율 열은 없다. 난이도가 오르면 ① 스테이지 레벨이 이어서 올라가고(§4.2 배율표 적용) ② 웨이브·몬스터 수가 늘고 ③ 몬스터 구성에 상위 몬스터가 섞이고 ④ **속성 저항 페널티**가 붙는다.
- 같은 스테이지의 난이도별 배율표 값(§4.2에서 발췌):

| 스테이지 | Normal | Nightmare | Hell | Torment |
|---|---|---|---|---|
| 1-1 레벨 | 1 | 33 | 53 | 78 |
| 1-1 HP 배율(‰) | 100 | 32,970 | 103,970 | 248,970 |
| 1-1 공격 배율(‰) | 100 | 1,130 | 3,755 | 22,525 |
| 3-9 레벨 | 31 | 52 | 77 | 95 |
| 3-9 HP 배율(‰) | 28,070 | 99,470 | 241,970 | 383,270 |
| 3-9 공격 배율(‰) | 1,045 | 3,500 | 20,945 | 245,585 |
| 3-9 골드 배율(‰) | 3,500 | 10,850 | 25,350 | 39,660 |
| 3-9 EXP 배율(‰) | 59,400 | 206,400 | 496,400 | 782,600 |

- 검색으로 나온 팬 가이드의 "Nightmare 약 2.5배, Hell 약 5배, Torment 약 10배, 드롭률 +0/+50/+100/+200%"(tbhguides.pages.dev, 검색 요약으로만 확인)는 **위 데이터와 맞지 않는다.** 드롭률은 오히려 난이도가 오를수록 처치당 확률이 내려간다(§3.4). 신뢰하지 말 것. **[불일치 기록]**

### 3.3 난이도별 속성 저항 페널티 [확인]
| 난이도 | 영웅의 화염·냉기·번개·카오스 저항 보정 |
|---|---|
| Normal | 0 |
| Nightmare | −20 |
| Hell | −40 |
| Torment | −60 |

- 속성 저항의 기본 상한은 75%("Max … Resistance" 스탯으로 상향 가능)이고, "전체 속성 저항(All Elemental Resistance)"에는 **카오스 저항이 포함되지 않는다**(일본어 공략 https://flex.shunshu-labo.org/task-bar-hero/2550/ ; taskbarhero.wiki의 스탯 목록에 Max Fire/Cold/Lightning/Chaos Resistance가 따로 있음). **[확인]**
- 물리 피해는 방어도로 줄이므로 대상이 아니다. 저항 1 = 그 속성 피해 1% 감소, 음수면 피해 증가(1.01.00에서 "음수 저항이 0과 같이 처리되던 버그" 수정). 인게임 저항 툴팁에 "현재 페널티"가 표시된다.
- 출처: F `mechanics.resistPenalty` {NIGHTMARE:20, HELL:40, TORMENT:60}; taskbarhero.co/mechanics 의 디버프 목록(저항 +20%/+40%/+60% 3묶음 × 4속성); 공식 공지의 "Resistance penalty" 언급(1.01.00, 1.02.03).

### 3.4 난이도별 보상 규칙 [확인: W·F]
| 난이도 | 일반 상자 드롭률(처치당) | 스테이지 보스 상자 드롭률(보스 처치당) | 스테이지 보스 EXP 배율 | Soulstone 등급 |
|---|---|---|---|---|
| Normal | 16% (1-1~1-3) → 12% → 8% → 3% → 2.5% → 2% | 100% → 80% → 60% → 40% → 30% → 20% | ×3 ~ ×15 | Immortal |
| Nightmare | 1.5% | 15% | ×6 | Arcana |
| Hell | 1.0% | 10% | ×6 | Beyond |
| Torment | 0.8% | 8% | ×6 | Celestial |

- 처치 수가 늘어나므로 클리어당 기대 상자 수는 비슷하게 유지된다(예: Torment 3-9는 651마리 × 0.8% ≈ 5.2개/클리어 — 단, 쿨다운 상한 §5.4에 걸린다).
- 상자의 "레벨"(장비 레벨 구간)이 스테이지 레벨에 따라 올라간다(§5.4 표).
- 1.2.0 액트 보스 상자 개편(공식): Nightmare 액트 2 ~ Torment 액트 3 상자는 장비 42% / 장신구 28% / 재료 30%로 통일, Beyond 장비 확률 2배, Celestial은 Nightmare 액트 1부터, Divine은 Nightmare 액트 3부터, Cosmic은 Hell 액트 2부터 낮은 확률로 등장, Arcana 장신구는 Normal 액트 3 이상.

### 3.5 난이도별 특수 규칙
- Plaguelands, 오염된 액트 보스, 할로윈 스테이지는 Nightmare 이상에만 있다(§2.6~2.7). **[확인]**
- 액트 보스는 난이도가 오를수록 스킬 수가 늘어난다(§4.5). **[확인]**

---

## 4. 몬스터

### 4.1 능력치 공식 [확인: 표와 식의 형태] / [추정: HP·공격력의 절대 스케일]
몬스터 테이블의 열은 `MaxLife, AttackDamage, AttackSpeed, MovementSpeed, RewardGold, RewardExp`뿐이다. 스테이지에서의 실제 값은 **기본값 × 스테이지 레벨 배율**이다.

```
일반 몬스터:  값 = round( 기본값 × 배율[StageLevel] / 1000 )        (배율은 §4.2 표, ‰)
스테이지 보스: 값 = round( 기본값 × 배율[StageLevel] / 1000 ) × 보스배율 / 1000
액트 보스:    값 = round( 기본값 × 배율[StageLevel] / 1000 )        (보스배율 없음)
```
- 검산(W 표시값과 일치): Normal 1-1 Slime(기본 HP 50, ATK 10, 골드 10, EXP 10), 배율 100 → HP 5, ATK 1, 골드 1, EXP 1. Torment 3-9 Finger of Death(HP 65, ATK 25, 골드 30, EXP 30), 레벨 95 배율(HP 383,270 / 공격 245,585 / 골드 39,660 / EXP 782,600) → HP 24,913, ATK 6,140, 골드 1,190, EXP 23,478. 같은 스테이지 보스 Mummy(HP 260) → 99,650 × 6 = 597,900. Normal 1-10 Skeleton King(HP 1,050, 레벨 12 HP 배율 1,470) → 1,544.
- 반올림: W 표시값은 0.5를 짝수 쪽으로 보내는 반올림과 맞는다(4.5 → 4, 1.5 → 2). 게임 내부가 같은 방식인지는 확인하지 못했다. **[추정]**
- **출처 간 불일치(중요)**: HP의 절대 스케일이 사이트 계열에 따라 **10배** 다르다.
  - taskbarhero.wiki · probonk.com: 위 식(÷1000). Normal 1-1 총 HP 56, Slime HP 5.
  - taskbarherowiki.com · taskbarhero.co(v1.00.09 기준): HP만 ÷100으로 계산. Normal 1-1 총 HP 560, 1-9 총 HP 81K(W는 8.1K). **골드·EXP는 두 계열이 같다**(1-1 클리어당 14골드 / 16EXP).
  - F(1.3.0)는 기본값과 "스테이지 레벨 1을 ×1로 본 상대 배율"만 싣는다.
  - 판단: ÷1000 쪽이 내부적으로 일관되고(보스 배율·치명타 등 다른 ‰ 필드와 같은 단위, 골드·EXP와 같은 식), taskbarhero.wiki는 방어도 공식 등을 "디컴파일한 코드와 바이너리 상수로 검증"했다고 밝힌다. 또 ÷100이면 Torment 3-9 일반 몬스터의 한 방이 6만 대가 되어, 공식 패치 노트에 나오는 영웅 체력 규모("Max HP +1000", "+2000" 같은 고유 옵션)와 맞지 않는다. **이 문서는 ÷1000을 채택하되, 절대값은 [추정]으로 둔다.** 독립 구현에서는 상대 곡선(§4.2)만 정확히 따르면 절대 스케일은 자유롭게 정해도 균형이 유지된다.
- 몬스터에게 방어도·저항 수치는 테이블에 없다. 몬스터 쪽 저항·방어 규칙은 **[미확인]** (열이 없으므로 "없다"로 추정).
- 영웅이 받는 물리 피해의 방어도 공식에 스테이지 레벨이 들어간다: `감소율 = Armor² / (Armor² + (14×StageLevel + 12) × (Armor + 0.4×Damage))`, 상한 75%(근접 영웅 85%, 1.01.00). 상세는 전투 공식 담당 보고서 참조. **[확인: taskbarhero.wiki/mechanics, probonk game-math]**

### 4.2 스테이지 레벨 배율표 (W·F 완전 일치, 1.00.17 = 1.3.0) [확인]
단위 ‰(1000 = 기본값 그대로). 레벨 1은 100, 즉 기본값의 0.1배에서 시작한다. 일반 지역은 레벨 95까지, Plaguelands는 40/65/90만 쓴다. 96~170은 데이터에만 있고 현재 쓰는 스테이지가 없다(향후 난이도·던전용으로 보임, **[추정]**).

| StageLevel | Atk | HP | Gold | EXP |
|---:|---:|---:|---:|---:|
| 1 | 100 | 100 | 100 | 100 |
| 2 | 130 | 180 | 150 | 130 |
| 3 | 160 | 220 | 200 | 160 |
| 4 | 190 | 270 | 300 | 300 |
| 5 | 220 | 320 | 350 | 450 |
| 6 | 260 | 440 | 380 | 650 |
| 7 | 310 | 590 | 410 | 950 |
| 8 | 350 | 720 | 440 | 1350 |
| 9 | 380 | 820 | 470 | 1800 |
| 10 | 410 | 970 | 550 | 2300 |
| 11 | 440 | 1070 | 600 | 2900 |
| 12 | 470 | 1470 | 650 | 3700 |
| 13 | 500 | 1970 | 710 | 4700 |
| 14 | 530 | 2570 | 780 | 5900 |
| 15 | 560 | 3270 | 860 | 7300 |
| 16 | 590 | 4070 | 950 | 8900 |
| 17 | 620 | 4970 | 1050 | 10700 |
| 18 | 650 | 5970 | 1160 | 12700 |
| 19 | 680 | 7070 | 1280 | 15000 |
| 20 | 710 | 8270 | 1410 | 17600 |
| 21 | 740 | 9570 | 1550 | 20400 |
| 22 | 770 | 10970 | 1700 | 23400 |
| 23 | 800 | 12470 | 1860 | 26600 |
| 24 | 830 | 14070 | 2030 | 30000 |
| 25 | 860 | 15770 | 2210 | 33600 |
| 26 | 890 | 17570 | 2400 | 37400 |
| 27 | 920 | 19470 | 2600 | 41400 |
| 28 | 950 | 21470 | 2810 | 45600 |
| 29 | 980 | 23570 | 3030 | 50000 |
| 30 | 1010 | 25770 | 3260 | 54600 |
| 31 | 1045 | 28070 | 3500 | 59400 |
| 32 | 1085 | 30470 | 3750 | 64400 |
| 33 | 1130 | 32970 | 4010 | 69600 |
| 34 | 1180 | 35570 | 4280 | 75000 |
| 35 | 1235 | 38270 | 4560 | 80600 |
| 36 | 1295 | 41070 | 4850 | 86400 |
| 37 | 1360 | 43970 | 5150 | 92400 |
| 38 | 1430 | 46970 | 5460 | 98600 |
| 39 | 1510 | 50070 | 5780 | 105000 |
| 40 | 1600 | 53270 | 6110 | 111600 |
| 41 | 1700 | 56570 | 6450 | 118400 |
| 42 | 1810 | 59970 | 6800 | 125400 |
| 43 | 1930 | 63470 | 7160 | 132600 |
| 44 | 2060 | 67070 | 7530 | 140000 |
| 45 | 2200 | 70770 | 7910 | 147600 |
| 46 | 2350 | 74570 | 8300 | 155400 |
| 47 | 2510 | 78470 | 8700 | 163400 |
| 48 | 2680 | 82470 | 9110 | 171600 |
| 49 | 2855 | 86570 | 9530 | 180000 |
| 50 | 3050 | 90770 | 9960 | 188600 |
| 51 | 3265 | 95070 | 10400 | 197400 |
| 52 | 3500 | 99470 | 10850 | 206400 |
| 53 | 3755 | 103970 | 11310 | 215600 |
| 54 | 4030 | 108570 | 11780 | 225000 |
| 55 | 4325 | 113270 | 12260 | 234600 |
| 56 | 4640 | 118070 | 12750 | 244400 |
| 57 | 4975 | 122970 | 13250 | 254400 |
| 58 | 5330 | 127970 | 13760 | 264600 |
| 59 | 5705 | 133070 | 14280 | 275000 |
| 60 | 6085 | 138270 | 14810 | 285600 |
| 61 | 6515 | 143570 | 15350 | 296400 |
| 62 | 6995 | 148970 | 15900 | 307400 |
| 63 | 7525 | 154470 | 16460 | 318600 |
| 64 | 8105 | 160070 | 17030 | 330000 |
| 65 | 8735 | 165770 | 17610 | 341600 |
| 66 | 9415 | 171570 | 18200 | 353400 |
| 67 | 10145 | 177470 | 18800 | 365400 |
| 68 | 10925 | 183470 | 19410 | 377600 |
| 69 | 11755 | 189570 | 20030 | 390000 |
| 70 | 12635 | 195770 | 20660 | 402600 |
| 71 | 13565 | 202070 | 21300 | 415400 |
| 72 | 14545 | 208470 | 21950 | 428400 |
| 73 | 15625 | 214970 | 22610 | 441600 |
| 74 | 16805 | 221570 | 23280 | 455000 |
| 75 | 18085 | 228270 | 23960 | 468600 |
| 76 | 19465 | 235070 | 24650 | 482400 |
| 77 | 20945 | 241970 | 25350 | 496400 |
| 78 | 22525 | 248970 | 26060 | 510600 |
| 79 | 24205 | 256070 | 26780 | 525000 |
| 80 | 26385 | 263270 | 27510 | 539600 |
| 81 | 29065 | 270570 | 28250 | 554400 |
| 82 | 32245 | 277970 | 29000 | 569400 |
| 83 | 35925 | 285470 | 29760 | 584600 |
| 84 | 40105 | 293070 | 30530 | 600000 |
| 85 | 44785 | 300770 | 31310 | 615600 |
| 86 | 50465 | 308570 | 32100 | 631400 |
| 87 | 57145 | 316470 | 32900 | 647400 |
| 88 | 64825 | 324470 | 33710 | 663600 |
| 89 | 73505 | 332570 | 34530 | 680000 |
| 90 | 87185 | 340770 | 35360 | 696600 |
| 91 | 105865 | 349070 | 36200 | 713400 |
| 92 | 129545 | 357470 | 37050 | 730400 |
| 93 | 158225 | 365970 | 37910 | 747600 |
| 94 | 196905 | 374570 | 38780 | 765000 |
| 95 | 245585 | 383270 | 39660 | 782600 |
| 96 | 304265 | 392070 | 40550 | 800400 |
| 97 | 372945 | 400970 | 41450 | 818400 |
| 98 | 451625 | 409970 | 42360 | 836600 |
| 99 | 540305 | 419070 | 43280 | 855000 |
| 100 | 638985 | 428270 | 44210 | 873600 |
| 101 | 747665 | 437570 | 45150 | 892400 |
| 102 | 866345 | 446970 | 46100 | 911400 |
| 103 | 995025 | 456470 | 47060 | 930600 |
| 104 | 1133705 | 466070 | 48030 | 950000 |
| 105 | 1282385 | 475770 | 49010 | 969600 |
| 106 | 1441065 | 485570 | 50000 | 989400 |
| 107 | 1609745 | 495470 | 51000 | 1009400 |
| 108 | 1788425 | 505470 | 52010 | 1029600 |
| 109 | 1977105 | 515570 | 53030 | 1050000 |
| 110 | 2175785 | 525770 | 54060 | 1070600 |
| 111 | 2384465 | 536070 | 55100 | 1091400 |
| 112 | 2603145 | 546470 | 56150 | 1112400 |
| 113 | 2831825 | 556970 | 57210 | 1133600 |
| 114 | 3070505 | 567570 | 58280 | 1155000 |
| 115 | 3319185 | 578270 | 59360 | 1176600 |
| 116 | 3577865 | 589070 | 60450 | 1198400 |
| 117 | 3846545 | 599970 | 61550 | 1220400 |
| 118 | 4125225 | 610970 | 62660 | 1242600 |
| 119 | 4413905 | 622070 | 63780 | 1265000 |
| 120 | 4712585 | 633270 | 64910 | 1287600 |
| 121 | 5021265 | 644570 | 66050 | 1310400 |
| 122 | 5339945 | 655970 | 67200 | 1333400 |
| 123 | 5668625 | 667470 | 68360 | 1356600 |
| 124 | 6007305 | 679070 | 69530 | 1380000 |
| 125 | 6355985 | 690770 | 70710 | 1403600 |
| 126 | 6714665 | 702570 | 71900 | 1427400 |
| 127 | 7083345 | 714470 | 73100 | 1451400 |
| 128 | 7462025 | 726470 | 74310 | 1475600 |
| 129 | 7850705 | 738570 | 75530 | 1500000 |
| 130 | 8249385 | 750770 | 76760 | 1524600 |
| 131 | 8658065 | 763070 | 78000 | 1549400 |
| 132 | 9076745 | 775470 | 79250 | 1574400 |
| 133 | 9505425 | 787970 | 80510 | 1599600 |
| 134 | 9944105 | 800570 | 81780 | 1625000 |
| 135 | 10392785 | 813270 | 83060 | 1650600 |
| 136 | 10851465 | 826070 | 84350 | 1676400 |
| 137 | 11320145 | 838970 | 85650 | 1702400 |
| 138 | 11798825 | 851970 | 86960 | 1728600 |
| 139 | 12287505 | 865070 | 88280 | 1755000 |
| 140 | 12786185 | 878270 | 89610 | 1781600 |
| 141 | 13294865 | 891570 | 90950 | 1808400 |
| 142 | 13813545 | 904970 | 92300 | 1835400 |
| 143 | 14342225 | 918470 | 93660 | 1862600 |
| 144 | 14880905 | 932070 | 95030 | 1890000 |
| 145 | 15429585 | 945770 | 96410 | 1917600 |
| 146 | 15988265 | 959570 | 97800 | 1945400 |
| 147 | 16556945 | 973470 | 99200 | 1973400 |
| 148 | 17135625 | 987470 | 100610 | 2001600 |
| 149 | 17724305 | 1001570 | 102030 | 2030000 |
| 150 | 18322985 | 1015770 | 103460 | 2058600 |
| 151 | 18931665 | 1030070 | 104900 | 2087400 |
| 152 | 19550345 | 1044470 | 106350 | 2116400 |
| 153 | 20179025 | 1058970 | 107810 | 2145600 |
| 154 | 20817705 | 1073570 | 109280 | 2175000 |
| 155 | 21466385 | 1088270 | 110760 | 2204600 |
| 156 | 22125065 | 1103070 | 112250 | 2234400 |
| 157 | 22793745 | 1117970 | 113750 | 2264400 |
| 158 | 23472425 | 1132970 | 115260 | 2294600 |
| 159 | 24161105 | 1148070 | 116780 | 2325000 |
| 160 | 24859785 | 1163270 | 118310 | 2355600 |
| 161 | 25568465 | 1178570 | 119850 | 2386400 |
| 162 | 26287145 | 1193970 | 121400 | 2417400 |
| 163 | 27015825 | 1209470 | 122960 | 2448600 |
| 164 | 27754505 | 1225070 | 124530 | 2480000 |
| 165 | 28503185 | 1240770 | 126110 | 2511600 |
| 166 | 29261865 | 1256570 | 127700 | 2543400 |
| 167 | 30030545 | 1272470 | 129300 | 2575400 |
| 168 | 30809225 | 1288470 | 130910 | 2607600 |
| 169 | 31597905 | 1304570 | 132530 | 2640000 |
| 170 | 32396585 | 1320770 | 134160 | 2672600 |

- 곡선의 성격: HP 배율은 레벨 12부터 증분이 매 레벨 100씩 커지는 **2차 곡선**(11→12: +400, 12→13: +500, … 94→95: +8,700). 골드 배율은 증분이 10씩 커지는 완만한 2차 곡선. EXP 배율은 증분이 200씩 커지는 2차 곡선(레벨 12 이후). **공격 배율만 레벨 80 전후부터 급격히 꺾여 오른다**(79→80: +2,180, 89→90: +13,680, 94→95: +48,680, 이후 매 레벨 증분이 약 10,000씩 커짐).
- 원본: https://taskbarhero.wiki/data/t/stage_levels.json (170행), F `mechanics.stageLevel`

### 4.3 몬스터 목록과 기본 능력치 (F 1.3.0, 73종. "1.00.17 때 ATK" 열은 W와 다른 것만 표기)
- 공속·이속은 100 = 1.0 표기(예: 공속 40 = 초당 0.4회, taskbarhero.co 표기와 일치). 속성은 F의 Element 필드(없으면 물리).
- 공격력이 바뀐 이력은 공식 공지와 맞는다: 1.01.00 원거리 물리 −25%(Skeleton Archer 20→15, Kobold Slinger 23→17, Snow Mountain Archer 20→15 등), 원거리 속성 −40%(Goblin Shaman 18→11), 1.2.0 속성 몬스터 추가 하향(Fire Elemental −27%, Dragon Hatchling −11%, Lava Being −15%, Hell Golem −33%, Burning/Frozen/Electric Hell Priest −17% 및 공속 −20%, Snow Mountain Mage −7%, Venom Insect −35%, Chaos Hell Priest −39% 및 공속 −20%).

| ID | 이름 | 기본 HP | 기본 ATK (1.3.0) | 1.00.17 때 ATK | 공속 | 이속 | 골드 | EXP | 속성 | 공격 패턴(1.00.17 데이터: 발동방식/속성/사거리/계수‰) |
|---|---|---:|---:|---:|---:|---:|---:|---:|---|---|
| 10011 | Slime | 50 | 10 | = | 40 | 110 | 10 | 10 | Physical(표기 없음) | BASEATTACK/Physical/200/1000 |
| 10021 | Goblin | 35 | 15 | = | 50 | 170 | 12 | 12 | Physical(표기 없음) | BASEATTACK/Physical/130/1000 |
| 10022 | Goblin Thief | 45 | 10 | = | 110 | 280 | 15 | 15 | Physical(표기 없음) | BASEATTACK/Physical/170/1000 |
| 10023 | Goblin Shaman | 30 | 11 | 18 | 70 | 135 | 20 | 20 | Fire | BASEATTACK/Fire/800/1000 |
| 10031 | Bat | 15 | 10 | = | 90 | 500 | 10 | 5 | Physical(표기 없음) | BASEATTACK/Physical/200/1000 |
| 10041 | Orc | 65 | 14 | = | 80 | 185 | 15 | 15 | Physical(표기 없음) | BASEATTACK/Physical/150/1000 |
| 10042 | Orc Warrior | 95 | 16 | = | 75 | 165 | 20 | 20 | Physical(표기 없음) | BASEATTACK/Physical/170/1000 |
| 10043 | Elite Orc | 185 | 17 | = | 65 | 120 | 35 | 35 | Physical(표기 없음) | BASEATTACK/Physical/250/1000 |
| 10051 | Skeleton | 50 | 20 | = | 80 | 220 | 10 | 11 | Physical(표기 없음) | BASEATTACK/Physical/150/1000 |
| 10052 | Skeleton Archer | 35 | 15 | 20 | 80 | 150 | 10 | 13 | Physical(표기 없음) | BASEATTACK/Physical/900/1000 |
| 10053 | Skeleton Warrior | 90 | 20 | = | 80 | 160 | 30 | 30 | Physical(표기 없음) | BASEATTACK/Physical/300/1000 |
| 10901 | Skeleton King | 1050 | 50 | = | 115 | 110 | 500 | 36 | Physical(표기 없음) | BASEATTACK/Physical/300/1000; BASEATTACK_COUNT/Physical/450/1500 |
| 20011 | Scorpion | 50 | 10 | = | 40 | 110 | 10 | 10 | Physical(표기 없음) | – |
| 20021 | Ratfolk Warrior | 35 | 15 | = | 50 | 230 | 12 | 12 | Physical(표기 없음) | – |
| 20022 | Ratfolk Archer | 45 | 8 | 10 | 110 | 280 | 15 | 15 | Physical(표기 없음) | – |
| 20023 | Plague Rat | 110 | 20 | = | 70 | 130 | 20 | 20 | Physical(표기 없음) | – |
| 20024 | Ratfolk Berserker | 75 | 17 | = | 150 | 500 | 25 | 25 | Physical(표기 없음) | – |
| 20031 | Cobra | 55 | 18 | = | 115 | 165 | 15 | 15 | Physical(표기 없음) | – |
| 20041 | Venom Insect | 45 | 15 | 23 | 130 | 320 | 15 | 15 | Chaos | – |
| 20042 | Venom Lord | 75 | 9 | 15 | 55 | 220 | 35 | 35 | Chaos | – |
| 20051 | Giant Fly | 45 | 20 | = | 120 | 440 | 11 | 11 | Physical(표기 없음) | – |
| 20061 | Kobold Guard | 90 | 20 | = | 80 | 250 | 17 | 17 | Physical(표기 없음) | – |
| 20062 | Kobold Slinger | 80 | 17 | 23 | 110 | 180 | 14 | 14 | Physical(표기 없음) | – |
| 20071 | Homunculus | 115 | 16 | = | 80 | 340 | 13 | 13 | Physical(표기 없음) | – |
| 20081 | Ghoul | 225 | 20 | = | 60 | 110 | 45 | 45 | Physical(표기 없음) | – |
| 20091 | Fire Elemental | 75 | 11 | 25 | 80 | 160 | 23 | 23 | Fire | – |
| 20111 | Mummy | 260 | 17 | = | 80 | 80 | 30 | 30 | Physical(표기 없음) | – |
| 20121 | Tick | 55 | 10 | = | 140 | 400 | 7 | 7 | Physical(표기 없음) | BASEATTACK/Physical/130/1000 |
| 20901 | Desert Overlord | 1850 | 80 | = | 170 | 120 | 500 | 12 | Physical(표기 없음) | BASEATTACK/Physical/230/1000; COOLDOWN/Physical/250/1800 |
| 30011 | Gremlin | 70 | 10 | = | 60 | 300 | 10 | 10 | Physical(표기 없음) | – |
| 30012 | Geonid | 50 | 15 | = | 90 | 300 | 12 | 12 | Physical(표기 없음) | – |
| 30013 | Fallen Angel's Helm | 40 | 25 | = | 110 | 450 | 15 | 15 | Physical(표기 없음) | – |
| 30021 | Yeti | 320 | 12 | = | 70 | 105 | 20 | 20 | Physical(표기 없음) | – |
| 30031 | Dragon Hatchling | 175 | 16 | 30 | 70 | 195 | 10 | 5 | Fire | – |
| 30041 | Snow Mountain Warrior | 90 | 15 | = | 70 | 330 | 10 | 5 | Physical(표기 없음) | – |
| 30042 | Snow Mountain Archer | 70 | 15 | 20 | 130 | 260 | 10 | 5 | Physical(표기 없음) | – |
| 30043 | Snow Mountain Guard | 155 | 15 | = | 90 | 240 | 10 | 5 | Physical(표기 없음) | – |
| 30044 | Snow Mountain Mage | 55 | 14 | 25 | 100 | 220 | 10 | 5 | Cold | – |
| 30051 | Ghost | 65 | 10 | = | 180 | 570 | 15 | 15 | Physical(표기 없음) | – |
| 30061 | Lava Being | 75 | 17 | 20 | 75 | 330 | 20 | 20 | Fire | – |
| 30071 | Blood Priest | 125 | 10 | 16 | 65 | 180 | 35 | 35 | Chaos | – |
| 30081 | Demon Soldier | 70 | 20 | = | 80 | 260 | 10 | 11 | Physical(표기 없음) | – |
| 30082 | Demon Legion Commander | 45 | 12 | 20 | 80 | 190 | 10 | 13 | Fire | – |
| 30083 | Demon Shocktrooper | 90 | 20 | = | 80 | 280 | 30 | 30 | Physical(표기 없음) | – |
| 30084 | Burning Piglet | 110 | 30 | = | 80 | 470 | 30 | 30 | Physical(표기 없음) | – |
| 30091 | Hell Golem | 185 | 27 | 40 | 60 | 160 | 30 | 30 | Fire | – |
| 30101 | Burning Hell Priest | 95 | 15 | 30 | 80 (구 100) | 230 | 30 | 30 | Fire | BASEATTACK/Fire/800/1000 |
| 30102 | Frozen Hell Priest | 95 | 15 | 30 | 80 (구 100) | 230 | 30 | 30 | Cold | BASEATTACK/Cold/800/1000 |
| 30103 | Electric Hell Priest | 95 | 15 | 30 | 80 (구 100) | 230 | 30 | 30 | Lightning | BASEATTACK/Lightning/800/1000 |
| 30104 | Chaos Hell Priest | 75 | 11 | 30 | 80 (구 100) | 230 | 30 | 30 | Chaos | BASEATTACK/Chaos/800/1000 |
| 30111 | Finger of Death | 65 | 25 | = | 160 | 430 | 30 | 30 | Physical(표기 없음) | – |
| 30901 | Archon Morkar | 2550 | 70 | = | 130 | 120 | 500 | 1 | Chaos | BASEATTACK/Chaos/700/1000; COOLDOWN/Chaos/700/800 |
| 10902 | Skeleton King | 2350 | 70 | = | 130 | 120 | 500 | 12 | Physical(표기 없음) | BASEATTACK/Physical/300/1000; BASEATTACK_COUNT/Physical/450/1500; COOLDOWN/Physical/700/1500 |
| 10903 | Skeleton King | 2350 | 70 | = | 130 | 120 | 500 | 18 | Physical(표기 없음) | BASEATTACK/Physical/300/1000; BASEATTACK_COUNT/Physical/450/1500; COOLDOWN/Physical/700/1500; COOLDOWN/Physical/300/1500 |
| 10904 | Skeleton King | 2350 | 70 | = | 130 | 120 | 500 | 15 | Physical(표기 없음) | BASEATTACK/Physical/300/1000; BASEATTACK_COUNT/Physical/450/1500; COOLDOWN/Physical/700/1500; COOLDOWN/Physical/300/1500; COOLDOWN/Physical/700/1500 |
| 20902 | Desert Overlord | 1950 | 100 | = | 170 | 120 | 500 | 14 | Physical(표기 없음) | BASEATTACK/Physical/230/1000; COOLDOWN/Physical/250/1800; BASEATTACK_COUNT/Physical/600/1350 |
| 20903 | Desert Overlord | 2050 | 120 | = | 170 | 120 | 500 | 31 | Physical(표기 없음) | BASEATTACK/Physical/230/1000; COOLDOWN/Physical/250/1800; BASEATTACK_COUNT/Physical/600/1350; COOLDOWN/Physical/270/2300 |
| 20904 | Desert Overlord | 2350 | 140 | = | 170 | 120 | 500 | 31 | Physical(표기 없음) | BASEATTACK/Physical/230/1000; COOLDOWN/Physical/250/1800; BASEATTACK_COUNT/Physical/600/1350; COOLDOWN/Physical/270/2300; COOLDOWN/Physical/600/2000 |
| 30902 | Archon Morkar | 2750 | 80 | = | 150 | 120 | 500 | 1 | Chaos | BASEATTACK/Chaos/700/1000; COOLDOWN/Chaos/700/800; COOLDOWN/Physical/800/1500 |
| 30903 | Archon Morkar | 3050 | 90 | = | 150 | 120 | 500 | 1 | Chaos | BASEATTACK/Chaos/700/1000; COOLDOWN/Chaos/700/800; COOLDOWN/Physical/800/1500; COOLDOWN/Chaos/700/1700 |
| 30904 | Archon Morkar | 3550 | 100 | = | 150 | 120 | 500 | 1 | Chaos | BASEATTACK/Chaos/700/1000; COOLDOWN/Chaos/700/800; COOLDOWN/Physical/800/1500; COOLDOWN/Chaos/700/1700; COOLDOWN/Chaos/600/2300 |
| 10912 | Contaminated Skeleton King | 916500 | 203 | 신규 | 130 | 120 | 500 | 14 | Physical(표기 없음) | – |
| 10913 | Contaminated Skeleton King | 916500 | 203 | 신규 | 130 | 120 | 500 | 46 | Physical(표기 없음) | – |
| 10914 | Contaminated Skeleton King | 916500 | 203 | 신규 | 130 | 120 | 500 | 24 | Physical(표기 없음) | – |
| 20912 | Contaminated Desert Overlord | 760500 | 290 | 신규 | 170 | 120 | 500 | 31 | Physical(표기 없음) | – |
| 20913 | Contaminated Desert Overlord | 799500 | 348 | 신규 | 170 | 120 | 500 | 31 | Physical(표기 없음) | – |
| 20914 | Contaminated Desert Overlord | 916500 | 406 | 신규 | 170 | 120 | 500 | 31 | Physical(표기 없음) | – |
| 30912 | Contaminated Archon Morkar | 1072500 | 232 | 신규 | 150 | 120 | 500 | 1 | Chaos | – |
| 30913 | Contaminated Archon Morkar | 1189500 | 261 | 신규 | 150 | 120 | 500 | 1 | Chaos | – |
| 30914 | Contaminated Archon Morkar | 1384500 | 290 | 신규 | 150 | 120 | 500 | 1 | Chaos | – |
| 5000101 | Jack-o' Skeleton | 50 | 20 | 신규 | 80 | 220 | 10 | 11 | Physical(표기 없음) | – |
| 5000102 | Jack-o' Skeleton Warrior | 90 | 20 | 신규 | 80 | 160 | 30 | 30 | Physical(표기 없음) | – |
| 5000103 | Jack-o'-Lantern Ghost | 65 | 10 | 신규 | 180 | 570 | 15 | 15 | Physical(표기 없음) | – |

- 원본: F https://flex.shunshu-labo.org/tbh/ (데이터 `…/tbh/data/tbh-data.json`), W https://taskbarhero.wiki/data/t/monsters.json
- 액트 2·3 일반 몬스터의 공격 패턴은 W에서 추출되지 않아 비어 있다.

### 4.4 종류 [확인]
- 데이터상 `MONSTERTYPE`은 전부 `MONSTER` 한 가지다. "정예(elite)" 등급은 없다(이름이 Elite Orc인 몬스터는 그냥 한 종). 구분은 스테이지 쪽에서 생긴다.
  - **일반 몬스터**: 웨이브를 채우는 개체.
  - **스테이지 보스**: 일반 종 + 배율(공격 ×2~3, HP ×3~6, 골드 ×2~3, EXP ×3~15) + 크기 3배.
  - **액트 보스**: 전용 3종 × 난이도 4단계(키 10901~10904, 20901~20904, 30901~30904). 기본 골드 500 고정, EXP는 매우 낮음(1~36).
  - **오염된 액트 보스**(1.2.0): 전용 9종, 기본 HP 76만~138만(일반 액트 보스의 약 390배), 기본 ATK 203~406.
  - **역병 변이 몬스터**(1.2.0): 키 2010001~2010004. 상세 **[미확인]**.
  - **이벤트 몬스터**(1.3.0 할로윈): 키 5000101~5000103.

스테이지 보스 배율 분포(W `stages`, 일반 스테이지 108개):

| 난이도 | 공격 | HP | 골드 | EXP | 해당 스테이지 수 |
|---|---:|---:|---:|---:|---:|
| Normal | ×2.0 | ×3.0 | ×2.0 | ×3.0 | 1 |
| Normal | ×2.5 | ×6.0 | ×3.0 | ×4.0 | 1 |
| Normal | ×2.5 | ×6.0 | ×3.0 | ×6.0 | 1 |
| Normal | ×2.5 | ×5.0 | ×3.0 | ×8.0 | 1 |
| Normal | ×3.0 | ×5.0 | ×3.0 | ×10.0 | 1 |
| Normal | ×3.0 | ×6.0 | ×3.0 | ×12.0 | 1 |
| Normal | ×3.0 | ×6.0 | ×3.0 | ×15.0 | 21 |
| Nightmare | ×3.0 | ×6.0 | ×3.0 | ×6.0 | 27 |
| Hell | ×3.0 | ×6.0 | ×3.0 | ×6.0 | 27 |
| Torment | ×3.0 | ×6.0 | ×3.0 | ×6.0 | 27 |

### 4.5 보스 패턴·특수 능력 [확인: 데이터 수준] / 세부 수치 [미확인]
- 액트 보스의 공격은 "발동 방식 / 속성 / 사거리 / 계수(‰)" 목록으로 정의된다(§4.3 표 마지막 열). 발동 방식은 `BASEATTACK`(기본 공격), `BASEATTACK_COUNT`(기본 공격 N회마다), `COOLDOWN`(쿨다운마다) 세 가지. **난이도가 오를 때마다 스킬이 하나씩 늘어난다**: Skeleton King 2개(Normal) → 3 → 4 → 5개(Torment), Desert Overlord 2 → 3 → 4 → 5, Archon Morkar 2 → 3 → 4 → 5.
- 디컴파일된 전투 클래스 이름으로 본 액트 보스 능력 13종(taskbarhero.wiki/mechanics): Bone Fall, Curved Projectile Base Attack, Dash Attack, Howling, Jump Attack, Massive Void Call, Monster Stab, Set Damage Reduction Mode, Soul Snatch, Spawn Undead, Spawn Void Turret, Void Thunder, Void Wave. 공식 공지에서 확인되는 것: 2-10 보스의 Soul Snatch(영웅의 영혼을 뽑아 연결하는 연출)와 점프 스킬, 3-10 보스 스킬 일부. 각 능력의 쿨다운·필요 타수·범위 수치는 **[미확인]**.
- 일반 몬스터 특수 효과: Fire Elemental·Demon Legion Commander는 광역 피해(플레이테스트 0.01.05 공지), Hell Priest 4종은 각각 화염·냉기·번개·카오스 원거리 공격.
- Plaguelands에서는 강도에 따라 몬스터 이동 속도도 오른다(§2.6).

### 4.6 속성과 상태 이상
- 피해 속성: Physical, Fire, Cold, Lightning, Chaos (+ 전체 속성 표기용 All Element). **[확인]**
- 속성 공격을 하는 몬스터(F): Fire — Goblin Shaman, Fire Elemental, Dragon Hatchling, Lava Being, Demon Legion Commander, Hell Golem, Burning Hell Priest / Cold — Snow Mountain Mage, Frozen Hell Priest / Lightning — Electric Hell Priest / Chaos — Venom Insect, Venom Lord, Blood Priest, Chaos Hell Priest, Archon Morkar(카오스+물리).
- 적에게 거는 상태 이상 6종(F `mechanics.statusEffects`, taskbarhero.co 일치): Chill 4.0초(공속·이속 −30%), Freeze 1.5초(행동 불가), Ignite 4.0초, Shock 6.0초, Bleed 7.0초, Stun 2.0초. 상세는 전투 담당 보고서. **[확인]**

---

## 5. 보상

### 5.1 처치·클리어 보상 공식
- 처치당 골드·EXP = §4.1 식(기본 `RewardGold`/`RewardExp` × 골드/EXP 배율 ÷ 1000). 스테이지 보스는 여기에 골드 ×2~3, EXP ×3~15. 액트 보스는 기본 골드 500 × 골드 배율(예: Normal 1-10 325골드, Torment 3-10 19,830골드), EXP는 미미. **[확인: W 계산값, 골드·EXP 스케일은 taskbarherowiki.com 계열과도 일치]**
- 클리어당 기대값 = Σ(웨이브 수 × 웨이브당 수 × 출현 확률 × 그 몬스터 보상) + 보스 보상. §2.3 표의 "골드/클리어", "EXP/클리어" 열(룬·펫·장비 보너스 제외).
- "클리어 보너스"(스테이지를 끝냈다는 이유로 주는 별도 골드·EXP)는 데이터에 없다. 보상은 전부 처치에서 나온다. **[추정: 필드 부재]**
- 보너스 스탯(룬 `rune_levels`의 STATTYPE, W 1.00.17 합계): `IncreaseGoldAmount` 합 1,900‰(+190%), `IncreaseExpAmount` 1,900‰, `AdditionalGold`(처치당 고정 추가) 합 6, `AdditionalGoldNormalMonster` 합 12, `AdditionalGoldStageBoss` 합 43,180, `AdditionalGoldActBoss` 합 262,500, EXP도 같은 구조. 1.3.0에서 액트 보스 EXP 룬 2개 추가, 기존 1개는 레벨당 +2,000 → +10,000. 적용 순서(고정 추가 후 % 증가인지)는 **[미확인]**.
- 펫 보너스(보유만 하면 항상 적용): 골드 +10~15%, EXP +15~20%, 상자 드롭 확률 +10~20% 등(W `pet_stats`). 펫 세부는 다른 조사자 담당.

### 5.2 파티 분배 [미확인]
- 골드는 계정 공용 재화다(재화 테이블에 Gold 한 종). **[확인]**
- EXP를 파티원이 **각자 전액** 받는지 **나눠** 받는지 명시한 자료를 찾지 못했다. 정황: 영웅마다 레벨이 따로 있고(업적 "영웅 4명을 Lv50 이상"), 팬 가이드에 "약한 영웅을 캐리 뒤에 넣어 보스 파밍 중 파워레벨링" 조언이 있어 **파티에 있기만 하면 EXP를 받는다**는 점은 유력하다. 분배 비율은 **[미확인]**.
- 지역 레벨 페널티는 영웅 개별 레벨 기준으로 적용되는 것으로 보인다(§2.5). **[추정]**

### 5.3 레벨업 경험치 표 (W·F 일치) [확인]
형식 `레벨:다음 레벨까지 필요 EXP`. 표는 1~100.

```
1:30 2:150 3:500 4:1,000 5:2,600 6:6,500 7:13,000 8:23,400 9:37,440 10:74,880 11:134,784 12:229,133 13:366,613 14:513,258 15:718,561 16:970,057 17:1,309,577 18:1,702,450 19:2,042,940 20:3,064,410 21:3,615,531 22:4,157,861 23:4,739,962 24:5,356,157 25:6,266,704 26:7,708,046 27:9,866,299 28:12,135,548 29:14,198,591 30:15,618,450 31:17,180,295 32:18,709,341 33:20,170,728 34:21,528,801 35:22,748,528 36:23,796,986 37:24,644,829 38:25,267,650 39:25,647,149 40:25,772,024 41:25,638,532 42:25,250,674 43:24,619,997 44:28,490,088 45:32,968,530 46:38,150,952 47:44,148,014 48:51,653,176 49:63,533,406 50:81,322,760 51:100,026,995 52:117,031,584 53:125,223,795 54:133,989,461 55:143,368,723 56:153,404,534 57:164,142,851 58:175,632,851 59:187,927,151 60:201,082,052 61:215,157,796 62:230,218,842 63:241,729,784 64:253,816,273 65:266,507,087 66:279,832,441 67:293,824,063 68:308,515,266 69:323,941,029 70:340,138,080 71:357,144,984 72:375,002,233 73:393,752,345 74:413,439,962 75:434,111,960 76:455,817,558 77:478,608,436 78:559,971,870 79:688,765,400 80:881,619,712 81:1,084,392,246 82:1,268,738,928 83:1,306,801,096 84:1,346,005,129 85:1,386,385,283 86:1,427,976,841 87:1,470,816,146 88:1,514,940,630 89:1,560,388,849 90:1,607,200,514 91:1,655,416,529 92:1,705,079,025 93:1,739,180,606 94:1,773,964,218 95:1,809,443,502 96:1,845,632,372 97:1,882,545,019 98:1,920,195,919 99:1,958,599,837 100:1,997,771,834
```
- 레벨 40~43 구간은 필요량이 오히려 줄어든다(40: 25,772,024 → 43: 24,619,997). 원본 그대로다.
- **현재 최대 레벨은 101**이다: 표가 100 → 101까지 있고, 공식 공지에 "Lv101 도달 후 오프라인 보상 EXP 표시 오류"(1.00.26)가 있으며, 일본어 공략이 "캐릭터를 최대(lv101)까지"라고 쓴다(https://flex.shunshu-labo.org/task-bar-hero/2550/ 내 인용). 업적은 Lv80까지만 있다. **[확인]** "최대 레벨 상향"(11월 예정)의 폭은 **[미확인]**.

### 5.4 보물상자 규칙

**종류(인게임 명칭 ↔ 데이터 명칭)** [확인]
| 인게임 | 데이터 | 등급색 | 획득 |
|---|---|---|---|
| Common Treasure Chest (일반 상자) | Normal Monster Box (#910xxx) | Common | 일반 몬스터 처치 시 확률 |
| Stage Treasure Chest (스테이지 보스 상자) | Stage Boss Box (#920xxx) | Rare | 스테이지 보스 처치 시 확률 |
| Act Boss Treasure Chest | Act Boss Box (#930xxx) | Legendary | 액트 보스 클리어 |
| Plague Normal / Stage Boss / Act Boss Chest | #915xxx / #925xxx / #935xxx | – | Plaguelands, 오염된 액트 보스 (별도 보관) |
| Halloween Chest / Boss Chest | #940001 / #941001 | – | 이벤트 스테이지 (별도 보관, 각 40개) |

**열었을 때**: 상자 하나는 **가중치 표에서 보상 1개**를 뽑는다(`EachDropOneWeight`). 항목은 "아이템 그룹(예: Common Sword Lv1 4종 중 무작위 1개)" 또는 단일 아이템. `_DLCVariant` 표는 Hunter·Slayer DLC 보유 여부에 따라 4가지 가중치 세트(기본 / Hunter / Slayer / 둘 다)가 있다(Priest 장비는 기본 풀에 포함). **[확인]** (W `/data/boxes/*.json`, taskbarherowiki.com/chests)

**드롭 판정** [확인]
- 일반 몬스터 처치마다 `MonsterDropItemRate`(‰, 160 = 16%) 확률, 스테이지 보스 처치 시 `BossDropItemRate`. 룬 `DropChanceNormalChestPercent` / `DropChanceStageBossChestPercent`가 이 확률을 % 증가시키고(F의 계산기는 `확률 × (1 + 보너스%)`), 펫도 같은 스탯을 준다.
- **서버가 강제하는 쿨다운(분 단위)**: 상자 종류(레벨 구간)마다 `DropCooldown`이 있고 "버킷형(isBucketBox)" 표시가 붙어 있다. F의 드롭 시뮬레이터는 이를 **하루 획득 상한 = 86,400초 ÷ (쿨다운×60초)** 로 모델링한다: `기대 상자 수 = min(주회 수 × 처치 수 × 확률, 86,400 / 쿨다운초)`. 1.2.4 공식 공지 "획득 후 무조건 대기를 없애고 **'일정 기간에 얻을 수 있는 상자 총량'** 방식만 남긴다(오래 플레이하면 운에 따라 연속 획득도 가능)"와 맞는다. 즉 **토큰 버킷**: 쿨다운 1회분마다 토큰 1개가 차고, 드롭 판정에 성공해도 토큰이 없으면 상자가 나오지 않는다. 버킷 용량(토큰을 몇 개까지 쌓는지)은 **[미확인]**.
- 쿨다운 이력:

| 구간 | 1.00.17 (W) | 1.3.0 (F) | 공식 공지 |
|---|---|---|---|
| 일반 상자, Normal 1-1 ~ 2-2 (Box 1~3) | 3분 | 2분 | 1.00.24 "전 스테이지 소폭 단축" |
| 일반 상자, 지역 Lv15 이상 | 5분 | **3분** | 1.3.0 "4분 → 3분" (중간에 4분이던 시기 있음) |
| 스테이지 보스 상자, 1-1 ~ 1-7 (Box 4, 5) | 3분 | 2분(1-1~1-3) / 3분(1-4~1-7) | – |
| 스테이지 보스 상자, 1-8 ~ 2-2 (Box 7) | 5분 | 4분 | – |
| 스테이지 보스 상자, 지역 Lv15 이상 | 7분 | **5분** | 1.3.0 "6분 → 5분" |
| Plaguelands 일반 상자 | – | 4분 | 출시 시 5분 → 1.02.03 Nightmare 4분 → 1.3.0 Hell/Torment 4분 |
| Plaguelands 스테이지 보스 상자 | – | 6분 | 출시 시 8분 → 1.02.03 Nightmare 6분, Hell/Torment 7분 → 1.3.0 Hell/Torment 6분 |
| 할로윈 상자 | – | 0.05분(3초) | 입장당 최대 10개 제한이 따로 있음 |
| 첫 클리어 전용 상자(Box 1~3, Box 6) | 3600 / 300 (단위 불명) | – | – |

  - taskbarhero.wiki의 상자 목록 페이지는 "v1.00.12부터 서버 강제 쿨다운(초, 상자별 표시)"이라고 적지만, 값 3·5·7이 공식 공지의 "분" 수치와 맞으므로 **분**으로 본다. **[확인: 공지 대조]**
  - 1.2.4 이전에는 스테이지를 바꾸거나 게임을 재실행하면 대기 시간이 초기화되는 문제가 있었다(수정됨).
- 출시 직후(1.00.06 이전)에는 상자가 "분당 여러 개" 나왔다가 서버 부하로 "5~10분에 1개" 수준이 됐다는 팬 사이트 기록이 있다(taskbarhero.co/updates). **[추정]**

**보관과 자동 열기** [확인: 룬 스탯 W·F] / 기본값 [미확인]
- 상자는 종류별 보관함에 쌓인다. 보관 최대치는 룬으로 늘린다: `MaxAmountNormalChest` 합 +15, `MaxAmountStageBossChest` +13, `MaxAmountActBossChest` +10(1.00.17·1.3.0 동일), Plaguelands용 각 +5(1.3.0). **룬이 없을 때의 기본 보관 수는 찾지 못했다 [미확인]** (1.00.14 공지에 "상자를 5개 넘게 들고 재접속하면 5개만 남던 문제"가 있어 5 전후로 짐작만 가능).
- 보관함이 가득 차면 넘치는 상자를 잃는지에 대해: 할로윈 상자는 "보관함이 부족하면 일부 상자를 놓칠 수 있다"고 공식 공지가 명시한다. 일반 상자도 같을 것으로 보인다. **[추정]**
- 수동으로 열거나, 룬 "Rune of the Mainspring"으로 **자동 열기**를 해금한다: 일반 상자 300, 스테이지 보스 상자 600, 액트 보스 상자 60(값의 단위는 초로 보임 **[추정]**), "Rune of Lubrication"으로 각각 최대 −39 / −75 / −6 단축(1.00.17 합계). Plaguelands용은 600 / 1200 / 120.
- "한 종류 상자 한꺼번에 열기"(500골드), "모든 종류 한꺼번에 열기"(10,000골드) 룬이 있다.
- 인벤토리가 가득 차면 획득물은 우편함으로 간다(1.01.00 수정 문구). **[확인]**

**상자 레벨 매핑**(1.00.07 공지 = W 데이터) [확인]
| 지역(스테이지) 레벨 | 나오는 상자 |
|---|---|
| 1 ~ 3 | Box 1 / Boss Box 4 (장비 Lv1) |
| 5 ~ 8 | Box 2 / Boss Box 5 (Lv5) |
| 10 ~ 14 | Box 3 / Boss Box 7 (Lv10) |
| 15 ~ 19 | Lv15 Box |
| 20 ~ 29 | Lv20 Box |
| 30 ~ 39 | Lv30 Box |
| 40 ~ 49 | Lv40 Box |
| 50 ~ 64 | Lv50 Box |
| 65 ~ 79 | Lv65 Box |
| 80 ~ 95 | Lv80 Box |

- 1.2.0: "Lv90 장비는 지역 레벨 90 이상 스테이지에서" 획득(Torment 2-9 이상과 Torment Plaguelands). **[확인: 공지]**

상자 59종 목록(W 1.00.17):

| ID | 이름(데이터) | 등급 | 드롭 쿨다운(1.00.17) | 버킷형 | 드롭 스테이지 |
|---|---|---|---:|---|---|
| 910011 | Normal Monster Box 1 | COMMON | 3 | 예 | 1101~1103 (3개) |
| 910051 | Normal Monster Box 2 | COMMON | 3 | 예 | 1104~1107 (4개) |
| 910101 | Normal Monster Box 3 | COMMON | 3 | 예 | 1108~1202 (4개) |
| 910151 | Normal Monster Box Lv15 | COMMON | 5 | 예 | 1203~1207 (5개) |
| 910201 | Normal Monster Box Lv20 | COMMON | 5 | 예 | 1208~1307 (9개) |
| 910251 | Normal Monster Box Lv25 | COMMON | 5 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 910301 | Normal Monster Box Lv30 | COMMON | 5 | 예 | 1308~2108 (10개) |
| 910351 | Normal Monster Box Lv35 | COMMON | 5 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 910401 | Normal Monster Box Lv40 | COMMON | 5 | 예 | 2109~2304 (14개) |
| 910451 | Normal Monster Box Lv45 | COMMON | 5 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 910501 | Normal Monster Box Lv50 | COMMON | 5 | 예 | 2305~3204 (18개) |
| 910551 | Normal Monster Box Lv55 | COMMON | 5 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 910601 | Normal Monster Box Lv60 | COMMON | 5 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 910651 | Normal Monster Box Lv65 | COMMON | 5 | 예 | 3205~4102 (16개) |
| 910701 | Normal Monster Box Lv70 | COMMON | 5 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 910751 | Normal Monster Box Lv75 | COMMON | 5 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 910801 | Normal Monster Box Lv80 | COMMON | 5 | 예 | 4103~4309 (25개) |
| 910851 | Normal Monster Box Lv85 | COMMON | 5 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 910901 | Normal Monster Box Lv90 | COMMON | 5 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 920001 | Stage Boss Box 1 | RARE | 3600 | – | 없음(미사용/첫 클리어 보상 전용) |
| 920002 | Stage Boss Box 2 | RARE | 3600 | – | 없음(미사용/첫 클리어 보상 전용) |
| 920003 | Stage Boss Box 3 | RARE | 3600 | – | 없음(미사용/첫 클리어 보상 전용) |
| 920004 | Stage Boss Box 3 | RARE | 3600 | – | 없음(미사용/첫 클리어 보상 전용) |
| 920005 | Stage Boss Box 3 | RARE | 3600 | – | 없음(미사용/첫 클리어 보상 전용) |
| 920006 | Stage Boss Box 3 | RARE | 3600 | – | 없음(미사용/첫 클리어 보상 전용) |
| 920011 | Stage Boss Box 4 | RARE | 3 | 예 | 1101~1103 (3개) |
| 920022 | Stage Boss Box 6 | RARE | 300 | – | 없음(미사용/첫 클리어 보상 전용) |
| 920032 | Stage Boss Box 6 | RARE | 300 | – | 없음(미사용/첫 클리어 보상 전용) |
| 920042 | Stage Boss Box 6 | RARE | 300 | – | 없음(미사용/첫 클리어 보상 전용) |
| 920051 | Stage Boss Box 5 | RARE | 3 | 예 | 1104~1107 (4개) |
| 920052 | Stage Boss Box 6 | RARE | 300 | – | 없음(미사용/첫 클리어 보상 전용) |
| 920101 | Stage Boss Box 7 | RARE | 5 | 예 | 1108~1202 (4개) |
| 920151 | Stage Boss Box Lv15 | RARE | 7 | 예 | 1203~1207 (5개) |
| 920201 | Stage Boss Box Lv20 | RARE | 7 | 예 | 1208~1307 (9개) |
| 920251 | Stage Boss Box Lv25 | RARE | 7 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 920301 | Stage Boss Box Lv30 | RARE | 7 | 예 | 1308~2108 (10개) |
| 920351 | Stage Boss Box Lv35 | RARE | 7 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 920401 | Stage Boss Box Lv40 | RARE | 7 | 예 | 2109~2304 (14개) |
| 920451 | Stage Boss Box Lv45 | RARE | 7 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 920501 | Stage Boss Box Lv50 | RARE | 7 | 예 | 2305~3204 (18개) |
| 920551 | Stage Boss Box Lv55 | RARE | 7 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 920601 | Stage Boss Box Lv60 | RARE | 7 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 920651 | Stage Boss Box Lv65 | RARE | 7 | 예 | 3205~4102 (16개) |
| 920701 | Stage Boss Box Lv70 | RARE | 7 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 920751 | Stage Boss Box Lv75 | RARE | 7 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 920801 | Stage Boss Box Lv80 | RARE | 7 | 예 | 4103~4309 (25개) |
| 920851 | Stage Boss Box Lv85 | RARE | 7 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 920901 | Stage Boss Box Lv90 | RARE | 7 | 예 | 없음(미사용/첫 클리어 보상 전용) |
| 930101 | Act Boss Box 1 | LEGENDARY | – | – | 1110~1110 (1개) |
| 930201 | Act Boss Box Lv20 | LEGENDARY | – | – | 1210~1210 (1개) |
| 930301 | Act Boss Box Lv30 | LEGENDARY | – | – | 1310~1310 (1개) |
| 930401 | Act Boss Box Lv40 | LEGENDARY | – | – | 2110~2110 (1개) |
| 930451 | Act Boss Box Lv45 | LEGENDARY | – | – | 2210~2210 (1개) |
| 930501 | Act Boss Box Lv50 | LEGENDARY | – | – | 2310~2310 (1개) |
| 930601 | Act Boss Box Lv60 | LEGENDARY | – | – | 3110~3110 (1개) |
| 930651 | Act Boss Box Lv65 | LEGENDARY | – | – | 3210~3210 (1개) |
| 930701 | Act Boss Box Lv70 | LEGENDARY | – | – | 3310~3310 (1개) |
| 930851 | Act Boss Box Lv85 | LEGENDARY | – | – | 4110~4110 (1개) |
| 930901 | Act Boss Box Lv90 | LEGENDARY | – | – | 4210~4310 (2개) |

---

## 6. 골드 경제

### 6.1 재화 종류 [확인]
| 재화 | 성격 | 용도 |
|---|---|---|
| **Gold** | 유일한 일반 재화(`currencies` 테이블 1행, 시작 보유 100) | 아래 6.3 전부 |
| Soulstone (Normal/Nightmare/Hell/Torment) | 아이템(재료) | 액트 보스 입장권. 마켓 거래 가능 |
| Contaminated Soulstone (Nightmare/Hell/Torment) | 아이템 | 오염된 액트 보스 입장권 (1.2.0) |
| Contamination | 수치 자원(시간 충전) | Plaguelands 체류 연료 (1.2.0) |
| Plague Fruit (Rare~Beyond) | 아이템 | Corrosion으로 Contamination 충전 |
| 기념 주화 10종 (Kingdom/Empire … Anniversary Coin, Common~Cosmic) | 아이템 | 큐브 Offering(소원) 재료. 서버 장애 보상으로도 지급 |
| Contaminated Reliquary / Relic (각 10등급) | 아이템 | Offering으로 성유물함·유물 획득 (1.3.0) |
| Jack-o's Ticket, Jack-o' Candy | 이벤트 아이템 | 이벤트 입장 / Offering 재료 (거래 불가) |
| Cube EXP | 수치 | 큐브 레벨(레시피 해금 조건) |
| Steam Wallet 잔액 | 게임 밖 | Steam 커뮤니티 마켓 거래 대금. 게임 내 골드로 환전되지 않음 |

- **게임 내 유료 재화(보석류)는 없다.** 과금은 전부 Steam DLC 구매다. **[확인]** (S, 스토어 DLC 목록)
- Steam DLC 8종(https://store.steampowered.com/api/dlcforapp/?appid=3678970 , 2026-11-22 조회): Priest (Class) [app 4427410, 무료], Hunter (Class) [4427420], Slayer (Class) [4427430], Supporter Pack [4427390, 펫 3종], 3 Stash Pack [4427400, 보관함 3탭], Trade Ship Pack [4876910, 교역선 슬롯 +5], Material Stash Pack [5413620, 재료 전용 보관함·칸당 999개], Soundtrack [4427440]. 스킨(Dusk Wanderer, Halloween Festival)은 게임 내 Store/Outfits 메뉴에서 파는 별도 상품으로 공지되어 있다. **[확인]**

### 6.2 골드 획득처 [확인]
1. 몬스터 처치(일반·스테이지 보스·액트 보스) — §5.1.
2. **Alchemy(연금)**: 큐브에 아이템을 넣어 골드로 바꿈. 등급별 기본 골드(`BaseAlchemyGold`): Common 10, Uncommon 30, Rare 90, Legendary 270, Immortal 810, Arcana 2,592, Beyond 8,294, Celestial 29,029, Divine 101,602, Cosmic 355,607. 여기에 아이템 레벨 스케일(Lv1 1,000‰ … Lv20 220,000‰ … Lv80 1,120,000‰ … Lv90 1,227,000‰), 아이템 종류 스케일(GEAR 1,000‰ / MATERIAL 12,000‰), 장비 종류 스케일이 곱해진다. 룬 `CubeAlchemyGoldPercent` 합 +85%. 정확한 곱셈식은 아이템·큐브 담당 보고서 참조.
3. 오프라인 보상 — §7.
4. 업적 보상으로 골드를 주는지는 **[미확인]**.
- Steam 마켓 판매는 골드가 아니라 Steam Wallet 잔액을 준다.

### 6.3 골드 소비처와 비용 곡선 [확인: W 1.00.17 테이블]
| 소비처 | 비용 |
|---|---|
| **룬 트리** (197노드, 레벨 663단계, 전부 골드) | 첫 노드 100골드. 전 노드 완료 합계 **10,040,515,050골드**. 1.2.0에서 44노드, 1.3.0에서 5노드 추가(추가분 비용은 룬 담당 보고서) |
| 영웅 해금 | 영웅당 500 |
| 편성 슬롯 | 2번째 1,000 / 3번째 150,000 (룬) |
| 스킬 슬롯 | +1칸 50,000 (룬) |
| 오프라인 보상 해금 | 100 (룬 Rune of Repose) |
| 인벤토리 칸 | 21번째 칸부터 50 → 100 → 200 → 500 → 1,000 → 5,000 → 10,000 → 이후 7칸마다 2배(20,000 … 5,120,000), 119번째 칸 이후 10,240,000 고정 (260칸 표). 룬 `MaxInventorySlot` 합 +84칸도 별도 |
| 창고(Storage) 칸 | 40번째 칸부터 50씩 등차 증가(50, 100, … 3,100; 101칸 표) |
| 보관함(Stash) 칸 | 42번째 칸부터 100 → 200 → 400 → 1,000 → 2,000 → 10,000 → 이후 7칸마다 2배(… 5,120,000; 131칸 표). 보관함 페이지 추가 룬 10,000 / 3,000,000 / 50,000,000 |
| 큐브 레시피 해금 | Alchemy 10(Lv1), Decoration 300(Lv8), Engraving 1,000(Lv15), Inscription 10,000(Lv25), Extraction 1,000(Lv10), Offering 3,000(Lv20 → 1.00.22에서 Lv10), Synthesis 단계 2~8: 100 / 500 / 1,000 / 3,000 / 5,000 / 7,000 / 10,000 (큐브 Lv10~70), Crafting 단계 1~8: 100 / 500 / 1,000 / 2,000 / 5,000 / 10,000 / 20,000 / 30,000 |
| Offering 실행 비용 | 단계별 10 / 110 / 210 / … / 910 (`TriggerGoldCost`) |
| Extraction 비용 | 100 ~ 200,000 (부위 3종 × 재료 종류 3종 × 티어 10) |
| Decoration/Engraving/Inscription 실행 | 골드 소모 여부·금액 **[미확인]** (큐브 담당 보고서 참조) |
| **Attunement** (1.3.0, 유물·성유물함 재조정) | 시도마다 비용 증가, 상한 도달 후 고정(공식). F 데이터: 성유물함 Common 기본 100, 증가분 120, 최대 19회 증가 … Cosmic 기본 12,200,000, 증가분 14,640,000 / 유물은 그 절반(Common 50 + 60×n … Cosmic 6,100,000 + 7,320,000×n). 식은 `비용 = base + inc × min(시도 횟수, 19)`로 읽힌다 **[추정]** |
| 상자 편의 룬 | 한 종류 일괄 열기 500, 전 종류 일괄 열기 10,000, 자동 열기 해금 10,000 / 200,000 / 1,000,000 |

- 룬 비용 예시(같은 스탯이 깊어질수록): 오프라인 골드 룬 Lv1 비용 500 → 50,000 → 1,000,000 → 5,000,000 → 10,000,000; 일반 상자 보관 +1 룬 1,000 → 20,000 → 50,000 → 100,000 → … → 20,000,000; 스테이지 보스 상자 보관 +1 룬 30,000 → 500,000 → … → 150,000,000.
- 골드 누적 업적: 1,000 / 1,000,000 / 100,000,000골드 획득, 연금으로 1,000 / 1,000,000골드.
- 스테이지별 클리어당 골드는 Normal 1-1 14골드에서 Torment 3-9 약 72만 골드까지(§2.3 표).

---

## 7. 오프라인/방치 보상

### 7.1 규칙 [확인: 2개 이상 독립 출처 + 공식 문구]
- **게임을 꺼 두었던 시간에 대해 보상이 있다.** 게임 시작 시 "Offline Reward" 창이 뜨고 확인 버튼으로 받는다(1.3.0 공지의 UI 언급).
- **해금 필요**: 룬 "Rune of Repose"(`UnlockOfflineReward`, 100골드)를 찍어야 한다. (W·F 룬 데이터)
- **대상 보상: 골드와 EXP만.** 상자·아이템은 없다. (taskbarhero.co/mechanics, /beginner-guide: "gold + XP only — no chests"; 한국어 가이드 games.gg — 검색 요약 — "오프라인에서는 골드와 경험치를 얻지만 상자는 드롭되지 않는다"; 룬 스탯도 `OfflineRewardGoldPercent`, `OfflineRewardExpPercent` 두 가지뿐) — 반대 주장: 트레이너 판매 사이트(xmodhub) 한 곳이 "오프라인에도 상자가 줄어든 비율로 나온다"고 쓰지만 데이터·다른 출처와 맞지 않아 채택하지 않았다. **[불일치 기록]**
- **최대 누적 8시간(28,800초).** 더 오래 꺼 두어도 8시간분만. (taskbarhero.wiki/mechanics, probonk game-math, taskbarhero.co 일치)
- **약 30일 이상 자리를 비우면 0** (시계 조작 방지 가드). (taskbarhero.wiki/mechanics "about 30 days or more … gives 0", probonk "around 30 days or longer, are ignored")
- **기준 스테이지: 마지막으로 접속을 끊은 스테이지.** (taskbarhero.co/mechanics "XP uses the last logged-out stage") **[추정: 단일 계열 출처]**
- **보너스**: 오프라인 골드·EXP 룬이 레벨당 +10%(값 100‰), 합연산. 1.00.17 기준 각 21레벨(노드 5개) = 최대 +210%. 1.3.0에서 오프라인 EXP 룬 3개 추가. (F의 룬 요약은 골드 합 500, EXP 합 650으로 표기하는데 집계 방식이 달라 보인다 — **불일치 기록**)
- 오프라인 중 레벨업은 온라인과 같은 경험치 표를 쓴다. 오프라인 EXP에도 지역 레벨 페널티가 적용된다(1.3.0에서 "적용되지 않던 문제 수정"). **[확인]**
- Plaguelands의 Contamination은 오프라인 중에도 충전된다. **[확인: S 1.02.00]**

### 7.2 계산표와 식
게임 테이블 `offline_rewards`(W 1.00.17, 116행: 스테이지 레벨 1~116):

| StageLevel | BaseGold | BaseExp | KillCount | ClearCount |
|---:|---:|---:|---:|---:|
| 1 | 1 | 1 | 180 | 20 |
| 2 | 2 | 2 | 300 | 15 |
| 3 | 3 | 2 | 423 | 15 |
| 4 | 4 | 4 | 423 | 15 |
| 5 | 5 | 6 | 423 | 12 |
| 6 | 6 | 11 | 528 | 12 |
| 7 | 6 | 15 | 660 | 12 |
| 8 | 6 | 15 | 792 | 12 |
| 9 | 6 | 21 | 828 | 12 |
| 10 | 7 | 29 | 864 | 12 |
| 11 | 10 | 49 | 939 | 12 |
| 12 | 10 | 53 | 939 | 12 |
| 13 | 10 | 58 | 939 | 10 |
| 14 | 12 | 91 | 939 | 10 |
| 15 | 13 | 103 | 939 | 10 |
| 16 | 13 | 125 | 980 | 10 |
| 17 | 13 | 126 | 980 | 10 |
| 18 | 20 | 222 | 1120 | 10 |
| 19 | 21 | 259 | 1120 | 10 |
| 20 | 21 | 267 | 1200 | 10 |
| 21 | 28 | 359 | 1200 | 10 |
| 22 | 28 | 359 | 1200 | 10 |
| 23 | 28 | 359 | 1200 | 10 |
| 24 | 28 | 359 | 1200 | 10 |
| 25 | 28 | 359 | 1440 | 10 |
| 26 | 29 | 359 | 1440 | 10 |
| 27 | 30 | 404 | 1440 | 10 |
| 28 | 56 | 936 | 1440 | 10 |
| 29 | 56 | 936 | 1600 | 10 |
| 30 | 68 | 1163 | 1700 | 10 |
| 31 | 68 | 1163 | 1870 | 10 |
| 32 | 68 | 1163 | 1885 | 10 |
| 33 | 68 | 1163 | 1900 | 10 |
| 34 | 68 | 1163 | 1900 | 10 |
| 35 | 68 | 1163 | 2145 | 10 |
| 36 | 76 | 1336 | 2400 | 10 |
| 37 | 76 | 1336 | 2400 | 10 |
| 38 | 76 | 1336 | 2600 | 10 |
| 39 | 76 | 1336 | 2600 | 10 |
| 40 | 98 | 1777 | 2730 | 10 |
| 41 | 98 | 1777 | 2730 | 10 |
| 42 | 98 | 1777 | 2730 | 10 |
| 43 | 103 | 1901 | 2730 | 10 |
| 44 | 121 | 2118 | 2940 | 10 |
| 45 | 125 | 2118 | 3080 | 10 |
| 46 | 125 | 2118 | 3080 | 10 |
| 47 | 125 | 2118 | 3080 | 10 |
| 48 | 125 | 2118 | 3080 | 10 |
| 49 | 125 | 2118 | 3080 | 10 |
| 50 | 148 | 2640 | 3080 | 10 |
| 51 | 198 | 3731 | 3300 | 10 |
| 52 | 198 | 3731 | 3300 | 10 |
| 53 | 198 | 3731 | 3450 | 10 |
| 54 | 198 | 3731 | 3450 | 10 |
| 55 | 198 | 3731 | 3600 | 10 |
| 56 | 198 | 3731 | 3600 | 10 |
| 57 | 212 | 4021 | 3600 | 10 |
| 58 | 212 | 4021 | 3600 | 10 |
| 59 | 212 | 4021 | 3840 | 10 |
| 60 | 223 | 4241 | 3840 | 10 |
| 61 | 223 | 4241 | 4000 | 10 |
| 62 | 243 | 4652 | 4000 | 10 |
| 63 | 243 | 4652 | 4000 | 10 |
| 64 | 243 | 4698 | 4000 | 10 |
| 65 | 243 | 4698 | 4000 | 10 |
| 66 | 314 | 5633 | 4000 | 10 |
| 67 | 314 | 5633 | 4250 | 10 |
| 68 | 314 | 5633 | 4250 | 10 |
| 69 | 314 | 5633 | 4250 | 10 |
| 70 | 314 | 5633 | 4420 | 10 |
| 71 | 314 | 5633 | 4420 | 10 |
| 72 | 314 | 5633 | 4420 | 10 |
| 73 | 314 | 5633 | 4420 | 10 |
| 74 | 314 | 5633 | 4420 | 10 |
| 75 | 466 | 9054 | 4420 | 10 |
| 76 | 466 | 9054 | 4680 | 10 |
| 77 | 466 | 9054 | 4680 | 10 |
| 78 | 466 | 9054 | 5040 | 10 |
| 79 | 466 | 9054 | 5040 | 10 |
| 80 | 466 | 9054 | 5040 | 10 |
| 81 | 466 | 9054 | 5040 | 10 |
| 82 | 466 | 9054 | 5040 | 10 |
| 83 | 466 | 9054 | 5040 | 10 |
| 84 | 466 | 9054 | 5320 | 10 |
| 85 | 497 | 9665 | 5320 | 10 |
| 86 | 497 | 9665 | 5510 | 10 |
| 87 | 497 | 9710 | 5510 | 10 |
| 88 | 497 | 9710 | 5510 | 10 |
| 89 | 603 | 11272 | 5800 | 10 |
| 90 | 606 | 11272 | 5800 | 10 |
| 91 | 606 | 11272 | 6000 | 10 |
| 92 | 606 | 11272 | 6000 | 10 |
| 93 | 690 | 12809 | 6000 | 10 |
| 94 | 1022 | 20395 | 6300 | 10 |
| 95 | 1110 | 21898 | 6300 | 10 |
| 96 | 1110 | 21898 | 6300 | 10 |
| 97 | 1110 | 21898 | 6300 | 10 |
| 98 | 1110 | 21898 | 6300 | 10 |
| 99 | 1110 | 21898 | 6300 | 10 |
| 100 | 1110 | 21898 | 6300 | 10 |
| 101 | 1110 | 21898 | 6300 | 10 |
| 102 | 1110 | 21898 | 6300 | 10 |
| 103 | 1110 | 21898 | 6300 | 10 |
| 104 | 1110 | 21898 | 6300 | 10 |
| 105 | 1110 | 21898 | 6300 | 10 |
| 106 | 1110 | 21898 | 6300 | 10 |
| 107 | 1110 | 21898 | 6300 | 10 |
| 108 | 1110 | 21898 | 6300 | 10 |
| 109 | 1110 | 21898 | 6300 | 10 |
| 110 | 1110 | 21898 | 6300 | 10 |
| 111 | 1110 | 21898 | 6300 | 10 |
| 112 | 1110 | 21898 | 6300 | 10 |
| 113 | 1110 | 21898 | 6300 | 10 |
| 114 | 1110 | 21898 | 6300 | 10 |
| 115 | 1110 | 21898 | 6300 | 10 |
| 116 | 1110 | 21898 | 6300 | 10 |

- 표의 뜻(추론): `BaseGold`·`BaseExp`는 그 스테이지 레벨에서의 **처치당 평균 골드·EXP**와 맞아떨어진다(레벨 95: 표 1,110골드 / 21,898EXP ↔ Torment 3-9 일반 몬스터의 처치당 595~1,190골드, 11,739~23,478EXP; 레벨 1: 표 1 / 1 ↔ Slime·Goblin 1 / 1). `KillCount`·`ClearCount`는 **단위 시간당 가정 처치 수·클리어 수**로 보인다(레벨 95: 6,300처치 / 10클리어 ↔ Torment 3-9는 클리어당 651처치이므로 10클리어 ≈ 6,510처치).
- 따라서 유력한 식: `오프라인 골드 = BaseGold × KillCount × (경과 시간 / 단위 시간) × (1 + 오프라인 골드 룬%)`, EXP도 같은 꼴에 지역 레벨 페널티. **단위 시간이 1시간인지, ClearCount가 보스 보상에 쓰이는지, 일반 골드/EXP 증가 룬이 함께 곱해지는지는 확인하지 못했다. [추정]** 1시간이라면 레벨 95에서 기본 시간당 약 699만 골드 / 1.38억 EXP(8시간 약 5,594만 골드)로, 온라인에서 Torment 3-9를 시간당 10회 도는 것과 같은 수준이다.
- 효율 %("온라인의 몇 %")를 직접 명시한 자료는 없다. 위 표가 사실상 그 역할을 한다: 표는 **6분에 1클리어(초반은 3~5분)** 속도를 가정하므로, 그보다 빨리 도는 계정은 온라인이 유리하다. **[추정]**

### 7.3 게임이 켜져 있지만 비활성일 때
- 이 게임의 기본 플레이가 "작업표시줄 위에 띄워 두고 다른 일을 하는 것"이다. 창이 켜져 있으면 포커스와 무관하게 전투가 실시간으로 계속되고, 상자 드롭도 정상 판정된다(자동 열기 룬이 있으면 상자도 자동 소화). **[확인: 스토어 설명 "Just leave it running on your screen"]** 별도의 "비활성 페널티" 규칙은 찾지 못했다. **[미확인]**
- 다만 온라인 판정이 필요한 것(상자 획득, 큐브, 우편함)은 서버 응답이 있어야 하고, 1.00.12 이후 "서버가 응답하지 않으면 게임이 종료"된다. 장시간 방치 중 401 오류로 종료되던 문제는 1.01.00에서 수정. **[확인]**

---

## 8. 온라인 의존 기능

### 8.1 서버 구조 변천 [확인: S]
- 출시 시: **아이템이 Steam 인벤토리 아이템**이었다. 상자 열기와 큐브 조작이 Steam 아이템 서버(Inventory Service) 호출이어서, 동시 접속 급증(SteamDB 기준 최고 약 54.6만 명)과 치트 사용자의 비정상 아이템 생성 요청으로 Steam 쪽이 과부하에 걸렸다. Steam이 "아이템 종류 수를 줄이라"고 요구해 1.00.07에서 장비 레벨 구간·Type B를 삭제했다.
- 1.00.12(06-15): 핵심 데이터 처리를 **개발사 서버**로 이전(공지에 "BACKND 서버 점검"이라는 표현, 개인정보 통지에 "게임 서버 운영에 쓰는 제3자 서비스"). 이후 구조: 서버 가입(계정 ID), 로그인 대기열(업데이트 직후 최대 1시간), 서버 측 아이템 검증("server item verification result" 창), 서버 강제 상자 쿨다운, 치트 탐지 데이터, 1.3.0부터 재화·아이템 변동 로그.
- 세이브: 로컬 세이브(`%USERPROFILE%\AppData\LocalLow\TesseractStudio\TaskBarHero`) + 클라우드. "게임 구조상 플레이 데이터를 클라우드에 저장해야 한다"(07-10 로드맵 공지). 다른 PC에서 로그인해 강제 종료되면 미저장분이 사라질 수 있다. 1.01.05부터 24시간마다 세이브 백업(30일 보관).
- 1.3.0: **Steam 연결이 불안정하거나 Steam 점검 중이어도 플레이 가능**, 단 교역선과 우편함은 제한. (개발사 서버 연결은 여전히 필요한 것으로 읽힌다. **[추정]**)

### 8.2 기능별
| 기능 | 무엇인가 | 서버가 필요한 이유 | 근거 |
|---|---|---|---|
| **Trade Ship (교역선)** | 게임 안에서 아이템을 **Steam 커뮤니티 마켓**에 등록하는 화면. 큐브 Lv10 해금, 등록 슬롯 4개(DLC로 +5), 슬롯당 신규 등록 쿨다운 8시간(쿨다운 시작 후 등록 취소 불가). 장비는 Legendary 이상만, 재료(장식·각인·명문·제작 재료, Soulstone)는 전 등급 거래. 마켓에서 산 아이템은 일정 시간 재판매 제한이 있고, 그것을 재료로 만든 결과물에도 남은 제한 시간이 승계된다. 거래 대금은 Steam Wallet | 아이템이 Steam 인벤토리와 연동된 실물 자산이고 실제 화폐 가치가 있어, 생성·이동·소유권을 서버가 검증해야 한다 | S 05-31, 06-01, 06-25, 07-02 |
| **Mailbox (우편함)** | General 탭: 마켓 구매품, 유실 복구품, 인벤토리 초과분, 이전 버전의 보유 상자. Reward 탭: 개발사가 보낸 보상·이벤트 선물(수령 기한 있음, 예: 7일·매일 05:00 UTC 지급). 새로고침 쿨다운 5초, 반복 수령 1분 대기 | 서버 → 계정 아이템 전달 통로 | S 06-15, 07-02, 07-04 |
| **Steam 마켓/인벤토리 연동** | 아이템에 `IsSteamItem`, `IsCanExchangeMarketable` 속성. 마켓용 변종 표기 Type A/B/C. 보유 아이템 수 상한, "Steam Inventory 복구" 기능 | 위와 같음 | W `items` 열, S |
| **상자 드롭** | 드롭 쿨다운과 보상 내용을 서버가 결정·검증 | 드롭 조작(치트)과 마켓 인플레이션 방지 | W 상자 페이지 주석, S 1.00.12, 1.00.26 |
| **큐브 연산** (합성·연금·제작·장식·각인·명문·봉헌·추출·부식·조율) | 결과를 서버가 처리. 응답이 느리면 로딩 표시, 통신 오류 시 재접속 때 미처리 작업 복구 | 결과물이 거래 가능 아이템이므로 | S 07-30, 1.2.5 |
| **DLC 소유 확인** | 영웅·보관함·교역선 슬롯·Material Stash·스킨. 스토어 메뉴의 "구매 정보 새로고침" | Steam 소유권 조회 | S |
| **이벤트** | 기간 한정 스테이지(할로윈), 접속 선물(우편), 서버 점검 보상 | 서버 시각·우편 | S 10-22 |
| **치트 제재** | 탐지 시 마켓 영구 차단(게임은 계속 가능) | 서버 판정 | S |
| **Steam 업적 / 통계** | Steam 업적 80개, Steam Stats, 1.2.0의 인게임 통계 UI | Steam API | 스토어 카테고리 |
| **리더보드** | **없음으로 보인다.** 스토어 카테고리에 Leaderboards가 없고(Single-player, Achievements, Steam Cloud, Stats, Family Sharing 등), 공지·팬 사이트 어디에도 순위표 언급이 없다 | – | **[추정]** |
| 멀티플레이·길드·채팅 | 없음(스토어 카테고리 Single-player) | – | **[확인]** |

---

## 9. 업적·퀘스트·도감 등 기타 진행 시스템

### 9.1 업적 [확인]
Steam 업적 **80개**(1.3.0에서 Plaguelands·유물 관련 24개 추가 전에는 56개 — probonk "56 goals"와 일치). 목록(API 번호 | 이름 | 조건):

```
100001 | Hero Out of the Taskbar | Clear stage 1-1 for the first time.
100002 | TBH, This Game Slaps | Clear stage 1-10 for the first time!
100003 | Still Not Off the Clock | Clear stage 2-10 for the first time!
100004 | Normal? That's Boring. | Clear Normal mode for the first time!
100005 | The Nightmare Begins | Clear Nightmare mode for the first time!
100006 | Hell? Better Than Monday. | Clear Hell mode for the first time!
101001 | Gone Without a Trace | Defeat 1,000 monsters.
101002 | I Was Just Idling... | Defeat 10,000 monsters.
101003 | Monsters? What Monsters? | Defeat 100,000 monsters.
102001 | Package Delivered~ | Open 10 normal boxes.
102002 | A Gift from the Boss | Open 10 stage boss boxes.
102003 | The Big Boss's Treasure | Open 10 act boss boxes.
103001 | Starlit Gear | Obtain an Arcana grade gear for the first time.
103002 | Gear Beyond Limits | Obtain a Beyond grade gear for the first time.
103003 | Heaven-Sent Gear | Obtain a Celestial grade gear for the first time.
103004 | Blessed by the Divine | Obtain a Divine grade gear for the first time.
103005 | Chosen by the Cosmos | Obtain a Cosmic grade gear for the first time.
111001 | Tasted the Power of Synthesis | Successfully synthesize an Uncommon grade item for the first time.
111002 | Hey, Not Bad! | Successfully synthesize a Rare grade item for the first time.
111003 | Legends Are Made, Not Born | Successfully synthesize a Legendary grade item for the first time.
111004 | Recipe for Immortality | Successfully synthesize an Immortal grade item for the first time.
112001 | A Decorative Awakening | Successfully apply a Tier 1+ decoration option for the first time.
112002 | Decoration is an Art | Successfully apply a Tier 5+ decoration option for the first time.
113001 | Baby Steps in Engraving | Successfully apply a Tier 1+ engraving option for the first time.
113002 | Outshining Jewels | Successfully apply a Tier 5+ engraving option for the first time.
114001 | Let's Try Inscribing | Successfully apply a Tier 1+ inscription option for the first time.
114002 | Etched into the Soul | Successfully apply a Tier 5+ inscription option for the first time.
115001 | First Wish | Successfully make an offering for the first time.
116001 | Accessory Workshop: OPEN! | Successfully craft a Common grade or higher accessory for the first time.
116002 | The Immortal Artisan | Successfully craft an Immortal grade or higher accessory for the first time.
119001 | Horroric Cube | Reach Cube level 10.
119002 | Decubed Cain | Reach Cube level 50.
120001 | Rookie Merchant | List an item on the Trading Ship for the first time.
121001 | Friend of the Night | Unlock the Bat pet.
122001 | Hero's First Awakening | Reach Hero level 10 for the first time.
122002 | Still Warming Up | Reach Hero level 20 for the first time.
122003 | Getting the Hang of It | Reach Hero level 30 for the first time.
122004 | Half-Legend | Reach Hero level 50 for the first time.
122005 | Unleashed Potential | Reach Hero level 60 for the first time.
122006 | Almost There | Reach Hero level 70 for the first time.
122007 | Legend of the Taskbar | Reach Hero level 80 for the first time.
123001 | The Sacred Calling | Unlock the Priest hero.
131001 | Heroes Never Walk Alone | Raise 4 heroes to level 50 or above.
131002 | Solo Shift in Hell | Clear Hell 3-10 solo.
131003 | Two's Company | Clear Torment 3-10 with a 2-player party.
131004 | Obsession? No, Dedication. | Attempt inscription 100 times on the same item.
131005 | The Perfectionist | Complete all decoration/engraving/inscription on all equipped gear (for items with 2/2/2 slots).
131006 | In the Blink of an Eye | Clear any stage within 10 seconds.
131007 | ...Wait, I'm the Only One Left? | Clear Normal 3-10 act boss with 2 party members dead in a 3-player party.
131008 | Like a Ghost | Clear Nightmare 3-10 act boss without getting hit.
104001 | First Paycheck | Earn 1,000 gold.
104002 | Millionaire Dreams | Earn 1,000,000 gold.
104003 | Overflowing Vault | Earn 100,000,000 gold.
110001 | Alchemy 101 | Earn 1,000 gold through alchemy.
110002 | The Philosopher's Stone | Earn 1,000,000 gold through alchemy.
117001 | Essence Extracted | Successfully extract for the first time.
105001 | Beak Mask On | Clear a Plaguelands stage for the first time.
105002 | Apprentice Hunter (Nightmare) | Clear Nightmare Plaguelands at Plague Intensity 5.
105003 | Plague Hunter (Nightmare) | Clear Nightmare Plaguelands at Plague Intensity 10.
105004 | Plague Slayer (Nightmare) | Clear Nightmare Plaguelands at Plague Intensity 15.
105005 | Bane of the Plague (Nightmare) | Clear Nightmare Plaguelands at Plague Intensity 20.
105006 | Apprentice Hunter (Hell) | Clear Hell Plaguelands at Plague Intensity 5.
105007 | Plague Hunter (Hell) | Clear Hell Plaguelands at Plague Intensity 10.
105008 | Plague Slayer (Hell) | Clear Hell Plaguelands at Plague Intensity 15.
105009 | Bane of the Plague (Hell) | Clear Hell Plaguelands at Plague Intensity 20.
105010 | Apprentice Hunter (Torment) | Clear Torment Plaguelands at Plague Intensity 5.
105011 | Plague Hunter (Torment) | Clear Torment Plaguelands at Plague Intensity 10.
105012 | Plague Slayer (Torment) | Clear Torment Plaguelands at Plague Intensity 15.
105013 | Bane of the Plague (Torment) | Clear Torment Plaguelands at Plague Intensity 20.
105014 | Source Eliminated | Defeat a Contaminated Act Boss.
105015 | Plague Doctor | Defeat 10,000 monsters in the Plaguelands.
118001 | Embrace the Blight | Successfully perform Corrosion for the first time.
124001 | Seal Broken | Obtain a Reliquary by making an offering with a Contaminated Reliquary for the first time.
124002 | Awaken the Relic | Place a Relic in a Reliquary for the first time.
124003 | First Resonance | Activate a Resonance effect for the first time.
124004 | Double Resonance | Have 2 Resonance effects active at once.
124005 | Reliquary Complete | Fill all 8 slots of a Reliquary with Relics.
124006 | First Attunement | Successfully attune for the first time.
124007 | Master of Attunement | Attune the same Relic or Reliquary 10 times.
124008 | Relic Restorer | Successfully synthesize a Relic for the first time.
```
- 출처: https://steamcommunity.com/stats/3678970/achievements (페이지 내장 데이터에서 추출)
- 업적 달성 보상(골드·아이템)이 있는지는 **[미확인]**.

### 9.2 그 밖의 진행 축
| 시스템 | 존재 | 비고 |
|---|---|---|
| 룬 트리 | [확인] | 계정 전체 영구 강화. 골드로 구매. 세부는 룬 담당 보고서 |
| 펫 | [확인] | 특정 몬스터 5,000마리 처치로 5종, 서포터 팩 3종, 할로윈 2종(500마리). 보유 시 상시 적용 |
| 유물·성유물함 | [확인] | 1.3.0. Plaguelands 1회 클리어로 UI 해금. 세부는 유물 담당 보고서 |
| 큐브 레벨 | [확인] | 1~100(다음 레벨 EXP 15 → … → 10,511,250, 100레벨은 999,999,999로 막음). 레시피·교역선 해금 조건 |
| 영웅 레벨·스킬 포인트·패시브 | [확인] | 스킬 재분배 무료(팬 가이드) |
| 통계(Statistics) UI | [확인] | 1.2.0. 각종 플레이 기록 열람 |
| 전투 기록(Battle Record / Records) 창, 전투 로그 | [확인] | 클리어 기록 표시 |
| 외형(스킨) | [확인] | 1.2.0. 능력치 영향 없음(DLC) |
| **일일 퀘스트·주간 과제·출석부** | **자료 없음** | 공지 117건과 팬 DB 어디에도 일일/주간 과제 시스템이 없다. 할로윈 "접속 선물"은 우편 지급 이벤트였다. **[추정: 없음]** |
| **몬스터·아이템 도감(수집 보상형)** | **자료 없음** | 인게임 도감 UI에 대한 언급을 찾지 못했다. **[미확인]** |
| 리딤 코드 | 없음 | 공식 코드·입력 창구 확인되지 않음(taskbarheroatlas.com/codes, 2026-10-28 점검) **[추정]** |

---

## 10. 프레스티지/환생/시즌/엔드게임

- **프레스티지·환생 없음.** taskbarhero.wiki가 게임 코드 기준으로 "there is no prestige or rebirth system"이라고 명시하고, taskbarhero.co도 Prestige: No. 공지에도 없다. **[확인]**
- **시즌 없음(현재).** 2026-08-19 개발 노트가 "9월 업데이트 뒤 가능한 한 빨리 시즌 1 업데이트"를 언급했으나 11-22 현재 미배포. 시즌의 규칙(초기화 범위 등)은 공개된 바 없다. **[확인: 계획만 존재]** / 내용 **[미확인]**
- **현재 엔드게임(1.3.2)**: ① Torment 3-9 등 고레벨 스테이지 반복으로 상자·골드·EXP 파밍 ② Torment 액트 보스(Soulstone 소모) ③ **Plaguelands 강도 1~20 × 3난이도**(Contamination 소모, 초고등급 전용 드롭) ④ **오염된 액트 보스**(Contaminated Soulstone) ⑤ 유물·성유물함 수집과 Attunement ⑥ 큐브 합성으로 Cosmic 등급 장비 ⑦ Steam 마켓 거래. **[확인]**
- **예정**: 던전 4종, 신규 난이도, 최대 레벨 상향, 신규 스킬(11월 목표). 스테이지 레벨 배율표가 170까지 준비돼 있다. **[확인: 계획]**

---

## (a) 출처 목록과 신뢰도 평가

| 출처 | URL | 데이터 기준 | 신뢰도 | 비고 |
|---|---|---|---|---|
| Steam 공지(전문 API) | https://api.steampowered.com/ISteamNews/GetNewsForApp/v2/?appid=3678970&count=300&maxlength=0 | 2025-10-14 ~ 2026-11-12, 117건 | **최상(공식)** | 패치 연대기·규칙 변경의 1차 자료. 07-10 로드맵은 이미지라 본문 없음 |
| Steam 스토어 API | https://store.steampowered.com/api/appdetails?appids=3678970 | 조회일 현재 | 최상 | 출시일, 장르, 카테고리, DLC ID |
| Steam 업적 페이지 | https://steamcommunity.com/stats/3678970/achievements | 조회일 현재 | 최상 | 업적 80개 |
| taskbarhero.wiki | https://taskbarhero.wiki (`/data/t/*.json`, `/data/stages/*.json`, `/data/boxes/*.json`, `/mechanics`, `/news`) | **v1.00.17** | 높음(게임 파일 추출, 테이블 45종 원본 공개, 방어도·저항 공식은 디컴파일 검증 명시) | 1.2.0 이후 콘텐츠 없음. 계산값(HP 등)은 사이트의 식 |
| flex.shunshu-labo.org TBH DBAPP | https://flex.shunshu-labo.org/tbh/ (`/wp-content/themes/shunshu/tbh/data/tbh-data.json`) | **v1.03.00**, 2026-10-23 갱신 | 높음(추출 데이터, 최신) | Plaguelands·오염 보스·이벤트·1.3.0 몬스터 값. EstGold/EstExp는 "추정치"라고 자체 표기. 룬 집계는 방식 불명 |
| probonk.com | https://probonk.com/tbh-task-bar-hero/ (game-math, stages, monsters) | 1.3.0 이전(업적 56개 표기) | 중상 | taskbarhero.wiki와 같은 식·같은 값(독립성은 불확실) |
| taskbarherowiki.com | https://taskbarherowiki.com (farm, chests, patch-notes) | **v1.00.09** | 중 | 레벨 차 EXP 페널티 곡선의 유일한 출처. HP 스케일이 W와 10배 다름 |
| taskbarhero.co ("Taskbar Hero Atlas") | https://taskbarhero.co (mechanics, stages, monsters, updates, beginner-guide) | v1.00.09 기준, v1.00.13 보정 | 중 | taskbarherowiki.com 계열로 보임. 오프라인 "골드+EXP만, 마지막 스테이지 기준" 서술 |
| taskbarheroatlas.com | https://taskbarheroatlas.com/updates/plaguelands-update/ 등 | 1.3.2 추적(2026-10-28 점검) | 중(공식 공지 재서술, 자체 데이터 없음) | 공지 해석 교차 확인용 |
| taskbarhero.top | https://taskbarhero.top | taskbarhero.wiki와 같은 구조(미러로 보임) | – | 별도 사용 안 함 |
| flex.shunshu-labo.org 공략 글 | https://flex.shunshu-labo.org/task-bar-hero/2540/ (오염도), /2550/ (강도 6 공략), /2634/ (안정 주회) | 1.2.x ~ 1.3.0 (2026-09-08 ~ 10-29) | 중(개인 실측·추측 구분 표기) | Corrosion 환산 예, 사망·부활 정황, 저항 상한 75%, 최대 Lv101 |
| 검색 요약으로만 본 것 | jeu.video, mobalytics.gg, gameoverdrive.com.br, tbhguides.pages.dev, tbh.city, commonsensegamer.com, exitlag.com, games.gg(한국어 가이드), xmodhub.com, roonby.com | – | 낮음 | 본문 직접 확인 못 함. tbhguides의 난이도 배율은 데이터와 불일치 |
| 후속 확인 후보 | https://gamewith.ai/tbh/ja/stages/1110 (GameWith 계열 TBH DB, 스테이지·보스 페이지), https://kamigame.jp/taskbarhero/ , https://altema.jp/taskbarhero/katenai , /levelup | – | 미확인 | 검색으로 존재만 확인. 보스 HP 표시값이 있으면 (b)-1의 스케일 문제를 풀 수 있다 |

**접근 실패**: steamdb.info, jeu.video, tbh.city, tbhguides.pages.dev, task-bar-hero.pages.dev, web.archive.org, reddit.com, docs.google.com(스프레드시트)은 세션 네트워크 정책에서 차단. tbhindex.com, mobalytics.gg는 허용됐으나 curl에 403(봇 차단). altema.jp는 curl과 실제 브라우저(Playwright) 모두 403. 인벤·디시·나무위키·아카라이브·gamewith.ai·kamigame은 시도하지 못함(조회 한도).

## (b) 미확인으로 남은 중요 항목

1. **몬스터 HP·공격력의 절대 스케일**(÷1000 vs ÷100, 출처 계열 간 10배 차이). 상대 곡선은 확정. 인게임 수치 1건(예: 특정 스테이지 보스의 체력 표시)만 있으면 해결된다.
2. **전멸(스테이지 실패) 시 처리의 세부**: "같은 스테이지 재도전, 손실 페널티 없음"까지는 정황으로 추정(§2.4). 부활 대기 시간(초), 스테이지 도중 자동 부활 여부, 자동 재시도를 끈 경우의 동작은 미확인.
3. **EXP 파티 분배**: 각자 전액인지 분할인지. 처치 영웅 우선 여부.
4. **오프라인 보상 식의 세부**: `KillCount`/`ClearCount`의 단위 시간(1시간 추정), 일반 골드·EXP 증가 룬과의 곱 여부, 기준 스테이지가 "마지막 스테이지"인지 "최고 클리어 스테이지"인지.
5. **상자 버킷 용량과 기본 보관 수**, 보관함 초과 시 유실 여부(일반 지역), 자동 열기 타이머 단위.
6. **Contamination 수치**: 최대치, 분당 소모량, 충전 속도, Corrosion 환산식, Plague Fruit 등급별 충전량.
7. **역병 변이 몬스터(2010001~2010004)** 의 이름·능력치·효과, 역병 강도 배율의 적용 방식(곱/합), 높은 역병 강도의 추가 속성 저항 페널티 수치.
8. **액트 보스 스킬의 세부 수치**(쿨다운, 필요 타수, 범위, 소환물), 탈출 포털 사용 시 Soulstone 소모 여부.
9. **레벨 차 EXP 페널티의 정확한 식**(곡선 표본만 있음), 골드에도 적용되는지.
10. 업적 보상 유무, 일일/주간 과제·도감의 부재 확정.
11. 07-10 **개발 로드맵** 이미지의 내용, 시즌 1의 규칙.
12. 한국어 현지화 용어(난이도·스테이지·상자 이름).

## (c) 서버 없이 단독 실행되는 구현에서 대체가 필요한 기능 목록

| 원작 기능 | 서버 의존 이유 | 단독 실행 구현에서의 대체안 |
|---|---|---|
| 상자 드롭 쿨다운(서버 강제, 토큰 버킷) | 조작 방지·마켓 보호 | 로컬 타이머로 같은 규칙 재현: 상자 종류별 `쿨다운(분)`마다 토큰 1개 충전, 처치 시 확률 판정 + 토큰 소모. 마켓이 없으므로 상한을 느슨하게 하거나 없애도 됨. 저장 데이터에 마지막 충전 시각 기록 |
| 상자 보상 결정·검증 | 서버 권위 | 로컬 난수로 가중치 표 추첨 |
| Trade Ship / Steam 마켓 | 실화폐 거래 | 제거하거나, NPC 상인(고정가 매입·랜덤 판매 목록)으로 대체. "Legendary 이상만 거래", "슬롯 4개·8시간 쿨다운" 같은 규칙은 마켓 보호용이므로 불필요 |
| Mailbox | 서버 → 계정 전달 | "인벤토리 초과분 임시 보관함"으로만 유지. 보상 우편은 제거 |
| 로그인·계정·대기열·치트 제재 | 온라인 서비스 | 불필요. 저장 데이터는 로컬(애드온이면 SavedVariables) |
| 클라우드 세이브·24시간 백업 | 데이터 보호 | 로컬 저장 + 선택적 백업 슬롯 |
| 오프라인 보상의 시각 판정(8시간 상한, 30일 가드) | 서버/시스템 시각 | 로컬 시각 차이로 계산. 음수·과대(30일 초과) 경과 시간은 0 처리 — 원작과 같은 가드 |
| Contamination 시간 충전(오프라인 포함) | 서버 시각 | 로컬 시각 기반 충전, 같은 가드 적용 |
| 기간 한정 이벤트(할로윈), 접속 선물 | 서버 일정 | 달력 기반 로컬 이벤트로 재현하거나 상시 콘텐츠화 |
| DLC 소유 확인(영웅·보관함·슬롯) | Steam 소유권 | 전부 기본 포함 또는 게임 내 진행으로 해금. 상자의 `_DLCVariant` 4가지 가중치 세트는 "해금한 영웅 조합"으로 대체 가능 |
| Steam 업적·통계 | Steam API | 게임 내 업적 목록(§9.1 조건 재사용 가능)과 로컬 통계 |
| 큐브 연산의 서버 처리·복구 | 거래 자산 보호 | 로컬 즉시 처리 |
| 아이템 Type A/B/C, 거래 제한 시간 승계 | 마켓 규칙 | 불필요 |
| 스테이지 변경 제한(비정상 변경 감지) | 상자 타이머 악용 방지 | 불필요(토큰 버킷을 스테이지와 무관한 전역 타이머로 두면 자연히 해결 — 원작도 1.2.4에서 그렇게 고침) |
