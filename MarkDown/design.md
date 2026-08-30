# Trip Split Design Contract

> **[계약 05 · 디자인 계약]** 화면 구조, 반응형과 상태 표현 원칙입니다.

2026-08-30 기준 Flutter Android 구현을 수용 기준으로 정리했다. 이후에는 이 문서와 `frontend/lib/shared/theme/app_theme.dart`를 함께 변경해야 하며, 개별 화면의 임의 literal이나 과거 Stitch prompt가 이 계약을 덮어쓰지 않는다.

## 1. 디자인 방향

Trip Split의 시각 기조는 **Structural Modernism**이다. 엄격한 그리드, 노출된 구분선, 제한된 색상과 정확한 정렬을 기본으로 하고, 날짜·지도·금액처럼 중요한 정보에만 건축적 부르탈리즘의 큰 규모와 면적 대비를 사용한다.

구현 기반은 Flutter의 Material Design 3로 고정한다. Material 3의 컴포넌트 상태, 접근성, navigation과 interaction 동작을 사용하되 기본 seed 외형은 그대로 쓰지 않는다. 큰 패널은 직각, 입력과 버튼은 2~4px 반경, cobalt 단일 포인트와 콘크리트 미색 canvas를 전역 `ThemeData`에 적용한다. 첫 Android MVP는 밝은 테마만 지원하고 다크 테마는 별도 수용 기준을 정한 뒤 추가한다.

모더니즘은 앱 전체의 규칙이고 부르탈리즘은 강조 수단이다. 모든 요소를 두꺼운 선이나 큰 글자로 만들지 않고 화면의 구조, 선택된 날짜, 여행 일수, 지도와 정산 총액처럼 위계가 필요한 지점에만 강한 대비를 둔다.

## 2. 시각 구성 원칙

- 8dp 간격 grid를 기본으로 하고 4dp은 조밀한 내부 정렬과 Material component의 광학 보정에만 사용한다.
- 장식용 카드 대신 canvas와 surface를 사용하고 내부 행과 일반 panel 외곽은 1px 선, 화면 경계와 초점 module은 3px 구조선으로 나눈다.
- 큰 날짜, 여행 일수와 정산 총액은 한 화면에서 하나의 주 시각 덩어리로만 사용한다.
- 시간, 날짜, 순서 번호와 금액은 고정폭 숫자로 정렬한다.
- 포인트 색은 선택, 주요 action, focus와 동선처럼 기능적 의미가 있을 때만 사용한다.
- 성공·경고·오류 색은 실제 상태에만 사용하고 장식이나 카테고리 구분에 재사용하지 않는다.
- 일정 block은 고정된 6개 유형 palette로 구분하고 유형 label·시간을 함께 표시한다. 일정마다 임의 색을 만들거나 상태 색을 재사용하지 않는다.
- hover 전용 action이나 PC에만 존재하는 필수 기능을 만들지 않는다.

## 3. 디자인 참고 도구

Stitch 앱·웹 시안과 기존 React 목업은 배치와 시각 비율을 비교하는 참고 자료로 사용한다. 현재 앱 시각 기준은 Stitch `Trip Split App Design` 프로젝트(`16505573828998485726`)의 계정 시작·전체 시간표·일정 지도·준비·비용 화면이다. 생성된 HTML이나 React code를 Flutter에 그대로 복사하지 않고 이 문서의 정보 구조, 도메인 계약, 한국어 문구와 접근성 결정이 우선한다.

React/Vite 데스크톱 배치는 Stitch `Trip Split Desktop Workspace` 프로젝트(`14722392259295009699`)의 분할 계정 시작 화면과 좌측 rail·구조선을 참고한다. 일정 workspace는 사용자 Google Sheets 예시처럼 날짜×시간 grid를 전체 폭으로 사용하고, 상세 지도·목록은 아래에 둔다.

