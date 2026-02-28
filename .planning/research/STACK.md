# Stack Research

**Domain:** Cross-platform dotfiles management (macOS + Linux/devcontainers)
**Researched:** 2026-02-28
**Confidence:** MEDIUM-HIGH (web-verified; official docs partially unavailable during research)

---

## Recommended Stack

### Core Technologies

| Technology | Version | Purpose | Why Recommended |
|------------|---------|---------|-----------------|
| GNU Stow | 2.4.0 | Dotfile symlink manager | Simplest correct tool for this project's scope. No extra state, no database — just symlinks from `~/.dotfiles/<pkg>/` to `$HOME`. Perfectly reversible. Works identically on macOS and Linux. The project's constraint (no secrets, no templating) means chezmoi's extra power is overhead, not value. |
| antidote | 1.x (latest) | Zsh plugin manager | Replaces Oh My Zsh. Pure zsh (no Rust/Go binary dep), generates a static plugin file for near-zero startup cost, supports deferred loading. Actively maintained. Simpler mental model than zinit. Faster than zinit in benchmarks. |
| Starship | v1.24.2 | Shell prompt | Shell-agnostic (works if user ever leaves zsh), written in Rust for speed, single TOML config, actively maintained. Powerlevel10k is on life support as of mid-2025 — Starship is the clear successor for new setups. |
| tmux | 3.6a | Terminal multiplexer | Already in use. Standard choice. No alternative considered. |
| TPM (Tmux Plugin Manager) | current HEAD | tmux plugin manager | De facto standard. Bootstraps itself via git clone in `install.sh`. Key binding–driven install/update. No alternatives with meaningful adoption. |
| Homebrew + Brewfile | current | macOS package management | Declarative, diffable, one-command restore (`brew bundle install`). `brew bundle dump --describe` self-documents. `mas` integration for App Store apps. macOS-only by design — that's correct for this project (Linux uses apt/native packages). |

### Supporting Libraries / Zsh Plugins

| Library | Version | Purpose | When to Use |
|---------|---------|---------|-------------|
| zsh-users/zsh-autosuggestions | latest | Fish-style inline command suggestions | Always — highest-ROI shell plugin. Load via antidote. |
| zsh-users/zsh-syntax-highlighting | latest | Real-time command syntax coloring | Always — catches typos before hitting Enter. Load via antidote, defer if startup time is sensitive. |
| zsh-users/zsh-completions | latest | Extended zsh completion definitions | Always — fills gaps in built-in completions. Load via antidote. |
| ohmyzsh/ohmyzsh (lib only) | latest | History, key bindings, completion setup | Use `kind:fpath` via antidote's `use-omz` helper if you want specific OMZ lib functions (e.g., `lib/history.zsh`). Do NOT load the full framework. |
| tmux-plugins/tmux-sensible | latest | Sane tmux defaults | Always — removes hours of manual tuning. Load via TPM. |
| tmux-plugins/tmux-resurrect | latest | Session save/restore across reboots | Always — preserves session state. Load via TPM. |
| tmux-plugins/tmux-continuum | latest | Auto-save resurrect every 15 min | Pair with tmux-resurrect. Load via TPM. |

### Development Tools / Scripts

| Tool | Purpose | Notes |
|------|---------|-------|
| `install.sh` (POSIX shell) | One-command bootstrap entry point | Detects platform (macOS/Linux), installs Homebrew on macOS, invokes Stow, installs TPM. Must be POSIX-compatible for Linux devcontainers. |
| `macos/Brewfile` | Declarative macOS package list | Symlinked to `~/Brewfile` or passed via `brew bundle --file`. Include brews, casks, mas entries. |
| `macos/defaults.sh` | macOS system preference automation | Idempotent `defaults write` commands. Source: `mathiasbynens/dotfiles` pattern is well-established. |
| `.zsh_plugins.txt` | antidote plugin list | One plugin per line, GitHub `user/repo` format. Checked into repo, lives in the `zsh/` Stow package. |
| `starship.toml` | Starship prompt config | Lives at `~/.config/starship.toml`. Stowed from `config/.config/starship.toml`. |

---

## Alternatives Considered

