---
phase: 04-polish
plan: 01
subsystem: infra
tags: [stow, bash, dotfiles, homebrew, antidote, cross-platform]

# Dependency graph
requires:
  - phase: 03-cross-platform
    provides: Platform guards (IS_MACOS/IS_LINUX), cross-platform install.sh pattern
  - phase: 01-foundation
    provides: install.sh with stow package management and PACKAGES array
provides:
  - "bin/.local/bin/dot — daily-driver dotfiles maintenance command"
  - "install.sh updated to stow bin package on fresh machine installs"
affects: [future-phases, devcontainer]

# Tech tracking
tech-stack:
  added: [bin stow package]
  patterns: [stow-managed ~/.local/bin scripts, command -v guard for optional binaries]

key-files:
  created: [bin/.local/bin/dot]
  modified: [install.sh]

key-decisions:
  - "dot script uses ~/.local/bin (not ~/bin) — already on PATH via zsh/.path, no PATH changes needed"
  - "antidote update guarded with command -v (not IS_MACOS) — works when antidote is brew binary, silently skips on Linux where antidote is sourced as zsh function"
  - "git pull --ff-only chosen over plain pull — fails cleanly on diverging commits instead of creating merge commits"
  - "PACKAGES in dot script includes bin itself — ensures dot restows the bin package on each run"

patterns-established:
  - "Stow package for ~/.local/bin: bin/.local/bin/<name> → ~/.local/bin/<name>"
  - "Optional binary guard: if command -v <tool> &>/dev/null; then ... fi"

requirements-completed: [PKGS-03]

# Metrics
duration: 5min
completed: 2026-03-01
---

# Phase 04 Plan 01: dot Update Command Summary

**Stow-managed `dot` command at `bin/.local/bin/dot` that runs git pull, restows all packages, updates antidote plugins, and updates Homebrew on macOS**

## Performance

- **Duration:** ~5 min
- **Started:** 2026-02-28T21:06:20Z
- **Completed:** 2026-03-01
- **Tasks:** 3 of 3 complete (2 auto + 1 checkpoint:human-verify — approved by user)
- **Files modified:** 2

## Accomplishments

- Created `bin/.local/bin/dot` as executable bash script managed by GNU Stow
- Script pulls dotfiles (ff-only), restows all 8 packages, updates antidote (guarded), updates Homebrew (macOS only)
- Updated `install.sh` PACKAGES array to include `bin` so fresh machine installs stow the bin package automatically

## Task Commits

Each task was committed atomically:

1. **Task 1: Create bin/.local/bin/dot update script** - `8399061` (feat)
2. **Task 2: Add bin to install.sh PACKAGES array** - `e3803c9` (chore)
3. **Task 3: Checkpoint human-verify** - approved by user, no code commit

**Plan metadata:** (docs commit for this SUMMARY)

## Files Created/Modified

- `bin/.local/bin/dot` - Executable dotfiles maintenance script; stowed to ~/.local/bin/dot
- `install.sh` - PACKAGES array updated to include `bin`

## Decisions Made

- `dot` uses `~/.local/bin` path because it is already on PATH via `zsh/.path` — no PATH changes needed
- `antidote update` is guarded with `command -v antidote` (not `$IS_MACOS`) — on macOS antidote is a brew binary; on Linux antidote is sourced as a zsh function and is not available as a standalone binary
- `git pull --ff-only` is safe and intentional — fails loudly if local commits diverge instead of creating unintended merge commits
- Platform detection block mirrors `install.sh` exactly (`PLATFORM="$(/usr/bin/uname -s)"`, `IS_MACOS`/`IS_LINUX` booleans)

## Deviations from Plan

None - plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None - no external service configuration required.

## Next Phase Readiness

- `dot` command is implemented, verified, and approved — ready for daily use
- `which dot` resolves to `~/.local/bin/dot` after stowing the bin package
- Idempotency confirmed: `dot` can be run twice without errors
- Phase 4 plans 04-02 (Ghostty) and 04-03 (tmux) are also complete — phase 4 is fully delivered

---
*Phase: 04-polish*
*Completed: 2026-02-28*
