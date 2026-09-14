# Trip Split Backend

> **[공통 안내 · 백엔드]** 두 백엔드 담당의 시작 문서, 파일 소유권과 검증 방법을 안내합니다. 2026-09-14 기준입니다.

Firebase Callable Functions, Firestore 보안 규칙과 Emulator 통합 테스트를 소유하는 Node.js 22 프로젝트입니다. 현재는 **Phase B(P0)**이며, 주요 서버 함수와 Emulator용 구현이 있습니다. 실제 Google Places 연결은 B의 남은 작업이고, OCR·번역의 실제 비교·연결은 B 완료 뒤 Phase C에서 시작합니다.

## 처음 합류하면

1. [루트 작업 규칙](../AGENTS.md)과 [개발 시작 안내](../docs/development-kickoff.md)에서 현재 단계와 본인의 역할을 확인합니다. 인계 문서의 “사용자·프론트/공통/통합”은 팀의 통합 담당을 뜻합니다.
2. [화면·API 인계](../docs/frontend-api-handoff.md)와 [Firebase API 계약](../docs/firebase-api-contract.md)에서 기존 구현·wire·미연결 항목을 확인합니다.
3. 아래 소유권 표에서 자신의 구현·문서·테스트 경로를 선택합니다. 다른 담당 코드도 읽고 영향을 확인할 수 있지만 수정은 담당 경계를 따릅니다.

## 담당별 코드·문서·테스트

아래 경로는 이 `backend/` 디렉터리 기준입니다. **정산·영수증 백엔드는 한 담당자가 `settlement`와 `ocr`를 함께 맡습니다.**

| 영역               | 일정·지도 백엔드                                                  | 정산·영수증 백엔드                                          |
| ------------------ | ----------------------------------------------------------------- | ----------------------------------------------------------- |
| 구현·단위 테스트   | [src/places/](src/places/)                                        | [src/settlement/](src/settlement/), [src/ocr/](src/ocr/)    |
| 담당 작업 문서     | [workstreams/itinerary-map/](workstreams/itinerary-map/) — 작성됨 | `workstreams/settlement-receipts/` — 필요 시 생성할 위치    |
| 새 Emulator 테스트 | `tests/emulator/itinerary-map/` — 테스트 추가 시 생성             | `tests/emulator/settlement-receipts/` — 테스트 추가 시 생성 |
| 현재 Phase B 작업  | 검색·링크·참조·동시 변경 회귀, 승인된 Google Places 연결          | equal/custom 지출 CRUD·금액·권한·참여자·응답 유실 회귀      |

일정·지도 담당 문서는 [SPEC.md](workstreams/itinerary-map/SPEC.md) → [plan.md](workstreams/itinerary-map/plan.md) → [tasks.md](workstreams/itinerary-map/tasks.md) 순서로 읽습니다. [AGENT.md](workstreams/itinerary-map/AGENT.md)는 **일정·지도 담당에게만 적용하는 지침**입니다. 정산·영수증 담당에게 해당 문서의 쓰기 제한이나 작업 순서를 적용하지 않습니다. `AGENT.md`는 작업 시작 시 명시적으로 읽는 문서입니다.

정산·영수증 담당은 우선 공통 개발 시작 안내를 따릅니다. 담당 문서를 도입할 때 위 전용 위치를 사용하며, 현재 그 폴더나 빈 문서는 만들지 않았습니다. 각 담당자는 위 표에 지정된 기존 `src/` 하위 폴더에서 구현을 이어갑니다.

### 공용 파일 변경 절차

| 영역                         | 경로                                                                                                                                                     | 변경 방식                                                          |
| ---------------------------- | -------------------------------------------------------------------------------------------------------------------------------------------------------- | ------------------------------------------------------------------ |
| 초기화·인증·여행 공유·export | `src/share/`, `src/shared/`, `src/index.ts`                                                                                                              | 통합 담당과 조율                                                   |
| 데이터 권한·인덱스           | `firestore.rules`, `firestore.indexes.json`                                                                                                              | 담당자가 재현·변경안을 공유하고 통합 담당이 최종 반영              |
| 공용 Emulator 회귀           | [domain-flows.emulator.test.ts](tests/emulator/domain-flows.emulator.test.ts), [trip-share.emulator.test.ts](tests/emulator/trip-share.emulator.test.ts) | 기존 파일에 수정·이동·helper 추출이 필요하면 관련 담당과 먼저 조율 |
| 공통 설정·문서·계약          | 이 README, package/config, `.env.example`, 저장소 루트의 lockfile·`firebase.json`·`AGENTS.md`·`docs/`·`MarkDown/`·CI                                     | 통합 담당과 변경 범위·영향 확인                                    |
| Flutter 전체                 | 저장소 루트의 `frontend/`                                                                                                                                | 프론트·공통·통합 담당 소유                                         |

