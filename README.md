# Dotfiles

Personal dotfiles for a Wayland-based Linux development environment, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Overview

| Package | Tool | Description |
|---------|------|-------------|
| `doom` | [Doom Emacs](https://github.com/doomemacs/doomemacs) | Feature-rich Emacs with Evil (VI) keybindings, LSP, and multi-language support |
| `fuzzel` | [Fuzzel](https://codeberg.org/dnkl/fuzzel) | Lightweight Wayland application launcher |
| `ghostty` | [Ghostty](https://ghostty.org) | GPU-accelerated terminal emulator |
| `hypr` | [Hyprland](https://hyprland.org) | Dynamic tiling Wayland compositor |
| `waybar` | [Waybar](https://github.com/Alexays/Waybar) | Status bar with workspaces, clock, and system info |
| `zsh` | [Zsh](https://www.zsh.org) | Shell with Starship prompt, fzf, autosuggestions, and syntax highlighting |

## Installation

Clone the repository to your home directory:

```sh
git clone https://github.com/yourusername/dotfiles.git ~/Dotfiles
cd ~/Dotfiles
```

Stow one or more packages:

```sh
stow doom fuzzel ghostty hypr waybar zsh
```

To stow a single package:

```sh
stow nvim
```

To remove a package's symlinks:

```sh
stow -D nvim
```
