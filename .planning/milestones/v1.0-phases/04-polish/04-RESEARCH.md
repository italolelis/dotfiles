# Phase 4: Polish - Research

**Researched:** 2026-02-28
**Domain:** Shell scripting (update command), Ghostty terminal config, tmux plugin ecosystem
**Confidence:** HIGH

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

#### dot command
- No specific discussion — Claude has discretion on implementation details
- Must cover: git pull, stow --restow, brew update + upgrade, antidote update
- Cross-platform: skip brew steps on Linux (reuse IS_MACOS/IS_LINUX pattern from install.sh)

#### Ghostty config
- Migrate existing config from machine, enhance with Ghostty best practices
- Color scheme: Catppuccin Mocha
- Quick terminal (global hotkey dropdown) enabled
- Native tabs and splits enabled alongside tmux
- Font: Claude's discretion (pick best for dev terminal with Ghostty support)

#### tmux setup
- Migrate existing config from machine, enhance with modern best practices
- Prefix key: Ctrl+a (screen-style)
- tmux handles splits and panes (not Ghostty) — works consistently across terminals and SSH
- Mouse mode enabled (click panes, scroll history, drag resize)
- Status bar: Claude's discretion (pick clean style that works with Catppuccin)
- Plugins: tmux-resurrect + tmux-continuum for session persistence (from requirements)
- TPM (Tmux Plugin Manager) for plugin management

### Claude's Discretion
- Font choice for Ghostty
- tmux status bar design (clean, works with Catppuccin)
- dot command flags and output style
- Ghostty keybindings beyond quick terminal
- tmux keybindings beyond prefix change
- Additional tmux plugins if they improve the experience

### Deferred Ideas (OUT OF SCOPE)

None — discussion stayed within phase scope
</user_constraints>

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| PKGS-03 | `bin/dot` update command (brew update + antidote update + stow restow) | See dot command architecture; platform guard pattern from install.sh reusable |
| TOOL-01 | Ghostty config Stow-managed under `.config/ghostty/` | Ghostty config path is `~/.config/ghostty/config`; already partially configured in repo as `ghostty/.config/ghostty/config`; needs Catppuccin Mocha + quick terminal + keybinds |
| TOOL-02 | tmux config with TPM plugin manager, tmux-resurrect, tmux-continuum | TPM: clone to `~/.tmux/plugins/tpm`; both plugins well-documented; tmux 3.6a on machine (exceeds 3.2 minimum for catppuccin/tmux); catppuccin/tmux recommended for status bar |
</phase_requirements>

---

## Summary

Phase 4 consists of three independent, self-contained deliverables. None depends on the others, so they can be planned as separate plans or tackled in any order. Each maps to one requirement: PKGS-03 (dot command), TOOL-01 (Ghostty config), TOOL-02 (tmux setup).

The `dot` command is a straightforward shell script that should live in a Stow-managed `bin/` directory. The existing `install.sh` platform-detection pattern (`IS_MACOS`/`IS_LINUX`) applies directly — brew steps are guarded behind `$IS_MACOS`. The command runs: `git -C $DOTFILES pull`, `stow --restow` for all packages, `antidote update`, and on macOS: `brew update && brew upgrade && brew cleanup`.

Ghostty config is already partially in place (`ghostty/.config/ghostty/config` exists with JetBrains Mono and a placeholder theme). The existing config needs: theme changed to `Catppuccin Mocha` (built-in to Ghostty, no extra install needed), quick terminal configured with a global keybind, and split/tab keybindings added. Font recommendation: keep JetBrains Mono (already installed via Brewfile `font-jetbrains-mono`; Ghostty now has built-in Nerd Font glyph rendering so no patched font is needed).

tmux setup requires migrating the existing `.tmux.conf` (which is already Stow-managed at `tmux/.tmux.conf`) to add: Ctrl+a prefix, TPM plugin block, tmux-resurrect + tmux-continuum, and catppuccin/tmux for the status bar. The existing config already has good bones (mouse on, 256-color, base-index 1, focus-events). TPM must be bootstrapped by cloning to `~/.tmux/plugins/tpm` — this is done either manually or via install.sh.

