# Firebase Feature Evolution

## 0. 현재 반영된 방향

이 문서의 논의 결과는 `product.md`, `requirements.md`, `tech.md`, `structure.md`, `task/` 문서에 반영한다.

현재 채택한 방향은 다음과 같다.

- Firebase BaaS를 백엔드로 사용한다.
- 제품은 국내 여행과 KRW를 기준으로 한 모바일 우선 웹/PWA MVP이며, 지도는 네이버 지도 API를 사용한다.
- 앱은 사용자-facing 로그인 장벽 없이 시작한다.
- 내부적으로 Firebase Anonymous Auth로 `uid`를 발급한다.
- Google 로그인은 선택 연결로 제공해 내 여행 목록과 사용자 프로필을 저장한다.
- 공유 코드와 초대 링크는 여행 세션 입장 키로 사용한다.
- 공유 코드나 초대 링크로 들어온 사용자는 `trips/{tripId}/members/{uid}`의 `TripMember`로 등록된다.
- 장소, 일정, 지출은 Firestore 실시간 구독으로 동기화한다.
- 인증·공동 편집 사용자인 `TripMember`와 지출의 결제자·소비자인 `Participant`를 분리한다.
- 정산은 개인 결제액, 개인 부담액, 정산 결과를 구분하고 전체 균등·항목별·직접 부담액 분할을 지원한다.
- OCR은 수정 가능한 항목 초안을 반환하며 사용자가 최종 저장하기 전에는 지출 원장에 반영하지 않는다.
- 영수증 이미지는 Firebase Storage에 영구 저장하지 않는다.
- `.trip.json`은 핵심 공유 방식이 아니라 백업, 복원, 데모 데이터 용도로 사용한다.

## 1. 핵심 변화

초기에는 로컬 저장, `.trip.json` 파일 공유, 단순 공유 링크를 중심으로 생각했다. Firebase BaaS를 사용하면 Trip Split은 단순 로컬 도구가 아니라 실시간 협업 여행 세션으로 확장할 수 있다.

핵심 변화는 다음과 같다.

```text
로컬 저장 앱
  -> Firebase 기반 공동 편집 앱

파일 공유
  -> 공유 코드 / 초대 링크 / 멤버 세션

로그인 없음
  -> 사용자-facing 로그인 없음 + 내부 익명 인증
  -> 선택적 Google 로그인 연결

정적 정산 결과
  -> 실시간 공동 지출 원장 + 개인 결제액/부담액/정산 결과 계산
  -> 정산 확정/송금 상태는 후속

단순 일정표
  -> Firestore에 실시간 반영되는 협업 일정
  -> 상세 변경 이력은 후속
```

## 2. 인증과 사용자 정보

### 과거 방향

- 로그인 없이 사용
- 공유 코드만 있으면 여행 접근
- 사용자 구분이 약함

### 현재 / MVP

- 기본 진입은 Firebase Anonymous Auth로 처리
- 사용자는 로그인 화면을 보지 않아도 내부적으로 `uid`를 가진다
- 선택적으로 Google 로그인을 연결하며 기존 익명 `uid`와 여행 접근 권한 유지
- Google 로그인 시 프로필, 이메일, 사진과 멤버십 기반 내 여행 목록 저장 가능
- `TripMember`는 `uid`를 가진 인증·공동 편집 사용자로 `trips/{tripId}/members/{uid}`에 저장
- `Participant`는 결제자 또는 소비자가 되는 정산 대상이며, 로그인하지 않은 동행도 포함
- `Participant.linkedUid`로 두 대상을 선택적으로 연결하되 동일한 엔터티로 합치지 않음. 같은 여행의 member만 참조하며 여행 안에서 중복 연결하지 않음

### 후속 기능

- 최근 본 여행
- 만든 여행·참여한 여행의 고급 필터와 보관 처리
- 여러 기기·계정 사이의 복구 정책

## 3. 공유 코드와 여행 세션

### 과거 방향

- 공유 코드 또는 초대 링크로 여행 접근
- 모든 사람이 편집 가능

### 현재 / MVP

공유 코드는 단순 문자열이 아니라 여행 세션 입장 키가 된다.

```text
shareCodes/{code}
  tripId
  expiresAt
  createdBy
  maxUses
  isActive

trips/{tripId}/members/{uid}
  displayName
  role
  joinedAt
  lastActiveAt
```

코드나 링크 검증이 성공하면 현재 익명 `uid`를 `TripMember`로 등록하고, 같은 여행의 장소·일정·지출 구독을 시작한다. 정산 대상 `Participant`는 필요할 때 별도로 만들고 `linkedUid`로 연결한다.

### 후속 기능

