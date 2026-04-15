---
name: cmux
description: Use this skill when the user mentions cmux, wants to open code/files in a new panel or pane, wants to view git diffs in a split view, wants to run terminal commands in a new panel, says "open the code", "show the diff", "run this in a new pane", "split the terminal", "open a panel", or wants to manage their cmux workspace layout for software development.
version: 1.0.0
---

# cmux Skill

cmux is a native macOS terminal multiplexer built on Ghostty, designed for running multiple AI coding agents and developer workflows simultaneously. This skill helps you manage panels, open files, view diffs, and run commands across split panes.

## Prerequisites

Ensure the cmux CLI is symlinked:
```bash
sudo ln -sf "/Applications/cmux.app/Contents/Resources/bin/cmux" /usr/local/bin/cmux
```

Verify it works:
```bash
cmux --help
```

## Core Concepts

- **Workspace**: A top-level container (like a tmux session), identified by `CMUX_WORKSPACE_ID`
- **Surface**: A pane/panel within a workspace, identified by `CMUX_SURFACE_ID`
- **Socket API**: cmux exposes a Unix socket at `CMUX_SOCKET_PATH` for programmatic pane control
- **Security**: Socket access is restricted to cmux-spawned processes by default (which includes Claude Code running inside cmux)

## Common Developer Workflows

### 1. Open a File in Neovim (New Right Panel)

When the user says "open the code", "show me the file", "open `<filepath>`":

```bash
# Split current pane to the right and open file in nvim
cmux-split right "nvim <filepath>"

# Example: open the current file being discussed
cmux-split right "nvim src/components/Button.tsx"

# Open with line number
cmux-split right "nvim +42 src/utils/helpers.ts"
```

Use the helper function from `scripts/cmux-helpers.sh` or run the socket command directly (see references/socket-api.md).

> **Editor**: Always use `nvim` (Neovim 0.11+), not `vim`. Neovim is configured with SpaceVim + `github_dark_default` colorscheme.

### 2. View Git Diff in a New Panel

When the user says "show the diff", "expand the diff", "open diff in a panel":

> **delta is configured as the default git pager** (side-by-side, line numbers, dark mode). Plain `git diff` already uses it — no need to pipe manually.

```bash
# Diff of all current changes — delta is automatic
cmux-split down "git diff"

# Diff of a specific file
cmux-split down "git diff -- src/components/Button.tsx"

# Diff of staged changes
cmux-split down "git diff --staged"

# Diff of a specific commit
cmux-split down "git show <commit-hash>"

# Explicit delta pipe (if needed outside git)
cmux-split down "git diff | delta"
```

### 3. Run a Command in a New Panel

When the user says "run this in a new panel", "execute in background pane", "run tests in a new pane":

```bash
# Run tests in a bottom panel
cmux-split down "npm test"
cmux-split down "pytest -v"
cmux-split down "go test ./..."

# Start a dev server in a right panel
cmux-split right "npm run dev"

# Run a build and keep output visible
cmux-split down "npm run build 2>&1 | tee build.log"

# Watch mode
cmux-split right "npm run test -- --watch"
```

### 4. Open Multiple Files Side by Side

When the user says "compare these files", "open both files":

```bash
# Open two files side by side
cmux-split right "vim <file1>"
# Then in the new pane:
cmux-split right "vim <file2>"
```

### 5. Check Workspace State

```bash
# List open workspaces
cmux list-workspaces

# Read what's currently on screen in this pane
cmux read-screen

# Send a notification when a long task finishes
cmux notify --title "Build Complete" --body "Build finished successfully"
```

## How to Execute Panel Splits

cmux has a native CLI. The pattern is: create a split → get the surface ref → send a command to it.

### Option A — Helper Script (recommended)

Source the helpers file or copy it to your PATH:
```bash
source ~/.claude/skills/cmux/scripts/cmux-helpers.sh

# Then use:
cmux-split right "vim src/index.ts"
cmux-split down "git diff | less -R"
cmux-split left "npm run dev"
cmux-split up "tail -f app.log"
```

### Option B — Direct CLI (two steps)

```bash
# Step 1: Create the split — returns "OK surface:3 workspace:1"
cmux new-split right

# Step 2: Send command to that surface (newline executes it)
cmux send --surface surface:3 "vim src/index.ts
"
```

### Option C — Send to Existing Pane

```bash
# Send a command to the current pane (runs in place)
cmux send "git diff
"

# Send a key press (e.g., Ctrl+C to stop a process)
cmux send-key "C-c"
```

## Decision Guide: Which Direction to Split

| Use case | Direction | Reason |
|---|---|---|
| View file / edit code | `right` | Wide panel for code |
| View git diff | `down` or `right` | Both work; `down` leaves editor accessible |
| Run long command / server | `right` | Monitor output alongside work |
| Tail logs | `down` | Small strip at bottom |
| Compare two files | `right` then `right` | Three-column layout |
| Run tests | `down` | Below current work |

## Example Prompts and What to Do

| User says | Action |
|---|---|
| "open the code" | Find the relevant file(s) in the project, run `cmux-split right "nvim <file>"` |
| "open `Button.tsx`" | Run `cmux-split right "nvim <path-to-Button.tsx>"` |
| "show me the diff" | Run `cmux-split down "git diff"` (delta is the default pager) |
| "expand the diffs" | Run `cmux-split down "git diff"` or `cmux-split down "git show <hash>"` |
| "run the tests in a new pane" | Run `cmux-split down "<test-command>"` |
| "start the dev server" | Run `cmux-split right "<start-command>"` |
| "open both files side by side" | Two sequential `cmux-split right "vim <file>"` calls |

## Error Handling

- **`CMUX_SOCKET_PATH` not set**: You are not inside a cmux session. Ask user to run Claude Code from within cmux, or use `cmux --help` to check available commands.
- **Socket connection refused**: cmux socket security may be set to "Off". User needs to enable it in cmux Settings > Security > Socket API.
- **`cmux` command not found**: Run the symlink setup command from Prerequisites above.
- **Split fails silently**: Verify `CMUX_WORKSPACE_ID` and `CMUX_SURFACE_ID` are set with `echo $CMUX_WORKSPACE_ID`.
