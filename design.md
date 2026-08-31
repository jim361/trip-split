# Structural Modernism Design System

> Trip Split의 현재 Flutter Android 디자인에서 추출한 범용 디자인 가이드.
>
> 최종 확인일: 2026-08-30

이 문서는 다른 제품에 시각 언어를 이식하기 위한 독립 문서다. 여행 일정, 지도, 정산처럼 Trip Split에만 해당하는 정보 구조와 문구는 포함하지 않는다. 새 프로젝트에서는 아래 토큰과 구성 원칙을 유지하고 브랜드명, 메뉴, 데이터와 사용자 흐름만 교체한다.

## 1. 디자인 정체성

디자인 기조는 **Structural Modernism**이다. 엄격한 그리드, 정확한 정렬, 노출된 구분선, 제한된 색상으로 구조를 먼저 보여준다. 큰 숫자나 넓은 색면 같은 부르탈리즘 표현은 화면에서 가장 중요한 정보 한 곳에만 사용한다.

- 기본 canvas는 따뜻한 콘크리트 미색, 실제 작업 surface는 흰색으로 구분한다.
- 장식용 카드와 그림자 대신 선, 여백, 정렬로 계층을 만든다.
- cobalt 한 색을 선택, 주요 CTA, focus와 진행 경로에만 사용한다.
- 입력과 버튼은 거의 직각으로 유지한다.
- 시간, 날짜, 순서, 금액 등 비교가 필요한 숫자는 고정폭으로 정렬한다.
- Material Design 3의 상태·접근성·interaction은 사용하되 기본 seed 외형을 그대로 사용하지 않는다.
- 밝은 테마를 기본으로 한다. 다크 테마는 색만 반전하지 말고 별도 대비 검증 후 추가한다.

### 피해야 할 표현

- gradient, glass surface, 장식용 blur와 illustration
- 둥근 floating card를 반복한 dashboard
- 두꺼운 offset shadow, sticker형 neo-brutalism
- 정보 종류마다 임의로 다른 강조색을 부여하는 방식
- 모든 텍스트를 크고 굵게 만들어 위계를 잃는 방식
- hover에서만 나타나는 필수 action
- 상태, 선택 또는 오류를 색상 하나로만 구분하는 방식

## 2. 디자인 토큰

### 색상

| 역할            | 값        | 사용 기준                              |
| --------------- | --------- | -------------------------------------- |
| Canvas          | `#F2F2EE` | 앱·페이지 기본 배경                    |
| Surface         | `#FFFFFF` | 입력, panel, navigation, 실제 작업 면  |
| Ink             | `#171717` | 본문, 아이콘, 강한 구조선              |
| Muted ink       | `#676762` | 보조 설명, 비활성 label                |
| Line            | `#D4D4CE` | 내부 row, grid, 일반 구분선            |
| Primary cobalt  | `#1D4ED8` | 주요 CTA, focus, 선택 강조             |
| Primary pressed | `#0037B0` | 눌림 상태, active navigation의 넓은 면 |
| Primary soft    | `#E8EFFF` | 선택 배경, 약한 강조                   |
| Neutral soft    | `#E8E8E3` | 보조 선택·중립 container               |
| Success         | `#18794E` | 실제 성공·완료 상태                    |
| Warning         | `#A15C00` | 실제 주의 상태                         |
| Error           | `#B42318` | 오류와 파괴적 action                   |

색상은 기능을 가진다. primary를 장식에 쓰지 않고 success, warning, error를 카테고리 구분에 재사용하지 않는다. 배경 위 본문과 action은 WCAG AA 이상의 대비를 유지한다.

### 간격과 크기

| 토큰                      |     값 | 용도                             |
| ------------------------- | -----: | -------------------------------- |
| Dense unit                |    `4` | 아이콘과 label 사이, 광학 보정   |
| Grid unit                 |    `8` | 모든 기본 spacing의 단위         |
| Content gutter            |   `16` | compact 화면 좌우 여백           |
| Wide gutter               |   `24` | medium 이상 화면 여백            |
| Minimum touch target      |   `48` | 버튼과 icon action의 최소 크기   |
| App bar height            |   `64` | 주요 상단 bar                    |
| Compact navigation height |   `64` | 하단 navigation                  |
| Medium breakpoint         |  `720` | rail 또는 다중 열 전환 시작      |
| Expanded breakpoint       | `1100` | 확장 rail과 보조 panel 전환 시작 |

