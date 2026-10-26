#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
BACKUP_SUFFIX="backup.$(date +%Y%m%d%H%M%S)"
NODE_VERSION="24.18.0"
PNPM_VERSION="11.15.0"
JAVA_VERSION="temurin-25.0.3+9.0.LTS"
PYTHON_VERSION="3.14"
NERD_FONT_VERSION="v3.5.1"
ORCA_VERSION="1.4.240"
TERMINAL_APP="${DOTFILES_TERMINAL:-}"
OS_TYPE="${DOTFILES_OS:-}"

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

choose_os() {
  if [ -z "$OS_TYPE" ]; then
    if [ ! -t 0 ]; then
      case "$(uname -s)" in
        Darwin) OS_TYPE="macos" ;;
        Linux) OS_TYPE="linux" ;;
        *)
          log "Unsupported OS: $(uname -s). Set DOTFILES_OS=macos or DOTFILES_OS=linux for non-interactive setup."
          return 1
          ;;
      esac
      log "non-interactive shell: using detected OS ($OS_TYPE). Set DOTFILES_OS to override."
    else
      printf 'Which OS is this?\n  1) macOS\n  2) Linux (Ubuntu)\n'
      while true; do
        read -r -p 'Select 1 or 2: ' OS_TYPE
        case "$OS_TYPE" in
          1) OS_TYPE="macos"; break ;;
          2) OS_TYPE="linux"; break ;;
          *) log "Enter 1 or 2." ;;
        esac
      done
    fi
  fi

  case "$OS_TYPE" in
    macos)
      log "selected OS: macos"
      ;;
    linux)
      log "selected OS: linux"
      if ! command -v apt-get >/dev/null 2>&1; then
        log "Linux support requires an apt-based distribution (Ubuntu/Debian); apt-get was not found."
        return 1
      fi
      ;;
    *)
      log "Invalid DOTFILES_OS: $OS_TYPE (expected macos or linux)"
      return 1
      ;;
  esac
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

install_terminal() {
  case "$OS_TYPE" in
    macos) install_terminal_macos ;;
    linux) install_terminal_linux ;;
  esac
}

install_terminal_macos() {
  if ! command -v brew >/dev/null 2>&1; then
    log "Homebrew is not installed; skipping $TERMINAL_APP installation"
    return
  fi

  if brew list --cask --versions "$TERMINAL_APP" >/dev/null 2>&1; then
    log "$TERMINAL_APP is already installed"
  elif [ "$TERMINAL_APP" = ghostty ] && brew list --cask --versions ghostty@tip >/dev/null 2>&1; then
    log "ghostty@tip is already installed; using it instead of the conflicting ghostty cask"
  else
    brew install --cask "$TERMINAL_APP"
  fi
}

install_terminal_linux() {
  if dpkg -s "$TERMINAL_APP" >/dev/null 2>&1; then
    log "$TERMINAL_APP is already installed"
    return
  fi

  if ! sudo apt-get install -y "$TERMINAL_APP"; then
    log "apt install $TERMINAL_APP failed. Enable the 'universe' repository (sudo add-apt-repository universe && sudo apt-get update) or follow the upstream install docs: https://ghostty.org/docs/install/binary (Ghostty) / https://github.com/alacritty/alacritty/blob/master/INSTALL.md (Alacritty)."
  fi
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

install_gh_apt() {
  if command -v gh >/dev/null 2>&1; then
    log "gh is already installed"
    return
  fi

  log "installing gh (GitHub CLI) from the official apt repository"
  sudo install -d -m 755 /etc/apt/keyrings
  curl -fsSL https://cli.github.com/packages/githubcli-archive-keyring.gpg \
    | sudo tee /etc/apt/keyrings/githubcli-archive-keyring.gpg >/dev/null
  sudo chmod go+r /etc/apt/keyrings/githubcli-archive-keyring.gpg
  echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/githubcli-archive-keyring.gpg] https://cli.github.com/packages stable main" \
    | sudo tee /etc/apt/sources.list.d/github-cli.list >/dev/null
  sudo apt-get update
  sudo apt-get install -y gh
}

install_nerd_font_linux() {
  local font_dir="$HOME/.local/share/fonts/RobotoMonoNerdFont"

  if [ -d "$font_dir" ] && [ -n "$(ls -A "$font_dir" 2>/dev/null)" ]; then
    log "RobotoMono Nerd Font is already installed"
    return
  fi

  log "installing RobotoMono Nerd Font"
  ensure_dir "$font_dir"
  local tmp_archive
  tmp_archive="$(mktemp)"
  curl -fsSL "https://github.com/ryanoasis/nerd-fonts/releases/download/$NERD_FONT_VERSION/RobotoMono.tar.xz" -o "$tmp_archive"
  tar -xJf "$tmp_archive" -C "$font_dir"
  rm -f "$tmp_archive"
  command -v fc-cache >/dev/null 2>&1 && fc-cache -f "$font_dir" >/dev/null
}

