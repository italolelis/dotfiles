# Pitfalls Research

**Domain:** Cross-platform dotfiles (macOS + Linux/devcontainers), migration from Oh My Zsh + rsync to zinit/sheldon + GNU Stow + Brewfile
**Researched:** 2026-02-28
**Confidence:** MEDIUM — core pitfalls verified across multiple sources; some Cursor-specific items are LOW due to rapid product churn

---

## Critical Pitfalls

### Pitfall 1: Secrets Committed to Git History

**What goes wrong:**
API keys, tokens, SSH passphrases, or machine-specific credentials end up in `.zshrc`, `.extra`, `.exports`, or `.gitconfig` and get committed. Even if the file is later deleted, the secret persists in git history and is trivially recoverable with `git log -p`.

**Why it happens:**
Developers move their existing, working dotfiles into the repo without auditing them first. The `.extra` pattern is meant to hold secrets but is easily confused with tracked files during migration. During an rsync-to-Stow migration, it's common to copy everything and curate later — "later" never comes.

**How to avoid:**
- Audit every file for secrets before the first `git add` — use `git diff --cached` and tools like `gitleaks` or `detect-secrets` before every commit during the migration phase.
- Add `.gitattributes` secrets patterns and a `.gitignore` that excludes `.extra`, `.env`, `*secret*`, `*credentials*`, `*token*` before touching any files.
- Establish the `.extra` convention explicitly: it is gitignored, sourced by `.zshrc`, and is the only file that ever touches credentials. Document this in a comment at the top of `.zshrc`.
- Rotate any credential immediately if committed; `git-filter-repo` can scrub history but the credential is compromised the moment it was pushed.

**Warning signs:**
- The words `export GITHUB_TOKEN`, `export AWS_SECRET`, `export OPENAI_API_KEY`, or any passphrase appear in any tracked file.
- `.gitignore` does not explicitly list `.extra`.
- The first commit of the migration includes more than ~10 files without a line-by-line review.

**Phase to address:** Phase 1 (repo setup / initial file audit) — before any files are stowed or committed.

---

### Pitfall 2: GNU Stow `--adopt` Overwrites Repo Files With Machine State

**What goes wrong:**
When running `stow --adopt` to migrate existing `~` files into the repo, Stow moves the live file from `$HOME` into the package directory and replaces the repo file without asking. If the repo already contains a curated version of the file, the live (possibly cruftier) machine version silently overwrites it.

**Why it happens:**
`--adopt` is the intuitive flag to use when "importing" existing dotfiles into a Stow-managed repo. Documentation describes it as a convenience, but the overwrite behavior is easy to miss. It is especially dangerous when going back and forth between machines.

**How to avoid:**
- Never run `stow --adopt` without first committing the current repo state (`git stash` or `git commit`).
- Prefer the manual migration pattern: copy file into Stow package dir → delete original from `$HOME` → run `stow <package>`. Verbose but safe.
- Run `stow --simulate` (dry-run) first to see what would happen before committing.
- Use `git diff` immediately after any `stow --adopt` run to see what changed in the repo before continuing.

**Warning signs:**
- `git status` shows unexpected modifications to files you thought were already correct after running Stow.
- Running `stow --adopt` was the first step, not the last step, of migrating a file.

**Phase to address:** Phase 1 (GNU Stow setup and initial symlink creation).

---

### Pitfall 3: rsync Copies Still On-Disk Shadowing New Symlinks

**What goes wrong:**
The old install script used `rsync` to copy dotfiles into `$HOME`. Those copied files still exist as real files. When you run `stow <package>`, Stow sees a real file already at the target path and reports a conflict, refusing to create the symlink. Alternatively, if Stow is forced, the real file takes precedence over a symlink.

**Why it happens:**
Migration is done incrementally — Stow is added but the old rsync copies are not removed first. The shell appears to work (it is loading the real file) but the symlink was never actually created, so edits in `$HOME` do not flow back to the repo.

