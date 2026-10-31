# ghostty

The terminal on both OSes (cmux was dropped 2026-10-30). macOS gets the Ghostty cask
from the Brewfile; Omarchy installs it through `omarchy-install-terminal` (Archfile).

- **One config serves both.** It imports Omarchy's live theme with `config-file = ?...`;
  the `?` makes it optional, so macOS falls back to the default theme. Linux-only keys
  (`gtk-*`, `async-backend`) are ignored on macOS. A new option is either cross-platform
  or harmless on the other OS.
- **It started as Omarchy's stock config** (`/usr/share/omarchy/config/ghostty/config`):
  diff against that to see what is customized.
- **Omarchy rewrites it behind the symlink.** `omarchy-display-text-size` edits it with
  `sed -i`, which writes a regular file over the link, and `omarchy refresh config
  ghostty/config` copies the stock file through it. `dot-check stow` reports the first;
  keep the live file with `stow --adopt --restow ghostty`, then `git diff`.
- Validate edits: `ghostty +validate-config` (also run by `dot-check`).
