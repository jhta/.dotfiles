#!/usr/bin/env bash
# cmux-helpers.sh — Helper functions for cmux panel management
# Source this in your ~/.zshrc or ~/.bashrc:
#   source ~/.claude/skills/cmux/scripts/cmux-helpers.sh

# Split a cmux pane in the given direction and run a command
# Usage: cmux-split <direction> "<command>"
# Directions: right, left, up, down
cmux-split() {
  local direction="${1:-right}"
  local cmd="${2:-}"

  if [[ -z "$CMUX_SOCKET_PATH" ]] && [[ ! -S "/tmp/cmux.sock" ]]; then
    echo "Error: cmux socket not found. Are you running inside cmux?" >&2
    return 1
  fi

  local surface_ref
  surface_ref=$(cmux new-split "$direction" 2>&1)
  if [[ $? -ne 0 ]]; then
    echo "Error creating split: $surface_ref" >&2
    return 1
  fi

  # Extract surface ref from output like "OK surface:3 workspace:1"
  local surface
  surface=$(echo "$surface_ref" | grep -oE 'surface:[0-9]+')

  if [[ -n "$cmd" ]]; then
    cmux send --surface "$surface" "${cmd}
"
  fi

  echo "$surface"
}

# Open a file in vim in a new right panel
# Usage: cmux-vim <filepath> [line_number]
cmux-vim() {
  local filepath="$1"
  local line="${2:-}"

  if [[ -z "$filepath" ]]; then
    echo "Usage: cmux-vim <filepath> [line_number]" >&2
    return 1
  fi

  if [[ -n "$line" ]]; then
    cmux-split right "nvim +${line} ${filepath}"
  else
    cmux-split right "nvim ${filepath}"
  fi
}

# Show git diff in a new bottom panel (delta is configured as default git pager)
# Usage: cmux-diff [filepath]
cmux-diff() {
  local filepath="${1:-}"
  if [[ -n "$filepath" ]]; then
    cmux-split down "git diff -- ${filepath}"
  else
    cmux-split down "git diff"
  fi
}

# Show staged diff
cmux-diff-staged() {
  cmux-split down "git diff --staged"
}

# Show a commit's diff
# Usage: cmux-show [commit-hash]
cmux-show() {
  local commit="${1:-HEAD}"
  cmux-split down "git show ${commit}"
}

# Run a command in a new bottom panel, keep it open after completion
# Usage: cmux-run <command>
cmux-run() {
  local cmd="$*"
  if [[ -z "$cmd" ]]; then
    echo "Usage: cmux-run <command>" >&2
    return 1
  fi
  cmux-split down "bash -c '${cmd}; echo; echo \"--- finished (press q or Ctrl+C to close) ---\"; read'"
}

# Tail a log file in a new bottom strip
# Usage: cmux-tail <filepath>
cmux-tail() {
  local filepath="${1:-}"
  if [[ -z "$filepath" ]]; then
    echo "Usage: cmux-tail <filepath>" >&2
    return 1
  fi
  cmux-split down "tail -f ${filepath}"
}

# Notify when done
# Usage: some-long-command; cmux-done "Build finished"
cmux-done() {
  local message="${1:-Done}"
  cmux notify --title "cmux" --body "$message"
}
