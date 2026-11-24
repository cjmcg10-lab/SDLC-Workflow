# sdlc-workflow

A Claude Code plugin for a lightweight, repeatable SDLC:
ticket → plan (you approve) → implement in a worktree → mechanical gates → independent review → ≤3 fix rounds → PR.

## Install (once per device)
In Claude Code:
```
/plugin marketplace add cjmcg10-lab/SDLC-Workflow
/plugin install sdlc-workflow@sdlc-workflow
```
Or from a terminal:
```bash
claude plugin marketplace add cjmcg10-lab/SDLC-Workflow && claude plugin install sdlc-workflow@sdlc-workflow
```
To update later: `/plugin marketplace update sdlc-workflow`.

**Cloud sessions (claude.ai/code) and teammates:** `/sdlc-workflow:init` adds `extraKnownMarketplaces` and
`enabledPlugins` to the project's `.claude/settings.json`. Any session that opens that repo then loads the plugin
automatically, with no per-device install.

## Use
| Command | What it does |
|---|---|
| `/sdlc-workflow:init` | One-time setup per project: detects the stack, writes and verifies `scripts/gates.sh`, and adds the workflow to CLAUDE.md |
| `/sdlc-workflow:plan <ticket>` | The planner writes `docs/plans/<ticket>.md` and stops |
| `/sdlc-workflow:build <ticket>` | Plan → **your OK** → implement on `feat/<ticket>-<slug>` in a worktree → gates → review loop → PR |
| `/sdlc-workflow:fix-bug <ticket>` | Failing reproduction test → minimal fix → gates → review loop → PR |
| `/sdlc-workflow:review [PR#\|branch]` | Gates and a fresh reviewer → a short PR comment |

`<ticket>` is a GitHub issue number (read with `gh`) or a path such as `docs/tickets/ABC-1.md`.

**Always-on hooks:**
- **Force-push to main/master:** blocked.
- **Needs your approval:** other force-pushes, merges, deploys and destructive commands.
- **Auto-format after edits:** only with the formatter the project already uses (local prettier, or ruff/black config).
