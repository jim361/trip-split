# 일정·지도 백엔드 SPEC

> 담당: 일정·지도 백엔드. 작성일: 2026-09-14. 확인 기준: `dev` / `a5cfb0ac98327ec709adde6964440178a4dfa9a1`.
> 이 문서는 TASK-03/04/05의 담당자 실행 명세다. 팀 공통 계약을 대체하지 않으며, 현재 착수 단계는 Phase B(P0)다.

## 1. 목표와 기준 자료

기존 장소 검색·링크 Callable을 유지하면서 입력·권한·실패 처리를 보강하고, 승인된 환경에서 Google Places를 연결한다. 일정·장소·예약·체크리스트의 참조와 동시 변경은 실제 저장 경계에서 검증한다.

- [최신 개발 시작 안내](../../../docs/development-kickoff.md): 단계·역할·완료 조건.
- [화면·API 인계](../../../docs/frontend-api-handoff.md), [Firebase API 계약](../../../docs/firebase-api-contract.md): 현재 구현과 wire.
- [기술 계약](../../../MarkDown/tech.md), [작업 인덱스](../../../MarkDown/task/tasks.md): 데이터·기능 ID·제품 제약.
- [실행 계획](plan.md), [작업 목록·인계 기록](tasks.md), [작업 지침](AGENT.md).

공통 진입점은 [백엔드 안내](../../README.md)다. 현재 코드와 최신 인계를 함께 확인하며, 문서 간 계약 충돌은 통합 담당에게 공유한다. 예전 이슈 #16/#18을 현재 미구현 목록으로 사용하지 않는다.

## 2. 파일 소유권

아래 경로는 저장소 루트 기준이다. 읽기는 서로의 구현까지 허용하고, 쓰기는 담당 범위로 제한한다. 폴더 분리는 협업 규칙이며 Git 권한이나 강제 차단 장치는 아니다.

| 구분                  | 경로                                                                                                                             | 이 담당자의 작업                                                     |
| --------------------- | -------------------------------------------------------------------------------------------------------------------------------- | -------------------------------------------------------------------- |
| 전용 문서             | `backend/workstreams/itinerary-map/`                                                                                             | 이 네 문서·결정·검증·인계 기록 관리                                  |
| 전용 구현·단위 테스트 | `backend/src/places/`                                                                                                            | 기존 handler와 회귀 테스트 수정. 필요한 구현 파일만 같은 폴더에 추가 |
| 전용 Emulator 테스트  | `backend/tests/emulator/itinerary-map/`                                                                                          | 새 일정·장소·준비 테스트를 구현할 때 생성                            |
| 다른 백엔드 영역      | `backend/src/settlement/`, `backend/src/ocr/`                                                                                    | 읽기·영향 확인. 직접 수정하지 않음                                   |
| 공용 Emulator 테스트  | `backend/tests/emulator/domain-flows.emulator.test.ts`, `trip-share.emulator.test.ts`                                            | 기존 회귀 유지. 수정·이동·공통 helper 추출은 먼저 조율               |
| 공통·통합 영역        | `backend/src/share/`, `backend/src/shared/`, `backend/src/index.ts`, `backend/firestore.rules`, `backend/firestore.indexes.json` | 재현과 변경안을 작성하고 통합 담당이 최종 반영                       |
| 공통 설정·계약        | 루트·backend의 package/config, lockfile, `firebase.json`, `.env.example`, `AGENTS.md`, `docs/`, `MarkDown/`, CI                  | 변경 이유·호출자 영향·검증안을 먼저 공유                             |
| 프론트 영역           | `frontend/` 전체                                                                                                                 | Flutter repository·모델·지도 adapter·두 기기 QA를 통합 담당과 협업   |

기존 소스를 전용 문서 폴더로 옮기지 않는다. 별도 Functions 프로젝트·package·공통 검증 프레임워크를 만들지 않는다. 모든 작업에 `IMB-*` ID를 사용하고 기존 `TASK-*`, `IT-*`, `PREP-*` ID는 유지한다.

## 3. 현재 동작과 유지할 계약

호출 흐름은 `FirebasePlaceProvider → searchPlaces/parsePlaceLink → 공통 입력·Auth·멤버 검사 → 장소 후보`다. 선택한 후보의 저장과 일정·준비 CRUD는 Flutter `FirestoreTripRepositories → Firestore Rules`에서 처리한다. 장소 검색 함수에 CRUD를 덧붙이지 않는다.

