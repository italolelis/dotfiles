# Architecture Research

**Domain:** Cross-platform dotfiles (macOS + Linux/devcontainer)
**Researched:** 2026-02-28
**Confidence:** HIGH (patterns corroborated by multiple community sources, official tool docs, and current repo inspection)

## Standard Architecture

### System Overview

```
┌─────────────────────────────────────────────────────────────────┐
│                      Entry Point Layer                           │
│                                                                  │
│   install.sh  (detects platform, orchestrates everything)        │
│       │                                                          │
│       ├── [macOS]  ──────────────────────────────────────────┐  │
│       └── [Linux/container]  ──────────────────────────────┐ │  │
└────────────────────────────────────────────────────────────│─│──┘
                                                             │ │
┌────────────────────────────────────────────────────────────│─│──┐
│                   Package Management Layer                  │ │  │
│                                                             │ │  │
│   Brewfile (macOS only)          apt/manual (Linux)         │ │  │
│       │                                                     │ │  │
│       └── installs: stow, zsh plugins, starship, tools  ←──┘ │  │
└──────────────────────────────────────────────────────────────│──┘
                                                               │
┌──────────────────────────────────────────────────────────────│──┐
│                  Symlink Management Layer                     │  │
│                                                               │  │
│   GNU Stow (stow <package>)  ←────────────────────────────── │  │
│       │                                                       │  │
│       ├── stow zsh   → ~/.zshrc, ~/.path, ~/.aliases, etc.   │  │
│       ├── stow git   → ~/.gitconfig, ~/.gitignore_global      │  │
│       ├── stow tmux  → ~/.tmux.conf                           │  │
│       ├── stow starship → ~/.config/starship.toml             │  │
│       ├── stow ghostty  → ~/.config/ghostty/config (macOS)   │  │
│       └── stow ssh   → ~/.ssh/config                         │  │
└─────────────────────────────────────────────────────────────────┘
                                │
                                ▼
┌─────────────────────────────────────────────────────────────────┐
│                     Shell Runtime Layer                          │
│                                                                  │
│   ~/.zshrc                                                       │
│       │                                                          │
│       ├── sources: .path → .exports → .aliases → .functions     │
│       ├── sources: .extra (machine-local, not in repo)           │
│       ├── loads: zsh plugin manager (zinit/sheldon)             │
│       │       └── lazy-loads: autosuggestions, syntax-highlight  │
│       └── evals: starship init zsh                              │
└─────────────────────────────────────────────────────────────────┘
```

### Component Responsibilities

| Component | Responsibility | Typical Implementation |
|-----------|----------------|------------------------|
| `install.sh` | Entry point; detects platform, calls right sub-scripts | POSIX sh with `uname`/`OSTYPE` check |
| `macos.sh` | macOS-specific: Homebrew, Brewfile, system defaults | bash, calls `brew bundle` |
| `linux.sh` | Linux/container-specific: apt installs, essential tools only | bash, minimal footprint |
| Brewfile | Declarative macOS package manifest | `brew bundle` reads it |
| GNU Stow | Creates symlinks from repo → home dir | `stow <package>` per topic |
| `zsh/` package | All zsh config files | `.zshrc`, `.path`, `.aliases`, `.functions`, `.exports`, `.extra` (gitignored) |
| `git/` package | Git identity, aliases, global gitignore | `.gitconfig`, `.gitignore_global` |
| `tmux/` package | Terminal multiplexer config | `.tmux.conf` |
| `starship/` package | Prompt config (XDG path) | `.config/starship/starship.toml` |
| `ghostty/` package | Terminal emulator config (macOS only) | `.config/ghostty/config` |
| `ssh/` package | SSH client config | `.ssh/config` (no keys — keys stay outside repo) |

## Recommended Project Structure

The target is a **stow-based topic organization**. Each top-level directory is a stow "package" that mirrors the home directory layout. Running `stow <package>` from the repo root creates symlinks into `~`.

