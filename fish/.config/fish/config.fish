if status is-interactive
    # Aliases 
    alias v nvim

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
end