- 공유 코드 만료
- 초대 링크 재생성
- 현재 접속 중인 사람 표시
- 여행장/편집자/보기 전용 권한
- 정산만 보기 링크
- 초대 받은 사람 목록

## 4. 실시간 공동 편집

### 과거 방향

- 각자 파일을 가져오거나 링크로 데이터 확인
- 동시 편집 고려가 약함

### 현재 / MVP

Firestore `onSnapshot` 기반으로 일정, 장소, 지출 변경이 실시간 반영된다.

- 일정 추가·수정은 다른 멤버의 일정 화면과 지도에 반영
- 장소 추가·수정은 장소 보관함과 지도에 반영
- 지출 추가·수정은 개인 소비와 정산 결과를 재계산
- `Participant` 이름 변경은 지출·정산 화면에 반영
- 합계나 순서처럼 충돌 가능성이 큰 쓰기는 transaction 또는 batch로 처리

### 후속 기능

- 누가 수정 중인지 표시
- 마지막 수정 시간 표시
- 세부 변경 이력과 충돌 해결 UI

## 5. 장소 기능

### 과거 방향

- 장소 검색
- 네이버 장소 링크 붙여넣기
- 직접 입력
- 네이버 저장 리스트 import는 실험 기능

### 현재 / MVP

장소는 여행 세션의 공동 장소 보관함이 된다. MVP는 네이버 장소 검색, 네이버 장소 링크 붙여넣기, 직접 입력을 지원하고 모두 앱 내부 `Place` 구조로 정규화한다. 네이버 저장 목록 자동 가져오기는 공식 API와 약관을 검증하는 실험으로만 분류하며 MVP의 정상 흐름이 의존하지 않게 한다.

```text
trips/{tripId}/places/{placeId}
  name
  address
  lat
  lng
  provider
  providerPlaceId
  sourceUrl
  addedBy
  createdAt
  memo
```

### 후속 기능

- 누가 추가한 장소인지 표시
- 장소 후보 투표
- 장소별 메모/태그
- 장소 채택/보류 상태
- 일정에 이미 사용된 장소 표시
- 장소별 예상 비용
- 장소별 연결된 지출 보기
- 장소 링크 파싱 결과 캐싱

## 6. 타임테이블 기능

### 과거 방향

- 날짜별 시간표
- 장소 연결
- 순서 변경 시 지도 핀과 동선 변경

### 현재 / MVP

타임테이블은 공동 편집 가능한 일정 데이터가 된다.

```text
trips/{tripId}/itinerary/{itemId}
  date
  startTime
  endTime
  placeId
  title
  memo
  order
  updatedBy
  updatedAt
```

일정 추가·수정·삭제와 순서 변경은 실시간 반영하며, 정렬 결과는 batch write로 저장해 일정 `order`, 지도 핀 번호와 직선 동선이 같은 순서를 보게 한다.

### 후속 기능

- 일정별 댓글 스레드
- 일정 확정 상태
- 선택 일정과 필수 일정 구분
- 일정별 예상 비용
- 일정 화면에서 연결 지출 목록과 합계를 모아 보는 분석 UI
- 일정 변경 이력

## 7. 지도 기능

### 과거 방향

- 네이버 지도 표시
- 일정 순서 번호 핀
- 날짜별 직선 동선
- 실제 경로 계산은 이후

### 현재 / MVP

지도는 Firestore의 장소/일정 데이터를 구독하는 네이버 지도 기반 실시간 뷰가 된다. MVP는 일정 순서 번호 핀, 날짜별 색상, 같은 날짜 장소 사이의 직선 동선까지만 제공한다.

다른 멤버가 장소 또는 일정 순서를 변경하면 지도 핀과 직선 동선도 실시간으로 갱신한다.

### 후속 기능

- 날짜별 표시 토글 저장
- 사용자별 지도 필터 preference 저장
- 좌표 없는 장소 목록 자동 표시
- 장소 링크 파싱 실패 항목 관리
- 실제 도로 경로와 교통수단별 예상 시간 계산
- 경로 계산 결과 캐싱
- 지도 스타일 설정 저장
- 해외 여행 모드와 Google Maps provider

## 8. 정산 기능

### 과거 방향

- 지출 항목 입력
- 결제자와 참여자 선택
- 균등 분할
- 최종 송금액 계산
- 정산 문구 복사

### 현재 / MVP

정산은 공동 `Expense` 원장과 파생 계산 기능으로 발전한다. MVP에서는 확정·송금 상태를 별도 원장으로 저장하지 않는다.

