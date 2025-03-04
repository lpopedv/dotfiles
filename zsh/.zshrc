export ZSH="$HOME/.oh-my-zsh"

ZSH_THEME="robbyrussell"

# Zsh plugins
plugins=(git zsh-syntax-highlighting zsh-autosuggestions)

### Exports

# Neovim
export PATH="$PATH:/opt/nvim-linux-x86_64/bin" 

# Go lang
export PATH=$PATH:/usr/local/go/bin
export GOPATH=$HOME/go
export PATH=$PATH:$GOPATH/bin

# Load zsh config
source $ZSH/oh-my-zsh.sh

