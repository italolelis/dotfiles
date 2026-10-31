# pi

`.pi/agent/settings.json` is the **single source of truth** for pi's packages, theme and
default model. `install_pi_packages` in `install.sh` parses it (with `node`, so the
Linux path needs no extra dependency) and runs `pi install` for anything missing.

- **pi writes to this repo.** The file is a symlink, so `pi install` / `pi remove` edit
  the tracked file: extension changes show up in `git status`, which is the point.
- **pi also writes machine state into it**: `deviceId` (per machine; must not reach this
  public repo) and `lastChangelogVersion`. The `pi-settings` git clean filter
  (`.gitattributes`, defined by `install.sh`) strips both on the way into git, and
  `dot-check secrets` blocks a commit that carries a `deviceId` anyway.
- **`install_pi` runs after `stow_packages`.** Keep that order, so `pi install` records
  packages in the tracked file rather than one stow is about to replace.
- Custom extensions are `.ts` files in `.pi/agent/extensions/`: drop one in, no
  registration step.
- **`~/.pi/agent/auth.json` and `~/.pi/agent/mcp.json` stay untracked**, outside this
  package: both hold live credentials.
