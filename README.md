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
5. Install [`pi`](https://github.com/earendil-works/pi-coding-agent) and every extension listed in [`pi/packages.txt`](./pi/packages.txt)
6. Stow every package (`zsh`, `git`, `tmux`, `starship`, `cship`, `cmux`, `ssh`, `misc`, `bin`) into `$HOME`, backing up any conflicting regular files to `~/.backup/dotfiles_<timestamp>/`

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

- **pi extensions** — the installer reads [`pi/packages.txt`](./pi/packages.txt) and runs `pi install <spec>` for anything missing, so a fresh machine gets the same extension set. It never touches packages that are already installed.

  After adding or removing an extension locally, print the current set and reconcile the manifest by hand (the file has a comment header worth keeping):

  ```zsh
  pi list | grep -oE '(npm|git|https?):[^ ]+'
  ```

  Keep specs unversioned so `pi update --extensions` can keep them current.

- **Local-only secrets** — put env vars, tokens, work-specific config into `~/.localrc` (sourced by `~/.zshrc` if present). **Never** put secrets in `zsh/.extra` — that file is tracked in this repo.

## Layout

```
zsh/        .zshrc, .aliases, .exports, .functions, .path, .extra, completions, antidote plugins
git/        .gitconfig, .gitignore_global
tmux/       .tmux.conf
starship/   starship.toml
cship/      cship config (Claude Code statusline)
cmux/       cmux config (~/.config/cmux/cmux.json) — the only terminal managed here
pi/         packages.txt — pi extension manifest (read by install.sh, not stowed)
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
