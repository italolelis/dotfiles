# ~/.bashrc — Omarchy's stock bashrc plus the few exports this setup depends on.
# Everything interactive (prompt, mise, fzf, zoxide, eza aliases) comes from
# Omarchy's defaults; keep additions here to what something actually breaks without.

# Omarchy environment (OMARCHY_PATH + PATH), needed even for non-interactive shells
[[ -r /usr/share/omarchy/default/bash/env-bootstrap ]] && source /usr/share/omarchy/default/bash/env-bootstrap

# If not running interactively, don't do anything else (leave this above the rc source)
[[ $- != *i* ]] && return

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
[[ -n "${OMARCHY_PATH:-}" && -r "$OMARCHY_PATH/default/bash/rc" ]] && source "$OMARCHY_PATH/default/bash/rc"

# ── macOS ─────────────────────────────────────────────────────────────────────
# No Omarchy defaults there: put Homebrew on PATH and start the same tools by hand.
if [[ "$OSTYPE" == darwin* ]]; then
  for brew in /opt/homebrew/bin/brew /usr/local/bin/brew; do
    [[ -x "$brew" ]] && { eval "$("$brew" shellenv)"; break; }
  done
  unset brew
  command -v mise &>/dev/null && eval "$(mise activate bash)"
  # Omarchy has its own prompt; macOS uses the one from the starship package.
  export STARSHIP_CONFIG="$HOME/.starship.toml"
  command -v starship &>/dev/null && eval "$(starship init bash)"
  command -v zoxide &>/dev/null && eval "$(zoxide init bash)"
  command -v fzf &>/dev/null && eval "$(fzf --bash)"
fi

# ── PATH ──────────────────────────────────────────────────────────────────────
# Prepended only when missing: on Omarchy ~/.local/bin is already there.
for dir in "$HOME/.local/bin" "$HOME/.cargo/bin" "$HOME/go/bin" "$HOME/.npm-global/bin"; do
  [[ -d "$dir" && ":$PATH:" != *":$dir:"* ]] && PATH="$dir:$PATH"
done
unset dir
export PATH

# npm -g installs land in ~/.npm-global, not in mise's node prefix (install.sh relies on it)
export npm_config_prefix="$HOME/.npm-global"
# NODE_ENV is deliberately NOT set globally: a stray value makes bundlers resolve
# dev-only exports in production builds (Next 16 rejects it, React breaks on useContext).

# ── Editor ────────────────────────────────────────────────────────────────────
# Cursor where installed; otherwise keep Omarchy's EDITOR (nvim).
if command -v cursor &>/dev/null; then
  export EDITOR="cursor" VISUAL="cursor" GIT_EDITOR="cursor --wait"
fi

# ── SSH agent: Proton Pass ────────────────────────────────────────────────────
# ssh finds the agent through IdentityAgent in ~/.ssh/config; ssh-add and git's
# SSH commit signing read SSH_AUTH_SOCK instead. Only while the socket exists,
# so the system agent stays the fallback.
[[ -S "$HOME/.ssh/proton-pass-agent.sock" ]] && export SSH_AUTH_SOCK="$HOME/.ssh/proton-pass-agent.sock"

# ── Kubernetes ────────────────────────────────────────────────────────────────
# ~/.kube/config is the homelab k3s admin credential (homelab repo, `make kubeconfig`).
export KUBECONFIG="$HOME/.kube/config"
# k9s on macOS ignores ~/.config/k9s unless told; logs stay out of the stowed repo dir.
export K9S_CONFIG_DIR="$HOME/.config/k9s"
export K9S_LOGS_DIR="$HOME/.local/state/k9s"

# ── Local-only overrides (untracked) ──────────────────────────────────────────
# Machine-specific secrets, tokens and work config go here, never in this file.
# An `if`, not `&&`: a missing file must not leave $? at 1, or starship opens
# every new terminal on a red "failed" prompt.
if [[ -r ~/.localrc ]]; then source ~/.localrc; fi
