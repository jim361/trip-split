# Trip Split Backend

> **[코드 안내 · 백엔드]** Callable Functions와 보안 규칙의 기능별 위치를 안내합니다.

Firebase Callable Functions, Firestore 보안 규칙과 Emulator 통합 테스트를 소유하는 Node.js 22 프로젝트입니다.

## 실행

저장소 루트에서 한 번 `npm install`한 뒤 다음 명령을 사용합니다.

```bash
# Functions 빌드와 단위 테스트
cd backend
npm run build
npm test
```

저장소 루트에서는 Emulator를 실행하거나 통합 테스트를 수행합니다.

```bash
# 저장소 루트에서 Auth, Firestore, Functions Emulator 시작
npm run dev:backend

# 전체 Emulator 통합 테스트
npm run test:emulator
```

Emulator 시작 명령은 Functions를 먼저 빌드하고 과금되지 않는 `demo-trip-split` 프로젝트 ID를 명시합니다. 실제 Firebase 프로젝트 생성·배포와 외부 유료 API 호출은 별도 승인 없이 수행하지 않습니다.

## 작업 경계

- `src`: `createTrip`, `createShareCode`, `joinTrip`과 향후 Google 장소·지출·provider-neutral OCR·번역 Callable
- `src/shared/callable.ts`: 공통 Auth·여행 멤버 검사와 `HttpsError`/`AppError` wire
- `firestore.rules`, `firestore.indexes.json`: 멤버 기반 Firestore 접근 계약
- `tests/emulator`: 익명 사용자·공유 코드·보안 규칙 통합 테스트
- `.env.example`: Functions 일반 환경변수와 secret 이름 예시

## 기능별 코드 찾기

| 기능                      | 주요 진입점                                           |
| ------------------------- | ----------------------------------------------------- |
| `TASK-01 · Firebase 기반` | `src/index.ts`, `src/shared`, `firestore.rules`       |
| `TASK-02 · 여행·공유`     | `src/share/trips.ts`, `src/share/shareCode.ts`        |
| `TASK-03 · Google 장소`   | `src/places` (예정); 검색·Maps URL을 `Place`로 정규화 |
| `TASK-07 · OCR·번역`      | `src/ocr` (예정); `parseReceipt`와 provider adapter   |
| 공통 검증                 | `tests/emulator`, `src/**/*.test.ts`                  |

외부 API secret은 클라이언트나 Git에 저장하지 않고 Functions secret/environment에서만 사용합니다.

Flutter 전환으로 backend runtime을 Dart로 바꾸지 않습니다. Node.js 22·TypeScript Functions와 `@firebase/rules-unit-testing` 기반 Emulator 테스트를 유지하며 Android Emulator 클라이언트는 host `10.0.2.2`로 연결합니다.
