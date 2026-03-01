# Phase 1: Foundation - Context

**Gathered:** 2026-02-28
**Status:** Ready for planning

<domain>
## Phase Boundary

Migrate the dotfiles repo from rsync-based file copying to GNU Stow symlink management. Restructure the repo into per-tool packages, replace install.sh with a Stow-based installer, create a curated Brewfile, and get Git and macOS defaults configs in place. This phase exits when all dotfiles are symlinked, Brewfile is populated, and the install script works idempotently.

</domain>

<decisions>
## Implementation Decisions

### Stow Package Structure
- One Stow package per tool: zsh/, git/, tmux/, starship/, ghostty/, ssh/
- All shell files (.zshrc, .aliases, .functions, .exports, .path, .extra, .zsh_completions) live in the zsh/ package — they're tightly coupled
- SSH config (hosts, options) stowed as ssh/ package; private keys excluded via .stow-local-ignore
- Ghostty config under ghostty/.config/ghostty/ to mirror XDG path

### Claude's Discretion: Misc Files
- Claude decides where to put "homeless" files (.editorconfig, .inputrc, .curlrc, .wgetrc) — likely a misc/ catch-all package

### Brewfile Curation
- Audit current machine installs and walk through category by category with user
- Include GUI apps as casks (Ghostty, Cursor, browsers, etc.)
- Skip Mac App Store apps — no `mas` integration
- Organize Brewfile into sections with comment headers (# Development, # CLI Tools, etc.)
- Do NOT blindly adopt current machine state — present what's installed, user approves/removes each category

### Install Script Behavior
- Step-by-step progress output: "Stowing zsh... done", "Stowing git... done" with status indicators
- Conflict handling: backup existing files to .backup/ directory, then create symlinks
- Confirmation prompt by default; --force flag skips confirmation (for automation/devcontainers)
- Auto-install Homebrew if not present (fresh Mac scenario)
- Idempotent: safe to run multiple times without errors or duplicate entries

### macOS Defaults
- Audit and trim the existing .macos script (~300 lines) — remove deprecated/irrelevant settings
- Priority categories: Finder & Desktop, Dock & Mission Control, Keyboard & Input, Security & Privacy
- macos.sh is a SEPARATE step from install.sh — run manually when ready
- Set up specific Dock layout with predetermined app arrangement (gather app list during implementation)
- Verify Sequoia compatibility for all remaining defaults

### Git Config
- Existing .gitconfig moves into git/ Stow package
- Global gitignore (.gitignore_global) included in git/ package

</decisions>

<specifics>
## Specific Ideas

- User wants the Brewfile walkthrough to be collaborative — "compare with what I have installed and suggest what to do" rather than blindly dumping
- Backup approach for conflicts: move to .backup/ dir so nothing is lost, user can review after install
- The --force flag is specifically for devcontainer/automation use — no interactive prompts in that path

</specifics>

<deferred>
## Deferred Ideas

None — discussion stayed within phase scope

</deferred>

---

*Phase: 01-foundation*
*Context gathered: 2026-02-28*
