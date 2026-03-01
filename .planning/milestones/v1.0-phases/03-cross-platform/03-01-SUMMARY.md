---
phase: 03-cross-platform
plan: 01
subsystem: infra
tags: [bash, install, platform-detection, linux, devcontainer, zsh, stow, antidote, starship, fzf]

# Dependency graph
requires:
  - phase: 01-foundation
    provides: install.sh with Homebrew/Stow/Brewfile macOS setup
  - phase: 02-shell
    provides: antidote zsh plugin manager, zsh config structure

provides:
  - Cross-platform install.sh with platform detection (IS_MACOS/IS_LINUX)
  - Linux setup functions for zsh, stow, antidote, starship, fzf
  - Devcontainer-safe --force/-f flag skipping interactive prompt
  - stow_packages runs on both platforms with full PACKAGES array

affects: [future-linux-dotfiles, devcontainer-setup, codespaces]

# Tech tracking
tech-stack:
  added: []
  patterns:
    - "Platform detection via uname: PLATFORM/IS_MACOS/IS_LINUX boolean flags gate all platform-specific logic"
    - "if $IS_MACOS / elif $IS_LINUX branching in main() with shared stow_packages call"
    - "Linux apt-get installs with root/sudo/graceful-fallback chain"
    - "fzf --bin install: binary only, no shell config (our .zshrc handles integration)"

key-files:
  created: []
  modified:
    - install.sh

key-decisions:
  - "fzf --bin flag: installs binary only, our .zshrc handles shell integration via source <(fzf --zsh)"
  - "stow ALL packages on Linux: config files are lightweight, missing binaries degrade gracefully"
  - "linux_install_starship uses curl installer to ~/.local/bin (no apt package, always latest)"
  - "linux_install_antidote uses git clone --depth=1 to ~/.antidote (no Homebrew path on Linux)"

patterns-established:
  - "if $IS_MACOS / elif $IS_LINUX: platform branching pattern for any future platform-specific logic"
  - "apt-get install with root check then sudo fallback then graceful fail: Linux package install pattern"

requirements-completed: [PLAT-01, PLAT-02, PLAT-04]

# Metrics
duration: 1min
completed: 2026-02-28
---

# Phase 3 Plan 01: Cross-Platform Installer Summary

**Single install.sh with uname-based platform detection routing macOS to Homebrew path and Linux to apt+curl path, with all packages stowed on both platforms**

## Performance

- **Duration:** 1 min
- **Started:** 2026-02-28T19:56:35Z
- **Completed:** 2026-02-28T19:57:55Z
- **Tasks:** 1 of 1
- **Files modified:** 1

## Accomplishments

- Added platform detection block (PLATFORM/IS_MACOS/IS_LINUX) after Helpers section using `/usr/bin/uname`
- Added five Linux setup functions: `linux_require_zsh`, `linux_require_stow`, `linux_install_antidote`, `linux_install_starship`, `linux_install_fzf`
- Updated `main()` to branch by platform: macOS runs Homebrew path unchanged, Linux runs linux_* functions, `stow_packages` runs unconditionally on both
- Done message now shows `$PLATFORM` for clarity during bootstrap

## Task Commits

Each task was committed atomically:

1. **Task 1: Add platform detection and Linux setup functions to install.sh** - `50b040c` (feat)

**Plan metadata:** _(docs commit pending)_

## Files Created/Modified

- `install.sh` - Added platform detection, five Linux setup functions, platform-branched main()

## Decisions Made

- `fzf --bin` flag used: installs only the fzf binary without modifying shell configs — our `.zshrc` already handles integration via `source <(fzf --zsh)`
- All packages stowed on both platforms per user decision: config files are lightweight, missing binaries on Linux just degrade gracefully (no errors)
- `linux_install_starship` uses the official curl installer to `~/.local/bin` with `-y` flag to skip prompts (devcontainer-safe)
- `linux_install_antidote` uses `git clone --depth=1` to `~/.antidote` (no Homebrew available on Linux)
- apt-get install pattern: check root via `$(id -u) -eq 0`, then sudo fallback, then graceful failure — works in devcontainers (often root) and servers (need sudo)

## Deviations from Plan

None — plan executed exactly as written.

## Issues Encountered

None.

## User Setup Required

None — no external service configuration required.

## Next Phase Readiness

- install.sh now serves both macOS and Linux/devcontainer environments from a single entry point
- Linux path installs a full shell experience: zsh, stow, antidote, starship, fzf
- macOS path is unchanged — no regression
- Ready for Phase 3 Plan 02 (shell config Linux compatibility: platform guards in .aliases, .functions, .zshrc antidote path)

---
*Phase: 03-cross-platform*
*Completed: 2026-02-28*
