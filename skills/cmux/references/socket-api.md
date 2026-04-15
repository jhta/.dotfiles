# cmux Socket API Reference

cmux exposes a Unix socket for programmatic panel control. The socket path is in `$CMUX_SOCKET_PATH`.

## Security Levels

| Level | Who can connect |
|---|---|
| Off | Nobody (disabled) |
| cmux processes only (default) | Processes spawned inside cmux (Claude Code, shells, etc.) |
| allowAll | Any local process |

If you get "connection refused", go to cmux Settings > Security > Socket API and set to "cmux processes only".

## Sending Commands

```bash
echo '<json-payload>' | nc -U "$CMUX_SOCKET_PATH"
```

## Split Pane

```json
{"type": "split", "direction": "right", "command": "vim src/index.ts"}
```

Directions: `right`, `left`, `up`, `down`

The `command` field is optional. Without it, a plain shell is opened.

## Send Text to Terminal

```bash
cmux send "npm test\n"
```

The `\n` sends Enter to execute. Without it, text is typed but not submitted.

## Send Key Press

```bash
cmux send-key "C-c"   # Ctrl+C
cmux send-key "C-z"   # Ctrl+Z (background)
cmux send-key "q"     # quit (e.g., in less/vim)
```

## Read Screen Contents

```bash
cmux read-screen
```

Returns the text currently visible in the active pane. Useful for Claude to see command output.

## List Workspaces

```bash
cmux list-workspaces
```

Returns JSON with workspace IDs and names.

## Notifications

```bash
cmux notify --title "Tests Passed" --body "All 42 tests green"
```

Sends a macOS native notification from within cmux.

## Environment Variables

| Variable | Description |
|---|---|
| `CMUX_WORKSPACE_ID` | Current workspace ID |
| `CMUX_SURFACE_ID` | Current pane/surface ID |
| `CMUX_SOCKET_PATH` | Path to the Unix socket |

## Browser Automation (Bonus)

cmux has an embedded browser with automation support:

```bash
cmux browser open "https://localhost:3000"
cmux browser snapshot          # Screenshot current browser view
cmux browser click "button#submit"  # Click a DOM element
```
