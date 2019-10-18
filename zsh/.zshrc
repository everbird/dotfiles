export ZSH=/Users/everbird/.oh-my-zsh
ZSH_THEME="robbyrussell"
plugins=(git osx brew vagrant fabric gem pip python rake ruby rvm github supervisor zsh-syntax-highlighting zsh-autosuggestions zsh-completions)

# User configuration
export PATH="/usr/local/bin:/usr/bin:/bin:/usr/sbin:/sbin"
source $ZSH/oh-my-zsh.sh

# From pyenv installed by brew
if which pyenv > /dev/null; then eval "$(pyenv init -)"; fi

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
