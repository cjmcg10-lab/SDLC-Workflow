#!/usr/bin/env bash
# PostToolUse (Edit|Write|MultiEdit): format the edited source file with the formatter the PROJECT uses.
# A formatter runs only if the project opts in (local install or config), so repos without one never get
# reformatted. Never blocks: unknown extension or no formatter = no-op.
f=$(jq -r '.tool_input.file_path // empty')
[ -n "$f" ] && [ -f "$f" ] || exit 0
root=$(git -C "$(dirname "$f")" rev-parse --show-toplevel 2>/dev/null) || root=$(dirname "$f")

has_cfg() { # has_cfg <pyproject-section> <file>...
  local section=$1 c
  shift
  for c in "$@"; do [ -f "$root/$c" ] && return 0; done
  [ -n "$section" ] && grep -q "^\[$section\]" "$root/pyproject.toml" 2>/dev/null
}

cmd=()
case "$f" in
  *.js | *.jsx | *.mjs | *.cjs | *.ts | *.tsx | *.css | *.scss | *.html | *.json | *.yml | *.yaml)
    [ -x "$root/node_modules/.bin/prettier" ] && cmd=("$root/node_modules/.bin/prettier" --write --log-level warn "$f") ;;
  *.py)
    if has_cfg tool.ruff ruff.toml .ruff.toml; then cmd=(ruff format -q "$f")
    elif has_cfg tool.black; then cmd=(black -q "$f"); fi ;;
  *.go) cmd=(gofmt -w "$f") ;;
  *.rs) cmd=(rustfmt "$f") ;;
  *.sh) has_cfg "" .editorconfig && cmd=(shfmt -w "$f") ;;
esac

[ "${#cmd[@]}" -gt 0 ] && command -v "${cmd[0]}" >/dev/null 2>&1 || exit 0
"${cmd[@]}" >/dev/null 2>&1 || true
exit 0
