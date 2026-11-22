# 06. 와우 포에버(World of Warcraft: Forever) 애드온 실행 환경 조사

- 조사 시점: 2026-11-21 ~ 2026-11-22 (KST 기준 표기, 출처의 원 시각은 각 항목에 병기)
- 조사 목적: 포에버 클라이언트에서 도는 **독립형 미니게임 애드온**(실제 전투·유닛·아이템을 건드리지 않는 순수 UI 애드온)을 설계하기 전에 실행 환경을 확정한다.
- 태그 규칙
  - **[확인]** 공식 자료, 또는 서로 독립된 2개 이상 출처가 일치
  - **[추정]** 단일 비공식 출처이거나 추론
  - **[미확인]** 찾지 못함(실제 클라이언트에서 확인 필요)
- 1차 근거로 가장 많이 쓴 것
  - 블리자드 공식 뉴스 `worldofwarcraft.blizzard.com` (ko-kr / en-us) — 직접 내려받아 본문 확인
  - 블리자드 공식 포럼 `us.forums.blizzard.com` — 직접 조회(공식 정책 글 + 플레이어 글)
  - GitHub `Gethe/wow-ui-source` 의 **`forever` 브랜치**(블리자드 클라이언트에서 추출한 공식 UI 소스 미러, 최신 커밋 `1.60.1 (71037)`, 2026-11-20) — 통째로 내려받아 grep
  - GitHub `Ketho/BlizzardInterfaceResources` 의 **`forever` 브랜치**(실제 포에버 클라이언트 안에서 덤프한 전역 함수·위젯 메서드·CVar·이벤트·GlobalStrings 목록, 커밋 `1.60.1 (70938)`, 2026-11-14)
  - GitHub `BigWigsMods/packager` 의 `release.sh` / `README.md`, 인기 애드온 TOC 원본
  - 인벤 와우 정보/포에버 게시판 — 직접 조회

> 결론 먼저: **"클래식 시대 애드온 API가 그대로 동작한다"는 가정은 틀리다.** 포에버는 리테일(Mainline) 코드 계열의 클라이언트이며, API·UI 프레임워크·애드온 제한(secret values)이 모두 리테일(한밤 12.1.x)과 같다. 다만 **게임 상태를 읽지 않는 순수 UI 애드온은 그 제한의 영향을 거의 받지 않는다**(4절).

---

## 1. 와우 포에버의 정체

### 1.1 명칭

| 항목 | 내용 | 태그 / 근거 |
|---|---|---|
| 영문 정식 명칭 | **World of Warcraft: Forever** (약칭 WoW: Forever) | [확인] 공식 뉴스 "Carve a New Path with World of Warcraft: Forever"(2026-09-12 게시) https://worldofwarcraft.blizzard.com/en-us/news/24302093 |
| 한글 정식 명칭 | **월드 오브 워크래프트: 포에버** (약칭 WoW: 포에버, 커뮤니티 통칭 "와우 포에버") | [확인] 공식 뉴스 https://worldofwarcraft.blizzard.com/ko-kr/news/24302093 , 클라이언트 문자열 `CATALOG_SHOP_WOW_FLAVOR_FOREVER = "WoW: 포에버"`, `EXPANSION_NAME_FOREVER0 = "포에버"` (Ketho `forever` 브랜치 `Resources/GlobalStrings/koKR.lua`) |
| 내부 코드명(게임 타입) | **Camelot** (TOC 조건문·TOC 접미사·`WOW_PROJECT_CAMELOT` 에 그대로 쓰임) | [확인] Gethe `forever` 브랜치, Ketho README, 블리자드 발언 인용(1.4) |
| CDN 제품 코드 | **`wowf`** (베타 때는 `wow_classic_beta`) | [확인] Gethe `forever` 브랜치 커밋 "Monitor wowf product"(2026-11-02, `.github/workflows/export.yml` 의 `product: wow_classic_beta` → `wowf`), `automation` 브랜치 `ExportInterfaceFiles.ps1` 의 제품 목록 |

### 1.2 공식 발표 내용과 일정

- [확인] **블리즈컨 2026(2026-09-12)** 에서 공개. 공식 표현: "Built as a new permanent home alongside modern and Classic WoW" / "현대 WoW 및 클래식 WoW와 함께 새롭고 영구적인 고향".
  출처: https://worldofwarcraft.blizzard.com/en-us/news/24302093 (게시 2026-09-12T20:45Z, 수정 2026-10-27)
- [확인] 공식 문구 **"This is not a mode, a season, or a new version of Classic."** — 즉 클래식의 새 시즌/새 버전이 아니라 별도의 상시 서비스 게임이라는 입장.
  출처: "World of Warcraft: Forever What's Next Panel Recap" https://worldofwarcraft.blizzard.com/en-us/news/24303862 (2026-09-12)
- [확인] 시대 배경: 《워크래프트 III 리포지드: 포세이큰 왕국》 사건 이후 ~ **화산 심장부 이전**. 오리지널 두 대륙에서 60레벨까지. (같은 기사)
- [확인] **베타**: 2026-09-17(PT) = 한국 9월 18일 시작. 스카이본 신화 꾸러미/워크래프트 포에버 컬렉션 구매자 대상. (en-us/ko-kr 24302093)
  - [추정] 베타 종료일 10월 22일 — 블리자드 뉴스 검색 요약에서만 확인(본문 직접 미확인). Gethe `forever` 브랜치의 베타 빌드 커밋이 2026-10-22 `1.60.1 (70532)` 에서 끊기고 11-02 부터 `wowf` 로 재개되는 것과 부합.
  - [확인] 10월 21일 스트레스 테스트 진행. 포럼 "Heads Up -- WoW Forever Stress Test on October 21" https://us.forums.blizzard.com/en/wow/t/2387920
- [확인] **정식 출시**: 2026-11-04 15:00 PST = 2026-11-04 23:00 UTC = **한국 시간 2026-11-05 08:00**, 전 세계 동시.
  - 공식 en-us: "launches globally on November 4, 2026, at 3:00 p.m. PST" (24302093, 24303862)
  - 공식 "World of Warcraft: Forever Now Live!" 게시 시각 2026-11-04T23:00:00Z https://worldofwarcraft.blizzard.com/en-us/news/24315820 , 한국어판 "월드 오브 워크래프트: 포에버가 출시되었습니다!" https://worldofwarcraft.blizzard.com/ko-kr/news/24315820
  - 인벤 정보 게시판에 전재된 공식 시간표: 한국(KST) 11월 5일 오전 8:00 / PST 11월 4일 오후 3:00 / UTC 11월 4일 23:00 https://www.inven.co.kr/board/wow/1896/52183 (2026-11-04 02:53 작성)
  - **출처 간 불일치(나란히 기록)**: 한국어 공식 기사 24302093 본문에는 "한국 시간 2026년 11월 5일 오전 7:00" 과 "한국 시간 2026년 11월 4일 오전 3:00" 이 함께 적혀 있다(현지화 오류로 보임). 영문 원문·인벤 전재 시간표·출시 기사 게시 시각은 모두 08:00 KST 와 일치하므로 08:00 을 채택.

### 1.3 2026-11-21 현재 상태

- [확인] **정식 서비스 중**(출시 17일차). 4개 지역 동시 서비스.
- [확인] 클라이언트 버전 **1.60.1**, 최신 빌드 **71037**(2026-11-20). 출시 이후 빌드 이력(Gethe `forever` 브랜치 커밋 로그): 70707(11-02) → 70755(11-03) → 70790(11-04, 출시일) → 70840(11-06) → 70862(11-07) → 70888(11-10) → 70938(11-13) → 70959(11-17) → 71037(11-20). 패치 번호는 베타 첫 빌드(69876, 2026-09-16)부터 계속 1.60.1.
- [확인] 아직 열린 공격대 없음(첫 공격대는 12월, 2절).
- [확인] 하드코어 규칙은 "출시 후 추가 예정"(미출시). (24315820)

### 1.4 기존 클래식·리테일과의 관계

- [확인] 리테일·클래식과 **병행 운영되는 세 번째 상시 서비스**. 공식 문구 "alongside modern and Classic WoW".
- [확인] 기술적으로는 **리테일과 같은 Mainline 코드 계열**이다(클래식 계열이 아님). 블리자드가 WoW UI 개발자 디스코드에 밝힌 내용(2026-09-15경):
  > "WoW Forever shares Mainline WoW's UI architecture, including the vast majority of APIs available in 12.1.5. From a UI loading perspective, the easiest way to think about it is that Forever and modern WoW (Midnight) are two game types within the Mainline code family: Camelot (to be renamed before launch) and Standard, respectively. The addon disarmament changes introduced in Midnight, including secrets, will also be active in Forever. The AuraContainer/AuraButton changes introduced in 12.1.0 will be available as well, and you can expect similar UI changes in the future to be introduced to both Standard and Forever."
  - 인용 경로(디스코드 원문은 직접 접근 불가): 공식 포럼 글 https://us.forums.blizzard.com/en/wow/t/2347251/1287 (2026-09-16), https://us.forums.blizzard.com/en/wow/t/2348036/10 (2026-09-19), 인벤 번역 https://www.inven.co.kr/board/wow/1896/51812 (2026-09-16 10:35, WeakAuras 공식 X 게시물 링크 포함). 서로 독립된 3곳이 같은 문장을 옮김.
  - 소스 코드로 교차 검증됨(3절·4절).
  - 참고: "출시 전 이름 변경 예정"이라던 Camelot 은 **출시 후 빌드(70938, 71037)에서도 그대로 Camelot** 이다. [확인] Ketho README `TOC [Game] => "Camelot"`, Gethe `forever` 브랜치 TOC 의 `[AllowLoadGameType camelot]`.
- [확인] 클래식 계열 클라이언트는 별도로 계속 존재: `Gethe/wow-ui-source` 브랜치 `classic_era`(1.15.9.70576), `classic_anniversary`(2.5.6.70577), `classic`(5.5.4.71060), `classic_titan`(3.80.2.70522), 리테일 `live`(12.1.5.70961), `ptr`(12.1.7.71087). 각 브랜치 `version.txt` 를 2026-11-21 에 직접 읽음.
- 기존 클래식 각 서비스의 현재 위치
  - [확인] 클래식 에라: 1.15.9 로 유지(위 `classic_era` 브랜치).
  - [확인] 20주년(Anniversary) 서버: 클라이언트가 2.5.6 = 불타는 성전 단계. [추정] 일반/PvP 서버는 2026-01-13 에 불타는 성전 클래식으로 넘어갔고 하드코어 서버만 오리지널 단계에 남았다(warcraft.wiki.gg 검색 요약).
  - [추정] 디스커버리 시즌(SoD): 개발은 끝났고 서버는 유지 중이라는 2차 보도(BlizzardWatch 2026-04, Massively OP 2025-11 — 검색 요약). 포에버 출시 이후 상태를 밝힌 공식 글은 찾지 못함 → [미확인]. 공식 기사에는 "WoW 클래식과 디스커버리 시즌에서 배운 것"이라는 언급만 있음.
  - 즉 포에버는 이들 중 어느 것의 후속 단계나 대체물이 아니라 **별도 클라이언트(`_forever_`, 제품 코드 `wowf`)** 다.

### 1.5 과금·접속 방식

- [확인] **WoW 구독 또는 게임 시간에 포함**(리테일·클래식과 같은 이용권). "World of Warcraft, including World of Warcraft: Forever, requires World of Warcraft Subscription or Game Time."
  출처: https://worldofwarcraft.blizzard.com/en-us/news/24301508 (2026-09-12 게시, 2026-11-04 수정)
- [확인] 선택형 유료 업그레이드(한글 명칭은 ko-kr 24302093 기준)
  - **스카이본 영웅 꾸러미**(Skyborne Heroic Pack): 신규 종족 스카이본 + 제프라스 섬 시작 지역 이용권, 이름 사전 예약, 탈것, 꾸미기 등
  - **스카이본 신화 꾸러미**(Skyborne Epic Pack): 위 + 베타 이용권 + 게임 시간 30일 등
  - **워크래프트 포에버 컬렉션**(2027-01-11 까지 판매): 위 + 워크래프트 III 리포지드 + 포세이큰 왕국 캠페인
  - 즉 **스카이본 종족은 유료 꾸러미가 있어야 플레이 가능**하다(애드온이 "플레이어 종족"을 쓸 경우 참고).
  - [추정] 가격 영웅 $29.99 / 신화 $59.99 — 팬 사이트 요약에서만 확인.