시안을 갱신할 때는 최소한 계정 시작, 여행 선택 시간표, 일정·지도, 준비, 비용 화면을 같은 디자인 system으로 비교한다. 팀 공유 기준은 외부 프로젝트 링크가 아니라 저장소에 기록된 token과 수용 기준이다.

## 4. 앱·웹 반응형 셸

Android 휴대폰 portrait에서 모든 핵심 흐름이 완결되어야 한다. Flutter 앱과 전환기 React/Vite 웹은 같은 정보 구조와 디자인 토큰을 사용하고, 각 런타임 안에서는 available width에 따라 같은 화면을 재배치한다. Flutter Web 실제 연결·배포는 Android MVP 이후 범위지만 React mock의 expanded layout으로 PC 정보 구조를 함께 검증한다.

| 범위 | 기준 | 앱 셸 |
| --- | --- | --- |
| compact | 720px 미만 | 64dp 상단 앱 바, 한 열 content, 64dp 하단 3-cell navigation, contextual bottom sheet |
| medium | 720px 이상 1280px 미만 | 248px에서 64px로 접는 좌측 rail, content 한 열 또는 두 열, contextual drawer |
| expanded | 1280px 이상 | 접이식 좌측 rail, 전체 폭 날짜×시간 workspace, 우측 동선·일정 서랍 |

위 표는 React/Vite Desktop Workspace의 배치 기준이다. Flutter Material 셸의 기존 breakpoint는 720dp/1100dp로 유지한다. 폭은 기기 종류가 아니라 실제 available width로 판정한다. 창을 줄였을 때 action을 삭제하지 않고 rail → bottom navigation, panel → drawer 또는 bottom sheet 순으로 변환한다.

### 홈

- route는 `/` 계정 시작 → `/trips` 여행 선택 → `/trips/:tripId/itinerary` 여행 workspace 순서로 구성
- 첫 진입은 `Google로 계속`, `계정 없이 시작`, `공유 코드로 여행 참여`만 있는 간결한 계정 시작 화면으로 제공
- 내부 Firebase Anonymous Auth는 시작 화면 이전에 준비할 수 있지만 Google 연결을 필수로 만들지 않음
- 내 여행에서 여행을 선택하고 전체 날짜를 압축한 작은 일정 미리보기를 즉시 확인
- 일정 미리보기는 여행 선택을 돕는 요약이며 이 화면에서 일정을 편집하지 않음
- 여행 만들기와 공유 코드 입장은 일정 미리보기보다 낮은 위계의 보조 action으로 제공
- compact는 여행 선택 → 일정 미리보기 → 보조 action의 한 열, expanded는 여행 rail → 일정 미리보기 → 우측 요약 panel로 재배치
- `.trip.json` 백업 복원과 데모 데이터 진입은 보조 메뉴로 제공
- 현재 mock은 도쿄 fixture 한 건을 선택 항목으로 사용한다. 실제 내 여행 다중 목록은 멤버십 조회·Firestore index·Rules 계약이 확정된 뒤 연결하며 mock 배열을 production 목록처럼 사용하지 않는다.

### 여행 앱 셸

여행에 입장하면 상단 앱 바, 현재 페이지 영역, 주요 내비게이션으로 구성한다.

- Android 상단 앱 바: 왼쪽 여행 선택 menu, 중앙 `TRIP SPLIT / MY TRIPS`, 오른쪽 36dp 계정·공유 action을 64dp 높이에 고정. 여행 이름·기간·동기화 상태는 각 화면의 첫 content section에 둔다.
- 주요 메뉴: `일정·지도`, `준비`, `비용`
- 세 메뉴를 64dp 높이의 동일 폭 cell로 화면 하단에 고정하고 아이콘과 한국어 label을 함께 표시
- medium과 expanded에서는 같은 순서와 label의 `NavigationRail`로 변환
- React/Vite 데스크톱에서는 좌측 rail을 248px와 64px 사이에서 접고 펼친다. 접힌 상태에서도 세 메뉴의 아이콘과 접근 가능한 label은 유지한다.
- 현재 메뉴는 cell 전체를 cobalt로 채우고 흰 아이콘·label로 표시해 색상뿐 아니라 위치, 아이콘과 채워진 면으로 함께 구분
- 장소 보관함은 네 번째 메뉴가 아니다. 일정·지도 통합 화면 안의 바텀시트 또는 보조 패널로 연다.
- 앱 바와 내비게이션은 모든 세 탭에서 동일하고 Android 뒤로 가기는 열린 sheet → 하위 화면 → 이전 탭/화면 순으로 예측 가능하게 동작한다.

