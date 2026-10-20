# ==============================================================================
# 1. Powerlevel10k Instant Prompt (keep at the very top of ~/.zshrc)
# ==============================================================================
if [[ -r "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh" ]]; then
  source "${XDG_CACHE_HOME:-$HOME/.cache}/p10k-instant-prompt-${(%):-%n}.zsh"
fi

# ==============================================================================
# 2. Environment & Cross-Platform PATH
# ==============================================================================
typeset -U path PATH

# macOS Homebrew
if [[ "$OSTYPE" == darwin* ]]; then
  if [[ -x /opt/homebrew/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv)"
  elif [[ -x /usr/local/bin/brew ]]; then
    eval "$(/opt/homebrew/bin/brew shellenv 2>/dev/null || /usr/local/bin/brew shellenv)"
  fi
  [[ -x /opt/homebrew/bin/ctags ]] && alias ctags="/opt/homebrew/bin/ctags"
fi

path=(
  "$HOME/bin"
  "$HOME/.local/bin"
  "$HOME/.emacs.d/bin"
  "$HOME/.config/emacs/bin"
  /usr/local/bin
  /usr/local/sbin
  $path
)

export VISUAL="vim"
export EDITOR="$VISUAL"
export GPG_TTY=$TTY

# Pyenv (lazy/conditional load)
if [[ -d "$HOME/.pyenv" ]]; then
  export PYENV_ROOT="$HOME/.pyenv"
  path=("$PYENV_ROOT/bin" $path)
  command -v pyenv >/dev/null 2>&1 && eval "$(pyenv init -)"
fi

# Rust / Cargo
[[ -f "$HOME/.cargo/env" ]] && source "$HOME/.cargo/env"

# ==============================================================================
# 3. Core Zsh Options & Sensible Defaults (Replaces oh-my-zsh lib)
# ==============================================================================
# History
HISTFILE="$HOME/.zsh_history"
HISTSIZE=50000
SAVEHIST=50000
setopt EXTENDED_HISTORY          # Record timestamp in history
setopt HIST_EXPIRE_DUPS_FIRST    # Expire duplicate entries first
setopt HIST_IGNORE_DUPS          # Do not record consecutive duplicate entries
setopt HIST_IGNORE_ALL_DUPS      # Delete old duplicate entry when new one is added
setopt HIST_IGNORE_SPACE         # Do not record commands starting with a space
setopt HIST_FIND_NO_DUPS         # Do not display duplicates when searching history
setopt HIST_VERIFY               # Show expanded history command before executing
setopt SHARE_HISTORY             # Share history across all active terminal sessions

# Navigation & Interaction
setopt AUTO_CD                   # Type directory name to cd into it
setopt AUTO_PUSHD                # cd pushes old directory onto directory stack
setopt PUSHD_IGNORE_DUPS         # Don't push duplicate directories onto stack
setopt PUSHD_SILENT              # Do not print directory stack after pushd/popd
setopt INTERACTIVE_COMMENTS      # Allow # comments in interactive shell
WORDCHARS='*?_-.[]~=&;!#$%^(){}<>'

# Keybindings (Emacs style + Up/Down prefix history search)
bindkey -e
autoload -U up-line-or-beginning-search down-line-or-beginning-search
zle -N up-line-or-beginning-search
zle -N down-line-or-beginning-search
bindkey '^[[A' up-line-or-beginning-search
bindkey '^[[B' down-line-or-beginning-search
bindkey '^[OA' up-line-or-beginning-search
bindkey '^[OB' down-line-or-beginning-search

# ==============================================================================
# 4. Lightweight Plugin Loader & Completion System
# ==============================================================================
ZSH_PLUGIN_DIR="${XDG_DATA_HOME:-$HOME/.local/share}/zsh/plugins"

_zsh_ensure_plugin() {
  local repo="$1"
  local name="${repo#*/}"
  local dir="$ZSH_PLUGIN_DIR/$name"
  if [[ ! -d "$dir" ]]; then
    mkdir -p "$ZSH_PLUGIN_DIR"
    echo "[zsh] Installing $repo..."
    git clone --depth 1 "https://github.com/$repo.git" "$dir" >/dev/null 2>&1
  fi
}

# Pre-completion plugin: zsh-completions
_zsh_ensure_plugin "zsh-users/zsh-completions"
[[ -d "$ZSH_PLUGIN_DIR/zsh-completions/src" ]] && fpath=("$ZSH_PLUGIN_DIR/zsh-completions/src" $fpath)

# Completion system (single cached compinit, full rebuild at most once every 24h)
autoload -Uz compinit
() {
  setopt localoptions extendedglob
  local zcompdump="${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompdump-${ZSH_VERSION}"
  mkdir -p "${zcompdump:h}"
  if [[ ! -f "$zcompdump" || -n "$zcompdump"(#qN.mh+24) ]]; then
    compinit -d "$zcompdump"
  else
    compinit -C -d "$zcompdump"
  fi
}

zstyle ':completion:*' menu select
zstyle ':completion:*' matcher-list 'm:{a-zA-Z}={A-Za-z}' 'r:|[._-]=* r:|=*' 'l:|=* r:|=*'
zstyle ':completion:*' special-dirs true
zstyle ':completion:*' use-cache yes
zstyle ':completion:*' cache-path "${XDG_CACHE_HOME:-$HOME/.cache}/zsh/zcompcache"

# Theme & Core Plugins
_zsh_ensure_plugin "romkatv/powerlevel10k"
[[ -f "$ZSH_PLUGIN_DIR/powerlevel10k/powerlevel10k.zsh-theme" ]] && \
  source "$ZSH_PLUGIN_DIR/powerlevel10k/powerlevel10k.zsh-theme"

_zsh_ensure_plugin "agkozak/zsh-z"
[[ -f "$ZSH_PLUGIN_DIR/zsh-z/zsh-z.plugin.zsh" ]] && \
  source "$ZSH_PLUGIN_DIR/zsh-z/zsh-z.plugin.zsh"

_zsh_ensure_plugin "zsh-users/zsh-autosuggestions"
[[ -f "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh" ]] && \
  source "$ZSH_PLUGIN_DIR/zsh-autosuggestions/zsh-autosuggestions.zsh"

# Syntax highlighting must be sourced last among plugins
_zsh_ensure_plugin "zsh-users/zsh-syntax-highlighting"
[[ -f "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh" ]] && \
  source "$ZSH_PLUGIN_DIR/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh"

# ==============================================================================
# 5. FZF, Aliases & Functions
# ==============================================================================
[[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh

# Find-in-file using ripgrep + fzf preview
fif() {
  if [[ "$#" -eq 0 ]]; then
    echo "Usage: fif <search-term>"
    return 1
  fi
  rg --files-with-matches --no-messages "$1" | \
    fzf --preview "highlight -O ansi -l {} 2>/dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
}

# Colorized ls & grep
if [[ "$OSTYPE" == darwin* ]]; then
  export CLICOLOR=1
  alias ls='ls -G'
else
  alias ls='ls --color=auto'
fi
alias grep='grep --color=auto'
alias ll='ls -lah'
alias la='ls -A'

# Shortcuts
alias v=vagrant
alias m=make
alias g=git
alias vi=vim
alias pyhftp="python3 -m http.server"

# ==============================================================================
# 6. Prompt Config & Local Machine Overrides
# ==============================================================================
[[ ! -f ~/.p10k.zsh ]] || source ~/.p10k.zsh
[[ ! -f ~/.zshrc.local ]] || source ~/.zshrc.local
