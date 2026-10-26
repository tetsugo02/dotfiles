#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

sync_instructions() {
  local target="$1"
  local start='<!-- DOTFILES_AGENT_INSTRUCTIONS_START -->'
  local end='<!-- DOTFILES_AGENT_INSTRUCTIONS_END -->'
  local tmp

  mkdir -p "$(dirname "$target")"
  tmp="$(mktemp)"
  if [ -e "$target" ]; then
    # Reject malformed markers instead of risking removal of personal instructions.
    if ! awk -v start="$start" -v end="$end" '
      $0 == start { if (inside || seen++) exit 1; inside = 1; next }
      $0 == end { if (!inside) exit 1; inside = 0; next }
      !inside { print }
      END { if (inside) exit 1 }
    ' "$target" > "$tmp"; then
      rm -f "$tmp"
      printf '[dotfiles] invalid instruction markers: %s\n' "$target" >&2
      return 1
    fi
  fi

  # Append directly after the preserved content so repeated runs add no blank lines.
  {
    printf '%s\n' "$start"
    cat "$DOTFILES_DIR/config/agents/instructions.md"
    printf '\n%s\n' "$end"
  } >> "$tmp"

  if [ -e "$target" ] && cmp -s "$tmp" "$target"; then
    rm -f "$tmp"
    printf '[dotfiles] instructions already synced: %s\n' "$target"
    return
  fi
  if [ -e "$target" ]; then
    local backup
    backup="$(mktemp "$target.backup.XXXXXXXX")"
    cp -p "$target" "$backup"
    printf '[dotfiles] backed up: %s\n' "$backup"
  fi
  # Preserve existing symlinks and permissions.
  cat "$tmp" > "$target"
  rm -f "$tmp"
  printf '[dotfiles] synced instructions: %s\n' "$target"
}

sync_instructions "${CODEX_HOME:-$HOME/.codex}/AGENTS.md"
sync_instructions "${CLAUDE_CONFIG_DIR:-$HOME/.claude}/CLAUDE.md"
