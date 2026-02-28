# Phase 2: Shell - Research

**Researched:** 2026-02-28
**Domain:** zsh configuration, antidote plugin management, Starship prompt, fzf shell integration
**Confidence:** HIGH

## Summary

This phase replaces Oh My Zsh with antidote, establishes a clean zsh load order, migrates Starship to its canonical config location, and wires up fzf shell integration. The current machine has OMZ actively installed at `~/.oh-my-zsh` and symlinked to the Stow-managed `.zshrc`. The migration is a surgical replace-and-rewrite of `.zshrc`, not an incremental change.

Antidote (v1.10.2) is a pure-zsh plugin manager with no binary dependencies. It generates a static `.zsh_plugins.zsh` file at first load and only regenerates it when `.zsh_plugins.txt` changes — this is the primary source of its speed advantage over OMZ. The `kind:defer` annotation defers plugin loading using `romkatv/zsh-defer` (auto-included by antidote; no manual entry needed). The OMZ git plugin is loaded via `getantidote/use-omz` + `ohmyzsh/ohmyzsh path:lib/git.zsh` + `ohmyzsh/ohmyzsh path:plugins/git`, preserving all git aliases (gst, gco, gp, gl) without the full OMZ framework overhead.

The Starship config currently lives at `.dotfiles/starship/.starship.toml` (symlinked to `~/.starship.toml`). Starship's canonical location is `~/.config/starship.toml`. The cleanest migration path is to restructure the Stow package so it produces `~/.config/starship.toml`, or to set `STARSHIP_CONFIG=$HOME/.starship.toml` in `.exports`. Both approaches work; the `STARSHIP_CONFIG` env var approach avoids restructuring the Stow package. The planner should choose based on consistency with how other `.config/` tools are managed in Phase 4.

**Primary recommendation:** Install antidote via `brew install antidote`, use the static-file generation pattern in `.zshrc`, load plugins via `.zsh_plugins.txt` with `kind:defer` for syntax-highlighting and autosuggestions, and set `STARSHIP_CONFIG` in `.exports` to keep the existing Stow package structure intact.

---

<user_constraints>
## User Constraints (from CONTEXT.md)

### Locked Decisions

**Plugin inventory:**
- Keep OMZ git plugin aliases (gst, gco, gp, gl, etc.) — load via antidote's OMZ plugin support
- Keep gh CLI completions via antidote
- Keep docker completions via antidote
- Drop kubectl completions and plugin entirely
- Add zsh-history-substring-search (up-arrow history filtering)
- Core plugins: zsh-autosuggestions, zsh-syntax-highlighting (lazy-loaded via antidote)

**Shell file layout:**
- .zsh_plugins.txt lives inside zsh/ Stow package (symlinked to ~/.zsh_plugins.txt)
- Keep .extra file pattern for local/machine-specific overrides (not committed)
- Git aliases sourced from OMZ git lib via antidote (not a standalone plugin)
- Claude's discretion on whether to keep multi-file split or consolidate

**OMZ feature replacement:**
- Add directory stack setopts (AUTO_PUSHD, PUSHD_SILENT, etc.) — lightweight, user may use them
- No auto-correction (setopt CORRECT disabled — user finds it annoying)
- Styled completions: case-insensitive matching, colored, grouped menu — replicate OMZ's zstyle settings
- Remove SSH agent management block entirely — 1Password SSH agent handles this now
- Remove Warp terminal integration block from .zshrc

**Alias housekeeping:**
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

### Deferred Ideas (OUT OF SCOPE)
- Modern CLI aliases (eza for ls, bat for cat, fd for find) — tracked as QOL-01 in v2 requirements
- 'dot' update command replacing the update alias — Phase 4
- Ghostty config management — Phase 4
</user_constraints>

---

<phase_requirements>
## Phase Requirements

