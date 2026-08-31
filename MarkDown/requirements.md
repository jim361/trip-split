# Trip Split MVP Requirements Draft

> **[계약 02 · 요구사항]** 기능 요구사항과 MVP 완료 조건입니다.

## 1. MVP 목표

2026년 11월 도쿄 여행을 첫 검증 시나리오로 장소, 일정, 준비, 비용과 OCR을 함께 다루는 Firebase 기반 Android 앱을 만든다. 클라이언트는 Flutter stable과 Dart, 백엔드는 기존 Node.js 22·TypeScript Firebase Functions를 사용한다. 지도는 Google Maps, 첫 fixture 통화는 JPY를 기준으로 하며 Flutter Web과 iOS는 첫 Android MVP 이후의 별도 타깃이다.

구현은 두 단계로 나눈다. P0는 Flutter 기반·여행 세션·Google 일정/지도·최소 준비·수동 equal/custom 정산이고, P1은 itemized 정산·영수증 OCR/번역·내 여행 목록과 Android 배포 품질이다. P0를 통과하기 전에 P1 외부 API를 연결하지 않는다.

## 2. 사용자 전제

- 사용자는 별도 회원가입 화면 없이 여행을 만들 수 있다.
- 앱은 내부적으로 Firebase Anonymous Auth를 사용해 사용자를 구분한다.
- 사용자는 선택적으로 Google 로그인을 연결할 수 있다.
- Google 로그인 사용자는 내 여행 목록과 프로필을 유지할 수 있다.
- 여행장은 공유 코드를 전달한다.
- 사용자는 공유 코드로 같은 여행 세션에 접근해 `TripMember`가 된다. Android App Links 초대는 후속 범위다.
- MVP에서는 공유 코드로 입장한 모든 `TripMember`가 일정과 검증된 지출을 편집할 수 있다.

## 3. 여행 세션, `TripMember`, `Participant`

- 여행은 하나의 Firebase 여행 세션으로 생성된다.
- 여행은 제목, 날짜, 국가·time zone, 기본 통화, 지도 provider, 공유 코드와 생성자 정보를 가진다.
- 여행 생성 시 예상 인원을 입력하고 그 수만큼 이름을 수정할 수 있는 `Participant` 초안을 만든다.
- 여행마다 공동 편집 멤버 목록과 정산 참여자 목록을 각각 가진다.
- `TripMember`는 Firebase `uid`를 가진 인증·공동 편집 사용자이며, MVP에서는 공유 코드로 등록된다.
- `TripMember`는 표시 이름, 프로필 이미지, role, 입장 시각, 마지막 활동 시각을 가진다.
- `Participant`는 지출의 결제자 또는 소비자가 될 수 있는 정산 대상이며, 앱에 접속하지 않은 동행도 포함할 수 있다.
- `Participant.linkedUid`로 같은 여행의 `TripMember`와 선택적으로 연결할 수 있지만 두 개념을 동일하게 취급하지 않는다. 한 여행에서 같은 `linkedUid`를 여러 `Participant`에 연결할 수 없다.
- MVP의 기본 role은 `editor`다.
- owner/editor/viewer 같은 세부 권한은 MVP 이후 기능으로 둔다.

## 4. 일정 기능

- 여행은 여러 날짜를 가질 수 있다.
- 각 날짜는 시간대별 타임테이블을 가진다.
- 타임테이블 항목은 시작 시간, 선택적 종료 시간, 장소, 메모, 작성자, 수정 시각을 가진다.
- 사용자는 시간대별로 언제 어디에 갈지 입력할 수 있다.
- 장소가 연결된 일정 항목은 지도에 표시된다.
- 일정 순서가 바뀌면 지도 핀 번호와 직선 동선 순서도 함께 바뀐다.
- 일정 데이터는 Firestore 실시간 구독으로 다른 `TripMember`에게 반영된다.

## 5. 장소 기능