4px 값은 조밀한 내부 정렬에만 사용한다. 일반 여백은 `8, 16, 24, 32, 48, 64` 순서를 우선한다.

### 선과 모서리

| 역할                 | 두께 / 반경 | 사용 기준                              |
| -------------------- | ----------- | -------------------------------------- |
| Row·grid line        | `1px`       | 내부 구분선                            |
| Panel frame          | `1px`       | 일반 panel, card, 지도 frame           |
| Outline action·focus | `2px`       | outline button, focused field          |
| Structural section   | `3px`       | app bar, navigation, 핵심 section 경계 |
| Panel radius         | `0px`       | 큰 작업 영역과 구조 panel              |
| Button radius        | `2px`       | filled·outlined·text button            |
| Control radius       | `4px`       | input, dialog, bottom sheet 상단       |

기본 elevation과 장식용 shadow는 사용하지 않는다. 지도 marker처럼 배경과 분리되어야 하는 overlay에만 작은 shadow를 예외적으로 허용한다.

## 3. 타이포그래피

본문과 headline은 sans-serif, label과 구조화된 숫자는 monospace를 사용한다. 원 시안의 조합은 Hanken Grotesk + JetBrains Mono이며, 폰트를 번들하지 않을 때는 한글을 안정적으로 지원하는 system sans-serif + system monospace로 대체한다.

| 역할           | 크기 / 행간 / 굵기 | 추가 규칙                     |
| -------------- | ------------------ | ----------------------------- |
| Display        | `48 / 1.1 / 800`   | expanded 화면의 핵심 값 하나  |
| Mobile display | `36 / 1.1 / 800`   | compact 화면의 핵심 값 하나   |
| Headline       | `24 / 1.2 / 700`   | 페이지 또는 주요 section 제목 |
| Title large    | `18 / 1.35 / 600`  | panel 제목                    |
| Title medium   | `16 / 1.35 / 600`  | 하위 section 제목             |
| Body large     | `18 / 1.5 / 500`   | 소개·강조 본문                |
| Body           | `14 / 1.5 / 400`   | 기본 본문                     |
| Body small     | `12 / 1.4 / 400`   | 보조 설명                     |
| Label          | `12 / 1.0 / 700`   | monospace, 자간 `0.6px`       |
| Compact label  | `10 / 1.2 / 700`   | monospace, 자간 `0.4px`       |

- 한 화면의 oversized type은 하나만 둔다.
- 크기보다 위치, 면적, 선과 여백으로 위계를 먼저 만든다.
- 날짜, 시간, 순번과 금액에는 `tabular-nums` 또는 고정폭 숫자를 적용한다.
- 금액은 우측 정렬하고 통화 단위를 숨기지 않는다.
- 본문을 모두 대문자로 쓰지 않는다. 짧은 제품명, section code와 label에만 제한한다.

## 4. 레이아웃

### Compact: 720px 미만

- 64px 상단 app bar
- 한 열 content와 16px 좌우 gutter
- 핵심 메뉴가 3~5개면 64px 하단 navigation
- contextual UI는 modal bottom sheet
- 고정 navigation 또는 CTA만큼 scroll 하단 여백 확보

### Medium: 720px 이상 1100px 미만

- 축약 navigation rail
- 한 열 또는 두 열 workspace
- contextual UI는 drawer 또는 보조 열
- 좌우 gutter 24px

### Expanded: 1100px 이상

- 약 224px의 확장 navigation rail
- 중앙 workspace와 선택적 우측 contextual panel
- compact에 존재하지 않는 필수 기능을 추가하지 않는다.

breakpoint는 기기 이름이 아니라 실제 available width로 판정한다. 화면이 좁아지면 `확장 rail → 축약 rail → 하단 navigation`, `보조 panel → drawer → bottom sheet` 순으로 변환한다. action 자체를 삭제하지 않는다.

### 화면 구성

