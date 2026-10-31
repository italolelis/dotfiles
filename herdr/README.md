# herdr

The terminal multiplexer on both OSes: tmux-style keys (`ctrl+space` prefix) and UI.
macOS gets it from the Brewfile; Omarchy ships it.

- **Only `config.toml` is tracked.** `~/.config/herdr` also holds herdr's sockets, logs
  and `session.json` (open workspaces); `--no-folding` keeps them out of the repo.
- Apply edits with `prefix+q` (`reload_config`).
- **herdr is a server plus clients**, like tmux. Quitting the TUI leaves the server, and
  the environment it started with, running; new panes inherit that. See
  `bash/README.md` for restarting it after a shell change.
