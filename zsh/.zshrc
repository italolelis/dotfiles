# Load the shell dotfiles, and then some:
# * ~/.path can be used to extend `$PATH`.
# * ~/.extra can be used for other settings you don't want to commit.
for file in ~/.{path,exports,aliases,functions,extra,zsh_completions}; do
	[ -r "$file" ] && [ -f "$file" ] && source "$file";
done;
unset file;

# If you come from bash you might have to change your $PATH.
# export PATH=$HOME/bin:/usr/local/bin:$PATH

# Path to your oh-my-zsh installation.
export ZSH=$HOME/.oh-my-zsh

# Set name of the theme to load --- if set to "random", it will
# load a random theme each time oh-my-zsh is loaded, in which case,
# to know which specific one was loaded, run: echo $RANDOM_THEME
# See https://github.com/ohmyzsh/ohmyzsh/wiki/Themes
# ZSH_THEME="agnoster"  # Disabled in favor of Starship

# Which plugins would you like to load?
# Standard plugins can be found in $ZSH/plugins/
# Custom plugins may be added to $ZSH_CUSTOM/plugins/
# Example format: plugins=(rails git textmate ruby lighthouse)
# Add wisely, as too many plugins slow down shell startup.
plugins=(git gh zsh-autosuggestions zsh-syntax-highlighting docker kubectl)

# Oh My Zsh settings
DISABLE_AUTO_UPDATE="false"
DISABLE_UPDATE_PROMPT="false"
COMPLETION_WAITING_DOTS="true"

source $ZSH/oh-my-zsh.sh

# Initialize Starship prompt
eval "$(starship init zsh)"

# Enhanced SSH agent management for macOS Sonoma
if [ -z "$SSH_AUTH_SOCK" ]; then
   # Check for a currently running instance of the agent
   RUNNING_AGENT="`ps -ax | grep 'ssh-agent -s' | grep -v grep | wc -l | tr -d '[:space:]'`"
   if [ "$RUNNING_AGENT" = "0" ]; then
        # Launch a new instance of the agent
        ssh-agent -s &> $HOME/.ssh/ssh-agent
   fi
   eval `cat $HOME/.ssh/ssh-agent`
fi

# Warp terminal integration (replaces iTerm2)
if [[ "$TERM_PROGRAM" == "WarpTerminal" ]]; then
    # Warp-specific configurations
    export WARP_ENABLE_SHELL_INTEGRATION=true
fi

# macOS Sonoma specific optimizations
if [[ "$OSTYPE" == "darwin"* ]]; then
    # Enable Homebrew completions
    if type brew &>/dev/null; then
        FPATH="$(brew --prefix)/share/zsh/site-functions:${FPATH}"
        autoload -Uz compinit
        compinit
    fi

    # Better performance for large directories
    zstyle ':completion:*' accept-exact '*(N)'
    zstyle ':completion:*' use-cache on
    zstyle ':completion:*' cache-path ~/.zsh/cache
fi

# Enhanced history settings
setopt HIST_IGNORE_ALL_DUPS
setopt HIST_REDUCE_BLANKS
setopt HIST_VERIFY
setopt SHARE_HISTORY
setopt EXTENDED_HISTORY