**Primary recommendation:** Implement each deliverable as its own plan: 04-01 (dot command), 04-02 (Ghostty config), 04-03 (tmux). All three are purely additive changes to existing files or new files in existing Stow packages.

---

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| GNU Stow | 2.4.0 (already installed) | Manages `bin/dot` via Stow symlink | Established pattern in this repo |
| Ghostty | Latest (cask, already installed) | Terminal emulator being configured | Already in Brewfile + Stow package |
| tmux | 3.6a (installed) | Multiplexer being configured | Already in Brewfile + Stow package |
| TPM | Latest (git clone) | tmux plugin manager | De-facto standard plugin manager |
| tmux-resurrect | Latest (via TPM) | Saves/restores sessions | Required by TOOL-02; most mature solution |
| tmux-continuum | Latest (via TPM) | Auto-saves every 15 min; auto-restores on start | Required by TOOL-02; companion to resurrect |
| catppuccin/tmux | v2.1.3 (via TPM) | Mocha status bar theme | Consistent with Ghostty color scheme |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| tmux-sensible | Latest (via TPM) | Modern defaults (escape-time 0, big history, screen-256color) | Optional — its settings can be inlined manually instead |
| Catppuccin Mocha (Ghostty) | Built-in | Ghostty theme | Already bundled; no separate file install needed |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| catppuccin/tmux (TPM) | Manual Catppuccin colors in .tmux.conf | Manual is simpler but harder to maintain; TPM plugin auto-updates |
| tmux-continuum | tmux-resurrect only (manual save/restore) | continuum adds automation at no complexity cost; worth including |
| `bin/dot` as Stow-managed script | Alias or function in `.aliases` | Script is cleaner: executable, testable, no shell source needed; discoverable via PATH |

---

## Architecture Patterns

### Recommended Project Structure

The three deliverables slot into existing Stow packages:

```
.dotfiles/
├── bin/                     # NEW Stow package for the dot command
│   └── bin/
│       └── dot              # The update script (executable)
├── ghostty/
│   └── .config/
│       └── ghostty/
│           └── config       # EXISTS — needs updates
└── tmux/
    └── .tmux.conf           # EXISTS — needs full rewrite/enhancement
```

After stowing, symlinks land at:
- `~/bin/dot` → `~/.dotfiles/bin/bin/dot`
- `~/.config/ghostty/config` → `~/.dotfiles/ghostty/.config/ghostty/config`
- `~/.tmux.conf` → `~/.dotfiles/tmux/.tmux.conf`

### Pattern 1: dot command — platform-aware update script

**What:** A bash script at `bin/bin/dot` that encapsulates the "sync dotfiles" workflow.
**When to use:** Whenever the user wants to pull the latest dotfiles and apply updates.

```bash
#!/usr/bin/env bash
# Source: install.sh platform-detection pattern
set -euo pipefail

DOTFILES="$HOME/.dotfiles"
PACKAGES=(zsh git tmux starship ghostty ssh misc bin)

PLATFORM="$(/usr/bin/uname -s)"
IS_MACOS=false
IS_LINUX=false
case "$PLATFORM" in
  Darwin) IS_MACOS=true ;;
  Linux)  IS_LINUX=true ;;
esac

log()  { echo "  $1"; }
info() { echo ""; echo "==> $1"; }
ok()   { echo "  [ok] $1"; }

info "Pulling latest dotfiles..."
git -C "$DOTFILES" pull --ff-only
ok "git pull"

info "Restowing packages..."
for pkg in "${PACKAGES[@]}"; do
  if [[ -d "$DOTFILES/$pkg" ]]; then
    stow --restow --no-folding --target="$HOME" --dir="$DOTFILES" "$pkg"
    ok "$pkg"
  fi
done

info "Updating antidote plugins..."
antidote update
ok "antidote"

if $IS_MACOS; then
  info "Updating Homebrew..."
  brew update && brew upgrade && brew cleanup
  ok "brew"
fi

echo ""
echo "=============================="
echo "  dot: all done"
echo "=============================="
```

