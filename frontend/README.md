# Trip Split Frontend

React, Vite, TypeScript로 만든 모바일 우선 PWA입니다. 화면, 라우팅, mock repository, Firebase Web SDK adapter와 지도 provider 경계는 이 프로젝트가 소유합니다.

## 실행

저장소 루트에서 한 번 `npm install`한 뒤 다음 중 하나를 사용합니다.

```bash
# 저장소 루트
npm run dev:frontend

# frontend 폴더
cd frontend
npm run dev
```

검증은 `npm run typecheck`, `npm test`, `npm run build`로 실행합니다. 실제 Firebase 연결값은 `.env.example`을 `.env.local`로 복사해 설정하며 기본 데이터 소스는 mock입니다.

## 작업 경계

- `src/app`, `src/pages`: 앱 셸, 라우트와 화면
- `src/features`: 일정·지도, 준비, 정산·영수증 기능
- `src/services`: mock 및 Firebase Web SDK repository/service
- `src/shared`: 공통 타입, 오류, ID와 UI
- `public`: PWA manifest와 정적 자산

화면 컴포넌트에서 Firebase SDK나 외부 지도 SDK를 직접 호출하지 않고 service, repository 또는 adapter를 사용합니다.
