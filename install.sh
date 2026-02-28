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

  install_homebrew
  require_stow
  run_brew_bundle
  stow_packages

  echo ""
  echo "=============================="
  echo "  Done!"
  echo "  Restart your shell or run:"
  echo "    source ~/.zshrc"
  echo "=============================="
}

main "$@"