**PATH consideration:** `~/bin` is not currently in `.path`. The plan must either add `~/bin` to PATH in `.path`, or place the script at `~/.local/bin/dot` within an existing `bin/` Stow package. The simplest approach: create a `bin/` Stow package whose structure maps `bin/bin/dot` to `~/bin/dot`, then add `$HOME/bin` to `.path`. Alternatively, place in `.local/bin/` by structuring as `bin/.local/bin/dot` → `~/.local/bin/dot` (already on PATH in `.path`). The `.local/bin` approach avoids any PATH change.

### Pattern 2: Ghostty config — complete config with Catppuccin Mocha

**What:** Ghostty reads `~/.config/ghostty/config`. The file already exists and is Stow-managed. It needs targeted changes.

```
# Source: ghostty.org/docs/config/reference and ghostty.org/docs/features/theme

# Font — JetBrains Mono (already installed via font-jetbrains-mono cask)
# Ghostty has built-in Nerd Font rendering; no patched variant needed
font-family = JetBrains Mono
font-size = 14

# Theme — Catppuccin Mocha is bundled into Ghostty
theme = Catppuccin Mocha

# Window
window-padding-x = 8
window-padding-y = 8
window-decoration = true
macos-titlebar-style = tabs

# Quick terminal (global hotkey — works system-wide even when Ghostty unfocused)
# macOS requires Accessibility permissions for global: prefix
quick-terminal-position = top
quick-terminal-screen = main
quick-terminal-autohide = true
quick-terminal-animation-duration = 0.2
keybind = global:cmd+grave_accent=toggle_quick_terminal

# Splits and tabs (supplementary — tmux is primary split manager)
keybind = cmd+shift+d=new_split:right
keybind = cmd+d=new_split:down
keybind = cmd+shift+h=goto_split:left
keybind = cmd+shift+l=goto_split:right
keybind = cmd+shift+k=goto_split:up
keybind = cmd+shift+j=goto_split:down

# Shell integration
shell-integration = zsh

# Visual
cursor-style = block
cursor-style-blink = false
background-opacity = 0.95
copy-on-select = true

# Font ligatures
font-feature = +liga
font-feature = +clig
```

**Critical:** The existing config uses `theme = "Monokai Pro"`. This must be replaced with `theme = Catppuccin Mocha` (note: no quotes — Ghostty 1.2.0+ uses Title Case without quotes; quoting still works but unquoted is canonical per docs).

### Pattern 3: tmux config — TPM + Catppuccin Mocha + session persistence

**What:** Full `.tmux.conf` rewrite incorporating: prefix Ctrl+a, modern terminal settings, TPM plugin block, catppuccin/tmux v2, tmux-resurrect, tmux-continuum.

```tmux
# Source: github.com/tmux-plugins/tpm, github.com/catppuccin/tmux, github.com/tmux-plugins/tmux-continuum

# ── Prefix ────────────────────────────────────────────────────────────────────
unbind C-b
set -g prefix C-a
bind C-a send-prefix

# ── General ───────────────────────────────────────────────────────────────────
set -g base-index 1
set -g pane-base-index 1
setw -g pane-base-index 1
set -g renumber-windows on     # renumber windows when one closes
set -s escape-time 0           # faster key sequences (no vim delay)
set -g history-limit 50000
set -g display-time 4000
set -g status-interval 5
set -g focus-events on
set -g mouse on

# ── Terminal colors ────────────────────────────────────────────────────────────
# Modern approach: tmux-256color for true color and italics support
set -g default-terminal "tmux-256color"
set -as terminal-overrides ",*-256color:Tc"

# ── Splits and navigation ──────────────────────────────────────────────────────
# Keep current path on split
bind | split-window -h -c "#{pane_current_path}"
bind - split-window -v -c "#{pane_current_path}"
unbind '"'
unbind %

# Vim-style pane navigation
bind h select-pane -L
bind j select-pane -D
bind k select-pane -U
bind l select-pane -R

# Reload config
bind r source-file ~/.tmux.conf \; display "Config reloaded"

# ── Catppuccin Mocha ─────────────────────────────────────────────────────────
set -g @catppuccin_flavor "mocha"
set -g @catppuccin_window_status_style "rounded"

# ── Plugins ───────────────────────────────────────────────────────────────────
# Order matters: resurrect before continuum; catppuccin status-right issue — put continuum LAST
set -g @plugin 'tmux-plugins/tpm'
set -g @plugin 'tmux-plugins/tmux-sensible'
set -g @plugin 'catppuccin/tmux#v2.1.3'
set -g @plugin 'tmux-plugins/tmux-resurrect'
set -g @plugin 'tmux-plugins/tmux-continuum'

# ── Session persistence ────────────────────────────────────────────────────────
set -g @continuum-restore 'on'   # auto-restore on tmux server start

# ── Status bar (catppuccin modules) ────────────────────────────────────────────
set -g status-left-length 100
set -g status-right-length 100
set -g status-left ""
set -g status-right "#{E:@catppuccin_status_session} #{E:@catppuccin_status_uptime}"

# ── Initialize TPM (must be last line) ────────────────────────────────────────
run '~/.tmux/plugins/tpm/tpm'
```

