# Phase 3: Cross-Platform - Research

**Researched:** 2026-02-28
**Domain:** Shell scripting, platform detection, Linux tool installation, devcontainer integration
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Linux scope**
- Target environments: Cursor devcontainers AND remote Linux servers (no Linux desktop)
- No Homebrew/Linuxbrew on Linux — Brewfile is macOS-only
- UI/GUI tooling is macOS-only; Linux gets only shell/CLI config
- Work without sudo when possible — use sudo when available, fall back to user-local installs when not
- zsh required — install via apt if missing; if can't install (no sudo), stow git config and exit gracefully

**Package partitioning**
- Stow ALL packages on both platforms — config files are lightweight, tools degrade gracefully if binary isn't installed
- One Brewfile, macOS-only — no split, no Linuxbrew
- Antidote on Linux: Claude's discretion (git clone to ~/.antidote or similar — no Homebrew path available)
- zsh only, install if missing — no bash fallback

**macOS guard strategy**
- Silent skip — macOS-only aliases/functions simply don't get defined on Linux (no errors, no warnings)
- Platform block pattern — one `if [[ $(uname) == Darwin ]]; then ... fi` wrapping all macOS-specific aliases, not per-command checks
- Guard .functions too — macOS-specific functions (pbcopy, open, Finder) wrapped in platform checks; cross-platform functions stay global
- Platform-aware antidote path in .zshrc — macOS uses `brew --prefix` path, Linux uses `~/.antidote` or equivalent

### Claude's Discretion
- Whether to install starship/fzf via apt/curl on Linux for a full shell experience, or let them degrade gracefully
- Antidote installation method on Linux (git clone path, update mechanism)
- Exact platform detection approach in install.sh (uname vs /etc/os-release vs both)
- How to handle the Homebrew fpath block in .zshrc on Linux (skip vs alternative)

### Deferred Ideas (OUT OF SCOPE)
None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PLAT-01 | Install script detects platform (macOS vs Linux) and branches accordingly | `uname -s` returns `Darwin` on macOS, `Linux` on Linux; use at top of install.sh to set `IS_MACOS`/`IS_LINUX` flags and branch all platform-specific functions |
| PLAT-02 | Linux install path: installs stow + stows shell and git packages only | On Linux with sudo: `apt-get install -y stow`; without sudo: compile from source or fall back; stow all packages (config is lightweight, binaries degrade gracefully) |
| PLAT-03 | `command -v` guards on macOS-specific aliases and functions | Wrap macOS-specific aliases/functions in `if [[ $(uname -s) == Darwin ]]; then ... fi` platform block in .aliases and .functions |
| PLAT-04 | install.sh compatible with Cursor devcontainers and GitHub Codespaces auto-dotfiles | GitHub Codespaces looks for `install.sh` first (executable); Cursor uses `dotfiles.installCommand` setting; both clone repo and run from cloned dir; DOTFILES constant must use `$HOME/.dotfiles`, not BASH_SOURCE |
</phase_requirements>

## Summary

Phase 3 requires splitting one install.sh into a macOS path and a Linux path using `uname -s` detection, then guarding all macOS-specific shell configuration (aliases, functions, .zshrc blocks) with platform checks. The existing architecture is solid for this: `install_homebrew()`, `run_brew_bundle()`, and the full PACKAGES list are the macOS-only concerns; GNU Stow + shell config stowing is the Linux-compatible path.

The main complexity is in .zshrc, which currently hard-codes two Homebrew paths for antidote: one for `fpath` additions (`$(brew --prefix)/share/zsh/site-functions`) and one for the antidote fpath (`$(brew --prefix)/opt/antidote/share/antidote/functions`). On Linux, antidote is installed via `git clone --depth=1 https://github.com/mattmc3/antidote.git ~/.antidote` and sourced from `~/.antidote/antidote.zsh`. Both paths need platform branching in .zshrc.

For devcontainers, GitHub Codespaces looks for an executable `install.sh` in the repo root and runs it from the cloned directory (`~/dotfiles` by default, or the target path configured in settings). The existing DOTFILES constant pattern (`DOTFILES="$HOME/.dotfiles"`) is correct for both — it assumes the repo is always at `~/.dotfiles`. A `--force` / `-f` flag already exists to skip the interactive prompt, which devcontainer automation requires.

