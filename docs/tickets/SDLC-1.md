# SDLC-1: Run a subset of gates

As a developer iterating on a failing test, I want to run only some gates so the feedback loop is faster.

## Acceptance criteria
- AC1: `scripts/gates.sh test` runs only the `test` gate; `scripts/gates.sh lint test` runs both, in table order.
- AC2: With no arguments, every gate runs exactly as today.
- AC3: An unknown gate name prints `unknown gate: <name>` to stderr and exits 2 without running any gate.
- AC4: The summary line still reads `GATES: GREEN` / `GATES: RED` based only on the gates that ran.
