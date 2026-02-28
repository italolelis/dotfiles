# Feature Research

**Domain:** Cross-platform developer dotfiles (macOS + Linux/devcontainers)
**Researched:** 2026-02-28
**Confidence:** HIGH (core features), MEDIUM (differentiators), LOW (anti-features noted where training-only)

---

## Feature Landscape

### Table Stakes (Users Expect These)

Features every well-maintained dotfiles setup has. Missing these = setup feels incomplete or broken.

| Feature | Why Expected | Complexity | Notes |
|---------|--------------|------------|-------|
| Symlink-based file management | Edits in `~` flow back to repo; true single source of truth. rsync-copy approach (current state) breaks this contract. | LOW | GNU Stow is the standard; creates farm of symlinks from `~/.dotfiles` to `$HOME`. Requires packages dir structure. |
| Single-command bootstrap | "Clone and run one command" is the entire value proposition. Without it, the setup isn't portable. | MEDIUM | Must handle: clone, install deps, stow packages, configure shell. Currently `install.sh` does this but via rsync. |
| Idempotent install script | Running install twice must not break things. Power failure, re-running to update — all must be safe. | MEDIUM | Current `install.sh` is partially idempotent (checks exist on OMZ install) but rsync isn't idempotent in spirit. Stow `--restow` is. |
| Platform detection (macOS vs Linux) | macOS needs Homebrew, Ghostty, macOS defaults. Linux/containers need shell + git only. One entry point branches by OS. | MEDIUM | `uname` check is standard. macOS branch runs `brew bundle`. Linux branch skips GUI tools. |
| Version-controlled configs | Config history, rollback, and sync across machines requires git. | LOW | Already have this. The issue is config drift (repo ≠ machine). Symlinks eliminate drift by definition. |
| Shell plugin manager (replacing Oh My Zsh) | OMZ adds ~200–500ms startup overhead. Modern setups use zinit (Turbo mode), sheldon, or zim for lazy loading. | MEDIUM | zinit Turbo mode yields 50–80% faster startup. sheldon has cleaner config (TOML). zim is fastest out-of-box. Decision needed — see STACK.md. |
| Zsh autosuggestions + syntax highlighting | Every modern zsh config includes these two plugins. Absence is conspicuous. | LOW | Already installed via OMZ custom plugins. Migrate to plugin manager. |
| Git configuration (global gitignore, aliases, signing) | Developers expect git to work correctly on any machine from day one. | LOW | Already partially done (`.gitconfig`, signing key set). Global gitignore must be configured post-stow. |
| `.extra` pattern for machine-local secrets | No secrets in repo. Machine-specific values (tokens, work email) live in `~/.extra` which is gitignored and sourced by `.zshrc`. | LOW | Already in use. Must preserve this pattern. |
| Shell aliases, functions, exports as separate files | Monolithic `.zshrc` becomes unmaintainable. Separation into `.aliases`, `.functions`, `.exports`, `.path` is universal pattern. | LOW | Already have these files. Stow should symlink them as-is. |
| Brewfile for macOS packages | Declarative, diffable, one-command install of all brews/casks/taps. `brew bundle` is standard for macOS dotfiles. | LOW | Already have `install/Brewfile`. Needs audit vs current machine state. |
| macOS system defaults script | `defaults write` commands for sensible macOS settings (Dock, Finder, screenshots, keyboard). Without it, fresh machine feels wrong. | MEDIUM | Already have `macos.sh`. Needs audit for Sequoia compatibility. |
| Starship prompt configuration | Starship is the de-facto cross-platform prompt. Config lives in `~/.config/starship.toml`. | LOW | Already have `.starship.toml`. Must be stowed correctly. |
| tmux configuration | Standard for developer terminal multiplexing. Nearly universal in power-user dotfiles. | LOW | Already have `.tmux.conf`. Must be stowed. |
| Ghostty terminal configuration | Project-specific requirement. Lives in `~/.config/ghostty/config`. | LOW | Already have config. Must be stowed. |

---

### Differentiators (Competitive Advantage)

Features that distinguish a well-crafted dotfiles setup from a basic one. Not universally present, but valued by power users.