### 일정·지도 통합 화면

전체 시간표와 일차별 목록은 같은 `ItineraryItem`을 표현하는 두 view다. 내 여행 선택 화면에는 작은 요약을 유지하고, React/Vite 웹 workspace는 계획 작성용 큰 날짜×시간 grid를 사용한다. Android 일정·지도는 선택한 하루의 지도와 순서형 목록을 기본으로 한다.

- 전체 일정 미리보기는 높이 약 256dp 안에서 실제 일정이 있는 시간 범위를 압축하고, 모든 날짜 열은 가로 scroll로 유지
- 축소 block은 대략적인 시간대와 일정 존재 여부를 확인하는 용도이며 편집 action이나 세부 메모를 넣지 않음
- 일정·지도 화면 상단에는 `1일차`, `2일차` 형태의 날짜 tab을 두고 일정이 없는 날짜도 여행 기간에 포함
- 선택 날짜의 지도는 화면의 주 시각 덩어리로 표시하고 해당 날짜의 번호 핀과 직선 동선만 보여줌
- 지도 아래 목록은 시작 시간, 두 자리 순서 번호, 일정 제목, 종료 시간과 연결 장소를 구분선 기반 row로 표시
- 일정 순서는 같은 `planId`·`date` 안의 `order`를 canonical로 사용하고 지도 번호와 목록 번호를 함께 갱신
- `지도 크게 보기`로 지도를 같은 화면 흐름에서 확대하며 `?map=expanded&day=YYYY-MM-DD`로 확대 상태와 선택 날짜를 복원
- 장소 검색, Google Maps URL 붙여넣기와 직접 입력은 `장소 보관함` modal bottom sheet에서 제공
- 장소를 일정에 추가하거나 순서를 바꾸면 번호와 지도 동선이 같은 순서로 갱신
- 빈 시간 추가와 장소 연결은 한 손으로 누르기 쉬운 하단 CTA 또는 각 시간대 action으로 제공

React/Vite 데스크톱에서는 가로에 여행 날짜, 세로에 시간을 놓고 일정의 시작·종료를 분 단위 위치와 높이로 표시한다. 겹치는 일정은 옆 lane으로 나누고, 시간 미정 일정은 별도 목록에 남긴다. 표시 시간은 기본 06:00~24:00이며 사용자가 바꿀 수 있다. 표시 범위 밖 일정은 수와 전체 24시간 보기 action을 제공해 숨겨진 사실을 알린다.

웹 일정 화면은 입력 공간을 우선한다. 큰 소개 영역과 별도 선택 날짜 안내 줄을 없애고 24px 화면 제목·상태·서랍 버튼을 compact header에 모은다. 시간표 위에는 A/B 전환·나란한 표시 시작/종료 설정·일정 수·`일정 입력`을 한 도구 모음으로 묶고, 범례는 짧은 별도 줄에 둔다. 중복된 `여행 시간표` 제목은 보조 기술용 heading으로 유지한다. 모든 주요 버튼과 날짜 header는 최소 48px이며, 좁은 폭에서는 겹치거나 잘리지 않도록 도구 모음을 줄바꿈한다. `일정 입력`은 하단 form의 제목 칸으로 scroll/focus만 옮기며 작성 중인 값과 선택 날짜·A/B안·편집 항목을 초기화하지 않는다. 준비·비용 등 다른 화면의 기존 소개 header는 변경하지 않는다.

