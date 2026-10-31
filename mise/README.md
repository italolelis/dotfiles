# mise

Global tools from mise: node, gh, claude, codex, pi (on Omarchy; macOS takes node and gh
from brew).

- The config is stowed, so `mise use -g <tool>` edits the tracked file.
- `install_mise_tools` runs before `install_pi` in `install.sh`, so pi comes from mise,
  not npm. Keep that order.
