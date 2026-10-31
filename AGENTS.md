# AGENTS.md

Personal dotfiles for macOS and Omarchy (Arch), with a Debian/Ubuntu fallback, managed
with **GNU Stow**, a **Brewfile** (macOS) and an **Archfile** (Arch). There is no build system, no test framework, and no CI — the
"application" is the user's `$HOME`, and every change here eventually gets symlinked
into it.

## The one thing to understand first

Each top-level directory is a **stow package**. Its internal structure mirrors `$HOME`
exactly. `bash/.bashrc` becomes `~/.bashrc`; `bin/.local/bin/dot` becomes
`~/.local/bin/dot`.

So: to add `~/.config/foo/bar.toml`, create `foo/.config/foo/bar.toml`. That is all:
every top-level directory is a package unless `bin/.local/bin/dot-packages` lists it in
`NOT_PACKAGES` (or in `LINUX_ONLY`, to skip it on macOS). Never create a file directly in `$HOME` and never write to a
path that is already a symlink into this repo — edit the file here instead.

`dot-packages` prints this machine's package list. The stow flags (`--target=~`,
`--no-folding`, ignores) live in `.stowrc`, which stow reads from the **current
directory** only: run stow from the repo root, or pass the flags yourself.

Not stowed: `Brewfile`, `Archfile`, `install.sh`, `macos.sh`, `assets/` (README logo).

## Setup and check commands

```bash
./install.sh --force              # full idempotent install; --force skips the prompt
~/.local/bin/dot                  # update: git pull + restow + brew/arch-bundle + mise
bash -n install.sh                # syntax check
shellcheck install.sh macos.sh bin/.local/bin/*   # lint (in the Brewfile and Archfile)
stow -nv <pkg>                    # DRY RUN, from the repo root (.stowrc) — show what stow would do
brew bundle check --file=Brewfile --verbose   # what's missing vs. the Brewfile
arch-bundle check                 # what's missing vs. the Archfile (Arch)
arch-bundle dump                  # installed here, but in neither the Archfile nor Omarchy's defaults
```

There are no tests. **Verification is running the thing**: `bash -n` plus `shellcheck`
on any script you touch, and a `stow -nv` dry run before any real stow.

`install.sh` must stay idempotent — safe to re-run on an already-configured machine.
It uses `stow --restow`, and every installer function checks for an existing
installation before doing work. Preserve that property in anything you add.

## Repo layout

```
bash/       .bashrc (Omarchy's stock bashrc + essential exports), .bash_profile
git/        .gitconfig, .gitignore_global
tmux/       .tmux.conf
starship/   .starship.toml
cship/      cship config (Claude Code statusline)
ghostty/    .config/ghostty/config — the terminal, on both OSes
herdr/      .config/herdr/config.toml — herdr (terminal multiplexer): tmux-style keys, UI
hypr/       .config/hypr/bindings.lua — Hyprland keybinding overrides (Linux only)
wave-xlr/   Elgato Wave XLR glue: `wave-xlr-volume` (volume keys → device headphone level)
            and the WirePlumber soft-mixer rule (Linux only; OpenXLR comes from the Archfile)
k9s/        .config/k9s/ — config, skin, aliases, hotkeys, views, flux/stern plugins
ssh/        ~/.ssh/config only — never keys
misc/       .curlrc, .editorconfig, .inputrc, .wgetrc
bin/        ~/.local/bin scripts: `dot` (update), `dot-packages` (package list), `arch-bundle` (Archfile installer)
pi/         .pi/agent/settings.json + extensions/ — pi config and custom extensions
mise/       .config/mise/config.toml — global mise tools (node, gh, claude, codex, pi)
assets/     README logo (not stowed)
Brewfile    brew + cask manifest
Archfile    pacman / AUR / Omarchy-installer manifest, read by arch-bundle
install.sh  idempotent installer (macOS + Linux)
macos.sh    macOS system defaults — run manually, needs a reboot
```

## Gotchas that will bite you

**Every top-level directory gets stowed.** `dot-packages` replaced two hand-kept
`PACKAGES` arrays that had silently diverged. The flip side: a new top-level directory
that is *not* a package (like `assets/`) must go in `NOT_PACKAGES`, or `dot` will
symlink its contents into `$HOME`. Hidden directories (`.git`, `.vscode`) are skipped.

**Omarchy's tools break symlinks.** `omarchy-display-text-size` edits
`~/.config/ghostty/config` with `sed -i`, which writes a new regular file over the
symlink. The repo copy goes stale and the next `dot` stops on a stow conflict. To keep
the live version: `stow --adopt --restow ghostty` from the repo root (moves the file
into the repo, relinks), then review `git diff`. Any Omarchy command that rewrites a
stowed file has the same effect.

