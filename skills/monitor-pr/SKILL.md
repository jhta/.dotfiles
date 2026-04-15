---
name: monitor-pr
description: PR monitoring loop that polls every 2 minutes for CI failures, review comments, and merge readiness. Use when the user says monitor PR, watch PR, babysit PR, keep watching, or poll PR. Replaces the babysit skill with comprehensive PR lifecycle monitoring.
---

# Monitor PR

Poll a GitHub PR every 2 minutes. Detect CI failures, new review comments, merge conflicts, and merge readiness. Auto-fix CI when possible, summarize review comments for the user, and never merge automatically.

## Startup

1. Read `.task-state.json` for `prNumber` and `prUrl`. If not found, ask the user for the PR number.
2. Detect repo owner and name:
   ```bash
   gh repo view --json owner,name --jq '{owner: .owner.login, name: .name}'
   ```
3. Reconstruct TodoWrite if resuming from a closed session.
4. Update `.task-state.json` phase to `"monitoring"`.

## Loop

Each iteration follows this sequence. After each iteration, sleep for 2 minutes using the Await tool with `block_until_ms: 120000`.

### Step 1: Gather State

Run these commands (all can run in parallel):

```bash
# CI checks
gh pr checks <PR_NUMBER> --json name,state,conclusion

# Reviews
gh api repos/{owner}/{repo}/pulls/{number}/reviews

# Review comments (line-level)
gh api repos/{owner}/{repo}/pulls/{number}/comments

# PR state
gh pr view <PR_NUMBER> --json state,mergeable,mergeStateStatus,reviewDecision,statusCheckRollup
```

### Step 2: Triage (in priority order)

**Priority 1 — CI Failure:**

If any check has `conclusion: "failure"`:
- Read the failing check details
- Attempt to fix (lint errors, type errors, test failures)
- Commit and push the fix
- Notify user: "Fixed CI failure in {check_name}: {description}. Pushed fix commit."
- If the failure is infrastructure-related or unfixable, notify user and explain

**Priority 2 — New Review Comments:**

Compare comment IDs against `lastCommentId` from `.task-state.json`:
- For each new comment, produce a summary:
  - **Who** commented
  - **Where** (file and line)
  - **What** they suggest
  - **Recommendation** (agree / disagree / needs-discussion)
- Present the full summary to the user
- **Wait for user approval** before applying any changes
- After user confirms which suggestions to apply:
  1. Apply the changes
  2. Commit and push
  3. Update `lastCommentId` in `.task-state.json`

**Priority 3 — Merge Conflicts:**

If `mergeable` is `false` or `mergeStateStatus` is `"DIRTY"`:
- Notify user: "PR has merge conflicts. Should I rebase on main?"
- Wait for approval before rebasing
- If approved: `git fetch origin main && git rebase origin/main`, resolve conflicts, force push

**Priority 4 — Ready to Merge:**

If all of these are true:
- All checks pass (`conclusion: "success"`)
- Review decision is `"APPROVED"`
- No merge conflicts
- No unresolved review threads

Then notify user: "PR is ready to merge! Merge it yourself when ready."

**Never merge automatically.** Continue polling even after notifying, in case new comments arrive.

**Priority 5 — No Changes:**

If nothing changed since last check:
- Update `lastChecked` in `.task-state.json`
- Stay silent
- Continue loop

### Step 3: Sleep

```
Await with block_until_ms: 120000
```

Then go back to Step 1.

## User Interaction During Loop

The user can interrupt at any time with commands like:
- "stop monitoring" — exit the loop, keep state
- "apply suggestion 2" — apply a specific review comment fix
- "skip that comment" — mark a comment as not needing action
- "rebase" — trigger a rebase on main

## State Management

Update `.task-state.json` after every meaningful change:
- `lastChecked`: ISO timestamp of current iteration
- `lastCommentId`: highest comment ID processed
- `ciStatus`: `"passing"`, `"failing"`, or `"pending"`
- `phase`: stays `"monitoring"` until PR is merged

When the PR is merged (detected via `state: "MERGED"`):
1. Update phase to `"merged"` in `.task-state.json`
2. Notify user: "PR has been merged! Say 'close task' to clean up."
3. Exit the loop
