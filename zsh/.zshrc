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

# Aliases
alias v='nvim'

# Load zsh config
source $ZSH/oh-my-zsh.sh

# pnpm
export PNPM_HOME="$HOME/.local/share/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac

# direnv
eval "$(direnv hook zsh)"

# bun completions
[ -s "$HOME/.bun/_bun" ] && source "$HOME/.bun/_bun"

# asdf
export PATH="${ASDF_DATA_DIR:-$HOME/.asdf}/shims:$PATH"

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
