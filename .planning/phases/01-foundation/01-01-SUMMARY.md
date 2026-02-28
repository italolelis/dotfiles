---
phase: 01-foundation
plan: 01
subsystem: infra
tags: [stow, dotfiles, symlinks, git, ssh, gitignore]

# Dependency graph
requires: []
provides:
  - "7 GNU Stow package directories: zsh/, git/, tmux/, starship/, ghostty/, ssh/, misc/"
  - "All tracked dotfiles moved into per-tool packages with git mv (history preserved)"
  - "ghostty/.config/ghostty/config mirrors XDG path layout for Stow symlinking"
  - "ssh/.ssh/config in correct nested path for Stow symlinking"
  - ".gitignore blocking .DS_Store, .backup/, and editor artifacts"
  - "ssh/.stow-local-ignore blocking all private key patterns from being stowed"
affects:
  - "02-shell"
  - "01-02-PLAN"
  - "01-03-PLAN"
  - "01-04-PLAN"

# Tech tracking
tech-stack:
  added: [GNU Stow package structure]
  patterns: [per-tool package dirs mirroring $HOME paths, XDG path mirroring for ghostty]

key-files:
  created:
    - ".gitignore"
    - "ssh/.stow-local-ignore"
  modified:
    - "zsh/.zshrc (moved from .zshrc)"
    - "zsh/.aliases (moved from .aliases)"
    - "zsh/.functions (moved from .functions)"
    - "zsh/.exports (moved from .exports)"
    - "zsh/.path (moved from .path)"
    - "zsh/.extra (moved from .extra)"
    - "zsh/.zsh_completions (moved from .zsh_completions)"
    - "git/.gitconfig (moved from .gitconfig)"
    - "git/.gitignore_global (moved from .gitignore_global)"
    - "tmux/.tmux.conf (moved from .tmux.conf)"
    - "starship/.starship.toml (moved from .starship.toml)"
    - "ghostty/.config/ghostty/config (moved from .config/ghostty/config)"
    - "ssh/.ssh/config (moved from .ssh/config)"
    - "misc/.editorconfig (moved from .editorconfig)"
    - "misc/.inputrc (moved from .inputrc)"
    - "misc/.curlrc (moved from .curlrc)"
    - "misc/.wgetrc (moved from .wgetrc)"

key-decisions:
  - "Removed .stow-local-ignore from .gitignore: the entry would have blocked tracking ssh/.stow-local-ignore in git, defeating its purpose as a safety net shipped with the repo"
  - "gitleaks not yet installed; manual audit confirms .extra is template-only and .gitconfig signingkey (5CB8AEE431026C4C) is a public GPG key ID, not a secret"

patterns-established:
  - "Stow package layout: each tool gets a top-level directory named after the tool, with internal structure mirroring $HOME"
  - "XDG apps use nested path inside package: ghostty/.config/ghostty/ not ghostty/"
  - "SSH package uses .stow-local-ignore to prevent stowing private keys; this file is tracked in git"
  - "git mv used for all moves to preserve git history"

requirements-completed: [FOUND-01]

# Metrics
duration: 2min
completed: 2026-02-28
---

# Phase 1 Plan 01: Stow Package Restructure Summary

**Flat dotfiles repo restructured into 7 GNU Stow packages with git-history-preserving moves, .gitignore, and SSH private key safety net**

## Performance

- **Duration:** ~2 min
- **Started:** 2026-02-28T12:29:18Z
- **Completed:** 2026-02-28T12:31:04Z
- **Tasks:** 2
- **Files modified:** 17 moved + 2 created = 19 total

## Accomplishments
- Moved 17 tracked dotfiles from flat root into 7 per-tool Stow packages using git mv (history preserved)
- Ghostty config correctly placed at ghostty/.config/ghostty/config mirroring XDG $HOME path
- SSH config placed at ssh/.ssh/config with nested path for correct Stow symlinking
- Created .gitignore protecting the repo from .DS_Store, .backup/, and editor artifacts
- Created ssh/.stow-local-ignore blocking all private key patterns from being stowed
- Manual secrets audit confirmed no secrets in any tracked file