웹 지도·동선·일차별 목록은 본문 아래에 상시 배치하지 않는다. 시간표 위 `동선·일정 열기`로 우측 서랍을 열며 기본 상태는 닫힘이다. 서랍은 최대 440px 폭의 native modal dialog로 시간표 위에 겹쳐 열리고, 좁은 화면에서는 화면 폭에 맞춘다. 서랍 안에서 날짜와 A/B안을 고르면 시간표와 같은 선택 상태를 공유한다. 닫기 버튼 또는 Escape로 닫고 열기 버튼으로 focus를 복원하며, 시간표의 미저장 입력은 유지한다. `?details=open`은 서랍을 열고 기존 `?map=expanded` 링크도 서랍 안의 확대 지도에 연결한다. 서랍을 닫으면 두 표시 query만 제거하고 다른 query는 보존한다.

grid 아래 `새 일정 추가`에서 날짜·시작·종료·제목·장소·유형·선택 메모를 입력한다. 저장하면 선택한 A안 또는 B안에 block이 생기고, block을 클릭·키보드로 선택하면 같은 form에서 수정·삭제한다. A/B 전환 시 각 안의 미저장 form 초안은 보존한다. 날짜를 옮긴 항목은 해당 안·날짜의 마지막 순서에 배치한다. 자정을 넘는 일정은 현재 단일 날짜 계약에 따라 날짜별 항목으로 나눠 입력한다. drag 재배치, 수식, 다중 셀 붙여넣기와 undo는 후속 범위다.

A안/B안은 같은 trip 안의 독립된 일정이며 한 번에 하나의 안만 표시한다. 시간표·선택 날짜 지도·순서형 요약에 같은 plan 필터를 적용한다. compact Android 앱은 같은 데이터를 작은 전체 일정 요약과 일차별 지도·목록으로 표현하며 A/B 전환을 제공한다. Firebase 또는 Emulator를 선택한 두 클라이언트는 같은 trip 문서를 구독하지만 기본 React mock 변경은 해당 브라우저 실행에만 남으므로 모바일 앱으로 전파된 것으로 표현하지 않는다.

실제 도로 경로와 예상 이동 시간은 표시하지 않고 필요한 구간은 외부 Google Maps로 연다. 후속 tablet/Web은 같은 정보 구조를 다중 열로 재배치할 수 있지만 Android에 없는 필수 action을 만들지 않는다.

### 준비 화면

- 항공·숙소·교통·활동 예약은 상태, 외부 URL과 메모를 가진 구분선 기반 row로 표시한다.
- 공동·개인 체크리스트는 완료 control과 선택적 담당자만 제공한다.
- 여권 사본이나 결제 카드 같은 민감 파일 업로드 UI는 만들지 않는다.

### 비용 화면

모바일은 사용자가 자기 소비를 먼저 이해한 다음 송금 결과와 전체 지출을 확인하도록 아래 순서를 고정한다.

1. 개인 요약
   - `내가 결제한 금액`
   - `내가 부담한 금액`
   - 양수면 `받을 금액`, 음수면 `보낼 금액`, 0이면 `정산 완료`
   - 카테고리별 개인 소비 합계
   - 날짜·장소·메뉴 또는 지출 항목별 개인 소비 내역
2. 최종 정산
   - 누구에게 얼마를 보내거나 받아야 하는지 표시
   - 정산 문구 복사 action 제공
3. 지출 목록
   - 결제자, 총액, 내 부담액, 분할 방식, 연결된 장소/영수증 표시
   - 지출 추가, 수정과 삭제 제공

영수증 촬영·검토는 비용 탭의 하위 화면으로 연다.

### 영수증 검토 화면

영수증은 `이미지 선택 → OCR 처리 → 항목 검토·분할 → 합계 확인 → 지출 저장` 순서로 진행한다.

