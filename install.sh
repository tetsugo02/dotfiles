#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SUFFIX="backup.$(date +%Y%m%d%H%M%S)"
NODE_VERSION="24.18.0"
PNPM_VERSION="11.15.0"
JAVA_VERSION="temurin-25.0.3+9.0.LTS"
TERMINAL_APP="${DOTFILES_TERMINAL:-}"

log() {
  printf '[dotfiles] %s\n' "$*"
}

ensure_dir() {
  mkdir -p "$1"
}

link_file() {
  local source="$1"
  local target="$2"

  ensure_dir "$(dirname "$target")"

  if [ -L "$target" ] && [ "$(readlink "$target")" = "$source" ]; then
    log "already linked: $target"
    return
  fi

  if [ -e "$target" ] || [ -L "$target" ]; then
    mv "$target" "$target.$BACKUP_SUFFIX"
    log "backed up: $target.$BACKUP_SUFFIX"
  fi

  ln -s "$source" "$target"
  log "linked: $target -> $source"
}

choose_terminal() {
  if [ -z "$TERMINAL_APP" ]; then
    if [ ! -t 0 ]; then
      log "Set DOTFILES_TERMINAL=alacritty or DOTFILES_TERMINAL=ghostty for non-interactive setup."
      return 1
    fi

    printf 'Which terminal should be installed?\n  1) Alacritty\n  2) Ghostty\n'
    while true; do
      read -r -p 'Select 1 or 2: ' TERMINAL_APP
      case "$TERMINAL_APP" in
        1) TERMINAL_APP="alacritty"; break ;;
        2) TERMINAL_APP="ghostty"; break ;;
        *) log "Enter 1 or 2." ;;
      esac
    done
  fi

  case "$TERMINAL_APP" in
    alacritty|ghostty) log "selected terminal: $TERMINAL_APP" ;;
    *) log "Invalid DOTFILES_TERMINAL: $TERMINAL_APP (expected alacritty or ghostty)"; return 1 ;;
  esac
}

link_terminal_config() {
  case "$TERMINAL_APP" in
    alacritty)
      link_file "$DOTFILES_DIR/config/alacritty/alacritty.toml" "$HOME/.config/alacritty/alacritty.toml"
      link_file "$DOTFILES_DIR/config/alacritty/themes/ayu_mirage.toml" "$HOME/.config/alacritty/themes/ayu_mirage.toml"
      ;;
    ghostty)
      link_file "$DOTFILES_DIR/config/ghostty/config" "$HOME/.config/ghostty/config"
      ;;
  esac
}

install_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    log "Homebrew is not installed. Install it first:"
    log '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    return
  fi

  log "installing Homebrew bundle"
  brew bundle --file "$DOTFILES_DIR/Brewfile"

  if brew list --cask --versions "$TERMINAL_APP" >/dev/null 2>&1; then
    log "$TERMINAL_APP is already installed"
  elif [ "$TERMINAL_APP" = ghostty ] && brew list --cask --versions ghostty@tip >/dev/null 2>&1; then
    log "ghostty@tip is already installed; using it instead of the conflicting ghostty cask"
  else
    brew install --cask "$TERMINAL_APP"
  fi
}

install_mise_tools() {
  if ! command -v mise >/dev/null 2>&1; then
    log "mise is not installed; skipping Node.js, pnpm, and Java setup"
    return
  fi

  mise use --global --pin \
    "node@$NODE_VERSION" \
    "pnpm@$PNPM_VERSION" \
    "java@$JAVA_VERSION"
}

install_rust() {
  if ! command -v rustup >/dev/null 2>&1; then
    log "rustup is not installed. Install it from https://rustup.rs/ if Rust is needed."
    return
  fi

  rustup toolchain install stable
  rustup default stable
}

main() {
  choose_terminal

  link_file "$DOTFILES_DIR/config/zsh/zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/config/zsh/zprofile" "$HOME/.zprofile"
  link_file "$DOTFILES_DIR/config/zsh/zshenv" "$HOME/.zshenv"
  link_file "$DOTFILES_DIR/config/zsh/profile" "$HOME/.profile"
  link_file "$DOTFILES_DIR/config/starship/starship.toml" "$HOME/.config/starship.toml"
  link_terminal_config
  link_file "$DOTFILES_DIR/config/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
  link_file "$DOTFILES_DIR/config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
  link_file "$DOTFILES_DIR/config/git/gitconfig" "$HOME/.gitconfig"
  link_file "$DOTFILES_DIR/config/ssh/config" "$HOME/.ssh/config"

  install_homebrew
  install_mise_tools
  install_rust

  log "done"
}

main "$@"
