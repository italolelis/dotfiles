# Roadmap: Dotfiles

## Overview

Modernize an existing dotfiles repo from rsync-based file copying to a symlink-managed, cross-platform dev environment. Four phases with hard ordering: establish the Stow symlink foundation first (eliminating config drift), then migrate the shell stack off Oh My Zsh, then extend cross-platform support to Linux and devcontainers, then bolt on daily-use enhancements. Each phase exits with a verifiable state before the next begins.

## Phases

**Phase Numbering:**
- Integer phases (1, 2, 3): Planned milestone work
- Decimal phases (2.1, 2.2): Urgent insertions (marked with INSERTED)

- [ ] **Phase 1: Foundation** - Stow-based symlink structure, Brewfile audit, Git and macOS defaults configs in place
- [ ] **Phase 2: Shell** - Oh My Zsh removed, antidote plugin manager live, clean zsh load order
- [ ] **Phase 3: Cross-Platform** - Single install.sh serving macOS and Linux/devcontainers
- [ ] **Phase 4: Polish** - dot update command, Ghostty config, tmux + TPM

## Phase Details

### Phase 1: Foundation
**Goal**: All dotfiles are symlink-managed via GNU Stow, with no config drift between the repo and the running machine
**Depends on**: Nothing (first phase)
**Requirements**: FOUND-01, FOUND-02, FOUND-03, PKGS-01, PKGS-02, TOOL-03, TOOL-04
**Success Criteria** (what must be TRUE):
  1. Running `ls -la ~` shows dotfile targets as symlinks pointing into `~/.dotfiles/`, not regular files
  2. Running `install.sh` twice in a row produces no errors and no duplicate entries
  3. Running `brew bundle check` passes with no missing packages
  4. Git config (signing key, aliases, global gitignore) is loaded and working in a fresh shell
  5. macOS defaults script runs without errors on Sequoia
**Plans**: TBD

Plans:
- [ ] 01-01: Restructure repo into Stow packages and audit configs for secrets
- [ ] 01-02: Replace rsync install script with idempotent Stow-based install.sh
- [ ] 01-03: Reconcile Brewfile with current machine state and integrate brew bundle
- [ ] 01-04: Migrate Git config and macOS defaults into Stow packages, audit Sequoia compatibility

### Phase 2: Shell
**Goal**: The zsh environment loads fast, with clean plugin management via antidote and no Oh My Zsh remnants
**Depends on**: Phase 1
**Requirements**: SHEL-01, SHEL-02, SHEL-03, SHEL-04, SHEL-05, SHEL-06
**Success Criteria** (what must be TRUE):
  1. Opening a new terminal shows Starship prompt with no OMZ banner or references
  2. Tab completion, syntax highlighting, and autosuggestions work on first keypress in a fresh shell
  3. `echo $PATH` in a new shell shows no duplicate entries
  4. `Ctrl+R` opens fzf history search; `Ctrl+T` opens fzf file finder
  5. `time zsh -i -c exit` completes in under 500ms
**Plans**: TBD

Plans:
- [ ] 02-01: Remove Oh My Zsh, install antidote, migrate plugins to .zsh_plugins.txt
- [ ] 02-02: Fix zsh load order (path → exports → aliases → functions → extra), compinit once, typeset -U PATH
- [ ] 02-03: Migrate Starship config to Stow package, add fzf shell integration

### Phase 3: Cross-Platform
**Goal**: One install.sh serves a fresh Mac and a Linux devcontainer; the shell works correctly in both environments
**Depends on**: Phase 2
**Requirements**: PLAT-01, PLAT-02, PLAT-03, PLAT-04
**Success Criteria** (what must be TRUE):
  1. Running install.sh on macOS completes the full setup (Homebrew, Stow, all packages)
  2. Running install.sh in a Linux container stows only shell and git packages with no errors
  3. Opening a shell in a Cursor devcontainer shows a working Starship prompt with no alias errors
  4. macOS-only aliases (brew, mas, etc.) do not error when run in a Linux container
**Plans**: TBD

Plans:
- [ ] 03-01: Add uname-based platform detection to install.sh, create linux.sh sub-script
- [ ] 03-02: Add command -v guards to macOS-specific aliases and functions, validate devcontainer path

### Phase 4: Polish
**Goal**: Daily workflow is enhanced with a dot update command, Ghostty config, and tmux session persistence
**Depends on**: Phase 3
**Requirements**: PKGS-03, TOOL-01, TOOL-02
**Success Criteria** (what must be TRUE):
  1. Running `dot` pulls latest changes, restows all packages, and updates antidote and Homebrew
  2. Ghostty launches with personal config applied (font, keybindings, colors)
  3. Tmux sessions survive terminal restart and are restored automatically via tmux-continuum
**Plans**: TBD

Plans:
- [ ] 04-01: Create bin/dot update command (git pull + stow --restow + brew update + antidote update)
- [ ] 04-02: Stow-manage Ghostty config under .config/ghostty/
- [ ] 04-03: Add TPM to tmux config, configure tmux-resurrect and tmux-continuum

## Progress

**Execution Order:**
Phases execute in numeric order: 1 → 2 → 3 → 4

| Phase | Plans Complete | Status | Completed |
|-------|----------------|--------|-----------|
| 1. Foundation | 0/4 | Not started | - |
| 2. Shell | 0/3 | Not started | - |
| 3. Cross-Platform | 0/2 | Not started | - |
| 4. Polish | 0/3 | Not started | - |
