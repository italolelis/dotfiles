# CLI Tools
brew "coreutils"
brew "fzf"
brew "gh"
brew "httpie"
brew "jq"
brew "sops"           # encrypted secrets; in the Archfile too
brew "stow"           # Required for dotfiles management
brew "tree"
brew "unar"
brew "wget"

# Proton Pass CLI: agents fetch secrets through it (agent-kit's proton-pass skill) as a
# scoped, audited agent token. `pass-cli update` doesn't apply to brew installs; brew upgrades it.
tap "protonpass/tap"
brew "protonpass/tap/pass-cli"

# Shell and terminal: Ghostty + herdr on both OSes (herdr's config is the `herdr`
# package, Ghostty's the `ghostty` package)
brew "herdr"
brew "starship"
brew "tmux"
cask "ghostty"

# Development
brew "bun"
brew "docker"
brew "git-delta"
brew "go"
brew "kubectl"
brew "kubectx"

# Kubernetes — homelab k3s cluster (oracle/tank/cypher), GitOps via Flux.
# k9s config is the `k9s` stow package; flux/stern back its plugins, so
# removing either leaves dead keybindings.
tap "fluxcd/tap"
brew "k9s"
brew "helm"
brew "fluxcd/tap/flux"
brew "stern"

brew "node"
brew "python@3.11"
brew "shellcheck"
brew "uv"

# Apps
cask "arc"
cask "discord"
cask "gpg-suite"
cask "insomnia"
cask "mac-mouse-fix"
cask "maccy"
cask "proton-pass"
cask "protonvpn"
cask "rectangle"
cask "tableplus"

# Fonts
cask "font-fira-code"
cask "font-jetbrains-mono"
cask "font-jetbrains-mono-nerd-font"   # the Ghostty font; Omarchy ships it