- 사용자는 장소를 검색하거나 직접 입력할 수 있다.
- 사용자는 지원하는 Google Maps 장소 URL을 붙여넣어 장소를 추가할 수 있다.
- 장소는 이름, 주소, 좌표, 메모, `provider`, `source`, `providerPlaceId`, `sourceUrl`, `addedBy`를 가진다.
- 장소 링크 붙여넣기는 장소명, 주소, 좌표 추출을 시도한다.
- 링크에서 정보를 가져오지 못하면 사용자가 검색 후보를 선택하거나 직접 입력한다.
- 장소는 여행 세션의 공동 장소 보관함에 저장된다.
- 장소가 추가, 수정, 삭제되면 다른 `TripMember` 화면에 실시간 반영된다.
- Google URL에서 정보를 얻지 못하면 검색 또는 직접 입력으로 전환한다.
- 국내 NAVER provider와 저장 목록 import는 첫 Android MVP 이후 범위다. 비공개 내부 API에는 의존하지 않는다.

## 6. 지도 기능

- 지도에는 일정에 포함된 장소가 핀으로 표시된다.
- 핀에는 날짜별 색상과 일정 순서 번호를 표시한다.
- 같은 날짜의 장소는 타임테이블 순서대로 직선으로 연결한다.
- 직선 동선은 실제 도로 경로가 아니라 일정 순서 시각화 용도다.
- Map Styling은 지도 배경과 기본 지도 요소를 조정해 커스텀 핀과 동선이 잘 보이도록 하는 용도로 사용한다.
- 범례에는 날짜별 색상과 "번호 순서대로 이동" 안내를 표시한다.
- 장소나 일정이 바뀌면 지도도 실시간 갱신된다.
- 실제 경로 계산, 이동 시간, 교통수단별 경로는 MVP 이후 기능으로 둔다.

## 7. 준비 기능

- 하단 내비게이션의 `준비`에는 항공·숙소·예약과 단순 체크리스트를 표시한다.
- 예약은 제목, 유형, 상태, URL, 메모와 연결된 일정 ID를 가질 수 있다.
- 체크리스트 항목은 제목, 완료 여부, 공동/개인 구분과 선택적 담당 Participant를 가진다.
- 여권 사본, 결제 카드 정보와 같은 민감한 파일은 저장하지 않는다.
- 예약 알림, 첨부 파일과 복잡한 업무 관리 기능은 첫 MVP 이후로 둔다.

## 8. 정산 기능

- `Participant`를 추가, 수정, 비활성화할 수 있다.
- `Expense`를 수동 입력하거나 검토가 끝난 OCR 초안에서 생성할 수 있다.
- `Expense`는 이름, 카테고리, 지출 날짜, 총액, 통화, `payer`, `consumers`, `allocationMethod`, `allocatedAmounts`, `receiptItems`, 장소, 일정, 메모, 작성자·수정자와 생성·수정 시각을 가진다.
- `payer`는 결제한 `participantId`와 금액을 가지며, MVP에서는 지출마다 한 명이 총액 전부를 결제한다.
- `consumers`는 비용을 부담하는 `Participant` 목록이고, `allocatedAmounts`는 참여자별 최종 부담 금액이다.
- `allocationMethod`는 `equal`, `itemized`, `custom`을 지원한다.
- `equal`은 영수증 또는 지출 전체를 선택한 소비자끼리 균등 분할한다.
- `itemized`는 메뉴 또는 항목별로 소비자를 지정하며, 공용 메뉴는 선택한 소비자끼리 균등 분할하거나 직접 금액을 입력할 수 있다.
- `custom`은 지출 전체의 참여자별 부담 금액을 직접 입력한다.
- `ReceiptItem`은 항목명, 금액, 종류, 소비자, 항목 분할 방식, 참여자별 배분 금액, 입력 출처, 표시 순서를 가진다.
- `ReceiptItem.kind`는 일반 항목, 할인, 봉사료, 기타 조정을 구분하고, 각 항목은 선택한 소비자에게 균등 또는 직접 금액으로 배분할 수 있다.
- 일반 항목과 봉사료는 양수, 할인은 음수, 기타 조정은 0이 아닌 양수 또는 음수로 기록하며 조정 반영 후 개인 최종 부담액은 음수가 될 수 없다.
- 금액은 ISO 4217 통화 코드와 해당 통화의 최소 단위 정수로 저장한다. JPY와 KRW는 정수 1이 각각 1엔과 1원이다.
- 균등 분할 나머지는 화면에 표시된 소비자 순서대로 최소 단위 1씩 배분한다.
- 서로 다른 통화의 결제액·부담액·정산 결과는 통화별로 분리하고 자동 환율 없이 합산하지 않는다.
- 지출의 `allocatedAmounts` 합계는 총액과 같아야 하며, `itemized`에서는 모든 `receiptItems` 금액 합계도 총액과 같아야 한다.
- 지출과 각 항목의 `allocatedAmounts`는 consumer마다 정확히 한 행을 가지며 `participantId`가 중복될 수 없다. 0원으로 계산된 consumer도 행을 유지한다.
- 지출이 변경되면 사람별 개인 결제액, 개인 부담액, 정산 결과를 다시 계산한다.
- 개인 결제액은 자신이 `payer`인 지출 금액의 합계다.
- 개인 부담액은 모든 `allocatedAmounts`에서 자신에게 배분된 금액의 합계다.
- 정산 결과는 `개인 결제액 - 개인 부담액`이며, 양수는 받을 금액, 음수는 보낼 금액이다.
- 개인 정산 화면은 개인 결제액, 개인 부담액, 받을 금액 또는 보낼 금액을 각각 표시한다.
- 개인 정산 화면은 카테고리별 개인 소비 합계와 날짜·장소·메뉴 또는 지출 항목별 개인 소비 내역을 제공한다.
- 지출 변경은 Firestore 실시간 구독으로 다른 `TripMember`에게 반영된다.
- 정산 결과를 복사해 공유할 수 있다.
- 정산 완료 체크, 송금 완료 상태, 정산 snapshot 저장은 MVP 이후 기능으로 둔다.

