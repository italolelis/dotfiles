# Project Research Summary

**Project:** Cross-platform dotfiles management (macOS + Linux/devcontainers)
**Domain:** Developer environment configuration management
**Researched:** 2026-02-28
**Confidence:** MEDIUM-HIGH

## Executive Summary

This project modernizes an existing dotfiles repo by replacing two broken conventions with well-established ones: rsync file-copying is replaced by GNU Stow symlink management, and Oh My Zsh is replaced by antidote (a lightweight zsh plugin manager) with Starship prompt. The core insight across all four research areas is that the existing repo already has the right files and the right ideas — the problem is in the mechanics of how they are deployed (rsync creates config drift) and how the shell is loaded (OMZ adds 200-400ms overhead and breaks the boundary between what belongs in the framework vs. the repo). The fix is structural, not a rewrite.

The recommended approach is a phased migration: first establish the Stow-based symlink foundation and audit current machine state vs. repo state (eliminating config drift), then migrate the zsh stack from OMZ to antidote and fix load order, then extend cross-platform support to Linux devcontainers, and finally bolt on quality-of-life enhancements. Each phase has a testable exit condition. The stack choices are conservative and justified: GNU Stow 2.4.0 (no state, no database, perfectly reversible), antidote (pure zsh, no binary dependencies, works in containers without Rust toolchain), Starship (shell-agnostic, actively maintained, Powerlevel10k is on life support as of mid-2025), Homebrew + Brewfile (declarative, diffable, one-command restore).

The primary risks are all front-loaded into Phase 1: secrets committed to git history during migration, Stow's `--adopt` flag silently overwriting curated repo files with machine state, and rsync-copied real files blocking symlink creation. These are not exotic failure modes — they are the default outcome if migration is done hastily. The mitigation is a deliberate file audit before any `git add`, a `stow --simulate` dry-run before any `stow` command, and explicit retirement of the rsync install path in the same phase where Stow is introduced. Once Phase 1 is clean, subsequent phases follow well-documented patterns with low ambiguity.

## Key Findings

### Recommended Stack

The stack is built around three core tool choices that work identically on macOS and Linux (or fall back gracefully when on Linux). GNU Stow 2.4.0 handles symlink management — the `--dotfiles` flag with directory support requires 2.x, and 2.4.0 fixes a known bug with that flag. antidote replaces Oh My Zsh as the zsh plugin manager: it is pure zsh (no compiled binary), generates a static plugin file for near-zero startup cost, supports deferred loading, and works in devcontainers without a Rust or Go toolchain. Starship replaces Powerlevel10k as the prompt — Powerlevel10k is on maintenance-only status as of June 2025 (author confirmed), Starship is shell-agnostic (future-proof if the user ever leaves zsh), and is actively maintained. All three are available via Homebrew on macOS and installable via standard Linux mechanisms.

**Core technologies:**
- GNU Stow 2.4.0: symlink management — simplest correct tool, no state, perfectly reversible, identical behavior on macOS and Linux
- antidote 1.x: zsh plugin manager — pure zsh (no binary dep), static plugin file, near-zero startup overhead, works in containers
- Starship v1.24.2: shell prompt — shell-agnostic, Rust-powered speed, single TOML config, active maintenance; replaces Powerlevel10k (life support)
- Homebrew + Brewfile: macOS package management — declarative, diffable, one-command restore via `brew bundle install`
- TPM (current HEAD): tmux plugin manager — de facto standard, bootstraps via git clone in install.sh
- tmux 3.6a: terminal multiplexer — already in use, no migration needed

**Key version notes:**
- GNU Stow must be 2.x (2.4.0 specifically fixes `--dotfiles` with directories)
- Powerlevel10k is explicitly NOT recommended for new setups
- zinit is NOT recommended as primary plugin manager (community-revived, uncertain maintenance, complex DSL)

### Expected Features

The feature research makes a strong distinction between what the repo must do (table stakes) and what would make it excellent (differentiators). The table stakes are all about correctness: symlinks so edits flow back to the repo, an idempotent install script that handles both macOS and Linux, platform detection that gates macOS-only tools, and all existing configs brought under proper symlink management. These are not optional — without them, the setup is not actually a dotfiles system, it is a file backup tool with no integrity guarantees.

