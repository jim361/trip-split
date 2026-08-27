---
name: trip-split-handoff
description: Prepare or audit a Trip Split task handoff when work must continue in another Codex session or move to another teammate. Capture the six required handoff sections with current decisions, protected scope, and executable verification evidence; do not use for ordinary progress summaries.
---

# Trip Split Handoff

Create a handoff that another contributor can act on without reconstructing the session.

## Gather evidence

1. Read `docs/codex/README.md` and `docs/codex/HANDOFF_TEMPLATE.md`.
2. Inspect the current branch, `git status`, and the relevant diff. Do not infer completed work from conversation alone.
3. Read only the product, task, or handoff documents relevant to the changed paths. If they conflict, record the exact paths and apply the precedence in `docs/codex/README.md`.
4. Record verification from commands actually run. Prefer `pwsh -File scripts/verify.ps1 -Mode Fast` during work and `pwsh -File scripts/verify.ps1 -Mode Full` before a PR.

## Produce the handoff

Use exactly these six sections from the project template:

1. 목표
2. 끝난 것
3. 남은 것
4. 결정한 것과 이유
5. 하지 말 것
6. 확인 방법

Write `확인 필요` for unknown facts. Distinguish passed, failed, blocked, and not-run checks; never report a command as passed when it was not executed. Put an executable command and its observed exit code in 확인 방법.

Return the filled handoff in the response unless the user asks to save it. When saving, create a dated file under `docs/codex/handoffs/` and leave the template unchanged.
