---
phase: 01-foundation
plan: "04"
subsystem: infra
tags: [git, gitconfig, gitignore, macos, defaults, sequoia]

# Dependency graph
requires:
  - phase: 01-01
    provides: git/ Stow package structure with .gitconfig and .gitignore_global in place
provides:
  - git/.gitconfig verified with signing key, aliases, and symlink-safe excludesfile path
  - git/.gitignore_global covering OS/editor/runtime artifacts including Windows
  - macos.sh as a clean, Sequoia-compatible standalone defaults script
affects: [02-shell, 03-tooling, install.sh]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "macos.sh as separate standalone script (not sourced by install.sh)"
    - "Global gitignore via core.excludesfile = ~/.gitignore_global (tilde-based, symlink-safe)"

key-files:
  created:
    - "macos.sh (replaced install-wrapper content with clean Sequoia defaults script)"
  modified:
    - "git/.gitignore_global (added Windows artifacts: Thumbs.db, ehthumbs.db, Desktop.ini)"
  deleted:
    - ".macos (consolidated into macos.sh, removed with git rm)"

key-decisions:
  - ".macos consolidated into macos.sh; old install-wrapper content in macos.sh was replaced because plan 01-RESEARCH.md confirms macos.sh should be the standalone defaults script separate from install.sh"
  - "All Tahoe 26.0 Beta references removed (Stage Manager note, LiveActivities, Tahoe comments) -- these were AI-generated future-macOS content incompatible with Sequoia"
  - "osascript target changed from 'System Preferences' to 'System Settings' (renamed in macOS Ventura+)"

patterns-established:
  - "macos.sh: standalone script, bash shebang, Sequoia header comment, run manually after install.sh"
  - "Global gitignore uses tilde path (~/.gitignore_global) for portability across machines when symlinked"

requirements-completed: [TOOL-03, TOOL-04]

# Metrics
duration: 2min
completed: 2026-02-28
---

# Phase 1 Plan 4: Git Config and macOS Defaults Audit Summary

**git/.gitconfig verified with GPG signing + global gitignore; .macos consolidated into a clean Sequoia-compatible macos.sh with all Tahoe 26.0 Beta references removed**

## Performance

- **Duration:** 2 min
- **Started:** 2026-02-28T12:33:51Z
- **Completed:** 2026-02-28T12:36:01Z
- **Tasks:** 2
- **Files modified:** 3 (git/.gitignore_global modified, macos.sh replaced, .macos deleted)

## Accomplishments
- Confirmed git/.gitconfig is correct: signing key (5CB8AEE431026C4C), gpgsign=true, core.excludesfile=~/.gitignore_global (tilde-based path survives symlink)
- Added Windows OS artifacts (Thumbs.db, ehthumbs.db, Desktop.ini) to git/.gitignore_global
- Replaced the install-wrapper macos.sh with a clean, Sequoia-compatible macOS defaults script
- Removed .macos (consolidated) and stripped all Tahoe 26.0 Beta references from the new macos.sh

## Task Commits

Each task was committed atomically:

1. **Task 1: Verify and finalize Git config in git/ Stow package** - `3cec00e` (chore)
2. **Task 2: Audit and clean macOS defaults script for Sequoia compatibility** - `dad61e2` (chore)

**Plan metadata:** _(final commit pending)_

## Files Created/Modified
- `git/.gitconfig` - Verified (no changes needed): signing key, gpgsign, excludesfile all correct
- `git/.gitignore_global` - Added Windows artifacts (Thumbs.db, ehthumbs.db, Desktop.ini)
- `macos.sh` - Replaced with clean Sequoia-compatible defaults script (was install wrapper)
- `.macos` - Deleted (consolidated into macos.sh)

## Decisions Made
- Replaced the entire `macos.sh` install-wrapper script with the cleaned macOS defaults content from `.macos`. The old `macos.sh` was an install script that called `brew tap homebrew/bundle`, `brew upgrade`, and sourced `.macos` — all deprecated/anti-patterns per RESEARCH.md. The new `macos.sh` is the standalone defaults script as intended by CONTEXT.md.
- Removed `WindowManager` Stage Manager entry — this was Tahoe-specific, not valid on Sequoia.
- Removed `LiveActivities` control center entry — also Tahoe-specific.
- Kept trackpad click/right-click defaults (valid on Sequoia, removed Tahoe comment framing).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing Critical] Added Windows artifacts to .gitignore_global**
- **Found during:** Task 1 (audit of git/.gitignore_global)
- **Issue:** Plan specified OS artifacts coverage but Thumbs.db (Windows) was absent
- **Fix:** Added Thumbs.db, ehthumbs.db, Desktop.ini under a "# Windows" comment section
- **Files modified:** git/.gitignore_global
- **Verification:** grep confirms Thumbs.db present
- **Committed in:** 3cec00e (Task 1 commit)

---

**Total deviations:** 1 auto-fixed (1 missing critical pattern)
**Impact on plan:** Minor addition for completeness. No scope creep.

## Issues Encountered
- The current `macos.sh` was an install-wrapper script (not the defaults script) that sourced `.macos`. The plan asked to audit `macos.sh` for Sequoia compatibility, but the actual defaults were in `.macos`. Resolved by consolidating `.macos` into `macos.sh` as the plan specified in the action section (step 4).

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- git/ Stow package is complete: .gitconfig and .gitignore_global are ready for stow deployment
- macos.sh is ready to run manually after install.sh on a fresh Mac
- install.sh still uses rsync (not Stow) - this will be addressed in the install.sh rewrite plan

---
*Phase: 01-foundation*
*Completed: 2026-02-28*