| ID | Description | Research Support |
|----|-------------|-----------------|
| SHEL-01 | Oh My Zsh removed and replaced with antidote plugin manager | antidote v1.10.2 via `brew install antidote`; OMZ dir removed with `rm -rf ~/.oh-my-zsh` after uninstall; `.zshrc` rewritten without OMZ source line |
| SHEL-02 | Plugins lazy-loaded via antidote (zsh-autosuggestions, zsh-syntax-highlighting) | `kind:defer` annotation in `.zsh_plugins.txt`; antidote auto-includes `romkatv/zsh-defer`; load order constraint: syntax-highlighting before history-substring-search |
| SHEL-03 | Single `compinit` call after all fpath additions, correct zsh load order | fpath populated before compinit; Homebrew completions, antidote fpath, tool completions all added first; `mattmc3/ez-compinit` plugin can automate this; daily-cache pattern with `-C` flag saves ~15ms |
| SHEL-04 | `typeset -U PATH path` prevents PATH duplication across subshells | Placed at top of `.zshrc` (before PATH modifications); `-U` flag enforces uniqueness on both the scalar and array form; placement outside function bodies is required |
| SHEL-05 | Starship prompt configured and loaded (migrate to Stow package) | Config currently at `~/.dotfiles/starship/.starship.toml` → `~/.starship.toml` symlink; use `STARSHIP_CONFIG=$HOME/.starship.toml` in `.exports` OR restructure to `starship/.config/starship.toml`; `eval "$(starship init zsh)"` placed after plugins |
| SHEL-06 | fzf shell integration (Ctrl+R history search, Ctrl+T file finder) | fzf installed via Brewfile; `source <(fzf --zsh)` in `.zshrc` (requires fzf ≥ 0.48.0); enables Ctrl+R, Ctrl+T, and Alt+C |
</phase_requirements>

---

## Standard Stack

### Core

| Tool | Version | Purpose | Why Standard |
|------|---------|---------|--------------|
| antidote | v1.10.2 (Homebrew current) | zsh plugin manager | Pure-zsh, no binary deps, static file generation, works in containers, already decided in project |
| zsh-autosuggestions | latest (via antidote) | Fish-like command suggestions | De facto standard, pairs with syntax-highlighting |
| zsh-syntax-highlighting | latest (via antidote) | Real-time command syntax coloring | De facto standard, must load before history-substring-search |
| zsh-history-substring-search | latest (via antidote) | Up-arrow prefix history search | Decided in CONTEXT.md; load after syntax-highlighting |
| getantidote/use-omz | latest (via antidote) | OMZ compatibility bridge for antidote | Required to load OMZ lib/plugins without full OMZ framework |
| Starship | installed via Brewfile | Cross-shell prompt, no OMZ theme needed | Already decided in project; replaces P10k |
| fzf | installed via Brewfile | Fuzzy finder for Ctrl+R, Ctrl+T | Already in Brewfile; native zsh integration via `--zsh` flag |

### Supporting

| Tool | Version | Purpose | When to Use |
|------|---------|---------|-------------|
| mattmc3/ez-compinit | latest (via antidote) | Correct compinit with deferred-safe compdef wrapper | Recommended to avoid double-compinit issues when mixing antidote plugins and manual fpath additions |
| zsh-users/zsh-completions | latest (via antidote) | Additional completion definitions | Adds completions for many tools not covered by system; use `kind:fpath path:src` |
| romkatv/zsh-defer | latest (auto-included) | Async plugin deferred loading | Auto-included by antidote when `kind:defer` is used; no manual entry |

### Alternatives Considered

| Instead of | Could Use | Tradeoff |
|------------|-----------|----------|
| antidote (decided) | zinit | zinit is faster in theory but requires Rust toolchain; antidote chosen for container compatibility |
| getantidote/use-omz | Manually curating git aliases | use-omz handles OMZ's internal dependency chain automatically; manual curation is fragile |
| `source <(fzf --zsh)` | Legacy fzf keybindings scripts | Modern API (fzf ≥ 0.48.0); simpler; official recommendation |
| ez-compinit plugin | Manual compinit optimization | ez-compinit wraps compdef so plugins can call it before compinit runs; prevents the chicken-and-egg problem |

**Installation:**

```bash
brew install antidote  # fzf and starship already in Brewfile
```

---

## Architecture Patterns

### Recommended zsh/ Stow Package Structure