**Primary recommendation:** Add a `detect_platform()` function at the top of install.sh that sets `IS_MACOS` and `IS_LINUX` flags; gate all macOS functions behind `$IS_MACOS`; add a `linux_setup()` function that installs stow (with/without sudo) and antidote via git clone; make .zshrc antidote block platform-aware using the same `$(uname -s)` check.

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| `uname -s` | POSIX | Platform detection in bash/zsh | Universally available, returns `Darwin` / `Linux`; no external deps |
| GNU Stow | 2.x (apt) | Dotfile symlinking on Linux | Already used on macOS; available in all major Linux distros via apt |
| antidote | latest (git clone) | Zsh plugin manager on Linux | Chosen for this project; git clone is the official non-Homebrew install method |
| apt-get | system | Package installation on Debian/Ubuntu | Standard in Cursor devcontainers and most Linux servers |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| Starship (curl install) | latest | Prompt on Linux | Install via `curl -sS https://starship.rs/install.sh \| sh -s -- -b ~/.local/bin -y` when sudo unavailable |
| fzf (git clone) | latest | Fuzzy finder on Linux | `git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install` |
| `command -v` | POSIX | Guard binary presence in aliases | Already used in project (.aliases line 85); extend this pattern |
| `/usr/bin/uname` | POSIX | Hardcoded path for reliability | Use `/usr/bin/uname` not bare `uname` in install.sh to avoid PATH issues |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| `uname -s` | `$OSTYPE` | `$OSTYPE` is zsh/bash-only, not available in all POSIX shells; `uname -s` works everywhere |
| `uname -s` | `/etc/os-release` | `/etc/os-release` is Linux-only and gives distro detail; not useful for macOS/Linux branching |
| apt-get (stow) | compile from source | Compilation is fragile and slow; apt-get works in all target containers |
| git clone (antidote) | Linuxbrew | User explicitly rejected Linuxbrew; git clone is officially supported |

## Architecture Patterns

### Recommended Project Structure

No new directories needed. Changes are to existing files:

```
install.sh           # Add detect_platform(), gate functions by IS_MACOS/IS_LINUX
zsh/.zshrc           # Make antidote block platform-aware
zsh/.aliases         # Wrap macOS block in Darwin guard
zsh/.functions       # Wrap macOS-specific functions in Darwin guard
```

### Pattern 1: Platform Detection in install.sh

**What:** Set boolean flags at script start; gate all macOS functions with `$IS_MACOS` check.
**When to use:** Anytime install.sh needs to branch on platform — Homebrew install, brew bundle, stow package list, antidote install.

```bash
# ── Platform Detection ─────────────────────────────────────────────────────────
PLATFORM="$(/usr/bin/uname -s)"
IS_MACOS=false
IS_LINUX=false

case "$PLATFORM" in
  Darwin) IS_MACOS=true ;;
  Linux)  IS_LINUX=true ;;
  *)      fail "Unsupported platform: $PLATFORM" ;;
esac
```

Then wrap macOS-only functions:

```bash
main() {
  if $IS_MACOS; then
    install_homebrew
    require_stow
    run_brew_bundle
  elif $IS_LINUX; then
    linux_require_zsh
    linux_require_stow
    linux_install_antidote
  fi
  stow_packages
}
```

### Pattern 2: Linux Stow Installation

**What:** Try `sudo apt-get install stow`, fall back to user-local if no sudo.
**When to use:** `linux_require_stow()` function in install.sh.

```bash
linux_require_stow() {
  info "Checking GNU Stow (Linux)..."
  if command -v stow &>/dev/null; then
    ok "GNU Stow already installed"
    return 0
  fi
  if command -v sudo &>/dev/null && sudo -n apt-get install -y stow &>/dev/null 2>&1; then
    ok "GNU Stow installed via apt"
  elif command -v apt-get &>/dev/null; then
    log "Trying apt-get with sudo prompt..."
    sudo apt-get install -y stow || fail "Cannot install GNU Stow — install manually"
  else
    fail "GNU Stow not found and apt-get unavailable. Install manually."
  fi
}
```

Note: Cursor devcontainers typically run as root — `sudo` may not be needed at all. Remote servers typically have sudo. The `command -v sudo && sudo -n` pattern handles the no-sudo case gracefully.

### Pattern 3: Antidote on Linux (git clone)

