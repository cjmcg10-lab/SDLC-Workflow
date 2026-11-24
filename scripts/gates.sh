#!/usr/bin/env bash
# Mechanical gates: the single source of truth for "green".
# Edit the GATES table when the stack changes. An empty command = SKIP (shown, never counted as pass).
# Usage: scripts/gates.sh
# Output: one line per gate "PASS|FAIL|SKIP <name> exit=<code>", failing output tail, then a summary.
# Exit code: 0 only if no gate failed.
set -u
cd "$(dirname "$0")/.." || exit 2

GATES=(
  "lint|scripts/lint.sh"
  "typecheck|"
  "test|tests/hooks.test.sh"
  "build|"
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