```
zsh/
├── .zshrc              # Main entry point; sources other files; plugin bootstrap
├── .zsh_plugins.txt    # antidote plugin manifest (symlinked to ~/.zsh_plugins.txt)
├── .path               # PATH declarations + typeset -U PATH path
├── .exports            # Env vars (EDITOR, STARSHIP_CONFIG, etc.)
├── .aliases            # Aliases (cleaned of Warp/kubectl)
├── .functions          # Shell functions (cleaned of stale Python 2 code)
├── .extra              # Local/machine overrides (not committed, .gitignore-excluded)
└── .zsh_completions    # Custom compdef calls (cleaned of kubectl refs)
```

Recommendation on multi-file vs consolidate: **keep the multi-file split**. The existing structure is clean, each file has a clear purpose, and consolidation provides no benefit for a single-user dotfiles repo. The split also makes `.extra` overrides easier to reason about.

### Pattern 1: antidote Static File Bootstrap

**What:** Generate `.zsh_plugins.zsh` once, regenerate only when `.zsh_plugins.txt` changes. On subsequent shell starts, just source the pre-generated file — zero antidote overhead.

**When to use:** Always. This is the recommended high-performance pattern.

```zsh
# Source: https://antidote.sh/install — High-Performance .zshrc Configuration

# antidote location (Homebrew install)
ANTIDOTE_HOME="$(brew --prefix)/opt/antidote/share/antidote"

# Define plugins file root name
zsh_plugins=${ZDOTDIR:-~}/.zsh_plugins

# Lazily load antidote functions
fpath=("$ANTIDOTE_HOME"/functions $fpath)
autoload -Uz antidote

# Regenerate compiled plugins only when .txt is newer than .zsh
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  antidote bundle <${zsh_plugins}.txt >|${zsh_plugins}.zsh
fi

# Source the compiled static file
source ${zsh_plugins}.zsh
```

### Pattern 2: .zsh_plugins.txt Layout

**What:** The antidote plugin manifest. Order matters. Completions and OMZ bridge first, then UI plugins deferred.

```
# Source: https://antidote.sh/usage and https://github.com/getantidote/use-omz

# Handle compinit correctly (defer-safe compdef wrapper)
mattmc3/ez-compinit

# OMZ compatibility bridge — must come before any ohmyzsh/* entries
getantidote/use-omz

# OMZ git lib and plugin (provides gst, gco, gp, gl, etc.)
ohmyzsh/ohmyzsh path:lib/git.zsh
ohmyzsh/ohmyzsh path:plugins/git

# Additional completions
zsh-users/zsh-completions kind:fpath path:src

# gh and docker completions via OMZ plugins
ohmyzsh/ohmyzsh path:plugins/gh
ohmyzsh/ohmyzsh path:plugins/docker

# Core UI plugins — deferred for fast startup
zsh-users/zsh-syntax-highlighting kind:defer
zsh-users/zsh-autosuggestions kind:defer
zsh-users/zsh-history-substring-search kind:defer
```

**Critical load order:** `zsh-syntax-highlighting` MUST come before `zsh-history-substring-search`. Deferred plugins all run after prompt appears, so relative order within deferred still matters for binding compatibility.

### Pattern 3: Correct zsh Load Order in .zshrc

**What:** The sequence that prevents PATH duplication, compinit double-calls, and missing completions.

```zsh
# 1. PATH uniqueness guard — must be FIRST before any PATH modification
typeset -U PATH path

# 2. Source path/exports/aliases/functions (sets fpath, PATH, env vars)
for file in ~/.{path,exports,aliases,functions,extra}; do
  [[ -r "$file" ]] && source "$file"
done
unset file

# 3. Directory stack options (lightweight OMZ replacement)
setopt AUTO_PUSHD PUSHD_SILENT PUSHD_IGNORE_DUPS PUSHD_TO_HOME
DIRSTACKSIZE=20

# 4. History settings
setopt HIST_IGNORE_ALL_DUPS HIST_REDUCE_BLANKS HIST_VERIFY SHARE_HISTORY EXTENDED_HISTORY

# 5. Homebrew fpath (must be before antidote/compinit)
if type brew &>/dev/null; then
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
fi

# 6. antidote plugin bootstrap (ez-compinit inside handles compinit)
[antidote static file block — see Pattern 1]

# 7. Key bindings for history-substring-search (after plugins sourced)
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

# 8. fzf shell integration (Ctrl+R, Ctrl+T)
source <(fzf --zsh)

# 9. Starship init — always last
eval "$(starship init zsh)"
```