**What:** Clone antidote to `~/.antidote`; skip if already present.
**When to use:** `linux_install_antidote()` in install.sh.

```bash
linux_install_antidote() {
  info "Checking antidote (Linux)..."
  if [[ -d "$HOME/.antidote" ]]; then
    ok "antidote already installed at ~/.antidote"
    return 0
  fi
  if ! command -v git &>/dev/null; then
    fail "git is required to install antidote"
  fi
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
  ok "antidote installed at ~/.antidote"
}
```

### Pattern 4: Platform-Aware .zshrc Antidote Block

**What:** Two separate antidote source paths depending on platform.
**When to use:** Replace the current hard-coded `brew --prefix` antidote block in .zshrc.

```zsh
# ── 7. antidote plugin bootstrap ──────────────────────────────────────────────
zsh_plugins=${ZDOTDIR:-~}/.zsh_plugins
[[ -f ${zsh_plugins}.txt ]] || touch ${zsh_plugins}.txt

if [[ $(uname -s) == Darwin ]]; then
  # macOS: antidote installed via Homebrew
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
  fpath=("$(brew --prefix)/opt/antidote/share/antidote/functions" $fpath)
else
  # Linux: antidote installed via git clone
  fpath=("$HOME/.antidote" $fpath)
  source "$HOME/.antidote/antidote.zsh"
fi

autoload -Uz antidote
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  antidote bundle <${zsh_plugins}.txt >|${zsh_plugins}.zsh
fi
source ${zsh_plugins}.zsh
```

Note: The `autoload -Uz antidote` line must come AFTER both fpath branches so antidote is loadable in either case.

### Pattern 5: macOS Block in .aliases

**What:** Single `if [[ $(uname -s) == Darwin ]]; then ... fi` wrapping all macOS-specific aliases.
**When to use:** Wrap the following aliases in .aliases that currently have no guard:
- `showfiles`, `hidefiles`, `showpath`, `hidepath` (Finder/defaults)
- `localip` (uses `ipconfig getifaddr`)
- `ips` (uses BSD `ifconfig` + `pcregrep`)
- `ifactive` (uses `pcregrep`)
- `flush` (uses `dscacheutil` + `mDNSResponder`)
- `lscleanup` (uses macOS LaunchServices registry path)
- `c` (uses `pbcopy`)
- `emptytrash` (uses macOS-specific paths)
- `update` (uses `brew`)

Cross-platform aliases that stay OUTSIDE the block: `..`, `...`, `g`, `dc`, `dcu`, `dcd`, `weather`, `myip`, `ports`, `l`, `ll`, `la`, `lsd`, `ls`, `grep`, `sudo`, `week`, `ip`, `cleanup`, `urlencode`, `map`, `reload`, `path`.

```zsh
# ── macOS-only aliases ────────────────────────────────────────────────────────
if [[ $(uname -s) == Darwin ]]; then
  alias showfiles="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"
  # ... rest of macOS aliases ...
fi
```

### Pattern 6: macOS Block in .functions

**What:** Wrap macOS-specific functions in a Darwin guard.
**When to use:** Identify functions that call macOS-only binaries:
- `cdf()` — calls `osascript` (macOS-only)
- `sysinfo()` — calls `sw_vers`, `vm_stat` (macOS-only)
- `o()` — already has partial cross-platform guard (has a Linux branch for `xdg-open`, extend it)

Functions that are cross-platform and need NO guard: `mkd`, `targz`, `fs`, `diff`, `dataurl`, `gz`, `digga`, `getcertnames`, `devserver`, `gitinit`, `dockerclean`, `portcheck`, `backup`, `tre`.

Note: `targz()` already uses `stat -f"%z"` (macOS) + `stat -c"%s"` (Linux) — this is the right cross-platform pattern.

### Anti-Patterns to Avoid