- Android 카메라 또는 시스템 Photo Picker로 이미지를 선택하고 로컬 미리보기만 표시하며 MVP에서는 Firebase Storage에 영구 저장하지 않음
- 원문 항목명과 한국어 번역을 함께 표시하고, 번역은 이해 보조임을 명확히 함
- OCR 항목명과 금액을 수정할 수 있고 누락된 메뉴, 할인, 봉사료, 기타 조정을 수동 추가할 수 있음
- 각 항목에 `일반 항목`, `할인`, `봉사료`, `기타 조정` kind를 표시
- 영수증 전체 균등 분할, 항목별 소비자 지정, 참여자별 금액 직접 입력을 전환할 수 있음
- 공용 메뉴는 소비자 chip을 여러 명 선택하고 `균등 분할`을 적용
- 직접 입력에서는 참여자별 금액과 남은 미배분 금액을 동시에 표시
- 항목 합계와 영수증 총액, 참여자별 배분 합계가 맞지 않으면 저장 CTA 가까이에 오류와 차액을 표시
- OCR을 읽지 못하면 `총액으로 직접 등록`을 제공해 결제자, 총액, 소비자와 분할 방식만으로 저장 가능
- 사용자가 검토를 완료하기 전에는 정산 데이터로 저장하지 않음

한 항목씩 읽기 쉬운 편집 row와 화면 하단 저장 CTA를 사용한다. 이미지·원문·번역·금액을 동시에 비교할 수 없을 정도로 좁으면 항목을 접거나 이미지 확대 화면을 제공한다.

## 5. 컬러 방향

기본은 콘크리트 미색 canvas, 흰 surface, 검정 구조선과 cobalt의 제한된 조합이다.

| 역할 | 값 | Flutter / React 기준 |
| --- | --- | --- |
| canvas | `#F2F2EE` | `AppTheme.canvas` / `--color-background` |
| surface | `#FFFFFF` | `colorScheme.surface` / `--color-surface` |
| ink | `#171717` | `AppTheme.ink` / `--color-text` |
| muted ink | `#676762` | `AppTheme.mutedInk` / `--color-muted` |
| line | `#D4D4CE` | `AppTheme.line` / `--color-line` |
| primary cobalt / CTA | `#1D4ED8` | `AppTheme.primary` / `--color-primary` |
| pressed / active navigation | `#0037B0` | `AppTheme.primaryPressed` / `--color-primary-pressed` |
| selection container | `#E8EFFF` | `AppTheme.primaryContainer` / `--color-primary-soft` |
| success | `#18794E` | `AppTheme.success` / `--color-success` |
| warning | `#A15C00` | `AppTheme.warning` / 상태 전용 literal |
| error | `#B42318` | `colorScheme.error` |
| map day 1 / 2 / 3 | `#1D4ED8` / `#171717` / `#6F6A52` | 지도 render model 전용 |

날짜별 지도 색은 지도 기능 안에서만 사용하며 번호, 날짜 label과 선 형태를 함께 표시한다. Google 지도 위에서는 핀과 동선이 잘 보여야 하므로 색상 수보다 대비를 우선한다.

시간표 유형 palette는 상태 색과 분리하며 Flutter·React에서 같은 의미로 사용한다. 색만으로 식별하지 않고 유형 label을 함께 제공한다.

| 유형 | 저장값 | 배경색 |
| --- | --- | --- |
| 항공 | `flight` | `#AEC9DE` |
| 이동 | `transport` | `#F2DE9B` |
| 식사 | `meal` | `#C6B8DB` |
| 관광·활동 | `activity` | `#BFD2B0` |
| 숙박·휴식 | `stay` | `#ECC49F` |
| 기타 | `other` | `#E1E3DE` |

### 구조·크기 토큰