**How to avoid:**
- Before running any `stow` commands, delete (or back up) the real files in `$HOME` that correspond to files in the Stow package.
- Run `stow --simulate` first to surface conflicts as errors before anything is changed.
- After stowing, verify symlinks with `ls -la ~ | grep '\->'` for each expected file. A real file where a symlink should be means something went wrong.
- Explicitly retire the rsync install script in the same phase as Stow is introduced — do not allow both to coexist.

**Warning signs:**
- `stow <package>` exits with "CONFLICT" or "existing target" errors.
- `ls -la ~/.zshrc` shows a regular file (`-rw-r--r--`) rather than a symlink (`lrwxr-xr-x`).
- Edits in `~/.zshrc` do not appear in the repo when running `git status`.

**Phase to address:** Phase 1 (symlink migration), immediately when replacing rsync with Stow.

---

### Pitfall 4: Zsh Shell Init File Load Order Confusion (zshenv / zprofile / zshrc / zlogin)

**What goes wrong:**
PATH entries, environment variables, and plugin setup get scattered across `.zshenv`, `.zprofile`, `.zshrc`, and `.exports`. This causes: (a) PATH duplication every time a subshell opens, (b) compinit called multiple times causing slow startups, (c) variables set in the wrong file that are unavailable in non-interactive or non-login shells (critical for devcontainers).

**Why it happens:**
The load order (`zshenv` → `zprofile` → `zshrc` → `zlogin`) is non-obvious. macOS terminal emulators open login shells by default, so `.zprofile` runs, but devcontainer shells may not be login shells. Oh My Zsh abstracted this — removing it surfaces the underlying complexity.

**How to avoid:**
- Establish a single, explicit convention: `PATH` manipulation only in `.zprofile` (login shells) or `.zshenv` (all shells, use sparingly), plugins and aliases only in `.zshrc`.
- Use `typeset -U path` (or `typeset -U PATH path`) to deduplicate PATH automatically — put this near the top of the PATH-setting file, not at the bottom.
- Call `compinit` exactly once, after the full `fpath` is configured, never before plugin managers finish loading.
- Test in both login and non-login contexts: `zsh -i -c 'echo $PATH'` vs. `zsh -l -i -c 'echo $PATH'` should behave predictably.
- On macOS, be aware that `/etc/zprofile` calls `path_helper` which reorders `PATH` — this runs before your dotfiles on login shells. Do not fight it; append, don't prepend, unless you have a specific reason.

**Warning signs:**
- `$PATH` contains duplicated entries (e.g., `/opt/homebrew/bin` appears 3 times).
- Shell starts noticeably slower in subshells than in the initial terminal.
- Commands available in the terminal are not found inside devcontainer scripts.

**Phase to address:** Phase 1 (zsh config restructure when replacing Oh My Zsh).

---

### Pitfall 5: Plugin Load Order Breaks Deferred/Lazy Loading

**What goes wrong:**
With sheldon, `zsh-defer` must be declared as a plugin before any plugin that uses the `defer` template. If the order in `plugins.toml` is wrong, deferred plugins fail silently or with cryptic "command not found" errors. With zinit Turbo mode, completion setup (e.g., `compinit`) must happen at the right moment relative to deferred plugins or completions are unavailable until the next keypress.

**Why it happens:**
Lazy loading is the primary performance win when dropping Oh My Zsh. Both zinit Turbo mode and sheldon's `zsh-defer` execute deferred commands from the zle (line editor) context, which has subtle differences from normal init context. Plugin ordering feels arbitrary until you understand the dependency graph.

**How to avoid:**
- With sheldon: always declare `zsh-defer` (romkatv/zsh-defer) as the first plugin entry. Put keybindings and any `setopt` calls that affect input in a non-deferred block — deferred keybindings require a keypress to activate.
- With zinit Turbo mode: load completion-aware plugins with `wait` but run `compinit` only after all `fpath` additions are done. Use `zinit cdreplay` if needed to replay completions.
- Profile startup with `zsh -i -c 'zprof'` (after adding `zmodload zsh/zprof` at the top of `.zshrc`) to verify plugins are loading in the expected order.
- Test key bindings and completions explicitly after any plugin order change — these are the two most common breakage points.

