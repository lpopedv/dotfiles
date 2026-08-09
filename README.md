# Dotfiles

Personal dotfiles for a Linux development environment, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Overview

| Package | Tool | Description |
|---------|------|-------------|
| `claude` | [Claude Code](https://claude.com/claude-code) | Global slash commands — `/en` (English tutor that corrects, suggests, and logs) and `/en-review` (weekly progress review) |
| `doom` | [Doom Emacs](https://github.com/doomemacs/doomemacs) | Feature-rich Emacs with Evil (VI) keybindings, LSP, and multi-language support |
| `dunst` | [dunst](https://dunst-project.org) | Notification daemon — dark translucent theme matching Waybar/rofi |
| `flameshot` | [Flameshot](https://flameshot.org) | Screenshot tool — native Wayland capture, no tray icon |
| `ghostty` | [Ghostty](https://ghostty.org) | GPU-accelerated terminal emulator |
| `hypr` | [Hyprland](https://hypr.land) | Wayland compositor — Lua config (0.55+) split into monitors, environment, autostart, look-and-feel, input, keybinds, rules, plus `hyprpaper` |
| `mise` | [mise](https://mise.jdx.dev) | Runtime/tool version manager |
| `nvim` | [Neovim](https://neovim.io) | Editor config (Lua) |
| `rofi` | [rofi](https://github.com/davatorium/rofi) | App launcher / dmenu — vim-motion keybinds and a custom dark theme |
| `scripts` | — | Standalone helper scripts (not stowed) |
| `systemd` | [systemd](https://systemd.io) | `hyprland-session.target` — binds the Hyprland session to `graphical-session.target` |
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
stow claude doom dunst flameshot ghostty hypr mise nvim rofi systemd tmux waybar wlogout zsh
```

Install the toolchain. `mise.lock` is committed, so this resolves to the exact
versions and checksums recorded here rather than whatever is newest:

```sh
mise install --locked
```

To bump the tools deliberately, run `mise up` — it re-resolves the `latest`
entries and rewrites `mise.lock`, so the diff shows exactly what moved.

### Desktop dependencies

The Hyprland desktop packages (`hypr`, `waybar`, `rofi`, `dunst`, `flameshot`) expect:

```sh
sudo pacman -S --needed waybar rofi hyprpaper hyprpicker cliphist wl-clipboard \
  rofimoji wtype btop wiremix playerctl brightnessctl qt6ct dunst flameshot \
  polkit-kde-agent kservice ttf-jetbrains-mono-nerd adwaita-icon-theme

paru -S --needed wlogout zen-browser-bin
```

`hyprpaper` reads `~/Wallpapers/01.jpg`; `SHIFT+F12` saves screenshots to `~/Pictures/Screenshots/`.
`wtype` is what lets `rofimoji` insert the emoji instead of only opening the picker.

### Session

Log in through **SDDM**. The Hyprland wiki lists GDM as crashing Hyprland on
first launch, while SDDM and greetd work without caveats:

```sh
sudo pacman -S --needed sddm && sudo systemctl enable sddm
```

**Do not install `uwsm`.** The `hyprland` package ships a second session entry,
`hyprland-uwsm.desktop`, guarded by `TryExec=uwsm` — without the binary the
entry never shows, which is the wanted behaviour. The wiki calls uwsm
"for advanced users" with "issues and additional quirks", and the `systemd`
package here covers what it would have given us. Installing it only adds a
duplicate, confusing option to the login screen.

To stow a single package:

```sh
stow nvim
```

To remove a package's symlinks:

```sh
stow -D nvim
```