| Recommended | Alternative | When to Use Alternative |
|-------------|-------------|-------------------------|
| GNU Stow | chezmoi | Use chezmoi instead if: (a) files need per-machine templating (different email, hostname-specific blocks), (b) secrets need to be committed encrypted (GPG/age integration), or (c) target is Windows too. For this project, none of those apply — Stow's simplicity wins. |
| GNU Stow | yadm | Use yadm if you want git-native dotfile management with zero external dependencies. Stow is more explicit and modular; yadm uses the home dir as the git work-tree directly, which can cause confusion. |
| GNU Stow | dotbot | Use dotbot if you need YAML-configured link maps, arbitrary shell commands, and macOS/Linux conditional hooks in one tool. More powerful than Stow, more complex. Not justified for this scope. |
| antidote | sheldon | Use sheldon if you prefer a TOML config and want a Rust binary for your plugin manager. Slightly faster startup in some benchmarks. Tradeoff: adds a binary dependency (Rust-compiled), vs antidote which is pure zsh. For portability to containers with no Rust toolchain, antidote wins. |
| antidote | zinit | Avoid zinit as primary choice in 2025/2026. It was abandoned by original author, revived by community (zdharma-continuum), but carries project-continuity risk and complex DSL. Benchmark load times are worse than antidote/sheldon. |
| antidote | zsh-unplugged | Use `zsh-unplugged` (100-line script, no framework) if you want absolute minimal dependency. Viable for power users who know exactly which plugins they need. More maintenance burden. |
| Starship | Spaceship | Starship is the standard. Spaceship is zsh-only, slower, less adoption. Only consider it if you need Spaceship-specific sections not covered by Starship. |
| Starship | Powerlevel10k | Do NOT use. P10k is on life support as of June 2025. The author has explicitly stated no further major development. New setups should use Starship. |
| TPM | manual tmux plugin sourcing | Manual sourcing is viable if you have very few plugins and want zero bootstrap complexity. For 3+ plugins, TPM's key-binding-driven install is worth it. |

---

## What NOT to Use

| Avoid | Why | Use Instead |
|-------|-----|-------------|
| Oh My Zsh | 200-400ms shell startup overhead, loads all plugins eagerly, framework bloat. The main value (plugins + themes) is available without the framework via antidote + Starship. | antidote (plugins) + Starship (prompt) |
| Powerlevel10k | Author confirmed life support status June 2025. Zsh-only, no cross-shell portability. Will break on new zsh versions without upstream fixes. | Starship v1.24.2+ |
| rsync-based dotfile "install" | Copies files instead of symlinking — edits in `$HOME` don't flow back to the repo. Creates config drift (the current problem). | GNU Stow 2.4.0 |
| zinit as primary plugin manager | Community-revived project with uncertain long-term maintenance. Complex configuration DSL. Worse benchmark load times vs antidote. | antidote |
| Mackup | Syncs dotfiles via cloud (iCloud/Dropbox). Adds cloud dependency, no version control, wrong mental model for reproducible setups. | Git + GNU Stow |
| Nix/Home Manager | Correct for reproducibility maximalists, but a complete paradigm shift. Steep learning curve, different abstraction entirely. Overkill for this project's stated scope. | Homebrew + Brewfile on macOS |

---

## Stack Patterns by Variant

**macOS (full setup):**
- GNU Stow symlinks all packages
- Homebrew installs brews + casks from Brewfile
- `mas` handles App Store apps via Brewfile
- `macos/defaults.sh` sets system preferences
- antidote + Starship + tmux + TPM all installed via Brew

**Linux / devcontainer (shell essentials only):**
- `install.sh` detects Linux, skips Homebrew
- GNU Stow symlinks only: `zsh/`, `git/`, `tmux/`, `config/` packages
- apt or native package manager installs zsh, tmux, git
- antidote bootstrapped via git clone (no Brew required)
- TPM bootstrapped via git clone
- Starship installed via `curl -sS https://starship.rs/install.sh | sh`

**devcontainer dotfiles integration:**
- Repo root contains `install.sh` (the standard convention for GitHub Codespaces, Cursor, VS Code devcontainers)
- `devcontainer.json` or Cursor settings point to: `"dotfiles.repository": "username/dotfiles"`, `"dotfiles.installCommand": "install.sh"`
- `install.sh` must be POSIX-compatible (no zsh-isms), idempotent, and handle the Linux-only path
- Only shell + git packages stowed in containers (no macOS-specific packages)

