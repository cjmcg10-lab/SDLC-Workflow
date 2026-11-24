---
name: init
description: One-time setup of the SDLC workflow in the current project — detect the stack, write scripts/gates.sh with verified commands, and add the workflow section to CLAUDE.md.
disable-model-invocation: true
---

# /sdlc-workflow:init

Run this once per project. Do not change any application code.

1. **Detect the stack** from manifests and CI config: `package.json` (+ the lockfile → npm/pnpm/yarn/bun),
   `pyproject.toml`/`requirements*.txt`, `go.mod`, `Cargo.toml`, `Makefile`, `.github/workflows/*`.
   Find the exact lint, typecheck, test and build commands the project already uses. Prefer scripts it already defines
   (e.g. `npm run lint`) over inventing new ones. Leave a gate empty if the project has no such step.
2. **Ask the human, in one message,** to confirm or correct: the commands, the base branch, the branch/PR conventions,
   where tickets live (GitHub Issues via `gh`, or `docs/tickets/`), and anything off-limits.
3. **Write `scripts/gates.sh`** (if it doesn't exist; if it does, show it and ask before changing it) from the template
   below. Fill in the `GATES` table, then `chmod +x scripts/gates.sh`.
4. **Verify:** run `scripts/gates.sh` and show the full output and exit code. If a gate fails because the command is
   wrong, fix the command and re-run. If it fails because the code is broken, report it; do not fix code.
5. **Append to `CLAUDE.md`** (create it if missing) the section below, with the confirmed values filled in.
6. Add `.worktrees/` to `.gitignore`.
7. Merge these keys into `.claude/settings.json`, keeping everything else. This loads the plugin automatically in cloud
   sessions and for anyone who opens the repo:
   ```json
   "extraKnownMarketplaces": { "sdlc-workflow": { "source": { "source": "github", "repo": "cjmcg10-lab/SDLC-Workflow" } } },
   "enabledPlugins": { "sdlc-workflow@sdlc-workflow": true }
   ```
8. Show the human the diff. Do not commit unless they ask.

## Template: scripts/gates.sh
```bash
#!/usr/bin/env bash
# Mechanical gates: the single source of truth for "green".
# Edit the GATES table when the stack changes. An empty command = SKIP (shown, never counted as pass).
# Output: one line per gate "PASS|FAIL|SKIP <name> exit=<code>", failing output tail, then a summary.
# Exit code: 0 only if no gate failed.
set -u
cd "$(dirname "$0")/.." || exit 2

GATES=(
  "lint|<command or empty>"
  "typecheck|<command or empty>"
  "test|<command or empty>"
  "build|<command or empty>"
)

logdir=$(mktemp -d)
failed=0
for entry in "${GATES[@]}"; do
  name=${entry%%|*}
  cmd=${entry#*|}
  if [ -z "$cmd" ]; then
    echo "SKIP $name (no command configured)"
    continue
  fi
  bash -c "$cmd" >"$logdir/$name.log" 2>&1
  code=$?
  if [ "$code" -eq 0 ]; then
    echo "PASS $name exit=0  \$ $cmd"
  else
    failed=1
    echo "FAIL $name exit=$code  \$ $cmd"
    tail -n 40 "$logdir/$name.log" | sed 's/^/    /'
  fi
done
rm -rf "$logdir"

if [ "$failed" -eq 0 ]; then echo "GATES: GREEN"; else echo "GATES: RED"; fi
exit "$failed"
```

## Template: CLAUDE.md section
```markdown
## SDLC workflow (plugin: sdlc-workflow)
- Stack: <language/framework>, package manager <pm>.
- Gates: `scripts/gates.sh` is the definition of green (lint: `<cmd>` · typecheck: `<cmd>` · test: `<cmd>` · build: `<cmd>`).
- Tickets: <GitHub Issues via `gh issue view <n>` | docs/tickets/<ID>.md>. Plans: `docs/plans/<ticket>.md`.
- Branches: `feat/<ticket>-<slug>`, `fix/<ticket>-<slug>` off `<base>`. Commits: `<type>(<ticket>): <summary>`.
- Merges: the human only. Off-limits without approval: <list, e.g. .env*, deploy config, migrations>.

Principles:
1. Requirements first: read the AC (and mockups) before planning. No AC → ask the human.
2. Plan before code: files to touch, tests to add, and AC → how satisfied, in `docs/plans/<ticket>.md`.
3. Minimal code: reuse existing code → stdlib → installed deps → new code. No unrequested abstractions, files or deps.
4. Author ≠ reviewer: review runs in a fresh `reviewer` subagent given only the ticket, the plan and the diff.
5. Gates decide green: run `scripts/gates.sh` and check exit codes. Never claim passing without showing output.
6. Bounded fix loop: max 3 review → fix rounds, then stop and report.
7. Each agent that writes code works in its own git worktree (`.worktrees/`).
8. The human approves merges, deploys, force-pushes and destructive commands.
```
