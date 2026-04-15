---
name: task-lifecycle
description: End-to-end task lifecycle orchestrator. Use when the user says start task, work on ticket, pick up ticket, begin task, continue task, or provides a ClickUp ticket ID to work on. Chains through ticket analysis, branch/worktree creation, planning, implementation, checks, PR creation, and handoff to monitoring.
---

# Task Lifecycle

Orchestrate the full lifecycle of a development task from ClickUp ticket to PR creation. This skill chains into `monitor-pr` after the PR is created.

## Phase 0: Resume Check

1. Check for `.task-state.json` in the repo root
2. If found: read it, reconstruct TodoWrite from the persisted phase, and resume from the last known phase
3. If not found: proceed with fresh setup (Phase 1)

When resuming, announce: "Resuming task {ticketId} from phase: {phase}"

## Phase 1: Ticket Analysis

**Read the ticket:**

Use ClickUp MCP `clickup_get_task` with the ticket ID (e.g., `DEFI-123`). If the user only said "start task" without a ticket, ask for the ticket ID.

**Evaluate the description:**

- If description is empty or has fewer than ~20 words: ask the developer to explain the task. Use their explanation to update the ticket description via `clickup_update_task`.
- If the description exists but the agent still cannot clearly understand what to implement: ask clarifying questions. Do not proceed until the task is unambiguous.

**Evaluate task size:**

If the task touches many modules or has multiple independent concerns, present two options:

1. **Split into subtasks** — create ClickUp subtasks via `clickup_create_task` (as children of the parent ticket) and work through them sequentially
2. **Create separate tickets** — create new independent ClickUp tickets, link them via `clickup_add_task_link`, and focus on one at a time

Ask the user which approach they prefer. Only proceed after they decide.

**Initialize progress:**

Create a TodoWrite visual progress tracker:

```
- [in_progress] Phase 1: Ticket analysis
- [pending] Phase 2: Branch and worktree
- [pending] Phase 3: Planning
- [pending] Phase 4: Implementation
- [pending] Phase 5: PR creation
- [pending] Phase 6: Monitoring (monitor-pr skill)
- [pending] Phase 7: Close (close-task skill)
```

## Phase 2: Branch and Worktree

1. Derive branch name: `{prefix}/{TICKET-ID}-{short-desc}` following project conventions (see AGENTS.md for prefix mapping)
2. Ask user: "Create a worktree (isolated, instant setup) or work in the current directory?"
3. If worktree:
   ```bash
   git worktree add -b feat/DEFI-123-short-desc ../DEFI-123 main
   cd ../DEFI-123
   yarn worktree:setup
   ```
   Always use repo scripts from `docs/worktrees.md`. Never improvise with `ps`, `kill`, `lsof`, or `rm -rf`.
4. If no worktree: create and checkout the branch in place
5. Move ticket to "in progress" via ClickUp MCP `clickup_update_task`
6. Write `.task-state.json`:
   ```json
   {
     "ticketId": "DEFI-123",
     "branch": "feat/DEFI-123-short-desc",
     "worktreePath": "../DEFI-123",
     "prNumber": null,
     "prUrl": null,
     "phase": "branch-created",
     "lastChecked": null,
     "lastCommentId": null,
     "ciStatus": null
   }
   ```

## Phase 3: Planning

1. Switch to Plan Mode
2. Explore the codebase to understand the change surface
3. Present an implementation plan: which files change, the approach, any risks or alternatives
4. Wait for user approval
5. If user requests changes: revise and re-present

Do not proceed to implementation without explicit approval.

## Phase 4: Implementation

1. Switch to Agent Mode
2. Implement the approved changes
3. Run all checks:
   ```bash
   yarn format:check
   npx tsc --noEmit
   npx oxlint
   yarn find-deadcode
   yarn test-changed-vs-main
   ```
4. On failures: fix and re-run (loop until all pass)
5. On success: notify user "Changes are done and all checks pass. Ready to push?"
6. Update `.task-state.json` phase to `"checks-passed"`

Wait for user authorization before pushing.

## Phase 5: PR Creation

After user authorizes, follow the `create-pr` skill workflow:

1. Commit following diff-driven commit conventions from AGENTS.md
2. Push: `git push -u origin HEAD`
3. Create PR: `gh pr create` with generated description
4. Send Slack notification via webhook:
   ```bash
   curl -s -X POST \
     "$SLACK_WEBHOOK_URL" \
     -H "Content-Type: application/json" \
     -d '{"description": "<SUMMARY>", "pr_url": "<PR_URL>"}'
   ```
5. Move ticket to "in review" via ClickUp MCP
6. Update `.task-state.json` with `prNumber`, `prUrl`, and phase `"pr-created"`

Then tell the user: "PR created. Say 'monitor PR' to start the monitoring loop, or I can start it now."

## State File

The `.task-state.json` file is written to the repo root and must be gitignored. Update it after every phase transition. Schema:

| Field | Type | Description |
|---|---|---|
| ticketId | string | ClickUp ticket ID (e.g., DEFI-123) |
| branch | string | Full branch name |
| worktreePath | string or null | Relative path to worktree directory |
| prNumber | number or null | GitHub PR number |
| prUrl | string or null | GitHub PR URL |
| phase | string | Current phase identifier |
| lastChecked | string or null | ISO timestamp of last monitor-pr check |
| lastCommentId | string or null | ID of last processed review comment |
| ciStatus | string or null | Last known CI status |

Phase identifiers: `ticket-analyzed`, `branch-created`, `planning`, `implementing`, `checks-passed`, `pr-created`, `monitoring`, `merged`, `closed`
