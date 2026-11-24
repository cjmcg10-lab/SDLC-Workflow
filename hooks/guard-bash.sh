#!/usr/bin/env bash
# PreToolUse (Bash): enforce "the human approves merges, deploys, force-pushes, destructive commands".
#   force-push to main/master  -> blocked outright (exit 2)
#   any other force-push, merge, deploy, destructive command -> asks the human
input=$(cat)
cmd=$(jq -r '.tool_input.command // empty' <<<"$input")
cwd=$(jq -r '.cwd // empty' <<<"$input")
[ -n "$cmd" ] || exit 0

ask() {
  jq -n --arg r "$1" '{hookSpecificOutput: {hookEventName: "PreToolUse",
    permissionDecision: "ask", permissionDecisionReason: $r}}'
  exit 0
}

if grep -Eq '(^|[^[:alnum:]_-])git([[:space:]]+-[^[:space:]]+([[:space:]]+[^-[:space:]][^[:space:]]*)?)*[[:space:]]+push([[:space:]]|$)' <<<"$cmd"; then
  force=0
  grep -Eq '(^|[[:space:]])(--force(-with-lease|-if-includes)?(=[^[:space:]]*)?|-[[:alpha:]]*f[[:alpha:]]*)([[:space:]]|$)|[[:space:]]\+[^[:space:]]' <<<"$cmd" && force=1
  if [ "$force" -eq 1 ]; then
    branch=$(git -C "${cwd:-.}" branch --show-current 2>/dev/null)
    if grep -Eq '(^|[[:space:]:+]|refs/heads/)(main|master)([[:space:];&|]|$)' <<<"$cmd" ||
      [[ "$branch" == main || "$branch" == master ]]; then
      echo "Blocked: force-push to main/master is not allowed. Open a PR instead." >&2
      exit 2
    fi
    ask "Force-push requires human approval."
  fi
fi

grep -Eq '(^|[^[:alnum:]_-])gh[[:space:]]+pr[[:space:]]+merge' <<<"$cmd" && ask "Merging requires human approval."
grep -Eiq '(^|[^[:alnum:]_])deploy([^[:alnum:]_]|$)' <<<"$cmd" && ask "Deploys require human approval."
grep -Eq '(^|[[:space:];&|])(rm[[:space:]]+-[[:alpha:]]*[rR]|git[[:space:]]+(reset[[:space:]]+--hard|clean[[:space:]]+-[[:alpha:]]*f|branch[[:space:]]+-D|checkout[[:space:]]+--[[:space:]]+\.|restore[[:space:]]+\.)|git[[:space:]]+push[[:space:]].*--delete)' <<<"$cmd" &&
  ask "Destructive command requires human approval."
grep -Eiq '(^|[^[:alnum:]_])(drop[[:space:]]+(table|database)|truncate[[:space:]]+table)' <<<"$cmd" &&
  ask "Destructive SQL requires human approval."
exit 0
