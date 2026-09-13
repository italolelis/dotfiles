# AGENTS.md

Personal dotfiles for macOS (with a Debian/Ubuntu fallback), managed with **GNU Stow**
and a **Brewfile**. There is no build system, no test framework, and no CI — the
"application" is the user's `$HOME`, and every change here eventually gets symlinked
into it.

## The one thing to understand first

Each top-level directory is a **stow package**. Its internal structure mirrors `$HOME`
exactly. `zsh/.aliases` becomes `~/.aliases`; `bin/.local/bin/dot` becomes
`~/.local/bin/dot`.

So: to add `~/.config/foo/bar.toml`, create `foo/.config/foo/bar.toml` and add `foo`
to the `PACKAGES` arrays. Never create a file directly in `$HOME` and never write to a
path that is already a symlink into this repo — edit the file here instead.

Stowed packages: `zsh git tmux starship cship cmux ssh misc bin`

Not stowed: `pi/` (a manifest read by `install.sh`), `Brewfile`, `install.sh`,
`macos.sh`.

## Setup and check commands

```bash
./install.sh --force              # full idempotent install; --force skips the prompt
~/.local/bin/dot                  # update: git pull + restow + antidote + brew
bash -n install.sh                # syntax check
shellcheck install.sh macos.sh    # lint (shellcheck is in the Brewfile)
stow -nv --target="$HOME" --dir=. <pkg>   # DRY RUN — show what stow would do
brew bundle check --file=Brewfile --verbose   # what's missing vs. the Brewfile
```

There are no tests. **Verification is running the thing**: `bash -n` plus `shellcheck`
on any script you touch, and a `stow -nv` dry run before any real stow.

`install.sh` must stay idempotent — safe to re-run on an already-configured machine.
It uses `stow --restow`, and every installer function checks for an existing
installation before doing work. Preserve that property in anything you add.

## Repo layout

```
zsh/        .zshrc, .aliases, .exports, .functions, .path, .extra, completions, antidote plugins
git/        .gitconfig, .gitignore_global
tmux/       .tmux.conf
starship/   .starship.toml
cship/      cship config (Claude Code statusline)
cmux/       .config/cmux/cmux.json — cmux is the only terminal managed here
ssh/        ~/.ssh/config only — never keys
misc/       .curlrc, .editorconfig, .inputrc, .wgetrc
bin/        ~/.local/bin scripts (currently `dot`)
pi/         packages.txt — pi extension manifest, read by install.sh, NOT stowed
Brewfile    brew + cask manifest
install.sh  idempotent installer (macOS + Linux)
macos.sh    macOS system defaults — run manually, needs a reboot
```

## Gotchas that will bite you

**Two `PACKAGES` arrays exist and drift apart.** One in `install.sh`, one in
`bin/.local/bin/dot`. Adding or renaming a stow package means editing both. They have
silently diverged before.

**A stow package with no files under a `$HOME`-shaped path stows nothing.** `cmux/`
once held only a stow-ignored reference file, so the package was inert while the real
config sat untracked in `~/.config/cmux/`. If a package seems to do nothing, run
`find <pkg> -type f` and confirm the paths actually mirror `$HOME`.

**cmux is the only terminal managed here.** Ghostty was replaced by cmux; don't
reintroduce Ghostty config, casks, or packages. (cmux is Ghostty-backed internally,
so the name still appears in cmux's own docs — that's fine.)

**`DOTFILES` is a fixed constant (`$HOME/.dotfiles`), deliberately not derived from
`BASH_SOURCE`.** Leave it that way; deriving it broke curl-piped installs.

**`install.sh` backs up conflicts before stowing.** Real files (not symlinks) that
would collide get moved to `~/.backup/dotfiles_<timestamp>/`. Don't bypass
`backup_conflicts`; a bad stow otherwise silently destroys real config.

**`brew bundle` never uninstalls.** Removing a line from the Brewfile only affects
fresh machines. Say so explicitly rather than implying something got removed. Do not
run `brew bundle cleanup` — this machine intentionally has many apps outside the
Brewfile, and cleanup would remove them.

**`zsh/.extra` is tracked in git.** Secrets go in `~/.localrc` (gitignored, sourced by
`.zshrc` if present). Never put a token, key, or password in any tracked file here.

**Never add private keys to `ssh/`.** `ssh/.stow-local-ignore` blocks the common
filenames, but that is a safety net, not permission. Only `ssh/config` belongs here.

## Style conventions

Shell scripts: `#!/usr/bin/env bash`, `set -euo pipefail`, 2-space indent, and the
existing `log` / `ok` / `info` / `fail` output helpers. Section headers use the
`# ── Name ───` box-drawing style. Quote variable expansions. Prefer
`command -v foo &>/dev/null` for capability checks.

Keep zsh config in the load order `.path` → `.exports` → `.aliases` → `.functions` →
`.extra`, sourced from `.zshrc`. macOS-only logic must be guarded — the Linux path is
real and used.

When you remove something non-obvious, leave a dated comment explaining why (see the
`NODE_ENV` note in `zsh/.exports` for the pattern).

## Commit conventions

Conventional Commits, as seen in `git log`: `feat:`, `fix:`, `chore:`, `docs:`,
`refactor:`. A scope is used when the change belongs to a package or plan, e.g.
`feat(cship): ...`, `feat(cmux): ...`.

Do not commit unless asked. This repo frequently carries unrelated uncommitted
changes — some machine-generated (Rancher Desktop appends a PATH block to `.zshrc`).
Check `git status` and stage deliberately rather than using `git commit -a`.

## Adding a pi extension

`pi/packages.txt` mirrors the `packages` array in `~/.pi/agent/settings.json`.
`install.sh` reads it and runs `pi install <spec>` only for entries not already
present. Keep specs unversioned so `pi update --extensions` can move them forward.
After changing extensions locally, reconcile the file by hand:

```bash
pi list | grep -oE '(npm|git|https?):[^ ]+'
```
