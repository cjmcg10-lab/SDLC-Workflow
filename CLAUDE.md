# SDLC workflow

A lightweight, repeatable ticket → plan → code → review → PR workflow for Claude Code.
Copy `.claude/`, `scripts/`, `tests/hooks.test.sh` and this file into another repo, then edit the `GATES` table in
`scripts/gates.sh` and the Stack section below.

## Stack
- Bash + jq. No package manager. Formatters used by the edit hook if installed: prettier, ruff, gofmt, rustfmt, shfmt.

## Commands (the gates)
| Gate | Command | Notes |
|------|---------|-------|
| all | `scripts/gates.sh` | **The** definition of green. Exit 0 = green. |
| lint | `scripts/lint.sh` | Shell syntax, settings JSON, agent/skill frontmatter. |
| typecheck | — | SKIP (not applicable) |
| test | `tests/hooks.test.sh` | Hook behaviour |
| build | — | SKIP (not applicable) |

## Conventions
- Tickets: GitHub Issues (`gh issue view <n>`), or `docs/tickets/<ID>.md` when there is no issue.
- Plans: `docs/plans/<ticket>.md`.
- Branches: `feat/<ticket>-<slug>`, `fix/<ticket>-<slug>`, `chore/<slug>`. Base branch: `main`.
- Commits: `<type>(<ticket>): <summary>` (types: feat, fix, test, docs, chore, refactor).
- PRs: squash-merged by the human only. Worktrees go in `.worktrees/` (gitignored).
- Off-limits without explicit approval: `.env*`/secrets, deploy scripts/config, DB migrations.

## Principles (enforced by the skills and agents)
1. **Requirements first:** read the ticket's AC (and mockups) before planning. No AC → ask the human.
2. **Plan before code:** `docs/plans/<ticket>.md` lists the files to touch, the tests to add, and AC → how satisfied.
3. **Minimal code:** reuse existing code → stdlib → installed deps → new code. No unrequested abstractions, files or deps.
4. **Author ≠ reviewer:** review runs in a fresh `reviewer` subagent given only the ticket, the plan and the diff.
5. **Gates decide green:** run `scripts/gates.sh` and check exit codes. Never claim passing without showing output.
6. **Bounded fix loop:** review → fix → re-review, max 3 rounds, then stop and report what's left.
7. **Isolation:** each agent that writes code works in its own git worktree, never a shared checkout.
8. **The human approves** merges, deploys, force-pushes and destructive commands (enforced by
   `.claude/hooks/guard-bash.sh`; force-push to main is blocked outright).

## Workflow commands
`/plan <ticket>` · `/build <ticket>` · `/fix-bug <ticket>` · `/review [PR#|branch]`
