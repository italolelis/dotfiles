# omarchy (Omarchy only, copied, not stowed)

The Omarchy shell's config: `shell.json` (bar layout, enabled plugins, dock, idle)
and `touchbar.json` (the Touch Bar strip, read by the
`io.github.austindixson.touchbar` plugin).

- **Not a stow package** (`NOT_PACKAGES` in `bin/.local/bin/dot-packages`). Omarchy
  writes `shell.json` with `mktemp` + `mv`, which replaces a symlink with a plain
  file on the first `omarchy bar` or `omarchy plugin` change, and the repo copy
  would silently stop tracking it. `dot-omarchy` copies instead:
  - `dot-omarchy status` / `diff`: does this machine differ from the repo?
  - `dot-omarchy apply`: repo -> `~/.config/omarchy` (backs up what it replaces),
    then renders the Touch Bar layout. `install.sh` runs it; `dot` only reports.
  - `dot-omarchy save`: `~/.config/omarchy` -> repo, then review and commit.
- **The plugins themselves** are `plugin` lines in the `Archfile`, cloned by
  `arch-bundle`. `shell.json` only places them in the bar; `arch-bundle dump` lists
  plugins installed here but not in the `Archfile`.
- **Touch Bar**: `apply` runs the plugin's `apply.sh`, which writes
  `/etc/tiny-dfr/config.toml` (sudo or a polkit prompt) and a marked block of key
  binds into `hypr/.config/hypr/bindings.lua`. That file is a stow link, which
  `apply.sh` refuses to follow, so `dot-omarchy` points it at the tracked file.
  The `PRINT` key is left out of `touchbar.json`'s binds on purpose: Omarchy already
  binds it to the screenshot tool, and a second bind would take two screenshots.
- This repo is public: these files hold layout and plugin ids only. Plugin
  settings that carry secrets (API keys, tokens) do not belong in `shell.json`
  here; keep them in Proton Pass and out of the bar config.
