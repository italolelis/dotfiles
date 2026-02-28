# Phase 2: Shell - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Remove Oh My Zsh, replace with antidote plugin manager, establish clean zsh load order with fast startup (<500ms). Starship prompt migrated to Stow package. fzf shell integration added. No new shell capabilities beyond what's scoped.

</domain>

<decisions>
## Implementation Decisions

### Plugin inventory
- Keep OMZ git plugin aliases (gst, gco, gp, gl, etc.) — load via antidote's OMZ plugin support
- Keep gh CLI completions via antidote
- Keep docker completions via antidote
- Drop kubectl completions and plugin entirely
- Add zsh-history-substring-search (up-arrow history filtering)
- Core plugins: zsh-autosuggestions, zsh-syntax-highlighting (lazy-loaded via antidote)

### Shell file layout
- .zsh_plugins.txt lives inside zsh/ Stow package (symlinked to ~/.zsh_plugins.txt)
- Keep .extra file pattern for local/machine-specific overrides (not committed)
- Git aliases sourced from OMZ git lib via antidote (not a standalone plugin)
- Claude's discretion on whether to keep multi-file split or consolidate

### OMZ feature replacement
- Add directory stack setopts (AUTO_PUSHD, PUSHD_SILENT, etc.) — lightweight, user may use them
- No auto-correction (setopt CORRECT disabled — user finds it annoying)
- Styled completions: case-insensitive matching, colored, grouped menu — replicate OMZ's zstyle settings
- Remove SSH agent management block entirely — 1Password SSH agent handles this now
- Remove Warp terminal integration block from .zshrc

### Alias housekeeping
- Remove Warp terminal aliases (w, wd) and .zshrc Warp integration block
- Drop kubectl aliases (k, kctx, kns) — consistent with dropping kubectl completions
- Simplify 'update' alias to just brew update + cleanup (Phase 4 'dot' command will be the real updater)
- Clean up broken utilities (e.g., urlencode uses Python 2 syntax) during migration

### Claude's Discretion
- Shell file organization (keep multi-file split vs consolidate)
- Exact antidote lazy-loading configuration
- compinit placement and optimization
- History settings (current setopt block is reasonable, adjust if needed)
- Any other cleanup of stale/dead code in dotfiles during migration

</decisions>

<specifics>
## Specific Ideas

- OMZ git plugin loaded through antidote's OMZ compatibility (not full OMZ framework)
- 1Password is the SSH agent — no custom SSH agent code needed
- Ghostty is the terminal now — all Warp references are dead weight
- Docker aliases (dc, dcu, dcd) stay; kubectl aliases go

</specifics>

<deferred>
## Deferred Ideas

- Modern CLI aliases (eza for ls, bat for cat, fd for find) — tracked as QOL-01 in v2 requirements
- 'dot' update command replacing the update alias — Phase 4
- Ghostty config management — Phase 4

</deferred>

---

*Phase: 02-shell*
*Context gathered: 2026-02-28*
