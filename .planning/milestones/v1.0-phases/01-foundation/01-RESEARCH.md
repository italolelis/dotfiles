# Phase 1: Foundation - Research

**Researched:** 2026-02-28
**Domain:** GNU Stow symlink management, Homebrew Bundle, Shell scripting, macOS defaults
**Confidence:** HIGH (core stack well-understood; macOS defaults Sequoia compatibility is MEDIUM)

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Stow Package Structure**
- One Stow package per tool: zsh/, git/, tmux/, starship/, ghostty/, ssh/
- All shell files (.zshrc, .aliases, .functions, .exports, .path, .extra, .zsh_completions) live in the zsh/ package — they're tightly coupled
- SSH config (hosts, options) stowed as ssh/ package; private keys excluded via .stow-local-ignore
- Ghostty config under ghostty/.config/ghostty/ to mirror XDG path

**Claude's Discretion: Misc Files**
- Claude decides where to put "homeless" files (.editorconfig, .inputrc, .curlrc, .wgetrc) — likely a misc/ catch-all package

**Brewfile Curation**
- Audit current machine installs and walk through category by category with user
- Include GUI apps as casks (Ghostty, Cursor, browsers, etc.)
- Skip Mac App Store apps — no `mas` integration
- Organize Brewfile into sections with comment headers (# Development, # CLI Tools, etc.)
- Do NOT blindly adopt current machine state — present what's installed, user approves/removes each category

**Install Script Behavior**
- Step-by-step progress output: "Stowing zsh... done", "Stowing git... done" with status indicators
- Conflict handling: backup existing files to .backup/ directory, then create symlinks
- Confirmation prompt by default; --force flag skips confirmation (for automation/devcontainers)
- Auto-install Homebrew if not present (fresh Mac scenario)
- Idempotent: safe to run multiple times without errors or duplicate entries

**macOS Defaults**
- Audit and trim the existing .macos script (~295 lines) — remove deprecated/irrelevant settings
- Priority categories: Finder & Desktop, Dock & Mission Control, Keyboard & Input, Security & Privacy
- macos.sh is a SEPARATE step from install.sh — run manually when ready
- Set up specific Dock layout with predetermined app arrangement (gather app list during implementation)
- Verify Sequoia compatibility for all remaining defaults

**Git Config**
- Existing .gitconfig moves into git/ Stow package
- Global gitignore (.gitignore_global) included in git/ package

### Claude's Discretion

- Where to place "homeless" files (.editorconfig, .inputrc, .curlrc, .wgetrc) — recommend a misc/ catch-all package

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| FOUND-01 | Repo restructured into Stow packages (one dir per tool: zsh/, git/, tmux/, starship/, ghostty/, etc.) | GNU Stow package directory layout pattern; directory naming conventions; XDG path mirroring |
| FOUND-02 | Install script uses `stow` to create symlinks instead of rsync file copying | `stow --restow` for idempotency; conflict-then-backup pattern; `--no-folding` for XDG dirs |
| FOUND-03 | Install script is idempotent (safe to run multiple times) | `stow --restow` unstows+restows safely; `brew bundle install` is a no-op for already-installed packages |
| PKGS-01 | Brewfile created with curated list of brews, casks, and taps (audited against current machine, user-approved) | `brew bundle dump --describe` generates starting Brewfile; deprecated taps to remove; current machine state inventoried |
| PKGS-02 | `brew bundle` integrated into macOS install path | `brew bundle install` in macos.sh; `brew bundle check` for success criteria verification |
| TOOL-03 | Git config (signing key, aliases, global gitignore) as Stow package | git/.gitconfig + git/.gitignore_global layout; `core.excludesfile` path changes to symlink-relative |
| TOOL-04 | macOS defaults script audited for Sequoia compatibility | macos-defaults.com is the authoritative compatibility reference; .macos has Tahoe-specific entries that need removal |
</phase_requirements>

---

## Summary

This phase migrates a flat rsync-based dotfiles repo into a structured GNU Stow symlink-managed setup. The current repo at `~/.dotfiles` already contains most target files (`.aliases`, `.zshrc`, `.gitconfig`, `.starship.toml`, `.tmux.conf`, `.ssh/config`, `.config/ghostty/config`) but they live in a flat layout that rsync copies to `$HOME`. The task is to reorganize them into per-tool Stow packages where each package directory mirrors the `$HOME` path layout, replace the rsync install.sh with a Stow-based one, curate the Brewfile, and audit the macOS defaults script.

GNU Stow 2.4.0 is the critical version requirement. The long-standing bug where `--dotfiles` flag did not work with directories (e.g., `dot-config/`) was fixed in 2.4.0 — older versions require workarounds. Stow is not currently installed on this machine; it must be added to the Brewfile. The conflict-then-backup pattern (move existing files to `.backup/` before stowing) must be implemented manually in install.sh since Stow's built-in `--adopt` flag moves files INTO the stow directory (opposite of what we want) and must never be used as the first migration step.

The Brewfile requires significant cleanup: the existing `install/Brewfile` references several deprecated taps (`homebrew/bundle`, `homebrew/cask`, `homebrew/cask-fonts`, `homebrew/cask-versions`, `homebrew/core`) that were all deprecated by Homebrew 4.3.0/4.5.0 and will cause warnings or errors. The current machine state also differs substantially from the Brewfile — many listed packages (`exa`, `bat`, `fd`, `kubectl`, `kubectx`, `wireshark`, `nmap`, `pre-commit`, `netbird`) are not installed, and many installed packages (`bun`, `go`, `hugo`, `starship`, `tmux`, `ripgrep`, `thefuck`, `opencode`) are missing from it.

**Primary recommendation:** Use `stow --restow --no-folding --target=$HOME` per package in install.sh; handle conflicts with a pre-stow backup-and-remove script; require GNU Stow 2.4.0+ installed via Brewfile before stowing begins.

---

## Current Repo State (Discovered)

This is critical context for planning the migration:

### Files currently tracked in repo (flat layout, NOT yet in packages):
```
.aliases
.config/ghostty/config     # already in XDG-style path
.curlrc
.editorconfig
.exports
.extra
.functions
.gitconfig
.gitignore_global
.inputrc
.macos
.path
.ssh/config                # SSH config tracked; private keys NOT tracked (correct)
.starship.toml
.tmux.conf
.wgetrc
.zsh_completions
.zshrc
install.sh
install/Brewfile
macos.sh
```

### Files in $HOME but NOT in repo (these will become conflicts during stow):
All files above exist as regular files in `$HOME` (confirmed via `ls -la ~/` — none are symlinks into `~/.dotfiles`). Every one will conflict with stow unless backed up first.

### Security status:
- Private SSH keys (`id_rsa`, `id_ed25519`) exist in `~/.ssh/` but are NOT tracked in the repo (safe)
- `.extra` file is a template with comments only, no real secrets
- `.gitconfig` contains a signing key ID (`5CB8AEE431026C4C`) — this is a public key fingerprint, not a secret
- No `.gitignore` exists in the repo — this is a gap that needs addressing (to exclude `.DS_Store`, `.backup/`, `.planning/`)

---

## Standard Stack

### Core
| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| GNU Stow | 2.4.0+ (REQUIRED) | Symlink farm manager — creates/removes symlinks from package dirs into target | 2.4.0 fixes --dotfiles flag with directories; earlier versions have broken directory symlink behavior |
| Homebrew | Current (4.5.0+) | macOS package manager for CLI tools and GUI apps | The standard macOS package manager; brew bundle is now built-in (no tap needed) |
| bash/zsh | System | Install script language | POSIX-compatible; macOS ships with zsh as default |

### Supporting
| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| gitleaks | Current | Scan repo for accidentally committed secrets | Run once before restructuring, before any `git add` of file contents |
| macos-defaults.com | Reference site | Verify which `defaults write` commands work on Sequoia | Use during TOOL-04 audit to check each command's compatibility |

### Alternatives Considered (OUT OF SCOPE per requirements)
| Instead of | Could Use | Why Not |
|------------|-----------|---------|
| GNU Stow | chezmoi | Templating/secrets features not needed; Stow is simpler. Locked decision. |
| GNU Stow | Nix/Home Manager | Overkill; high complexity. Locked decision. |

---

## Architecture Patterns

### Target Repo Structure After Phase 1

```
~/.dotfiles/
├── zsh/                        # Package: all shell config
│   ├── .zshrc
│   ├── .aliases
│   ├── .functions
│   ├── .exports
│   ├── .path
│   ├── .extra
│   └── .zsh_completions
├── git/                        # Package: git config
│   ├── .gitconfig
│   └── .gitignore_global
├── tmux/                       # Package: tmux config
│   └── .tmux.conf
├── starship/                   # Package: starship prompt
│   └── .starship.toml
├── ghostty/                    # Package: Ghostty terminal
│   └── .config/
│       └── ghostty/
│           └── config
├── ssh/                        # Package: SSH config (NOT private keys)
│   └── .ssh/
│       └── config
├── misc/                       # Package: catch-all for homeless files
│   ├── .editorconfig
│   ├── .inputrc
│   ├── .curlrc
│   └── .wgetrc
├── Brewfile                    # Moved out of install/ subdir, top-level
├── install.sh                  # Replaced: now Stow-based
├── macos.sh                    # Audited: Sequoia-compatible defaults
├── .gitignore                  # NEW: exclude .DS_Store, .backup/, .planning/ outputs
└── .planning/                  # GSD planning artifacts (already present)
```

### Pattern 1: GNU Stow Package Layout

**What:** Each package directory mirrors the path structure relative to `$HOME`. Stow creates symlinks in `$HOME` pointing back into the package.

**When to use:** Always — this is the core pattern for all packages.

**Example:**
```bash
# Package: ghostty/
# File: ghostty/.config/ghostty/config
# Stow creates: ~/.config/ghostty/config -> ~/.dotfiles/ghostty/.config/ghostty/config

# Package: git/
# File: git/.gitconfig
# Stow creates: ~/.gitconfig -> ~/.dotfiles/git/.gitconfig

# Command:
stow --restow --no-folding --target="$HOME" --dir="$HOME/.dotfiles" ghostty
```

### Pattern 2: Idempotent Stow with --restow

**What:** `--restow` = unstow then stow. On first run: creates symlinks. On subsequent runs: removes old symlinks, creates fresh ones. This is idempotent — no error if already stowed.

**When to use:** Every time install.sh runs. Use `--restow` instead of `--stow` to handle pruning of obsolete symlinks after package reorganizations.

```bash
# Idempotent stow of all packages
stow_package() {
  local pkg="$1"
  echo "Stowing $pkg..."
  stow --restow --no-folding --target="$HOME" --dir="$HOME/.dotfiles" "$pkg"
  echo "  done"
}

for pkg in zsh git tmux starship ghostty ssh misc; do
  stow_package "$pkg"
done
```

### Pattern 3: Pre-Stow Conflict Backup

**What:** Before stowing a package, find any regular files (not symlinks) that would conflict and move them to `.backup/` with a timestamp. Then stow proceeds cleanly.

**Why:** Stow 2.x aborts the ENTIRE run (two-phase algorithm) if any conflict is found. It does NOT back up files itself. `--adopt` must NOT be used — it moves files into the stow dir, potentially overwriting repo contents.

```bash
backup_conflicting_files() {
  local pkg="$1"
  local backup_dir="$HOME/.backup/dotfiles_$(date +%Y%m%d_%H%M%S)"

  # Simulate stow to find conflicts
  local conflicts
  conflicts=$(stow --simulate --restow --no-folding \
    --target="$HOME" --dir="$HOME/.dotfiles" "$pkg" 2>&1 | grep "conflict")

  if [[ -n "$conflicts" ]]; then
    mkdir -p "$backup_dir"
    # For each conflicting file: move to backup, then stow proceeds
    while IFS= read -r line; do
      # Extract filepath from conflict message
      local filepath
      filepath=$(echo "$line" | grep -oP '(?<=existing target is )\S+')
      if [[ -f "$HOME/$filepath" ]] && [[ ! -L "$HOME/$filepath" ]]; then
        mv "$HOME/$filepath" "$backup_dir/"
        echo "  Backed up: ~/$filepath -> $backup_dir/"
      fi
    done <<< "$conflicts"
  fi
}
```

Note: The exact conflict message parsing depends on Stow's output format. A simpler and more reliable approach is to use `stow --simulate` output and handle files individually, OR just pre-identify and move known conflicting paths before stowing.

### Pattern 4: --no-folding for XDG Config Dirs

**What:** By default, Stow "folds" directories — if an entire directory can be symlinked, it symlinks the directory itself rather than its contents. This is BAD for `~/.config/` because: (a) other apps write into `~/.config/` and (b) a symlinked `~/.config` would point into the stow dir, contaminating the repo with other apps' configs.

**When to use:** Always use `--no-folding`. It ensures Stow creates the actual directory in `$HOME` and only symlinks individual files.

```bash
# Without --no-folding (BAD for ~/.config):
# Stow might create: ~/.config -> ~/.dotfiles/ghostty/.config (entire dir symlinked!)

# With --no-folding (CORRECT):
# Stow creates: ~/.config/ghostty/ (real directory)
#               ~/.config/ghostty/config -> ~/.dotfiles/ghostty/.config/ghostty/config
```

### Pattern 5: .stow-local-ignore for SSH Package

**What:** A `.stow-local-ignore` file inside a package directory tells Stow which files to skip when stowing. IMPORTANT: when this file exists, it OVERRIDES all default ignore patterns — you must re-add defaults (.git, etc.) you still want.

```
# ~/.dotfiles/ssh/.stow-local-ignore
# Regex patterns (not glob)
\.git
\.gitignore
README.*
id_rsa
id_rsa\.pub
id_ed25519
id_ed25519\.pub
id_ecdsa
id_ecdsa\.pub
known_hosts
known_hosts\.old
control-.*
agent
```

Note: Even though private keys are not currently tracked in the repo (good), the `.stow-local-ignore` is a safety net in case they ever end up there.

### Pattern 6: Brewfile Structure

**What:** Organized Brewfile with comment sections. Deprecated taps removed.

```ruby
# Taps (only non-default taps needed)
# NOTE: Do NOT tap homebrew/bundle, homebrew/cask, homebrew/core, homebrew/cask-fonts
# These are all deprecated as of Homebrew 4.3.0/4.5.0 and are now built-in or merged.

# CLI Tools
brew "coreutils"
brew "wget"
brew "jq"
brew "tree"
brew "fzf"
brew "ripgrep"
brew "starship"
brew "stow"              # Required for this dotfiles setup!
brew "tmux"
brew "gh"
brew "git-delta"

# Shell
brew "zsh-autosuggestions"
brew "zsh-syntax-highlighting"

# Development
brew "go"
brew "node"
brew "bun"
brew "uv"

# Apps (casks)
cask "ghostty"
cask "rectangle"
cask "maccy"
cask "gpg-suite"
cask "1password"

# Fonts (now in main cask repo, no tap needed)
cask "font-jetbrains-mono"
cask "font-fira-code"
```

### Anti-Patterns to Avoid

- **Using `stow --adopt`:** This moves existing `$HOME` files INTO the stow directory, silently overwriting repo contents with machine state. Never use as a first migration step.
- **Using `stow --stow` (not --restow) on repeated runs:** `--stow` may error if symlinks already exist in some edge cases. `--restow` is always safe.
- **Tapping deprecated Homebrew taps:** `homebrew/bundle`, `homebrew/cask`, `homebrew/cask-fonts`, `homebrew/cask-versions`, `homebrew/core` are all deprecated. Including `brew tap homebrew/bundle` in install.sh now causes warnings or errors.
- **Stowing the entire `~/.config` as a directory symlink:** Without `--no-folding`, the whole `~/.config` might get symlinked, breaking other applications that write to it.
- **Running `brew upgrade` unconditionally in install.sh:** The current `macos.sh` runs `brew upgrade` — this is slow and non-idempotent (upgrades things unrelated to dotfiles). Separate this from the stow install path.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Symlink creation and management | Custom ln -sf scripts | GNU Stow | Stow handles conflict detection, two-phase safety, package tracking |
| Package inventory from current machine | Manual brew list parsing | `brew bundle dump --describe` | Generates complete Brewfile with descriptions from current state as starting point |
| Checking if all packages installed | Custom brew list grep | `brew bundle check` | Built-in; returns exit code 0 (all installed) or 1 (missing packages) |
| Secret scanning before git add | Manual grep for API_KEY patterns | `gitleaks detect` | Handles hundreds of secret patterns; misses less than manual approaches |

**Key insight:** Stow's entire value is that it handles the symlink lifecycle correctly. Any custom symlink management code will miss edge cases (already-stowed check, conflict detection, orphan cleanup) that Stow handles natively.

---

## Common Pitfalls

### Pitfall 1: stow --adopt as Migration Step
**What goes wrong:** Running `stow --adopt` on first migration copies `$HOME` files into the stow package, overwriting repo content with machine state (silently).
**Why it happens:** Looks like a helpful "pull machine state into repo" flag, and it is — but only AFTER the package structure is correct in the repo. Using it before that corrupts the repo.
**How to avoid:** Always use the backup-then-stow pattern. Move conflicting `$HOME` files to `.backup/` first, then stow.
**Warning signs:** If you see the repo files' contents changed after stowing, you used `--adopt` accidentally.

### Pitfall 2: GNU Stow Version < 2.4.0
**What goes wrong:** The `--dotfiles` flag does NOT work with directories in Stow < 2.4.0. Using `dot-config/` prefix for XDG dirs fails silently or with confusing errors.
**Why it happens:** Known bug fixed in 2.4.0 (May 2024). Many systems (and older Homebrew formulas) ship with 2.3.x.
**How to avoid:** Install Stow via Homebrew (formula is current); verify with `stow --version` and fail-fast in install.sh if version < 2.4.0. Alternatively, avoid `--dotfiles` flag entirely and use the explicit path mirror layout (preferred approach — no dot-prefix needed).
**Warning signs:** `stow: ERROR: dot-config is not a valid package name` or symlinks not created for directories.

**Note on project approach:** The CONTEXT.md decisions use explicit path mirroring (e.g., `ghostty/.config/ghostty/config`) rather than `dot-` prefix naming. This means `--dotfiles` flag is NOT needed and the 2.4.0 requirement is about general correctness/stability, not the `--dotfiles` bug specifically.

### Pitfall 3: Deprecated Homebrew Taps in Brewfile
**What goes wrong:** The existing `install/Brewfile` taps `homebrew/bundle`, `homebrew/cask`, `homebrew/cask-fonts`, `homebrew/cask-versions`, and `homebrew/core` — all deprecated. Running `brew bundle install` with these taps now produces errors or warnings that interrupt the install.
**Why it happens:** These taps were standard practice before Homebrew 4.3.0 (May 2024). The old `macos.sh` also explicitly runs `brew tap homebrew/bundle` which is now an error.
**How to avoid:** Remove all deprecated tap lines from the new Brewfile. Do not call `brew tap homebrew/bundle` in install.sh.
**Warning signs:** `Error: homebrew/bundle was deprecated. This tap is now empty as all its formulae were migrated.`

### Pitfall 4: Brewfile Drift from Machine State
**What goes wrong:** The current `install/Brewfile` lists tools not installed (`exa`, `bat`, `fd`, `kubectl`, `kubectx`, `wireshark`, `nmap`, `pre-commit`, `git-lfs`, `httpie`, `unar`, `openssl`, `python`) and is missing many that are installed (`bun`, `go`, `hugo`, `starship`, `tmux`, `ripgrep`, `thefuck`, `opencode`, `1password`, `discord`, `spotify`, `nordvpn`, `google-chrome`, `ghostty`, `signal`).
**Why it happens:** Brewfile was never kept in sync with actual installs.
**How to avoid:** Use `brew bundle dump --describe --global` to generate a fresh starting Brewfile from current state, then collaboratively trim/organize with user as specified in decisions.
**Warning signs:** `brew bundle check` fails on packages that are supposed to be "installed by default."

### Pitfall 5: .macos Script References macOS Tahoe (26.0 Beta)
**What goes wrong:** The current `.macos` script (at `~/.macos`, which is tracked in the repo) contains lines referencing "macOS Tahoe 26.0 Beta" features (`WindowManager`, `LiveActivities`). This is from a future/beta macOS, not Sequoia. Running this on Sequoia may silently do nothing or may set wrong preferences.
**Why it happens:** The script appears to have been modified with AI-generated content that references a future macOS version.
**How to avoid:** Strip all Tahoe-specific comments/blocks during the Sequoia audit. Focus on what macos-defaults.com confirms works on macOS 15 (Sequoia).
**Warning signs:** Comments saying "macOS Tahoe 26.0 Beta" or "Enable Stage Manager (new in Tahoe)" in the script.

### Pitfall 6: No .gitignore in Repo
**What goes wrong:** Without a `.gitignore`, `git add .` or `git status` will surface `.DS_Store`, `.backup/`, `.planning/` output files (if generated in working dir), and stow-generated artifacts.
**Why it happens:** Not present in the current repo.
**How to avoid:** Add a `.gitignore` as part of the restructuring (Plan 01-01).

### Pitfall 7: install.sh Source Path Assumption
**What goes wrong:** The current `install.sh` uses `cd "$(dirname "${BASH_SOURCE}")"` which works when run directly but breaks when run as a symlink (BASH_SOURCE follows the symlink, `dirname` points to the stow package dir, not `~/.dotfiles`).
**Why it happens:** The script will be stowed, making `~/install.sh` a symlink. `dirname "${BASH_SOURCE}"` on a symlink resolves to the symlink target dir (which is actually correct here — it resolves to `~/.dotfiles/`). But using `${BASH_SOURCE}` with `/bin/sh` shebang doesn't work — `BASH_SOURCE` is bash-only. Current shebang is `#!/bin/sh`.
**How to avoid:** Rewrite install.sh with `#!/usr/bin/env bash` (not `/bin/sh`) and use `DOTFILES="$HOME/.dotfiles"` as a fixed constant rather than deriving from BASH_SOURCE. The dotfiles dir location is a known constant.

---

## Code Examples

### Install Script Skeleton

```bash
#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$HOME/.dotfiles"
BACKUP_DIR="$HOME/.backup/dotfiles_$(date +%Y%m%d_%H%M%S)"
PACKAGES=(zsh git tmux starship ghostty ssh misc)

# ── Helpers ──────────────────────────────────────────────────────────────────

log()  { echo "  $1"; }
ok()   { echo "  [ok] $1"; }
info() { echo ""; echo "==> $1"; }
fail() { echo "  [fail] $1" >&2; exit 1; }

require_stow() {
  if ! command -v stow &>/dev/null; then
    fail "GNU Stow not found. Install with: brew install stow"
  fi
  # Verify version >= 2.4.0
  local ver
  ver=$(stow --version 2>&1 | grep -oE '[0-9]+\.[0-9]+\.[0-9]+' | head -1)
  log "GNU Stow version: $ver"
}

backup_and_remove_conflict() {
  local target="$1"
  if [[ -e "$target" ]] && [[ ! -L "$target" ]]; then
    mkdir -p "$BACKUP_DIR"
    mv "$target" "$BACKUP_DIR/"
    log "Backed up: $target"
  fi
}

stow_package() {
  local pkg="$1"
  info "Stowing $pkg..."

  # Pre-check: find conflicts and back them up
  # (Manual conflict identification per package — more reliable than parsing stow output)
  find "$DOTFILES/$pkg" -type f | while read -r src; do
    local rel="${src#$DOTFILES/$pkg/}"
    local target="$HOME/$rel"
    backup_and_remove_conflict "$target"
  done

  stow --restow --no-folding \
    --target="$HOME" \
    --dir="$DOTFILES" \
    "$pkg"
  ok "$pkg"
}

install_homebrew() {
  if ! command -v brew &>/dev/null; then
    info "Installing Homebrew..."
    /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
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

run_brew_bundle() {
  info "Installing packages from Brewfile..."
  brew bundle install --file="$DOTFILES/Brewfile" --no-lock
  ok "Brew bundle complete"
}

# ── Main ─────────────────────────────────────────────────────────────────────

main() {
  echo ""
  echo "Dotfiles installer"
  echo "=================="

  if [[ "${1:-}" != "--force" ]] && [[ "${1:-}" != "-f" ]]; then
    read -rp "This will stow dotfiles into $HOME. Continue? (y/N) " reply
    [[ "$reply" =~ ^[Yy]$ ]] || { echo "Aborted."; exit 0; }
  fi

  install_homebrew
  require_stow
  run_brew_bundle

  for pkg in "${PACKAGES[@]}"; do
    stow_package "$pkg"
  done

  echo ""
  echo "Done! Restart your shell or run: source ~/.zshrc"
}

main "$@"
```

### brew bundle check (Success Criteria Verification)

```bash
# Verifies PKGS-01 success criterion: "Running brew bundle check passes with no missing packages"
brew bundle check --file="$HOME/.dotfiles/Brewfile"
# Exit 0 = all installed
# Exit 1 = missing packages (outputs which ones)
```

### Generating Fresh Brewfile from Current Machine State

```bash
# Starting point for PKGS-01 work — generates Brewfile from current installs
brew bundle dump --describe --file=/tmp/Brewfile.current
# Then compare with existing install/Brewfile and curate with user
```

### Verifying Symlinks After Stow (FOUND-01 Success Criterion)

```bash
# Verifies: "Running ls -la ~ shows dotfile targets as symlinks pointing into ~/.dotfiles/"
ls -la ~ | grep "\->" | grep ".dotfiles"
# Expected output: lines like:
# .zshrc -> .dotfiles/zsh/.zshrc
# .gitconfig -> .dotfiles/git/.gitconfig
# .tmux.conf -> .dotfiles/tmux/.tmux.conf
```

### Idempotency Test (FOUND-03 Success Criterion)

```bash
# Run install.sh twice — second run must be error-free
./install.sh --force && echo "First run: OK"
./install.sh --force && echo "Second run: OK (idempotent)"
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|-----------------|--------------|--------|
| `brew tap homebrew/bundle` + bundle as external tap | `brew bundle` is built-in | Homebrew 4.5.0 (April 2025) | Remove tap line from Brewfile and install scripts |
| `brew tap homebrew/cask-fonts` for font casks | Font casks in main `homebrew/cask` | May 2024 | Fonts like `font-jetbrains-mono` install directly without tap |
| `brew tap homebrew/cask` | No tap needed for casks | Deprecated with Homebrew 3.x→4.x | Remove tap line |
| `stow --dotfiles` broken with directories | Fixed in Stow 2.4.0 | May 2024 | Can now use `dot-config/` directory names if desired; explicit path mirroring is still fine |
| GNU Stow 2.3.x | GNU Stow 2.4.0+ | May 2024 | Install from Homebrew for current version |
| rsync-based dotfiles (copy files) | Stow-based (symlinks) | Phase 1 | Edits in $HOME flow back to repo automatically |

**Deprecated/outdated in current repo:**
- `brew tap homebrew/bundle` in macos.sh: deprecated, causes errors
- `brew tap homebrew/cask`, `homebrew/cask-fonts`, `homebrew/cask-versions`, `homebrew/core` in Brewfile: all deprecated
- `brew "exa"` in Brewfile: `exa` is abandoned (last release 2022), community has moved to `eza`
- `brew 'mac-mouse-fix'` listed as brew but `mac-mouse-fix` is a cask, not a formula
- `.macos` script references "macOS Tahoe 26.0 Beta" features: wrong macOS version entirely
- `System Preferences` in osascript call: renamed to `System Settings` in macOS Ventura+

---

## Recommendation: misc/ Package for Homeless Files

Per Claude's Discretion, the following files have no natural per-tool package:

| File | Recommendation | Rationale |
|------|---------------|-----------|
| `.editorconfig` | misc/ | Editor-agnostic project config, not tied to one tool |
| `.inputrc` | misc/ | GNU Readline config, used by bash/python/etc |
| `.curlrc` | misc/ | curl defaults |
| `.wgetrc` | misc/ | wget defaults |

A `misc/` package keeps the repo clean without creating single-file packages for each. The `misc/` name is conventional and self-explanatory.

---

## Open Questions

1. **Where does Brewfile live — top-level or in install/ subdir?**
   - What we know: Currently in `install/Brewfile`. CONTEXT.md says "Organize Brewfile into sections" but doesn't specify location.
   - What's unclear: `brew bundle` defaults to `$PWD/Brewfile`. Top-level placement is more conventional and easier to reference.
   - Recommendation: Move to top-level `~/.dotfiles/Brewfile`. Reference in install.sh as `--file="$DOTFILES/Brewfile"`.

2. **Should install.sh itself be stowed (symlinked to $HOME/install.sh) or stay in the repo root only?**
   - What we know: The script needs to be discoverable. Current convention is it's in the repo root.
   - What's unclear: Stowing it creates `~/install.sh`. That's non-standard placement in $HOME.
   - Recommendation: Do NOT stow install.sh. It lives at `~/.dotfiles/install.sh` and is run directly from there. No symlink needed.

3. **Should macos.sh be run as part of the PKGS-02 integration or remain fully separate?**
   - What we know: CONTEXT.md explicitly says macos.sh is SEPARATE from install.sh.
   - What's unclear: The success criterion says "brew bundle check passes" — brew bundle runs in install.sh, not macos.sh.
   - Recommendation: Keep separation. install.sh handles stow + brew bundle. macos.sh is a standalone script for macOS preferences only.

4. **exa vs eza in Brewfile?**
   - What we know: Current Brewfile has `brew "exa"`. `exa` is abandoned (no releases since 2022). The active fork is `eza`.
   - Recommendation: Replace `exa` with `eza` in the new Brewfile. (This is a v2 requirement QOL-01 technically, but the Brewfile curation is Phase 1 scope.)

---

## Sources

### Primary (HIGH confidence)
- GNU Stow official manual (https://www.gnu.org/software/stow/manual/stow.html) — package layout, --restow, --no-folding, conflict detection, .stow-local-ignore
- GNU Stow 2.4.0 release announcement (https://www.mail-archive.com/info-gnu@gnu.org/msg03275.html) — confirmed directory bug fix
- GitHub Issue: aspiers/stow #33 — "Dotfiles option doesn't work with directories" — confirmed fixed in 2.4.0
- Homebrew official docs (https://docs.brew.sh/Brew-Bundle-and-Brewfile) — brew bundle install/check behavior
- Homebrew 4.5.0 release notes (https://brew.sh/2025/04/29/homebrew-4.5.0/) — bundle built-in confirmation
- Current repo state (git ls-files, ls -la ~/) — confirmed actual file inventory

### Secondary (MEDIUM confidence)
- Homebrew deprecation discussion #6213 (https://github.com/orgs/Homebrew/discussions/6213) — tap deprecation status
- homebrew/cask-fonts deprecation (multiple issues + SketchyBar #580) — confirmed all fonts moved to main cask
- macos-defaults.com — Sequoia compatibility reference for defaults write commands (confirmed active, Sequoia-tested)
- GNU Stow --no-folding community docs (System Crafters, tamerlan.dev) — confirmed XDG directory protection pattern

### Tertiary (LOW confidence — flag for validation)
- macOS Sequoia specific defaults write compatibility: general consensus is most Finder/Dock/Keyboard defaults still work, but no exhaustive verified list found. The existing `.macos` script should be tested command-by-command against a Sequoia machine (which this IS — Darwin 25.4.0 = macOS 15.x).
- Stow --restow idempotency on already-stowed packages: documented behavior says it unstows then restows; confirmed no error on clean second run per community usage patterns, but not explicitly tested here.

---

## Metadata

**Confidence breakdown:**
- Standard stack (GNU Stow, Homebrew): HIGH — official docs, confirmed version requirements
- Package structure: HIGH — derived from locked decisions + official Stow layout docs
- Brewfile deprecated taps: HIGH — confirmed in official Homebrew docs and release notes
- Conflict/backup pattern: HIGH — confirmed from Stow's two-phase conflict algorithm docs
- macOS defaults Sequoia compatibility: MEDIUM — general confirmation defaults mechanism works; specific commands need per-command validation
- Tahoe references in .macos: HIGH (confident they're wrong — .macos was clearly AI-generated with future macOS references)

**Research date:** 2026-02-28
**Valid until:** 2026-03-30 (stable tools; Homebrew deprecation state is settled)