공용 변경은 **문제·재현 → 대상 파일과 현재/제안 동작 → 다른 담당·Flutter 영향과 검증 방법 공유 → 합의 → 통합 담당 최종 반영 → 반영 SHA 확인·재검증** 순서로 진행합니다. 공개 API·공통 모델·Firestore 경로를 각자 변경하지 않습니다.

`domain-flows.emulator.test.ts`에는 장소·준비·정산·OCR 등 여러 영역의 회귀가 섞여 있습니다. 기존 검증은 유지하고 새 도메인 테스트는 담당별 하위 폴더에 추가합니다. 기존 Vitest 설정이 `tests/emulator/**/*.emulator.test.ts`를 발견하므로 폴더를 나누기 위한 설정 변경은 필요하지 않습니다.

## 현재 서버 구현

[src/index.ts](src/index.ts)에서 다음 **11개 Callable**을 export합니다. 함수 구현과 실제 외부 서비스 연결 완료는 구분합니다.

| 기능                | Callable                                          | 코드와 연결 상태                                                                                         |
| ------------------- | ------------------------------------------------- | -------------------------------------------------------------------------------------------------------- |
| 여행·공유           | `createTrip`, `createShareCode`, `joinTrip`       | [src/share/trips.ts](src/share/trips.ts), 구현됨                                                         |
| 내 여행·참여자 연결 | `listMyTrips`, `linkMyParticipant`                | [src/share/tripManagement.ts](src/share/tripManagement.ts), 구현됨                                       |
| 장소 검색·링크      | `searchPlaces`, `parsePlaceLink`                  | [src/places/places.ts](src/places/places.ts), 인증·멤버·입력 검증과 Emulator fixture, 외부 Google 미연결 |
| 지출 CRUD           | `createExpense`, `updateExpense`, `deleteExpense` | [src/settlement/expenses.ts](src/settlement/expenses.ts), 구현됨                                         |
| 영수증 검토 후보    | `parseReceipt`                                    | [src/ocr/receipts.ts](src/ocr/receipts.ts), 입력 검증과 Emulator fixture, 외부 OCR 미연결                |

장소·OCR 함수는 현재 Emulator 밖에서 `unavailable`을 반환합니다. 기존 itemized·OCR 선행 구현과 회귀는 유지하되 실제 OCR 연결을 현재 B의 필수 작업으로 착각하지 않습니다. 일정·장소·준비 CRUD는 Flutter repository와 Firestore Rules 경계이며, 시트용 서버 함수를 추가하지 않습니다.

## 실행

Node.js 22·Java 21을 준비합니다. 백엔드 담당은 Flutter SDK 없이 시작할 수 있습니다. 아래 명령은 **모두 저장소 루트**에서 실행합니다.

```bash
# 최초 의존성 설치
npm ci

# Functions 빌드와 backend 단위 테스트
npm run build --workspace backend
npm test --workspace backend
```

Emulator 상시 실행과 일회성 통합 테스트는 같은 포트를 사용하므로 동시에 실행하지 않습니다.

```bash
# 저장소 루트에서 Auth, Firestore, Functions Emulator 시작
npm run dev:backend

# 전체 Emulator 통합 테스트
npm run test:emulator

# 작업 중 공통 검증 / dev 반영 전 전체 검증
npm run verify:fast
npm run verify:full
```

Emulator 시작 명령은 Functions를 먼저 빌드하고 과금되지 않는 `demo-trip-split` 프로젝트 ID를 명시합니다.

각자 별도 clone의 `dev`에서 작업하고 시작 전·push 직전에 최신 `origin/dev`를 확인합니다. 원격 변경을 통합하면 검증을 다시 실행하고, 승인된 파일만 `dev`에 반영합니다. commit·push·PR은 각 요청의 승인 범위를 따르며 `main`은 릴리스 PR로 관리합니다.

외부 API secret은 클라이언트나 Git에 저장하지 않고 Functions secret/environment에서만 사용합니다. 실제 환경 연결·secret 등록·유료 호출·배포는 승인된 범위에서만 수행합니다. Android Emulator 클라이언트의 host는 `10.0.2.2`이며, Emulator 회귀 통과와 실제 API·두 Android 기기 QA 완료는 따로 기록합니다.
