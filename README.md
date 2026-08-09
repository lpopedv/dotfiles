# Dotfiles

Personal dotfiles for a Linux development environment, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Overview

| Package | Tool | Description |
|---------|------|-------------|
| `claude` | [Claude Code](https://claude.com/claude-code) | Global slash commands — `/en` (English tutor that corrects, suggests, and logs) and `/en-review` (weekly progress review) |
| `doom` | [Doom Emacs](https://github.com/doomemacs/doomemacs) | Feature-rich Emacs with Evil (VI) keybindings, LSP, and multi-language support |
| `dunst` | [dunst](https://dunst-project.org) | Notification daemon — dark translucent theme matching Waybar/rofi |
| `flameshot` | [Flameshot](https://flameshot.org) | Screenshot tool (Wayland/grim adapter, no tray icon) |
| `ghostty` | [Ghostty](https://ghostty.org) | GPU-accelerated terminal emulator |
| `hypr` | [Hyprland](https://hypr.land) | Wayland compositor — Lua config (0.55+) split into monitors, environment, autostart, look-and-feel, input, keybinds, rules, plus `hyprpaper` |
| `mise` | [mise](https://mise.jdx.dev) | Runtime/tool version manager |
| `nvim` | [Neovim](https://neovim.io) | Editor config (Lua) |
| `rofi` | [rofi](https://github.com/davatorium/rofi) | App launcher / dmenu — vim-motion keybinds and a custom dark theme |
| `scripts` | — | Standalone helper scripts (not stowed) |
| `tmux` | [tmux](https://github.com/tmux/tmux) | Terminal multiplexer config |
| `waybar` | [Waybar](https://github.com/Alexays/Waybar) | Status bar — minimal i3bar-style black bottom bar, workspaces, clock, tray and custom launchers |
| `wlogout` | [wlogout](https://github.com/ArtsyMacaw/wlogout) | Session menu — `phosphor` theme, square buttons |
| `zsh` | [Zsh](https://www.zsh.org) | Shell with a native minimal prompt (git-aware, no Starship/extra installs needed), fzf, autosuggestions, and syntax highlighting |

## Installation

Clone the repository to your home directory:

```sh
git clone https://github.com/yourusername/dotfiles.git ~/Dotfiles
cd ~/Dotfiles
```

Stow one or more packages:

```sh
stow claude doom dunst flameshot ghostty hypr mise nvim rofi tmux waybar wlogout zsh
```

### Desktop dependencies

The Hyprland desktop packages (`hypr`, `waybar`, `rofi`, `dunst`, `flameshot`) expect:

```sh
sudo pacman -S --needed waybar rofi hyprpaper hyprpicker cliphist wl-clipboard \
  rofimoji btop wiremix playerctl brightnessctl qt6ct dunst flameshot \
  polkit-kde-agent kservice ttf-jetbrains-mono-nerd adwaita-icon-theme

paru -S --needed wlogout zen-browser-bin
```

`hyprpaper` reads `~/Wallpapers/01.jpg`; `SHIFT+F12` saves screenshots to `~/Pictures/Screenshots/`.

To stow a single package:

```sh
stow nvim
```

To remove a package's symlinks:

```sh
stow -D nvim
```