```text
trips/{tripId}/participants/{participantId}
  name
  color
  linkedUid
  isActive
  createdAt
  updatedAt

trips/{tripId}/expenses/{expenseId}
  title
  category
  expenseDate
  totalAmount              # KRW 원 단위 정수
  currency                 # MVP: KRW
  payer                    # { participantId, amount }
  consumers                # participantId[]
  allocationMethod         # equal | itemized | custom
  allocatedAmounts         # [{ participantId, amount }]
  receiptItems             # ReceiptItem[]
  source                    # manual | ocr
  placeId
  itineraryItemId
  memo
  createdBy
  updatedBy
  createdAt
  updatedAt
```

`ReceiptItem`은 일반 메뉴, 할인, 봉사료, 기타 조정을 나타내며 항목명, 금액, 소비자, `equal | custom` 분할 방식과 참여자별 배분 금액을 가진다. 일반 항목과 봉사료는 양수, 할인은 음수, 기타 조정은 0이 아닌 양수 또는 음수로 기록한다. 전체 지출 분할은 다음 세 방식을 지원한다.

- `equal`: 영수증 또는 지출 전체를 선택한 소비자끼리 균등 분할
- `itemized`: 메뉴·항목별 소비자를 지정하고 공용 항목은 선택한 소비자끼리 균등 또는 직접 금액으로 분할
- `custom`: 지출 전체의 참여자별 부담 금액을 직접 입력

모든 KRW 금액은 원 단위 정수로 저장한다. 균등 분할의 1원 나머지는 UI에 표시된 소비자 순서대로 배분하며, 지출과 각 항목의 배분 금액 합은 해당 총액과 일치해야 한다.

개인 정산은 다음 세 값을 분리한다.

- 개인 결제액: 자신이 `payer`인 지출 금액의 합계
- 개인 부담액: `allocatedAmounts`에서 자신에게 배분된 금액의 합계
- 정산 결과: `개인 결제액 - 개인 부담액`; 양수는 받을 금액, 음수는 보낼 금액

개인 화면은 위 세 값뿐 아니라 카테고리별 소비 합계와 날짜·장소·메뉴 또는 지출 항목별 개인 소비 내역을 제공한다. `allocatedAmounts`는 저장된 정산 원장의 기준값이고, 송금 관계는 이 원장에서 계산한 파생 결과다.

### 후속 기능

- 누가 지출을 추가했는지 표시
- 지출 확정/미확정
- 정산 완료 체크
- 송금 완료 상태
- 사람별 미정산 금액
- 정산 결과 snapshot 저장
- 정산 결과 공유 링크
- 지출 수정 이력
- 영수증 문맥을 이용한 소비자 자동 추론
- 운전자 보상, 숙소 선결제 같은 특수 규칙

## 9. OCR 기능

### 과거 방향

- 로컬 이미지 선택
- CLOVA OCR로 텍스트 추출
- 사용자가 확인 후 지출 등록
- 이미지는 저장하지 않는 방향

### 현재 / MVP

MVP의 OCR은 영구 작업 큐가 아니라 사용자 검토를 전제로 한 일회성 변환 흐름이다.

```text
로컬 영수증 이미지 선택
  -> Cloud Function parseReceipt
  -> CLOVA OCR 일시 전송
  -> 수정 가능한 ReceiptItem 초안 반환
  -> 항목명/금액 수정, 누락 항목 수동 추가
  -> 소비자와 equal/custom 배분 지정
  -> 사용자 최종 저장
  -> Expense 원장 및 정산 결과에 반영
```

OCR이 실패하거나 항목 합계를 신뢰할 수 없으면 전체 금액 기반 수동 지출 등록으로 전환한다. 사용자가 최종 저장하기 전에는 OCR 초안을 Firestore 원장에 반영하지 않으며, 영수증 이미지는 Firebase Storage에 영구 저장하지 않는다.

### 후속 기능

- OCR 비동기 처리 상태와 검토 대기 목록
- OCR 초안 보관과 실패 재시도 이력
- 금액·상호명·일정·장소 후보 자동 연결
- 영수증 문맥을 이용한 소비자 자동 추론
- 사용자가 명시적으로 선택하는 이미지 보관 옵션

```text
trips/{tripId}/receiptJobs/{jobId}
  status
  requestedBy
  extractedDraft
  linkedExpenseId
  createdAt
  updatedAt
```

## 10. `.trip.json` 기능의 위치 변경

### 과거 방향

- 서버 없는 공유의 핵심 수단

### 현재 / MVP

`.trip.json`은 핵심 공유 방식이 아니라 백업, 복원, 데모 데이터 기능이 된다. 공유 코드와 초대 링크가 일상적인 공동 작업 진입점이다.

- 여행 백업 내보내기
- 백업 복원
- 테스트·시연용 데모 데이터 불러오기

### 후속 기능

- 여행 복제
- Firebase 장애 시 export
- 다른 계정으로 여행 이전
- 버전 마이그레이션 테스트

## 11. 알림과 활동 기록