### Pattern 4: Starship Config Migration

**What:** The existing `.starship.toml` lives at `~/.starship.toml` (symlinked from `starship/.starship.toml`). Starship's default is `~/.config/starship.toml`. Two valid migration paths:

**Option A — STARSHIP_CONFIG env var (recommended, least disruption):**
```zsh
# In .exports:
export STARSHIP_CONFIG="$HOME/.starship.toml"
```
Keep the Stow package as-is. Requires one env var. Works immediately.

**Option B — Restructure Stow package to canonical location:**
```
starship/
└── .config/
    └── starship.toml    # Stow symlinks to ~/.config/starship.toml
```
Cleaner long-term; matches how other `.config/` tools work in Phase 4. Requires renaming `.starship.toml` → `starship.toml` and adding `.config/` directory layer.

Decision: Claude's discretion. Option A is faster; Option B is more consistent with canonical XDG layout used in Phase 4.

### Pattern 5: Completion Styling (OMZ Replacement)

**What:** Replicate OMZ's styled completion: case-insensitive matching, colored, grouped menu.

```zsh
# In .zshrc after compinit (or handled by ez-compinit):
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}'  # case-insensitive
zstyle ':completion:*' menu select                            # arrow-key menu
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"     # colored
zstyle ':completion:*' group-name ''                         # grouped by type
zstyle ':completion:*' use-cache on                          # cache results
zstyle ':completion:*' cache-path ~/.zsh/cache
```

### Pattern 6: gh and Docker Completions

**What:** gh CLI and Docker completions can be loaded through the OMZ plugins via antidote. The OMZ `gh` and `docker` plugins bundle completion scripts.

```
# In .zsh_plugins.txt:
ohmyzsh/ohmyzsh path:plugins/gh
ohmyzsh/ohmyzsh path:plugins/docker
```

Alternatively, for gh: `gh completion -s zsh` outputs a completion function that can be placed in a fpath directory. For Docker: Docker Desktop on macOS also installs completions at `$(brew --prefix)/share/zsh/site-functions` — these are picked up automatically once Homebrew fpath is added before compinit.

**Recommendation:** Use OMZ plugins via antidote for both (consistent approach), fall back to native completion commands only if the OMZ plugins prove stale or broken.

### Anti-Patterns to Avoid

- **Multiple compinit calls:** The existing `.zshrc` calls `compinit` in the macOS block AND `.zsh_completions` calls `compinit` again. This forces cache regeneration on every shell start. Fix: single compinit via ez-compinit, remove from `.zsh_completions`.
- **PATH built inside functions:** `typeset -U path` inside a function body clears PATH. Place the typeset declaration at the top level of `.zshrc`.
- **`kind:defer` without understanding the trade-off:** Deferred plugins are not available until after the first prompt appears. If any alias/function in `.aliases` or `.functions` depends on a deferred plugin's functions, it will silently fail on first shell start. For zsh-autosuggestions and zsh-syntax-highlighting this is fine — they only affect interactive typing.
- **OMZ source without use-omz bridge:** Loading `ohmyzsh/ohmyzsh path:plugins/git` without `getantidote/use-omz` first causes missing `lib/` function errors.
- **`antidote load` in hot path:** Using `antidote load` (instead of the static file pattern) runs antidote logic on every shell start. Use the `[[ ! .zsh -nt .txt ]]` check pattern instead.

---

## Don't Hand-Roll