**Warning signs:**
- Tab completion does not work on the first keypress after opening a new shell but works after pressing a key.
- `zsh: command not found: defer` error in shell init output.
- Keybindings (e.g., Ctrl+R for history search) are unresponsive until after the first command.

**Phase to address:** Phase 2 (zsh plugin manager setup and lazy loading configuration).

---

## Technical Debt Patterns

Shortcuts that seem reasonable but create long-term problems.

| Shortcut | Immediate Benefit | Long-term Cost | When Acceptable |
|----------|-------------------|----------------|-----------------|
| Keep Oh My Zsh running alongside zinit/sheldon during migration | Reduces risk of breaking the shell mid-migration | Double startup overhead; OMZ's `compinit` call conflicts with plugin manager's; config becomes impossible to debug | Never — migrate completely in one phase, use a branch |
| Commit all current dotfiles first, clean up later | Gets things under version control fast | Secrets may be committed; config drift from machine is preserved as-is | Only if you audit every file with `gitleaks` immediately after |
| Use `stow --adopt` to skip manual file migration | Saves 5 minutes per file | Risk of silently overwriting curated repo contents | Only with a clean `git stash` immediately before |
| Copy-paste completions from the internet without understanding them | Fast setup of exotic completions | Slows startup via repeated `compinit` calls or broken `fpath` additions | Never for `compinit`-touching snippets; acceptable for pure alias blocks |
| Single monolithic `.zshrc` instead of split files | Simpler initial setup | Cross-platform conditionals proliferate; Linux-only and macOS-only blocks entangle; hard to stow selectively | Acceptable early, but plan the split before Phase 3 |
| Skip `Brewfile.lock.json` in git | Reduces noise in PRs | No reproducibility guarantee; a `brew bundle` on a new machine may install different versions | Acceptable — `Brewfile.lock.json` is for debugging, not locking (Homebrew has no real lock semantics) |

---

## Integration Gotchas

Common mistakes when connecting to external services or tools.

| Integration | Common Mistake | Correct Approach |
|-------------|----------------|------------------|
| GNU Stow + XDG config dir | Stowing a package that places files in `~/.config/<app>/` when the app expects `$XDG_CONFIG_HOME/<app>/` — they are the same path only if XDG_CONFIG_HOME is set | Verify `$XDG_CONFIG_HOME` defaults to `~/.config` on both macOS and Linux before assuming Stow paths will work cross-platform |
| Starship + sheldon deferred init | Running `eval "$(starship init zsh)"` inside a deferred block causes the prompt to render as a string literal on first shell open | Load Starship init synchronously, never defer it |
| Homebrew + cask self-updating apps | Including casks for apps like Chrome, Slack, or 1Password in `brew bundle upgrade` causes Homebrew to fight with the app's internal updater, sometimes corrupting the install | Add `cask_args appdir: "/Applications"` to Brewfile and document which casks are excluded from `brew upgrade` |
| Cursor devcontainers + GNU Stow symlinks | Cursor's devcontainer lifecycle commands (postCreateCommand, onCreateCommand) may not resolve symlinked scripts because the shell used does not source the user's dotfiles | The install script invoked by devcontainers must be a real file (not a symlink) or the Stow target must be in a directory the container shell can resolve without dotfile sourcing |
| Devcontainers + macOS-only zshrc blocks | `.zshrc` that sources macOS-only tools (e.g., `brew shellenv`, `/opt/homebrew/bin/...`) fails silently or fatally in Linux containers | Wrap all macOS-specific sourcing with `[[ "$(uname)" == "Darwin" ]]` guards |
| zinit + OMZ plugin loading | Using `OMZP::` snippets without checking if the OMZ plugin has been updated or renamed in the OMZ repo — zinit fetches them live | Pin OMZ plugins as git snippets with a specific commit hash for reproducibility, not the moving `OMZP::` pointer |