1. App bar: 제품 맥락, 상위 이동, 계정 또는 대표 action
2. Page header: 현재 대상과 상태, 화면 제목
3. Primary workspace: 화면에서 가장 중요한 정보와 action
4. Supporting sections: 1px 구분선 기반 row 또는 panel
5. Navigation / CTA: 안전 영역과 겹치지 않는 고정 action

큰 surface를 다시 여러 개의 둥근 card로 쪼개지 않는다. 반복 데이터는 card 묶음보다 header + divider row 구조를 우선한다.

## 5. 컴포넌트 규칙

### App bar

- 높이 64px, canvas 배경, elevation 0
- 아래쪽에 3px ink 구조선
- icon action의 hit area는 48×48px 이상
- 긴 제목은 한 줄 ellipsis 처리

### Navigation

- 모든 destination은 같은 너비와 순서를 유지한다.
- icon과 텍스트 label을 함께 제공한다.
- 선택 cell 전체를 `Primary pressed`로 채우고 foreground를 흰색으로 바꾼다.
- 선택 상태는 색뿐 아니라 위치, 채워진 면, icon 형태와 접근성 상태로 함께 표현한다.
- compact는 하단 bar, medium 이상은 동일 항목의 rail을 사용한다.

### Button

- 기본 높이 48px 이상, radius 2px
- Primary: cobalt 배경 + 흰 foreground
- Secondary: 투명 또는 흰 배경 + 2px ink outline
- Tertiary: 배경 없이 cobalt text
- 삭제는 primary cobalt와 구분되는 error 표현 및 확인 단계를 사용한다.
- loading 중에는 label을 동작형 문구로 바꾸고 중복 실행을 막는다.

### Input

- 흰 배경, 1px line, radius 4px
- 기본 padding은 가로 16px, 세로 약 15px
- focus는 2px cobalt outline
- label, 입력값, 도움말, 오류 문구를 색상만으로 구분하지 않는다.
- 키보드와 validation message가 입력값 또는 저장 CTA를 가리지 않게 한다.

### Panel, card와 row

- 큰 panel은 radius 0, 1px ink 또는 line frame, shadow 0
- section을 card로 감싸기 전에 여백 + heading + divider로 해결 가능한지 확인한다.
- 반복 항목은 1px divider row를 우선한다.
- 선택 row는 primary soft 배경과 구조적 marker를 함께 사용한다.

### Dialog와 bottom sheet

- radius 최대 4px, 흰 surface, surface tint와 shadow 최소화
- bottom sheet는 drag handle, 제목과 명시적 닫기 action을 제공한다.
- keyboard focus를 overlay 내부에 유지한다.
- compact의 sheet는 medium 이상에서 drawer나 contextual panel로 재배치할 수 있다.

### Data visualization과 map

- 배경보다 데이터가 먼저 보이게 한다.
- point color 수를 늘리기보다 번호, label, 선 종류를 함께 사용한다.
- overlay control은 흰 배경, 얇은 선, 48px touch target을 사용한다.
- 범례 없이 색만으로 의미를 추측하게 만들지 않는다.

## 6. 상태와 피드백

모든 주요 화면은 최소한 빈 상태, 로딩, 오류, 저장 중, 저장 완료와 오프라인 상태를 설계한다.

- 로딩: layout을 유지하는 skeleton을 우선하고 전체 화면 spinner를 남용하지 않는다.
- 빈 상태: 현재 상태, 사용자가 할 수 있는 다음 action 하나를 함께 제시한다.
- 오류: 원인 요약과 가능한 `다시 시도` 또는 이전 화면 action을 제공한다.
- 저장 중: `저장 중…`처럼 현재 동작을 표현하고 중복 submit을 막는다.
- 로컬 저장: 서버 완료처럼 표현하지 않고 `기기에 저장됨 · 동기화 대기`처럼 구분한다.
- 완료: 아이콘, 짧은 문구와 success color를 함께 사용한다.
- 오프라인: 마지막 동기화 시각, 제한되는 기능과 재시도 방법을 표시한다.

상태 문구는 기술 코드가 아니라 사용자가 취할 다음 행동을 설명해야 한다.

## 7. 접근성과 플랫폼 원칙

