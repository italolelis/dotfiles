# ssh

Only `~/.ssh/config`: no keys, no real hosts. This repo is public.

- **Keys live in Proton Pass**, served by pass-cli's SSH agent on
  `~/.ssh/proton-pass-agent.sock`. The config points every host at it (`IdentityAgent`),
  `bash/.bashrc` exports `SSH_AUTH_SOCK` for `ssh-add` and git's SSH commit signing, and
  `install.sh` starts the agent at login (LaunchAgent on macOS, systemd user unit on
  Linux). It serves nothing until `pass-cli login` has run once; the `proton-pass`
  skill covers a broken agent.
- **Keep the `~/.ssh/*.pub` files**: with `IdentitiesOnly yes`, ssh offers only the agent
  keys a `.pub` names.
- **Private keys stay out.** `.stow-local-ignore` blocks the common filenames as a safety
  net. It replaces stow's default ignores, so it also re-lists `README.*`.
- **Real hosts go in `~/.ssh/config.local`** (untracked, pulled in by the `Include` at
  the top). `Include` comes first on purpose: ssh takes the first value it reads for each
  keyword, so the local file wins. The homelab entries there come from `make ssh-config`
  in the private homelab repo. Shell functions use the Host alias (`ssh -t oracle`), not
  `user@ip`.