## Task Commits

Each task was committed atomically:

1. **Task 1: Create Stow package directories and move all tracked files** - `7f72e24` (feat)
2. **Task 2: Create .gitignore, ssh/.stow-local-ignore, and run gitleaks scan** - `471d6e6` (feat)

**Plan metadata:** (docs commit — see state updates below)

## Files Created/Modified
- `zsh/.zshrc` - Shell config entry point (moved from root)
- `zsh/.aliases` - Shell aliases (moved from root)
- `zsh/.functions` - Shell functions (moved from root)
- `zsh/.exports` - Environment exports (moved from root)
- `zsh/.path` - PATH configuration (moved from root)
- `zsh/.extra` - Machine-specific template (moved from root)
- `zsh/.zsh_completions` - Completions config (moved from root)
- `git/.gitconfig` - Git configuration with signing, aliases, global gitignore ref (moved from root)
- `git/.gitignore_global` - Global gitignore patterns (moved from root)
- `tmux/.tmux.conf` - Tmux configuration (moved from root)
- `starship/.starship.toml` - Starship prompt config (moved from root)
- `ghostty/.config/ghostty/config` - Ghostty terminal config in XDG layout (moved from .config/ghostty/)
- `ssh/.ssh/config` - SSH host config (moved from .ssh/)
- `misc/.editorconfig` - Editor-agnostic formatting rules (moved from root)
- `misc/.inputrc` - Readline config (moved from root)
- `misc/.curlrc` - curl defaults (moved from root)
- `misc/.wgetrc` - wget defaults (moved from root)
- `.gitignore` - Repo-level ignore rules (created)
- `ssh/.stow-local-ignore` - SSH package private key safety net (created)

## Decisions Made
- Removed `.stow-local-ignore` from `.gitignore`: the plan specified adding it, but this would prevent git from tracking `ssh/.stow-local-ignore` — the very file that acts as the private key safety net. GNU Stow already knows to skip its own `.stow-local-ignore` files; the git ignore was redundant and harmful.
- gitleaks not yet installed (not in Brewfile until plan 01-03). Manual audit performed: `.extra` is template-only (all real values commented out), `.gitconfig` `signingkey` is a public GPG key ID — not a secret.

## Deviations from Plan

### Auto-fixed Issues

**1. [Rule 1 - Bug] Removed .stow-local-ignore from .gitignore**
- **Found during:** Task 2 (Create .gitignore and ssh/.stow-local-ignore)
- **Issue:** The plan specified adding `.stow-local-ignore` to `.gitignore`, but this prevented git from staging `ssh/.stow-local-ignore`. The file needs to be tracked in git to ship the safety net with the repo. GNU Stow already ignores its own config files during symlinking — the git ignore was incorrect.
- **Fix:** Removed the `# Stow` / `.stow-local-ignore` section from `.gitignore`
- **Files modified:** `.gitignore`
- **Verification:** `git add ssh/.stow-local-ignore` succeeded after fix; file now tracked
- **Committed in:** `471d6e6` (Task 2 commit)

---

**Total deviations:** 1 auto-fixed (Rule 1 - bug in plan specification)
**Impact on plan:** Fix was necessary for correctness — without it, the SSH private key safety net would not be tracked in the repository. No scope creep.

## Issues Encountered
- gitleaks not installed — performed equivalent manual audit instead. Confirmed clean.

## User Setup Required
None - no external service configuration required.

## Next Phase Readiness
- All 7 Stow packages exist with correct internal layouts
- Git history preserved for all moved files
- Repo protected by .gitignore
- SSH safety net in place
- Ready for plan 01-02: Replace rsync install.sh with idempotent Stow-based installer

---
*Phase: 01-foundation*
*Completed: 2026-02-28*