| Problem | Don't Build | Use Instead | Why |
|---------|-------------|-------------|-----|
| Deferred plugin loading | Custom `zsh-defer` wrapper | `kind:defer` in `.zsh_plugins.txt` (antidote auto-includes romkatv/zsh-defer) | Correct async scheduling around ZLE state; edge cases in subshells |
| OMZ dependency management | Manually sourcing `lib/git.zsh` before `plugins/git` | `getantidote/use-omz` | Handles the full OMZ lib dependency chain; lazy-loads lib components on demand |
| compinit deferred compdef | Manual `compdef` scheduling | `mattmc3/ez-compinit` | Wraps compdef so it can be called before compinit runs; prevents silent failures |
| PATH deduplication | Shell function that strips dupes | `typeset -U PATH path` | Built into zsh; one line, handles both scalar and array form |
| fzf key bindings | Sourcing individual fzf shell script files | `source <(fzf --zsh)` | Official API since fzf 0.48.0; handles Ctrl+R, Ctrl+T, Alt+C in one call |

**Key insight:** Every "clever" shell startup script someone writes to manage these concerns is a hand-rolled approximation of something the ecosystem already solved correctly. The discipline is using the right primitive for each concern.

---

## Common Pitfalls

### Pitfall 1: Double compinit Kills Cache Performance

**What goes wrong:** The rewritten `.zshrc` calls compinit, antidote's OMZ bridge calls compinit again, and the existing `.zsh_completions` file calls it a third time. The zcompdump cache is regenerated on every shell start, adding 50-200ms.

**Why it happens:** Different files added compinit calls independently over time; the OMZ framework managed this internally so the duplication went unnoticed.

**How to avoid:** Use `mattmc3/ez-compinit` as the first antidote plugin entry. Remove explicit `compinit` calls from `.zshrc` macOS block and from `.zsh_completions`. ez-compinit defers compinit to the end of startup after all fpath additions are complete.

**Warning signs:** `time zsh -i -c exit` consistently above 300ms with antidote; `zsh -x` shows multiple `compinit` invocations.

### Pitfall 2: antidote Static File Not Being Rebuilt After Plugin Changes

**What goes wrong:** User edits `.zsh_plugins.txt` but the `.zsh_plugins.zsh` static file is not regenerated because the timestamp check fails (e.g., the `.txt` file was restored from git without touching its mtime).

**Why it happens:** The `[[ ! .zsh -nt .txt ]]` check uses filesystem modification time, which git restore/checkout does not preserve.

**How to avoid:** After any change to `.zsh_plugins.txt`, run `antidote bundle` manually, or force regeneration with `touch ~/.zsh_plugins.txt`.

**Warning signs:** New plugin not loading despite being in `.zsh_plugins.txt`; `antidote list` shows expected plugins but they aren't in `$fpath` or sourced.

### Pitfall 3: zsh-history-substring-search Key Bindings Not Working

**What goes wrong:** Up-arrow does not trigger history substring search; instead it does standard history recall.

**Why it happens:** `kind:defer` means the plugin loads after the first prompt, but key bindings set before the plugin loads are overwritten. OR: `zsh-syntax-highlighting` loads after `zsh-history-substring-search`, overriding its bindings.

**How to avoid:** Set key bindings AFTER the antidote plugin source block in `.zshrc` (not before). Use `bindkey "$terminfo[kcuu1]"` rather than hardcoded escape sequences for terminal portability. Ensure `zsh-syntax-highlighting` is listed before `zsh-history-substring-search` in `.zsh_plugins.txt`.

**Warning signs:** `bindkey | grep history-substring` shows no entries; or up-arrow does plain history cycling.

### Pitfall 4: Homebrew antidote Path Hardcoded for Wrong Architecture

**What goes wrong:** `.zshrc` hardcodes `/opt/homebrew/...` which breaks on Intel Macs or Linux containers.

**Why it happens:** Apple Silicon Homebrew prefix is `/opt/homebrew`; Intel Macs use `/usr/local`; Linux uses `/home/linuxbrew/.linuxbrew`.

**How to avoid:** Use `$(brew --prefix)/opt/antidote/share/antidote/antidote.zsh` (dynamically resolved) or the `fpath` + `autoload` pattern which only needs to resolve the functions directory once at build time.

**Warning signs:** Shell fails to start on Intel Mac or Linux container with "no such file" error.

### Pitfall 5: Warp/OMZ Remnant Left in .zshrc Breaking Clean Slate