---

## Performance Traps

Patterns that work initially but degrade startup time.

| Trap | Symptoms | Prevention | When It Breaks |
|------|----------|------------|----------------|
| `compinit` called multiple times | `zsh` startup >200ms; running `zprof` shows `compinit` is the top offender | Call `compinit` exactly once, at the end of `.zshrc`, after all `fpath` additions. Use `compinit -C` for subsequent shells (skip security check when dump cache is fresh) | Immediately, on every shell open |
| `fpath` changes between compinit calls | compdump cache is regenerated on every shell open despite no real changes | Deduplicate fpath with `fpath=(${(uo)fpath})` before calling compinit | Immediately, on every shell open |
| Lazy-loading SDKs that are already fast | Adding `nvm`/`pyenv`/`rbenv` deferred wrappers for tools that are rarely used but slow to init | Only lazy-load tools that meaningfully contribute to startup time — profile with `zprof` first, not by assumption | At N+1 tools, cumulative overhead matters |
| Eager `eval "$(tool init zsh)"` for every tool | Startup time creeps past 500ms over months as tools accumulate | Use lazy wrappers or sheldon deferred blocks for init-heavy tools (nvm, rbenv, pyenv, mise). Starship is the exception — must be eager | Noticeable when adding a 3rd or 4th SDK manager |
| Sourcing `.aliases`, `.functions`, `.exports` via sequential `source` calls | Negligible individually, measurable collectively; more importantly, re-source in subshells | Consolidate into a single sourced file or directly inline in `.zshrc` | Noticeable at 5+ separate sourced files |

---

## Security Mistakes

Domain-specific security issues in dotfiles projects.

| Mistake | Risk | Prevention |
|---------|------|------------|
| Tracking `.gitconfig` with `user.email` and `user.signingkey` in a public repo | Personal email and GPG key ID exposed; key ID can be used to download the public key and confirm identity | This is generally acceptable since email and public key ID are not sensitive, but track `.gitconfig` without any `[credential]` sections; use `includeIf` for work vs personal identity switching |
| `.netrc` or curl/wget config files with embedded auth tokens | Full credential exposure on push | Never track `.netrc`; add to `.gitignore`; use `.extra` for any auth-adjacent config; `.curlrc` and `.wgetrc` should never contain credentials |
| `macos` defaults script reading/printing sensitive system state | Low risk from the script itself, but piping the output or logging it could expose UUIDs or hardware identifiers | Run defaults scripts locally only; do not pipe to a service or log to a file that gets committed |
| SSH config (`~/.ssh/config`) with internal hostnames, jumphost paths, or internal IPs | Exposes internal network topology | Either gitignore `.ssh/config` entirely and manage it separately, or track only a sanitized version with no real hostnames |
| Homebrew tap from a private or untrusted source in Brewfile | Risk of supply chain compromise | Only add `tap` entries for official or well-audited sources; document why each tap is present |

---

## "Looks Done But Isn't" Checklist

Things that appear complete but are missing critical pieces.

