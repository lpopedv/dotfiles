bindkey -e
bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char
bindkey "^H" backward-kill-word
bindkey "^[[3;5~" kill-word
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# Exports
export EDITOR=nvim
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.config/emacs/bin:$PATH
export PATH=$HOME/.opencode/bin:$PATH

# Evals
eval "$(mise activate zsh)"

# Prompt 
autoload -Uz vcs_info
autoload -Uz colors && colors
setopt PROMPT_SUBST

zstyle ':vcs_info:git:*' check-for-changes true
zstyle ':vcs_info:git:*' unstagedstr ' %F{yellow}*%f'
zstyle ':vcs_info:git:*' stagedstr ' %F{yellow}*%f'
zstyle ':vcs_info:git:*' formats ' %F{8}on%f %F{magenta}%b%f%c%u'
precmd() { vcs_info }

PROMPT='%F{cyan}%~%f${vcs_info_msg_0_}
%(?.%F{green}.%F{red})❯%f '

# Fzf
source <(fzf --zsh)

# Plugins
source /usr/share/zsh/plugins/zsh-syntax-highlighting/zsh-syntax-highlighting.zsh


# Aliases
alias ls="eza --icons --git --links --long"
alias l="eza --icons --git --links --long"
alias ai="claude"
alias v="nvim ."
alias lg="lazygit"
alias t="tmux"

norm() {
  if tmux has-session -t norm-platform 2>/dev/null; then
    if [ -n "$TMUX" ]; then
      tmux switch-client -t norm-platform
    else
      tmux attach -t norm-platform
    fi
  else
    tmuxp load ~/Workspace/norm-platform
  fi
}

dotup() {
  git -C ~/Dotfiles pull --ff-only && ~/Dotfiles/system/install/bootstrap.sh "$@"
}

HISTFILE=~/.zsh_history
HISTSIZE=1000
SAVEHIST=1000
setopt HIST_IGNORE_DUPS
setopt HIST_IGNORE_SPACE
setopt SHARE_HISTORY
setopt APPEND_HISTORY

# bun
export BUN_INSTALL="$HOME/.bun"
export PATH="$BUN_INSTALL/bin:$PATH"