**A stow package with no files under a `$HOME`-shaped path stows nothing.** A package
(the since-removed `cmux/`) once held only a stow-ignored reference file, so it was
inert while the real config sat untracked in `~/.config/`. If a package seems to do nothing, run
`find <pkg> -type f` and confirm the paths actually mirror `$HOME`.

**k9s on macOS ignores `~/.config/k9s` by default.** It reads
`~/Library/Application Support/k9s` unless `K9S_CONFIG_DIR` is set, which `bash/.bashrc`
does. Remove that export and the entire `k9s` package goes inert with no error — the
same class of bug as the inert package above. Verify with `k9s info`, which
prints the paths it will actually use.

**k9s config schemas are not uniform.** `config.yaml` is nested under a `k9s:` root key;
`views.yaml`, `aliases.yaml`, `hotkeys.yaml` and `plugins.yaml` are not. A wrong root is
not a crash — it is one `WRN Validation failed` line in `~/.local/state/k9s/k9s.log` and
a silently ignored file. Check that log after editing any of them.

**The k9s node plugins depend on SSH host aliases.** `Ctrl-O` and `Ctrl-L` run
`ssh $NAME` with the Kubernetes node name, which works only because `ssh/.ssh/config`
defines `oracle`, `tank` and `cypher` with exactly those names.