- [ ] **Symlink setup:** Ran `stow <package>` successfully — verify with `ls -la ~/<file>` that it shows `->` pointing into the repo, not a regular file. Stow exits 0 even when a file was skipped due to a conflict if `--no-folding` is not set.
- [ ] **Cross-platform zshrc:** Works on macOS — verify it also opens without errors in a Linux container (`docker run --rm -it debian zsh -i -c 'echo ok'` with the dotfiles mounted).
- [ ] **Devcontainer install script:** `install.sh` runs in the container — verify it is executable (`chmod +x`), is a real file not a symlink, and does not rely on tools that are macOS-only (Homebrew, etc.).
- [ ] **Brewfile completeness:** `brew bundle` runs without errors on a fresh machine — verify by running `brew bundle check` to identify packages installed on the machine but missing from the Brewfile.
- [ ] **PATH hygiene:** No duplicate entries after opening a new terminal and a subshell — verify with `echo $PATH | tr ':' '\n' | sort | uniq -d`.
- [ ] **Compinit called once:** Verify with `zsh -i -c 'zprof' 2>&1 | grep compinit` — should appear once, not multiple times.
- [ ] **No secrets in tracked files:** Run `gitleaks detect --source .` (or `git log -p | grep -E 'AKIA|ghp_|sk-|token|secret|password|api_key'`) before the first push.
- [ ] **Idempotency:** Run the install script twice consecutively — it should succeed on both runs without errors or duplicate entries.
- [ ] **Stow package boundaries correct:** Each package directory in the Stow repo mirrors the directory structure from `$HOME` — e.g., `zsh/.zshrc` not `zsh/home/.zshrc`.
- [ ] **macOS defaults script:** After running `.macos`, confirm with `defaults read <domain> <key>` that at least 3 settings you care about are actually applied.

---

## Recovery Strategies

When pitfalls occur despite prevention, how to recover.

| Pitfall | Recovery Cost | Recovery Steps |
|---------|---------------|----------------|
| Secret committed to git | HIGH | 1. Rotate the credential immediately. 2. Use `git-filter-repo --path <file> --invert-paths` to remove from history. 3. Force-push all branches. 4. Notify any collaborators to re-clone. |
| `stow --adopt` overwrote repo file | LOW-MEDIUM | `git diff` to see what changed. `git checkout -- <file>` to restore repo version. Manually merge any desired machine-side changes back in. |
| Real files shadowing symlinks (rsync remnants) | LOW | `rm ~/.zshrc` (or whichever file), then `stow <package>`. Verify with `ls -la`. |
| PATH duplicated / shell very slow | LOW | Add `typeset -U PATH path` near top of PATH-setting file. `exec zsh` to reload. |
| compinit called multiple times | LOW | `grep -n compinit ~/.zshrc` to find all calls. Remove all but the last one. Delete `~/.zcompdump*` to force cache rebuild. |
| Plugin order broke completions/keybindings | MEDIUM | Revert `plugins.toml` / `.zshrc` to last-known-good commit. Add plugins back one at a time, testing after each addition. |
| Devcontainer install script not executing | LOW | Check: is it executable? Is it a real file (not a symlink)? Does Cursor point to the correct repo and installCommand? |
| Config drift discovered (machine state ≠ repo) | MEDIUM | Run `diff ~/.zshrc $(readlink ~/.zshrc)` (shows nothing if symlink is correct). If dotfiles were never symlinked, use `diff` to identify divergence, then manually reconcile before stowing. |

---

## Pitfall-to-Phase Mapping

How roadmap phases should address these pitfalls.

| Pitfall | Prevention Phase | Verification |
|---------|------------------|--------------|
| Secrets committed to git | Phase 1: Repo setup and file audit | `gitleaks detect` passes on initial commit |
| `stow --adopt` data loss | Phase 1: GNU Stow migration | `git diff` clean after every stow operation |
| rsync copies shadowing symlinks | Phase 1: Retire rsync, install Stow | `ls -la` on all tracked files shows symlinks, not real files |
| Zsh load order / PATH duplication | Phase 2: zsh config restructure | `typeset -U PATH path` in place; `zprof` shows no duplicated sourcing |
| Plugin order breaks lazy loading | Phase 2: Plugin manager setup | Tab completion and keybindings work on first shell open, no zprof surprise |
| compinit called multiple times | Phase 2: zsh config restructure | `grep compinit ~/.zshrc` returns exactly one call |
| Starship deferred and rendering as string | Phase 2: Plugin manager setup | Prompt renders correctly on first shell open, no keypress needed |
| macOS-only blocks in cross-platform zshrc | Phase 3: Cross-platform script split | `uname` guards on all macOS-specific sections; tested in Linux container |
| Devcontainer: symlinked install script fails | Phase 3: Devcontainer support | Cursor opens a devcontainer with dotfiles and install.sh completes without errors |
| Brewfile incomplete / missing packages | Phase 4: Brewfile setup | `brew bundle check` passes with no missing packages |
| Cask self-updater conflicts | Phase 4: Brewfile setup | Documented list of casks excluded from `brew upgrade` |
| Config drift not addressed at project start | Phase 1: Initial audit | `git log --stat` shows a deliberate "audit and reconcile" commit |