Firebase를 쓰면 MVP 이후 알림과 활동 기록을 붙일 수 있다.

### 후속 기능

- 최근 활동 피드
- "민수가 장소를 추가했어요"
- "지현이 지출을 등록했어요"
- "정산 결과가 변경됐어요"
- 일정 변경 알림
- 정산 요청 알림
- 여행 전날 체크 알림

후속 단계에서 활동 기록을 도입할 때는 푸시 알림보다 앱 내부 활동 피드를 먼저 구현한다.

## 12. 권한 모델

### MVP

```text
공유 코드/링크로 들어온 사람 = 편집 가능
```

### 확장

```text
owner: 여행 설정, 공유 코드 관리, 멤버 관리
editor: 일정, 장소, 지출 편집
viewer: 보기만 가능
settlementViewer: 정산 결과만 보기
```

### 후속 기능

- 공유 링크별 권한 설정
- 정산 결과만 공유
- 장소 후보만 편집 가능
- 여행장이 정산 확정
- 멤버 내보내기

## 13. Firebase 전환으로 우선순위가 바뀌는 기능

### 현재 / MVP 우선순위

- 익명 인증
- Google 로그인 연결
- Firestore 보안 규칙
- 공유 코드 검증 Cloud Function
- `members`와 `participants` 컬렉션 분리
- 실시간 구독 구조
- 작성자/수정자 기록
- `Expense`, `ReceiptItem`, `allocatedAmounts` 원장과 정산 불변식
- `parseReceipt` Cloud Function과 저장 전 OCR 검토 흐름

### 후속 우선순위

- 활동 피드와 변경 이력
- 세부 권한 모델
- 정산 완료·송금 상태와 정산 snapshot
- 영구 `receiptJobs`와 OCR 재시도 큐
- 실제 경로·예상 시간 및 해외 Google Maps 연동

### 중요도가 내려가는 기능

- `.trip.json` 기반 공유
- 완전 로컬 저장
- 단순 클립보드 공유만으로 협업 처리

### 제품 핵심으로 유지되는 기능

- 네이버 장소 검색·링크 붙여넣기·직접 입력
- 타임테이블
- 번호 핀과 직선 동선
- 개인 결제액·부담액·정산 결과를 구분하는 정산 엔진
- 항목별 분할과 수정 가능한 OCR 초안

## 14. 추천 MVP 재정의

Firebase를 적극 활용한다면 MVP는 다음처럼 재정의하는 것이 좋다.

```text
1. 국내/KRW 기준 모바일 우선 PWA로 시작하고 네이버 지도를 사용한다.
2. 사용자는 로그인 화면 없이 앱에 들어오며 내부적으로 익명 uid를 발급받는다.
3. 여행을 만들면 공유 코드와 초대 링크가 생성된다.
4. 친구가 코드나 링크로 들어오면 같은 tripId의 TripMember가 된다.
5. 정산 대상 Participant는 TripMember와 분리하며 linkedUid로 선택 연결한다.
6. 네이버 장소, 일정, Expense는 Firestore에 저장되고 실시간 반영된다.
7. 정산은 equal/itemized/custom 배분으로 결제액·부담액·정산 결과를 재계산한다.
8. 개인 화면은 카테고리 및 날짜·장소·메뉴/지출별 소비 내역을 제공한다.
9. OCR은 수정 가능한 항목 초안을 반환하고 사용자가 저장할 때만 Expense가 된다.
10. Google 로그인은 선택 연결로 내 여행 목록과 프로필을 유지한다.
11. .trip.json은 공유가 아니라 백업·복원·데모 데이터에 사용한다.
```

## 15. 1차 구현 추천

1. 모바일 우선 앱 셸, Firebase 클라이언트와 에뮬레이터, Anonymous Auth
2. `users/{uid}`와 여행·생성자 멤버·첫 코드를 원자적으로 만드는 `createTrip`, 코드 재생성용 `createShareCode`, 입장용 `joinTrip` Function
3. `participants`, `expenses` 공통 타입과 원 단위 정산 불변식 및 순수 계산 테스트
4. 외부 API 없이 개발할 장소·일정·정산 mock repository와 강릉 fixture
5. 네이버 장소 검색·링크 파싱·직접 입력, 일정, 번호 핀과 직선 동선
6. 장소·일정·지출 Firestore 실시간 구독
7. 수동 지출 입력, 전체 균등·항목별·직접 금액 분할, 개인 소비 화면
8. `parseReceipt` Cloud Function, OCR 항목 검토와 전체 금액 수동 fallback
9. Google 로그인 계정 연결
10. PWA, `.trip.json` 백업·복원, 통합 QA

활동 로그, 세부 권한, 정산 상태/snapshot, 영구 OCR 작업 큐는 MVP 이후에 구현한다.
