#!/usr/bin/env bash
# Tests for .claude/hooks/*. Prints one line per case; exits non-zero on any failure.
set -u
cd "$(dirname "$0")/.." || exit 2
guard=.claude/hooks/guard-bash.sh
fails=0

# expect <allow|ask|block> <command> [cwd]
expect() {
  local want=$1 cmd=$2 cwd=${3:-/nonexistent} out code got
  out=$(jq -n --arg c "$cmd" --arg d "$cwd" '{tool_input: {command: $c}, cwd: $d}' | "$guard" 2>/dev/null)
  code=$?
  if [ "$code" -eq 2 ]; then got=block
  elif grep -q '"ask"' <<<"$out"; then got=ask
  else got=allow; fi
  if [ "$got" = "$want" ]; then echo "ok    $want: $cmd"; else echo "FAIL  want=$want got=$got: $cmd"; fails=1; fi
}

expect block 'git push --force origin main'
expect block 'git push -f origin master'
expect block 'git push origin +main'
expect block 'git push --force-with-lease origin HEAD:main'
expect block 'cd x && git push -uf origin main'
expect ask   'git push --force origin feat/1-login'
expect allow 'git push -u origin feat/1-login'
expect allow 'git push origin main'
expect allow 'git log --format=%f'
expect ask   'gh pr merge 12 --squash'
expect ask   'npm run deploy'
expect ask   'rm -rf build'
expect ask   'git reset --hard HEAD~1'
expect ask   'git clean -fd'
expect ask   'git branch -D old'
expect ask   'psql -c "DROP TABLE users"'
expect allow 'ls -la'
expect allow 'echo deployment-notes.md'

# force-push with no refspec while on main -> block
tmp=$(mktemp -d)
git -C "$tmp" init -q -b main
expect block 'git push --force' "$tmp"
rm -r "$tmp"

# format hook: formats a Python file when ruff exists; no-op for unknown files
if command -v ruff >/dev/null; then
  tmp=$(mktemp -d)
  printf 'x=[1,2 ,3]\n' >"$tmp/a.py"
  printf 'x=[1,2 ,3]\n' >"$tmp/a.txt"
  for f in a.py a.txt; do
    jq -n --arg f "$tmp/$f" '{tool_input: {file_path: $f}}' | .claude/hooks/format.sh
  done
  if [ "$(cat "$tmp/a.py")" = 'x = [1, 2, 3]' ] && [ "$(cat "$tmp/a.txt")" = 'x=[1,2 ,3]' ]; then
    echo "ok    format: .py formatted, .txt untouched"
  else
    echo "FAIL  format hook"; fails=1
  fi
  rm -r "$tmp"
else
  echo "skip  format: ruff not installed"
fi

exit "$fails"
