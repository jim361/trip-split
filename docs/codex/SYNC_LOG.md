# 작업 동기화 로그

작업 단위가 끝날 때 아래 항목을 한 번 기록한다. 긴 설명은 인계 템플릿으로 옮기고, 이 파일에는 다음 작업자가 재개할 수 있는 사실만 남긴다.

## 2026-08-27 — Codex 협업 하네스 적용

- 담당/브랜치: Codex / `feature/codex-harness`
- 범위: 제품 코드는 바꾸지 않고 저장소 단위 지침·문서·스킬·검증·훅을 추가
- 완료: `AGENTS.md` 다이어트, 문서 충돌 우선순위, 인계·정지 계약·래칫, 자연 호출 스킬, Fast/Full verifier, 위험 Git 명령 차단
- 남은 것: 팀원의 훅 신뢰 검토와 브랜치 리뷰
- 막힌 점: 없음. 현재 로컬 checkout의 기존 tracked 파일은 전역 `core.autocrlf=true`로 CRLF이므로, 엄격한 포맷 검증은 LF 임시 checkout에서 수행
- 계약 변경: 제품 계약 없음
- 결정 근거: `MarkDown/decision_history.md`의 2026-08-27 결정, 현재 `src/`·`functions/`·`tests/`, OpenAI의 Codex AGENTS.md·Skills·Hooks 문서
- 변경 파일: `AGENTS.md`, `.gitattributes`, `.agents/`, `.codex/`, `docs/codex/`, `scripts/verify.ps1`
- 다음 작업: 새 Codex 세션에서 `/hooks`를 열어 정의를 검토하고, PR 전 Full verifier를 다시 실행

### 확인

```text
pwsh -File scripts/verify.ps1 -Mode Fast
pwsh -File scripts/verify.ps1 -Mode Full
```

- 실행 환경과 명령: Node.js 22.19.0, Java 21, LF 임시 checkout에서 Full 실행
- 종료 코드와 결과: `0`; lint·typecheck, unit/UI/Functions 27개, production build, Emulator 8개 통과
- 의도적 실패: Java를 PATH에서 제외한 Full 실행은 종료 코드 `2`와 전제조건 오류를 출력
- 훅 검사: 안전 명령 허용과 `git clean -fd` deny JSON 확인, 내장 8개 사례 통과
- 스킬 검사: 공식 `quick_validate.py` 통과, 이름 없는 인계 요청에서 `trip-split-handoff` 자연 선택 확인
- 수동 확인: `codex debug prompt-input`에서 루트 `AGENTS.md`와 저장소 스킬 경로가 모델 입력에 포함됨을 확인

## YYYY-MM-DD — 작업명

- 담당/브랜치:
- 범위:
- 완료:
- 남은 것:
- 막힌 점:
- 계약 변경:
- 결정 근거:
- 변경 파일:
- 다음 작업:

### 확인

```text
pwsh -File scripts/verify.ps1 -Mode Fast
pwsh -File scripts/verify.ps1 -Mode Full
```

- 실행 환경과 명령:
- 종료 코드와 결과:
- 실패 시 첫 오류와 재현 방법:
- 수동 확인 경로·viewport·data source:

### 날짜별 짧은 기록(선택)

| 날짜       | 완료 | 다음 | 막힌 점 | 계약 변경 |
| ---------- | ---- | ---- | ------- | --------- |
| YYYY-MM-DD |      |      |         |           |