| Feature | Value Proposition | Complexity | Notes |
|---------|-------------------|------------|-------|
| Devcontainer / Codespaces auto-install | Shell feels identical in Cursor devcontainers and Codespaces. GitHub natively supports dotfiles repos with an auto-install hook. Add `install.sh` that GitHub/Codespaces calls automatically. | MEDIUM | GitHub Codespaces looks for `install.sh`, `setup.sh`, or `bootstrap.sh`. Script must detect container context and install only shell essentials (no Homebrew, no macOS defaults). |
| Lazy-loaded plugins with measurable startup time | Shell opens in <200ms. Turbo mode (zinit) or deferred loading (sheldon + zsh-defer) achieves this. | MEDIUM | zinit `wait` keyword defers plugins until after prompt. Benchmark with `time zsh -i -c exit` before/after. |
| Modern CLI tool aliases (bat, eza, ripgrep, fd) | `cat` → `bat`, `ls` → `eza`, `grep` → `rg`, `find` → `fd`. Dramatically better output and UX. | LOW | Requires tools installed via Brewfile (macOS) and separate mechanism on Linux. Aliases conditional on tool existence (`command -v bat && alias cat=bat`). |
| fzf shell integration (history, file search, dir jump) | Ctrl+R searches history with fuzzy preview. Ctrl+T inserts files. Alt+C changes directories. Transforms daily workflow. | LOW | fzf ships keybindings via `$(brew --prefix)/opt/fzf/install`. Must be sourced in `.zshrc`. |
| Topic-based modular directory structure (Holman pattern) | Adding new tool = create new directory. Files auto-sourced by extension (`.zsh`, `.symlink`). Scales cleanly. | MEDIUM | Not using this currently — all files flat in root. Adds some upfront organization cost but pays off as config grows. Worth considering vs flat Stow packages. |
| CI testing with GitHub Actions | Install script tested on every push. Catches breakage before it matters. webpro/dotfiles pattern: test on Ubuntu + macOS weekly. | MEDIUM | Requires Docker for Linux tests or macOS runner. Smoke test: does install script complete without errors on clean machine? |
| `dot` update command | One command to pull latest changes and re-apply: `git pull && stow --restow packages/`. Holman's `bin/dot` is the canonical example. | LOW | Small script, high value. Makes day-to-day maintenance frictionless. |
| Shell function library (useful, documented) | Curated functions for common tasks: `mkcd`, `extract`, `server`, etc. Functions that you actually use vs functions hoarded from tutorials. | LOW | Already have `.functions`. The differentiator is curation and documentation, not existence. |
| Conditional tool loading (graceful degradation) | On Linux/containers where only shell + git is available, aliases for missing tools don't cause errors. `command -v tool` guards on all aliases. | LOW | Critical for devcontainer scenario. Simple implementation, but must be explicit policy. |
| Startup time benchmark in README | Showing `zsh` cold start time demonstrates intentionality about performance. Signals a well-maintained setup. | LOW | `time zsh -i -c exit` result. Purely documentation value, but meaningful to technical audience. |

---

### Anti-Features (Commonly Requested, Often Problematic)

Features that seem useful but create real problems in practice.

| Feature | Why Requested | Why Problematic | Alternative |
|---------|---------------|-----------------|-------------|
| Nix / home-manager for everything | Fully declarative, reproducible. Attractive in theory. | Massive learning curve. Tight iteration loop: every config edit requires `home-manager switch`. Rebuilds for plaintext file changes are actively harmful. Community itself warns against over-Nixification. Incompatible with "greenfield-ish modernization" scope. | GNU Stow + Homebrew + shell plugin manager achieves 90% of the declarative value with 10% of the complexity. Nix belongs in a separate phase if ever. |
| Secrets in the repo | Convenience — no need to remember what's in `.extra`. | API keys committed to git are a permanent security liability even after deletion (git history). Common source of credential leaks. | `.extra` pattern (gitignored, machine-local). 1Password CLI for runtime secret injection if needed. |
| Full GUI app installation automation (beyond Brewfile) | Appealing to have "everything" provisioned. | GUI apps change frequently, require App Store sign-in, have license issues. Casks handle the installable subset. Trying to automate beyond this creates brittle scripts. | Brewfile casks cover what's automatable. Document the rest in README as "install manually." |
| Neovim / Vim config | Many dotfiles include it. Vim is a classic dotfiles component. | Out of scope per PROJECT.md. Cursor syncs its own settings. Adding vim config creates maintenance burden for unused tooling. | Explicitly out of scope. If workflow changes, add in a dedicated phase. |
| VS Code settings | Common in dotfiles repos. | Cursor handles its own settings sync. Duplicating creates drift. | Explicitly excluded. Note in README that editor settings are managed by Cursor. |
| Oh My Zsh (keeping it) | Already installed, familiar, has themes. | 200–500ms shell startup overhead. Plugin updates are opaque. Custom plugin directory coupling. Large surface area for things to go wrong. Community consensus has moved to plugin managers. | zinit / sheldon / zim. Same plugins (autosuggestions, syntax-highlighting), lazy loading, faster startup. |
| rsync-based install (keeping it) | Simple to understand. | Copies files instead of symlinking: edits in `~` don't flow back to repo. Creates the exact config drift problem this project is solving. Running install again overwrites local changes. | GNU Stow symlinks. Bidirectional: edit anywhere, tracked everywhere. |
| Over-engineered topic auto-loading (full Holman pattern) | Elegant: drop a `.zsh` file anywhere and it's sourced. | Implicit loading order is hard to debug. Files sourced alphabetically, making load order opaque. Some plugins must load before others. | Explicit `source` calls in `.zshrc` or a plugin manager with explicit ordering. Topic directories for organization only, not auto-loading. |
| Cross-machine config with templating (chezmoi-style) | Single repo that generates different configs per machine. | Significant complexity increase. Template syntax to learn. For this setup (one personal Mac + Linux containers), the `.extra` pattern handles machine differences more simply. | `.extra` for local overrides. Platform detection in install script for macOS vs Linux branches. Chezmoi belongs in a future phase if managing 3+ distinct machines. |

