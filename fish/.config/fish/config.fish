if status is-interactive
    # Disable welcome message
    set -U fish_greeting

    ## Aliases ##
    alias v nvim
    alias ls "eza --icons"
    alias dot "cd ~/Dotfiles"

    ## PATH Configuration ##
    # Note: Earlier entries take precedence over later ones
    set -gx PATH "$HOME/.asdf/shims" $PATH        # ASDF-managed tools (Erlang, Elixir, Node.js, etc.)
    set -gx PATH "$HOME/.local/bin" $PATH         # User-installed binaries
    set -gx PATH "$HOME/.config/emacs/bin" $PATH  # Doom Emacs binaries
    set -gx PATH $PATH $HOME/go/bin               # Go-installed packages

    ## Environment Configuration ##
    
    # Direnv: Automatically load/unload environment variables based on directory
    if command -v direnv >/dev/null
        direnv hook fish | source
    end

    # Pnpm: Node.js package manager
    set -gx PNPM_HOME "$HOME/.local/share/pnpm"
    if not string match -q -- $PNPM_HOME $PATH
        set -gx PATH "$PNPM_HOME" $PATH
    end

    # Terminal color support
    set -gx TERM xterm-256color
    set -gx COLORTERM truecolor
end
