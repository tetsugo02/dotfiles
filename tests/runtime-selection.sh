#!/usr/bin/env bash
set -euo pipefail

source "$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)/install.sh"
trace="$(mktemp)"
trap 'rm -f "$trace"' EXIT

log() { :; }
brew() { printf 'brew %s\n' "$*" >> "$trace"; }
mise() { printf 'mise %s\n' "$*" >> "$trace"; }
install_mise_cli_linux() { printf 'install mise\n' >> "$trace"; }
install_uv_linux() { printf 'install uv/python\n' >> "$trace"; }
install_rust() { printf 'install rust\n' >> "$trace"; }

for invalid in '' ',node' 'node,' 'node,,java' 'jvm' 'node python' $'node\njava'; do
  if parse_runtimes "$invalid"; then
    printf 'Unexpected valid input: %s\n' "$invalid" >&2
    exit 1
  fi
done
parse_runtimes node,node,java
[ "$RUNTIMES" = node,java ]
parse_runtimes all
[ "$RUNTIMES" = node,python,java,rust ]
DOTFILES_RUNTIMES=none choose_runtimes
[ -z "$RUNTIMES" ]
unset DOTFILES_RUNTIMES
if choose_runtimes < /dev/null; then
  printf 'Non-interactive selection must require DOTFILES_RUNTIMES\n' >&2
  exit 1
fi

for OS_TYPE in macos linux; do
  for selection in none node python java all; do
    : > "$trace"
    parse_runtimes "$selection"
    install_runtime_managers
    install_mise_tools
    actual="$(cat "$trace")"
    case "$selection" in
      none) [ -z "$actual" ] ;;
      node)
        [[ "$actual" == *"node@$NODE_VERSION pnpm@$PNPM_VERSION"* ]]
        [[ "$actual" != *java* && "$actual" != *python* ]]
        ;;
      python)
        [[ "$actual" == *python* && "$actual" != *mise* ]]
        ;;
      java)
        [[ "$actual" == *"java@$JAVA_VERSION"* && "$actual" != *node* && "$actual" != *python* ]]
        ;;
      all)
        [[ "$actual" == *"node@$NODE_VERSION"* && "$actual" == *"java@$JAVA_VERSION"* && "$actual" == *python* ]]
        ;;
    esac
  done
done

# Exercise main's runtime and Rust gates without changing the machine.
choose_os() { :; }
choose_terminal() { :; }
link_file() { :; }
link_terminal_config() { :; }
install_homebrew() { :; }
install_apt_packages() { :; }
install_orca_linux() { :; }
install_terminal() { :; }
install_agent_clis() { :; }
bash() { :; } # Skip global instruction writes in main.
for selection in none rust; do
  : > "$trace"
  DOTFILES_RUNTIMES="$selection" main
  actual="$(cat "$trace")"
  if [ "$selection" = none ]; then
    [ -z "$actual" ]
  else
    [ "$actual" = 'install rust' ]
  fi
done
printf 'PASS: runtime validation, OS-specific installation, omission, and Rust selection\n'
