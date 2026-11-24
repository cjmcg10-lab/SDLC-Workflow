---
name: build
description: Full ticket-to-PR flow — plan, human approval, implement in a worktree, gates, independent review, bounded fix loop, PR.
argument-hint: <issue# | docs/tickets/ID.md>
disable-model-invocation: true
---

# /build $ARGUMENTS

Follow these steps in order. Do not skip any of them, and never write code in this (orchestrator) conversation.

## 1. Plan
Run the `/plan` steps (`.claude/skills/plan/SKILL.md`) for `$ARGUMENTS`. If there is no AC, stop and ask.

## 2. Human approval — WAIT
Show the plan and ask: "Approve this plan? (yes / edits)". **Do not continue until the human says yes.**
If they ask for edits, re-run `planner` with their feedback and ask again.

## 3. Branch + worktree
`git fetch origin main` then
`git worktree add .worktrees/<branch> -b <branch> origin/main`, where `<branch>` = `feat/<ticket>-<short-slug>`.
Copy the approved plan into the worktree (`docs/plans/<ticket>.md`) and commit it there as `docs(<ticket>): plan`.
Every agent below works only inside `<abs path>/.worktrees/<branch>`.

## 4. Implement
Spawn `implementer` with: the worktree path, the plan path and the ticket text.
If it reports AMBIGUITIES, show them to the human and wait for answers before continuing.

## 5. Gates
Spawn `gate-runner` with the worktree path. If the result is RED, send the failure output to `implementer` (counts as a
fix round) and re-run the gates.

## 6. Review — fresh context
Get the diff: `git -C <worktree> diff origin/main...HEAD`.
Spawn a **new** `reviewer` each round. Give it ONLY: the ticket text, the plan, and the diff. Never the implementer's
output or this conversation's history.

## 7. Fix loop (max 3 rounds)
CHANGES → send the blocker and major findings to `implementer` → `gate-runner` → new `reviewer`. Stop when:
- APPROVE and GREEN → go to step 8.
- After round 3 there are still blockers/majors, or the gates are RED → STOP. Report the remaining findings and the
  gate output to the human, and do not open a PR unless they say so.

## 8. Pull request
Push the branch (`git -C <worktree> push -u origin <branch>`), then `gh pr create --base main` with this body:
```
## Summary
<2–4 bullets>
Closes #<n>            (GitHub issues only)

## Acceptance criteria
- [x] AC1 — <test that proves it>
- [ ] AC2 — <why not met, if any>

## Gates (commit <sha>)
<gate-runner PASS/FAIL/SKIP lines>

## Review
<verdict> after <n> round(s). Open minor findings: <list or none>

Plan: docs/plans/<ticket>.md
```
Give the human the PR link. **Do not merge.** The human merges.