**Must have (table stakes) — v1:**
- GNU Stow symlink management — without this, config drift is structural and unsolvable
- Idempotent cross-platform install script (macOS + Linux branches from single entry point)
- Drop Oh My Zsh, adopt antidote — measurably faster shell startup is the outcome, not just a preference
- Brewfile audit (current machine state reconciled with repo)
- Config audit (all current dotfiles reconciled and stowed)
- macOS defaults script audited for Sequoia compatibility
- Platform-conditional tool aliases (`command -v` guards on all modern tool aliases)

**Should have (competitive) — v1.x:**
- Devcontainer / GitHub Codespaces auto-install (install.sh as entry point per convention)
- `dot` update command (`bin/dot` wrapping `git pull && stow --restow`)
- fzf shell integration (Ctrl+R history, Ctrl+T file search, Alt+C dir jump)
- Modern CLI tool aliases (bat, eza, ripgrep, fd) with conditional loading
- Startup time benchmark documented in README

**Defer (v2+):**
- CI testing with GitHub Actions — valuable but not blocking daily use
- Topic-based modular directory structure — current flat Stow packages sufficient for this scope
- chezmoi-style multi-machine templating — `.extra` pattern handles machine differences for 1 Mac + containers

**Anti-features to explicitly avoid:**
- Nix / Home Manager — complete paradigm shift, overkill for stated scope
- Secrets in any tracked file — `.extra` is the secrets boundary, gitignored by convention
- Oh My Zsh running alongside antidote during migration — causes double overhead and `compinit` conflicts
- `stow --adopt` as the first step of migration — silently overwrites repo with machine state

### Architecture Approach

The architecture is a four-layer system: an entry point layer (`install.sh` with `uname`-based platform detection), a package management layer (Homebrew on macOS, apt on Linux), a symlink management layer (GNU Stow packages mapping to `$HOME`), and a shell runtime layer (`.zshrc` sourcing split files in correct order). Each Stow "package" is a top-level directory whose internal layout mirrors `$HOME` — `stow zsh` creates `~/.zshrc → ~/.dotfiles/zsh/.zshrc`. The `.extra` file is the one non-stowed file: machine-local, gitignored, sourced last so it can override anything. This is the secrets isolation boundary.

**Major components:**
1. `install.sh` — POSIX-compatible entry point; detects platform, installs stow, calls platform sub-script, stows packages
2. `macos.sh` — macOS-specific: Xcode CLI tools, Homebrew, `brew bundle`, `macos-defaults.sh`; never runs on Linux
3. `linux.sh` — Linux/container path: installs stow via apt, stows shell-essential packages only (zsh, git, misc)
4. Stow packages (zsh/, git/, tmux/, starship/, ghostty/, ssh/, misc/) — each mirrors `$HOME` structure; Linux containers stow a subset
5. `.zshrc` (shell runtime) — sources `.path → .exports → .aliases → .functions → .extra` in that order; loads antidote; evals Starship init synchronously
6. Brewfile — declarative macOS package manifest; lives at repo root, not in a Stow package; invoked by `macos.sh`

**Build order dependency (hard constraints):**
```
Xcode CLI Tools (macOS) → Homebrew → brew bundle → GNU Stow available → stow packages → shell restart
apt install stow (Linux) → GNU Stow available → stow packages → shell restart
```

### Critical Pitfalls

The top pitfalls are all migration-specific — they do not apply to a greenfield setup, but they are near-certain failure modes when migrating an existing rsync-based repo to Stow.

1. **Secrets committed to git during migration** — audit every file before `git add`; run `gitleaks detect` before first push; establish `.gitignore` with `.extra`, `.env`, `*secret*`, `*token*` before touching any files. Rotation is the only recovery if a credential is pushed.

2. **`stow --adopt` overwrites repo files with machine state** — never use `--adopt` without first committing or stashing repo state; prefer the safe manual pattern: copy file to Stow package dir → delete original from `$HOME` → run `stow <package>`; always run `stow --simulate` first.