## 9. OCR·번역 기능

- 사용자는 Android 카메라 또는 시스템 Photo Picker에서 영수증 이미지를 선택할 수 있다.
- 앱은 MIME type, 파일 크기와 이미지 크기를 검사하고 외부 전송에 동의한 요청만 Cloud Functions의 provider-neutral `parseReceipt`로 전달한다.
- OCR provider는 클라이언트에 고정하지 않는다. 일본어 fixture를 기준으로 Document AI Expense Parser 또는 일반 OCR과 Translation 조합을 backend adapter에서 비교한다.
- MVP에서는 이미지 파일을 Firebase Storage에 영구 저장하지 않는다.
- OCR 응답은 원문 항목명, 한국어 번역 보조명, 금액·통화 후보, source language와 confidence를 가진 수정 가능한 초안으로 표시한다.
- 번역은 이해를 돕는 표시이며 수량과 금액 검증은 원문과 이미지가 기준이다.
- 사용자는 OCR이 추출한 항목명과 금액을 수정할 수 있다.
- 사용자는 OCR에서 누락된 항목, 할인, 봉사료, 기타 조정 금액을 수동으로 추가할 수 있다.
- 사용자는 각 항목의 소비자를 지정하고 균등 분할 또는 직접 부담액 입력을 선택할 수 있다.
- OCR 인식에 실패하거나 항목 합계를 신뢰할 수 없으면 전체 금액 기반 수동 지출 등록으로 전환할 수 있다.
- 사용자가 검토를 마치고 지출로 저장하기 전까지 OCR 초안은 Firestore 지출 원장과 정산 결과에 반영되지 않는다.
- MVP에서는 미확정 OCR 초안과 이미지를 별도 영구 저장하지 않는다.
- 지원 언어 밖의 영수증, 인식 실패와 낮은 confidence는 일반 OCR 또는 전체 금액 수동 등록으로 전환한다.
- OCR 비동기 작업 큐, 재시도 이력, 초안 보관, 이미지 저장 옵션과 소비자 자동 추론은 MVP 이후 기능으로 둔다.

## 10. 공유 기능

- 여행마다 공유 코드를 생성한다.
- 공유 코드 검증은 Cloud Function을 통해 처리한다.
- 유효한 공유 코드를 가진 사용자는 여행 멤버로 등록된다.
- 멤버로 등록된 사용자는 여행 정보를 확인하고 편집할 수 있다.
- MVP에서는 보기 전용, 편집 가능 같은 세부 권한을 나누지 않는다.
- 첫 공유 코드는 `createTrip`에서 만들고 만료일과 최대 사용 횟수를 두지 않는다.
- 재생성하면 기존 코드를 비활성화하고 새 코드만 활성화한다.
- `.trip.json` 내보내기/가져오기는 공유 핵심 기능이 아니라 백업 및 데이터 이전용으로 제공한다.

## 11. 사용자 정보 기능