| Callable         | 입력                                                 | 반환과 의미                                              |
| ---------------- | ---------------------------------------------------- | -------------------------------------------------------- |
| `searchPlaces`   | `{ tripId, query: string }`, query는 trim 후 1~160자 | `PlaceCandidate[]`. 정상 검색의 일치 결과가 없으면 `[]`  |
| `parsePlaceLink` | `{ tripId, url: string }`, URL은 trim 후 1~2048자    | `PlaceCandidate` 한 개. 해석된 장소가 없으면 `not-found` |

- `PlaceCandidate` 필수 필드는 `name`, `provider`, `source`이고 선택 필드는 `address`, `lat`, `lng`, `providerPlaceId`, `sourceUrl`, `memo`다. 저장 ID·tripId·감사 필드를 검색 응답에 새로 요구하지 않는다.
- 이름은 trim 후 1~~160자, 좌표는 둘 다 생략하거나 유한한 수로 위도 -90~~90·경도 -180~180 범위여야 한다. 외부 응답도 신뢰하지 않고 검사한다.
- Google 여행에서 `provider=google`을 사용한다. 검색은 `source=googleSearch`, 링크는 `source=googleMapsUrl`이며 링크의 `sourceUrl`을 유지한다.
- 입력과 여행 멤버십 검증을 통과하기 전에는 외부 요청을 보내지 않는다. `TripMember.uid`와 `Participant.id`를 혼용하지 않는다.
- 현재는 Emulator fixture만 반환한다. 외부 연결 전 운영 환경은 `unavailable` / `retryable=false`다. 운영에서 fixture로 성공을 흉내 내지 않는다.
- Callable 이름·응답 형태·Firestore 경로·기존 오류 체계는 유지한다. 새 필드나 오류 코드는 통합 담당과 합의한 뒤 반영한다.

## 4. 검색·링크·오류 수용 기준

### 검색과 provider

- 정상 결과·빈 결과·유효하지 않은 provider 응답을 서로 구분한다. 잘못된 좌표·이름을 성공 후보로 넘기지 않는다.
- 외부 연결 코드는 기존 helper와 Node 22의 `fetch`, `URL`, `AbortController` 계열 기능부터 사용한다. 테스트는 기존 Vitest로 외부 응답을 대체하며 실제 유료 호출을 하지 않는다.
- 외부 요청의 전체 시간 제한과 응답 크기를 제한한다. 호출량 제한·예산·secret 사용 위치는 연결 전에 정한다. 자동 반복 재시도로 비용을 늘리지 않는다.
- provider 원문·키·사용자가 붙여 넣은 전체 URL을 오류나 로그에 그대로 내보내지 않는다. 오류 분류·소요 시간·호출 수 등 필요한 진단 정보만 남긴다.

### 링크 지원 범위

| 형식                                                             | 현재 상태           | 다음 단계                                                 |
| ---------------------------------------------------------------- | ------------------- | --------------------------------------------------------- |
| HTTPS `maps.google.com`의 `q`/`query`                            | 지원                | 기존 성공·실패 사례 유지                                  |
| HTTPS `google.com`·`www.google.com`의 `/maps` 경로와 `q`/`query` | 지원                | 인코딩·빈 값·길이 경계 회귀 보강                          |
| 장소 ID를 담은 일반 Maps URL, `/maps/place/...`                  | 아직 일반 지원 아님 | 실제 fixture로 장소 식별 가능성을 확인하고 지원 목록 합의 |
| `maps.app.goo.gl` 등 단축 링크                                   | 현재 거부           | 허용할 호스트·redirect 정책을 합의한 경우에만 추가        |
| 임의 도메인·IP·HTTP·사용자 정보·비표준 포트                      | 거부                | 계속 거부                                                 |

단축 링크를 지원한다면 자동 redirect 추종에 맡기지 않고 매 단계의 HTTPS·정확한 호스트·경로·포트를 확인한다. 내부 주소·위장 호스트·redirect 순환·상한 초과를 차단하고 전체 시간 제한을 공유한다. 정확히 식별할 수 없는 링크를 임의의 다른 장소로 확정하지 않는다. 지원되지 않는 링크는 검색·직접 입력으로 복구한다.

### 오류 매핑 기준

