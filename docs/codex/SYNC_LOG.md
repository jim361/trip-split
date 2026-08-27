# 동기화 기록 정책

`SYNC_LOG.md`는 여러 담당자가 동시에 덧붙이는 작업 로그가 아니다. 공유 파일의
충돌을 피하기 위해 이 문서에는 기록 정책만 둔다. 작업 진행·실패·검증·인계
사실은 `docs/codex/handoffs/` 아래의 새 파일에 기록한다.

## 인계 파일명

- 기본: `handoffs/YYYY-MM-DD-task-owner.md`
- 같은 날짜·작업·담당자가 다시 생긴 경우: `handoffs/YYYY-MM-DD-HHmm-task-owner.md`
- `task`와 `owner`는 파일명에 안전한 짧은 slug를 사용한다.
- 기존 파일을 덮어쓰거나 이 파일에 작업 로그를 append하지 않는다.
- 새 기록을 찾을 때는 이 파일에 색인을 추가하지 말고 `handoffs/` 디렉터리를 직접 확인한다.
