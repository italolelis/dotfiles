#!/usr/bin/env bash
set -euo pipefail

# ── Constants ──────────────────────────────────────────────────────────────────
# Use a fixed constant — do NOT derive from BASH_SOURCE (see RESEARCH.md Pitfall 7)
export DOTFILES="$HOME/.dotfiles"  # exported for dot-packages
BACKUP_DIR="$HOME/.backup/dotfiles_$(date +%Y%m%d_%H%M%S)"
# Which packages to stow is decided by dot-packages (every top-level dir, minus a
# skip list); how to stow them by .stowrc. Run from the repo: bin/ is not stowed yet.
DOT_PACKAGES="$DOTFILES/bin/.local/bin/dot-packages"
# Single source of truth for pi's extension list, theme, and default model.
# Read straight from the repo so it works before the pi package is stowed.
PI_SETTINGS="$DOTFILES/pi/.pi/agent/settings.json"

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

# ── Arch / Omarchy ─────────────────────────────────────────────────────────────
# The Archfile is the Brewfile for Arch; arch-bundle installs whatever it lists
# that is missing. Run from the repo path: bin/ is not stowed yet.
arch_install_packages() {
  info "Running arch-bundle..."
  "$DOTFILES/bin/.local/bin/arch-bundle" install \
    || log "[warn] some Archfile entries failed — review output above"
}

# Global mise tools (node, gh, claude, codex, pi) from the stowed
# ~/.config/mise/config.toml. Omarchy ships mise; macOS gets these from brew.
install_mise_tools() {
  command -v mise &>/dev/null || return 0
  info "Installing mise tools..."
  mise install || log "[warn] some mise tools failed — review output above"
  # This script never sources the shell's mise activation; the shims make node, npm
  # and pi visible to install_pi below.
  export PATH="$HOME/.local/share/mise/shims:$PATH"
  ok "mise tools"
}

# ── Linux Setup ───────────────────────────────────────────────────────────────
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

install_cship() {
  info "Checking cship..."
  if command -v cship &>/dev/null; then
    ok "cship already installed: $(cship --version 2>/dev/null | head -1)"
    return 0
  fi
  log "Installing cship via official installer..."
  curl -fsSL https://cship.dev/install.sh | bash
  if ! command -v cship &>/dev/null && [[ -x "$HOME/.local/bin/cship" ]]; then
    log "cship installed to ~/.local/bin (ensure ~/.local/bin is on PATH)"
  fi
  if command -v cship &>/dev/null; then
    ok "cship installed"
  else
    log "[warn] cship install completed but binary not found on PATH — restart shell or check ~/.local/bin"
  fi
}

# ── pi (coding agent) ──────────────────────────────────────────────────────────
install_pi() {
  info "Checking pi..."
  if ! command -v npm &>/dev/null; then
    log "[warn] npm not found — skipping pi (install node first)"
    return 0
  fi

  if command -v pi &>/dev/null; then
    ok "pi already installed: $(pi --version 2>/dev/null | head -1)"
  else
    log "Installing pi via npm..."
    # bash/.bashrc sets npm_config_prefix, but this script is non-interactive and
    # never sources it - without this, npm would install into Homebrew's prefix
    # while ~/.npm-global/bin sits first on the shell PATH, so a later `npm i -g`
    # from an interactive shell would silently shadow this install.
    npm_config_prefix="$HOME/.npm-global" \
      npm install -g --ignore-scripts @earendil-works/pi-coding-agent
    export PATH="$HOME/.npm-global/bin:$PATH"
    if command -v pi &>/dev/null; then
      ok "pi installed"
    else
      log "[warn] pi not on PATH after install — check your npm global bin dir"
      return 0
    fi
  fi

  install_pi_packages
}