| 토큰 | 값 | 용도 |
| --- | ---: | --- |
| `gridUnit` | 8dp | 기본 spacing 단위 |
| `denseUnit` | 4dp | 조밀한 내부 정렬과 광학 보정 |
| `minimumTouchTarget` | 48dp | 버튼과 icon action의 최소 hit area |
| `appBarHeight` | 64dp | 모든 주요 화면의 상단 앱 바 |
| `navigationHeight` | 64dp | compact 하단 3-cell navigation |
| `mediumBreakpoint` | 720dp | compact에서 medium rail로 전환 |
| `expandedBreakpoint` | 1100dp | 확장 rail·다중 panel로 전환 |
| `rowStroke` / `frameStroke` | 1dp | 내부 row·grid와 일반 frame |
| `outlineStroke` | 2dp | 보조 outline action과 focus |
| `sectionStroke` | 3dp | 앱 바·navigation·주요 section 경계 |
| panel / button / control radius | 0 / 2 / 4dp | 구조 panel / action / 입력·dialog |

Flutter 실행 기준은 `AppTheme`, React 실행 기준은 `frontend/src/shared/styles/global.css`의 `:root` 변수다. 화면 전용 크기처럼 재사용되지 않는 값은 별도 token을 만들지 않고 8dp grid와 위 표의 구조선을 따른다.

## 6. 컴포넌트와 반응형 원칙

- 앱 셸, 시간표, 지도와 큰 panel은 0px, 일정 block과 버튼은 2px, 입력·dialog·bottom sheet는 최대 4px 반경을 사용한다.
- 내부 row·grid 구분선과 일반 card·panel·지도·날짜 tab 외곽은 1px, 보조 outline action은 2px `ink`, 앱 바·navigation·준비 module과 주요 section 경계는 3px `ink`를 사용한다.
- 주요 CTA는 cobalt를 사용하되 위험한 삭제 action과 구분한다.
- 지도 위 control은 흰색 배경과 얇은 line을 사용하며 장식용 shadow를 넣지 않는다.
- 장소, 일정, 지출과 영수증 항목은 반복 카드보다 명확한 구분선이 있는 row로 표현한다.
- surface를 중첩하거나 모든 section을 card로 만들지 않는다.
- 모든 touch target은 최소 48×48dp로 하고 action 사이에 충분한 간격을 둔다.
- 웹 시간표는 1시간당 24px의 압축된 격자를 사용하며 짧은 일정 block도 실제 시간 비율을 유지한다. 키보드로 선택할 수 있고, 바로 아래 `선택 날짜 일정 전체 보기`에서 같은 일정을 48px 버튼으로 선택하는 동등한 경로를 제공한다. 공간이 부족한 block은 제목부터 표시하고, 시간·유형·장소는 접근 가능한 이름과 대체 목록에서 확인한다.
- hover만으로 의미나 action을 노출하지 않는다. 아이콘 단독 버튼에는 접근 가능한 한국어 label을 제공한다.
- 금액은 우측 정렬하고 현재 locale에 맞게 구분하며 통화 코드를 숨기지 않는다. `결제`, `부담`, `받기`, `보내기` label을 항상 함께 표시한다.
- 바텀시트는 drag handle, 제목, 닫기 action을 제공하고 키보드 focus가 시트 밖으로 빠지지 않게 한다.
- 입력 화면은 `MediaQuery.viewInsets`를 반영해 키보드가 현재 필드와 저장 CTA를 가리지 않게 한다.
- tablet/Web에서는 같은 도메인과 repository를 열과 패널로 재배치한다. 웹 시간표와 하단 form은 입력 효율을 높이는 표현 차이이며 Android에는 같은 CRUD에 도달하는 compact 입력 흐름을 후속 구현한다.

### Safe area와 Android 시스템 UI

- Flutter `SafeArea`와 system insets를 앱 셸에서 한 번 적용하고 중첩 Widget의 이중 padding을 피한다.
- 스크롤 콘텐츠 하단에는 64dp 하단 navigation과 저장 CTA 높이만큼 여백을 확보한다.
- 지도와 modal bottom sheet는 gesture navigation, display cutout과 키보드 inset을 함께 검증한다.
- portrait를 우선하되 가로 회전과 작은 화면에서도 앱 바·내비게이션·sheet가 잘리지 않는지 확인한다.

