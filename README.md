# Dotfiles

My macOS (and Linux fallback) setup, managed with [GNU Stow](https://www.gnu.org/software/stow/) and a [`Brewfile`](./Brewfile).

## One-shot install

On a fresh Mac (after installing Xcode CLT — happens automatically the first time you run `git`):

```zsh
git clone https://github.com/italolelis/dotfiles.git ~/.dotfiles && ~/.dotfiles/install.sh --force
```

That single command will:

1. Install Homebrew if missing
2. Install GNU Stow
3. Run `brew bundle` against [`Brewfile`](./Brewfile) (CLI tools + casks)
4. Install [`cship`](https://cship.dev)
5. Stow every package (`zsh`, `git`, `tmux`, `starship`, `cship`, `cmux`, `pi`, `ssh`, `misc`, `bin`) into `$HOME`, backing up any conflicting regular files to `~/.backup/dotfiles_<timestamp>/`
6. Install [`pi`](https://github.com/earendil-works/pi-coding-agent) plus every extension listed in the now-stowed `~/.pi/agent/settings.json`

After it finishes, restart your shell (or `source ~/.zshrc`).

## Post-install

- **macOS defaults** — run once, reboot after:

  ```zsh
  ~/.dotfiles/macos.sh
  ```

- **SSH key for GitHub** — generate and add to your account:

  ```zsh
  ssh-keygen -t ed25519 -C "you@example.com"
  gh auth login        # or paste ~/.ssh/id_ed25519.pub into GitHub manually
  ```

  Then switch the dotfiles remote to SSH:

  ```zsh
  git -C ~/.dotfiles remote set-url origin git@github.com:italolelis/dotfiles.git
  ```

- **pi** — `pi/.pi/agent/settings.json` is stowed to `~/.pi/agent/settings.json` and carries the package list, theme, and default model. The installer parses it and runs `pi install <spec>` for anything missing, so a fresh machine gets the same setup. Custom extensions (e.g. the Claude Code-style status line) live in `pi/.pi/agent/extensions/`.

  Since the settings file is a symlink into this repo, `pi install` / `pi remove` edit the tracked file directly — extension changes show up in `git status`. Keep specs unversioned so `pi update --extensions` can move them forward.

  `~/.pi/agent/auth.json` and `~/.pi/agent/mcp.json` hold live credentials and are **never** tracked.

- **Local-only secrets** — put env vars, tokens, work-specific config into `~/.localrc` (sourced by `~/.zshrc` if present). **Never** put secrets in `zsh/.extra` — that file is tracked in this repo.

## Layout

```
zsh/        .zshrc, .aliases, .exports, .functions, .path, .extra, completions, antidote plugins
git/        .gitconfig, .gitignore_global
tmux/       .tmux.conf
starship/   starship.toml
cship/      cship config (Claude Code statusline)
cmux/       cmux config (~/.config/cmux/cmux.json) — the only terminal managed here
pi/         pi config: settings.json (theme, model, packages) + custom extensions
ssh/        ~/.ssh/config (no keys)
misc/       miscellaneous dotfiles
bin/        ~/.local/bin scripts
Brewfile    brew + cask package manifest
install.sh  idempotent installer (macOS + Linux)
macos.sh    macOS system defaults (run manually)
```

## Updating

```zsh
cd ~/.dotfiles && git pull && ./install.sh --force
```

`install.sh` is idempotent — it uses `stow --restow` so re-running is safe.

## Linux

`install.sh` also runs on Debian/Ubuntu: installs `zsh`, `stow`, `antidote`, `starship`, `fzf`, `cship`, and `pi` without Homebrew. Casks are skipped.
