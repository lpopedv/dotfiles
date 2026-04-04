# Binds
bindkey "^[[H" beginning-of-line
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char
bindkey "^H" backward-kill-word
bindkey "^[[3;5~" kill-word
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# Exports
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.config/emacs/bin:$PATH
eval "$(mise activate zsh)"

# Fzf
source <(fzf --zsh)

# Plugins
source /usr/share/zsh/plugins/zsh-autosuggestions/zsh-autosuggestions.zsh
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh

# Evals
eval "$(direnv hook zsh)"

# Aliases
alias ls="eza --icons --git --links --long"
alias l="eza --icons --git --links --long"

# Starship
eval "$(starship init zsh)"
