---
name: clickup-tickets
description: Manage ClickUp tickets for DEFI and CORE teams. Create, read, update, and search tickets in the right boards. Use when the user mentions ticket, tickets, clickup, or tasks in the context of project management.
---

# ClickUp Tickets Skill

Manage ClickUp tickets for the DEFI Wallet and Core App teams. All operations use `$CLICKUP_API_KEY` for authentication and workspace ID `$CLICKUP_WORKSPACE_ID`.

## Trigger Phrases

- "ticket" / "tickets"
- "clickup"
- "tasks" (in PM context)
- "create a ticket for DEFI/CORE"
- "update ticket DEFI-xxx / CORE-xxx"
- "show me tickets" / "list tickets"
- "what's in the sprint"

## Space & Board Reference

### DEFI Wallet
- Space ID: `$CLICKUP_DEFI_SPACE_ID`
- Sprint Folder ID: `$CLICKUP_DEFI_SPRINT_FOLDER_ID`
- DeFi MVP Folder ID: `$CLICKUP_DEFI_MVP_FOLDER_ID` (feature-based backlog)
- Statuses: `to do` | `in progress` | `in review` | `blocked` | `to be tested` | `to deploy` | `cancelled` | `complete`

### Core App
- Space ID: `$CLICKUP_CORE_SPACE_ID`
- **Backlog List ID: `$CLICKUP_CORE_BACKLOG_LIST_ID`** (always use this for CORE tickets)
- Statuses: `ready to refine` | `to do` | `refined` | `in progress` | `done`

### Common
- Team/Workspace ID: `$CLICKUP_WORKSPACE_ID`
- Custom task IDs format: `DEFI-xxx` / `CORE-xxx`

---

## Routing Logic

| User says | Target board |
|-----------|-------------|
| "DEFI" / "DEFI sprint" / "DeFi team" | Current active DEFI sprint (dynamic) |
| "DEFI backlog" | DeFi MVP folder — show feature lists, ask user to pick |
| "CORE" / "Core team" / "Core backlog" | Core App Backlog list (`$CLICKUP_CORE_BACKLOG_LIST_ID`) |

---

## Step 1: Detect Intent & Routing

Read the user's message and determine:
1. **Team**: DEFI or CORE
2. **Board**: sprint vs backlog (DEFI only; CORE always uses backlog)
3. **Action**: create / read / update / search / list

---

## Step 2: Find Current DEFI Sprint (when needed)

Query the sprint folder to find the active sprint dynamically:

```bash
curl -s "https://api.clickup.com/api/v2/folder/$CLICKUP_DEFI_SPRINT_FOLDER_ID/list?archived=false" \
  -H "Authorization: $CLICKUP_API_KEY" | jq '[.lists[] | {id, name, orderindex}] | sort_by(.orderindex)'
```

Parse the sprint name date ranges (format: `Sprint N (d/m - d/m)`). The dates don't include year — assume they are in the current year. Compare against today's date to find the active sprint. If unsure, take the sprint with the highest `orderindex` that has already started.

Example: Today is 2026-03-24 → Sprint with range `23/3 - 6/4` is current.

---

## Operations

### CREATE TICKET

**For DEFI sprint:**

```bash
# First find the current sprint list ID (Step 2 above)
SPRINT_LIST_ID="<current_sprint_id>"

curl -s -X POST \
  "https://api.clickup.com/api/v2/list/$SPRINT_LIST_ID/task" \
  -H "Authorization: $CLICKUP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "<TITLE>",
    "description": "<DESCRIPTION>",
    "status": "to do",
    "priority": 3
  }'
```

**For DEFI backlog (DeFi MVP feature lists):**

First, show the user the available feature lists to pick one:

```bash
curl -s "https://api.clickup.com/api/v2/folder/$CLICKUP_DEFI_MVP_FOLDER_ID/list?archived=false" \
  -H "Authorization: $CLICKUP_API_KEY" | jq '[.lists[] | {id, name}]'
```

Present the list to the user and ask which feature area the ticket belongs to. Then create in the chosen list.

**For CORE backlog:**

```bash
curl -s -X POST \
  "https://api.clickup.com/api/v2/list/$CLICKUP_CORE_BACKLOG_LIST_ID/task" \
  -H "Authorization: $CLICKUP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "name": "<TITLE>",
    "description": "<DESCRIPTION>",
    "status": "ready to refine",
    "priority": 3
  }'
```

**Priority mapping:**
- urgent → 1
- high → 2
- normal → 3 (default)
- low → 4

**After creating**, display:
```
✅ Ticket created: DEFI-xxx / CORE-xxx
   Title: <name>
   URL: https://app.clickup.com/t/$CLICKUP_WORKSPACE_ID/<custom_id>
   List: <sprint/backlog name>
   Status: to do
```

---

### READ / GET TICKET

Get a ticket by its custom ID (e.g., `DEFI-175` or `CORE-1368`):

