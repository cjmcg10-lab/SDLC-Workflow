# sdlc-workflow (Claude Code plugin)

This repo is both a Claude Code plugin and its own marketplace. Users install it with
`/plugin marketplace add cjmcg10-lab/SDLC-Workflow` and then `/plugin install sdlc-workflow@sdlc-workflow`.

## Layout
- `.claude-plugin/plugin.json`: the plugin manifest. **Bump `version` on every release**, or installed copies won't update.
- `.claude-plugin/marketplace.json`: the marketplace, which lists this repo (`source: "./"`) as the plugin.
- `agents/`: planner, implementer, reviewer, gate-runner.
- `skills/`: init, plan, build, fix-bug, review (invoked as `/sdlc-workflow:<name>`).
- `hooks/hooks.json`: `guard-bash.sh` (PreToolUse on Bash) and `format.sh` (PostToolUse on edits).
- `scripts/`, `tests/`: this repo's own gates. They are not used by the projects that install the plugin.

## Commands (the gates)
| Gate | Command |
|------|---------|
| all | `scripts/gates.sh` (exit 0 = green) |
| lint | `scripts/lint.sh`: shell syntax, JSON manifests, agent/skill frontmatter |
| typecheck | SKIP |
| test | `tests/hooks.test.sh`: hook behaviour |
| build | SKIP. Also run `claude plugin validate .` before release. |

## Conventions
- Branches: `feat/…`, `fix/…`, `chore/…` off `main`. Commits: `<type>(<ticket>): <summary>`. The human merges.
- `main` is what users install, so only merge green, validated changes.

## Principles (what the plugin enforces in the projects that use it)
1. Requirements first: no AC → ask. 2. Plan before code. 3. Minimal code: reuse → stdlib → installed deps → new.
4. Author ≠ reviewer: a fresh reviewer that sees only the ticket, the plan and the diff. 5. Gates decide green; show
the output. 6. Max 3 fix rounds. 7. One worktree per agent that writes code. 8. The human approves merges, deploys,
force-pushes and destructive commands.