---

## Version Compatibility

| Package | Compatible With | Notes |
|---------|-----------------|-------|
| tmux 3.6a | TPM (any version) | TPM requires tmux >= 1.9; 3.6a is well beyond that |
| antidote 1.x | zsh-autosuggestions, zsh-syntax-highlighting (latest) | Both plugins are in antidote's documented examples; confirmed compatible |
| Starship v1.24.2 | zsh (any modern version) | Works with zsh 5.x+; eval line goes at end of .zshrc |
| GNU Stow 2.4.0 | macOS (Homebrew), Ubuntu/Debian (apt), Arch (pacman) | `--dotfiles` flag requires 2.x; 2.4.0 fixes --dotfiles with directories |
| Brewfile | Homebrew (current) | `brew bundle` is a built-in command in modern Homebrew; no separate install |

---

## Installation

```bash
# macOS: Install Homebrew (if missing)
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# macOS: Install GNU Stow
brew install stow

# Stow packages
cd ~/.dotfiles
stow zsh git tmux config  # Linux
stow zsh git tmux config macos  # macOS (includes .macos defaults)

# macOS: Install all packages from Brewfile
brew bundle install --file=~/.dotfiles/macos/Brewfile

# Bootstrap antidote (all platforms)
git clone --depth=1 https://github.com/mattmc3/antidote.git "${ZDOTDIR:-$HOME}/.antidote"

# Bootstrap TPM (all platforms)
git clone https://github.com/tmux-plugins/tpm ~/.tmux/plugins/tpm

# Linux: Install Starship (no Homebrew)
curl -sS https://starship.rs/install.sh | sh

# macOS: Install Starship via Homebrew (already in Brewfile)
brew install starship
```

---

## Sources

- chezmoi comparison table — https://www.chezmoi.io/comparison-table/ (MEDIUM confidence — WebSearch verified)
- chezmoi v2.69.4 release — https://github.com/twpayne/chezmoi/releases (MEDIUM confidence — WebSearch verified)
- Starship v1.24.2 release — https://github.com/starship/starship/releases/tag/v1.24.2 (MEDIUM confidence — WebSearch verified)
- Starship replacing Powerlevel10k — https://hashir.blog/2025/06/powerlevel10k-is-on-life-support-hello-starship/ (MEDIUM confidence — WebSearch, 2025 article)
- antidote official site — https://antidote.sh/ (MEDIUM confidence — WebSearch verified)
- antidote vs zinit benchmark — https://github.com/rossmacarthur/zsh-plugin-manager-benchmark (MEDIUM confidence — WebSearch verified)
- GNU Stow 2.4.0 — https://www.gnu.org/software/stow/ (MEDIUM confidence — WebSearch verified, fixes --dotfiles flag)
- GNU Stow on macOS 2025 — https://www.msleigh.io/blog/2025/01/31/using-gnu-stow-for-deploying-dotfiles/ (LOW confidence — single source)
- tmux 3.6a release — https://github.com/tmux/tmux/releases (MEDIUM confidence — WebSearch verified)
- TPM — https://github.com/tmux-plugins/tpm (HIGH confidence — de facto standard, no serious alternatives)
- tmux-resurrect/tmux-continuum — https://github.com/tmux-plugins/list (MEDIUM confidence — GitHub star rankings May 2025 confirmed)
- devcontainer dotfiles convention — https://forum.cursor.com/t/dev-container-using-dotfiles/108724 (LOW confidence — forum source)
- devcontainer install.sh convention — https://devpod.sh/docs/developing-in-workspaces/dotfiles-in-a-workspace (MEDIUM confidence — official DevPod docs)
- Homebrew Brewfile best practices — https://gist.github.com/ChristopherA/a579274536aab36ea9966f301ff14f3f (MEDIUM confidence — widely referenced gist)
- antidote + Starship ZSH setup — https://hiiruki.com/blog/zsh-antidote-starship/ (LOW confidence — single blog source)

---

*Stack research for: cross-platform dotfiles management (macOS + Linux/devcontainers)*
*Researched: 2026-02-28*
