---
phase: 01-foundation
plan: 02
subsystem: infra
tags: [stow, homebrew, install, bash, symlinks, idempotent]

# Dependency graph
requires:
  - phase: 01-01
    provides: "7 GNU Stow package directories (zsh/, git/, tmux/, starship/, ghostty/, ssh/, misc/) with correct internal layouts"
provides:
  - "install.sh: idempotent Stow-based installer with --restow --no-folding for all 7 packages"
  - "install.sh: auto-installs Homebrew on fresh Mac (ARM + Intel detection)"
  - "install.sh: backs up conflicting $HOME files to ~/.backup/ before stowing"
  - "install.sh: supports --force/-f flag to skip confirmation prompt (devcontainer/automation use)"
  - "install.sh: requires GNU Stow, auto-installs via brew if missing"
  - "install.sh: skips Brewfile gracefully if not yet present (plan 01-03 scope)"
affects:
  - "01-03-PLAN"
  - "01-04-PLAN"
  - "02-shell"
  - "03-devcontainer"

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "backup-then-stow: move conflicting regular files to ~/.backup/dotfiles_TIMESTAMP/ before running stow --restow"
    - "stow --restow --no-folding: idempotent symlinking pattern for all packages"
    - "brew bundle install --no-lock: idempotent package installation without generating lock file"

key-files:
  created: []
  modified:
    - "install.sh"

key-decisions:
  - "Used DOTFILES='$HOME/.dotfiles' fixed constant (not derived from BASH_SOURCE) per RESEARCH.md Pitfall 7: prevents broken behavior when install.sh is run as a symlink"
  - "backup_conflicts() uses find + per-file check before stowing rather than parsing stow --simulate output: more reliable approach that handles all conflict types without stow output format dependency"
  - "run_brew_bundle() skips gracefully if Brewfile does not exist: plan 01-03 adds Brewfile; install.sh must be functional before that plan runs"
  - "require_stow() attempts brew install stow before failing: improves fresh-Mac UX where stow is not yet installed"

patterns-established:
  - "install.sh uses #!/usr/bin/env bash (not /bin/sh): BASH_SOURCE, arrays, [[ ]] require bash"
  - "All stow invocations use --restow --no-folding --target=$HOME --dir=$DOTFILES: the canonical idempotent stow pattern"
  - "--force/-f flag skips confirmation: convention for devcontainer and CI automation use"

requirements-completed: [FOUND-02, FOUND-03]

# Metrics
duration: 2min
completed: 2026-02-28
---

# Phase 1 Plan 02: Stow-Based Installer Summary

**Rsync-based install.sh replaced with idempotent GNU Stow installer: auto-installs Homebrew, backs up $HOME conflicts to ~/.backup/, stows all 7 packages with --restow --no-folding, and supports --force flag for automation**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-02-28T12:33:40Z
- **Completed:** 2026-02-28T12:35:37Z
- **Tasks:** 2
- **Files modified:** 1 (install.sh rewritten)

## Accomplishments
- Replaced 69-line rsync/Oh-My-Zsh script with 136-line Stow-based installer
- Implemented backup_conflicts() that pre-moves conflicting regular $HOME files to timestamped ~/.backup/ dir before stowing
- Added install_homebrew() with Apple Silicon (/opt/homebrew) and Intel (/usr/local) path detection
- Added require_stow() that auto-installs stow via brew if missing and verifies version
- Added run_brew_bundle() that gracefully skips if Brewfile not yet present
- Verified GNU Stow 2.4.1 installed and stow --simulate confirms all 7 package directories are valid with correct path layouts
- Confirmed --force/-f flag correctly bypasses confirmation prompt

## Task Commits

Each task was committed atomically:

1. **Task 1: Rewrite install.sh as idempotent Stow-based installer** - `267fe42` (feat)
2. **Task 2: Verify install.sh idempotency with dry-run test** - no code changes (verification only; Task 1 commit captures all work)

**Plan metadata:** (docs commit — see state updates below)

## Files Created/Modified
- `install.sh` - Rewritten from scratch: Stow-based installer with Homebrew auto-install, conflict backup, stow_packages(), and --force flag

## Decisions Made
- `DOTFILES="$HOME/.dotfiles"` fixed constant (not BASH_SOURCE): RESEARCH.md Pitfall 7 documents that BASH_SOURCE on a symlink causes path resolution issues; fixed constant is simpler and more reliable
- backup_conflicts() uses `find -type f` + per-file `[[ -e target ]] && [[ ! -L target ]]` checks instead of parsing `stow --simulate` output: the simulate output format could vary; the per-file approach is more robust
- run_brew_bundle() skips gracefully when Brewfile missing: install.sh is created in plan 01-02 but Brewfile is created in plan 01-03; the installer must be functional as a partial bootstrap
- require_stow() attempts `brew install stow` automatically: on a fresh Mac, stow is not pre-installed; auto-installing improves the bootstrap UX

## Deviations from Plan

None - plan executed exactly as written.

Note: GNU Stow was installed during Task 2 verification (it was not yet installed on this machine). This is consistent with the plan's intent — stow not being installed is the normal fresh-Mac state and install.sh's require_stow() handles it. The stow --simulate test confirmed all package directories are valid; observed conflicts are expected (regular $HOME files that backup_conflicts() will handle at runtime).

## Issues Encountered
- GNU Stow was not installed on this machine at plan start (expected — it's in the Brewfile that plan 01-03 will create). Installed it manually during Task 2 verification to run stow --simulate. Install confirmed stow 2.4.1 (exceeds minimum 2.4.0 requirement).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- install.sh is complete and passes all verification checks
- All 7 Stow packages have valid directory structures (verified by stow --simulate)
- GNU Stow 2.4.1 is now installed on this machine
- Ready for plan 01-03: Create curated Brewfile

---
*Phase: 01-foundation*
*Completed: 2026-02-28*
