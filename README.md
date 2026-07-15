# Dotfiles

Personal dotfiles for a Linux development environment, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Overview

| Package | Tool | Description |
|---------|------|-------------|
| `doom` | [Doom Emacs](https://github.com/doomemacs/doomemacs) | Feature-rich Emacs with Evil (VI) keybindings, LSP, and multi-language support |
| `ghostty` | [Ghostty](https://ghostty.org) | GPU-accelerated terminal emulator |
| `mise` | [mise](https://mise.jdx.dev) | Runtime/tool version manager |
| `nvim` | [Neovim](https://neovim.io) | Editor config (Lua) |
| `scripts` | — | Standalone helper scripts (not stowed) |
| `tmux` | [tmux](https://github.com/tmux/tmux) | Terminal multiplexer config |
| `zsh` | [Zsh](https://www.zsh.org) | Shell with a native minimal prompt (git-aware, no Starship/extra installs needed), fzf, autosuggestions, and syntax highlighting |

## Installation

Clone the repository to your home directory:

```sh
git clone https://github.com/yourusername/dotfiles.git ~/Dotfiles
cd ~/Dotfiles
```

Stow one or more packages:

```sh
stow doom ghostty mise nvim tmux zsh
```

To stow a single package:

```sh
stow nvim
```

To remove a package's symlinks:

```sh
stow -D nvim
```
