# dotfiles

Personal macOS development environment bootstrap.

## Install

Run this on a new Mac:

```sh
xcode-select --install
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
git clone git@github.com:tetsugo02/dotfiles.git ~/dotfiles
cd ~/dotfiles
./install.sh
```

If GitHub SSH is not ready yet, clone with HTTPS and switch remotes later.

## What This Sets Up

- Homebrew packages and casks from `Brewfile`
- zsh startup files
- Starship prompt
- Zellij config
- opencode config
- Git identity
- SSH client config
- nvm, Node.js, pnpm, uv, Rust, Java 17 paths

## Secrets

Secrets are intentionally not tracked. Put local credentials in:

```sh
~/.config/zsh/secrets.zsh
```

Use `config/zsh/secrets.zsh.example` as a template.

## Manual Steps

- Recreate or migrate SSH private keys into `~/.ssh`
- Run `gh auth login -h github.com`
- Sign in to app-store or vendor-installed apps manually
- Confirm Homebrew ownership if needed:

```sh
sudo chown -R "$USER":admin /opt/homebrew
```

