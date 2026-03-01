---
phase: 04-polish
plan: 02
subsystem: terminal
tags: [ghostty, catppuccin, quick-terminal, keybindings, stow]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: Stow-managed dotfiles infrastructure enabling ghostty package symlinking
provides:
  - Ghostty terminal config with Catppuccin Mocha theme, quick terminal dropdown, and split keybindings
affects: [04-polish]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Ghostty Catppuccin Mocha theme (built-in, Title Case, unquoted)"
    - "Quick terminal global hotkey via global:cmd+grave_accent=toggle_quick_terminal"
    - "Vim-style split navigation with cmd+shift+hjkl"

key-files:
  created: []
  modified:
    - ghostty/.config/ghostty/config

key-decisions:
  - "Catppuccin Mocha is bundled into Ghostty — no separate theme file install needed; referenced as 'Catppuccin Mocha' (Title Case, unquoted, canonical since Ghostty 1.2.0+)"
  - "Quick terminal global hotkey requires macOS Accessibility permission — documented in config comment"
  - "Ghostty splits are supplementary to tmux — tmux remains primary split/pane manager"
  - "font-family uses unquoted style (JetBrains Mono) — canonical Ghostty config style"

patterns-established:
  - "Theme names in Ghostty config are unquoted Title Case — not quoted strings"
  - "Section headers with ASCII art separators (──) used for readability in config files"

requirements-completed: [TOOL-01]

# Metrics
duration: 5min
completed: 2026-03-01
---

# Phase 4 Plan 02: Ghostty Config Enhancement Summary

**Ghostty terminal reconfigured with Catppuccin Mocha theme, global Cmd+\` quick terminal dropdown, vim-style split keybindings (Cmd+Shift+D/Cmd+D/HJKL), and JetBrains Mono 14pt**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-02-28
- **Completed:** 2026-03-01T11:32:52Z
- **Tasks:** 1 auto + 1 checkpoint:human-verify
- **Files modified:** 1

## Accomplishments

- Replaced Monokai Pro theme with Catppuccin Mocha (bundled in Ghostty, no separate install)
- Added quick terminal feature with `global:cmd+grave_accent=toggle_quick_terminal` global hotkey (dropdown from top of screen, works system-wide)
- Added split keybindings: Cmd+Shift+D (right split), Cmd+D (down split), Cmd+Shift+HJKL (vim-style navigation)
- Bumped font size from 13 to 14pt and moved ligature settings next to font section
- Organized config with ASCII-art section headers for readability
- User verified config in Ghostty (checkpoint approved)

## Task Commits

Each task was committed atomically:

1. **Task 1: Replace Ghostty config with enhanced Catppuccin Mocha version** - `9a081ac` (feat)
2. **Task 2: checkpoint:human-verify** - approved by user (no commit — checkpoint, not code task)

**Plan metadata:** committed with docs commit (this summary)

## Files Created/Modified

- `ghostty/.config/ghostty/config` - Complete Ghostty config rewrite: Catppuccin Mocha theme, quick terminal, split keybindings, font 14pt, section headers

## Decisions Made

- Catppuccin Mocha is bundled into Ghostty — no separate theme file install needed. Referenced as `Catppuccin Mocha` (Title Case, unquoted), which is the canonical format since Ghostty 1.2.0+.
- Quick terminal global hotkey requires macOS Accessibility permission — documented in config with comment directing user to System Settings.
- Ghostty splits are supplementary to tmux — tmux remains the primary split/pane manager (noted in config comment).
- `font-family` uses unquoted style (`JetBrains Mono`) — canonical Ghostty config style, consistent with theme name style.

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None — config was a full rewrite as specified. User verified and approved the result via checkpoint.

**Accessibility note:** The quick terminal hotkey (`global:cmd+grave_accent`) requires Ghostty to have macOS Accessibility permission (System Settings → Privacy & Security → Accessibility). This is documented in the config file and was communicated to the user at the checkpoint.

## User Setup Required

**Manual step needed for quick terminal hotkey:**
- Grant Ghostty access in System Settings → Privacy & Security → Accessibility
- Without this, `global:cmd+grave_accent=toggle_quick_terminal` will not function system-wide
- Standard Ghostty keybinds and splits work without this permission

## Next Phase Readiness

- Ghostty config is complete and Stow-managed — symlinked via `ghostty` package to `~/.config/ghostty/config`
- Catppuccin Mocha theme active in Ghostty (consistent with tmux Catppuccin Mocha from 04-03)
- Phase 04-polish is now complete — all three plans (04-01 dot update, 04-02 Ghostty, 04-03 tmux) delivered

---
*Phase: 04-polish*
*Completed: 2026-03-01*
