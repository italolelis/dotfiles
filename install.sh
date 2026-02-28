#!/usr/bin/env bash
set -euo pipefail

# ── Constants ──────────────────────────────────────────────────────────────────
# Use a fixed constant — do NOT derive from BASH_SOURCE (see RESEARCH.md Pitfall 7)
DOTFILES="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.backup/dotfiles_$(date +%Y%m%d_%H%M%S)"
PACKAGES=(zsh git tmux starship ghostty ssh misc)

# ── Helpers ────────────────────────────────────────────────────────────────────
log()  { echo "  $1"; }
ok()   { echo "  [ok] $1"; }
info() { echo ""; echo "==> $1"; }
fail() { echo "  [fail] $1" >&2; exit 1; }

# ── Platform Detection ─────────────────────────────────────────────────────────
PLATFORM="$(/usr/bin/uname -s)"
IS_MACOS=false
IS_LINUX=false

case "$PLATFORM" in
  Darwin) IS_MACOS=true ;;
  Linux)  IS_LINUX=true ;;
  *)      fail "Unsupported platform: $PLATFORM" ;;
esac

# ── Homebrew ───────────────────────────────────────────────────────────────────
install_homebrew() {
  info "Checking Homebrew..."
  if ! command -v brew &>/dev/null; then
    log "Homebrew not found. Installing..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
    # Evaluate shellenv to make brew available in current session
    if [[ "$(uname -m)" == "arm64" ]]; then
      eval "$(/opt/homebrew/bin/brew shellenv)"
    else
      eval "$(/usr/local/bin/brew shellenv)"
    fi
    ok "Homebrew installed"
  else
    ok "Homebrew already installed"
  fi
}

