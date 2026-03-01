# Phase 3: Cross-Platform - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

One install.sh that serves a fresh Mac and a Linux server/devcontainer. The shell works correctly in both environments. Platform detection routes to macOS-full or Linux-minimal setup paths.

</domain>

<decisions>
## Implementation Decisions

### Linux scope
- Target environments: Cursor devcontainers AND remote Linux servers (no Linux desktop)
- No Homebrew/Linuxbrew on Linux — Brewfile is macOS-only
- UI/GUI tooling is macOS-only; Linux gets only shell/CLI config
- Work without sudo when possible — use sudo when available, fall back to user-local installs when not
- zsh required — install via apt if missing; if can't install (no sudo), stow git config and exit gracefully

### Package partitioning
- Stow ALL packages on both platforms — config files are lightweight, tools degrade gracefully if binary isn't installed
- One Brewfile, macOS-only — no split, no Linuxbrew
- Antidote on Linux: Claude's discretion (git clone to ~/.antidote or similar — no Homebrew path available)
- zsh only, install if missing — no bash fallback

### macOS guard strategy
- Silent skip — macOS-only aliases/functions simply don't get defined on Linux (no errors, no warnings)
- Platform block pattern — one `if [[ $(uname) == Darwin ]]; then ... fi` wrapping all macOS-specific aliases, not per-command checks
- Guard .functions too — macOS-specific functions (pbcopy, open, Finder) wrapped in platform checks; cross-platform functions stay global
- Platform-aware antidote path in .zshrc — macOS uses `brew --prefix` path, Linux uses `~/.antidote` or equivalent

### Claude's Discretion
- Whether to install starship/fzf via apt/curl on Linux for a full shell experience, or let them degrade gracefully
- Antidote installation method on Linux (git clone path, update mechanism)
- Exact platform detection approach in install.sh (uname vs /etc/os-release vs both)
- How to handle the Homebrew fpath block in .zshrc on Linux (skip vs alternative)

</decisions>

<specifics>
## Specific Ideas

- The user's Linux use is servers and containers — lightweight, not desktop
- "The tooling with UI no need to install on Linux. The rest is just for Mac."
- install.sh should be the single entry point for both platforms

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 03-cross-platform*
*Context gathered: 2026-02-28*
