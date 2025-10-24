if status is-interactive
    function fish_greeting
#        echo "Terminal ready." | cowsay -f dragon | lolcat
 #       date "+%A, %d de %B de %Y" | lolcat
    end

    # Aliases
    alias v nvim
    alias ls "eza --icons"
    alias claude="$HOME/.claude/local/claude"

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

    # Mix escripts
    set -gx PATH PATH="$HOME/.mix/escripts:$PATH"

    # Go Binaries
    set -gx PATH $PATH $HOME/go/bin

    # General binaries
   set -gx PATH $HOME/.local/bin $PATH

    # Direnv configuration
    if command -v direnv >/dev/null
        direnv hook fish | source
    end

    # Pnpm
    set -gx PNPM_HOME "$HOME/.local/share/pnpm"
    if not string match -q -- $PNPM_HOME $PATH
        set -gx PATH "$PNPM_HOME" $PATH
    end

    set -gx TERM xterm-256color
    set -gx COLORTERM truecolor

    # Load general variables
    if test -f ~/.env
        source ~/.env
    end
end

# bun
set --export BUN_INSTALL "$HOME/.bun"
set --export PATH $BUN_INSTALL/bin $PATH

set -x RADV_PERFTEST aco
set -x AMD_VULKAN_ICD RADV
set -x VK_ICD_FILENAMES /usr/share/vulkan/icd.d/radeon_icd.x86_64.json

  # AMD gaming optimizations
  set -gx RADV_PERFTEST gpl,nggc,sam
  set -gx AMD_VULKAN_ICD RADV
  set -gx MESA_LOADER_DRIVER_OVERRIDE radeonsi
  set -gx ENABLE_VKBASALT 1
  
