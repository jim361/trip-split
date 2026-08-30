# Trip Split 기능 범위 회의

> **[회의 00 · 기능 범위 회의 안내]** 합의 전 기능 후보와 결정 상태를 관리합니다.

**논의 홈** · [Flutter Android 전환](flutter-android-migration.md) · [Firebase/API 계약](firebase-api-contract.md) · [프로젝트 범위 사전 점검](project-scope-review.md) · [일정·지도](itinerary-map.md) · [정산·영수증](settlement-receipts.md)

이 문서는 팀이 첫 배포 범위를 회의에서 정하기 위한 인덱스다. 기능 구현 진행률을 관리하는 문서가 아니며, 회의에서 합의된 내용이 `MarkDown`의 제품·기술 계약에 반영되기 전까지는 기존 계약 문서가 기준이다.

## 문서 사용법

1. 기능을 이야기할 때 문서의 기능 ID를 사용한다.
2. 각 행의 `상태`를 `논의중`, `MVP`, `후속`, `제외` 중 하나로 바꾼다.
3. 기능을 빼더라도 행을 삭제하지 않고 `제외`로 남겨 결정 이유를 보존한다.
4. 새 기능은 각 문서의 `추가 제안` 표에 넣는다.
5. 회의가 끝나면 채택된 항목만 제품·요구사항·기술 계약과 기능별 task에 반영한다.

| 상태     | 의미                           |
| -------- | ------------------------------ |
| `논의중` | 아직 팀 합의가 필요함          |
| `MVP`    | 첫 배포에 포함함               |
| `후속`   | 필요하지만 첫 배포 이후로 미룸 |
| `제외`   | 구현하지 않으며 이유를 기록함  |

## 공통 기본안

| ID      | 기능                                                  | 사용 상황·기대 결과                                                 | 상태 | 회의 메모                                                  |
| ------- | ----------------------------------------------------- | ------------------------------------------------------------------- | ---- | ---------------------------------------------------------- |
| BASE-01 | 여행 생성 시 `국내 / 해외`를 선택한다                 | 후속 국내 모드에서 지도 provider를 자동 제안한다                    | 후속 | 첫 Android 배포는 도쿄·Google만 노출                       |
| BASE-02 | 한 여행은 하나의 지도 provider를 사용한다             | 장소 검색과 지도 표시가 일관된다                                    | MVP  | 직접 입력 장소는 어느 여행에서도 허용                      |
| BASE-03 | 솔로와 단체 여행은 같은 여행 모델을 사용한다          | 1명이면 솔로 원장, 인원과 멤버가 늘어나면 공동 여행으로 동작한다    | MVP  | 별도 `solo` 타입은 만들지 않음                             |
| BASE-04 | 예상 인원으로 정산 참여자를 만들고 이후 추가·제외한다 | 여행 생성 직후 정산 대상을 준비하되 실제 참가 변경을 반영할 수 있다 | MVP  | 접근 멤버와 정산 참여자는 분리                             |
| BASE-05 | 주요 앱 영역을 `일정·지도 / 준비 / 비용`으로 둔다     | Android 하단 메뉴를 세 개로 유지하고 영수증은 비용 안에서 연다      | MVP  | Flutter Android 앱 셸 계약에 반영                          |
| BASE-06 | 화면은 mock repository로 먼저 완성한다                | 각 담당자가 Firebase와 외부 API 없이 독립 개발할 수 있다            | MVP  | 실제 연동은 같은 repository/provider/adapter 계약으로 교체 |

## 첫 회의에서 먼저 결정할 것

- `준비` 영역에서 예약과 체크리스트를 어디까지 첫 배포에 포함할지
- KRW와 JPY가 섞인 여행을 통화별로 따로 정산할지, 여행당 한 통화만 허용할지
- P0 수동 equal/custom 뒤 P1 itemized·OCR·번역까지의 일정이 현실적인지
- 실제 지도·OCR API의 키, 비용 한도와 호출 제한을 누가 관리할지
- Flutter Web 보조판을 Android MVP 뒤 언제 시작할지

## 2026-08-28 반영 상태

| 결정                                          | 상태                                                       |
| --------------------------------------------- | ---------------------------------------------------------- |
| Flutter Android 우선, Flutter Web·iOS 후속    | scaffold·mock 앱·FlutterFire 경계 완료; 실기기 통합 미검증 |
| 도쿄·Google·JPY 우선, 국내 NAVER 후속         | 계약 반영 완료                                             |
| `일정·지도 / 준비 / 비용`, 영수증은 비용 하위 | 계약 반영 완료                                             |
| Node.js·TypeScript Firebase backend 유지      | 계약 반영 완료                                             |
| OCR은 provider-neutral 원문·한국어 번역 검토  | 계약 반영 완료; provider benchmark 필요                    |
| 걸음·거리·경로 기록                           | P2 경계만 기록, 권한·구현 미착수                           |

## 회의 결과 기록 양식

```text
회의 날짜:
참석자:
대상 버전:

MVP로 채택한 ID:
수정해서 채택한 ID와 내용:
후속으로 미룬 ID와 이유:
제외한 ID와 이유:
새로 추가한 기능과 담당자:
계약 문서 반영 담당자:
```

## 문서 역할

- `docs/project-scope-review.md`: 현재 구현, 첫 사용 가능 버전, 추가 후보와 회의 우선 질문
- `docs/firebase-api-contract.md`: 화면별 Firebase/API 계약, 모바일·웹 불일치와 실제 연결 상태
- `docs/flutter-android-migration.md`: 확정된 플랫폼 전환과 단계별 실행 순서
- `docs/README.md`, `docs/itinerary-map.md`, `docs/settlement-receipts.md`: 회의용 기능 후보와 결정 상태
- `MarkDown/product.md`, `MarkDown/requirements.md`, `MarkDown/tech.md`, `MarkDown/structure.md`: 합의가 끝난 제품·기술 계약
- `MarkDown/task/*.md`: 채택된 기능의 구현 체크리스트
- `MarkDown/decision_history.md`: 결정 이력과 변경 이유(현재 계약을 직접 대체하지 않음)
