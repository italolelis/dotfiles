# hypr (Omarchy only)

- **Only `bindings.lua` is tracked.** The rest of `~/.config/hypr` (`monitors.lua`,
  `hyprland.lua`, ...) is per machine.
- After editing, run `hyprctl reload`, then `hyprctl configerrors`.
- Omarchy's defaults bind the volume keys first, so the `hl.unbind` lines stay before
  the `o.bind` lines that replace them.