```
~/.dotfiles/
├── install.sh              # Entry point (detects platform, orchestrates)
├── macos.sh                # macOS-specific setup (Homebrew, defaults)
├── linux.sh                # Linux/devcontainer setup (shell essentials only)
├── Brewfile                # Declarative macOS packages (moved from install/)
│
├── zsh/                    # Stow package: all zsh config
│   ├── .zshrc              # → ~/.zshrc
│   ├── .path               # → ~/.path (PATH additions)
│   ├── .exports            # → ~/.exports (env vars)
│   ├── .aliases            # → ~/.aliases
│   ├── .functions          # → ~/.functions
│   └── .zsh_completions    # → ~/.zsh_completions
│   # NOTE: .extra is NOT in repo (machine-local secrets/overrides)
│
├── git/                    # Stow package: git config
│   ├── .gitconfig          # → ~/.gitconfig
│   └── .gitignore_global   # → ~/.gitignore_global
│
├── tmux/                   # Stow package: tmux config
│   └── .tmux.conf          # → ~/.tmux.conf
│
├── starship/               # Stow package: starship prompt
│   └── .config/
│       └── starship/
│           └── starship.toml  # → ~/.config/starship/starship.toml
│
├── ghostty/                # Stow package: Ghostty terminal (macOS only)
│   └── .config/
│       └── ghostty/
│           └── config      # → ~/.config/ghostty/config
│
├── ssh/                    # Stow package: SSH client config only
│   └── .ssh/
│       └── config          # → ~/.ssh/config
│       # Keys, known_hosts stay outside repo
│
├── misc/                   # Stow package: miscellaneous dotfiles
│   ├── .curlrc             # → ~/.curlrc
│   ├── .wgetrc             # → ~/.wgetrc
│   ├── .editorconfig       # → ~/.editorconfig
│   └── .inputrc            # → ~/.inputrc
│
└── .planning/              # Project planning (not stowed)
    └── ...
```

### Structure Rationale

- **stow packages/:** Each tool owns its own directory. `stow zsh` sets up just shell config; `stow git` sets up just git. This means Linux containers only stow `zsh`, `git`, `misc` — no ghostty, no Brewfile noise.
- **Mirror home layout inside each package:** Stow requires this. A file at `zsh/.zshrc` creates `~/.zshrc`. A file at `starship/.config/starship/starship.toml` creates `~/.config/starship/starship.toml`. No special flags needed.
- **Brewfile at root:** Belongs to macOS setup, not a stow package. Invoked directly by `macos.sh`.
- **`.extra` never in repo:** Machine-local values (API keys, work credentials, machine-specific `$PATH`) live in `~/.extra`, sourced by `.zshrc` but not tracked.

## Architectural Patterns

### Pattern 1: Stow-Based Symlink Management

**What:** Each config "topic" is its own directory. `stow <dir>` creates symlinks from that dir into `$HOME`, preserving directory structure. No file copying — the repo IS the source of truth.

**When to use:** Always. This replaces the current rsync copy approach.

**Trade-offs:** Requires GNU Stow to be installed before stowing. On macOS: `brew install stow`. On Linux: `apt install stow`. Stow must be installed before symlinks are created — so the install script installs stow first, then stows packages.

**Example:**
```bash
# From repo root:
stow zsh      # Creates ~/.zshrc → ~/.dotfiles/zsh/.zshrc
stow git      # Creates ~/.gitconfig → ~/.dotfiles/git/.gitconfig
stow starship # Creates ~/.config/starship/starship.toml → ~/.dotfiles/starship/.config/starship/starship.toml
```

### Pattern 2: Platform-Branching Install Script

**What:** A single `install.sh` entry point that detects the OS and delegates to platform-specific sub-scripts. The macOS path is full-featured; the Linux path installs only shell essentials.

**When to use:** Required for cross-platform support. Devcontainers run Linux; install.sh must not attempt Homebrew or cask installs there.

