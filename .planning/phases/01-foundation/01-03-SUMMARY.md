---
phase: 01-foundation
plan: 03
subsystem: package-management
tags: [brewfile, homebrew, packages, stow]
dependency_graph:
  requires: [01-01, 01-02]
  provides: [Brewfile]
  affects: [install.sh, 02-shell]
tech_stack:
  added: []
  patterns: [brew-bundle, organized-sections]
key_files:
  created: [Brewfile]
  modified: []
  deleted: [install/Brewfile]
decisions:
  - "netbird requires tap netbirdio/tap — added to Brewfile"
  - "brew bundle check fails (packages not installed yet) — expected; Brewfile is declaration for fresh installs"
  - "spotify and signal removed per user request; arc, mac-mouse-fix, netbird added"
metrics:
  duration: ~5min
  completed: 2026-02-28
---

# Phase 1 Plan 3: Brewfile Curation Summary

**One-liner:** Curated Brewfile with user-approved packages in organized sections, replacing deprecated-tap-laden install/Brewfile.

## What Was Built

A clean top-level `Brewfile` replacing the old `install/Brewfile`. The new file:

- Organized into labeled sections: Taps, CLI Tools, Shell, Development, Apps, Fonts
- Removes all deprecated taps (homebrew/bundle, homebrew/cask, homebrew/core, homebrew/cask-fonts, homebrew/cask-versions)
- Includes `brew "stow"` (required for dotfiles management)
- Contains no `mas` entries
- Adds `tap "netbirdio/tap"` for netbird cask availability

## Tasks Completed

| Task | Name | Commit | Files |
|------|------|--------|-------|
| 1 | Audit current machine state | (no file change) | /tmp/Brewfile.current |
| 2 | User approves Brewfile package list | (checkpoint decision) | — |
| 3 | Write final Brewfile and remove old install/Brewfile | 2f3beaf | Brewfile, install/Brewfile |

## Decisions Made

1. **netbird tap required:** `brew info netbird` returns no formula — tap `netbirdio/tap` is needed. Added to Brewfile.
2. **brew bundle check fails on this machine:** Packages not installed on current machine (packages declared for fresh installs). This is expected behavior — `install.sh` runs `brew bundle install` during bootstrap.
3. **User modifications applied:** Removed `spotify`, `signal`; added `arc`, `mac-mouse-fix` (cask), `netbird` (via tap).

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 2 - Missing] netbirdio/tap added for netbird**
- **Found during:** Task 3
- **Issue:** `netbird` cask not available without custom tap
- **Fix:** Added `tap "netbirdio/tap"` to Taps section
- **Files modified:** Brewfile
- **Commit:** 2f3beaf

### Scope Note

`brew bundle check` fails because packages are not installed on the current machine. This is not a Brewfile error — the file is correct and will be used by `install.sh` to install packages on a fresh machine. The plan's verification step assumed packages were pre-installed; they are not on this machine.

## Self-Check: PASSED

- [x] Brewfile exists at /Users/italovietro/.dotfiles/Brewfile
- [x] install/Brewfile removed
- [x] stow in Brewfile
- [x] No deprecated taps
- [x] No mas entries
- [x] Commit 2f3beaf exists