`backend/src/shared/callable.ts`의 `appError()`와 Firebase `HttpsError`를 재사용한다. 아래 provider 행은 구현할 목표이며 아직 연결된 동작이 아니다.

| 상황                                       | 표준 code / `details.appCode`                        | `retryable` |
| ------------------------------------------ | ---------------------------------------------------- | ----------- |
| 미인증·비멤버                              | `unauthenticated` 또는 `permission-denied` / 같은 값 | false       |
| 잘못된 입력·지원하지 않는 링크             | `invalid-argument` / 같은 값                         | false       |
| 링크에서 장소를 찾지 못함                  | `not-found` / 같은 값                                | false       |
| 외부 연결·키·권한 설정 미완료              | `unavailable` / 같은 값                              | false       |
| 일시적인 provider 장애·잘못된 응답         | `unavailable` / 같은 값                              | true        |
| 시간 초과                                  | `deadline-exceeded` / `unavailable`                  | true        |
| 일시적 호출 제한                           | `resource-exhausted` / 같은 값                       | true        |
| 일일 할당량·예산 소진처럼 즉시 재시도 불가 | `resource-exhausted` / 같은 값                       | false       |

provider가 일시 제한과 할당량 소진을 구분할 근거를 주지 않으면 즉시 재시도를 유도하지 않는다. `retryable=true`는 자동 재호출 지시가 아니다. 입력 오류의 `details.field`를 유지하며 URL 해석 오류는 기존 `sourceUrl` 필드를 따른다.

## 5. 참조·동시 변경 검증

현재 Rules의 `itinerary.placeId`는 비어 있지 않은 문자열만 확인한다. 실제 장소 존재·같은 여행 소속은 보장하지 않는다. 장소 삭제도 멤버 여부만 검사하므로 화면의 참조 확인만으로 연결·삭제 경합을 막을 수 없다.

- 장소 없는 일정과 정상 연결·해제는 허용되어야 한다. 없는 장소·다른 여행 장소의 연결은 재현하고, 같은 여행 참조를 저장 시 검사하는 변경안을 통합 담당에게 제시한다.
- 예약은 저장 시 같은 여행의 일정 존재, 체크리스트는 담당 참여자 존재를 이미 검사한다. 저장 후 대상 삭제·동시 변경까지 보장하는지 별도로 확인한다. `personal`은 비공개 권한이 아니다.
- 일정 재정렬은 기존 Flutter transaction이 대상 존재·날짜·A/B를 읽고 `order`만 일괄 변경한다. 동시 이동·삭제는 실패 후 재조회, 동시 추가는 유지, 동일 order는 ID로 정렬하는 정책을 검증한다.
- Emulator에서 직접 Firestore를 조작하는 테스트는 Rules·데이터 상태 검증이다. 이것만으로 실제 Dart transaction이나 Android 두 기기 동작 검증을 대체하지 않는다.
- 장소 삭제 정책은 **미확정**이다. 참조 중 삭제 거부, 명시적 연결 해제 등 UX와 서버 보장 범위를 합의한다. Rules에서 임의 컬렉션 역참조 검색이 가능한 것으로 가정하지 않는다. 일반 쓰기에 `exists()`를 추가하는 것만으로 동시 삭제까지 해결됐다고 판단하지 않는다.
- 역참조 문서·삭제 Callable·transaction·모델 변경이 필요하면 경쟁하는 양쪽 쓰기 경로와 비용을 포함한 최소 변경안을 먼저 공유한다. 정산의 장소·일정 참조도 함께 확인하고 다른 백엔드 코드를 직접 수정하지 않는다.

## 6. 제외 범위와 완료 조건

이번 담당 범위에서 Flutter 화면·repository·지도 SDK를 구현하거나 시트용 서버 함수를 만들지 않는다. OCR·번역·정산 알고리즘, NAVER, Routes API·자동 이동 시간, Gemini, 백업 서버, 운영 배포는 추가하지 않는다. 기존 P1 구현과 회귀는 유지한다.

담당 완료는 입력·권한·오류·참조·동시 변경 회귀, 합의된 Google 연결·URL 사례, `npm run verify:full` 결과와 프론트 인계 증거가 모두 있을 때 표시한다. 로컬 문서 작성, Emulator 통과, 승인된 실제 API 확인, Android 두 기기 QA를 각각 구분한다. Phase B 전체 완료 판정은 통합 담당의 공통 체크리스트를 따른다.
