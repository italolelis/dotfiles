# hypr (Omarchy only)

- **Only `bindings.lua` and `looknfeel.lua` are tracked.** The rest of `~/.config/hypr`
  (`monitors.lua`, `hyprland.lua`, ...) is per machine.
- **`looknfeel.lua`** turns the gaps off (`gaps_in`/`gaps_out` 0, border kept to show
  focus). Everything else in it is Omarchy's commented examples.
- **`bindings.lua` has a block the Touch Bar plugin owns**, between the
  `io.github.austindixson.touchbar` markers. `dot-omarchy apply` regenerates it from
  `omarchy/touchbar.json`; edit that file, not the block.
- After editing, run `hyprctl reload`, then `hyprctl configerrors`.
- Omarchy's defaults bind the volume keys first, so the `hl.unbind` lines stay before
  the `o.bind` lines that replace them.