---

## Sources

- [GNU Stow manual — `--adopt` flag behavior](https://www.gnu.org/software/stow/manual/html_node/Invoking-Stow.html) — MEDIUM confidence (official docs)
- [GNU Stow for deploying dotfiles — msleigh.io (Jan 2025)](https://www.msleigh.io/blog/2025/01/31/using-gnu-stow-for-deploying-dotfiles/) — MEDIUM confidence
- [Using GNU Stow — System Crafters](https://systemcrafters.net/managing-your-dotfiles/using-gnu-stow/) — MEDIUM confidence
- [How I manage dotfiles with GNU Stow — tamerlan.dev](https://tamerlan.dev/how-i-manage-my-dotfiles-using-gnu-stow/) — MEDIUM confidence
- [Zinit — zdharma-continuum GitHub](https://github.com/zdharma-continuum/zinit) — MEDIUM confidence (official source)
- [Sheldon examples — sheldon.cli.rs](https://sheldon.cli.rs/Examples.html) — MEDIUM confidence (official docs)
- [zsh-defer — romkatv/zsh-defer GitHub](https://github.com/romkatv/zsh-defer) — MEDIUM confidence (official source)
- [Speed up zsh compinit by checking cache once a day — GitHub Gist (ctechols)](https://gist.github.com/ctechols/ca1035271ad134841284) — HIGH confidence (widely referenced)
- [Speeding Up Zsh — joshyin.cc](https://www.joshyin.cc/blog/speeding-up-zsh) — LOW-MEDIUM confidence
- [Dotfiles Security: Why public dotfiles are a security minefield — InstaTunnel](https://instatunnel.my/blog/why-your-public-dotfiles-are-a-security-minefield) — MEDIUM confidence
- [Removing Sensitive Data from Git History — Microsoft Tech Community (2025)](https://techcommunity.microsoft.com/blog/azureinfrastructureblog/how-to-safely-remove-secrets-from-your-git-history-the-right-way/4464722) — MEDIUM confidence
- [Cursor devcontainer: lifecycle commands broken with symlinked dotfiles — Cursor Forum](https://forum.cursor.com/t/cursor-devcontainer-lifecycle-commands-does-not-work-with-symlinked-dotfiles/132923) — LOW confidence (active bug thread, rapidly changing)
- [Brew Bundle Brewfile Tips — Christopher Allen GitHub Gist](https://gist.github.com/ChristopherA/a579274536aab36ea9966f301ff14f3f) — MEDIUM confidence
- [Brewfile.lock.json is misleading — homebrew-bundle issue #1188](https://github.com/Homebrew/homebrew-bundle/issues/1188) — HIGH confidence (official project issue tracker)
- [Remove duplicates in zsh $PATH — til.hashrocket.com](https://til.hashrocket.com/posts/7evpdebn7g-remove-duplicates-in-zsh-path) — HIGH confidence (standard zsh behavior)
- [Properly setting $PATH for zsh on macOS — GitHub Gist](https://gist.github.com/Linerre/f11ad4a6a934dcf01ee8415c9457e7b2) — MEDIUM confidence
- [Cross-Platform Dotfiles — calvin.me](https://calvin.me/cross-platform-dotfiles/) — LOW-MEDIUM confidence (personal blog, single source)

---
*Pitfalls research for: cross-platform dotfiles migration (macOS + Linux/devcontainers)*
*Researched: 2026-02-28*