3. **rsync copies blocking symlink creation** — old rsync-installed real files in `$HOME` cause `stow` to report CONFLICT and refuse to symlink; delete or back up real files before stowing; verify with `ls -la` that targets are symlinks (`->`) not regular files (`-rw-`).

4. **Zsh init file load order / PATH duplication** — `zshenv → zprofile → zshrc → zlogin` is non-obvious; macOS opens login shells by default so `/etc/zprofile` runs `path_helper` before your dotfiles; deduplicate with `typeset -U path PATH`; call `compinit` exactly once after all `fpath` additions.

5. **Plugin load order breaks lazy loading** — antidote/zinit deferred plugins execute from the zle context, which differs from normal init context; Starship init must be eager (never deferred); keybindings and `setopt` calls affecting input must also be non-deferred; test with `zsh -i -c 'zprof'` after any plugin order change.

## Implications for Roadmap

Based on the combined research, the work naturally groups into four phases with hard dependencies between them. The order is not stylistic — each phase is a prerequisite for the next.

### Phase 1: Foundation — Stow Migration and Config Audit

**Rationale:** Everything else depends on having a correct symlink-based foundation. The rsync-vs-symlink problem is not a detail; it is the core correctness issue. Until symlinks are in place, editing configs anywhere creates drift. This phase must also do the file audit to catch secrets before they are committed, which cannot be deferred.

**Delivers:**
- All existing configs stowed (symlinks verified with `ls -la`)
- Rsync install script retired and replaced with idempotent Stow-based `install.sh`
- Brewfile reconciled with current machine state (`brew bundle check` passes)
- macOS defaults script audited for Sequoia compatibility
- `.gitignore` includes `.extra`, `.env`, `*secret*`, `*token*`
- `gitleaks detect` passes before first push

**Addresses:** Symlink management, idempotent install script, Brewfile audit, config audit, platform detection skeleton

**Avoids:** Secrets in git history (audit before add), `--adopt` data loss (manual migration pattern), rsync copies blocking symlinks (retire rsync first), `.extra` not gitignored (`.gitignore` setup before any `git add`)

**Research flag:** No additional research needed. Stow patterns are well-documented and the current repo state is known.

---

### Phase 2: Shell Modernization — Drop OMZ, Adopt antidote

**Rationale:** Oh My Zsh cannot cleanly coexist with antidote — both touch `compinit`, both manage `fpath`, and both expect to own the plugin lifecycle. This must be a complete cutover in one phase, not an incremental migration. The load order pitfalls (PATH duplication, compinit called multiple times) are addressed here because they surface specifically when removing OMZ's abstraction layer.

**Delivers:**
- Oh My Zsh fully removed; no OMZ references in `.zshrc`
- antidote installed and managing zsh-autosuggestions, zsh-syntax-highlighting, zsh-completions
- Starship loaded synchronously (never deferred)
- `.zshrc` sourcing split files in correct order: `.path → .exports → .aliases → .functions → .extra`
- `typeset -U path PATH` in place; no duplicate PATH entries
- `compinit` called exactly once
- Shell startup time measured before and after (baseline + post-migration benchmark)
- Plugin load order verified with `zsh -i -c 'zprof'`; tab completion and keybindings work on first shell open

**Uses:** antidote 1.x, Starship v1.24.2, zsh-users/zsh-autosuggestions, zsh-users/zsh-syntax-highlighting, zsh-users/zsh-completions

**Implements:** Shell runtime layer (`.zshrc` sourcing order, plugin manager, Starship init)

**Avoids:** Running OMZ and antidote simultaneously (complete cutover), Starship deferred (eager init only), compinit called multiple times (one call, after all fpath additions)

**Research flag:** No additional research needed. antidote patterns are well-documented; Starship setup is straightforward.

---

### Phase 3: Cross-Platform Support — Linux and Devcontainer Paths

**Rationale:** Once the macOS shell config is clean and symlinked, extending to Linux is primarily about adding guards. The install script already needs a `detect_platform()` branch; this phase makes that branch fully functional and tested. Devcontainer support (Cursor, GitHub Codespaces) follows naturally since it uses the Linux path with one additional constraint: `install.sh` must be a real file, not a symlink.