- **Checking `$OSTYPE` instead of `uname -s`:** `$OSTYPE` is a shell variable (zsh/bash only) — not available in the bare bash during install.sh. Use `/usr/bin/uname -s` in install.sh, `$(uname -s)` in .zshrc/.aliases/.functions (zsh-sourced).
- **Per-alias command guards for macOS binaries:** The decision is a single platform block, not per-command `command -v` guards. Only use `command -v` for tools that might be optionally installed on BOTH platforms (e.g., `fzf`, `starship`).
- **Hardcoding `~/dotfiles` as DOTFILES path:** GitHub Codespaces clones to `~/dotfiles` by default but users can configure it. The project decision is `~/.dotfiles` — install.sh must use `DOTFILES="$HOME/.dotfiles"` and devcontainer config must target the same path.
- **Forgetting `--force` on devcontainer runs:** The interactive confirmation prompt (`read -rp`) will hang in non-interactive devcontainer execution. The existing `--force`/`-f` flag handles this — Cursor/Codespaces config must pass it.
- **Using `brew --prefix` without checking for brew:** The current .zshrc line 44 already checks `if type brew &>/dev/null` for the Homebrew fpath block. The antidote block at line 53 does NOT check — this is the bug to fix.

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Antidote update on Linux | Custom git pull wrapper | `git -C ~/.antidote pull` | One-liner; same git operations that work anywhere |
| Starship on Linux | Manual binary management | Official install script with `-b ~/.local/bin -y` flags | Handles arch detection, binary placement, verification |
| fzf on Linux | Custom fzf integration | `git clone && ~/.fzf/install --no-bash --no-fish` | Official installer wires shell integration correctly |
| Platform-specific PATH | Separate .path files per OS | Single .path with `if [[ "$OSTYPE" == "darwin"* ]]` guards | .path already uses this pattern for Homebrew — extend it |

**Key insight:** The project already has the right instincts (see existing `if [[ "$OSTYPE" == "darwin"* ]]` in .path). Phase 3 applies this same pattern consistently to install.sh, .aliases, .functions, and .zshrc.

## Common Pitfalls

### Pitfall 1: Antidote fpath without Homebrew check

**What goes wrong:** Current .zshrc line 53 adds `$(brew --prefix)/opt/antidote/share/antidote/functions` to fpath unconditionally. On Linux, `brew` is not found, `$(brew --prefix)` expands to empty/error, and the fpath entry becomes invalid, causing `autoload -Uz antidote` to fail silently (or with error if brew exits non-zero).

**Why it happens:** The Homebrew fpath block at line 44 has a `type brew &>/dev/null` guard, but the antidote fpath at line 53 does not.

**How to avoid:** Replace the antidote block with a platform-conditional that sources either the Homebrew path (macOS) or `~/.antidote/antidote.zsh` (Linux).

**Warning signs:** `command not found: antidote` on Linux even after `linux_install_antidote` ran successfully.

### Pitfall 2: Homebrew Fpath Block on Linux

**What goes wrong:** Line 44 of .zshrc: `if type brew &>/dev/null; then fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath); fi` — the guard is correct, but on Linux `type brew` returns false so the Homebrew completions fpath is simply skipped. This is correct behavior BUT Homebrew completions fpath is where some macOS-only completions (gh, etc.) live. On Linux those completions come from antidote plugins instead.

**Why it happens:** Not a bug, just needs documenting — the guard already works.

**How to avoid:** No action needed. Document that Linux uses antidote plugins for completions, not Homebrew fpath.

### Pitfall 3: install.sh DOTFILES constant mismatch with devcontainer clone target

**What goes wrong:** GitHub Codespaces default clone target is `~/dotfiles`. If Cursor/Codespaces settings specify `dotfiles.targetPath: ~/dotfiles` but install.sh uses `DOTFILES="$HOME/.dotfiles"`, stow will look for packages in the wrong place and fail silently (packages not found, nothing stowed).

**Why it happens:** The constant and the clone target must match.

**How to avoid:** Either (a) configure devcontainer settings to `dotfiles.targetPath: ~/.dotfiles` (recommended — matches existing constant) or (b) make DOTFILES dynamic using `SCRIPT_DIR` detection. Option (a) is simpler. The existing DOTFILES constant is `$HOME/.dotfiles` — just ensure Cursor/Codespaces config clones to that path.

**Warning signs:** `stow_package` skips all packages with "Package directory not found — skipping" messages.

### Pitfall 4: Interactive prompt hangs in devcontainer

**What goes wrong:** install.sh currently prompts `read -rp "... Continue? (y/N)"` when no `--force` flag is passed. In a devcontainer, stdin is non-interactive and the prompt blocks forever (or times out and aborts).

**Why it happens:** The `--force`/`-f` flag already exists to skip this prompt (lines 119-122) but Cursor/Codespaces config must explicitly pass it.