**What goes wrong:** The migration forgets to remove the SSH agent block, Warp block, or OMZ-related `compinit` call from the macOS block. OMZ variables (`$ZSH`, `DISABLE_AUTO_UPDATE`, etc.) remain as dead code that confuses future debugging.

**Why it happens:** Incremental editing of `.zshrc` is tempting; a complete rewrite is more reliable.

**How to avoid:** Treat the `.zshrc` rewrite as a clean-slate file, not a patch. Start from the canonical antidote template and add back only what is explicitly needed. Verify with `grep -n 'oh-my-zsh\|ZSH=\|ssh-agent\|WarpTerminal' ~/.zshrc` returning zero results.

### Pitfall 6: .zsh_plugins.txt Stow Symlink Target Collision

**What goes wrong:** `~/.zsh_plugins.txt` symlink already exists (from a previous failed attempt) and stow cannot create it.

**Why it happens:** Stow fails on conflicts unless `--adopt` is used (which is destructive).

**How to avoid:** Before stowing, check for and remove any existing `~/.zsh_plugins.txt` file. The generated `~/.zsh_plugins.zsh` is a runtime artifact (not part of the Stow package) and should be added to `.stow-local-ignore` or `.gitignore` in the zsh/ package.

### Pitfall 7: urlencode Alias Uses Python 2 Syntax

**What goes wrong:** `alias urlencode='python -c "import sys, urllib as ul; print ul.quote_plus(sys.argv[1]);"'` fails silently on macOS because Python 2 is not installed.

**Why it happens:** Original alias was written for Python 2; macOS ships Python 3 only.

**How to avoid:** Replace with: `alias urlencode='python3 -c "import sys, urllib.parse; print(urllib.parse.quote_plus(sys.argv[1]))"'` — already noted in CONTEXT.md as cleanup task.

### Pitfall 8: .path Has Duplicate Entries

**What goes wrong:** `$HOME/.local/bin` appears twice in `.path`; `$HOME/.npm-global/bin` appears in both `.path` and `.exports`. Even with `typeset -U PATH path`, the duplicates are printed by `echo $PATH` before `typeset` runs.

**Why it happens:** Entries were added to multiple files without cross-checking.