---

## Feature Dependencies

```
Symlink management (GNU Stow)
    └──required by──> All config files (zsh, git, tmux, ghostty, starship)
                          └──required by──> Shell plugin manager config
                          └──required by──> Ghostty config
                          └──required by──> tmux config

Platform detection in install script
    └──required by──> macOS branch (Brewfile, macos.sh)
    └──required by──> Linux branch (shell essentials only)
    └──required by──> Devcontainer support (subset of Linux branch)

Shell plugin manager (zinit/sheldon/zim)
    └──required by──> Lazy-loaded plugins
    └──required by──> Measurable startup time improvement
    └──replaces──> Oh My Zsh (conflict: cannot run both)

Brewfile (macOS)
    └──required by──> Modern CLI tools (bat, eza, fzf, ripgrep, fd)
    └──required by──> Modern CLI tool aliases (tools must exist first)

Modern CLI tools (bat, eza, fzf, ripgrep, fd)
    └──enhances──> Shell aliases (conditional on tool existence)
    └──enhances──> fzf shell integration (fzf must be installed)

`dot` update command
    └──requires──> Symlink management (Stow --restow)
    └──requires──> Git-tracked repo structure

CI testing (GitHub Actions)
    └──requires──> Idempotent install script (can't test non-idempotent scripts)
    └──enhances──> All features (catches regressions)

Devcontainer support
    └──requires──> Platform detection (Linux path)
    └──requires──> Conditional tool loading (graceful degradation)
    └──conflicts──> macOS-specific features (Homebrew, macos.sh) in container context
```

### Dependency Notes

- **Stow requires all others:** Everything flows from solving the symlink/single-source-of-truth problem first. No point migrating shell configs if they'll be copied (not symlinked) anyway.
- **Plugin manager conflicts with Oh My Zsh:** These cannot coexist cleanly. The migration requires fully removing OMZ before installing the new plugin manager.
- **Devcontainer requires conditional loading:** Any alias or function that references a macOS-only tool (Homebrew paths, macOS commands) will error in containers. Guards must be in place before testing devcontainer support.
- **Modern CLI tools require Brewfile audit:** Tools used in aliases must be in the Brewfile. Drift between alias definitions and Brewfile entries causes errors on fresh machines.

---

## MVP Definition

### Launch With (v1)

Minimum viable product — what's needed for the setup to actually work as a "one command" cross-platform dotfiles repo.

- [ ] **GNU Stow-based symlink management** — without this, config drift is unsolvable and the setup is fundamentally broken
- [ ] **Idempotent cross-platform install script** — macOS branch (Brew + stow) and Linux branch (git + stow only)
- [ ] **Drop Oh My Zsh, adopt lightweight plugin manager** — zinit/sheldon/zim; measurably faster shell startup
- [ ] **Brewfile audit** — current machine state → Brewfile, eliminate drift
- [ ] **Config audit** — current machine dotfiles → repo, eliminate drift. All existing configs stowed.
- [ ] **macOS defaults script audit** — verify Sequoia compatibility
- [ ] **Platform-conditional tool aliases** — `command -v` guards on all modern tool aliases

### Add After Validation (v1.x)

Features to add once the core is working and tested.

- [ ] **Devcontainer/Codespaces auto-install** — add once base install script is solid; requires platform detection to be working
- [ ] **`dot` update command** — `bin/dot` script wrapping git pull + stow restow; add after Stow migration stabilizes
- [ ] **fzf shell integration** — high value, low effort, but depends on Brewfile and plugin manager being in place
- [ ] **Startup time benchmark** — measure before/after plugin manager migration; document in README

### Future Consideration (v2+)

Features to defer until v1 is stable and in daily use.

- [ ] **CI testing with GitHub Actions** — valuable but not blocking daily use; add once install script is stable
- [ ] **Topic-based modular structure** — only worth it if configs grow significantly; current flat structure + Stow packages is sufficient for this scope
- [ ] **Chezmoi-style multi-machine templating** — not needed for one Mac + containers use case; revisit if managing more machines

