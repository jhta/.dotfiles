---
name: daily-standup
description: >-
  Generate a daily standup summary by aggregating activity from GitHub, Slack,
  ClickUp, Google Calendar, and Google Drive. Use when the user asks for a
  standup, daily update, yesterday summary, what did I do, or end-of-day report.
---

# Daily Standup Generator

Aggregate the user's activity from **GitHub**, **Slack**, **ClickUp**, **Google Calendar**, and **Google Drive** into a two-tier standup report.

## Workflow

### 1. Determine the date range

- Default: **yesterday** (relative to today's date).
- If the user specifies a different date or range, use that instead.
- Compute `TARGET_DATE` in `YYYY-MM-DD` format and `NEXT_DATE` (TARGET_DATE + 1 day).
- Compute `7_DAYS_AGO` (TARGET_DATE - 7 days) for meeting notes search.

### 2. Gather data in parallel

Launch all five data sources simultaneously to minimize latency.

#### A. GitHub (via `gh` CLI)

```bash
# Get events for TARGET_DATE
gh api "/users/$(gh api /user --jq '.login')/events" --paginate \
  --jq '.[] | select(.created_at >= "TARGET_DATEt00:00:00Z" and .created_at < "NEXT_DATEt00:00:00Z") | {type, repo: .repo.name, created_at, action: (.payload.action // ""), ref: (.payload.ref // ""), ref_type: (.payload.ref_type // ""), title: (.payload.pull_request.title // .payload.issue.title // ""), number: (.payload.pull_request.number // .payload.issue.number // 0), commits: (.payload.commits // [] | length)}'
```

Then fetch PR titles for each unique PR number:

```bash
gh pr view <NUMBER> --repo <REPO> --json title,state,number
```

Categorize events into:
- **PRs merged** (`PullRequestEvent` with `action: closed, merged: true`)
- **PRs opened** (`PullRequestEvent` with `action: opened`)
- **PRs reviewed** (`PullRequestReviewEvent` or `PullRequestReviewCommentEvent`)
- **Branches created** (`CreateEvent` with `ref_type: branch`)
- **Pushes** (`PushEvent` — count commits)

Deduplicate review events by PR number. Extract ticket IDs from branch names using pattern `([A-Z]+-\d+)`.

#### B. Slack (via `plugin-slack-slack` MCP)

Use `slack_search_public_and_private` with:

```
query: "from:<@USER_ID> on:TARGET_DATE"
sort: "timestamp"
sort_dir: "asc"
include_context: false
response_format: "concise"
limit: 20
```

- The user's Slack ID is shown in the tool description.
- Paginate with `cursor` if results indicate more pages.
- Group messages by channel/DM.
- Extract **key discussion topics** (ignore trivial messages like "ok", "nice", single emoji).
- Summarize substantive conversations into 1-line bullets.
- For DM content: summarize the *topic* discussed, not the private content itself.

#### C. ClickUp (via `user-clickup` MCP)

1. Resolve the user's ClickUp ID:

```
clickup_resolve_assignees with assignees: ["me"]
```

2. Search for recently updated tasks:

```
clickup_filter_tasks with:
  assignees: [USER_ID]
  order_by: "updated"
  reverse: true
  include_closed: true
```

3. Also search for tickets referenced in GitHub branches/PRs:

```
clickup_search with:
  keywords: "TICKET-1 TICKET-2 ..."
  filters: { assignees: [USER_ID], asset_types: ["task"] }
  sort: [{ field: "updated_at", direction: "desc" }]
```

#### D. Google Calendar (via `gws` CLI)

```bash
gws calendar events list \
  --params '{
    "calendarId": "primary",
    "timeMin": "TARGET_DATEt00:00:00Z",
    "timeMax": "NEXT_DATEt00:00:00Z",
    "singleEvents": true,
    "orderBy": "startTime",
    "fields": "items(id,summary,start,end,attendees,description,organizer,status)"
  }'
```

- Include only events the user attended (filter: `attendees[].self=true` and `responseStatus=accepted`, or events the user organized).
- Skip declined events and all-day events that are not real meetings (e.g., OOO blocks, holidays).
- Extract: title, time slot, attendee count, agenda/description summary.
- Note any Google Doc URLs found in the event description — these are candidates for meeting notes.

#### E. Google Drive (via `gws` CLI)

**E1. Files modified by the user only:**

```bash
gws drive files list \
  --params '{
    "q": "modifiedTime > '\''TARGET_DATEt00:00:00Z'\'' and lastModifyingUser.me = true",
    "fields": "files(id,name,mimeType,modifiedTime,webViewLink,parents)",
    "orderBy": "modifiedTime desc"
  }'
```

**Important:** Only include files where `lastModifyingUser.me = true`. Discard any file where another user is the last modifier — even if it was modified the same day.

**E2. Meeting notes — find relevant Docs:**

```bash
gws drive files list \
  --params '{
    "q": "mimeType = '\''application/vnd.google-apps.document'\'' and (name contains '\''meeting'\'' or name contains '\''notes'\'' or name contains '\''recap'\'') and modifiedTime > '\''7_DAYS_AGO'\''",
    "fields": "files(id,name,modifiedTime,webViewLink)"
  }'
```

Also include any Doc URLs found in calendar event descriptions (Step D).

For each meeting-notes Doc found, read its content:

```bash
gws docs documents get --params '{"documentId": "DOC_ID"}'
```

Extract from each Doc:
- Action items (look for "action item", "TODO", "follow up", assignee patterns like "@name" or "Name:")
- Key decisions made
- Items specifically mentioning the user by name

---

### 3. Compile the two-tier output

#### TIER 1 — Team Summary (shareable)

This is the concise standup for the team. One line per item. No prose.

```markdown
## Standup — {DATE}

**Done:**
- [GitHub] Merged PR #N — TICKET-ID: Short title
- [GitHub] Opened PR #N — TICKET-ID: Short title
- [GitHub] Reviewed #N: Short PR title
- [ClickUp] TICKET-ID moved to {status}
- [Calendar] Attended: Meeting Name (key outcome in ≤8 words if available)
- [Drive] Updated: filename (type)

**Today:**
- Continue TICKET-ID: brief description
- Get PR #N through review
- (infer from open PRs, in-progress branches, and action items from meeting notes)

**Blockers:** (omit entire section if none)
- Blocker description
```

Rules:
- Group GitHub by type: merged > opened > reviewed.
- Deduplicate: PR both opened and merged same day → only "Merged".
- Omit empty sections entirely.
- Keep calendar entries to meaningful meetings only (skip 1:1s unless something notable happened).
- Drive entries: omit if the file change is trivial (e.g., minor doc edits with no significance).

---

#### TIER 2 — Extended Personal Log

This section is for personal review and storage.

```markdown
---
## Extended Activity Log — {DATE}

### GitHub
**PRs Merged ({count}):**
- **[TICKET-ID]** Title (#PR_NUMBER) — repo

**PRs Opened ({count}):**
- **[TICKET-ID]** Title (#PR_NUMBER) — status

**New Branches:**
- `branch-name` — description of work started

**Code Reviews ({count}):**
- #PR_NUMBER — Title (repo)

**Pushes:**
- {N} commits to `branch-name` in repo

---

### ClickUp
- **TICKET-ID** — Title → moved to *{status}* (was: *{previous_status}*)
- **TICKET-ID** — Title → commented / updated

---

### Calendar & Meetings
**{TIME} — Meeting Title** ({N} attendees)
- Agenda: ...
- Notes Doc: [link] (if available)

---

### Meeting Notes Highlights
**Doc: [Title](link)**
- Action items for me: ...
- Key decisions: ...
- Other relevant points: ...

---

### Drive Changes
| File | Type | Modified at | Link |
|------|------|-------------|------|
| filename | Google Doc / Sheet / etc. | HH:MM | [Open] |

---

### Slack Discussions
**#channel-name:**
- Topic summary line

**DM with Name:**
- Topic summary (no private details)
```

---

### 4. Formatting rules

- Omit any section (in both tiers) if it has no data.
- For "Working on Today" in Tier 1: infer from open PRs, in-progress branches, and action items from meeting notes.
- Slack DM content: summarize the *topic* only, not private content.
- Meeting notes: only surface items relevant to the user; skip unrelated decisions.
- Drive: show folder path if helpful for context (e.g., "Design / Q2 Specs").

---

### 5. Offer next steps

After presenting both tiers, ask:
- "Want me to send the Team Summary to a Slack channel?"
- "Want me to save the Extended Log to a Google Doc?"
