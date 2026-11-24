#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): format the edited source file.
# Never blocks: unknown extension or missing formatter = no-op.
f=$(jq -r '.tool_input.file_path // empty')
[ -n "$f" ] && [ -f "$f" ] || exit 0

case "$f" in
  *.js | *.jsx | *.mjs | *.cjs | *.ts | *.tsx | *.css | *.scss | *.html | *.json | *.yml | *.yaml)
    cmd=(prettier --write --log-level warn "$f") ;;
  *.py) cmd=(ruff format -q "$f") ;;
  *.go) cmd=(gofmt -w "$f") ;;
  *.rs) cmd=(rustfmt "$f") ;;
  *.sh) cmd=(shfmt -w "$f") ;;
  *) exit 0 ;;
esac

command -v "${cmd[0]}" >/dev/null 2>&1 || exit 0
"${cmd[@]}" >/dev/null 2>&1 || true
exit 0
