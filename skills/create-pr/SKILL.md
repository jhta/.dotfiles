---
name: create-pr
description: Create GitHub Pull Requests with auto-generated descriptions. Use when user says create PR, make pull request, generate PR, push PR, or auto create PR. Analyzes git diff, extracts ticket from branch name, generates comprehensive PR body.
---

# Create PR Skill

Automatically create GitHub Pull Requests using the GitHub CLI with descriptions generated from git diff analysis.

## Trigger Phrases

- "create pr" / "create pull request"
- "make pr" / "make pull request"
- "generate pr" / "generate pull request"
- "auto create pr"
- "push pr"

## Workflow

### 1. Pre-flight Checks

```bash
# Check if we're on a branch (not main)
git branch --show-current

# Check if there are uncommitted changes
git status --porcelain

# Check if branch exists on remote
git ls-remote --heads origin $(git branch --show-current)
```

**Requirements:**
- Must be on a feature branch (not main/master)
- No uncommitted changes (everything should be committed)
- Branch must exist on remote (already pushed)

### 2. Branch Analysis

Parse branch name with this regex (supports both `DEFI-131` style and raw ClickUp IDs like `869cgjwr7`):

```
^(?<prefix>feature|feat|fix|bugfix|hotfix|chore|patch|release|refactor|build|ci|test|docs|perf)[/-](?<ticket>(web|vavo|favo|pay|pro|proapp|markets|rt|user|fe|bug|core|regtech|earn|pr|rwds|qa|pt|defi)-[0-9]+|[a-z0-9]{6,})?-?(?<title>.*)$
```

The `ticket` group matches:
- Standard format: `DEFI-131`, `CORE-1234`, etc. (case-insensitive)
- Raw ClickUp task IDs: alphanumeric strings of 6+ chars like `869cgjwr7`

Map branch prefix to conventional commit prefix:
- `feature|feat` → `feat:`
- `fix|bugfix|hotfix` → `fix:`
- `chore` → `chore:`
- `refactor` → `refactor:`
- `docs` → `docs:`
- `test` → `test:`
- `perf` → `perf:`

### 3. PR Existence Check

```bash
gh pr list --head $(git branch --show-current) --base main --json number
```

If PR exists, offer options: update description, create with different base, or cancel.

### 4. Generate PR Description

Run `git fetch origin main && git diff main...HEAD` to analyze changes.

**Output format (raw markdown only, no explanations):**

```markdown
### Ticket:
[TICKET-123](https://app.clickup.com/t/$CLICKUP_WORKSPACE_ID/TICKET-123)

### Types of changes
- [x] :sparkles: New feature
- [ ] :bug: Bug fix
- [ ] :boom: Breaking change

### Summary
[3-line summary of main changes]

### Detailed Changes
- 3–5 concise bullets max covering the most important behavioral or architectural changes
- Focus on *what changed and why*, not on listing files or components
- Only mention specific files if they are critical to understanding the change (e.g., new modules, deleted files, config changes)
- Skip trivial renames, import adjustments, test-only additions, and minor refactors
```

**Only add if present:**
- Package Updates (added/updated/removed)
- New Storybook Stories
- Feature Flags & Experiments
- Workflow Changes
- Documentation Needs Update

### 5. Create PR

```bash
gh pr create \
  --title "feat: [TICKET-123] Descriptive Title" \
  --body "$(generated_description)" \
  --base main \
  --head $(git branch --show-current)
```

### 6. Post-Creation

- Display PR URL and number
- Show next steps (request reviewers, add labels)

### 7. Notify Slack

Send a notification to Slack with the PR URL and a very brief summary of the changes (1 sentence max, no ticket IDs).

```bash
curl -s -X POST \
  "$SLACK_WEBHOOK_URL" \
  -H "Content-Type: application/json" \
  -d '{
    "description": "<SUMMARY>",
    "pr_url": "<PR_URL>"
  }'
```

**Replace these placeholders before executing:**
- `<SUMMARY>` → a very short summary of what the PR does (1 sentence, no ticket IDs). Example: "Add SkeletonCell core-ui component for loading states"
- `<PR_URL>` → the full GitHub PR URL returned by `gh pr create`

This step runs automatically after PR creation — no confirmation needed.

### 8. Update ClickUp Ticket

This step only runs when:
- A ticket ID was extracted from the branch name (step 2)
- The env var `CLICKUP_API_KEY` is available

**How to get the API key:**

```bash
echo "$CLICKUP_API_KEY"
```

If the variable is empty or unset, skip this step and inform the user that the ClickUp update was skipped because `CLICKUP_API_KEY` is not configured.

#### 8a. Fetch available statuses

Before doing anything, fetch the task to get the list ID, then fetch the list's available statuses. This avoids blindly sending a status name that doesn't exist.

```bash
# Get task details (list ID + current status)
curl -s -X GET \
  "https://api.clickup.com/api/v2/task/TICKET-123?custom_task_ids=true&team_id=$CLICKUP_WORKSPACE_ID" \
  -H "Authorization: $CLICKUP_API_KEY" | jq '{status: .status.status, list_id: .list.id}'

# Get all valid statuses for that list
curl -s "https://api.clickup.com/api/v2/list/<LIST_ID>" \
  -H "Authorization: $CLICKUP_API_KEY" | jq '[.statuses[].status]'
```

From the available statuses, pick the best match for "in review":
- If a status named exactly `in review` exists → use it
- If a status like `review`, `code review`, or `in progress` exists → use the closest match
- If none match → show the user the available statuses and ask which one to use

#### 8b. Confirm with the user

**CRITICAL: Before executing this step, you MUST ask the user for explicit confirmation.** Show the ticket ID, PR URL, comment text, and the target status, then wait for approval.

```
I'm about to update ClickUp ticket DEFI-84:

  1. Add comment:
     🔗 Pull Request created: https://github.com/org/repo/pull/456
     Add empty state to wallet screen when no assets are present.

  2. Move status: "in progress" → "in review"

Proceed? (yes/no)
```

**Only execute the API calls after the user confirms.**

#### 8c. Post comment

```bash
curl -s -X POST \
  "https://api.clickup.com/api/v2/task/TICKET-123/comment?custom_task_ids=true&team_id=$CLICKUP_WORKSPACE_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: $CLICKUP_API_KEY" \
  -d '{
    "comment_text": "🔗 Pull Request created: <PR_URL>\n\n<SHORT_DESCRIPTION>",
    "notify_all": false
  }'
```

**Replace these placeholders before executing:**
- `TICKET-123` → the ticket ID extracted from the branch (e.g., `DEFI-84` or `869cgjwr7`)
- `<PR_URL>` → the full GitHub PR URL returned by `gh pr create`
- `<SHORT_DESCRIPTION>` → 1–2 sentence summary reused from the PR description Summary section

#### 8d. Move ticket status

After the comment is posted successfully, update the status (no need to ask again — already confirmed in 8b):

```bash
curl -s -X PUT \
  "https://api.clickup.com/api/v2/task/TICKET-123?custom_task_ids=true&team_id=$CLICKUP_WORKSPACE_ID" \
  -H "Content-Type: application/json" \
  -H "Authorization: $CLICKUP_API_KEY" \
  -d '{"status": "<TARGET_STATUS>"}'
```

If the status update fails, display the error and inform the user — the comment was still posted successfully. Do not retry.

## Error Handling

- Not authenticated: `gh auth login`
- No GitHub CLI: Install from https://cli.github.com/
- Branch not pushed: `git push -u origin <branch>`
- On main branch: Switch to feature branch first
- ClickUp status not found: fetch available statuses and ask the user to pick one