- 익명 사용자는 임시 displayName을 가진다.
- Google 로그인 연결 시 displayName, email, photoURL을 저장할 수 있다.
- 사용자 정보는 `users/{uid}`에 저장한다.
- 여행 멤버 정보는 `trips/{tripId}/members/{uid}`에 저장한다.
- 내 여행 목록은 멤버십 기반으로 조회한다.

## 12. 첫 Android MVP에서 제외하는 것

- 강제 회원가입
- owner/editor/viewer 권한 분리
- 변경 이력 관리
- 활동 피드
- iOS와 Flutter Web 공개 배포
- 국내 NAVER 지도와 NAVER 저장 리스트 import
- Google Maps 실제 경로 계산
- 이동 시간 자동 계산
- 걸음 수·Health Connect와 백그라운드 여행 경로 기록
- 자동 교통수단 판별
- 완전한 오프라인 공동 편집과 사용자 정의 충돌 병합
- OCR 문맥 기반 소비자 자동 추론
- 송금 연동
- 정산 완료·송금 완료 상태와 정산 snapshot 저장
- 서로 다른 통화의 자동 환산·합산

## 13. 구현 중 검증할 사항

- 로그인 없는 UX를 유지하면서 Firestore 보안 규칙을 어떻게 설계할지
- Android 네이티브 Google 로그인 credential을 익명 계정에 연결하면서 기존 uid를 보존하는지
- Google Maps 일반 장소 URL과 단축 URL에서 장소 ID, 이름, 주소, 좌표를 어디까지 안정적으로 얻을 수 있는지
- OCR API 호출 시 이미지 전송 및 보관 정책을 사용자에게 어떻게 안내할지
- Firebase, Google Maps와 Document AI·Translation 과금 한도를 어떻게 제한할지
- 큰 영수증의 `receiptItems`를 지출 문서에 포함할 때 Firestore 문서 크기와 편집 성능을 어떻게 제한할지
- Firestore 캐시 데이터, 동기화 대기 write와 실패를 Android UI에서 어떻게 구분할지
- Flutter Web에서 지도, 파일·카메라와 로그인 capability 차이를 어떤 범위까지 수용할지

## 14. MVP 정산·OCR 완료 조건

- 순두부 12,000원을 한 사람, 커피 6,000원을 다른 한 사람에게 전액 배분할 수 있다.
- 감자전 15,000원을 세 사람이 균등 부담하면 각 배분 금액의 합이 정확히 15,000원이 된다.
- 숙소 180,000원을 네 사람이 균등 부담하면 각 45,000원으로 계산된다.
- 전체 균등, 항목별 소비자 지정, 공용 항목 균등, 참여자별 직접 부담액, 할인·봉사료·기타 조정 배분을 모두 저장하고 재계산할 수 있다.
- 각 참여자의 결제액, 부담액, 받을 금액 또는 보낼 금액이 지출 원장과 일치한다.
- 개인 소비를 카테고리별, 날짜별, 장소별, 메뉴 또는 지출별로 조회할 수 있다.
- OCR 항목 수정, 누락 항목 추가, 합계 검증, 인식 실패 시 전체 금액 수동 등록이 가능하다.
- 저장을 취소한 OCR 초안은 지출 원장과 정산 결과를 변경하지 않으며 영수증 이미지는 Trip Split의 Firestore와 Firebase Storage에 영구 저장되지 않는다.

## 15. Android 플랫폼 완료 조건

- Android API 24 이상 emulator와 최소 한 대의 실기기에서 앱이 실행된다.
- `dart format --output=none --set-exit-if-changed .`, `flutter analyze`, `flutter test`, `flutter build apk --debug`가 통과한다.
- mock `tokyo-2026-11` fixture로 `일정·지도 / 준비 / 비용` 세 영역을 Firebase 없이 열 수 있다.
- Android Emulator에서 Anonymous Auth uid와 현재 `TripSession`을 확인할 수 있다.
- Auth·Firestore·Functions Emulator에서 익명 사용자 두 명이 같은 여행 member로 등록되고 변경을 동기화한다.
- Widget에서 Firebase, Google Maps와 OCR SDK를 직접 호출하지 않고 service/repository/adapter로 제한한다.
- Android 뒤로 가기, 키보드 inset, `SafeArea`, 화면 회전과 48dp 이상 터치 영역을 검증한다.
- Flutter Web은 compile 또는 제한된 smoke test를 선택적으로 수행할 수 있지만 Android MVP의 완료 조건은 아니다.
