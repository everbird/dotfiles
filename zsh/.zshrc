export ZSH=~/.oh-my-zsh
ZSH_THEME="robbyrussell"
plugins=(git osx vagrant brew z vagrant-prompt zsh-completions zsh-autosuggestions zsh-syntax-highlighting )

# zsh plugin config
autoload -U compinit && compinit

export VISUAL='/usr/bin/vim'
export EDITOR="$VISUAL"

# User configuration
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
source $ZSH/oh-my-zsh.sh

# Enable z
source $ZSH/plugins/z/z.sh

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
alias nest="ssh -A nest.smfc.twitter.com"
