# Dotfiles

## What This Is

A portable, cross-platform dotfiles setup for macOS and Linux. Clone the repo, run one command, and get a fully configured development environment — Ghostty terminal with Catppuccin Mocha, tmux with session persistence, fast zsh with antidote plugins and Starship prompt, curated Homebrew packages, and all personal configurations symlinked into place via GNU Stow. Also works in Cursor devcontainers for a consistent shell experience anywhere.

## Core Value

One command bootstraps a complete, consistent dev environment on a fresh Mac or Linux container.

## Requirements

### Validated

- ✓ Symlink-based dotfile management via GNU Stow (8 packages) — v1.0
- ✓ Brewfile-based package management for macOS (brews, casks, taps) — v1.0
- ✓ Idempotent install script safe to run multiple times — v1.0
- ✓ Oh My Zsh replaced with antidote plugin manager — v1.0
- ✓ Lazy-loaded zsh plugins (autosuggestions, syntax-highlighting) with clean load order — v1.0
- ✓ Cross-platform install script (macOS full setup + Linux shell/git essentials) — v1.0
- ✓ Devcontainer support for Cursor — v1.0
- ✓ Ghostty terminal configuration (Catppuccin Mocha, quick terminal, splits) — v1.0
- ✓ tmux configuration with TPM, session persistence (resurrect + continuum) — v1.0
- ✓ Starship prompt configuration — v1.0
- ✓ Git configuration (signing, aliases, global gitignore) — v1.0
- ✓ macOS system defaults script (Sequoia compatible) — v1.0
- ✓ Shell aliases and functions synced from current machine — v1.0
- ✓ `dot` update command (git pull + stow restow + antidote + brew) — v1.0

### Active

(None — start next milestone to define)

### Out of Scope

- Neovim/Vim config — not part of current workflow
- VS Code settings — using Cursor instead, which syncs its own settings
- Secrets/credentials management — handled separately (1Password, SSH agent)
- Linux GUI app installation — containers are shell-only
- Nix/Home Manager — overkill for plaintext config management
- CI/CD pipeline — defer until install script is stable and trustworthy

## Context

Shipped v1.0 with 1,139 LOC shell/config across 8 Stow packages.
Tech stack: GNU Stow 2.4, antidote, Starship, TPM, Homebrew Bundle.
Daily workflow: Ghostty + tmux + Claude CLI + Cursor.
Catppuccin Mocha theme consistent across Ghostty and tmux.

## Constraints

- **Cross-platform**: Must work on both macOS (full) and Linux/devcontainers (shell essentials)
- **Idempotent**: Install script must be safe to run multiple times
- **No secrets in repo**: .extra pattern for machine-specific/sensitive values
- **Stow structure**: All configs live in per-tool packages mirroring $HOME paths

## Key Decisions

| Decision | Rationale | Outcome |
|----------|-----------|---------|
| GNU Stow over rsync | True single source of truth, edits flow both ways | ✓ Good — zero config drift |
| Brewfile over script-based installs | Declarative, diffable, one-command install | ✓ Good — 60+ packages managed |
| antidote over Oh My Zsh | Faster startup, less bloat, static loading | ✓ Good — clean load order |
| Platform detection in install.sh | One entry point, branches by OS | ✓ Good — works macOS + Linux |
| Catppuccin Mocha everywhere | Visual consistency across terminal tools | ✓ Good — Ghostty + tmux unified |
| TPM self-bootstrap in .tmux.conf | Zero manual setup on fresh machine | ✓ Good — auto-installs plugins |
| `dot` at ~/.local/bin | Already on PATH, no .path changes needed | ✓ Good — clean integration |
| antidote update guarded with command -v | Works where antidote is binary, skips where it's sourced | ✓ Good — cross-platform safe |

---
*Last updated: 2026-03-01 after v1.0 milestone*
