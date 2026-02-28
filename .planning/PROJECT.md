# Dotfiles

## What This Is

A portable, cross-platform dotfiles setup for macOS and Linux. Clone the repo, run one command, and get a fully configured development environment — Ghostty terminal, tmux, fast zsh with Starship prompt, modern CLI tools, and all personal configurations symlinked into place. Also works in Cursor devcontainers for a consistent shell experience anywhere.

## Core Value

One command bootstraps a complete, consistent dev environment on a fresh Mac or Linux container.

## Requirements

### Validated

(None yet — ship to validate)

### Active

- [ ] Brewfile-based package management for macOS (brews, casks, taps)
- [ ] Drop Oh My Zsh in favor of lightweight plugin manager (zinit or sheldon)
- [ ] Symlink-based dotfile management (GNU Stow or similar) replacing rsync copy
- [ ] Cross-platform install script (macOS full setup + Linux shell/git essentials)
- [ ] Devcontainer support for Cursor (auto-install dotfiles in containers)
- [ ] Modernized zsh config with lazy-loaded plugins (autosuggestions, syntax-highlighting)
- [ ] Ghostty terminal configuration
- [ ] tmux configuration
- [ ] Starship prompt configuration
- [ ] Git configuration (signing, aliases, global gitignore)
- [ ] Shell aliases and functions synced from current machine
- [ ] macOS system defaults script
- [ ] Audit and update all configs to match current machine state (fix config drift)

### Out of Scope

- Neovim/Vim config — not part of current workflow
- VS Code settings — using Cursor instead, which syncs its own settings
- Secrets/credentials management — handled separately (1Password, etc.)
- Linux GUI app installation — containers are shell-only

## Context

- Current repo has config drift: files in repo don't match what's actually on the machine
- Install script uses rsync (copies files) instead of symlinks — edits in ~ don't flow back
- Oh My Zsh adds startup overhead; modern approach is plugin managers with lazy loading
- Daily workflow: Ghostty + tmux + Claude CLI + Cursor
- Devcontainers need only shell + git config, not the full macOS setup
- Existing configs: .zshrc, .aliases, .functions, .exports, .path, .extra, .gitconfig, .starship.toml, .tmux.conf, .macos, .curlrc, .wgetrc, .editorconfig, .inputrc

## Constraints

- **Cross-platform**: Must work on both macOS (full) and Linux/devcontainers (shell essentials)
- **Idempotent**: Install script must be safe to run multiple times
- **No secrets in repo**: .extra pattern for machine-specific/sensitive values
- **Backward compatible**: Existing shell workflow shouldn't break during migration

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| Brewfile over script-based installs | Declarative, diffable, one-command install | — Pending |
| Drop Oh My Zsh for lightweight plugin manager | Faster startup, less bloat, same plugins | — Pending |
| Symlinks over rsync | True single source of truth, edits flow both ways | — Pending |
| Platform detection in install script | One entry point, branches by OS | — Pending |

---
*Last updated: 2026-02-28 after initialization*
