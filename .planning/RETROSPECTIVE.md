# Project Retrospective

*A living document updated after each milestone. Lessons feed forward into future planning.*

## Milestone: v1.0 — MVP

**Shipped:** 2026-03-01
**Phases:** 4 | **Plans:** 12 | **Sessions:** ~8

### What Was Built
- 8 GNU Stow packages replacing rsync-based dotfile management
- antidote plugin manager replacing Oh My Zsh with lazy-loaded plugins
- Cross-platform install.sh serving macOS and Linux/devcontainers
- `dot` daily update command (pull + restow + antidote + brew)
- Ghostty config with Catppuccin Mocha, quick terminal, split keybindings
- tmux config with TPM, Catppuccin Mocha, session persistence (resurrect + continuum)

### What Worked
- Wave-based parallel execution: all 3 Phase 4 plans ran simultaneously, cutting wall-clock time by ~60%
- Human checkpoints at the end of each plan caught the missing `stow bin` symlink before it became a gap
- Research-before-plan pattern: RESEARCH.md identified critical pitfalls (TPM plugin ordering, Ghostty Accessibility requirement) that plans handled proactively
- YOLO mode with plan verification: automated checks caught issues without requiring manual approval at every step

### What Was Inefficient
- API connection errors caused 2-3 session restarts during Phase 2 execution, losing context each time
- Some executor agents produced checkpoint docs commits that weren't strictly necessary
- Phase 1-2 SUMMARY.md files lacked one-liner field, making milestone accomplishment extraction fail — had to extract manually

### Patterns Established
- Platform guard pattern: `if [[ $(uname -s) == Darwin ]]` blocks at end of file, not scattered
- `command -v` guard for optional binaries (starship, antidote, fzf) — degrades gracefully
- Stow package structure mirrors $HOME paths exactly (e.g., `ghostty/.config/ghostty/config`)
- Catppuccin Mocha as unified theme across terminal tools

### Key Lessons
1. Plugin ordering in tmux matters — catppuccin must be declared before resurrect/continuum or status-right gets overwritten
2. TPM self-bootstrap in .tmux.conf eliminates manual setup steps on fresh machines
3. `git pull --ff-only` in update scripts prevents accidental merge commits
4. antidote should manage plugin repos (not Homebrew formulae) to avoid version conflicts

### Cost Observations
- Model mix: ~20% opus (orchestration), ~80% sonnet (research, planning, execution, verification)
- Sessions: ~8 across 1 day
- Notable: Entire v1.0 milestone completed in a single day — 4 phases, 12 plans, 20 requirements

---

## Cross-Milestone Trends

### Process Evolution

| Milestone | Sessions | Phases | Key Change |
|-----------|----------|--------|------------|
| v1.0 | ~8 | 4 | Initial baseline — established GSD workflow patterns |

### Top Lessons (Verified Across Milestones)

1. Research before planning prevents rework — every pitfall caught in RESEARCH.md was handled in plans
2. Parallel wave execution scales well for independent plans
