# bash

`.bashrc` is Omarchy's stock bashrc (sourced first) plus only the exports something
breaks without: the Proton Pass `SSH_AUTH_SOCK` (git's SSH commit signing), PATH and
npm prefix, `KUBECONFIG` and the k9s dirs, `STARSHIP_CONFIG`, the editor, `~/.localrc`.
Prompt, mise, fzf, zoxide and aliases come from Omarchy's defaults; on macOS the Darwin
block starts the same tools by hand. Guard any macOS-only logic: the Linux path is real.

- **The rc ends with `$?` = 0.** A trailing `[[ -r f ]] && source f` leaves `$?` at 1 when
  `f` is missing, and starship opens every terminal on a red failed prompt. End with an
  `if`; `dot-check rc` enforces it.
- **Secrets go in `~/.localrc`** (untracked, sourced last), never in this public file.
- **A removal that looks arbitrary gets a dated comment** saying why (the `NODE_ENV`
  note is the pattern).
- **Test in a clean environment**, since your own shell inherits the old exports:
  `env -i HOME=$HOME USER=$USER TERM=xterm-256color PATH=/usr/bin:/bin bash -i`.

## Changing the login shell

Long-lived processes keep the old `SHELL` and start it for every new window, so the
switch is ordered, and the old shell is uninstalled last:

1. `sudo chsh -s /usr/bin/bash "$USER" && getent passwd "$USER"` must end in the new
   shell. `chsh` can fail on authentication without stopping the next command.
2. Log out and back in: Ghostty runs as one process that opens every window, and the
   systemd user environment holds `SHELL` too.
3. Restart the herdr **server**, not just its client, from a plain Ghostty window:
   `herdr server stop && herdr`. It closes every pane.
4. Only now remove the old shell (`sudo pacman -Rns zsh`). Removing it while
   `/etc/passwd` still names it leaves a login that cannot start.

`tr '\0' '\n' < /proc/<pid>/environ | grep ^SHELL=` shows what a running process will
start.
