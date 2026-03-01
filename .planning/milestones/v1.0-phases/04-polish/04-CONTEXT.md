# Phase 4: Polish - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Three independent daily-use enhancements: a `dot` update command (git pull + restow + brew/antidote update), Ghostty terminal config managed via Stow, and tmux with TPM plugin manager and session persistence. No new capabilities beyond what ROADMAP.md specifies.

</domain>

<decisions>
## Implementation Decisions

### dot command
- No specific discussion — Claude has discretion on implementation details
- Must cover: git pull, stow --restow, brew update + upgrade, antidote update
- Cross-platform: skip brew steps on Linux (reuse IS_MACOS/IS_LINUX pattern from install.sh)

### Ghostty config
- Migrate existing config from machine, enhance with Ghostty best practices
- Color scheme: Catppuccin Mocha
- Quick terminal (global hotkey dropdown) enabled
- Native tabs and splits enabled alongside tmux
- Font: Claude's discretion (pick best for dev terminal with Ghostty support)

### tmux setup
- Migrate existing config from machine, enhance with modern best practices
- Prefix key: Ctrl+a (screen-style)
- tmux handles splits and panes (not Ghostty) — works consistently across terminals and SSH
- Mouse mode enabled (click panes, scroll history, drag resize)
- Status bar: Claude's discretion (pick clean style that works with Catppuccin)
- Plugins: tmux-resurrect + tmux-continuum for session persistence (from requirements)
- TPM (Tmux Plugin Manager) for plugin management

### Claude's Discretion
- Font choice for Ghostty
- tmux status bar design (clean, works with Catppuccin)
- dot command flags and output style
- Ghostty keybindings beyond quick terminal
- tmux keybindings beyond prefix change
- Additional tmux plugins if they improve the experience

</decisions>

<specifics>
## Specific Ideas

- Both Ghostty and tmux configs should be migrated from existing machine state, then improved with best practices
- Catppuccin Mocha should be consistent across Ghostty and tmux if possible
- tmux is the primary split/pane manager; Ghostty tabs/splits are supplementary (for quick access)

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 04-polish*
*Context gathered: 2026-02-28*