**TPM bootstrap:** TPM is not installed by Homebrew — it must be cloned:
```bash
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
```
This must happen before `tmux source ~/.tmux.conf` works. The plan needs a task for this. An optional self-bootstrapping approach:
```tmux
# Auto-install TPM if missing (add before 'run tpm' line)
if "test ! -d ~/.tmux/plugins/tpm" \
  "run 'git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && ~/.tmux/plugins/tpm/bin/install_plugins'"
```

### Anti-Patterns to Avoid

- **Putting tmux-continuum before tmux-resurrect in plugin list:** continuum depends on resurrect; order matters.
- **Putting catppuccin/tmux after continuum:** catppuccin/tmux rewrites `status-right`; if it comes after continuum, it overrides continuum's save hook. Put catppuccin before resurrect+continuum.
- **Using `global:` Ghostty keybind on Linux:** The `global:` prefix is macOS-only. The existing config is macOS-only anyway (Ghostty is a cask), so this is not a concern.
- **Quoting theme name in Ghostty:** `theme = "Catppuccin Mocha"` works but the canonical form since 1.2.0 is `theme = Catppuccin Mocha` (Title Case, no quotes).
- **Placing `run '~/.tmux/plugins/tpm/tpm'` anywhere but last line:** TPM must be the final line — all `@plugin` declarations must precede it.
- **Structuring bin Stow package as `bin/dot`:** This would symlink to `~/dot`, not `~/bin/dot`. The package structure must be `bin/bin/dot` (package-dir/target-path) or `bin/.local/bin/dot` to land at `~/.local/bin/dot`.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| tmux session persistence | Custom save/restore scripts | tmux-resurrect + tmux-continuum | Handles sessions, windows, panes, working dirs, running programs; edge cases are extensive |
| tmux Catppuccin status bar | Manual hex colors in .tmux.conf | catppuccin/tmux TPM plugin | Keeps theme in sync with Ghostty automatically; maintains across tmux updates |
| TPM plugin installation | Custom plugin manager | TPM | Industry standard; prefix+I / prefix+U / prefix+alt+u; well-maintained |

**Key insight:** All three "don't hand-roll" items are available as TPM plugins and require only configuration lines in `.tmux.conf` — no custom scripting.

---

## Common Pitfalls

### Pitfall 1: catppuccin/tmux v2 overwrites status-right — breaks tmux-continuum

**What goes wrong:** tmux-continuum appends a hook to `status-right` for auto-save to work. If catppuccin/tmux runs AFTER continuum and rewrites `status-right`, the autosave hook disappears silently.
**Why it happens:** Plugin load order in TPM determines execution order.
**How to avoid:** Place catppuccin/tmux plugin declaration BEFORE tmux-resurrect and tmux-continuum in the `@plugin` list. Verify with `tmux show-options -g status-right` — continuum's hook should be visible.
**Warning signs:** `@continuum-status` shows no autosave counter in the status bar; manual save still works but auto-save doesn't run.

### Pitfall 2: TPM not installed before sourcing .tmux.conf

