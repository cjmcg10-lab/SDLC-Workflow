---
name: plan
description: Write an implementation plan for a ticket using the planner subagent only. No code changes.
argument-hint: <issue# | docs/tickets/ID.md | "pasted ticket text">
---

# /plan $ARGUMENTS

1. **Fetch the ticket:**
   - A number → `gh issue view <n> --json number,title,body,comments,url`. Ticket ID = `GH-<n>`.
   - A path → read the file. Ticket ID = the file's base name.
   - Anything else → treat it as the ticket text and ask the human for an ID.
   Open any mockups the ticket links to or attaches.
2. **Requirements gate:** if the ticket has no acceptance criteria, STOP and ask the human for them. Do not plan.
3. Spawn the `planner` subagent with the ticket ID and the full ticket text, including comments and mockup paths.
   If it returns `NO_AC`, STOP and ask the human.
4. Show the human the full contents of `docs/plans/<ticket>.md` and the open questions. Stop there.