## 7. 타이포그래피

- 시안 기준 폰트: 본문·headline은 Hanken Grotesk, label·시간·날짜·순서·금액은 JetBrains Mono
- 현재 번들 구현: Android system sans-serif와 `monospace`를 동일 역할로 사용한다. 실제 폰트 파일을 번들할 때 fallback 순서와 한글 glyph를 함께 검증한다.
- 시간, 날짜, 일정 순서와 금액은 tabular-nums 또는 고정폭 숫자를 사용한다.
- 본문은 regular/medium, label은 bold, 큰 핵심 값은 extra-bold까지 사용하되 크기·위치·선으로 위계를 먼저 만든다.
- 한 화면에서 oversized type은 여행 일수, 선택 날짜, 지도 section code 또는 정산 총액 중 하나에만 사용한다.
- 서비스 첫 화면은 마케팅 landing이 아니라 Google 연결과 계정 없이 시작을 선택하는 계정 시작 화면이다.

| 역할 | 크기 / 행간 / 굵기 | Flutter 기준 |
| --- | --- | --- |
| display | 48 / 1.1 / 800 | `displayLarge`, system sans-serif |
| mobile display | 36 / 1.1 / 800 | 화면의 `displaySmall` override |
| headline | 24 / 1.2 / 700 | `headlineSmall`, system sans-serif |
| body large | 18 / 1.5 / 500 | `bodyLarge`, system sans-serif |
| body | 14 / 1.5 / 400 | `bodyMedium`, system sans-serif |
| label | 12 / 1.0 / 700 | `labelLarge`, `monospace` |
| compact label | 10 / 1.2 / 700 | `labelMedium`·`labelSmall`, `monospace` |

화면에서 크기를 조정한 시간·날짜·금액도 `monospace` 또는 `FontFeature.tabularFigures()`를 유지한다.

## 8. 상태 디자인

모든 주요 화면은 다음 상태를 가진다.

- 빈 상태
- 로딩 상태
- 에러 상태
- 저장 중 상태
- 저장 완료 상태
- 동기화 상태
- 오프라인 상태
- 익명 세션 상태

상태는 색상만으로 구분하지 않고 아이콘, 짧은 한국어 문구와 가능한 다음 action을 함께 제공한다.

- 초기 로딩: 화면 골격을 유지하는 skeleton을 사용하고 전체 화면 spinner 남용을 피함
- 저장 중: `저장 중…`
- 로컬 반영: `기기에 저장됨 · 동기화 대기`
- 서버 저장 완료: `모든 변경사항이 동기화됐어요`
- 실시간 동기화 중: `변경사항 동기화 중…`
- 동기화 완료: `모든 변경사항이 저장됐어요`
- 오프라인: 캐시 데이터에는 마지막 동기화 시각을 표시하고 pending write를 서버 저장 완료로 표현하지 않음. 장소 검색·OCR은 `온라인에서 다시 시도해 주세요`를 표시
- 재시도 가능한 오류: 원인 요약과 `다시 시도` 제공
- 권한 오류: `이 여행을 편집할 권한이 없어요`와 이전 화면 action 제공
- OCR 처리 중: 원본 미리보기를 유지하고 `영수증을 읽고 있어요…` 표시
- OCR 실패: `영수증을 읽지 못했어요`와 `다시 시도`, `총액으로 직접 등록` 제공
- 합계 불일치: `항목 합계가 영수증 총액과 JPY 1,000 달라요`처럼 통화와 정확한 차액 표시

예시:

- 장소가 없을 때: "장소 링크를 붙여넣거나 검색해서 첫 장소를 추가하세요."
- 일정이 없을 때: "시간을 추가하고 장소를 연결해보세요."
- 지출이 없을 때: "첫 지출을 추가하면 정산 결과가 계산됩니다."
- 개인 소비가 없을 때: "아직 내가 부담한 지출이 없어요."
- 받을 금액과 보낼 금액이 모두 0일 때: "정산이 모두 끝났어요."
- 익명 사용자일 때: "Google로 연결하면 내 여행 목록을 안전하게 보관할 수 있어요."

