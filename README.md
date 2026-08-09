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

### From the custom ISO

```sh
sudo pacman -S archiso
sudo ./iso/build.sh
```

The ISO lands in `iso/out/`. Write it to a stick with `dd`, boot it, and the
installer starts on its own with every answer from `install/archinstall.json`
already filled in. The TUI still asks for the three things a file should not
decide: the disk, the user, and the passwords.

It carries the repository at the commit it was built from, so after the
install the dotfiles are already in your home directory and `bootstrap.sh`
runs without a clone.

The profile is not vendored — `build.sh` copies `releng` from the installed
archiso package and lays `iso/overlay/` on top, so archiso updates arrive on
their own. Rebuild the ISO whenever this repo changes; it is a snapshot, not
a link.

### From the official ISO

Boot the official Arch ISO, then:

```sh
archinstall --config https://raw.githubusercontent.com/yourusername/dotfiles/main/install/archinstall.json
```

`install/archinstall.json` answers everything that is not disk-related:
systemd-boot on UEFI, pt_BR locale with a `br` keymap, America/Sao_Paulo,
pipewire, NetworkManager, zstd swap, open-source graphics, and a Minimal
profile — the desktop comes from `bootstrap.sh`, not from an archinstall
profile. `git` is included so the next step can run.

**`disk_config` is deliberately absent**, so archinstall still asks for the two
choices that wipe data — which device, and the filesystem — with real device
names and sizes on screen. Pick **btrfs** to match the machine this was written
on. Everything else is already filled in.

#### Other machines

The file carries no CPU model: archinstall detects the vendor and installs
`intel-ucode` or `amd-ucode` on its own, so it is not pinned to the desktop it
was written on. Check three things before reusing it elsewhere:

| Key | Change it when |
|---|---|
| `profile_config.gfx_driver` | The machine has an NVIDIA GPU — use `Nvidia (open kernel module for newer GPUs, Turing+)`. archinstall rejects `Nvidia (proprietary)` outright now, since nvidia-dkms left the Arch repos. Open-source is correct for Intel and AMD. |
| `locale_config.kb_layout` | The keyboard is not ABNT2 — use `us` for a US layout. |
| `hostname` | Always, if both machines share a network. `hostnamectl set-hostname` also works after the fact. |

`packages.txt`, `aur.txt` and `bootstrap.sh` carry no hardware assumptions and
need no per-machine changes.

Validate the file without touching any disk first:

```sh
archinstall --dry-run --config install/archinstall.json
```

Then reboot and continue below.

### On a machine that already runs Arch

```sh
git clone https://github.com/yourusername/dotfiles.git ~/Dotfiles
~/Dotfiles/install/bootstrap.sh
```

`bootstrap.sh` installs everything listed in `install/packages.txt` and
`install/aur.txt`, builds `paru` if it is missing, stows every package,
resolves the toolchain from `mise.lock`, and enables sddm and docker. Every
step checks its own state first, so it is safe to re-run on a machine that is
already set up.

Those two lists are the single source of truth for what this configuration
needs — do not repeat them here. `install/packages.txt` is grouped by purpose
and commented.

### By hand

```sh
stow claude doom dunst flameshot ghostty git hypr mise nvim rofi systemd tmux waybar wlogout zsh
mise install --locked
```

`mise install --locked` resolves to the exact versions and checksums in
`mise.lock` rather than whatever is newest. To bump the tools deliberately, run
`mise up` — it re-resolves the `latest` entries and rewrites the lockfile, so
the diff shows exactly what moved.

### Notes

`hyprpaper` reads `~/Wallpapers/01.jpg`; `SHIFT+Print` saves screenshots to
`~/Pictures/Screenshots/`. `wtype` is what lets `rofimoji` insert the emoji
instead of only opening the picker.

### Session

Log in through **SDDM** — `bootstrap.sh` enables it. The Hyprland wiki lists GDM
as crashing Hyprland on first launch, while SDDM and greetd work without
caveats.

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