**Trade-offs:** Slightly more indirection, but makes `install.sh` the one URL a user ever needs. Devcontainer tooling (Cursor, GitHub Codespaces) always runs `install.sh` by convention.

**Example:**
```bash
#!/usr/bin/env bash
set -euo pipefail

DOTFILES_DIR="$(cd "$(dirname "$0")" && pwd)"

detect_platform() {
  case "$(uname -s)" in
    Darwin) echo "macos" ;;
    Linux)  echo "linux" ;;
    *)      echo "unknown" ;;
  esac
}

PLATFORM="$(detect_platform)"

install_stow() {
  if ! command -v stow &>/dev/null; then
    if [[ "$PLATFORM" == "macos" ]]; then
      brew install stow
    else
      sudo apt-get install -y stow 2>/dev/null || echo "Stow not available via apt, install manually"
    fi
  fi
}

stow_packages() {
  local packages=("zsh" "git" "misc")
  if [[ "$PLATFORM" == "macos" ]]; then
    packages+=("ghostty" "starship" "tmux" "ssh")
  fi
  cd "$DOTFILES_DIR"
  for pkg in "${packages[@]}"; do
    stow --restow --target="$HOME" "$pkg"
  done
}

case "$PLATFORM" in
  macos)
    source "$DOTFILES_DIR/macos.sh"
    install_stow
    stow_packages
    ;;
  linux)
    install_stow
    stow_packages
    ;;
esac
```

### Pattern 3: Lazy-Loaded Plugin Manager

**What:** Replace Oh My Zsh with a lightweight zsh plugin manager (zinit or sheldon) that lazy-loads plugins. Plugins like `zsh-autosuggestions` and `zsh-syntax-highlighting` load after the first prompt, not at shell start.

**When to use:** Essential for the modernized zsh config. Oh My Zsh adds ~200-400ms to startup; zinit with lazy loading brings this under 50ms.

**Trade-offs:** More explicit configuration in `.zshrc` vs. Oh My Zsh's automatic plugin loading. Zinit syntax is more complex but well-documented.

**Example (zinit):**
```bash
# In .zshrc — zinit lazy-loads plugins after first prompt
source "$HOME/.local/share/zinit/zinit.git/zinit.zsh"

zinit ice wait lucid
zinit light zsh-users/zsh-autosuggestions

zinit ice wait lucid
zinit light zsh-users/zsh-syntax-highlighting

eval "$(starship init zsh)"
```

## Data Flow

### Install Flow (End to End)

```
User runs: ./install.sh
    │
    ▼
detect_platform()
    │
    ├── [macOS] ─────────────────────────────────────────────────┐
    │   ├── 1. Install Xcode CLI tools (if missing)              │
    │   ├── 2. Install Homebrew (if missing)                     │
    │   ├── 3. brew bundle (installs all Brewfile packages)       │
    │   │       → includes: stow, starship, zsh plugins, CLI tools│
    │   ├── 4. stow_packages (zsh, git, tmux, starship, ghostty, │
    │   │       ssh, misc)                                        │
    │   └── 5. (optional) source macos-defaults.sh               │
    │                                                             │
    └── [Linux/devcontainer] ───────────────────────────────────►│
        ├── 1. apt install stow (if missing)                      │
        └── 2. stow_packages (zsh, git, misc only)               │
                                                                  │
    ▼ (both paths converge here)                                  │
Symlinks created in $HOME  ◄─────────────────────────────────────┘
    │
    ▼
User opens new shell
    │
    ▼
~/.zshrc loads
    ├── sources .path   → $PATH extended
    ├── sources .exports → env vars set
    ├── sources .aliases → shell aliases registered
    ├── sources .functions → shell functions available
    ├── sources .extra  → machine-local overrides (if file exists)
    ├── plugin manager initializes (zinit/sheldon)
    │   └── lazy-loads: autosuggestions, syntax-highlighting
    └── eval "$(starship init zsh)"  → prompt active
```

### Symlink Data Flow