**What goes wrong:** If `~/.tmux/plugins/tpm` doesn't exist when tmux starts, the `run '~/.tmux/plugins/tpm/tpm'` line silently fails. Plugins are not loaded.
**Why it happens:** TPM is a git-cloned binary, not a Homebrew package.
**How to avoid:** The plan must include a step to clone TPM before expecting plugins to work. The self-bootstrapping snippet in the `.tmux.conf` handles this automatically on first run.
**Warning signs:** Prefix+I does nothing; `@catppuccin_flavor` has no effect; sessions not being saved.

### Pitfall 3: Quick terminal global keybind requires macOS Accessibility permissions

**What goes wrong:** `global:cmd+grave_accent=toggle_quick_terminal` does nothing after setting it.
**Why it happens:** macOS requires explicit Accessibility permission for apps that intercept system-wide keypresses.
**How to avoid:** After setting the keybind, go to System Settings → Privacy & Security → Accessibility and enable Ghostty. This must be done manually — no script can grant it.
**Warning signs:** Quick terminal doesn't appear on hotkey press even after Ghostty restart.

### Pitfall 4: dot command fails if antidote is not on PATH

**What goes wrong:** `antidote update` in `bin/dot` fails with "command not found" because `dot` runs outside a zsh login shell (antidote is sourced in `.zshrc`).
**Why it happens:** `bin/dot` is a bash script, not a zsh function. Antidote on macOS is installed via Homebrew at `/opt/homebrew/bin/antidote` or `/usr/local/bin/antidote`, which should be on PATH if `brew shellenv` is evaluated. On Linux, antidote is at `~/.antidote/antidote.zsh` and cannot be called as a binary.
**How to avoid:** On macOS, ensure brew's prefix is sourced before calling antidote. On Linux, antidote update is not applicable (or call the shell function via `zsh -c 'antidote update'`). The dot command should guard: `if command -v antidote &>/dev/null; then antidote update; fi` and platform-gate accordingly.
**Warning signs:** `dot` exits with non-zero on Linux or when run from a non-interactive shell.

### Pitfall 5: Ghostty config file location — XDG vs macOS Application Support

**What goes wrong:** Config changes in `~/.config/ghostty/config` have no effect.
**Why it happens:** On macOS, Ghostty also reads `~/Library/Application Support/com.mitchellh.ghostty/config`. If both exist, the App Support version takes precedence or conflicts.
**How to avoid:** Verify only the Stow-managed `~/.config/ghostty/config` exists (or is the one Ghostty is reading). If the App Support path exists from a previous config, delete it so XDG path is authoritative. Run `ghostty +list-themes` to confirm Ghostty reads config correctly.
**Warning signs:** Theme doesn't change despite config update; font stays wrong.

### Pitfall 6: stow --restow in dot command with bin/ as new package

**What goes wrong:** If `bin/` is added as a new Stow package in Phase 4, the PACKAGES list in `install.sh` and `dot` must both include `bin`. Running `dot` before `install.sh` is updated would miss the new package.
**Why it happens:** PACKAGES list is hardcoded in `install.sh`.
**How to avoid:** Update `PACKAGES` in both `install.sh` and `bin/dot` to include `bin`. The plan must include this step.

---

## Code Examples

### bin/dot — complete script structure

```bash
#!/usr/bin/env bash
# ~/.dotfiles/bin/bin/dot — update dotfiles, packages, and plugins
# Usage: dot
set -euo pipefail

DOTFILES="$HOME/.dotfiles"
PACKAGES=(zsh git tmux starship ghostty ssh misc bin)

PLATFORM="$(/usr/bin/uname -s)"
IS_MACOS=false
IS_LINUX=false
case "$PLATFORM" in
  Darwin) IS_MACOS=true ;;
  Linux)  IS_LINUX=true ;;
esac

log()  { echo "  $1"; }
info() { echo ""; echo "==> $1"; }
ok()   { echo "  [ok] $1"; }

# 1. Pull latest changes
info "Pulling dotfiles..."
git -C "$DOTFILES" pull --ff-only
ok "git pull"

# 2. Restow all packages (prunes stale symlinks, creates new ones)
info "Restowing packages..."
for pkg in "${PACKAGES[@]}"; do
  if [[ -d "$DOTFILES/$pkg" ]]; then
    stow --restow --no-folding --target="$HOME" --dir="$DOTFILES" "$pkg"
    ok "$pkg"
  fi
done

# 3. Update antidote plugins
# macOS: antidote is a brew binary; Linux: antidote is sourced from ~/.antidote
if $IS_MACOS && command -v antidote &>/dev/null; then
  info "Updating antidote plugins..."
  antidote update
  ok "antidote"
fi

# 4. Update Homebrew (macOS only)
if $IS_MACOS; then
  info "Updating Homebrew..."
  brew update && brew upgrade && brew cleanup
  ok "brew"
fi

echo ""
echo "=============================="
echo "  dot: done"
echo "=============================="
```