# ── Stow ───────────────────────────────────────────────────────────────────────
require_stow() {
  info "Checking GNU Stow..."
  if ! command -v stow &>/dev/null; then
    log "GNU Stow not found. Attempting: brew install stow..."
    brew install stow
  fi
  if ! command -v stow &>/dev/null; then
    fail "GNU Stow not found after install attempt. Install manually: brew install stow"
  fi
  local ver
  ver=$(stow --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  ok "GNU Stow version: $ver"
}

# ── Brewfile ───────────────────────────────────────────────────────────────────
run_brew_bundle() {
  info "Running brew bundle..."
  if [[ -f "$DOTFILES/Brewfile" ]]; then
    brew bundle install --file="$DOTFILES/Brewfile" || log "Some packages failed — review output above"
    ok "Brew bundle done"
  else
    log "Brewfile not found at $DOTFILES/Brewfile — skipping (will be added in plan 01-03)"
  fi
}

# ── Linux Setup ───────────────────────────────────────────────────────────────
linux_require_zsh() {
  info "Checking zsh (Linux)..."
  if command -v zsh &>/dev/null; then
    ok "zsh already installed: $(zsh --version)"
    return 0
  fi
  if command -v apt-get &>/dev/null; then
    log "Installing zsh via apt-get..."
    if [[ "$(id -u)" -eq 0 ]]; then
      apt-get update -qq && apt-get install -y zsh
    elif command -v sudo &>/dev/null; then
      sudo apt-get update -qq && sudo apt-get install -y zsh
    else
      log "No sudo access and zsh not found — stowing git config only"
      stow_package git
      exit 0
    fi
    ok "zsh installed"
  else
    fail "Cannot install zsh — apt-get not available and zsh not found"
  fi
}

linux_require_stow() {
  info "Checking GNU Stow (Linux)..."
  if command -v stow &>/dev/null; then
    ok "GNU Stow already installed"
    return 0
  fi
  if command -v apt-get &>/dev/null; then
    log "Installing stow via apt-get..."
    if [[ "$(id -u)" -eq 0 ]]; then
      apt-get install -y stow
    elif command -v sudo &>/dev/null; then
      sudo apt-get install -y stow
    else
      fail "GNU Stow not found and no sudo access. Install manually."
    fi
    ok "GNU Stow installed via apt"
  else
    fail "GNU Stow not found and apt-get unavailable. Install manually."
  fi
}

linux_install_antidote() {
  info "Checking antidote (Linux)..."
  if [[ -d "$HOME/.antidote" ]]; then
    ok "antidote already at ~/.antidote"
    return 0
  fi
  if ! command -v git &>/dev/null; then
    fail "git is required to install antidote"
  fi
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
  ok "antidote installed at ~/.antidote"
}

linux_install_starship() {
  info "Checking starship (Linux)..."
  if command -v starship &>/dev/null; then
    ok "starship already installed"
    return 0
  fi
  mkdir -p "$HOME/.local/bin"
  curl -sS https://starship.rs/install.sh | sh -s -- -b "$HOME/.local/bin" -y
  ok "starship installed to ~/.local/bin"
}

linux_install_fzf() {
  info "Checking fzf (Linux)..."
  if command -v fzf &>/dev/null; then
    local fzf_ver
    fzf_ver=$(fzf --version 2>/dev/null | grep -oE '[0-9]+\.[0-9]+' | head -1)
    ok "fzf already installed (v${fzf_ver})"
    return 0
  fi
  if [[ -d "$HOME/.fzf" ]]; then
    ok "fzf directory exists at ~/.fzf — run ~/.fzf/install if not working"
    return 0
  fi
  git clone --depth 1 https://github.com/junegunn/fzf.git "$HOME/.fzf"
  "$HOME/.fzf/install" --bin
  ok "fzf installed at ~/.fzf"
}

# ── Conflict Backup ────────────────────────────────────────────────────────────
# For each package, find regular files (not symlinks) that would conflict with
# stow and move them to ~/.backup/ before stowing.
# This implements the pre-stow conflict resolution from RESEARCH.md Pattern 3.
backup_and_remove_conflict() {
  local target="$1"
  if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$target" "$BACKUP_DIR/"
    log "Backed up: $target -> $BACKUP_DIR/"
  fi
}

backup_conflicts() {
  local pkg="$1"
  if [[ ! -d "$DOTFILES/$pkg" ]]; then
    return 0
  fi
  while IFS= read -r -d '' src; do
    local rel="${src#"$DOTFILES/$pkg/"}"
    local target="$HOME/$rel"
    backup_and_remove_conflict "$target"
  done < <(find "$DOTFILES/$pkg" -type f -print0)
}

# ── Stow Packages ─────────────────────────────────────────────────────────────
stow_package() {
  local pkg="$1"
  info "Stowing $pkg..."

  if [[ ! -d "$DOTFILES/$pkg" ]]; then
    log "Package directory $DOTFILES/$pkg not found — skipping"
    return 0
  fi

  # Back up any conflicting regular files before stowing
  backup_conflicts "$pkg"

  stow --restow --no-folding \
    --target="$HOME" \
    --dir="$DOTFILES" \
    "$pkg"
  ok "$pkg"
}

stow_packages() {
  for pkg in "${PACKAGES[@]}"; do
    stow_package "$pkg"
  done
}

# ── Main ───────────────────────────────────────────────────────────────────────
main() {
  echo ""
  echo "=============================="
  echo "  Dotfiles installer"
  echo "=============================="

  # Confirmation prompt — skip if --force or -f passed (for devcontainer/automation)
  if [[ "${1:-}" != "--force" ]] && [[ "${1:-}" != "-f" ]]; then
    echo ""
    read -rp "  This will stow dotfiles from $DOTFILES into $HOME. Continue? (y/N) " reply
    [[ "$reply" =~ ^[Yy]$ ]] || { echo "  Aborted."; exit 0; }
  fi

  if $IS_MACOS; then
    install_homebrew
    require_stow
    run_brew_bundle
  elif $IS_LINUX; then
    linux_require_zsh
    linux_require_stow
    linux_install_antidote
    linux_install_starship
    linux_install_fzf
  fi

  stow_packages

  echo ""
  echo "=============================="
  echo "  Done! ($PLATFORM)"
  echo "  Restart your shell or run:"
  echo "    source ~/.zshrc"
  echo "=============================="
}

main "$@"
