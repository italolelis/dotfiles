# ── 1. PATH uniqueness guard ─────────────────────────────────────────────────
# Must be FIRST, before any PATH modification, at top level (NOT in a function)
typeset -U PATH path

# ── 2. Source dotfiles ────────────────────────────────────────────────────────
# Load path → exports → aliases → functions → extra (in that order)
# .zsh_completions is no longer sourced here — ez-compinit handles compinit
for file in ~/.{path,exports,aliases,functions,extra}; do
  [[ -r "$file" ]] && source "$file"
done
unset file

# ── 3. Directory stack options ────────────────────────────────────────────────
# Lightweight OMZ directories.zsh replacement
setopt AUTO_PUSHD        # cd acts like pushd
setopt PUSHD_SILENT      # suppress stack output
setopt PUSHD_IGNORE_DUPS # no duplicate entries
setopt PUSHD_TO_HOME     # pushd with no args goes home
DIRSTACKSIZE=20

# ── 4. History settings ──────────────────────────────────────────────────────
HISTSIZE=50000
SAVEHIST=50000
HISTFILE=~/.zsh_history
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
setopt INC_APPEND_HISTORY

# ── 5. Completion styling ─────────────────────────────────────────────────────
# Replicate OMZ completion appearance: case-insensitive, colored, grouped menu
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' menu select
zstyle ':completion:*' list-colors "${(s.:.)LS_COLORS}"
zstyle ':completion:*' group-name ''
zstyle ':completion:*' use-cache on
zstyle ':completion:*' cache-path ~/.zsh/cache
zstyle ':completion:*' accept-exact '*(N)'

# ── 6. Homebrew fpath ─────────────────────────────────────────────────────────
# Must be before antidote/compinit so Homebrew completions are in fpath
if type brew &>/dev/null; then
  fpath=("$(brew --prefix)/share/zsh/site-functions" $fpath)
fi

# ── 7. antidote plugin bootstrap ──────────────────────────────────────────────
# Static file pattern: generates .zsh_plugins.zsh once, sources it on every start
# Only regenerates when .zsh_plugins.txt is newer (saves ~180ms vs antidote load)
zsh_plugins=${ZDOTDIR:-~}/.zsh_plugins
[[ -f ${zsh_plugins}.txt ]] || touch ${zsh_plugins}.txt
fpath=("$(brew --prefix)/opt/antidote/share/antidote/functions" $fpath)
autoload -Uz antidote
if [[ ! ${zsh_plugins}.zsh -nt ${zsh_plugins}.txt ]]; then
  antidote bundle <${zsh_plugins}.txt >|${zsh_plugins}.zsh
fi
source ${zsh_plugins}.zsh

# ── 7b. Custom completions ────────────────────────────────────────────────────
# Must be sourced AFTER antidote/ez-compinit so compdef calls are safe
[[ -r ~/.zsh_completions ]] && source ~/.zsh_completions

# ── 8. Key bindings ──────────────────────────────────────────────────────────
# history-substring-search bindings — MUST be after antidote source block
# Uses terminfo for terminal portability (not hardcoded escape sequences)
bindkey "$terminfo[kcuu1]" history-substring-search-up
bindkey "$terminfo[kcud1]" history-substring-search-down

# ── 9. fzf shell integration ─────────────────────────────────────────────────
# Requires fzf >= 0.48.0 (installed via Brewfile)
# Enables: Ctrl+R (history search), Ctrl+T (file picker), Alt+C (cd into dir)
if command -v fzf &>/dev/null; then
  source <(fzf --zsh)
fi

# ── 10. Starship prompt ──────────────────────────────────────────────────────
# Always last — prompt init must come after all plugins and completions
eval "$(starship init zsh)"