**Delivers:**
- `install.sh` with full macOS and Linux branches using `uname` detection
- `linux.sh` sub-script for shell-essentials-only path (stows zsh, git, misc; skips ghostty, Brewfile)
- `command -v` guards on all aliases referencing modern CLI tools (bat, eza, rg, fd)
- `[[ "$(uname)" == "Darwin" ]]` guards on all macOS-specific zshrc blocks
- `install.sh` verified as real file (not symlink), executable (`chmod +x`)
- Cursor devcontainer tested: opens container, install.sh runs to completion, shell is functional
- antidote bootstrapped via git clone on Linux (no Brew required)
- Starship installed via `curl -sS https://starship.rs/install.sh | sh` on Linux

**Avoids:** macOS-only commands in shared scripts (all gated by platform detection), devcontainer install script being a symlink (Cursor devcontainer lifecycle breaks on symlinked scripts), missing tool aliases erroring in containers (`command -v` guards)

**Research flag:** Cursor devcontainer symlink behavior is LOW confidence (active bug thread, rapidly changing). May need to validate current Cursor version behavior before finalizing devcontainer support. This is the one area where research may be stale.

---

### Phase 4: Quality of Life — CLI Enhancements and Maintenance Tools

**Rationale:** Once the foundation is solid and cross-platform, add the features that make daily use excellent. These have no hard dependencies on each other and can be sequenced freely within the phase. The `dot` update command pays ongoing dividends (one command to stay current). fzf shell integration transforms daily workflow with minimal setup. Modern CLI tool aliases (bat, eza, rg, fd) require these tools to already be in the Brewfile (established in Phase 1) — so this phase adds only the alias wiring.

**Delivers:**
- `bin/dot` update command (`git pull && stow --restow` for each package)
- fzf shell integration sourced in `.zshrc` (Ctrl+R history, Ctrl+T file insert, Alt+C dir jump)
- Modern CLI tool aliases with conditional loading: bat→cat, eza→ls, rg→grep, fd→find
- tmux session persistence via tmux-resurrect and tmux-continuum (TPM)
- Startup time benchmark documented in README (`time zsh -i -c exit` result)

**Uses:** fzf (already in Brewfile), bat, eza, ripgrep, fd, tmux-resurrect, tmux-continuum

**Avoids:** Aliases for tools not in Brewfile (drift between alias definitions and installed packages), fzf integration sourced before fzf is installed (Brewfile must run first)

**Research flag:** No additional research needed. These are all well-documented, low-complexity additions.

---

### Phase Ordering Rationale

- **Phase 1 before all others:** Symlinks are the foundation. There is no correct version of any other phase if configs are being rsync-copied rather than symlinked. Config drift makes any shell changes uncertain — you cannot trust you are editing what is actually loaded.
- **Phase 2 before Phase 3:** The shell config must be clean and working on macOS before cross-platform testing. Debugging platform-conditional issues in a broken OMZ-to-antidote migration state is extremely difficult.
- **Phase 3 before Phase 4:** Conditional tool loading guards (established in Phase 3) are required before adding modern CLI tool aliases (Phase 4). Aliases without guards will error in Linux containers.
- **Phase 4 is independent:** Within Phase 4, tasks can be done in any order. The `dot` command, fzf integration, and modern aliases are independent of each other.

### Research Flags

Phases needing deeper research or validation during planning:
- **Phase 3 (Cursor devcontainer + symlinks):** The behavior of Cursor's devcontainer lifecycle with symlinked dotfiles is LOW confidence (based on an active forum thread with conflicting reports). Before implementing devcontainer support, test the current Cursor version to verify whether `install.sh` must be a real file or whether Cursor has resolved this. Check the Cursor forum thread status first.

Phases with well-documented patterns (no additional research needed):
- **Phase 1:** GNU Stow migration patterns are extensively documented across official docs and community sources.
- **Phase 2:** antidote setup, Starship init, and zsh load order are well-documented. The `compinit` single-call pattern is canonical.
- **Phase 4:** fzf integration, modern CLI aliases, and `bin/dot` patterns are standard dotfiles conventions.

