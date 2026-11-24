---
name: fix-bug
description: Bug-fix flow — reproduce with a failing test first, minimal fix, gates, independent review, PR.
argument-hint: <issue# | docs/tickets/ID.md>
disable-model-invocation: true
---

# /fix-bug $ARGUMENTS

1. **Fetch the ticket** the same way as `/plan`. You need the expected behaviour, the actual behaviour and the steps to
   reproduce. If any of these is missing, stop and ask the human.
2. **Worktree:** `git fetch origin main && git worktree add .worktrees/fix/<ticket>-<slug> -b fix/<ticket>-<slug> origin/main`.
3. **Reproduce first:** spawn `implementer` with the worktree path and the ticket, and this instruction: *"Write ONLY a
   failing test that reproduces the bug. Do not fix it. Run it and paste the failing output. Commit as
   `test(<ticket>): reproduce`."*
   If the test does not fail for the reported reason, stop and report to the human. Do not fix an unreproduced bug.
4. **Minimal fix:** spawn `implementer` with: *"Make the smallest change that makes the reproduction test pass without
   breaking others. Find the root cause first, and say what it is. No refactors."*
5. **Gates:** `gate-runner` on the worktree. The repro test must now pass and everything else must be green.
6. **Review + fix loop:** same as `/build` steps 6–7 (a fresh `reviewer` each round, given only the ticket, the root
   cause note and the diff; max 3 rounds; then stop and report).
7. **PR:** same as `/build` step 8. Add a "Root cause" section and the repro test name. Do not merge.
