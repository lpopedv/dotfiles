if status is-interactive
    function fish_greeting
        echo "Terminal ready." | cowsay -f dragon | lolcat
        date "+%A, %d de %B de %Y" | lolcat
    end

    # Aliases
    alias v nvim
    alias ls "eza --icons"

    # ASDF configuration code
    if test -z $ASDF_DATA_DIR
        set _asdf_shims "$HOME/.asdf/shims"
    else
        set _asdf_shims "$ASDF_DATA_DIR/shims"
    end

    if not contains $_asdf_shims $PATH
        set -gx --prepend PATH $_asdf_shims
    end
    set --erase _asdf_shims

    # Starship Theme
    starship init fish | source

    # Doom emacs
    set -gx PATH "$HOME/.config/emacs/bin" $PATH

    # Elixir Lsp
    set -gx PATH $PATH $HOME/.lsp/elixir-ls/release

    set -gx PATH PATH="$HOME/.mix/escripts:$PATH"

    # Go Binaries
    set -gx PATH $PATH $HOME/go/bin

    # Direnv configuration
    if command -v direnv >/dev/null
        direnv hook fish | source
    end

    # Pnpm
    set -gx PNPM_HOME "$HOME/.local/share/pnpm"
    if not string match -q -- $PNPM_HOME $PATH
        set -gx PATH "$PNPM_HOME" $PATH
    end

    # Load general variables
    if test -f ~/.env
        source ~/.env
    end
end