### Ghostty config — complete enhanced config

```
# ~/.config/ghostty/config
# Source: ghostty.org/docs/config/reference

# Font
font-family = JetBrains Mono
font-size = 14
font-feature = +liga
font-feature = +clig

# Theme (built-in — no separate install needed)
theme = Catppuccin Mocha

# Window
window-padding-x = 8
window-padding-y = 8
window-decoration = true
macos-titlebar-style = tabs
background-opacity = 0.95

# Cursor
cursor-style = block
cursor-style-blink = false

# Shell integration
shell-integration = zsh

# Clipboard
copy-on-select = true

# Quick terminal (macOS global hotkey — requires Accessibility permission)
quick-terminal-position = top
quick-terminal-screen = main
quick-terminal-autohide = true
quick-terminal-animation-duration = 0.2
keybind = global:cmd+grave_accent=toggle_quick_terminal

# Splits (supplementary; tmux is primary pane manager)
keybind = cmd+shift+d=new_split:right
keybind = cmd+d=new_split:down
keybind = cmd+shift+h=goto_split:left
keybind = cmd+shift+l=goto_split:right
keybind = cmd+shift+k=goto_split:up
keybind = cmd+shift+j=goto_split:down
```

### tmux TPM plugin installation (bootstrap)

```bash
# Run once on a new machine before starting tmux with the new config
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm
# Then start tmux and press prefix + I (capital i) to install plugins
```

Or self-bootstrapping in `.tmux.conf`:
```tmux
# Auto-install TPM if not present
if "test ! -d ~/.tmux/plugins/tpm" \
  "run 'git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm && ~/.tmux/plugins/tpm/bin/install_plugins'"
```

### tmux-continuum verify autosave is working

```bash
# After tmux starts with the new config:
# Check continuum status in status bar, or:
tmux show-options -g @continuum-save-last-time
# Should show a recent timestamp (updates every 15 min)
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|--------------|------------------|--------------|--------|
| `xterm-256color` in tmux | `tmux-256color` + `terminal-features` (or `-overrides`) for true color | tmux 3.2+ | Proper italics and true color inside tmux |
| screen-256color in tmux | `tmux-256color` default-terminal | Modern ncurses | screen-256color doesn't support italics |
| Catppuccin theme = `catppuccin-mocha` (kebab-case) | `theme = Catppuccin Mocha` (Title Case) | Ghostty 1.2.0 | Old name still accepted but new form is canonical |
| Manual Catppuccin colors in .tmux.conf | catppuccin/tmux v2 TPM plugin | 2024 | v2 requires tmux 3.2+; v0.x for older tmux |
| Patched Nerd Fonts required | Built-in Nerd Font glyph rendering in Ghostty | 2025 (post-Mitchell PR) | No need to install patched font variants |
| Manual tmux session scripts | tmux-resurrect + tmux-continuum | Ongoing standard | Full session tree persisted automatically |

**Deprecated/outdated in existing .tmux.conf:**
- `set -g default-terminal "xterm-256color"` and `set -ga terminal-overrides ",xterm-256color:Tc"`: Replace with `tmux-256color` approach
- Manual red/yellow color scheme: Replace with catppuccin/tmux plugin
- `visual-activity on` / `visual-bell on` / `bell-action none`: These conflict; the catppuccin/tmux config simplifies this

---

## Open Questions

1. **Should `bin/` be a new Stow package or should `dot` live in an existing location?**
   - What we know: `.local/bin` is already on PATH (via `.path`); a `bin/` Stow package with structure `bin/.local/bin/dot` would work without PATH changes. Alternatively, a `bin/` package with `bin/bin/dot` requires adding `~/bin` to `.path`.
   - What's unclear: User preference for where they want `dot` to live.
   - Recommendation: Use `bin/.local/bin/dot` (lands at `~/.local/bin/dot`) — already on PATH, no `.path` changes needed, consistent with how the linux starship installer uses `~/.local/bin`.

2. **TPM in install.sh or separate task?**
   - What we know: TPM must be cloned before first tmux session after config change. This is a one-time bootstrap step.
   - What's unclear: Whether the planner wants TPM clone in `install.sh` or handled by the self-bootstrapping `.tmux.conf` snippet.
   - Recommendation: Add TPM self-bootstrap to `.tmux.conf` so it works on any machine without `install.sh` modification. The `dot` command naturally handles ongoing `stow --restow` for the config file.

3. **catppuccin/tmux v2.1.3 — should the version be pinned?**
   - What we know: The fetch instruction uses `catppuccin/tmux#v2.1.3`. v2 requires tmux 3.2+; machine has 3.6a.
   - What's unclear: Whether pinning to a tag is required or if `catppuccin/tmux` (latest) is fine.
   - Recommendation: Pin to `#v2.1.3` as shown in official docs — prevents breaking changes from v3 migration if/when it arrives.