```
~/.dotfiles/zsh/.zshrc
    │ (GNU Stow creates symlink)
    ▼
~/.zshrc  ──────────────────────► zsh sources on shell start
```

Edits to `~/.zshrc` modify the repo file directly. No sync step. The symlink is the repo file.

### Key Data Flows

1. **Package install → tool available → stow works:** Homebrew (or apt) must complete before stow runs, because stow itself may need to be installed via brew/apt.
2. **Symlinks created → shell sources configs:** Symlinks must exist before any shell session starts. First-time setup requires a terminal restart after `install.sh`.
3. **`.extra` gate:** `.zshrc` sources `.extra` only if it exists (`[ -r "$file" ]` check). New machine gets no `.extra`; user creates it for machine-specific values. This is the secrets isolation boundary.

## Scaling Considerations

This is personal tooling, not a multi-user service. "Scaling" here means complexity growth as configs expand.

| Scale | Architecture Adjustments |
|-------|--------------------------|
| 1 machine | Flat stow packages, single install.sh |
| 2-3 machines (work + personal) | `.extra` per machine for overrides; consider hostname-based branching in `.zshrc` |
| Many machines / team use | Consider chezmoi (templates) for machine-aware config generation — outside current scope |

### Scaling Priorities

1. **First pain point:** Config drift between machines. Solved by symlinks (edits in `~` ARE the repo).
2. **Second pain point:** Machine-specific values bleeding into commits. Solved by `.extra` pattern (never committed).

## Anti-Patterns

### Anti-Pattern 1: rsync Copy Instead of Symlinks

**What people do:** `rsync -avh . ~/` on every install, copying files from repo to home dir.
**Why it's wrong:** Creates divergence. Edits in `~/` don't flow back to the repo. You either edit in the repo and re-rsync, or you edit in `~/` and they drift. The current repo has this problem.
**Do this instead:** `stow <package>`. The file in `~/` IS the file in the repo. Editing it in either location edits the same inode.

### Anti-Pattern 2: Monolithic .zshrc With Everything Inline

**What people do:** One giant `.zshrc` with aliases, functions, exports, plugin config, and prompt all inline.
**Why it's wrong:** Hard to find things, hard to selectively source on different platforms, can't enable/disable sections without commenting.
**Do this instead:** Source separate files (`.path`, `.exports`, `.aliases`, `.functions`). The current repo already does this correctly — keep it.

### Anti-Pattern 3: macOS-Only Commands in Shared Scripts

**What people do:** `brew install` or `defaults write` calls directly inside `install.sh` without platform gating.
**Why it's wrong:** Breaks Linux/devcontainer installs. `brew` doesn't exist in containers.
**Do this instead:** All macOS-specific commands live in `macos.sh`, which is only sourced after `detect_platform()` confirms Darwin.

### Anti-Pattern 4: Secrets or API Keys in Config Files

**What people do:** Put `GITHUB_TOKEN=xxx` or `export AWS_ACCESS_KEY=...` in `.exports` or `.zshrc`.
**Why it's wrong:** Those files are in the repo. Committed secrets are hard to revoke and linger in git history.
**Do this instead:** Machine-sensitive values always go in `~/.extra`. `.extra` is gitignored and sourced last so it can override anything.

### Anti-Pattern 5: Eager Plugin Loading

**What people do:** `source /path/to/zsh-autosuggestions.zsh` at the top of `.zshrc`.
**Why it's wrong:** Adds 100-300ms to every shell startup. On devcontainers this is felt on every `docker exec` session.
**Do this instead:** Use zinit's `ice wait lucid` directives to defer plugin loading until after the first prompt renders.

## Integration Points

### External Services

| Service | Integration Pattern | Notes |
|---------|---------------------|-------|
| Homebrew | `brew bundle --file=Brewfile` | macOS only; run during `macos.sh` |
| GNU Stow | `stow --restow --target=$HOME <pkg>` | Core symlink mechanism |
| Cursor devcontainer | Reads `dotfiles.repository` + `dotfiles.installCommand` from Cursor settings; runs `install.sh` on container start | `install.sh` must be executable and handle Linux path |
| GitHub Codespaces | Same convention as Cursor: clones repo, runs `install.sh` | Works automatically if `install.sh` handles Linux |
| 1Password / secrets manager | Out of scope — `.extra` is the boundary; user manually populates sensitive values | |

