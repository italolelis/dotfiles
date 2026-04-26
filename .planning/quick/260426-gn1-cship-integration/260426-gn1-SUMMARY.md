---
quick_id: 260426-gn1
slug: cship-integration
date: 2026-04-26
status: complete
---

# Quick Task 260426-gn1: cship integration — Summary

## Outcome

`cship` (Claude Code statusline renderer) is now managed by dotfiles, on par with starship.

## Verified pre-existing state

- `starship` 1.24.2 installed via Homebrew, in Brewfile
- `STARSHIP_CONFIG=$HOME/.starship.toml` exported in `zsh/.exports`
- `starship init zsh` wired in `zsh/.zshrc`
- Stow package `starship/.starship.toml` → `~/.starship.toml` already in place
- Claude Code `~/.claude/settings.json` already has `statusLine.command = "cship"`

## Changes applied

| File | Change |
|------|--------|
| `cship/.config/cship.toml` | New stow package — moved from existing `~/.config/cship.toml` (Tokyo Night theme, model/cost/context_bar/usage_limits modules) |
| `install.sh` | Added `install_cship()` (curl `https://cship.dev/install.sh \| bash`, idempotent); added `cship` to `PACKAGES` array; called from both macOS and Linux branches of `main()` |

## Verification

- `ls -la ~/.config/cship.toml` → symlink to `.dotfiles/cship/.config/cship.toml` ✓
- `cship --version` → `cship 1.5.1` ✓
- `cship explain` → resolves config from symlinked path ✓
- `bash -n install.sh` → syntax OK ✓
- `shellcheck install.sh` → clean ✓
- Backup of pre-existing regular file at `~/.backup/dotfiles_cship_20260426_120516/cship.toml`

## Reproducibility on a fresh machine

After `./install.sh`:
1. Homebrew installs starship (Brewfile)
2. `install_cship` curls the official cship installer (binary lands in `~/.local/bin`)
3. `stow_packages` materializes `~/.config/cship.toml` symlink
4. cship is a no-arg command on PATH; Claude Code statusLine just calls `cship`
5. cship reads its own config and (when starship is configured globally) the starship config for native modules

## Notes

- cship binary is not in Homebrew, so `cargo install cship` would also work but requires rust. The official curl installer was chosen because it matches how starship is bootstrapped on Linux in this repo and works without a rust toolchain.
- `~/.config/starship.toml` (a separate, non-symlinked starship preset file) is left untouched — it is not the file starship uses (`STARSHIP_CONFIG` overrides to `~/.starship.toml`).
- `zsh/.extra` deliberately not modified — contains an unredacted GITHUB_PAT in the working tree that was flagged separately; user is handling.
