# git

`.gitconfig` is shared by every machine, so nothing machine-specific goes in it:

- The credential helper is platform-specific; `install.sh` writes it to the untracked
  `~/.gitconfig.local`, which `.gitconfig` includes.
- The editor comes from `EDITOR` / `GIT_EDITOR` in `bash/.bashrc` (Cursor where
  installed, Omarchy's nvim otherwise).
- Commits are signed with SSH through the Proton Pass agent (`gpg.format ssh`): when
  the agent is down, `git commit` fails. See `ssh/README.md`.

This repo's own hook and filter (`core.hooksPath`, `filter.pi-settings`) are repo-local
config set by `install.sh`'s `configure_repo_git`, not part of this package.
