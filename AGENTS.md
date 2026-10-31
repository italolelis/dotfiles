# AGENTS.md

Personal dotfiles for macOS and Omarchy (Arch), with a Debian/Ubuntu fallback, managed
with **GNU Stow**, a **Brewfile** (macOS) and an **Archfile** (Arch). The "application" is
the user's `$HOME`: every change here ends up symlinked into it.

## Packages

Each top-level directory is a **stow package** mirroring `$HOME`: `bash/.bashrc` becomes
`~/.bashrc`. To add `~/.config/foo/bar.toml`, create `foo/.config/foo/bar.toml` and run
`dot`. Edit files here, never through a path in `$HOME` you have not checked is a link.

- **Every top-level directory gets stowed** unless `bin/.local/bin/dot-packages` lists it
  in `NOT_PACKAGES` (or `LINUX_ONLY`, skipped on macOS). Hidden directories are skipped.
  `dot-packages` prints this machine's list.
- **Stow's flags live in `.stowrc`** (`--target=~`, `--no-folding`), which stow reads from
  the current directory only: run stow from the repo root.
- **Before editing a package, read its `README.md`** when it has one: package-specific
  gotchas live there. Stow never links a package's `README.*`.

## Commands

```bash
dot-check                         # the guardrail: scripts, rc, stow, secrets, ghostty (pre-commit hook + CI)
stow -nv <pkg>                    # dry run, from the repo root
./install.sh --force              # full idempotent install
dot                               # update: git pull, dot-check stow, restow, brew/arch-bundle, mise
brew bundle check --file=Brewfile --verbose   # missing vs. the Brewfile
arch-bundle check | dump          # missing vs. / installed but not in the Archfile
```

`dot-check` must pass before a commit; the hook runs it, and CI runs it (`--ci`, no
ghostty) on every push and PR. When it misses a class of mistake, extend `dot-check`
rather than writing a rule here.

## Gotchas

- **Apps rewrite stowed files behind the link** (Omarchy's `sed -i`, `omarchy refresh
  config`). `dot-check stow` lists them; `stow --adopt --restow <pkg>` keeps the live
  file, then review `git diff`.
- **A package with no files under a `$HOME`-shaped path stows nothing**, silently. If one
  seems inert, `find <pkg> -type f` and check the paths mirror `$HOME`.
- **`install.sh` stays idempotent** (`stow --restow`, every installer checks before
  acting) and **backs up conflicts** to `~/.backup/dotfiles_<timestamp>/` via
  `backup_conflicts`. Keep both properties.
- **`DOTFILES` is the fixed `$HOME/.dotfiles`**, not derived from `BASH_SOURCE`: deriving
  it broke curl-piped installs.
- **Brewfile and Archfile only add.** Removing a line affects fresh machines only; say so.
  `brew bundle cleanup` would remove the many apps intentionally outside the Brewfile.
  A tool added to one usually belongs in the other; Omarchy's own defaults
  (`/usr/share/omarchy/install/omarchy-*.packages`) stay out of the Archfile. Its entry
  types are documented at its top.

## This repo is public

Secrets go in `~/.localrc`; real ssh hosts in `~/.ssh/config.local`; machine git settings
in `~/.gitconfig.local`; SSH keys in Proton Pass. Tracked files carry none of them
(details: `ssh/README.md`, `pi/README.md`).

## Style

Shell scripts: `#!/usr/bin/env bash`, `set -euo pipefail`, 2-space indent, quoted
expansions, `command -v foo &>/dev/null` for capability checks, the `log` / `ok` / `info`
/ `fail` helpers, and `# ── Name ───` section headers. Commit scopes name the package
(`feat(k9s): …`). This repo often carries machine-written uncommitted changes (pi's
settings, Rancher Desktop's PATH block): stage by name.