# Install every package listed in the tracked settings.json that isn't already
# present. Idempotent: existing packages are left untouched (no version churn).
install_pi_packages() {
  if [[ ! -f "$PI_SETTINGS" ]]; then
    log "No pi settings at $PI_SETTINGS — skipping extensions"
    return 0
  fi
  command -v pi &>/dev/null || return 0

  local installed spec specs
  installed="$(pi list 2>/dev/null | sed 's/^[[:space:]]*//' || true)"

  # node is guaranteed here (pi itself is an npm package), so use it rather
  # than adding a jq dependency to the Linux path.
  if ! specs="$(node -e '
    const fs = require("node:fs");
    const s = JSON.parse(fs.readFileSync(process.argv[1], "utf8"));
    for (const p of s.packages || []) console.log(p);
  ' "$PI_SETTINGS" 2>/dev/null)"; then
    log "[warn] could not parse $PI_SETTINGS — skipping extensions"
    return 0
  fi

  while IFS= read -r spec || [[ -n "$spec" ]]; do
    [[ -n "$spec" ]] || continue

    if grep -qxF "$spec" <<<"$installed"; then
      ok "pi extension present: $spec"
    else
      log "Installing pi extension: $spec"
      if pi install "$spec"; then
        ok "pi extension installed: $spec"
      else
        log "[warn] failed to install pi extension: $spec"
      fi
    fi
  done <<<"$specs"
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

  # Flags (--target=~, --no-folding) come from .stowrc, which stow only reads
  # from the current directory, hence the cd.
  (cd "$DOTFILES" && stow --restow "$pkg")
  ok "$pkg"
}

stow_packages() {
  local pkg
  while IFS= read -r pkg; do
    stow_package "$pkg"
  done < <("$DOT_PACKAGES")
}

# ── Git credential helper ──────────────────────────────────────────────────────
# The helper is platform-specific, so it lives in the untracked
# ~/.gitconfig.local (included by git/.gitconfig) rather than the tracked file.
configure_git_credentials() {
  info "Checking git credential helper..."
  local local_config="$HOME/.gitconfig.local"
  if git config --file "$local_config" credential.helper &>/dev/null; then
    ok "credential.helper already set in $local_config"
    return 0
  fi
  local helper=""
  if $IS_MACOS; then
    helper="osxkeychain"
  elif [[ -x /usr/lib/git-core/git-credential-libsecret ]]; then
    helper="/usr/lib/git-core/git-credential-libsecret"
  fi
  if [[ -n "$helper" ]]; then
    git config --file "$local_config" credential.helper "$helper"
    ok "credential.helper = $helper"
  else
    log "No credential helper available — skipping"
  fi
}

# ── This repo's own git config ─────────────────────────────────────────────────
# Repo-local, so it can't live in the tracked git/.gitconfig: the pre-commit hook
# that runs bin/.local/bin/dot-check.
configure_repo_git() {
  info "Configuring the dotfiles repo's git hook..."
  git -C "$DOTFILES" config core.hooksPath .githooks
  ok "pre-commit hook"
}

# ── Login shell ────────────────────────────────────────────────────────────────
check_login_shell() {
  local current
  if $IS_MACOS; then
    current="$(dscl . -read "/Users/$USER" UserShell 2>/dev/null | awk '{print $2}')"
  else
    current="$(getent passwd "$USER" 2>/dev/null | cut -d: -f7)"
  fi
  if [[ "${current##*/}" != bash ]]; then
    log "[warn] login shell is ${current:-unknown}, not bash — run: chsh -s /bin/bash"
  fi
}