install_zsh_autocomplete_linux() {
  local target="$HOME/.zsh-autocomplete"

  if [ -d "$target" ]; then
    log "zsh-autocomplete is already installed"
    return
  fi

  log "cloning zsh-autocomplete"
  git clone --depth 1 https://github.com/marlonrichert/zsh-autocomplete.git "$target"
}

install_starship_linux() {
  if command -v starship >/dev/null 2>&1; then
    log "starship is already installed"
    return
  fi

  log "installing starship"
  curl -sS https://starship.rs/install.sh | sh -s -- -y
}

ensure_zsh_default_shell_linux() {
  local zsh_path
  zsh_path="$(command -v zsh)"

  if [ "${SHELL:-}" = "$zsh_path" ]; then
    log "zsh is already the default shell"
    return
  fi

  log "setting zsh as the default shell (you may be prompted for your password)"
  if ! chsh -s "$zsh_path" "$USER"; then
    log "failed to change default shell automatically; run 'chsh -s $zsh_path' manually"
  fi
}

install_apt_packages() {
  log "installing apt packages"
  sudo apt-get update
  sudo apt-get install -y \
    zsh git gnupg ripgrep tree ffmpeg imagemagick \
    fonts-noto-cjk fonts-noto-cjk-extra

  ensure_zsh_default_shell_linux
  install_gh_apt
  install_nerd_font_linux
  install_zsh_autocomplete_linux
  install_starship_linux
}

install_orca_linux() (
  if [ "$(dpkg-query -W -f='${Status}' orca-ide 2>/dev/null || true)" = 'install ok installed' ]; then
    log "Orca is already installed"
    return
  fi

  local arch tmp_dir package
  arch="$(dpkg --print-architecture)"
  case "$arch" in
    amd64|arm64) ;;
    *) log "Orca does not provide a .deb for $arch; skipping installation"; return ;;
  esac

  tmp_dir="$(mktemp -d)"
  trap 'rm -rf "$tmp_dir"' EXIT
  package="$tmp_dir/orca-ide_${ORCA_VERSION}_${arch}.deb"
  log "installing Orca $ORCA_VERSION ($arch)"
  curl -fsSL "https://github.com/stablyai/orca/releases/download/v${ORCA_VERSION}/orca-ide_${ORCA_VERSION}_${arch}.deb" -o "$package"
  # Allow apt's _apt user to read the downloaded package.
  chmod 755 "$tmp_dir"
  chmod 644 "$package"
  sudo apt-get install -y "$package"
)

install_mise_cli_linux() {
  if command -v mise >/dev/null 2>&1; then
    log "mise is already installed"
    return
  fi

  log "installing mise"
  curl -fsSL https://mise.run | sh
  export PATH="$HOME/.local/bin:$PATH"
}

install_uv_linux() {
  if command -v uv >/dev/null 2>&1; then
    log "uv is already installed"
  else
    log "installing uv"
    curl -LsSf https://astral.sh/uv/install.sh | sh
    export PATH="$HOME/.local/bin:$PATH"
  fi

  log "installing Python $PYTHON_VERSION via uv"
  uv python install "$PYTHON_VERSION"
}

install_agent_clis() {
  if command -v codex >/dev/null 2>&1; then
    log "codex is already installed"
  else
    log "installing codex"
    curl -fsSL https://chatgpt.com/codex/install.sh | sh
  fi

  if command -v claude >/dev/null 2>&1; then
    log "claude (Claude Code) is already installed"
  else
    log "installing Claude Code"
    curl -fsSL https://claude.ai/install.sh | bash
  fi

  if command -v herdr >/dev/null 2>&1; then
    log "herdr is already installed"
  else
    log "installing herdr"
    curl -fsSL https://herdr.dev/install.sh | sh
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
  choose_os
  choose_terminal

  link_file "$DOTFILES_DIR/config/zsh/zshrc" "$HOME/.zshrc"
  link_file "$DOTFILES_DIR/config/zsh/zprofile" "$HOME/.zprofile"
  link_file "$DOTFILES_DIR/config/zsh/zshenv" "$HOME/.zshenv"
  link_file "$DOTFILES_DIR/config/zsh/profile" "$HOME/.profile"
  link_file "$DOTFILES_DIR/config/starship/starship.toml" "$HOME/.config/starship.toml"
  link_terminal_config
  link_file "$DOTFILES_DIR/config/opencode/opencode.json" "$HOME/.config/opencode/opencode.json"
  link_file "$DOTFILES_DIR/config/git/gitconfig" "$HOME/.gitconfig"
  link_file "$DOTFILES_DIR/config/ssh/config" "$HOME/.ssh/config"
  bash "$DOTFILES_DIR/scripts/sync-agent-instructions.sh"

  case "$OS_TYPE" in
    macos)
      install_homebrew
      ;;
    linux)
      install_apt_packages
      install_orca_linux
      install_mise_cli_linux
      install_uv_linux
      ;;
  esac

  install_terminal
  install_mise_tools
  install_rust
  install_agent_clis

  log "done"
}

main "$@"