- 모든 interactive target은 최소 48×48px로 만든다.
- icon-only button에는 화면 언어의 접근 가능한 label 또는 tooltip을 제공한다.
- hover 없이 touch와 keyboard만으로 전체 흐름을 완료할 수 있어야 한다.
- focus indicator를 제거하지 않는다.
- `SafeArea`와 system inset은 shell에서 한 번 적용해 이중 padding을 피한다.
- gesture navigation, display cutout, 화면 회전과 software keyboard를 검증한다.
- scroll content 아래에는 고정 navigation과 CTA 높이만큼 여백을 둔다.
- 의미 있는 읽기 순서, heading 구조와 screen reader 상태를 제공한다.
- motion은 구조 이해에 필요한 짧은 전환만 사용하고 reduced motion 설정을 존중한다.

## 8. 다른 프로젝트에 적용하는 방법

1. 이 문서의 색상, spacing, stroke, radius와 typography를 전역 token으로 먼저 등록한다.
2. app shell, button, input, navigation, panel 다섯 종류만 공통 theme에 구현한다.
3. 새 제품의 핵심 작업 화면 하나에 적용해 정보 밀도와 대비를 검증한다.
4. compact 360px, medium 720px, expanded 1100px 이상에서 같은 action이 유지되는지 확인한다.
5. 빈 상태, 오류, loading, keyboard와 screen reader까지 확인한 뒤 나머지 화면으로 확장한다.

이식할 때 유지할 것은 **시각 문법과 interaction 원칙**이다. 메뉴 개수, 화면 이름, 도메인 색, 콘텐츠 순서와 문구는 대상 제품의 사용자 흐름에 맞게 다시 설계한다.

### CSS token 시작점

```css
:root {
  --canvas: #f2f2ee;
  --surface: #ffffff;
  --ink: #171717;
  --muted-ink: #676762;
  --line: #d4d4ce;
  --primary: #1d4ed8;
  --primary-pressed: #0037b0;
  --primary-soft: #e8efff;
  --success: #18794e;
  --warning: #a15c00;
  --error: #b42318;

  --space-1: 4px;
  --space-2: 8px;
  --space-3: 16px;
  --space-4: 24px;
  --space-5: 32px;

  --stroke-row: 1px;
  --stroke-outline: 2px;
  --stroke-section: 3px;
  --radius-panel: 0;
  --radius-button: 2px;
  --radius-control: 4px;
  --touch-target: 48px;
  --app-bar-height: 64px;
  --navigation-height: 64px;
}
```

### 완료 점검표

- [ ] canvas, surface, ink와 cobalt의 역할이 일관적인가?
- [ ] 일반 spacing이 8px grid를 따르는가?
- [ ] panel 0px, button 2px, control 4px radius가 유지되는가?
- [ ] shadow 대신 선과 여백으로 계층이 보이는가?
- [ ] 한 화면에 oversized 핵심 정보가 하나뿐인가?
- [ ] active, error와 success가 색 이외의 단서도 제공하는가?
- [ ] 모든 action이 48px touch target과 접근 가능한 이름을 갖는가?
- [ ] 720px과 1100px 전환에서 기능이 사라지지 않는가?
- [ ] loading, empty, error, saving과 offline 상태가 있는가?
- [ ] keyboard, safe area와 screen reader 흐름을 확인했는가?

## 9. 원본과 적용 우선순위

이 문서는 아래 저장소 자료에서 범용 규칙만 추출했다.

1. `frontend/lib/shared/theme/app_theme.dart` — 현재 Flutter Android 실행 기준
2. `MarkDown/design.md` — 제품 디자인 계약과 수용 기준
3. `frontend/lib/app/trip_shell.dart` — breakpoint, shell과 navigation 구현
4. `frontend/test/app_theme_test.dart` — token 회귀 검증

`frontend/src/`의 React/Vite 목업에는 이전 단계의 큰 radius, shadow와 640/1024px breakpoint가 일부 남아 있으므로 새 프로젝트 이식 기준으로 사용하지 않는다. 원본 저장소에서 계약이 바뀌면 이 문서도 수동으로 다시 동기화해야 한다.