## 9. 피해야 할 것

- 과한 랜딩 페이지
- 어두운 대시보드 중심 디자인
- 알록달록한 neo-brutalism, 두꺼운 offset shadow와 sticker 표현
- gradient, glass surface와 장식용 illustration
- 일정마다 임의의 포인트 색을 배정하는 방식
- 둥근 floating card를 반복하는 dashboard
- 지도보다 카드가 더 눈에 띄는 구성
- 날짜·시간 grid 대신 일반 관리자 화면 같은 행 단위 편집표를 메인으로 사용하는 방식
- Google 지도 marker와 동선을 가리는 과한 배경색
- 저장 리스트 import에 의존하는 UX
- Google 로그인 없이는 사용할 수 없는 UX
- 동기화 상태를 숨기는 UX
- 장소 보관함을 별도 메인 메뉴로 만드는 UX
- Android 화면 사이에서 메뉴명·순서와 system back 동작이 달라지는 UX
- 개인 정산에서 결제액, 부담액과 송금 결과를 하나의 금액으로 섞어 표시하는 UX
- 합계가 맞지 않는 OCR 결과를 확인 없이 저장하는 UX
- MVP 영수증 이미지를 Firebase Storage에 영구 보관하는 UX

## 10. 디자인 결정

2차 디자인 결정은 다음과 같다.

- 기본 디자인 기조: Structural Modernism
- 구현 system: Material Design 3 interaction과 접근성 + custom visual theme
- 전체 톤: 정확한 grid, 제한된 색상, 노출된 구조선과 선택적 부르탈리즘 규모
- 포인트 색: CTA cobalt `#1D4ED8`, active navigation `#0037B0`, 선택 tint `#E8EFFF`
- 핵심 화면: 내 여행의 작은 전체 일정 요약과 일차별 지도·순서형 일정
- 앱 셸: Android handset 우선, `일정·지도 / 준비 / 비용` 세 개의 하단 내비게이션
- expanded 셸: 248px/64px 접이식 rail, A/B 날짜×시간 grid와 하단 일정 form, 열고 닫는 우측 동선·일차별 일정 서랍
- 핵심 시각 요소: 축소 날짜·시간 grid, 선택 일차, 큰 지도, 번호 핀, 순서 row, 직선 동선, 결제액·부담액·정산 결과가 분리된 개인 요약
- 장소 보관함: 일정·지도 안의 바텀시트 또는 보조 패널
- 영수증 UX: OCR 초안을 항목별로 수정·배분한 뒤 저장하며 실패 시 총액 수동 등록
- 계정 UX: 비차단 시작 화면에서 Google 연결 또는 계정 없이 시작, 내부 기본은 익명 세션
- 협업 UX: 공유 코드로 입장한 참여자가 실시간으로 같은 여행을 편집

## 11. 후속 이동 기록 UX 원칙

걸음 수·거리·여행 경로 기록은 P2이며 첫 Android MVP에는 권한이나 화면을 넣지 않는다. 도입할 때는 다음을 지킨다.

- 사용자가 `기록 시작`과 `기록 종료`를 명시적으로 제어한다.
- 권한 요청 전에 수집 데이터, 사용 목적, 배터리 영향과 삭제 방법을 설명한다.
- 백그라운드 기록 중에는 Android의 지속 알림과 현재 상태를 숨기지 않는다.
- 일시정지, 위치 권한 상실, 절전 중 누락 구간을 실제 이동처럼 연결하지 않는다.
- 원본 위치와 공유 요약의 보관 기간을 분리하고 여행 단위 삭제 기능을 제공한다.
- Health Connect와 위치 기록을 하나의 권한으로 묶지 않는다.