### Internal Boundaries

| Boundary | Communication | Notes |
|----------|---------------|-------|
| `install.sh` → `macos.sh` | Direct source or call | `install.sh` is the only user-facing entry point |
| `install.sh` → stow packages | `stow --restow --target=$HOME <pkg>` | Idempotent: `--restow` removes stale symlinks before re-linking |
| `.zshrc` → fragment files | `source ~/.path`, etc. | Load order matters: path first, exports second, then aliases/functions |
| `.zshrc` → `.extra` | `source ~/.extra` (guarded by `[ -r ]`) | Machine-local file, not in repo |
| Stow packages → `~/.config/` | Directory mirroring | Tools using XDG paths (starship, ghostty) need the `.config/<tool>/` dir structure inside their stow package |

## Build Order Implications

The install flow has hard dependencies that determine sequencing:

```
1. [macOS] Xcode CLI Tools
       │ (required for git, curl, compiler)
       ▼
2. [macOS] Homebrew
       │ (required for all brew packages)
       ▼
3. [macOS] brew bundle (Brewfile)      [Linux] apt install stow
       │ installs stow + all tools           │
       ▼                                     │
4. GNU Stow available ◄────────────────────── ┘
       │ (required before any stow commands)
       ▼
5. stow_packages (creates symlinks in $HOME)
       │
       ▼
6. [macOS optional] macos-defaults.sh
       │
       ▼
7. Shell restart (symlinks now in place; zsh loads config)
       │
       ▼
8. zinit/sheldon installs plugins on first shell launch
```

Phases 1-3 are macOS-only. Linux/devcontainer starts at the apt equivalent of Phase 3, making the Linux path significantly shorter — by design, since containers need only shell and git to be useful.

## Sources

- [GNU Stow manual — official symlink mechanics](https://www.gnu.org/software/stow/manual/stow.html) — HIGH confidence
- [Managing dotfiles with GNU Stow (tamerlan.dev)](https://tamerlan.dev/how-i-manage-my-dotfiles-using-gnu-stow/) — MEDIUM confidence (WebSearch, couldn't fetch)
- [Managing Dotfiles with GNU Stow (Medium/mbvissers)](https://medium.com/quick-programming/managing-dotfiles-with-gnu-stow-9b04c155ebad) — MEDIUM confidence
- [GNU Stow — andreibosco GitHub Gist](https://gist.github.com/andreibosco/cb8506780d0942a712fc) — MEDIUM confidence
- [Awesome Dotfiles (webpro/awesome-dotfiles)](https://github.com/webpro/awesome-dotfiles) — MEDIUM confidence (community curation)
- [Cursor dotfiles devcontainer forum thread](https://forum.cursor.com/t/dev-container-using-dotfiles/108724) — MEDIUM confidence
- [Dotfiles in a Workspace — DevPod docs](https://devpod.sh/docs/developing-in-workspaces/dotfiles-in-a-workspace) — MEDIUM confidence
- [My Dotfiles Setup with GNU Stow (penkin.me, 2025)](https://www.penkin.me/development/tools/productivity/configuration/2025/10/20/my-dotfiles-setup-with-gnu-stow.html) — MEDIUM confidence (couldn't fetch, found via search)
- [Using GNU Stow for deploying dotfiles (msleigh.io, 2025)](https://www.msleigh.io/blog/2025/01/31/using-gnu-stow-for-deploying-dotfiles/) — MEDIUM confidence
- Existing repo inspection (`/Users/italovietro/.dotfiles/`) — HIGH confidence (direct observation)

---
*Architecture research for: cross-platform dotfiles (macOS + Linux/devcontainer)*
*Researched: 2026-02-28*
