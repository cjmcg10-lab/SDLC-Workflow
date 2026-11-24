# Plan: SDLC-1 — Run a subset of gates

## Acceptance criteria
- AC1: `scripts/gates.sh test` runs only the `test` gate; `scripts/gates.sh lint test` runs both, in table order.
- AC2: With no arguments, every gate runs exactly as today.
- AC3: An unknown gate name prints `unknown gate: <name>` to stderr and exits 2 without running any gate.
- AC4: The summary line still reads `GATES: GREEN` / `GATES: RED` based only on the gates that ran.

## Approach
Add optional positional gate-name arguments to `scripts/gates.sh`. Before `mktemp`/the loop, if `$# -gt 0`, check each
argument against the names in the existing `GATES` table; on the first miss print `unknown gate: <name>` to stderr and
`exit 2`. In the existing `for entry in "${GATES[@]}"` loop, `continue` past any entry whose name was not requested
(only when arguments were given), so the table still drives order and the no-argument path is byte-for-byte unchanged.
`failed` is only set by gates that actually ran, so the existing summary/exit logic already satisfies AC4 untouched.
Tests run a copy of `gates.sh` inside a temp dir with stub `scripts/lint.sh` / `tests/hooks.test.sh` (gates.sh `cd`s to
`$(dirname "$0")/..`), which controls pass/fail and avoids the test gate recursively invoking itself.

## Files to touch
| File | Change |
|------|--------|
| scripts/gates.sh | Accept optional gate names: validate against `GATES` (stderr + exit 2), skip unrequested entries; update Usage comment. |
| tests/gates.test.sh | New executable test script (same `ok`/`FAIL` + `fails` style as `tests/hooks.test.sh`) covering AC1–AC4. |
| scripts/gates.sh (GATES table) | `test` gate command becomes `tests/hooks.test.sh && tests/gates.test.sh` so the new tests run in the gates. |
| CLAUDE.md | Commands table: `test` row lists both test scripts; `all` row notes `scripts/gates.sh [gate...]`. |

## Tests to add
All in `tests/gates.test.sh`; each case copies `scripts/gates.sh` into `$tmp/scripts/` with stubs
`$tmp/scripts/lint.sh` and `$tmp/tests/hooks.test.sh` that append their name to `$tmp/ran` and exit 0 or 1 as set.

| Test (file :: name) | Covers |
|---------------------|--------|
| tests/gates.test.sh :: single gate `test` runs only test | AC1 (`ran` == `test`; no `PASS lint`/`SKIP` lines) |
| tests/gates.test.sh :: `test lint` runs both in table order | AC1 (`ran` == `lint` then `test`, args given out of order) |
| tests/gates.test.sh :: no args runs every gate | AC2 (PASS lint, SKIP typecheck, PASS test, SKIP build in order; exit 0) |
| tests/gates.test.sh :: unknown gate rejected | AC3 (`lint nope`: stderr == `unknown gate: nope`, exit 2, stdout empty, `ran` empty) |
| tests/gates.test.sh :: summary ignores gates not run | AC4 (lint stub fails; `gates.sh test` → `GATES: GREEN` exit 0; `gates.sh lint` → `GATES: RED` exit 1) |

## AC → how satisfied
- AC1: name filter `continue` inside the existing `GATES` loop in `scripts/gates.sh`; proven by "single gate" and "table order" tests.
- AC2: filter only active when `$# -gt 0`; proven by "no args runs every gate".
- AC3: validation block before `mktemp` and the loop, `echo "unknown gate: $n" >&2; exit 2`; proven by "unknown gate rejected".
- AC4: unchanged `failed`/summary logic, which only counts gates that ran; proven by "summary ignores gates not run".

## Reuse / not adding
- Reusing: the existing `GATES` table and loop in `scripts/gates.sh` (names parsed with the same `${entry%%|*}`); the
  `ok`/`FAIL`/`fails` test style from `tests/hooks.test.sh`; `scripts/lint.sh` already lints `tests/*.sh` (syntax + executable bit).
- Not adding: flags/getopts, `--list`/`--help`, env-var or file overrides for the gate table, any new deps.

## Risks & open questions
- Wiring: the plan adds `tests/gates.test.sh` to the `test` gate command (and CLAUDE.md). Alternative is appending the
  cases to `tests/hooks.test.sh`, but that file is scoped to hook behaviour. Reviewer may prefer either.
- Duplicate args (`test test`) run the gate once, since the table drives iteration — reasonable but not stated in the ticket.
- Requesting a SKIP gate (e.g. `typecheck`) prints its `SKIP` line and yields `GATES: GREEN` (nothing failed) — consistent with today's semantics.
- `tests/gates.test.sh` must be `chmod +x` or the lint gate fails.
