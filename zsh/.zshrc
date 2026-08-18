bindkey "^[[F" end-of-line
bindkey "^[[3~" delete-char
bindkey "^H" backward-kill-word
bindkey "^[[3;5~" kill-word
bindkey "^[[1;5D" backward-word
bindkey "^[[1;5C" forward-word

# Exports
export EDITOR=nvim
export VISUAL=nvim
export PATH=$HOME/.local/bin:$PATH
export PATH=$HOME/.config/emacs/bin:$PATH
export PATH=$HOME/.opencode/bin:$PATH

# Evals
eval "$(mise activate zsh)"

# Prompt (native zsh, no external tools needed)
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

# Pull the latest dotfiles and re-apply them. bootstrap.sh is idempotent, so
# this is the only command needed to pick up config/package changes, here or
# from another machine. Args pass through, e.g. `dotup --dry-run`.
dotup() {
  git -C ~/Dotfiles pull --ff-only && ~/Dotfiles/install/bootstrap.sh "$@"
}

# History - kept short on purpose; zsh-history-wipe.timer clears the file
# outright every 2 days on top of this
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
