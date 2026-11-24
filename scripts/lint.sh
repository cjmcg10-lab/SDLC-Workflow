#!/usr/bin/env bash
# Lint for this repo's own workflow files: shell syntax, JSON validity, agent/skill frontmatter.
set -u
cd "$(dirname "$0")/.." || exit 2
rc=0

for f in scripts/*.sh tests/*.sh hooks/*.sh; do
  bash -n "$f" || { echo "syntax error: $f"; rc=1; }
  [ -x "$f" ] || { echo "not executable: $f"; rc=1; }
done

for j in .claude/settings.json .claude-plugin/*.json hooks/hooks.json; do jq empty "$j" || { echo "invalid JSON: $j"; rc=1; }; done

for f in agents/*.md skills/*/SKILL.md; do
  head -n1 "$f" | grep -qx -- '---' || { echo "missing frontmatter: $f"; rc=1; continue; }
  fm=$(awk 'NR>1 && /^---$/ {exit} NR>1' "$f")
  grep -q '^name: ' <<<"$fm" || { echo "missing name: $f"; rc=1; }
  grep -q '^description: ' <<<"$fm" || { echo "missing description: $f"; rc=1; }
done

[ "$rc" -eq 0 ] && echo "lint ok"
exit "$rc"