---

## Sources

### Primary (HIGH confidence)
- [ghostty.org/docs/config/reference](https://ghostty.org/docs/config/reference) — quick-terminal options, keybind actions, font-family, theme
- [ghostty.org/docs/features/theme](https://ghostty.org/docs/features/theme) — theme system, `ghostty +list-themes`, built-in themes
- [ghostty.org/docs/config/keybind/reference](https://ghostty.org/docs/config/keybind/reference) — toggle_quick_terminal, new_split, goto_split actions
- [github.com/tmux-plugins/tpm](https://github.com/tmux-plugins/tpm) — TPM installation, plugin format, `bin/install_plugins`
- [github.com/tmux-plugins/tmux-resurrect](https://github.com/tmux-plugins/tmux-resurrect) — what gets saved, key bindings, requirements
- [github.com/tmux-plugins/tmux-continuum](https://github.com/tmux-plugins/tmux-continuum) — auto-save interval, `@continuum-restore 'on'`, status-right caveat
- [github.com/catppuccin/tmux](https://github.com/catppuccin/tmux) — v2 installation, TPM declaration, `@catppuccin_flavor`, module list, tmux 3.2+ requirement
- [antidote.sh/commands](https://antidote.sh/commands) — `antidote update` command description

### Secondary (MEDIUM confidence)
- [github.com/catppuccin/ghostty](https://github.com/catppuccin/ghostty) — confirms built-in vs manual theme; built-in may differ slightly from repo version (verified: built-in is sufficient for this use case)
- Community configs confirming `keybind = global:cmd+grave_accent=toggle_quick_terminal` pattern (multiple sources agree)
- tmux-sensible GitHub README — settings list, design philosophy

### Tertiary (LOW confidence)
- WebSearch result re: `antidote update` on Linux — not confirmed by official antidote docs whether `antidote update` works as a binary call (not just zsh function). Flag for validation when implementing dot command on Linux.

---

## Metadata

**Confidence breakdown:**
- dot command: HIGH — bash scripting pattern is straightforward; reuses established `install.sh` structure; only Linux antidote behavior is LOW
- Ghostty config: HIGH — official docs consulted; `theme = Catppuccin Mocha` confirmed built-in; quick terminal keybind confirmed
- tmux stack (TPM + plugins): HIGH — all official READMEs consulted; plugin order critical detail confirmed from continuum docs; catppuccin/tmux v2 confirmed working with tmux 3.2+ (machine has 3.6a)
- Architecture: HIGH — existing Stow structure understood; pitfalls derived from official source warnings

**Research date:** 2026-02-28
**Valid until:** 2026-03-30 (stable tools; tmux plugin versions may change but pinned tags mitigate this)