- [확인] 접속: Battle.net 앱의 게임 버전 메뉴에서 선택. 서버 목록 대신 **규칙(Ruleset)** 을 고른다 — 일반 / PvP / 롤플레이 / 롤플레이 PvP (하드코어는 추후). PvP 규칙에서는 한 진영만 생성 가능. (24315820, https://worldofwarcraft.blizzard.com/en-us/news/24302070 )
- [확인] **서버(realm) 구분이 없는 구조 + 이중 이름(이름·성)**. 전체 이름이 지역 단위로 고유. https://worldofwarcraft.blizzard.com/en-us/news/24304161 (2026-09-21) → 애드온의 캐릭터 식별 키 설계에 직접 영향(4.4절).
- [확인] 첫 접속 시 **플레이 환경 사전 설정**(클래식 / 강화됨[Enhanced]) 선택 — 모델·UI 배치·가방 통합·퀘스트 표시 기본값만 다르고 규칙과 무관. API: `C_GameRules.GetForeverExperiencePreset()`, `Enum.ForeverExperiencePreset.Classic(0) / Enhanced(1)` (Gethe `forever` `GameRulesDocumentation.lua`).

---

## 2. 게임 콘텐츠 범위

### 2.1 레벨·직업·종족

- [확인] **최대 레벨 60, 이후에도 올리지 않음.** "sticks to a level cap of 60 without going beyond. This leaves room for an expanding game without an expansion of levels."
  출처: "WoW: Forever—What's New and What Feels Familiar" https://worldofwarcraft.blizzard.com/en-us/news/24315821 (2026-11-03)
- [확인] **직업 9개**: 전사, 성기사, 사냥꾼, 도적, 사제, 주술사, 마법사, 흑마법사, 드루이드. (죽음의 기사·수도사 등 없음)
  근거: 공식 기사 "Create the Hero You Want to Be" https://worldofwarcraft.blizzard.com/en-us/news/24304075 (2026-09-22) + 클라이언트 소스 `Blizzard_FrameXMLBase/Camelot/Constants.lua` 의 `CLASS_SORT_ORDER`(9개).
- [확인] **종족 9개**: 인간, 드워프, 노움, 나이트 엘프 / 오크, 언데드(포세이큰), 타우렌, 트롤 / **스카이본(신규, 양 진영 선택)**. 불타는 성전 이후 종족(블러드 엘프, 드레나이 등)은 없음.
  근거: 같은 공식 기사 + `Blizzard_NewPlayerExperience/Camelot/Blizzard_TutorialData.lua` 의 종족 키(Human, Dwarf, Gnome, NightElf, Scourge, Orc, Troll, Tauren, Skyborne).
- [확인] 스카이본: 하이 엘프 망명자 계열("셴도레이"), 시작 지역 제프라스 섬(1~12레벨). 캐릭터 생성 때 진영 선택 — 호드 = **바람구체자**(Windshaper), 얼라이언스 = **고등 마법원 스카이본**(High Order). 한글 명칭은 ko-kr 24315820.

### 2.2 진영별 직업 제한 — **유지되지 않는다**

- [확인] 오리지널의 "성기사 = 얼라이언스 전용, 주술사 = 호드 전용"은 **깨졌다.** 신규 종족·직업 조합 6개(오크 마법사, 트롤 흑마법사, **언데드 성기사**, 인간 사냥꾼, 노움 사제, **드워프 주술사**)와 스카이본이 추가되어 **양 진영 모두 9개 직업 전부 선택 가능**하다.
- 공식 종족·직업 표(https://worldofwarcraft.blizzard.com/en-us/news/24304075 의 HTML 표를 직접 파싱)

| 진영 | 종족 | 선택 가능한 직업 |
|---|---|---|
| 호드 | 오크 | 사냥꾼, **마법사**(신규), 도적, 주술사, 흑마법사, 전사 |
| 호드 | 타우렌 | 드루이드, 사냥꾼, 주술사, 전사 |
| 호드 | 트롤 | 사냥꾼, 마법사, 사제, 도적, 주술사, **흑마법사**(신규), 전사 |
| 호드 | 언데드 | 마법사, **성기사**(신규), 사제, 도적, 흑마법사, 전사 |
| 호드 | 스카이본(바람구체자) | 드루이드, 사냥꾼, 도적, **주술사**, 전사 |
| 얼라이언스 | 드워프 | 사냥꾼, 성기사, 사제, 도적, **주술사**(신규), 전사 |
| 얼라이언스 | 노움 | 마법사, **사제**(신규), 도적, 흑마법사, 전사 |
| 얼라이언스 | 인간 | **사냥꾼**(신규), 마법사, 성기사, 사제, 도적, 흑마법사, 전사 |
| 얼라이언스 | 나이트 엘프 | 드루이드, 사냥꾼, 사제, 도적, 전사 |
| 얼라이언스 | 스카이본(고등 마법원) | 드루이드, 사냥꾼, **마법사**, 도적, 전사 |

- 정리: **호드 성기사는 언데드만, 얼라이언스 주술사는 드워프만** 가능. 스카이본은 성기사·사제·흑마법사 불가.
- 미니게임 설계 시사점: "진영 → 사용 가능 직업"을 오리지널 규칙으로 하드코딩하면 실제 게임과 어긋난다.

### 2.3 오리지널 대비 변경점(클래식+ 요소) — 모두 [확인], 출처 24315820 / 24303862 / 24315821

- 신규·개편 지역: 하이잘 산, 셴드랄라스(멀고어와 잊혀진 땅 사이), 강물터(Riverglades, 30중반~40중반), 제프라스 섬. 1~60 구간 신규 퀘스트 1,000개 이상.
- 신규 5인 던전 9개(13~60레벨): Hall of Thanes(아이언포지 지하), Ruins of Lordaeron, 웰가르 발굴지 위 발굴 현장, City of Dalaran, Blackmaw Hold(검은아귀 요새), Drowned City, Krol'dok Stronghold, Alcaz Prison, Shaper's Terrace. 기존 오리지널 던전(검은바위 나락·첨탑 등)도 존재(오닉시아 조율 퀘스트에 등장).
- 신규 전장: 검은창 군도(15 대 15).
- 신규 시스템: 유산(Legacy) 시스템(계정 단위 수평 성장), 야영(Camping, 모닥불 기반 공유 버프), 이중 이름, 규칙(Ruleset) 선택, 형상변환(선택), HD/SD 캐릭터 모델 선택, 게임패드 지원(베타 상태).
- 직업: 특성·기술 갱신, 종족 특성 갱신.
- 기본 UI: 리테일식 **편집 모드, 쿨다운 관리자, 데미지 미터 내장**(24315821 "Advanced options ... Cooldown Manager and a Damage Meter").
- 유지되는 원칙: 비행 탈것 없음, 레벨 스케일링 없음.

### 2.4 던전·공격대 공개 일정

| 공격대 | 상태(2026-11-21) | 근거 |
|---|---|---|
| **지하 심굴**(The Barrow Deeps) — 10인, 우두머리 8, 하이잘 산 내부 | 미개방. **2026-12-09(PT) / 한국 12월 10일** 개방 | [확인] en-us https://worldofwarcraft.blizzard.com/en-us/news/24303009 , ko-kr https://worldofwarcraft.blizzard.com/ko-kr/news/24303009 (2026-10-20) |
| **하이잘 정상**(Hyjal Summit) — 20인, 우두머리 13 | 미개방. 같은 날 개방 | [확인] 같은 기사 |
| **오닉시아의 둥지** — 40인, 비룡불꽃 아뮬렛 조율 필요(진영별 퀘스트라인) | 미개방. 같은 날 개방 | [확인] 같은 기사 |
| **화산 심장부** | 일정 없음. 게임 배경 자체가 "화산 심장부 이전" | [확인] 배경 설명(24302093, 24315820). 공식 로드맵 문구에는 "a revamped iconic raid"(이름 미공개)만 있음(24303862) |
| 검은날개 둥지 / 줄구룹 / 안퀴라즈 폐허·사원 / 낙스라마스 | **[미확인]** 공식 기사 23건 본문 검색에서 이름이 전혀 나오지 않음 | 2026-11-21 내려받은 공식 기사 텍스트 grep 결과 |

- [확인] 현재 열려 있는 공격대는 **없다.** 모든 공격대는 주 단위 초기화 예정("With all raids currently planned to reset each week").
- [확인] 공식 로드맵 문구(24303862): "New raids unlock on December 9, followed by more raids, dungeons, PvP updates, world content, additional quests throughout the level 1–60 journey, Hardcore, a revamped iconic raid, and major updates".
- [추정] 팬 사이트들이 로드맵 이미지를 옮겨 적은 내용: 2026~27 겨울 하드코어, 2027 봄 신규 공격대 2개(10인·20인)+던전 2개, 2027 여름 "개편된 상징적 공격대"+신규 공격대 1개, 공격대 단계 간격 약 4개월. 로드맵 이미지는 CDN 차단으로 직접 확인 못 함. 화산 심장부가 그 "개편 공격대"라는 것은 **추측일 뿐 공식 확인 없음**.
- 미니게임 설계 시사점: 포에버의 실제 진행은 "오닉시아 → 화산 심장부 → 검은날개 둥지…" 순이 아니며, 포에버 고유 공격대(지하 심굴, 하이잘 정상)가 먼저다. 오리지널 공격대 이름을 쓰는 것은 자유지만 "현재 서버 진행도와 일치"한다고 표기하면 안 된다.

---

## 3. 클라이언트 / 애드온 기술 정보

### 3.1 빌드와 `## Interface:` 번호

| 항목 | 값 | 태그 |
|---|---|---|
| 패치 버전 | **1.60.1** | [확인] |
| 최신 빌드 | **71037** (2026-11-20). 출시일 빌드 70790 | [확인] Gethe `forever` 브랜치 `version.txt` = `1.60.1.71037` |
| **TOC `## Interface:`** | **`16001`** | **[확인]** — 아래 근거 5종 |
| `GetBuildInfo()` | `"1.60.1", "70938", "Nov 12 2026", 16001` (빌드 70938 시점 덤프). 반환 시그니처: buildVersion, buildNumber, buildDate, interfaceVersion, localizedVersion, buildInfo | [확인] |

**Interface 번호 16001 의 근거(어디에서 봤는지)**

1. `Ketho/BlizzardInterfaceResources` `forever` 브랜치 **`README.md`** — 실제 클라이언트에서 실행한 결과: ``GetBuildInfo() => "1.60.1", "70938", "Nov 12 2026", 16001`` (커밋 2026-11-14). https://github.com/Ketho/BlizzardInterfaceResources/tree/forever
2. `BigWigsMods/packager` **`README.md`**: ``## Interface: 11509, 20506, 30405, 38002, 40402, 50504, 120100, 16001`` — "latest version of all client flavors and Forever Beta". 같은 저장소 **`release.sh`**: `16???) game_type="forever"`, `forever) game_type_toc_prefix="16[0-9]"`. https://raw.githubusercontent.com/BigWigsMods/packager/master/release.sh
3. 인기 애드온 TOC 원본(2026-11-21 raw 조회)
   - `BigWigsMods/BigWigs` `BigWigs.toc`: `## Interface: 11508, 11509, 16001, 20505, …, 120107`
   - `DeadlyBossMods/DeadlyBossMods` `DBM-Core/DBM-Core.toc`: `## Interface: 11509, 16001, 20506, …`
   - `WoWUIDev/Ace3` `Ace3.toc`, `funkydude/BugSack` `BugSack.toc`, `Nevcairiel/Bartender4` `Bartender4.toc`, `Nevcairiel/HereBeDragons` `HereBeDragons.toc`: 모두 `16001` 포함
   - `Tercioo/Details-Damage-Meter` **`Details_Camelot.toc`**: `## Interface: 16001`
   - `Stanzilla/AdvancedInterfaceOptions` TOC: `16001` + 주석 `# WOW_INTERFACE_TARGETS: … forever, forever-beta, vanilla`
4. 공식 포럼의 플레이어 보고: "Client: 1.60.1 build 70862 (Nov 6 2026), toc 16001" https://us.forums.blizzard.com/en/wow/t/2405538 , "Client: 1.60.1.69913 (Interface 16001)" https://us.forums.blizzard.com/en/wow/t/2354798 , "the game version is 16001" https://us.forums.blizzard.com/en/wow/t/2403005
5. 버전 규칙상 1.60.1 → 1·60·01 = 16001 과 일치.

- 주의: 클래식 에라는 `11509`(1.15.9) 이다. **`115xx` 를 적으면 포에버에서 "구버전 애드온"으로 표시된다.** 한 팬 가이드는 어떤 애드온이 `11601` 로 잘못 적어 구버전 처리된 사례를 언급([추정], 검색 요약).
- [추정] 다음 패치(1.60.2 등)가 나오면 번호가 바뀐다. 여러 값을 쉼표로 나열할 수 있다(`## Interface: 16001, 16002`).

### 3.2 설치 폴더

- **[확인] `World of Warcraft\_forever_\`** — 애드온 경로 `…\_forever_\Interface\AddOns\<애드온폴더>\`, 설정 경로 `…\_forever_\WTF\`.
  - 근거: 공식 포럼 글 다수 — 스트레스 테스트 클라이언트가 "renamed itself to WoW Forever and has the `_forever_` folder" https://us.forums.blizzard.com/en/wow/t/2387920/126 (2026-10-22), 설정 이전 성공 보고 "…\World of Warcraft\_forever_\WTF\Account\…" https://us.forums.blizzard.com/en/wow/t/2386497/2 , 충돌 보고서의 실행 경로 `"C:\Games\World of Warcraft\_forever_\Wow.exe"` https://us.forums.blizzard.com/en/wow/t/2406253 . 팬 설치 가이드 다수도 일치(검색 요약).
  - 블리자드 고객지원 문서에는 아직 `_forever_` 가 적혀 있지 않다는 지적이 있음([추정], 검색 요약).
- [확인] 베타 때 폴더는 `_classic_beta_`(실행 파일 `WowB.exe`). 베타용 안내글의 경로를 그대로 믿으면 안 된다. https://us.forums.blizzard.com/en/wow/t/2386497
- [확인] 실행 파일은 `_forever_\Wow.exe`(위 충돌 보고서).
- [추정] WTF 구조: `WTF\Account\<계정>\SavedVariables\<애드온>.lua`(계정 공용), `WTF\Account\<계정>\<realm 폴더>\<이름-성>\SavedVariables\<애드온>.lua`(캐릭터별). 베타에서는 realm 폴더가 숫자(예: `70`)였다는 보고(같은 글). **라이브의 realm 폴더명은 [미확인].**

### 3.3 TOC 파일 접미사와 조건 지시문

- **[확인] 포에버 전용 TOC 접미사는 `_Camelot.toc`** (또는 `-Camelot.toc`). `_Forever.toc` 라는 접미사의 근거는 찾지 못했다.
  - 근거: `BigWigsMods/packager` `release.sh` 의 접미사 목록 `(Mainline|Classic|Vanilla|BCC|TBC|Wrath|WOTLKC|Cata|Mists|Camelot)`, `forever) new_file+="_Camelot.toc"`; 실제 사용 예 `Tercioo/Details-Damage-Meter/Details_Camelot.toc`; GitHub PR "Add WoW: Forever (Camelot) TOC files"(Ludovicus-Maior/WoW-Pro-Guides #3460, 검색 요약).
- [확인] 포에버는 **Mainline 패밀리**다: Ketho README `TOC [Family] => "Mainline"`, `TOC [Game] => "Camelot"`. 따라서
  - `[Family]` 경로 변수는 `Mainline` 으로, `[Game]` 은 `Camelot` 으로 치환된다.
  - [추정] `_Mainline.toc` 는 리테일과 포에버 **양쪽에서** 읽힌다(패키저가 `_Mainline` 에 retail·forever 인터페이스 번호를 모두 허용: "Special check for _Mainline (the "modern" game family) to allow retail (standard) and forever versions"). 우선순위는 `_Camelot.toc` > `_Mainline.toc` > 기본 `.toc` 로 추정.
  - [추정] `_Vanilla.toc`, `_Classic.toc` 는 포에버에서 **읽히지 않는다**(클래식 패밀리가 아님).
- [확인] 조건 지시문에서 쓰는 게임 타입 이름
  - `camelot` = 포에버만. 예: `ForeverOnly.lua [AllowLoadGameType camelot]` (packager README), `forever.lua [ExcludeLoadGameType standard, classic][AllowLoadGameType camelot]` (BugSack TOC)
  - `standard` = 리테일만, `mainline` = 리테일+포에버(패밀리), `classic` = 클래식 계열 전체, `vanilla` = 에라
  - 블리자드 자체 TOC 예: `[Family]\MinimapConstants.lua [AllowLoadGameType mainline] [ExcludeLoadGameType camelot]` (Gethe `forever` `Blizzard_Minimap.toc`)
  - [미확인] `forever` 라는 별칭이 게임 타입으로 인정되는지. Bartender4 는 `[AllowLoadGameType camelot, forever]` 로 둘 다 적어 둠(이름 변경 대비로 보임). **`camelot` 을 반드시 포함**할 것.
- 권장: 포에버 전용 애드온이면 **기본 `.toc` 하나에 `## Interface: 16001`** 만 적는 것이 가장 단순하다. 리테일도 지원하려면 인터페이스 번호를 쉼표로 추가하거나 `_Camelot.toc` 를 따로 둔다.

### 3.4 `WOW_PROJECT_ID`

- **[확인] `WOW_PROJECT_ID == 18`, 상수명 `WOW_PROJECT_CAMELOT`.**
  - 근거 1: Gethe `forever` 브랜치 `Interface/AddOns/Blizzard_ProjectConstants/Camelot/ProjectConstants.lua` — `WOW_PROJECT_CAMELOT = 18;` `WOW_PROJECT_ID = WOW_PROJECT_CAMELOT;` (TOC: `Camelot\ProjectConstants.lua [AllowLoadGameType camelot]`)
  - 근거 2: Ketho README — `WOW_PROJECT_ID => WOW_PROJECT_CAMELOT (18)`
  - 근거 3: warcraft.wiki.gg `WOW_PROJECT_ID` 문서가 "1.60.1 베타에서 `WOW_PROJECT_CAMELOT`(18) 추가"로 기술(검색 요약, 본문 직접 접근 실패)
- [확인] 포에버에서 정의되는 프로젝트 상수는 `WOW_PROJECT_MAINLINE = 1`, `WOW_PROJECT_CLASSIC = 2`, `WOW_PROJECT_CAMELOT = 18` 뿐(같은 폴더의 `ProjectConstants.lua`). `WOW_PROJECT_BURNING_CRUSADE_CLASSIC` 등은 **nil**.
- 함정: 포에버에서는 `WOW_PROJECT_ID == WOW_PROJECT_MAINLINE` 도 **false**, `== WOW_PROJECT_CLASSIC` 도 **false** 다. "리테일 아니면 클래식" 식의 분기는 포에버를 클래식으로 오판한다. 권장 판별:
  ```lua
  local IS_FOREVER = (WOW_PROJECT_CAMELOT ~= nil) and (WOW_PROJECT_ID == WOW_PROJECT_CAMELOT)
  ```
- [확인] `LE_EXPANSION_LEVEL_CURRENT == LE_EXPANSION_CLASSIC (0)`, `IsPublicBuild() == true`, `IsTestBuild() == false`, `IsBetaBuild() == false` (Ketho README).
- [추정] 팬 개발 가이드는 초기 베타 빌드 하나가 `1` 을 반환했다고 적음(검색 요약). 출시 후 덤프는 18.

### 3.5 배포 사이트의 게임 버전 태그

| 사이트 | 포에버 표기 | 태그 / 근거 |
|---|---|---|
| CurseForge | 게임 버전 종류 **"Forever"**(gameVersionTypeID `88568`), 버전 이름 `1.60.1` | [확인] `BigWigsMods/packager` `release.sh` `forever) game_id=88568`; 공식 포럼의 "Forever tab in Curseforge" 언급 https://us.forums.blizzard.com/en/wow/t/2401511 . CurseForge 사이트 자체는 접근 차단 |
| Wago Addons | `supported_forever_patches` | [추정] packager 가 게임 타입 이름을 그대로 키로 씀(`supported_${wago_type}_patches`). Wago 사이트 직접 확인 못 함 |
| WoWInterface | **포에버 게임 타입 없음** | [확인] packager: `titan|forever) echo "WARNING: No WoWInterface game type match…"` |
| BigWigs packager | `-g forever`(또는 `camelot`), 키워드 `@version-forever@` | [확인] `release.sh` |

---

## 4. 애드온 API 환경

### 4.1 리테일 API 이식은 사실인가 — **[확인] 사실**

1. **블리자드 발언**(1.4 인용). 2026-09-17 개발자 Q&A에서 리드 소프트웨어 엔지니어가 "modern API approach" 라고 했다는 인용도 있음([추정], 포럼 재인용 https://us.forums.blizzard.com/en/wow/t/2374157/217 ).
2. **소스 구조**: Gethe `forever` 브랜치에서 Camelot 전용 파일은 `[Game]` 폴더(`Camelot\…`)에 있고 공통 파일은 `Mainline\…` 를 쓴다. 예: `Blizzard_ActionBar` 는 `Camelot`, `Mainline`, `Shared`, `WoWLabs` 폴더만 있고 `Classic` 폴더가 없다. 편집 모드, 설정(Settings), 메뉴(MenuUtil), ScrollBox, 쿨다운 관리자, 데미지 미터 등 리테일 UI 모듈이 모두 들어 있다.
3. **API 문서 비교**(각 브랜치의 `Blizzard_APIDocumentationGenerated` 를 diff)
   - 문서 파일 수: forever 643 / 리테일 live(12.1.5) 623 / 에라 535 — 포에버는 리테일의 **상위 집합**(리테일보다 약간 최신, 12.1.7 계열에 가까움).
   - 위젯 문서 차이 줄 수(live ↔ forever / era ↔ forever): `SimpleTextureBaseAPI` 0 / 214, `SimpleFontStringAPI` 0 / 56, `SimpleAnimGroupAPI` 0 / 51, `SimpleFrameAPI` 4 / 246, `SoundDocumentation` 0 / 25, `UITimerDocumentation` 0 / 20, `UnitDocumentation` 153 / 1692. 즉 **리테일과는 거의 동일, 에라와는 크게 다르다.**
4. **실클라이언트 덤프**: Ketho `forever` `GlobalAPI.lua` 에 `C_Secrets`(27개 함수), `issecretvalue`, `canaccessvalue`, `canaccesstable`, `scrubsecretvalues`, `secretwrap`, `C_RestrictedActions`, `C_CurveUtil`, `C_DurationUtil`, `C_EncodingUtil` 등 한밤 12.x API 가 존재.
5. 커뮤니티: 인벤 포에버 게시판 "본섭 api 그대로 이식된다고 하니 기존 클래식의 애드온 상당수는 쓸 수 없게 됩니다 … 위크오라 핵심 기능인 스펠 추적이 일부를 제외하곤 전투중에 다 막히기 때문" https://www.inven.co.kr/board/wow/6567/17 (2026-09-16 15:10) — **처음 주어진 단서는 사실로 확인됨.** 공식 포럼의 애드온 개발자 발언 "wowf is using mainline's API, restrictions and all" https://us.forums.blizzard.com/en/wow/t/2348036/12 .

### 4.2 적용되는 제한

- [확인] **Secret values(비밀 값)**: 전투 관련 조회 API 가 "읽을 수 없는 값"을 돌려준다. 테인트된(= 애드온) 코드가 그 값을 비교·산술·문자열 연결하면 Lua 오류가 난다. 값은 `StatusBar:SetValue`, `FontString:SetText` 같은 표시용 API 에 넘기는 것만 가능.
  - 실제 라이브 오류 예: `attempt to compare local 'value' (a secret number value, while execution tainted by …)` — 공식 포럼 https://us.forums.blizzard.com/en/wow/t/2420339 (2026-11-18)
  - 문서상 플래그 예(Gethe `forever` `UnitDocumentation.lua`): `UnitHealth` = `SecretReturns`, `UnitClass`/`UnitRace`/`UnitGUID`/`UnitSex` = `SecretWhenUnitIdentityRestricted`, `UnitName` = `SecretWhenUnitNameIdentityRestricted`. **`UnitLevel`, `UnitFactionGroup`, `UnitExists`, `UnitAffectingCombat` 에는 secret 플래그가 없다.**
  - `SecretWhenUnitIdentityRestricted` 의 정의: "unit isn't player-controlled or in the party/raid" 일 때 비밀 값(`SecretPredicatesDocumentation.lua`). → `"player"` 자신에 대한 조회는 해당하지 않는다([추정]: 문서 해석, 클라이언트 확인 권장).
- [확인] **애드온 제한 상태 6종**(`Enum.AddOnRestrictionType`): Combat(0), Encounter(1), ChallengeMode(2), PvPMatch(3), Map(4, 던전·공격대 등 제한 맵), Chat(5). 조회 `C_RestrictedActions.IsAddOnRestrictionActive(type)`, 이벤트 `ADDON_RESTRICTION_STATE_CHANGED`. (`RestrictedActionsDocumentation.lua`, `RestrictedActionsConstantsDocumentation.lua`)
- [추정] 전투 로그는 애드온에 사실상 제공되지 않고, 인스턴스 안 채팅은 비밀 값으로 오며, 인스턴스 안에서 애드온이 /말·/외침·감정표현을 보낼 수 없다(팬 사이트 요약 + 포럼 질문 https://us.forums.blizzard.com/en/wow/t/2385926/3 ). 이벤트 이름 `COMBAT_LOG_EVENT_UNFILTERED` 자체는 이벤트 목록에 남아 있음(Ketho `Events.lua`).
- [확인] 제한은 계속 조여지는 중: 출시 후 미니맵 노드 읽기 차단(포럼 https://us.forums.blizzard.com/en/wow/t/2414151 , 2026-11-13), 생물 GUID 의 realm/서버/스폰 ID 난독화가 "upcoming 1.60.1 hotfix" 로 포에버에도 적용 예정(WoWUIDev 디스코드 공지 전재 https://us.forums.blizzard.com/en/wow/t/2423386 , 2026-11-20). 리테일 12.1.x 의 애드온 보안 변경이 포에버에도 따라온다.

### 4.3 순수 UI 애드온에 미치는 영향 — **거의 없음**(단, 아래 6가지는 지킬 것)

비밀 값은 "게임 상태를 조회하는 API 의 반환값"에만 붙는다. 자체 데이터(SavedVariables, 자체 난수, 자체 타이머)로 계산하는 시뮬레이션·인벤토리·제작 로직은 대상이 아니다. 프레임 생성·텍스처·폰트·타이머·슬래시 명령·저장은 전투 중에도 동작한다(보호되지 않은 애드온 프레임 기준). 블리자드 제한의 취지도 "전투 정보 기반 로직"을 막는 것이다(1.4 인용의 "addon disarmament").

지켜야 할 점:

1. **실제 유닛 수치(체력·자원·오라·주문 시전·위협 수준)를 읽어 계산에 쓰지 말 것.** 읽는 순간 비밀 값 오류 위험이 생긴다. 꼭 필요하면 `issecretvalue(v)` 로 먼저 검사.
2. **플레이어 기본 정보는 로그인 시 한 번만 읽어 캐시**(`PLAYER_LOGIN` 에서 `UnitFactionGroup("player")`, `UnitClass("player")`, `UnitLevel("player")`, `UnitRace("player")`). 전투·인스턴스 중 반복 조회를 피한다.
3. **블리자드 보호 프레임을 건드리지 말 것**(행동 단축바, 유닛 프레임, 이름표 등에 부모 지정·앵커·후킹 금지). 테인트가 번지면 기본 UI 가 전투 중 오류를 낸다. 자체 최상위 프레임을 `UIParent` 에 붙이는 것은 안전.
4. **키보드·마우스 입력 전파 설정은 전투 밖에서만 바꿀 것.** API 문서에서 `HasRestrictions = true` 가 붙은 프레임 메서드는 `SetPropagateKeyboardInput`, `SetPropagateMouseClicks`, `SetPropagateMouseMotion`, `SetPassThroughButtons` 4개뿐이다([확인] Gethe `forever` `SimpleFrameAPIDocumentation.lua`, `SimpleScriptRegionAPIDocumentation.lua` 를 전수 추출). [추정] 이들은 전투 중 애드온 코드에서 호출하면 차단된다 → 창을 만들 때(전투 밖) 한 번만 설정하고, 키보드 조작은 선택 기능으로 두며 마우스 조작을 기본으로 한다.
   - 참고: 같은 문서에서 `IsProtectedFunction = true` 는 `Show`, `Hide`, `SetShown`, `SetPoint`, `SetSize`, `SetScale`, `SetParent`, `EnableMouse`, `EnableKeyboard`, `StartMoving`, `StartSizing` 등 수십 개에 붙어 있다. 이것은 "**보호된(secure) 프레임에 대해** 전투 중 호출 금지"라는 기존 규칙의 표기이며, 애드온이 만든 일반 프레임에는 적용되지 않는다([추정]: `Show`/`SetPoint` 까지 포함된 점에서 도출한 해석. 부록 b-18 로 확인).
5. **채팅·애드온 통신에 의존하지 말 것.** 인스턴스/전투 중 `C_ChatInfo.SendChatMessage`·`SendAddonMessage` 는 제한된다(포럼 https://us.forums.blizzard.com/en/wow/t/2414922 ). 길드 순위표 같은 플레이어 간 동기화 기능은 "되면 좋고 안 되면 무시" 수준으로.
6. **제거된 구식 전역 함수를 쓰지 말 것**(4.5).

### 4.4 포에버 고유 주의점: 캐릭터 이름과 realm

- [확인] 포에버에서 `UnitName(unit)` 의 두 번째 반환값은 **성(surname)** 으로 쓰인다. `Blizzard_FrameXMLUtil/Camelot/NameUtil.lua`:
  ```lua
  local name, surname = UnitName(unit);
  if (surname) then return name..Constants.CharacterNameSeparatorConsts.CHARACTERNAME_SURNAME_SEPARATOR..surname; end
  ```
  (API 문서 표기는 여전히 `unitName, unitServer`.) 관련 전역: `UnitNameUnmodified`, `RegionalUniqueNamesEnabled()`, `UnitFullName`, `GetNormalizedRealmName` 모두 존재(Ketho `GlobalAPI.lua`).
- [미확인] `GetRealmName()` / `GetNormalizedRealmName()` 이 서버 없는 구조에서 무엇을 돌려주는지(규칙 이름? 내부 realm 이름? 포럼 보고에는 "CAMWOW US2 Realm 11 RP" 같은 내부 이름이 보임 https://us.forums.blizzard.com/en/wow/t/2405538 ).
- 권장: 캐릭터별 데이터 키는 `"이름-서버"` 문자열 대신 **`UnitGUID("player")`** 를 쓰거나, 아예 `## SavedVariablesPerCharacter` 에 맡긴다.

### 4.5 API·기능별 사용 가능 여부

근거 약어: **[G]** = Ketho `forever` `Resources/GlobalAPI.lua`(실클라이언트 전역 함수 덤프, 빌드 70938) / **[W]** = 같은 저장소 `WidgetAPI.lua`(위젯 메서드·스크립트 핸들러 덤프) / **[S]** = Gethe `forever` 브랜치 소스(빌드 71037) / **[D]** = 같은 브랜치 `Blizzard_APIDocumentationGenerated`

| API / 기능 | 사용 | 주의점 | 태그·근거 |
|---|---|---|---|
| `CreateFrame` | 가능 | 위젯 타입: Frame, Button, CheckButton, EditBox, Slider, StatusBar, ScrollFrame, GameTooltip, PlayerModel, Model, ModelScene, DressUpModel, Cooldown, ColorSelect, MessageFrame, SimpleHTML 등 | [확인] [G][W] |
| `BackdropTemplate` / `BackdropTemplateMixin` | 가능 | `Frame:SetBackdrop` 은 **기본 메서드가 아니다**(Frame 위젯 메서드 목록에 없음). `CreateFrame("Frame", nil, parent, "BackdropTemplate")` 로 상속해야 `SetBackdrop`/`SetBackdropColor` 가 생긴다 | [확인] [S] `Blizzard_SharedXML/Backdrop.lua`·`.xml`, [W] |
| `Texture:SetColorTexture(r, g, b [, a])` | 가능 | | [확인] [D][W] |
| `Texture:SetAtlas(atlas, useAtlasSize, filterMode, resetTexCoords, wrapH, wrapV)` | 가능 | 아틀라스 이름은 **리테일 것**(예: `ui-hud-minimap-addon-indicator`). 존재 확인은 `C_Texture.GetAtlasInfo(name)` / `C_Texture.GetAtlasExists`. 포에버용 전체 목록: Ketho `Resources/AtlasInfo.lua`(약 2.6만 줄) | [확인] [D][G] |
| `Texture:SetGradient(orientation, minColor, maxColor)` | 가능 | **색은 colorRGBA 객체 2개**(`CreateColor(r,g,b,a)`). 구식 8숫자 시그니처·`SetGradientAlpha` 는 **없음** | [확인] [D] `SimpleTextureBaseAPIDocumentation.lua`, [W](SetGradientAlpha 부재) |
| MaskTexture | 가능 | `Frame:CreateMaskTexture()`, `Texture:AddMaskTexture(mask)` / `RemoveMaskTexture`, `MaskTexture:SetTexture/SetAtlas` | [확인] [D][W] |
| AnimationGroup | 가능 | `CreateAnimationGroup`, `CreateAnimation("Alpha"/"Translation"/"Scale"/"Rotation"/"FlipBook"/"VertexColor"/"Path"…)`, `SetLooping`, `SetToFinalAlpha`, 핸들러 OnPlay/OnFinished/OnLoop/OnStop/OnPause/OnUpdate | [확인] [W] |
| `C_Timer.After(seconds, cb)` / `NewTimer` / `NewTicker(seconds, cb, iterations)` | 가능 | 티커 객체 `:Cancel()`. 로딩 화면·백그라운드에서도 프레임 단위로 처리되므로 "방치 보상"은 타이머 누적이 아니라 **저장된 시각 차이**로 계산할 것 | [확인] [D] `UITimerDocumentation.lua`, [G] |
| `OnUpdate` | 가능 | Frame·AnimationGroup 모두 지원. 숨겨진 프레임은 OnUpdate 가 돌지 않음(일반 동작) | [확인] [W] |
| ScrollBox / ScrollUtil | 가능 | `WowScrollBoxList`, `MinimalScrollBar`, `WowTrimScrollBar`, `ScrollUtil.InitScrollBoxListWithScrollBar`, `CreateScrollBoxListLinearView`, `CreateDataProvider` | [확인] [S] `Blizzard_SharedXML/Shared/Scroll/*` |
| `FauxScrollFrameTemplate` / `UIPanelScrollFrameTemplate` | 가능(구식이지만 남아 있음) | `FauxScrollFrame_Update` 포함. 신규 코드는 ScrollBox 권장 | [확인] [S] `Blizzard_SharedXML/SecureScrollTemplates.lua`·`.xml` |
| `Settings` API | 가능 | `Settings.RegisterCanvasLayoutCategory(frame, name)` → `Settings.RegisterAddOnCategory(category)` → `Settings.OpenToCategory(category:GetID())`. 세로 레이아웃: `RegisterVerticalLayoutCategory`, `RegisterAddOnSetting`, `Settings.CreateCheckbox/CreateDropdown` 등 | [확인] [S] `Blizzard_Settings_Shared/Blizzard_Settings.lua` |
| `InterfaceOptions_AddCategory`, `InterfaceOptionsFrame_OpenToCategory` | **없음** | Settings API 로 대체 | [확인] [S] 정의 없음, [G] 부재 |
| AddonCompartment(미니맵 애드온 서랍) | 가능 | TOC 필드 `## AddonCompartmentFunc: 전역함수이름`, `## AddonCompartmentFuncOnEnter`, `## AddonCompartmentFuncOnLeave`, 아이콘은 `## IconTexture` 또는 `## IconAtlas`. 포에버 전용 배치(`GameTimeFrame` 아래)·스킨 있음. [미확인] "클래식" 사전 설정 UI 배치에서도 버튼이 보이는지 | [확인] [S] `Blizzard_Minimap/Mainline/AddonCompartment.lua` + `Blizzard_Minimap/Camelot/AddonCompartment.lua`·`.xml` |
| 미니맵 버튼(LibDBIcon) | 가능 | 포에버를 지원하는 BugSack 이 포에버 경로에서도 조건 없이 `LibStub("LibDBIcon-1.0"):Register(addonName, plugin, BugSackLDBIconDB)` 를 호출하고, 애드온 서랍 연동(`ldbi:IsButtonCompartmentAvailable()`, `AddButtonToCompartment`)도 쓴다. LibDBIcon 본체는 WowAce SVN(`repos.wowace.com/wow/libdbicon-1-0`)에 있어 본체 코드는 직접 확인 못 함. `Minimap` 프레임·`MinimapButtonTemplate`(camelot 로드) 존재. 외부 라이브러리 없이 하려면 AddonCompartment TOC 필드 + 슬래시 명령만으로도 진입점은 충분 | [확인] 사용 예: `funkydude/BugSack` `ldb.lua`·`config.lua`·`.pkgmeta`(2026-11-22 raw 조회), [S] `Blizzard_Minimap.toc` / [추정] 본체 내부 동작 |
| `SlashCmdList` | 가능 | 전통 방식 그대로: `SLASH_MYADDON1 = "/wih"`, `SlashCmdList["MYADDON"] = function(msg, editBox) … end`. 소스 주석: "must at present remain global tables, as there exists a lot of addon code that is directly accessing these tables" | [확인] [S] `Blizzard_ChatFrameBase/Shared/SlashCommandsRegistry.lua` |
| `C_AddOns` | 가능(29개 함수) | `C_AddOns.GetAddOnMetadata(name, field)`, `IsAddOnLoaded`, `LoadAddOn`, `GetNumAddOns`, `GetAddOnInfo`, `GetAddOnEnableState`… **구 전역 `GetAddOnMetadata`/`IsAddOnLoaded`/`LoadAddOn`/`GetNumAddOns`/`GetAddOnInfo`/`EnableAddOn` 은 없음** | [확인] [G][D] |
| SavedVariables / SavedVariablesPerCharacter | 가능 | TOC `## SavedVariables: A, B` / `## SavedVariablesPerCharacter: C`. `## LoadSavedVariablesFirst: 1` 도 사용 예 있음(BugSack). **베타 초기(2026-09-17~24, 빌드 69893~69977)에 "저장은 되는데 다시 읽히지 않는" 버그가 있었고 9월 24~25일 패치로 해결**됐다는 다수 보고 https://us.forums.blizzard.com/en/wow/t/2353992 , https://us.forums.blizzard.com/en/wow/t/2354798 . 출시 후 재발 보고는 찾지 못함 | [확인] 기능 존재·베타 버그와 해결 / [추정] 라이브 정상(직접 실행 확인은 아님) |
| 저장 타이밍(`ADDON_LOADED`, `PLAYER_LOGOUT`) | 가능 | 이벤트·페이로드: `ADDON_LOADED(addOnName, containsBindings)` — 자기 애드온 이름일 때 저장 변수 준비됨, `PLAYER_LOGIN`, `PLAYER_ENTERING_WORLD(isInitialLogin, isReloadingUi)`, `PLAYER_LEAVING_WORLD`, **`PLAYER_LOGOUT`**(저장 직전 마지막 정리 기회), `ADDONS_UNLOADING(closingClient)`, `SAVED_VARIABLES_TOO_LARGE(addOnName)`. [추정] 파일 기록은 로그아웃·종료·`/reload` 때만 일어나고 **클라이언트 충돌·강제 종료 시에는 기록되지 않는다**(일반적인 WoW 동작; 포에버는 충돌 보고가 많으므로 손실 허용 설계 필요) | [확인] 이벤트 존재 [D] `AddOnsDocumentation.lua`·`SystemDocumentation`, Ketho `Events.lua` / [추정] 기록 시점 |
| `time()`, `date()`, `GetTime()`, `GetServerTime()`, `debugprofilestop()` | 가능 | 추가로 `GetTimePreciseSec()`, `GetSessionTime()`, `GetGameTime()`, `C_DateAndTime.GetCurrentCalendarTime()`, `C_DateAndTime.GetServerTimeLocal()`, `C_DateAndTime.GetSecondsUntilDailyReset()`. 오프라인 진행 계산은 PC 시계(`time()`) 조작에 취약 → `GetServerTime()` 권장 | [확인] [G] |
| `UnitFactionGroup("player")` | 가능 | 시그니처 `(unitName, checkDisplayRace=false)` → `factionGroupTag, localized`. secret 플래그 없음. [추정] 스카이본도 생성 때 고른 진영에 따라 `"Alliance"`/`"Horde"` | [확인] [D][G] |
| `UnitClass("player")` | 가능 | → `className, classFilename, classID`. `SecretWhenUnitIdentityRestricted`(자기 자신은 해당 없음으로 해석). 직업 판별은 지역화되지 않는 `classFilename`(예: `"PALADIN"`) 사용 | [확인] [D] / [추정] player 비해당 |
| `UnitLevel("player")` | 가능 | secret 플래그 없음. 최대 레벨은 `GetMaxPlayerLevel()` 존재 | [확인] [D][G] |
| `UnitRace("player")` | 가능 | → `localizedRaceName, englishRaceName, raceID`. [추정] 스카이본의 영문 파일명은 `"Skyborne"`(튜토리얼 테이블 키), 언데드는 `"Scourge"` | [확인] [D] / [추정] 값 |
| 프레임 리사이즈 | `SetResizeBounds(minW, minH [, maxW, maxH])` | **`SetMinResize`/`SetMaxResize` 는 없음.** `SetResizable(true)`, `StartSizing(point)`, `StopMovingOrSizing()`, 템플릿 `PanelResizeButtonTemplate`, `PanelDragBarTemplate` | [확인] [W](부재 확인), [D], [S] |
| `GameTooltip` | 가능 | `SetOwner`, `AddLine`, `AddDoubleLine`, `SetText`, `ClearLines`, `AddTexture`, `Show/Hide`. `SetHyperlink`·`SetItemByID`·`SetSpellByID` 등 데이터형 메서드는 Lua 계층(`TooltipDataHandler`, `C_TooltipInfo`)으로 구현됨. 자체 내용 툴팁은 `AddLine` 계열만 쓰면 충분. 템플릿 `GameTooltipTemplate`, `SharedTooltipTemplate` | [확인] [W], [S] `Blizzard_SharedXMLGame/Tooltip/TooltipDataHandler.lua` |
| `PlayerModel` 로 생물 표시 | 가능 | `SetCreature(creatureID [, displayID])`, `SetDisplayInfo(displayID [, mountDisplayID])`, `SetUnit(unit)`(`RequiresDeclassifiedUnitIdentity`), `SetModel(fileAsset)`, `SetPortraitZoom`, `SetCamDistanceScale`, `SetFacing`, `SetPosition`, `SetAnimation`, `FreezeAnimation`, `SetKeepModelOnHide`, `ClearModel`. [미확인] 특정 생물 ID/표시 ID 가 포에버 데이터에 있는지와 캐시 안 된 생물의 `SetCreature` 동작 → `SetDisplayInfo` 가 더 안전 | [확인] [D] `FrameAPICharacterModelBaseDocumentation.lua`, [W] |
| `ModelScene` | 가능 | `CreateActor()` → `actor:SetModelByCreatureDisplayID(id)`, `SetModelByFileID`, `SetAnimation`, `SetYaw/SetPosition/SetScale`. 템플릿 `ModelSceneMixinTemplate`, `PanningModelSceneMixinTemplate` | [확인] [D][W][S] |
| `PlaySound(soundKitID [, channel, forceNoDuplicates, runFinishCallback])` | 가능 | 포에버에서는 `PlaySound = C_Sound.PlaySound` 별칭. 채널 문자열 `"Master"`, `"SFX"`, `"Music"`, `"Ambience"`, `"Dialog"` 사용 예 유지. 사운드킷 상수는 `SOUNDKIT.*`(리테일 목록). 반환 `success, soundHandle`; 정지 `StopSound(handle)` | [확인] [S] `Blizzard_SharedXML/Mainline/Sound.lua`, [G] |
| `PlaySoundFile(pathOrFileID [, channel])` | 가능 | 전역 함수 존재. 블리자드 UI 코드에서는 사용처 0건(애드온용 비문서 함수)이지만, 포에버 지원 애드온 BugSack 이 `PlaySoundFile(sound, "Master")` 를 그대로 쓴다. 애드온 폴더의 `.ogg`/`.mp3` 재생은 [추정] | [확인] 존재 [G], 사용 예 `funkydude/BugSack` `core.lua` / [추정] 형식 |
| 문자열·인코딩 유틸 | 가능 | `strlenutf8`, `strcmputf8i`, `strsplit`, `strjoin`, `strtrim`, `format`, `C_StringUtil.*`, **`C_EncodingUtil.CompressString/DecompressString/EncodeBase64/DecodeBase64/SerializeCBOR/DeserializeCBOR/SerializeJSON/DeserializeJSON`**(세이브 내보내기·가져오기 문자열에 유용). **`utf8sub` 는 없음** → 한글 부분 문자열은 직접 구현 필요 | [확인] [G] |
| 믹스인·유틸 | 가능 | `Mixin`, `CreateFromMixins`, `CreateFramePool`, `CallbackRegistryMixin`, `EventRegistry`, `CopyTable`, `tInvert`, `Clamp`, `Lerp`, `CreateColor`, `RunNextFrame`, `GenerateClosure`, `SecondsToTime`, `FormatLargeNumber`, `AbbreviateNumbers`, `BreakUpLargeNumbers`, `GetMoneyString`, `StaticPopup_Show`/`StaticPopupDialogs`, `UISpecialFrames`(ESC 로 닫기), `MenuUtil.CreateContextMenu`, `UIDropDownMenu_*`(구식, 아직 있음) | [확인] [G][S] |
| 프레임 템플릿 | 가능 | `ButtonFrameTemplate`, `PortraitFrameTemplate`, `BasicFrameTemplate`, `BasicFrameTemplateWithInset`, `DefaultPanelTemplate`, `InsetFrameTemplate`, `UIPanelButtonTemplate`, `UIPanelCloseButton`, `UICheckButtonTemplate`, `InputBoxTemplate`, `PanelTabButtonTemplate`, `TabSystemTemplate`, `WowStyle1DropdownTemplate` | [확인] [S] |

**없어진(쓰면 nil 오류가 나는) 구식 전역** — [확인] [G] 덤프에 부재

| 구식 | 대체 |
|---|---|
| `GetAddOnMetadata`, `IsAddOnLoaded`, `LoadAddOn`, `GetNumAddOns`, `GetAddOnInfo`, `EnableAddOn` | `C_AddOns.*` |
| `GetItemInfo`, `GetItemIcon` | `C_Item.GetItemInfo`, `C_Item.GetItemIconByID`, `C_Item.GetItemInfoInstant` |
| `GetSpellInfo`, `GetSpellTexture` | `C_Spell.GetSpellInfo`(테이블 반환), `C_Spell.GetSpellTexture`, `C_Spell.GetSpellName` |
| `SendChatMessage`, `SendAddonMessage` | `C_ChatInfo.SendChatMessage`, `C_ChatInfo.SendAddonMessage` |
| `GetMouseFocus` | `GetMouseFoci()`(테이블 반환) |
| `GetCoinTextureString` | `C_CurrencyInfo.GetCoinTextureString` |
| `InterfaceOptions_AddCategory`, `InterfaceOptionsFrame_OpenToCategory` | `Settings.*` |
| `EasyMenu`, `message`, `SetPortraitToTexture`, `RunMacroText` | `MenuUtil.*`, `print`/`StaticPopup`, `Texture:SetTexture`+마스크, (대체 없음) |
| `Frame:SetMinResize`, `Frame:SetMaxResize`, `Texture:SetGradientAlpha` | `SetResizeBounds`, `SetGradient`(색 객체) |
| `getglobal`, `setglobal` | `_G[name]`. 블리자드 폴백(`Blizzard_Deprecated/Shared/Deprecated_12_1_0.lua`)은 CVar `loadDeprecationFallbacks`(덤프상 기본값 `"1"`)가 켜져 있을 때만 정의되고, Ketho 함수 덤프에는 보이지 않음 → **의존 금지** ([미확인] 실제 존재 여부) |

- [추정] 베타 테스터 보고: `GetItemStats`, `GetZonePVPInfo`, `UnitCharacterPoints`, `GetItemCooldown`, `GetNumSpellTabs`, `UnitMaxHealth` 는 nil, `math.randomseed` 도 nil. 난수는 `math.random`/`random`/`fastrandom` 사용. https://us.forums.blizzard.com/en/wow/t/2385926 (2026-10-18)

### 4.6 문자열 길이·테이블·저장 파일 크기

- [확인] `SAVED_VARIABLES_TOO_LARGE(addOnName)` 이벤트가 존재한다(저장 변수가 너무 커서 로드에 실패했음을 알림). 임계값은 문서에 없음 → [미확인].
- [확인] `C_EncodingUtil` JSON/CBOR 역직렬화는 메모리 증가 제한이 걸린다(12.1.7 PTR 공지 전재: "malformed or oversized payloads no longer crash the client") https://us.forums.blizzard.com/en/wow/t/2423386
- [추정] 일반적으로 알려진 한계(이번 조사에서 포에버 기준으로 재확인하지 못함): 채팅/애드온 메시지 255바이트, 매크로 255자, EditBox 는 `SetMaxLetters`/`SetMaxBytes` 로 제한, Lua 문자열 자체에는 실질 한계 없음, 저장 파일은 통째로 Lua 청크로 읽히므로 수 MB 를 넘기면 로그인 로딩이 눈에 띄게 느려짐.
- 설계 권고: 로그·통계는 상한을 둔 링 버퍼로, 인벤토리는 `{id, 수량}` 같은 작은 구조로, 문자열 키 대신 숫자 인덱스를, 버전 필드(`db.version`)로 마이그레이션을, 저장 직전(`PLAYER_LOGOUT`)에 파생 캐시는 지우기.

---

## 5. 리소스

### 5.1 내장 텍스처·아이콘·사운드 참조

- [확인] 애드온은 클라이언트 내장 자산을 **경로 문자열 또는 fileID** 로 참조할 수 있다. `Texture:SetTexture(textureAsset, …)`, `GetFileIDFromPath(path)`, `C_Texture.GetFilenameFromFileDataID(id)` 존재([D][G]). TOC 에서도 `## IconTexture: 134521` 처럼 fileID 를 쓴다(AdvancedInterfaceOptions TOC).
- [확인] 아이콘 조회 API: `C_Item.GetItemIconByID(itemID)`, `C_Spell.GetSpellTexture(spellID)`(fileID 반환).
- [추정] 포에버는 오리지널 주문·아이템이 실제 게임 데이터로 들어 있으므로 해당 아이콘 파일은 클라이언트에 있다. 다만
  - [미확인] `Interface\Icons\INV_Sword_04` 같은 **경로 이름으로의 조회가 포에버 클라이언트에서 전부 해석되는지**, 리테일 전용(오리지널 이후) 아이콘까지 포함돼 있는지. → 사용할 아이콘 목록을 정한 뒤 클라이언트에서 일괄 검증(부록 b). 깨지면 물음표 아이콘(`Interface\Icons\INV_Misc_QuestionMark`)으로 대체하는 방어 코드 권장.
  - [추정] 일부 클래식 주문이 신·구 두 ID 로 중복 존재하고 포에버 전용 기술은 높은 ID 대역(예: 1259705)을 쓴다는 베타 보고(포럼 t/2385926). 주문 ID 를 키로 쓰면 중복 주의.
- [확인] 내장 사운드는 `PlaySound(SOUNDKIT.XXX)` 로 재생. 상수 목록은 `Blizzard_SharedXML/Mainline/SoundKitConstants.lua`(리테일 목록, 포에버 항목 추가됨 예: `AMB_GLUESCREEN_SKYBORNE = 356655`).
- [추정] 클래식 시절처럼 `Sound\` 폴더에 파일을 넣어 내장 사운드를 덮어쓰는 방식은 더 이상 동작하지 않는다는 보고 https://us.forums.blizzard.com/en/wow/t/2380439/13

### 5.2 koKR 기본 폰트 — [확인] Gethe `forever` 브랜치 `Interface/AddOns/Blizzard_Fonts_Shared/Shared/GameFonts.xml`, `Mainline/Fonts.xml`

```lua
if (LOCALE_koKR) then
    STANDARD_TEXT_FONT = "Fonts\\2002.TTF";
    UNIT_NAME_FONT     = "Fonts\\2002B.TTF";
    DAMAGE_TEXT_FONT   = "Fonts\\K_Damage.TTF";
```

| 용도 | koKR 폰트 파일 |
|---|---|
| 기본 UI 글꼴(`STANDARD_TEXT_FONT`, 대부분의 `GameFont*`/`SystemFont_*` 의 korean 멤버) | `Fonts\2002.TTF` |
| 유닛 이름(`UNIT_NAME_FONT`) | `Fonts\2002B.TTF` |
| 전투 숫자(`DAMAGE_TEXT_FONT`) | `Fonts\K_Damage.TTF` |
| 퀘스트·책 본문(`QuestFont` 계열의 korean 멤버) | `Fonts\K_Pagetext.TTF` |
| 참고: 영문 `Fonts\FRIZQT__.TTF`, `ARIALN.TTF`, `MORPHEUS.TTF`, `skurri.ttf` / 간체 `ARKai_T.ttf` / 번체 `blei00d.TTF` / 러시아 `FRIZQT___CYR.TTF` | |

한글 표시 주의점
- [확인] 블리자드 글꼴 객체는 `<FontFamily>` 안에 알파벳별 멤버(roman / korean / simplifiedchinese / traditionalchinese / russian)를 둔다. **`GameFontNormal`, `GameFontHighlight`, `SystemFont_Shadow_Med1` 같은 글꼴 객체를 상속(`SetFontObject`)하면 로캘에 맞는 파일이 자동 선택**된다.
- [추정] `fontString:SetFont("Fonts\\FRIZQT__.TTF", 12)` 처럼 영문 폰트를 직접 지정하면 koKR 에서 한글이 네모(□)로 나온다. 직접 지정해야 하면 `STANDARD_TEXT_FONT` 전역을 쓴다.
- [확인] 길이 계산: `#str`/`string.len` 은 바이트 수(한글 1자 = UTF-8 3바이트). 글자 수는 `strlenutf8`. `utf8sub` 가 없으므로 자르기는 직접 구현하거나 `FontString:SetWordWrap`/`SetMaxLines`/`SetWidth` 로 표시 단계에서 처리. EditBox 는 `SetMaxLetters`(글자) 와 `SetMaxBytes`(바이트)가 따로 있다.
- [추정] 한글은 띄어쓰기 없이 길게 이어질 수 있으므로 `FontString:SetNonSpaceWrap(true)` 가 필요할 수 있다(메서드 존재는 [확인] [W]).
- [추정] 한글 폰트는 같은 포인트 크기에서 영문보다 크게 보인다 → 레이아웃을 고정 픽셀 폭으로 짜지 말고 `GetStringWidth()` 기반으로.
- [확인] 로캘 문자열 분리: TOC 에서 `Localization\[TextLocale].lua` 경로 변수와 `[AllowLoadTextLocale koKR]` 지시문 사용 가능(packager README 예시), TOC 메타데이터 `## Title-koKR:`, `## Notes-koKR:`, `## Category-koKR:` 사용 예(BugSack TOC).

### 5.3 애드온에 포함하는 자체 텍스처·폰트의 형식 제약

이 절은 포에버 기준 1차 근거를 확보하지 못했다(warcraft.wiki.gg 본문 접근 실패 → 검색 요약만 사용). 포에버가 리테일과 같은 Mainline 엔진이라는 점(4.1)에 기대어 리테일 문서를 적용한 것이므로 전부 [추정]이며 부록 b-14 로 확인해야 한다.

- [추정] 형식: warcraft.wiki.gg `API_TextureBase_SetTexture` 문서(검색 요약, 2026-11-22 조회) — "Custom images must be in **BLP, JPEG, PNG, or TGA** format with **power-of-two dimensions**"(예: 16x16, 8x32, 256x64). TGA 는 8bpp 그레이스케일 / 24bpp RGB / 32bpp RGBA, RLE 압축 지원. https://warcraft.wiki.gg/wiki/API_TextureBase_SetTexture
  - PNG 지원은 리테일 10.0.7(2023-03-21)에서 추가됐다는 기록(구 wowpedia 문서, 검색 요약). 포에버는 12.1.x 계열 엔진이므로 PNG·JPEG 도 될 가능성이 높지만 **포에버에서 직접 확인된 근거는 없다.** 안전하게 가려면 32비트 TGA(알파 포함)를 기본으로 하고, PNG 는 클라이언트 확인 후 채택.
- [추정] 가로·세로는 **2의 거듭제곱**(정사각일 필요는 없음: 512x256 가능). 어기면 로드 실패(초록색 사각형). 최대 크기는 출처마다 다름(1024 라는 옛 문서, 2048 에서 문제가 있었다는 포럼 글) → **1024 이하로 유지** 권장, 그 이상은 [미확인].
- [확인] 경로 형식: `Interface\AddOns\<애드온폴더>\<경로>\파일`(확장자 생략 가능). 사용 예 `## IconTexture: Interface\AddOns\BugSack\Media\icon`.
- [추정] 클라이언트 실행 중에 새로 추가한 파일은 `/reload` 로는 인식되지 않고 **클라이언트 재시작**이 필요하다.
- [추정] 여러 장의 스프라이트는 한 장의 아틀라스 TGA 로 묶고 `SetTexCoord` 로 잘라 쓰는 편이 로딩·메모리에 유리. `Texture:SetSpriteSheetCell` 메서드도 존재([확인] [W]).
- [추정] 폰트는 TTF/OTF 를 애드온 폴더에 넣고 `SetFont("Interface\\AddOns\\…\\font.ttf", size, flags)` 로 지정. 한글 글리프가 있는 폰트여야 하며 재배포 라이선스 확인 필요(나눔 계열 등 OFL). 블리자드 내장 `2002.TTF` 를 쓰면 포함할 필요가 없다.
- [추정] 사운드는 OGG(또는 MP3). 저작권 있는 음원 배포 금지(6절 2009-07-15 공지).

---

## 6. 블리자드 애드온 정책

### 6.1 공식 정책 원문 — [확인]

"World of Warcraft User Interface Add-On Development Policy", 공식 포럼 고정 글(커뮤니티 매니저 Kaivax 게시 2018-11-19, 원 정책은 2009-03-20 발표)
https://us.forums.blizzard.com/en/wow/t/ui-add-on-development-policy/24534

1. **무료여야 한다.** 유료 다운로드, 유료 "프리미엄" 버전, 애드온 관련 유료 서비스, 다운로드·접근 대가 요구 모두 금지.
2. **코드가 완전히 공개돼야 한다.** 숨기거나 난독화 금지.
3. **서버나 다른 플레이어에게 악영향을 주면 안 된다.** 예: 채팅 시스템 과다 사용, 불필요한 디스크 로딩, 프레임 저하.
4. **광고 금지.** 어떤 상품·서비스도 광고할 수 없다.
5. **게임 안에서 후원(기부) 요청 금지.** 후원 요청은 애드온 웹사이트·배포 사이트에서만.
6. **불쾌하거나 부적절한 내용 금지.** ESRB "T" 등급에서 허용되지 않는 내용 불가.
7. **WoW 이용 약관(ToU)·EULA 준수.**
8. **블리자드는 언제든 애드온 기능을 비활성화할 수 있다.**
- 부속 공지(2009-07-15): 게임 음악·음성 등 저작물을 애드온으로 무단 배포하는 것은 불법.
- 문의처: WoWUI@blizzard.com

### 6.2 현재 집행 분위기 — [확인] 논란 존재 / [추정] 블리자드 입장

- 포에버 출시 전후(2026-10) 유료 레벨링 가이드 애드온(RestedXP, Journey)에 대한 정책 집행 요구 글이 공식 포럼에 다수 올라옴. 예: https://us.forums.blizzard.com/en/wow/t/2391909 , https://us.forums.blizzard.com/en/wow/t/2395596 , https://us.forums.blizzard.com/en/wow/t/2388653 . 블리자드 직원의 새 정책 발표는 찾지 못함([미확인]).
- 정책 문구 자체는 2009년판이 그대로 유효한 것으로 인용되고 있다.

### 6.3 애드온 내부 미니게임에 해당되는 제약

- [확인] 미니게임을 명시적으로 금지하는 조항은 없다. (정책 8개 조항 전문 확인)
- 정책에서 직접 도출되는 제약
  - 유료 재화, 유료 해금, "후원하면 보상" 문구, 후원 링크 출력 금지(1·5조). 게임 내 화면에 "후원/도네이션" 버튼을 두면 안 된다.
  - 다른 게임·서비스·디스코드 홍보 배너 금지로 해석될 수 있음(4조). [추정] 저장소 주소 한 줄 표기는 관행상 흔하지만 최소화가 안전.
  - 코드 난독화·압축(minify) 배포 금지(2조). 빌드 산출물도 읽을 수 있는 Lua 여야 한다.
  - 채팅 자동 출력·애드온 통신 남용 금지(3조). 자동 전투 로그를 `print` 로 매 틱 쏟아내는 것도 피할 것(자체 창에 표시).
  - 선정적·과도한 폭력 표현 금지(6조).
- [추정] 정책 문구에는 없지만 약관(7조)과 관련해 주의할 점
  - 실제 골드·아이템을 걸고 다른 플레이어와 하는 도박성 기능(주사위 내기 중개 등)은 계정 제재 사례가 알려져 있다 → 미니게임 재화는 **전부 가상**이고 실제 게임 자산·거래와 연결하지 않는다.
  - 플레이어 입력 없이 실제 게임 행동(이동·전투·거래)을 자동화하는 것은 약관 위반이지만, 본 애드온은 실제 게임을 건드리지 않으므로 해당 없음. 애드온 창 안의 "방치형 자동 전투"는 자체 시뮬레이션일 뿐이다.
  - 블리자드 상표·아트 재사용: 내장 아이콘·모델을 **클라이언트 안에서 참조**하는 것은 일반적 관행이나, 추출한 블리자드 자산 파일을 애드온에 넣어 재배포하면 안 된다(2009-07-15 공지 취지).

---

## 7. 개발·테스트 도구

### 7.1 이번 조사에서 직접 확인한 것 — [확인]

| 도구·자료 | 내용 | 주소 |
|---|---|---|
| **공식 UI 소스 미러** | `Gethe/wow-ui-source` **`forever` 브랜치**. 빌드마다 자동 갱신(2026-11-20 `1.60.1 (71037)`). 2026-11-21 기준 브랜치 목록: `live`, `ptr`, `ptr2`, `beta`, `forever`, `classic`, `classic_ptr`, `classic_beta`, `classic_era`, `classic_era_ptr`, `classic_anniversary`, `classic_titan`, `automation` | https://github.com/Gethe/wow-ui-source/tree/forever |
| **실클라이언트 API 덤프** | `Ketho/BlizzardInterfaceResources` **`forever` 브랜치**: `Resources/GlobalAPI.lua`(전역 함수 약 7,000개), `WidgetAPI.lua`, `Events.lua`, `CVars.lua`, `LuaEnum.lua`, `Mixins.lua`, `Templates.lua`, `Frames.lua`, `FrameXML.lua`, `AtlasInfo.lua`, `GlobalStrings/koKR.lua` 등 | https://github.com/Ketho/BlizzardInterfaceResources/tree/forever |
| **게임 내 API 문서** | `Blizzard_APIDocumentation`·`Blizzard_APIDocumentationGenerated` 가 포에버 클라이언트에 포함 → 게임 안에서 `/api` 명령으로 검색([추정]: 명령 동작은 리테일과 같을 것) | Gethe `forever` 브랜치 `Interface/AddOns/Blizzard_APIDocumentation*` |
| **패키징** | `BigWigsMods/packager`(`release.sh`)가 포에버 지원: `-g forever`, `_Camelot.toc` 생성, CurseForge/Wago 업로드 | https://github.com/BigWigsMods/packager |
| **오류 수집** | BugSack(+!BugGrabber)이 16001 지원 | https://github.com/funkydude/BugSack |
| 게임 내 오류 표시 | `/console scriptErrors 1` (포럼 사용 예) | https://us.forums.blizzard.com/en/wow/t/2420339 |

### 7.2 게임 밖 테스트 방법 — [추정](일반 지식. 이번 조사에서 각 도구의 포에버 대응 여부를 개별 확인하지 못함)

- WoW 의 Lua 는 **5.1 계열**(일부 함수 제거·추가: `bit` 라이브러리, `strsplit`, `wipe`, `tinsert` 등 전역 별칭 존재 — 존재 자체는 [확인] [G]). 로컬에서는 표준 **Lua 5.1 인터프리터**(또는 LuaJIT 의 5.1 호환 모드)로 순수 로직을 돌린다.
- **구조 권고**: 게임 로직(전투 시뮬레이션, 인벤토리, 제작, 저장 직렬화)을 WoW API 를 전혀 호출하지 않는 순수 Lua 모듈로 분리하고, 시간·난수·저장소를 주입받게 한다. 이 부분은 `busted` 같은 일반 Lua 테스트 러너로 100% 게임 밖에서 검증 가능하다. UI 계층(CreateFrame 등)만 게임 안에서 수동 확인.
- **정적 검사**: `luacheck` 에 `std = "lua51"` 과 WoW 전역 목록(`read_globals`)을 설정. 전역 목록은 위 Ketho 덤프(`GlobalAPI.lua`, `FrameXML.lua`, `LuaEnum.lua`)에서 포에버 기준으로 생성할 수 있다.
- **편집기 지원**: LuaLS(Lua Language Server) + Ketho 의 WoW API 주석 확장(vscode-wow-api)이 널리 쓰임. 포에버 전용 프로필 유무는 [미확인] — 리테일 정의를 쓰면 거의 맞다(4.1).
- **WoW API 목(mock)·헤드리스 러너**: 커뮤니티 목 라이브러리들이 있으나 대부분 일부 API 만 흉내 내며, 포에버(12.x API)를 충실히 재현하는 공인 러너는 [미확인]. 필요한 최소 목(`CreateFrame` 스텁, `C_Timer`, `time`, 저장 변수 테이블)만 직접 작성하는 편이 현실적.
- **게임 안 반복 주기**: 파일 수정 → `/reload`. 새 파일(Lua·텍스처) 추가나 TOC 변경은 클라이언트 재시작 필요([추정]).

### 7.3 API 문서 사이트

| 사이트 | 상태 |
|---|---|
| warcraft.wiki.gg (`World of Warcraft API`, `TOC format`, `WOW_PROJECT_ID`, `Patch 12.1.5/API changes`, `Secret Values`) | 포에버 관련 문서 존재(검색 결과로 확인). **이 세션에서는 본문 접근 실패**(HTTP 403) — 검색 요약만 사용 |
| townlong-yak.com/framexml | 접근 실패(차단). 포에버 빌드 제공 여부 [미확인] |
| 블리자드 "Combat Philosophy and Addon Disarmament in Midnight"(secret values 배경 설명) | 주소만 확인 https://news.blizzard.com/en-us/article/24246290/combat-philosophy-and-addon-disarmament-in-midnight (본문 접근 실패) |

---

## (a) 출처 목록과 신뢰도 평가

### 직접 열람한 1차·공식 출처 (신뢰도 높음)

| 출처 | 작성·게시 시점 | 쓴 곳 | 비고 |
|---|---|---|---|
| 블리자드 공식 뉴스 24302093 "Carve a New Path…" / "…새로운 길을 개척하세요" (en-us, ko-kr) | 2026-09-12 (수정 en 10-27, ko 09-23) | 1, 2 | ko-kr 본문에 출시 시각 표기 오류 있음(1.2) |
| 공식 뉴스 24303862 "What's Next Panel Recap" | 2026-09-12 | 1, 2 | 로드맵 문구. 로드맵 이미지는 못 봄 |
| 공식 뉴스 24301508 "Purchase … Upgrades" | 2026-09-12 (수정 11-04) | 1.5 | 과금 |
| 공식 뉴스 24304075 "Create the Hero You Want to Be" | 2026-09-22 | 2.1, 2.2 | 종족·직업 표를 HTML 에서 직접 파싱 |
| 공식 뉴스 24304161 "Create a Name of Your Own" | 2026-09-21 | 1.5, 4.4 | 이중 이름·서버 없는 구조 |
| 공식 뉴스 24303009 "Raid Overview" (en-us, ko-kr) | 2026-10-20 | 2.4 | 공격대 일정·규모 |
| 공식 뉴스 24302070 "Choose Your Ruleset" | 2026-10-22 | 1.5 | |
| 공식 뉴스 24315821 "What's New and What Feels Familiar" | 2026-11-03 | 2.1, 2.3 | 레벨 상한 고정 |
| 공식 뉴스 24315820 "Now Live!" / "출시되었습니다!" (en-us, ko-kr) | 2026-11-04T23:00Z | 1, 2 | 출시 확인 |
| 공식 포럼 "UI Add-On Development Policy" t/24534 | 2018-11-19 (원 2009) | 6 | 블리자드 직원 게시 |
| `Gethe/wow-ui-source` `forever` 브랜치 (커밋 734f065, `1.60.1 (71037)`) 및 `live`/`classic_era`/`classic_anniversary`/`automation` 브랜치 | 2026-11-20 | 3, 4, 5 | 블리자드 클라이언트에서 추출한 UI 소스. 제3자 미러지만 내용은 블리자드 코드 |
| `Ketho/BlizzardInterfaceResources` `forever` 브랜치 (커밋 e230342, `1.60.1 (70938)`) | 2026-11-14 | 3, 4, 5 | 실클라이언트 안에서 덤프. 최신 빌드보다 2빌드 이전 |
| `BigWigsMods/packager` `release.sh`, `README.md` (master) | 2026-11-21 조회 | 3 | 사실상 표준 패키저 |
| 인기 애드온 TOC 원본: BigWigs, DBM, Ace3, Details(`Details_Camelot.toc`), BugSack, Bartender4, HereBeDragons, AdvancedInterfaceOptions | 2026-11-21 조회 | 3.1, 3.3 | 독립된 8개 프로젝트가 16001 로 일치 |

### 직접 열람한 커뮤니티 출처 (신뢰도 중간 — 개별 주장은 [추정], 여러 글이 일치하면 [확인])

| 출처 | 시점 | 쓴 곳 |
|---|---|---|
| 인벤 정보 게시판 51812 "와우 포에버는 본섭과 동일한 애드온 API를 가져갈 것 (위크오라 사용 불가)" | 2026-09-16 10:35 | 1.4, 4.1 — 블리자드 발언 번역 |
| 인벤 포에버 게시판 6567/17 "와우 포에버 애드온 대체품 정리" | 2026-09-16 15:10 | 4.1 — 처음 받은 단서의 원문 |
| 인벤 정보 게시판 52183 "와우: 포에버가 11월 5일 오전 8시에 출시됩니다!" | 2026-11-04 02:53 | 1.2 — 공식 시간표 전재 |
| 공식 포럼(플레이어 글) t/2347251/1287, t/2348036, t/2374157/217 | 2026-09-16 ~ 10-07 | 1.4, 4.1 — 블리자드 디스코드 발언 인용 |
| 공식 포럼 t/2385926 "WoW Forever Beta - Addon Feedback" | 2026-10-18 | 4.5 — 베타 애드온 개발 경험담(단일 작성자) |
| 공식 포럼 t/2353992, t/2354798 (SavedVariables 버그) | 2026-09-18 ~ 09-25 | 4.5 — 다수 사용자가 증상과 해결을 보고 |
| 공식 포럼 t/2386497, t/2387920/126, t/2383856, t/2406253, t/2401511 (폴더명) | 2026-10-15 ~ 11-08 | 3.2 |
| 공식 포럼 t/2420339, t/2414151, t/2414922, t/2423386 (비밀 값·API 제한 변화) | 2026-11-13 ~ 11-20 | 4.2 |
| 공식 포럼 t/2405538, t/2403005 (toc 16001 보고) | 2026-11-06 ~ 11-10 | 3.1 |

### 검색 요약으로만 본 출처 (신뢰도 낮음 — 본문 직접 확인 못 함, 해당 내용은 [추정])

- Icy Veins "Addons in WoW Forever? Blizzard Devs Just Addressed the Big Question", Wowhead 포에버 가이드, warcraft.wiki.gg `World_of_Warcraft:_Forever` / `WOW_PROJECT_ID` / `Patch_12.1.5/API_changes` / `API_TextureBase_SetTexture`(텍스처 형식) / `20th_Anniversary_Edition`, BlizzardWatch·Massively OP(SoD 상태), 네이트 뉴스(2026-11-05 출시 보도), 루리웹 글, 각종 팬 가이드 사이트(로드맵·가격·설치 폴더·`11601` 오기 사례). 팬 가이드 사이트는 서로 베껴 쓰는 경향이 있어 여러 개가 일치해도 독립 출처로 세지 않았다.

### 접근에 실패한 출처

| 출처 | 결과 |
|---|---|
| `news.blizzard.com` | 세션 네트워크 허용 목록 밖(같은 기사를 `worldofwarcraft.blizzard.com` 에서 읽어 대체) |
| `warcraft.wiki.gg` (MediaWiki API 포함) | 사이트가 HTTP 403 반환 |
| `www.wowhead.com` | 사이트가 HTTP 403 반환 |
| `kr.forums.blizzard.com` | 허용 목록 밖 |
| `bnetcmsus-a.akamaihd.net`(공식 기사 이미지 CDN — 로드맵 이미지) | 프록시 거부 |
| `www.curseforge.com`, `addons.wago.io`, `wago.tools`, `www.townlong-yak.com`, `namu.wiki`, `www.icy-veins.com`, `bluetracker.gg`, `web.archive.org` | 허용 목록 밖 |
| WoW UI 개발자 디스코드(블리자드 발언 원문) | 접근 수단 없음 — 재인용 3곳으로 대체 |
| GitHub API(`api.github.com`) | 세션 권한 없음(raw 파일과 git clone 으로 대체) |

---

## (b) 미확인으로 남은 중요 항목 — 실제 클라이언트에서 확인할 것

명령은 채팅창에 그대로 입력한다(`/dump` 는 값을 출력, `/run` 은 실행). 오류 표시는 먼저 `/console scriptErrors 1`.

| # | 확인할 것 | 왜 중요한가 | 확인 명령 |
|---|---|---|---|
| 1 | 현재 빌드·인터페이스 번호(패치 후 변동 여부) | TOC `## Interface:` 값 | `/dump GetBuildInfo()` — 기대: `"1.60.1", "<빌드>", "<날짜>", 16001` |
| 2 | 프로젝트 ID | 클라이언트 분기 | `/dump WOW_PROJECT_ID, WOW_PROJECT_CAMELOT, WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC` — 기대: `18, 18, 1, 2` |
| 3 | 로캘과 기본 폰트 경로 | 한글 표시 | `/dump GetLocale(), STANDARD_TEXT_FONT, UNIT_NAME_FONT, DAMAGE_TEXT_FONT` — 기대: `"koKR", "Fonts\\2002.TTF", "Fonts\\2002B.TTF", "Fonts\\K_Damage.TTF"` |
| 4 | 글꼴 객체가 실제로 쓰는 파일 | 상속 방식 검증 | `/dump GameFontNormal:GetFont()` |
| 5 | 캐릭터 이름·realm 반환 형태 | 저장 키 설계 | `/dump UnitName("player")` , `/dump UnitFullName("player")` , `/dump GetRealmName(), GetNormalizedRealmName()` , `/dump UnitGUID("player")` , `/dump RegionalUniqueNamesEnabled()` |
| 6 | 진영·직업·종족·레벨 값 | 미니게임 초기값 | `/dump UnitFactionGroup("player")` , `/dump UnitClass("player")` , `/dump UnitRace("player")` , `/dump UnitLevel("player"), GetMaxPlayerLevel()` |
| 7 | 위 값이 **전투 중**에도 평범한 값인지(비밀 값 여부) | 4.3-2 | 전투 중에 `/dump issecretvalue(UnitLevel("player")), issecretvalue((UnitClass("player"))), issecretvalue((UnitName("player")))` — 기대: 모두 `false` |
| 8 | 현재 제한 상태 조회 | 제한 인지 | `/dump C_Secrets.HasSecretRestrictions()` , `/dump C_RestrictedActions.IsAddOnRestrictionActive(Enum.AddOnRestrictionType.Combat)` |
| 9 | 구식 전역의 실제 존재 여부 | 4.5 표 검증 | `/dump type(getglobal), type(GetAddOnMetadata), type(InterfaceOptions_AddCategory), type(GetItemInfo), type(PlaySoundFile), type(math.randomseed)` , `/dump C_CVar.GetCVar("loadDeprecationFallbacks")` |
| 10 | SavedVariables 왕복 | 핵심 기능 | 테스트 애드온에 `## SavedVariables: WIHTestDB` 선언 후 `/run WIHTestDB = WIHTestDB or {}; WIHTestDB.n = (WIHTestDB.n or 0) + 1; print(WIHTestDB.n)` → `/reload` → 다시 실행해 값이 증가하는지. 이어서 완전 종료 후 재접속해서도 확인. 파일 위치: `_forever_\WTF\Account\<계정>\SavedVariables\` |
| 11 | 캐릭터별 저장 폴더명(realm 폴더) | 3.2 | 위 테스트에 `## SavedVariablesPerCharacter:` 추가 후 `_forever_\WTF\Account\<계정>\` 아래 폴더 구조를 눈으로 확인 |
| 12 | 아이콘 경로 해석 | 5.1 | `/dump GetFileIDFromPath("Interface\\Icons\\INV_Sword_04")` , `/dump GetFileIDFromPath("Interface\\Icons\\Spell_Fire_Fireball02")` — nil 이면 경로 미해석. 화면 확인: `/run local t=UIParent:CreateTexture(); t:SetSize(64,64); t:SetPoint("CENTER"); t:SetTexture("Interface\\Icons\\INV_Misc_QuestionMark")` |
| 13 | 아틀라스 존재 | 5.1 | `/dump C_Texture.GetAtlasInfo("ui-hud-minimap-addon-indicator")` |
| 14 | 자체 TGA/PNG 로드와 2의 거듭제곱 제약 | 5.3 | 애드온 폴더에 256×256 TGA, 300×200 TGA, 256×256 PNG 를 넣고 `/run local t=UIParent:CreateTexture(); t:SetSize(128,128); t:SetPoint("CENTER"); print(t:SetTexture("Interface\\AddOns\\WIHTest\\test256"))` 를 파일별로 실행(반환 success, 초록 사각형 여부 관찰) |
| 15 | 생물 모델 표시 | PlayerModel 사용 가능성 | `/run local m=CreateFrame("PlayerModel",nil,UIParent); m:SetSize(300,300); m:SetPoint("CENTER"); m:SetCreature(11502)` (11502 = 라그나로스), 안 보이면 `/run local m=CreateFrame("PlayerModel",nil,UIParent); m:SetSize(300,300); m:SetPoint("CENTER"); m:SetDisplayInfo(11121)` 처럼 표시 ID 로 시도. 플레이어 모델: `m:SetUnit("player")` |
| 16 | 사운드 재생 | 5.1 | `/run print(PlaySound(SOUNDKIT.IG_MAINMENU_OPEN, "SFX"))` , 자체 파일: `/run print(PlaySoundFile("Interface\\AddOns\\WIHTest\\ding.ogg", "SFX"))` |
| 17 | 애드온 서랍 버튼 표시 여부(클래식/강화됨 사전 설정 각각) | 4.5 | `/dump AddonCompartmentFrame ~= nil, AddonCompartmentFrame and AddonCompartmentFrame:IsShown()` , `/dump C_GameRules.GetForeverExperiencePreset()` |
| 18 | 전투 중 자체 창 조작 | 4.3-4 | 전투 중에 자체 프레임 `Show/Hide`, `SetPropagateKeyboardInput(true)`, `EnableKeyboard(true)` 를 호출해 `ADDON_ACTION_BLOCKED` 오류가 나는지 관찰 |
| 19 | 설정 패널 등록 | 4.5 | `/run local f=CreateFrame("Frame"); local c=Settings.RegisterCanvasLayoutCategory(f,"WIH Test"); Settings.RegisterAddOnCategory(c); Settings.OpenToCategory(c:GetID())` |
| 20 | 시간 API | 오프라인 진행 계산 | `/dump time(), GetServerTime(), GetTime(), date("%Y-%m-%d %H:%M:%S")` |
| 21 | TOC 접미사 우선순위(`_Camelot.toc` / `_Mainline.toc` / 기본) | 3.3 | 세 TOC 에 서로 다른 `## Title:` 을 적고 애드온 목록에서 어느 제목이 보이는지 확인. `forever` 별칭: 파일 한 줄에 `[AllowLoadGameType forever]` 를 달아 로드되는지 확인 |
| 22 | 게임 내 API 문서 | 개발 편의 | `/api` , `/api search secret` , `/api C_Timer list` |

### 실제 클라이언트 없이는 끝내 확인할 수 없었던 조사 항목 요약

- 검은날개 둥지·줄구룹·안퀴라즈·낙스라마스·화산 심장부의 포에버 내 공개 여부와 일정(공식 미발표).
- 디스커버리 시즌 등 기존 클래식 서비스의 향후 운영 방침.
- 자체 텍스처의 PNG/JPEG 지원과 최대 크기(리테일 위키 문서는 "BLP·JPEG·PNG·TGA, 2의 거듭제곱"이라 하나 포에버에서 직접 확인된 근거 없음 — b-14).
- 전투 중 애드온 일반 프레임의 Show/Hide·키보드 입력 설정이 실제로 막히지 않는지(문서 플래그 해석에 의존 — b-18).
- `GetRealmName()` 등 realm 계열 함수의 반환값과 캐릭터별 저장 폴더 이름(서버 없는 구조 — b-5, b-11).
- SavedVariables 크기 임계값(`SAVED_VARIABLES_TOO_LARGE` 발생 조건).
- Wago 의 포에버 태그 정확한 표기, townlong-yak 의 포에버 지원 여부.
- LibDBIcon-1.0 자체의 포에버 대응 버전.
- 블리자드의 유료 애드온 논란에 대한 최신 공식 입장.
