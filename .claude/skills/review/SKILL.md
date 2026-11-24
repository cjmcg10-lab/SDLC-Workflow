---
name: review
description: Run gates and an independent review on a PR or branch, then post a short PR comment. No code changes.
argument-hint: [PR# | branch]   (default: current branch)
---

# /review $ARGUMENTS

1. **Resolve the target:**
   - A PR number → `gh pr view <n> --json number,headRefName,body,url,closingIssuesReferences`.
   - A branch, or nothing (= the current branch) → `gh pr list --head <branch> --json number,url` to find its PR, if any.
2. **Worktree:** `git fetch origin <branch> && git worktree add --detach .worktrees/review-<branch> origin/<branch>`.
3. **Context for the reviewer:**
   - Ticket: the linked issue (`gh issue view`), else the PR body.
   - Plan: `docs/plans/<ticket>.md` if it exists, else "no plan".
   - Diff: `git -C <worktree> diff origin/main...HEAD`.
4. Spawn `gate-runner` (with the worktree path) and a fresh `reviewer` (with only the ticket, the plan and the diff),
   in parallel.
5. **Report:** show the human the result. If there is a PR, post the comment with
   `gh pr comment <n> --body-file <tmpfile>`, keeping it to about 20 lines:
   ```
   **Review: <APPROVE|CHANGES>** · Gates: <GREEN|RED> @ <sha>
   Gates: lint PASS · typecheck SKIP · test PASS · build SKIP
   - [blocker] path:line — <one line>
   - [major] path:line — <one line>
   - [minor] path:line — <one line>
   AC: AC1 ✅ · AC2 ❌
   ```
   Use one line per finding and no prose.
6. Remove the worktree: `git worktree remove .worktrees/review-<branch>`. Do not change code, approve or merge.
