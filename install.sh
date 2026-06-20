#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SUFFIX="backup.$(date +%Y%m%d%H%M%S)"

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

install_homebrew() {
  if ! command -v brew >/dev/null 2>&1; then
    log "Homebrew is not installed. Install it first:"
    log '/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"'
    return
  fi

  log "installing Homebrew bundle"
  brew bundle --file "$DOTFILES_DIR/Brewfile"
}

install_nvm() {
  if [ ! -d "$HOME/.nvm" ]; then
    log "nvm is not installed. Install nvm manually, then rerun this script."
    log "https://github.com/nvm-sh/nvm"
    return
  fi

  # shellcheck source=/dev/null
  . "$HOME/.nvm/nvm.sh"
  nvm install 22.18.0
  nvm alias default 22.18.0
  corepack enable || true
  npm install -g @github/copilot npm@10.9.3
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
  link_file "$DOTFILES_DIR/config/zsh/zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/config/zsh/zprofile" "$HOME/.zprofile"
  link_file "$DOTFILES_DIR/config/zsh/zshenv" "$HOME/.zshenv"
  link_file "$DOTFILES_DIR/config/zsh/profile" "$HOME/.profile"
  link_file "$DOTFILES_DIR/config/starship/starship.toml" "$HOME/.config/starship.toml"
  link_file "$DOTFILES_DIR/config/zellij/config.kdl" "$HOME/.config/zellij/config.kdl"
  link_file "$DOTFILES_DIR/config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
  link_file "$DOTFILES_DIR/config/git/gitconfig" "$HOME/.gitconfig"
  link_file "$DOTFILES_DIR/config/ssh/config" "$HOME/.ssh/config"

  install_homebrew
  install_nvm
  install_rust

  log "done"
}

main "$@"