**One terminal everywhere: Ghostty + herdr.** cmux was dropped (2026-10-30); macOS
gets the Ghostty cask and herdr from the Brewfile, Omarchy installs Ghostty through
`omarchy-install-terminal` (Archfile) and ships herdr. The one `ghostty` config serves
both: it imports Omarchy's live theme with `config-file = ?...` (the `?` makes it
optional, so macOS falls back to the default theme), and its Linux-only keys
(`gtk-*`, `async-backend`) are ignored on macOS. Keep any new option either
cross-platform or harmless on the other OS. It started as Omarchy's stock config (`/usr/share/omarchy/config/ghostty/config`), so
diff against that to see what's actually customized. `omarchy refresh config
ghostty/config` copies the stock file through the symlink, overwriting the tracked one;
check `git diff` after it. Validate edits with `ghostty +validate-config`.

**Only `config.toml` from `~/.config/herdr` is tracked.** The same directory holds
herdr's sockets, logs and `session.json` (open workspaces); `--no-folding` is what
keeps them out of the repo. Apply edits with `prefix+q` (`reload_config`).

**Only `bindings.lua` from `~/.config/hypr` is tracked.** The rest (`monitors.lua`,
`hyprland.lua`, ...) is per machine. After editing it, run `hyprctl reload` then
`hyprctl configerrors`; Omarchy's defaults bind the volume keys first, so the
`hl.unbind` lines in it must stay before the `o.bind` lines that replace them.

**Wave XLR: the hardware mixer is half broken.** Reading its `Mic` control fails
(`broken mixer GET_CUR` in `dmesg`), so the WirePlumber rule keeps PipeWire on a soft
mixer, and `wave-xlr-volume` writes only the `PCM` control (the headphone level). The
mic-goes-silent bug is fixed by OpenXLR's packaged `52-openxlr-mk1-capture-hold.conf`,
not by anything here. The rule matches any Wave XLR by name pattern on purpose: a
unit's serial number does not belong in this public repo.

**`DOTFILES` is a fixed constant (`$HOME/.dotfiles`), deliberately not derived from
`BASH_SOURCE`.** Leave it that way; deriving it broke curl-piped installs.

**`install.sh` backs up conflicts before stowing.** Real files (not symlinks) that
would collide get moved to `~/.backup/dotfiles_<timestamp>/`. Don't bypass
`backup_conflicts`; a bad stow otherwise silently destroys real config.

**`brew bundle` never uninstalls.** Removing a line from the Brewfile only affects
fresh machines. Say so explicitly rather than implying something got removed. Do not
run `brew bundle cleanup` — this machine intentionally has many apps outside the
Brewfile, and cleanup would remove them.

**The Linux path also covers Arch/Omarchy.** The `Archfile` is the Brewfile equivalent;
`bin/.local/bin/arch-bundle` installs it (`install.sh` calls it by repo path because `bin`
isn't stowed yet; `dot` calls it too). Add a package to the Brewfile and you probably want
it in the Archfile too. Entries are `pacman`, `aur`, `omarchy <pkg> <installer> [args]`
(runs `omarchy-<installer>` only when `<pkg>` is missing) and `ignore` (hides a package
from `arch-bundle dump`). Like `brew bundle`, `arch-bundle` never uninstalls.
Omarchy's defaults (`/usr/share/omarchy/install/omarchy-*.packages`) don't belong in the
Archfile; `dump` filters them out. Node, gh, claude, codex and pi come from mise on
Omarchy: `mise/.config/mise/config.toml` is stowed, so `mise use -g` edits the tracked
file, and `install_mise_tools` runs before `install_pi` so pi comes from mise, not npm. Nothing machine-specific goes into
`git/.gitconfig`: the credential helper is written to the untracked `~/.gitconfig.local`,
and the editor comes from `EDITOR`/`GIT_EDITOR` in `bash/.bashrc`.

**`bash/.bashrc` is tracked in git.** Secrets go in `~/.localrc` (gitignored, sourced by
`.bashrc` if present). Never put a token, key, or password in any tracked file here.

**SSH keys live in Proton Pass, not on disk.** pass-cli serves the "SSH Keys" vault on
`~/.ssh/proton-pass-agent.sock`: `ssh/.ssh/config` points every host at it
(`IdentityAgent`), `bash/.bashrc` exports `SSH_AUTH_SOCK` for `ssh-add` and git's SSH
signing, and `install.sh` starts the agent at login (a LaunchAgent on macOS, a systemd
user unit on Linux). It serves nothing until `pass-cli login` has run once. Keep the
`~/.ssh/*.pub` files: `IdentitiesOnly yes` offers only agent keys a `.pub` names.

**Never add private keys to `ssh/`.** `ssh/.stow-local-ignore` blocks the common
filenames, but that is a safety net, not permission. Only `ssh/config` belongs here.

**No real hosts in `ssh/.ssh/config` either — this repo is public.** Addresses,
usernames, ports and jump hosts go in `~/.ssh/config.local`, which is untracked and
pulled in by the `Include` at the top of the tracked file. `Include` is first on
purpose: ssh takes the first value obtained for each keyword, so the local file wins.
The homelab entries there are generated by `make ssh-config` in the private homelab
repo, from its Ansible inventory. The same rule applies to shell functions — use the
Host alias (`ssh -t oracle`), never `user@ip`.

## Style conventions

Shell scripts: `#!/usr/bin/env bash`, `set -euo pipefail`, 2-space indent, and the
existing `log` / `ok` / `info` / `fail` output helpers. Section headers use the
`# ── Name ───` box-drawing style. Quote variable expansions. Prefer
`command -v foo &>/dev/null` for capability checks.

Keep `bash/.bashrc` thin: Omarchy's stock bashrc first, then only exports something
breaks without. Interactive niceties come from Omarchy's defaults, not this repo.
macOS-only logic must be guarded — the Linux path is real and used.

When you remove something non-obvious, leave a dated comment explaining why (see the
`NODE_ENV` note in `bash/.bashrc` for the pattern).

## Commit conventions

Conventional Commits, as seen in `git log`: `feat:`, `fix:`, `chore:`, `docs:`,
`refactor:`. A scope is used when the change belongs to a package or plan, e.g.
`feat(cship): ...`, `feat(k9s): ...`.

Do not commit unless asked. This repo frequently carries unrelated uncommitted
changes — some machine-generated (Rancher Desktop appends a PATH block to the shell rc).
Check `git status` and stage deliberately rather than using `git commit -a`.

## pi configuration

`pi/.pi/agent/settings.json` is stowed to `~/.pi/agent/settings.json` and is the
**single source of truth** for the package list, theme, and default model. There is
no separate manifest to keep in sync — `install_pi_packages` in `install.sh` parses
that file (with `node`, not `jq`, so the Linux path needs no extra dependency) and
runs `pi install <spec>` only for packages not already present.

Because it is a symlink into this repo, `pi install` and `pi remove` edit the tracked
file directly. That is deliberate: extension changes show up in `git status` instead
of silently diverging. It also means **pi writes to the repo on its own** —
`lastChangelogVersion` bumps on version upgrades and will appear as a stray diff.
Commit or discard it; it is not a conflict.

`install_pi` runs *after* `stow_packages` in `main()`. Keep that order: it ensures
`pi install` records new packages in the tracked settings file rather than in one
that stow is about to replace.

Custom extensions are plain `.ts` files in `pi/.pi/agent/extensions/`. Drop a file in
and it is picked up — no registration step.

**Never track `~/.pi/agent/auth.json` or `~/.pi/agent/mcp.json`.** Both hold live
credentials (OAuth tokens and MCP server secrets). They stay local, untracked, and
outside the `pi` stow package. This repo is public.
