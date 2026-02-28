# Requirements: Dotfiles

**Defined:** 2026-02-28
**Core Value:** One command bootstraps a complete, consistent dev environment on a fresh Mac or Linux container.

## v1 Requirements

Requirements for initial release. Each maps to roadmap phases.

### Foundation

- [x] **FOUND-01**: Repo restructured into Stow packages (one dir per tool: zsh/, git/, tmux/, starship/, ghostty/, etc.)
- [x] **FOUND-02**: Install script uses `stow` to create symlinks instead of rsync file copying
- [x] **FOUND-03**: Install script is idempotent (safe to run multiple times)

### Shell

- [ ] **SHEL-01**: Oh My Zsh removed and replaced with antidote plugin manager
- [ ] **SHEL-02**: Plugins lazy-loaded via antidote (zsh-autosuggestions, zsh-syntax-highlighting)
- [ ] **SHEL-03**: Single `compinit` call after all fpath additions, correct zsh load order
- [ ] **SHEL-04**: `typeset -U PATH path` prevents PATH duplication across subshells
- [ ] **SHEL-05**: Starship prompt configured and loaded (already exists, migrate to Stow package)
- [ ] **SHEL-06**: fzf shell integration (Ctrl+R history search, Ctrl+T file finder)

### Packages

- [x] **PKGS-01**: Brewfile created with curated list of brews, casks, and taps (audited against current machine, user-approved)
- [x] **PKGS-02**: `brew bundle` integrated into macOS install path
- [ ] **PKGS-03**: `bin/dot` update command (brew update + antidote update + stow restow)

### Cross-Platform

- [ ] **PLAT-01**: Install script detects platform (macOS vs Linux) and branches accordingly
- [ ] **PLAT-02**: Linux install path: installs stow + stows shell and git packages only
- [ ] **PLAT-03**: `command -v` guards on macOS-specific aliases and functions
- [ ] **PLAT-04**: install.sh compatible with Cursor devcontainers and GitHub Codespaces auto-dotfiles

### Tool Configs

- [ ] **TOOL-01**: Ghostty config Stow-managed under `.config/ghostty/`
- [ ] **TOOL-02**: tmux config with TPM plugin manager, tmux-resurrect, tmux-continuum
- [x] **TOOL-03**: Git config (signing key, aliases, global gitignore) as Stow package
- [x] **TOOL-04**: macOS defaults script audited for Sequoia compatibility

## v2 Requirements

Deferred to future release. Tracked but not in current roadmap.

### Quality of Life

- **QOL-01**: Modern CLI aliases (eza for ls, bat for cat, fd for find)
- **QOL-02**: Shell startup time benchmarking (before/after measurement)
- **QOL-03**: `.devcontainer.json` template with dotfiles repo reference
- **QOL-04**: Stow `--adopt` workflow documentation for pulling machine state into repo
- **QOL-05**: Automated conflict detection and resolution on stow

## Out of Scope

| Feature | Reason |
|---------|--------|
| Neovim/Vim config | Not part of current workflow |
| VS Code settings | Using Cursor, which syncs its own settings |
| Secrets/credentials in repo | Handled by 1Password; `.extra` pattern for local overrides |
| Nix/Home Manager | Overkill for plaintext config management; high complexity for marginal gain |
| chezmoi | Templating/secrets features not needed; GNU Stow is simpler for this use case |
| Linux GUI app installation | Containers are shell-only |
| CI/CD pipeline | Defer until install script is stable and trustworthy |

## Traceability

Which phases cover which requirements. Updated during roadmap creation.

| Requirement | Phase | Status |
|-------------|-------|--------|
| FOUND-01 | Phase 1 | Complete |
| FOUND-02 | Phase 1 | Complete |
| FOUND-03 | Phase 1 | Complete |
| SHEL-01 | Phase 2 | Pending |
| SHEL-02 | Phase 2 | Pending |
| SHEL-03 | Phase 2 | Pending |
| SHEL-04 | Phase 2 | Pending |
| SHEL-05 | Phase 2 | Pending |
| SHEL-06 | Phase 2 | Pending |
| PKGS-01 | Phase 1 | Complete |
| PKGS-02 | Phase 1 | Complete |
| PKGS-03 | Phase 4 | Pending |
| PLAT-01 | Phase 3 | Pending |
| PLAT-02 | Phase 3 | Pending |
| PLAT-03 | Phase 3 | Pending |
| PLAT-04 | Phase 3 | Pending |
| TOOL-01 | Phase 4 | Pending |
| TOOL-02 | Phase 4 | Pending |
| TOOL-03 | Phase 1 | Complete |
| TOOL-04 | Phase 1 | Complete |

**Coverage:**
- v1 requirements: 20 total
- Mapped to phases: 20
- Unmapped: 0

---
*Requirements defined: 2026-02-28*
*Last updated: 2026-02-28 after roadmap creation*
