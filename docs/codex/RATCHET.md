# 실패 고정 규칙

이 문서는 실패를 개인 기억에 남기지 않고 다음 작업의 규칙이나 강제 검증으로 승격하기 위한 기록이다. 한 번의 실패만으로 큰 규칙을 만들지 말되, 같은 실수가 두 번 나오면 재발 방지 장치를 제안한다.

## 실패 3분류

### A. 계약·데이터 실패

문서에서 정한 경계, 타입, 라우트, Firestore 규칙, 도메인 불변식과 구현이 어긋난 경우다.

예:

- `TripMember`와 `Participant`를 같은 ID로 처리함
- `Place` 정규화 없이 provider 원문을 저장함
- `payer` 또는 `allocatedAmounts` 합계가 canonical `Expense` 불변식을 깨뜨림
- 최신 route/redirect 계약과 다른 URL을 추가함

승격 후보: runtime validator, Firestore Emulator 테스트, canonical type, route regression test, 문서의 명시 규칙.

### B. 검증·품질 실패

검증 명령, 회귀 시나리오, 반응형·오류 상태 확인이 실패한 경우다.

예:

- `format:check`, lint, unit test, build 또는 Emulator test 실패
- 일정 순서 변경 뒤 지도 핀·직선 동선 순서가 달라짐
- OCR 합계 불일치가 저장 가능함
- 모바일/PC에서 같은 기능의 정보 구조가 달라짐

승격 후보: CI gate, 최소 재현 테스트, 완료 조건, 고정 fixture, viewport별 회귀 시나리오.

### C. 환경·경계 실패

실행 환경, 외부 서비스, 비밀 정보, 오프라인 상태처럼 코드만 고쳐서는 해결되지 않는 경계가 실패한 경우다.

예:

- Node.js 버전 또는 dependency lockfile 차이
- 실제 Firebase/API를 써야만 재현되는 오류
- OCR 이미지·secret·외부 응답이 로그에 노출될 위험
- 오프라인인데 저장 완료로 표시함

승격 후보: Node/Emulator 고정, mock fixture, env example, AppError 변환, 로그 검증, 온라인 상태 차단.

## 승격 절차

1. 첫 실패에는 재현 명령, 오류, 영향 범위를 현재 작업의 `docs/codex/handoffs/YYYY-MM-DD-task-owner.md`에 남긴다. `SYNC_LOG.md`에는 작업 로그를 덧붙이지 않는다.
2. 같은 원인의 두 번째 실패에는 “두 번 발생”을 명시하고, 규칙·테스트·도구 강제 중 하나를 제안한다.
3. 승격할 때는 해당 규칙을 검증할 명령이나 테스트를 함께 적는다.
4. verifier를 약화하는 방법은 승격으로 인정하지 않는다.
5. 계약 변경이 필요한 경우 `MarkDown/decision_history.md` 또는 관련 기술 문서에 결정을 남긴 뒤 구현한다.

## 승격 기록

| 날짜       | 분류(A/B/C) | 같은 실수 횟수 | 재현 방법 | 승격한 규칙/장치 | 검증 방법 |
| ---------- | ----------- | -------------: | --------- | ---------------- | --------- |
| YYYY-MM-DD |             |              2 |           |                  |           |
