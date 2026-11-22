# 07. 환경 점검 결과 (게임 내 확인)

- 실행일: 2026-11-22, 와우 포에버 한국어 클라이언트. 사용자가 `WIH_EnvCheck 0.1.0`을 실행해 전달한 결과다.
- 이 문서의 항목은 **실제 클라이언트에서 확인된 것**이다. `06-wow-forever-addon-env.md`의 [추정]·[미확인] 가운데 아래에 나온 것은 확인으로 바뀐다.

## 확인된 것

| 항목 | 결과 | 설계에 주는 의미 |
|---|---|---|
| 빌드 | `GetBuildInfo()` = 1.60.1, 71037, Nov 18 2026, **16001** | TOC의 `## Interface: 16001` 유지 |
| 프로젝트 | `WOW_PROJECT_ID` = 18 = `WOW_PROJECT_CAMELOT` | |
| TOC 선택 | 기본 TOC와 `_Camelot.toc`가 함께 있으면 **`_Camelot.toc`가 쓰인다** | 본 애드온도 두 TOC를 함께 넣는다(빌드 때 기본 TOC에서 복사). 기본 TOC만 있을 때의 동작은 확인하지 않음 |
| 로캘·글꼴 | koKR, `Fonts\2002.TTF`. `GameFontNormal` 12, `GameFontHighlightSmall` 11, `GameFontNormalLarge` 14, `NumberFontNormal` 13(OUTLINE). 한글 폭 계산 정상, `strlenutf8` 있음 | 블리자드 글꼴 객체 상속 방식 그대로 |
| 이름·서버 | `UnitName`의 두 번째 값은 성. **`GetRealmName()`과 `GetNormalizedRealmName()`은 빈 문자열** | 서버 이름을 키로 쓰지 않는다. 저장은 계정 공용이라 영향 없음 |
| 플레이어 정보 | 진영, 직업 토큰, 종족, 레벨은 평범한 값. 최대 레벨 60 | 필요하면 진영 기본값 제안에 쓸 수 있음(현재 결정은 연동 없음) |
| 애드온 제한 | 전투 밖에서도 `C_Secrets.HasSecretRestrictions()` = true, **`UnitHealth("player")`는 비밀 값**. 레벨·직업·이름·`GetTime`은 아님 | 실제 유닛 수치를 읽지 않는다는 원칙 유지 |
| Lua 환경 | Lua 5.1. `math.randomseed` 없음, `loadstring`·`setfenv`·`bit`·`table.wipe`·`C_Timer`·`debugprofilestop` 있음 | 엔진은 자체 난수를 쓰므로 영향 없음 |
| 없어진 전역 | `GetAddOnMetadata`, `InterfaceOptions_AddCategory`, `GetSpellInfo`, `GetItemInfo`, `GetSpellTexture` | `C_AddOns`, `Settings` 사용 |
| 프레임 종류 | Frame, Button, CheckButton, EditBox, ScrollFrame, Slider, StatusBar, Cooldown, PlayerModel, Model, ModelScene 등 18종 전부 생성 가능 | |
| 템플릿 | BackdropTemplate, UIPanelButtonTemplate, UIPanelScrollFrameTemplate, ScrollFrameTemplate, InputBoxTemplate, WowScrollBoxList, MinimalScrollBar 등 15종 전부 사용 가능 | 긴 목록(인벤토리)은 ScrollBox 사용 가능 |
| Frame 메서드 | `SetResizeBounds` 있음. **`SetMinResize`·`SetMaxResize` 없음.** 일반 프레임에는 `SetBackdrop` 없음(BackdropTemplate 필요) | 배경은 텍스처로 직접 그린다 |
| Texture | `SetColorTexture`, `SetAtlas`, `SetTexCoord`, `SetRotation`, `SetDesaturated`, 마스크 있음. `SetGradient(방향, 색 객체, 색 객체)` 성공. **`SetGradientAlpha` 없음** | |
| 애니메이션 | Alpha, Translation, Scale, Rotation, Path, FlipBook 등 10종 생성 가능 | 전투 장면의 이동·점멸에 사용 가능 |
| PlayerModel | `SetUnit`, `SetCreature`, `SetDisplayInfo`, `SetAnimation`, `HasAnimation`, `FreezeAnimation`, `SetPaused`, `SetFacing`, `SetPosition`, `SetCamDistanceScale`, `SetPortraitZoom` 있음. `SetModelByFileID` 없음 | |
| 모델 불러오기 | `SetCreature(11502)` → 표시 ID 11121, `SetCreature(10184)` → 8570, `SetCreature(3098)` → 503. `SetDisplayInfo(11121 / 8570 / 503 / 4449)`도 모델 파일이 잡힘 | 생물 ID와 표시 ID 모두로 모델을 불러올 수 있다 |
| 내장 아이콘 | `Interface\Icons\…` 경로 45개 전부 해석됨(아이템, 주문, 직업 아이콘, 기계공학, 보스 업적 아이콘 포함) | 아이콘은 경로 이름으로 참조 |
| 아틀라스 | 직업 아이콘, 진영 문장, 역할 아이콘 등 21개 있음. `Padlock` 없음 | 잠금 표시는 다른 자산 사용 |
| 포함 텍스처 | TGA 256×256, TGA 300×200(2의 거듭제곱 아님), PNG 256×256 모두 `SetTexture`가 성공을 돌려줌 | 화면에 제대로 그려지는지는 눈으로 확인 필요(아래) |
| 시간 | `time()`과 `GetServerTime()`이 13초 차이 | 오프라인 정산은 `GetServerTime()` 기준 |
| 저장 | `/reload` 뒤 값 유지, `PLAYER_LOGOUT`에서 쓴 값 저장됨, 10만 글자 문자열·2,000항목 표·중첩 표·소수 왕복 정상 | SavedVariables 설계 그대로 |
| 설정 패널 | `Settings.RegisterCanvasLayoutCategory` 등록 성공 | |
| 소리 | `PlaySound(SOUNDKIT…)` 성공 | |
| 계산 성능 | 산술 100만 회 14.4ms, 표 접근 20만 회 12.6ms, 함수 호출 50만 회 29.4ms. 프레임율 75 | 개발 환경의 Lua 5.1과 비슷한 속도(함수 호출만 약 2배 느림). 엔진 비용은 `docs/STATUS.md` 참조 |

## 아직 확인되지 않은 것

결과 글에 기록이 없어 다음 실행 때 확인이 필요하다.

1. **전투 중 점검**: 전투 기록이 없다. 몬스터와 한 번 전투한 뒤 "다시 점검"을 눌러야 한다. 전투 중 일반 프레임의 표시·숨김·위치 변경이 막히는지가 여기서 나온다.
2. **모델 16개 부하**: 누르지 않았다. 전투 장면에 모델을 몇 개까지 쓸지 정하는 근거다.
3. **눈으로 본 결과**: 글에는 나오지 않는다.
   - 텍스처 줄 앞 세 칸(TGA 256, TGA 300x200, PNG 256)이 줄무늬로 보였는지, 초록 사각형이나 빈칸이었는지
   - 모델 여덟 칸에 실제로 모델이 보였는지
   - "동작 바꾸기"를 누를 때 동작이 달라졌는지, 어느 번호가 공격·시전·죽음처럼 보였는지
   - 한글이 깨지지 않았는지, 창을 끌어 옮길 수 있었는지