**How to avoid:** Document in devcontainer settings: `dotfiles.installCommand: install.sh --force`.

**Warning signs:** Devcontainer setup hangs silently after cloning dotfiles repo.

### Pitfall 5: `pbcopy` alias error on Linux

**What goes wrong:** The alias `c="tr -d '\n' | pbcopy"` (line 94 of .aliases) references `pbcopy`, which is macOS-only. On Linux, sourcing .aliases will not immediately error (alias definitions don't execute), but running `c` will produce `command not found: pbcopy`.

**Why it happens:** `pbcopy` is in a macOS-only alias that has no guard.

**How to avoid:** Move `c` alias inside the Darwin platform block (or simply omit it on Linux — no Linux equivalent is needed since user doesn't use Linux GUI).

**Warning signs:** Running `echo test | c` on Linux produces `pbcopy: command not found`.

### Pitfall 6: `update` alias on Linux

**What goes wrong:** The alias `update='brew update && brew upgrade && brew cleanup'` calls `brew` directly. On Linux, `brew` is not found and running `update` will fail with `command not found: brew`.

**Why it happens:** The alias is unconditional.

**How to avoid:** Move `update` inside the Darwin block, or replace with platform-aware version (Linux: `sudo apt-get update && sudo apt-get upgrade -y`). Given macOS focus, simpler to wrap in Darwin block only.

### Pitfall 7: `sysinfo()` function on Linux

**What goes wrong:** `sysinfo()` calls `sw_vers` and `vm_stat` (macOS-only binaries). On Linux, calling `sysinfo` will error.

**Why it happens:** The function is defined unconditionally in .functions.

**How to avoid:** Wrap `sysinfo()` in a Darwin guard. Cross-platform alternative is not needed since user uses Linux only for servers/containers.

### Pitfall 8: fzf shell integration version sensitivity

**What goes wrong:** The current .zshrc uses `source <(fzf --zsh)` (line 74). The `--zsh` flag was added in fzf 0.48.0. Older Linux distros ship fzf 0.44.x or earlier via apt (e.g., Ubuntu 22.04 ships 0.29). On those systems, `fzf --zsh` is an unknown flag and will error.

**Why it happens:** `fzf --zsh` is a relatively new API.

**How to avoid:** For Linux, either install fzf via git clone (gets latest) or add a version check. Since the existing `.zshrc` already guards with `command -v fzf &>/dev/null`, the only risk is if an old fzf is already installed system-wide. Recommendation: install fzf on Linux via git clone to `~/.fzf` to ensure version ≥ 0.48.0.

## Code Examples

Verified patterns from official sources and current codebase:

### Platform Detection Block (install.sh)

```bash
# Source: POSIX uname standard; pattern recommended by bash community
PLATFORM="$(/usr/bin/uname -s)"
IS_MACOS=false
IS_LINUX=false
case "$PLATFORM" in
  Darwin) IS_MACOS=true ;;
  Linux)  IS_LINUX=true ;;
  *)      fail "Unsupported platform: $PLATFORM" ;;
esac
```

### Linux zsh Install (install.sh)

```bash
linux_require_zsh() {
  info "Checking zsh (Linux)..."
  if command -v zsh &>/dev/null; then
    ok "zsh already installed: $(zsh --version)"
    return 0
  fi
  if command -v apt-get &>/dev/null; then
    log "Installing zsh via apt-get..."
    # Try with sudo if available; devcontainer root users don't need it
    if [[ "$(id -u)" -eq 0 ]]; then
      apt-get install -y zsh
    elif command -v sudo &>/dev/null; then
      sudo apt-get install -y zsh
    else
      log "No sudo access — stowing git config only, skipping shell setup"
      stow_package git
      exit 0
    fi
    ok "zsh installed"
  else
    fail "Cannot install zsh — apt-get not available and zsh not found"
  fi
}
```

### Antidote Git Clone (install.sh)

```bash
# Source: https://antidote.sh/install (official docs)
linux_install_antidote() {
  info "Checking antidote (Linux)..."
  if [[ -d "$HOME/.antidote" ]]; then
    ok "antidote already at ~/.antidote"
    return 0
  fi
  git clone --depth=1 https://github.com/mattmc3/antidote.git "$HOME/.antidote"
  ok "antidote installed at ~/.antidote"
}
```

### Antidote Update on Linux

```bash
# In future bin/dot update command (Phase 4 concern)
git -C "$HOME/.antidote" pull
```

### Platform-Aware Antidote Block (.zshrc)

```zsh
# ── 7. antidote plugin bootstrap ──────────────────────────────────────────────
zsh_plugins=${ZDOTDIR:-~}/.zsh_plugins
[[ -f ${zsh_plugins}.txt ]] || touch ${zsh_plugins}.txt

if [[ $(uname -s) == Darwin ]]; then
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
  fpath=("$(brew --prefix)/opt/antidote/share/antidote/functions" $fpath)
else
  source "$HOME/.antidote/antidote.zsh"
fi

autoload -Uz antidote
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  antidote bundle <${zsh_plugins}.txt >|${zsh_plugins}.zsh
fi
source ${zsh_plugins}.zsh
```

### macOS Alias Guard (.aliases)

```zsh
# ── macOS-only aliases ────────────────────────────────────────────────────────
if [[ $(uname -s) == Darwin ]]; then
  alias showfiles="defaults write com.apple.finder AppleShowAllFiles YES; killall Finder"
  alias hidefiles="defaults write com.apple.finder AppleShowAllFiles NO; killall Finder"
  alias showpath="defaults write com.apple.finder _FXShowPosixPathInTitle -bool true; killall Finder"
  alias hidepath="defaults write com.apple.finder _FXShowPosixPathInTitle -bool false; killall Finder"
  alias localip="ipconfig getifaddr en0"
  alias ips="ifconfig -a | grep -o 'inet6\? \(addr:\)\?\s\?\(\(\([0-9]\+\.\)\{3\}[0-9]\+\)\|[a-fA-F0-9:]\+\)' | awk '{ sub(/inet6? (addr:)? ?/, \"\"); print }'"
  alias ifactive="ifconfig | pcregrep -M -o '^[^\t:]+:([^\n]|\n\t)*status: active'"
  alias flush="dscacheutil -flushcache && killall -HUP mDNSResponder"
  alias lscleanup="/System/Library/Frameworks/CoreServices.framework/Frameworks/LaunchServices.framework/Support/lsregister -kill -r -domain local -domain system -domain user && killall Finder"
  alias c="tr -d '\n' | pbcopy"
  alias emptytrash="sudo rm -rfv /Volumes/*/.Trashes; sudo rm -rfv ~/.Trash; sudo rm -rfv /private/var/log/asl/*.asl; sqlite3 ~/Library/Preferences/com.apple.LaunchServices.QuarantineEventsV* 'delete from LSQuarantineEvent'"
  alias update='brew update && brew upgrade && brew cleanup'
fi
```

### Starship No-Sudo Install for Linux (install.sh)

```bash
# Source: https://starship.rs/install.sh (official install script flags)
linux_install_starship() {
  if command -v starship &>/dev/null; then
    ok "starship already installed"
    return 0
  fi
  mkdir -p "$HOME/.local/bin"
  curl -sS https://starship.rs/install.sh | sh -s -- -b "$HOME/.local/bin" -y
  ok "starship installed to ~/.local/bin"
}
```

### Cursor Devcontainer Settings (Claude's discretion)

In `~/.cursor/settings.json` on the host:
```json
{
  "dotfiles.repository": "https://github.com/italovietro/dotfiles.git",
  "dotfiles.targetPath": "~/.dotfiles",
  "dotfiles.installCommand": "install.sh --force"
}
```

The `dotfiles.targetPath: ~/.dotfiles` is critical — it must match `DOTFILES="$HOME/.dotfiles"` in install.sh.

For GitHub Codespaces: configure via GitHub Settings > Codespaces > Dotfiles to point to the same repo.

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| Separate .aliases_mac / .aliases_linux files | Single .aliases with platform block | Community consensus ~2018+ | Simpler maintenance, one file to edit |
| Linuxbrew for cross-platform package management | macOS Homebrew only; apt-get + curl installs on Linux | This project decision (CONTEXT.md) | Avoids Linuxbrew complexity; faster Linux setup |
| OMZ (Oh My Zsh) for cross-platform shell | antidote + pure zsh config | Phase 2 of this project | antidote works identically on macOS and Linux |
| Hard-coding brew paths everywhere | `if type brew` guards + platform detection | .zshrc already does this for the fpath block | Linux-safe .zshrc |
| `fzf --zsh` (new API) | Check with `command -v fzf` guard | fzf 0.48.0 (2024) | Existing guard in .zshrc is correct; Linux needs version ≥ 0.48 |

**Deprecated/outdated:**
- Linuxbrew: No longer recommended for dotfile setups targeting containers; adds significant complexity for minimal gain.
- Per-command `command -v brew` guards: Replaced by single platform block for macOS-specific aliases. Per-command guards are only for truly optional tools available on both platforms.

## Open Questions

1. **Cursor devcontainer symlinked dotfiles bug**
   - What we know: A September 2025 Cursor forum post reports that lifecycle commands don't evaluate symlinked dotfiles. The issue was closed without resolution after 22 days.
   - What's unclear: Whether this affects the install.sh execution itself (which runs before lifecycle commands) or only env vars set by dotfiles during lifecycle commands.
   - Recommendation: Test empirically in a Cursor devcontainer before finalizing plan 03-02. The STATE.md blocker note confirms this. The install.sh execution path (runs from cloned repo, not a symlink) is likely unaffected.

2. **Starship/fzf: install on Linux or degrade gracefully?**
   - What we know: Both have curl/git clone install paths that work without sudo. Starship: `curl -sS https://starship.rs/install.sh | sh -s -- -b ~/.local/bin -y`. fzf: `git clone --depth 1 https://github.com/junegunn/fzf.git ~/.fzf && ~/.fzf/install`.
   - What's unclear: User preference — the question is Claude's discretion.
   - Recommendation: Install both on Linux. Starship is the configured prompt (without it, Linux shell will be bare and broken-looking). fzf is optional but the `fzf --zsh` integration is already in .zshrc and needs fzf ≥ 0.48.0. Install both via the no-sudo methods and avoid the version mismatch from apt.

3. **Root vs non-root in Cursor devcontainers**
   - What we know: Cursor devcontainer containers typically run as root (no sudo needed). Remote Linux servers may be non-root with sudo.
   - What's unclear: Whether the user's remote servers always have sudo available.
   - Recommendation: Use `[[ "$(id -u)" -eq 0 ]]` check first, then fall back to `sudo` if non-root. This handles both cases without extra configuration.

## Sources

### Primary (HIGH confidence)
- https://antidote.sh/install — antidote git clone installation method (`git clone --depth=1 ... ~/.antidote`) and .zshrc sourcing pattern
- https://github.com/mattmc3/antidote — antidote official repo, update via `git pull`
- https://starship.rs/installing/ — Starship official install script with `-b ~/.local/bin -y` flags for no-sudo
- https://github.com/junegunn/fzf — fzf official repo, git clone install method and shell integration
- https://docs.github.com/en/codespaces/setting-your-user-preferences/personalizing-github-codespaces-for-your-account — GitHub Codespaces dotfiles: script detection order (install.sh first), clone location

### Secondary (MEDIUM confidence)
- https://forum.cursor.com/t/dev-container-using-dotfiles/108724 — Cursor devcontainer dotfiles settings format (`dotfiles.repository`, `dotfiles.targetPath`, `dotfiles.installCommand`)
- https://forum.cursor.com/t/cursor-devcontainer-lifecycle-commands-does-not-work-with-symlinked-dotfiles/132923 — Known issue with symlinked dotfiles in Cursor lifecycle commands (September 2025, unresolved)
- WebSearch: platform detection with `uname -s` returns `Darwin` on macOS, `Linux` on Linux — cross-referenced with multiple sources

### Tertiary (LOW confidence)
- WebSearch: Cursor devcontainer feature restored in extension 1.0.14 / 1.0.16 — unverified version numbers; treat as directional only

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — antidote git clone, starship curl, fzf git clone all verified against official docs
- Architecture patterns: HIGH — patterns derived from existing codebase + official sources; uname-s platform detection is POSIX standard
- Pitfalls: HIGH — most pitfalls identified by direct code inspection of existing files (antidote fpath bug verified by reading .zshrc line 53); fzf version sensitivity verified against fzf changelog
- Devcontainer integration: MEDIUM — Cursor forum posts are the primary source; symlink bug is unresolved and needs empirical testing

**Research date:** 2026-02-28
**Valid until:** 2026-03-28 (stable tooling — Stow, antidote, uname are not fast-moving)