```bash
curl -s "https://api.clickup.com/api/v2/task/<TICKET_ID>?custom_task_ids=true&team_id=$CLICKUP_WORKSPACE_ID" \
  -H "Authorization: $CLICKUP_API_KEY" | jq '{
    id: .custom_id,
    name: .name,
    status: .status.status,
    assignees: [.assignees[].username],
    priority: .priority.priority,
    description: .description,
    url: .url,
    list: .list.name
  }'
```

Display in a clean format with the ticket URL.

---

### LIST TICKETS

**List current DEFI sprint tasks:**

```bash
# First resolve current sprint ID (Step 2)
curl -s "https://api.clickup.com/api/v2/list/<SPRINT_LIST_ID>/task?archived=false" \
  -H "Authorization: $CLICKUP_API_KEY" | jq '[.tasks[] | {id: .custom_id, name, status: .status.status, assignees: [.assignees[].username]}]'
```

**List CORE backlog tasks:**

```bash
curl -s "https://api.clickup.com/api/v2/list/$CLICKUP_CORE_BACKLOG_LIST_ID/task?archived=false&order_by=created&reverse=true&limit=20" \
  -H "Authorization: $CLICKUP_API_KEY" | jq '[.tasks[] | {id: .custom_id, name, status: .status.status}]'
```

Present results grouped by status or in a readable table.

---

### UPDATE TICKET

**Update status:**

```bash
# First fetch available statuses from the list to avoid invalid status errors:
curl -s "https://api.clickup.com/api/v2/task/<TICKET_ID>?custom_task_ids=true&team_id=$CLICKUP_WORKSPACE_ID" \
  -H "Authorization: $CLICKUP_API_KEY" | jq '{status: .status.status, list_id: .list.id}'

curl -s "https://api.clickup.com/api/v2/list/<LIST_ID>" \
  -H "Authorization: $CLICKUP_API_KEY" | jq '[.statuses[].status]'
```

Then update:

```bash
curl -s -X PUT \
  "https://api.clickup.com/api/v2/task/<TICKET_ID>?custom_task_ids=true&team_id=$CLICKUP_WORKSPACE_ID" \
  -H "Authorization: $CLICKUP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"status": "<NEW_STATUS>"}'
```

**Update title/description/priority:**

```bash
curl -s -X PUT \
  "https://api.clickup.com/api/v2/task/<TICKET_ID>?custom_task_ids=true&team_id=$CLICKUP_WORKSPACE_ID" \
  -H "Authorization: $CLICKUP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{"name": "<TITLE>", "description": "<DESCRIPTION>", "priority": 3}'
```

**IMPORTANT: Always confirm with the user before updating an existing ticket.** Show a summary of what will change:

```
I'm about to update DEFI-175:
  - Status: "in progress" → "in review"

Proceed? (yes/no)
```

---

### SEARCH TICKETS

Search within a specific space:

```bash
# Search DEFI space
curl -s "https://api.clickup.com/api/v2/team/$CLICKUP_WORKSPACE_ID/task?space_ids[]=$CLICKUP_DEFI_SPACE_ID&query=<SEARCH_TERM>&include_closed=false" \
  -H "Authorization: $CLICKUP_API_KEY" | jq '[.tasks[] | {id: .custom_id, name, status: .status.status, list: .list.name}]'

# Search CORE space
curl -s "https://api.clickup.com/api/v2/team/$CLICKUP_WORKSPACE_ID/task?space_ids[]=$CLICKUP_CORE_SPACE_ID&query=<SEARCH_TERM>&include_closed=false" \
  -H "Authorization: $CLICKUP_API_KEY" | jq '[.tasks[] | {id: .custom_id, name, status: .status.status, list: .list.name}]'
```

---

### ADD COMMENT

```bash
curl -s -X POST \
  "https://api.clickup.com/api/v2/task/<TICKET_ID>/comment?custom_task_ids=true&team_id=$CLICKUP_WORKSPACE_ID" \
  -H "Authorization: $CLICKUP_API_KEY" \
  -H "Content-Type: application/json" \
  -d '{
    "comment_text": "<COMMENT>",
    "notify_all": false
  }'
```

---

## Error Handling

- **Missing API key**: Check `echo $CLICKUP_API_KEY`. If empty, tell the user to set it in their shell profile.
- **Invalid status**: Fetch the list's available statuses and show them to the user.
- **Ticket not found**: Verify the custom ID format (`DEFI-xxx` or `CORE-xxx`) and confirm team_id is `$CLICKUP_WORKSPACE_ID`.
- **Rate limit (429)**: Wait a moment and retry once. If it persists, inform the user.

---

## Output Format

After any operation, always display the ticket URL in this format:
```
https://app.clickup.com/t/$CLICKUP_WORKSPACE_ID/<custom_id>
```

Example: `https://app.clickup.com/t/$CLICKUP_WORKSPACE_ID/DEFI-175`
