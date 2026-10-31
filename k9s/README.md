# k9s

Config for the homelab k3s cluster: skin, aliases, hotkeys, views, flux/stern plugins.

- **macOS ignores `~/.config/k9s` by default.** k9s reads
  `~/Library/Application Support/k9s` unless `K9S_CONFIG_DIR` is set, which
  `bash/.bashrc` does. Without that export the whole package goes inert with no error.
  `k9s info` prints the paths it actually uses.
- **Config schemas are not uniform.** `config.yaml` nests under a `k9s:` root key;
  `views.yaml`, `aliases.yaml`, `hotkeys.yaml` and `plugins.yaml` do not. A wrong root is
  one `WRN Validation failed` line in `~/.local/state/k9s/k9s.log` and a silently
  ignored file: check that log after editing any of them.
- **The node plugins depend on SSH host aliases.** `Ctrl-O` and `Ctrl-L` run
  `ssh $NAME` with the node name, which works only because `ssh/.ssh/config` defines
  `oracle`, `tank` and `cypher` with exactly those names.
- Brew installs `flux` and `stern` because the plugins call them; removing either
  leaves dead keybindings.