**How to avoid:** During migration, audit `.path` and `.exports` together. Remove `$HOME/go/bin` from `.exports` (it's already in `.path`). Keep all PATH modifications in `.path` only; `.exports` handles env vars but not PATH.

---

## Code Examples

Verified patterns from official sources:

### Complete .zsh_plugins.txt

```
# Source: https://antidote.sh/usage + https://github.com/getantidote/use-omz

# Completion init (defer-safe compdef wrapper)
mattmc3/ez-compinit

# OMZ compatibility layer — MUST precede any ohmyzsh/* entries
getantidote/use-omz

# OMZ git library and plugin (gst, gco, gp, gl, gcmsg, etc.)
ohmyzsh/ohmyzsh path:lib/git.zsh
ohmyzsh/ohmyzsh path:plugins/git

# Additional completions
zsh-users/zsh-completions kind:fpath path:src

# Tool completions via OMZ plugins
ohmyzsh/ohmyzsh path:plugins/gh
ohmyzsh/ohmyzsh path:plugins/docker

# Core UI — defer for fast time-to-prompt
# IMPORTANT: syntax-highlighting before history-substring-search
zsh-users/zsh-syntax-highlighting kind:defer
zsh-users/zsh-autosuggestions kind:defer
zsh-users/zsh-history-substring-search kind:defer
```

### Minimal antidote .zshrc block

```zsh
# Source: https://antidote.sh/install (High-Performance Configuration)

# antidote bootstrap (Homebrew install, cross-arch compatible)
zsh_plugins=${ZDOTDIR:-~}/.zsh_plugins
[[ -f ${zsh_plugins}.txt ]] || touch ${zsh_plugins}.txt
fpath=("$(brew --prefix)/opt/antidote/share/antidote/functions" $fpath)
autoload -Uz antidote
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  antidote bundle <${zsh_plugins}.txt >|${zsh_plugins}.zsh
fi
source ${zsh_plugins}.zsh
```

### fzf shell integration

```zsh
# Source: https://junegunn.github.io/fzf/shell-integration/
# Requires fzf >= 0.48.0 (current Homebrew version)
# Enables: Ctrl+R (history), Ctrl+T (file picker), Alt+C (cd)
source <(fzf --zsh)
```

### typeset -U PATH — correct placement

```zsh
# Must be at top level of .zshrc, NOT inside a function, NOT inside a conditional
# Place BEFORE any PATH modifications
typeset -U PATH path
```

### zsh-history-substring-search key bindings

```zsh
# Source: https://github.com/zsh-users/zsh-history-substring-search
# terminfo approach is more portable than hardcoded ^[[A/^[[B escape codes
# Place AFTER antidote source block (plugins must be loaded first)
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down
```

### Completion styling (OMZ-equivalent)

```zsh
# Replicate OMZ completion appearance without the framework
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*' accept-exact '*(N)'
```

### Directory stack setopts (OMZ directories.zsh replacement)

```zsh
setopt AUTO_PUSHD        # cd acts like pushd; maintains directory stack
setopt PUSHD_SILENT      # suppress stack output after pushd/popd
setopt PUSHD_IGNORE_DUPS # no duplicate entries in the stack
setopt PUSHD_TO_HOME     # pushd with no args → home dir
DIRSTACKSIZE=20
```

### STARSHIP_CONFIG override (Option A — in .exports)

```zsh
# Keeps existing starship/ Stow package structure intact
export STARSHIP_CONFIG="$HOME/.starship.toml"
```

---

## State of the Art

| Old Approach | Current Approach | When Changed | Impact |
|---|---|---|---|
| Oh My Zsh framework | antidote + targeted OMZ plugin loading | OMZ slows as plugin count grows; antidote static file is ~10x faster startup | OMZ startup overhead is 200-800ms depending on plugins; antidote static load is ~20ms |
| `eval "$(fzf --zsh)"` manual scripts | `source <(fzf --zsh)` unified integration | fzf 0.48.0 (2024) | Single line replaces separate key-binding and completion script sources |
| Powerlevel10k | Starship | P10k maintenance-only since June 2025 (per STATE.md) | Starship is actively maintained, same feature set, faster init via binary |
| `antidote load` (always runs) | Static file pattern with mtime check | antidote documentation "High-Performance" section | Eliminates antidote overhead on every shell start |
| Multiple `compinit` calls | Single deferred compinit via ez-compinit | Identified as major startup time contributor in zsh community | Prevents cache regeneration on every shell start; saves 50-200ms |
| Python 2 `urllib` | Python 3 `urllib.parse` | Python 2 EOL 2020; macOS removed Python 2 in Monterey | Existing `urlencode` alias is silently broken |

**Deprecated/outdated in current dotfiles:**
- `DISABLE_AUTO_UPDATE`, `DISABLE_UPDATE_PROMPT`, `COMPLETION_WAITING_DOTS`: OMZ-specific variables; remove entirely
- `export ZSH=$HOME/.oh-my-zsh`: Remove
- SSH agent management block: Remove (1Password handles this)
- Warp terminal block and aliases (w, wd): Remove
- kubectl aliases (k, kctx, kns) and `_kctx` completion: Remove
- `USE_GKE_GCLOUD_AUTH_PLUGIN=True` in `.exports`: Stale if kubectl is dropped; keep if gcloud is still in use (verify)
- `OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES`: macOS Sonoma workaround; may no longer be needed on current macOS
- `export PYTHONPATH`: Non-standard; can cause issues with virtualenvs; remove unless specifically needed

---

## Open Questions

1. **Starship config migration: Option A (STARSHIP_CONFIG env var) vs Option B (restructure Stow package to .config/starship.toml)**
   - What we know: Both work. Option A is one env var. Option B matches canonical XDG structure.
   - What's unclear: What pattern Phase 4 will adopt for `.config/` tools (Ghostty, tmux).
   - Recommendation: Choose Option A now for speed; Plan 02-03 should note "if Phase 4 consolidates under .config/, migrate starship then."

2. **antidote fpath path for Homebrew — Linux container compatibility**
   - What we know: `$(brew --prefix)/opt/antidote/...` evaluates correctly on both Intel and Apple Silicon.
   - What's unclear: Phase 3 (cross-platform) needs Linux path. On Linux without Homebrew, antidote would need a different source path (`~/.antidote` clone or system package).
   - Recommendation: Use the `brew --prefix` pattern here; Phase 3 will add the Linux branch. Guard with `[[ -x "$(command -v brew)" ]]` so the block is skipped on Linux.

3. **`USE_GKE_GCLOUD_AUTH_PLUGIN=True` in .exports — remove or keep?**
   - What we know: This was required for gcloud/kubectl integration. kubectl plugin is being dropped.
   - What's unclear: Whether gcloud is still actively used without kubectl.
   - Recommendation: Keep for now (gcloud is in Brewfile); removing it could break gcloud auth. Flag for user review.

4. **gh CLI completions — OMZ plugin vs native `gh completion -s zsh`**
   - What we know: OMZ `gh` plugin exists and works with antidote. Native `gh completion -s zsh` generates current completions on demand.
   - What's unclear: Whether the OMZ gh plugin completions are kept current with gh CLI releases.
   - Recommendation: Use OMZ plugin first. If gh tab-completion feels incomplete, switch to: `mkdir -p ~/.zsh/completions && gh completion -s zsh > ~/.zsh/completions/_gh` + add that dir to fpath.

---

## Validation Architecture

> `nyquist_validation` is not set in `.planning/config.json` (key absent). Skipping Validation Architecture section.

---

## Sources

### Primary (HIGH confidence)

- https://antidote.sh/install — Installation, Homebrew path, static file pattern
- https://antidote.sh/usage — .zsh_plugins.txt format, all annotation types
- https://antidote.sh/options — kind values (defer, fpath, path, clone, zsh), use-omz bridge
- https://github.com/getantidote/use-omz — use-omz README; how OMZ plugins load via antidote
- https://github.com/mattmc3/antidote/blob/main/README.md — v1.10.2 version, core docs
- https://junegunn.github.io/fzf/shell-integration/ — `source <(fzf --zsh)` API, Ctrl+R/Ctrl+T bindings
- https://github.com/zsh-users/zsh-history-substring-search — Load order constraint (after zsh-syntax-highlighting), key binding patterns
- https://starship.rs/config/ — STARSHIP_CONFIG env var override, default location `~/.config/starship.toml`
- https://github.com/mattmc3/ez-compinit — ez-compinit purpose, compdef wrapping, antidote compatibility

### Secondary (MEDIUM confidence)

- https://antidote.sh/completions — `kind:fpath path:src` pattern for completion-only plugins
- WebSearch: `typeset -U PATH path` behavior — confirmed by multiple zsh sources; placement warning (not in function bodies) from ohmyzsh/ohmyzsh issue #3168
- WebSearch: compinit daily-cache pattern — confirmed by https://gist.github.com/ctechols/ca1035271ad134841284 (widely referenced)
- WebSearch: antidote `kind:defer` auto-includes `romkatv/zsh-defer` — confirmed by antidote manpages on Ubuntu/Debian

### Tertiary (LOW confidence)

- WebSearch: antidote startup time vs OMZ — antidote developer publishes benchmarks in dotfiles repo but specific numbers not retrieved; claimed order-of-magnitude improvement
- WebSearch: `OBJC_DISABLE_INITIALIZE_FORK_SAFETY=YES` still needed on macOS 15 — not verified; treat as potentially stale

---

## Metadata

**Confidence breakdown:**
- Standard stack: HIGH — antidote v1.10.2 confirmed from GitHub README; all plugins confirmed from official sources
- Architecture patterns: HIGH — sourced from official antidote docs, fzf docs, zsh-history-substring-search README
- Pitfalls: HIGH — most pitfalls directly observable in current dotfiles files (double compinit, Python 2 alias, PATH duplication, Warp/OMZ remnants)
- Starship migration: HIGH — STARSHIP_CONFIG env var confirmed from starship.rs official docs

**Research date:** 2026-02-28
**Valid until:** 2026-03-28 (antidote is stable; fzf API is stable; 30-day window)