---

## Feature Prioritization Matrix

| Feature | User Value | Implementation Cost | Priority |
|---------|------------|---------------------|----------|
| Symlink management (Stow) | HIGH | MEDIUM | P1 |
| Idempotent cross-platform install script | HIGH | MEDIUM | P1 |
| Drop Oh My Zsh / adopt plugin manager | HIGH | MEDIUM | P1 |
| Brewfile + config audit (fix drift) | HIGH | LOW | P1 |
| macOS defaults script audit | MEDIUM | LOW | P1 |
| Platform-conditional tool aliases | HIGH | LOW | P1 |
| Devcontainer support | HIGH | LOW | P2 |
| `dot` update command | MEDIUM | LOW | P2 |
| fzf shell integration | HIGH | LOW | P2 |
| Modern CLI tool aliases (bat, eza, rg, fd) | MEDIUM | LOW | P2 |
| Startup time benchmark | LOW | LOW | P2 |
| CI testing | MEDIUM | MEDIUM | P3 |
| Topic-based modular structure | LOW | MEDIUM | P3 |
| Nix / home-manager | LOW | HIGH | Anti-feature |

**Priority key:**
- P1: Must have for launch
- P2: Should have, add when possible
- P3: Nice to have, future consideration

---

## Reference Dotfiles Analyzed

| Project | Key Pattern | Relevance |
|---------|-------------|-----------|
| holman/dotfiles | Topic-based dir structure, `.symlink` extension convention, `bin/dot` update script | Organizational model; `dot` update command pattern |
| mathiasbynens/dotfiles | `.macos` system defaults script, canonical macOS defaults | Benchmark for macOS defaults coverage |
| webpro/dotfiles | CI on GitHub Actions (Ubuntu + macOS weekly), Brewfile, GNU Stow | CI pattern; tested on Sequoia/15 |
| Lissy93/dotfiles | Cross-platform, modular, graceful degradation | Multi-platform pattern |
| chezmoi | Templating, secrets management, multi-machine | Explicitly NOT chosen for this scope (complexity vs value) |

---

## Sources

- [webpro/awesome-dotfiles — curated dotfiles resources](https://github.com/webpro/awesome-dotfiles) — MEDIUM confidence (WebSearch)
- [holman/dotfiles — topic-based organization](https://github.com/holman/dotfiles) — MEDIUM confidence (WebSearch + well-known project)
- [mathiasbynens/dotfiles — macOS defaults](https://github.com/mathiasbynens/dotfiles) — MEDIUM confidence (WebSearch + well-known project)
- [Zach Holman: Dotfiles Are Meant to Be Forked](https://zachholman.com/2010/08/dotfiles-are-meant-to-be-forked/) — MEDIUM confidence (foundational article)
- [zinit — Turbo mode 50-80% faster startup claim](https://github.com/zdharma-continuum/zinit) — MEDIUM confidence (WebSearch, project README)
- [zsh plugin manager benchmark](https://github.com/rossmacarthur/zsh-plugin-manager-benchmark) — MEDIUM confidence (WebSearch)
- [chezmoi — why use chezmoi](https://www.chezmoi.io/why-use-chezmoi/) — HIGH confidence (official docs)
- [GitHub Codespaces dotfiles personalization](https://docs.github.com/en/codespaces/setting-your-user-preferences/personalizing-github-codespaces-for-your-account) — HIGH confidence (official GitHub docs)
- [CI your macOS dotfiles with GitHub Actions](https://mattorb.com/ci-your-dotfiles-with-github-actions/) — MEDIUM confidence (WebSearch)
- [You don't have to use Nix for dotfiles (anti-Nix argument)](https://jade.fyi/blog/use-nix-less/) — MEDIUM confidence (WebSearch, community consensus supported by multiple sources)
- [1Password for secrets in shell config](https://samedwardes.com/blog/2023-11-03-1password-for-secret-dotfiles/) — MEDIUM confidence (WebSearch)
- [GNU Stow for dotfile management](https://gist.github.com/andreibosco/cb8506780d0942a712fc) — MEDIUM confidence (WebSearch)
- [Cross-platform dotfiles — Calvin Bui](https://calvin.me/cross-platform-dotfiles/) — MEDIUM confidence (WebSearch)
- [The Ultimate Guide to Mastering Dotfiles — Daytona](https://www.daytona.io/dotfiles/ultimate-guide-to-dotfiles) — MEDIUM confidence (WebSearch)

---

*Feature research for: Cross-platform developer dotfiles (macOS + Linux/devcontainers)*
*Researched: 2026-02-28*