## Confidence Assessment

| Area | Confidence | Notes |
|------|------------|-------|
| Stack | MEDIUM-HIGH | Core choices (Stow, antidote, Starship) verified across multiple sources. Powerlevel10k deprecation confirmed from 2025 article. antidote vs zinit benchmark from independent third-party benchmark repo. |
| Features | HIGH (core), MEDIUM (differentiators) | Table stakes features are universal and confirmed across multiple reference dotfiles repos. Differentiators based on community patterns (webpro/dotfiles, holman/dotfiles, mathiasbynens/dotfiles). |
| Architecture | HIGH | Patterns corroborated by official GNU Stow docs, multiple community sources, and direct inspection of the existing repo. Build order is deterministic. |
| Pitfalls | MEDIUM | Core pitfalls (secrets, `--adopt`, rsync conflicts, PATH duplication) confirmed across multiple sources. Cursor-specific devcontainer pitfall is LOW (active bug thread, rapidly changing product). |

**Overall confidence:** MEDIUM-HIGH

### Gaps to Address

- **Cursor devcontainer + symlinked install.sh:** Behavior is uncertain. Test empirically before Phase 3 planning. The fix (ensure install.sh is a real file, not symlinked) is simple if the issue is confirmed, but may not be necessary in current Cursor versions.
- **macOS Sequoia compatibility for `macos-defaults.sh`:** The current script was not audited against Sequoia during research. Phase 1 must include a line-by-line audit of `defaults write` commands against Sequoia (macOS 15) behavior. Some keys may have moved or been deprecated.
- **Brewfile current state vs. machine state drift:** The research assumes the Brewfile is incomplete relative to the current machine (a near-universal finding in existing dotfiles repos). The exact gap is not known until `brew bundle check` is run. Phase 1 must include this audit.
- **antidote `.zsh_plugins.txt` structure:** The exact plugin list for migration from OMZ custom plugins to antidote needs to be determined during Phase 2 planning by inspecting the current OMZ plugin configuration.

## Sources

### Primary (HIGH confidence)
- GNU Stow manual (official) — symlink mechanics, `--adopt` behavior, `--restow` semantics
- GitHub Codespaces dotfiles docs (official GitHub) — `install.sh` convention for devcontainers
- Speed up zsh compinit by checking cache once a day (ctechols gist) — compinit single-call pattern
- Brewfile.lock.json semantics (homebrew-bundle issue #1188) — lock file behavior clarified
- zsh PATH deduplication via `typeset -U` — standard zsh behavior, multiple confirmed sources

### Secondary (MEDIUM confidence)
- antidote official site (antidote.sh) — plugin manager capabilities and setup
- Starship v1.24.2 release (github.com/starship/starship) — current version confirmation
- GNU Stow 2.4.0 (gnu.org/software/stow) — version and `--dotfiles` flag fix
- zsh plugin manager benchmark (rossmacarthur/zsh-plugin-manager-benchmark) — antidote vs zinit vs sheldon
- webpro/dotfiles — CI pattern, Brewfile, GNU Stow usage
- holman/dotfiles — `bin/dot` update command pattern, topic organization
- mathiasbynens/dotfiles — macOS defaults coverage benchmark
- DevPod docs (devpod.sh) — devcontainer dotfiles install.sh convention
- Homebrew Brewfile best practices (ChristopherA gist) — widely referenced

### Tertiary (LOW confidence)
- Cursor devcontainer forum thread — symlinked install.sh behavior (active thread, rapidly changing)
- Starship replacing Powerlevel10k (hashir.blog, 2025) — P10k life support status (single source but cross-referenced with community consensus)
- GNU Stow on macOS 2025 (msleigh.io) — macOS-specific Stow usage
- antidote + Starship ZSH setup (hiiruki.com) — integration example (single blog source)
- Cursor devcontainer dotfiles convention (forum.cursor.com) — devcontainer dotfiles setup

---
*Research completed: 2026-02-28*
*Ready for roadmap: yes*
