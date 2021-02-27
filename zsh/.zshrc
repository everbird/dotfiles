export ZSH=~/.oh-my-zsh
# Only use oh-my-zsh built-in settings here, override later if zplug
# exists
ZSH_THEME="robbyrussell"
plugins=(git osx vagrant brew z fzf tmux vagrant-prompt)
## history-substring-search is required to be here to get enabled
# plugins=(git osx vagrant brew z fzf tmux vagrant-prompt history-substring-searchx)

# zsh plugin config
autoload -U compinit && compinit

export VISUAL='/usr/bin/vim'
export EDITOR="$VISUAL"

# User configuration
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
source $ZSH/oh-my-zsh.sh

# Enable z
source $ZSH/plugins/z/z.sh

# TODO
## Rust
#source $HOME/.cargo/env

# zplug
export ZPLUG_HOME=~/.zplug
if [ -e "${ZPLUG_HOME}" ]; then
    source $ZPLUG_HOME/init.zsh
    # Override $ZSH_THEME
    # zplug "dracula/zsh", as:theme

    # Async for zsh, used by pure
    zplug "mafredri/zsh-async", from:github, defer:0
    zplug "sindresorhus/pure", use:pure.zsh, from:github, as:theme
    zplug "zsh-users/zsh-autosuggestions"
    zplug "zsh-users/zsh-completions"
    zplug "zsh-users/zsh-syntax-highlighting"
    ## If you want to use zsh-syntax-highlighting along with this script, then make sure that you load it before you load this script
    # zplug "zsh-users/zsh-history-substring-search", defer:2
    zplug "agkozak/zsh-z"
    # Supports oh-my-zsh plugins and the like
    zplug "plugins/git", from:oh-my-zsh

    # ssh-multi
    zplug "everbird/d5f7f9946760e96f6efd676a518cb919", \
        from:gist, \
        as:command, \
        use:ssh-multi.sh

    # Install plugins if there are plugins that have not been installed
    if ! zplug check --verbose; then
        printf "Install? [y/N]: "
        if read -q; then
            echo; zplug install
        fi
    fi
    # Then, source plugins and add commands to $PATH
    zplug load --verbose

    if zplug check zsh-users/zsh-history-substring-search; then
        bindkey '^[[A' history-substring-search-up
        bindkey '^[[B' history-substring-search-down
    fi
fi


# Add RVM to PATH for scripting. Make sure this is the last PATH variable change.
export PATH="$PATH:$HOME/.rvm/bin"
export PATH="$PATH:$HOME/.gem/ruby/2.1.0/bin"

# Twitter MDE installed pdk for puppet
export PATH="$PATH:/opt/puppetlabs/pdk/bin"

# From pyenv installed by brew
export PYENV_ROOT="$HOME/.pyenv"
export PATH="$PYENV_ROOT/bin:$PATH"
if command -v pyenv 1>/dev/null 2>&1; then
  eval "$(pyenv init -)"
fi

# Shortcuts
alias v=vagrant
alias m=make
alias g=git
alias vi=vim

# Tools
alias pyhftp="python -m SimpleHTTPServer"
alias pyfftp="python ~/bin/pyfftp.py"

# Mars
alias mars="java -jar ~/bin/mars.jar"

export PATH="/usr/local/sbin:$PATH"
autoload -U compinit && compinit

# Twitter
alias nest='ssh -A $(for x in atlc smfc; do echo "nest.$x.twitter.com"; done | fzf)'
alias nest-smfc="ssh -A nest.smfc.twitter.com"
alias nest-atlc="ssh -A nest.atlc.twitter.com"
alias nest-tmux="ssh -A smfc-ahy-29-sr2.corpdc.twitter.com"

# fzf util
[ -f ~/.fzf.zsh ] && source ~/.fzf.zsh
# using ripgrep combined with preview
# find-in-file - usage: fif <searchTerm>
fif() {
    if [ ! "$#" -gt 0 ]; then echo "Need a string to search for!"; return 1; fi
    rg --files-with-matches --no-messages "$1" | fzf --preview "highlight -O ansi -l {} 2> /dev/null | rg --colors 'match:bg:yellow' --ignore-case --pretty --context 10 '$1' || rg --ignore-case --pretty --context 10 '$1' {}"
}

# GPG
# Without this it may result error like:
#   gpg: signing failed: Inappropriate ioctl for device
export GPG_TTY=$(tty)

export PATH="$PATH:$HOME/bin"
