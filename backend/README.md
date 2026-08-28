# Trip Split Backend

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

Emulator 명령은 과금되지 않는 `demo-trip-split` 프로젝트 ID를 명시합니다. 실제 Firebase 프로젝트 생성·배포와 외부 유료 API 호출은 별도 승인 없이 수행하지 않습니다.

## 작업 경계

- `src`: `createTrip`, `createShareCode`, `joinTrip`과 향후 장소 검색·OCR Callable
- `firestore.rules`, `firestore.indexes.json`: 멤버 기반 Firestore 접근 계약
- `tests/emulator`: 익명 사용자·공유 코드·보안 규칙 통합 테스트
- `.env.example`: Functions 일반 환경변수와 secret 이름 예시

외부 API secret은 클라이언트나 Git에 저장하지 않고 Functions secret/environment에서만 사용합니다.