# ── Proton Pass SSH agent ──────────────────────────────────────────────────────
# SSH keys live in the Proton Pass vault "SSH Keys". pass-cli serves them on
# ~/.ssh/proton-pass-agent.sock, which ssh/.ssh/config (IdentityAgent) and
# bash/.bashrc (SSH_AUTH_SOCK) point at. It needs `pass-cli login` once.
install_proton_ssh_agent() {
  info "Checking Proton Pass SSH agent..."
  local pass_cli
  if ! pass_cli="$(command -v pass-cli)"; then
    log "pass-cli not installed — skipping (the Brewfile installs it)"
    return 0
  fi
  local vault="SSH Keys"
  local socket="$HOME/.ssh/proton-pass-agent.sock"
  if $IS_MACOS; then
    local label="me.proton.pass-cli.ssh-agent"
    local plist="$HOME/Library/LaunchAgents/$label.plist"
    if launchctl print "gui/$(id -u)/$label" &>/dev/null; then
      ok "SSH agent already running ($label)"
    else
      mkdir -p "$(dirname "$plist")"
      # ThrottleInterval: before `pass-cli login` the agent exits at once, and
      # KeepAlive would otherwise restart it every ten seconds.
      cat >"$plist" <<EOF
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>Label</key>
  <string>$label</string>
  <key>ProgramArguments</key>
  <array>
    <string>$pass_cli</string>
    <string>ssh-agent</string>
    <string>start</string>
    <string>--vault-name</string>
    <string>$vault</string>
    <string>--socket-path</string>
    <string>$socket</string>
  </array>
  <key>RunAtLoad</key>
  <true/>
  <key>KeepAlive</key>
  <true/>
  <key>ThrottleInterval</key>
  <integer>60</integer>
  <key>StandardOutPath</key>
  <string>$HOME/.ssh/proton-pass-agent.log</string>
  <key>StandardErrorPath</key>
  <string>$HOME/.ssh/proton-pass-agent.log</string>
</dict>
</plist>
EOF
      launchctl bootstrap "gui/$(id -u)" "$plist"
      ok "SSH agent starts at login ($label)"
    fi
  elif $IS_LINUX && command -v systemctl &>/dev/null; then
    # `pass-cli login` fails after the browser step ("Error opening temp session
    # file") when its session dir is missing: 2.4.2 needed the data dir, 2.5.1
    # needs .session inside it too (seen 2026-10-30, after a re-login).
    local pass_data="$HOME/.local/share/proton-pass-cli"
    mkdir -p "$pass_data/.session" && chmod 700 "$pass_data" "$pass_data/.session"
    local unit="proton-pass-ssh-agent.service"
    if systemctl --user is-enabled "$unit" &>/dev/null; then
      ok "SSH agent already enabled ($unit)"
    else
      mkdir -p "$HOME/.config/systemd/user"
      cat >"$HOME/.config/systemd/user/$unit" <<EOF
[Unit]
Description=Proton Pass SSH agent

[Service]
ExecStart=$pass_cli ssh-agent start --vault-name "$vault" --socket-path $socket
Restart=on-failure
RestartSec=60

[Install]
WantedBy=default.target
EOF
      systemctl --user enable --now "$unit"
      ok "SSH agent starts at login ($unit)"
    fi
  fi
  if ! "$pass_cli" info &>/dev/null; then
    log "[warn] pass-cli is not logged in: run \`pass-cli login\`; the agent serves no keys until then"
  fi
}

# ── OpenXLR (Elgato Wave XLR) ──────────────────────────────────────────────────
# The Archfile installs openxlr, but a package cannot touch $HOME: enable its user
# daemon here and link its Omarchy bar plugin. The link needs a running Omarchy shell.
setup_openxlr() {
  info "Checking OpenXLR..."
  if ! command -v openxlr-daemon &>/dev/null; then
    log "openxlr not installed — skipping (the Archfile installs it)"
    return 0
  fi
  if systemctl --user is-enabled openxlr-daemon.service &>/dev/null; then
    ok "daemon already enabled"
  else
    systemctl --user enable --now openxlr-daemon.service
    ok "daemon starts at login"
  fi
  if [[ -e "$HOME/.config/omarchy/plugins/openxlr.mixer" ]]; then
    ok "bar plugin already linked"
  elif command -v openxlr-omarchy-enable &>/dev/null; then
    openxlr-omarchy-enable \
      || log "[warn] openxlr-omarchy-enable failed — run it inside the Omarchy session"
  fi
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
    install_cship
  elif $IS_LINUX; then
    # On Arch this installs stow, so the apt-based check below no-ops.
    if command -v pacman &>/dev/null; then
      arch_install_packages
    fi
    linux_require_stow
    linux_install_starship
    linux_install_fzf
    install_cship
  fi

  # ~/.ssh must stay private; create it before stow would make it 755.
  mkdir -p "$HOME/.ssh" && chmod 700 "$HOME/.ssh"
  stow_packages
  configure_git_credentials
  configure_repo_git
  install_proton_ssh_agent
  if $IS_LINUX; then setup_openxlr; fi
  check_login_shell
  install_mise_tools

  # After stowing: ~/.pi/agent/settings.json is a symlink into this repo by
  # now, so `pi install` records new packages in the tracked file rather than
  # in one that stow is about to replace.
  install_pi

  echo ""
  echo "=============================="
  echo "  Done! ($PLATFORM)"
  echo "  Restart your shell or run:"
  echo "    source ~/.bashrc"
  echo "=============================="
}

main "$@"
