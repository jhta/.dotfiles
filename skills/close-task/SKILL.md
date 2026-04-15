---
name: close-task
description: Post-merge cleanup and session retrospective. Use when the user says task merged, PR merged, close task, finish task, or wrap up. Archives worktree, updates ClickUp ticket status, and suggests new Cursor rules and skills based on session learnings.
---

# Close Task

Clean up after a merged PR: archive the worktree, update the ClickUp ticket, and run a session retrospective with actionable suggestions for new Cursor rules and skills.

## Step 1: Worktree Cleanup

Read `.task-state.json` to check if a worktree was used (`worktreePath` is not null).

If a worktree exists:

```bash
cd {worktreePath}
yarn worktree:archive
cd /path/to/main/repo
git worktree remove {worktreePath}
git branch -d {branch}
```

Always use the repo's worktree scripts. Never improvise with `ps`, `kill`, `lsof`, or `rm -rf`.

If no worktree was used, just clean up the branch:
```bash
git checkout main
git pull origin main
git branch -d {branch}
```

## Step 2: Ticket Status Update

1. Read the ticket via ClickUp MCP `clickup_get_task` to confirm current status
2. Determine target status:
   - **DEFI space:** move to `"to be tested"`
   - **CORE space:** move to `"done"` (no testing column)
3. If the target status does not exist in the ticket's list, fetch available statuses and ask the user which one to use
4. Update via `clickup_update_task`

## Step 3: Session Retrospective

Analyze the full session — the code changes, review comments received, CI failures encountered, and workflow friction — then present three categories of suggestions:

### New Cursor Rules

Look for patterns that emerged during implementation:
- Repeated code patterns that should be standardized
- Error handling approaches used consistently
- Naming conventions applied implicitly
- Data flow patterns that could be documented
- Testing patterns worth codifying

Present each as: "Pattern observed: {description}. Suggested rule: {rule name and brief content}. Should I create it?"

### New or Updated Skills

Look for workflow improvements:
- Steps that were manual but could be automated
- Checks that were forgotten and caught late
- Tools or commands used repeatedly that could be scripted
- Integrations that could be streamlined

Present each as: "Friction point: {description}. Suggested skill: {skill name and what it does}. Should I create it?"

### AI Workflow Improvements

Reflect on what could have gone better:
- Was the ticket description clear enough from the start?
- Did the implementation plan need major revisions?
- Were there unnecessary back-and-forth cycles?
- Could context have been provided more efficiently?

Present 2-3 actionable tips for the next task.

## Step 4: Cleanup

1. Delete `.task-state.json` from the repo root
2. Update TodoWrite to mark all phases as completed
3. Announce: "Task {ticketId} is complete. Session closed."
