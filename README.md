# Dotfiles

Personal dotfiles for a Linux development environment, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Overview

| Package | Tool | Description |
|---------|------|-------------|
| `claude` | [Claude Code](https://claude.com/claude-code) | Global skills — `/en` (English tutor that corrects, suggests, and logs) and `/en-review` (weekly progress review) — plus the `mono` custom theme matching nvim/ghostty |
| `doom` | [Doom Emacs](https://github.com/doomemacs/doomemacs) | Feature-rich Emacs with Evil (VI) keybindings, LSP, and multi-language support |
| `dunst` | [dunst](https://dunst-project.org) | Notification daemon — dark translucent theme matching Waybar/rofi |
| `flameshot` | [Flameshot](https://flameshot.org) | Screenshot tool — native Wayland capture, no tray icon |
| `ghostty` | [Ghostty](https://ghostty.org) | GPU-accelerated terminal emulator |
| `hypr` | [Hyprland](https://hypr.land) | Wayland compositor — Lua config (0.55+) split into monitors, environment, autostart, look-and-feel, input, keybinds, rules, plus `hyprpaper`, `hypridle`/`hyprlock` (idle lock/DPMS-off/suspend chain, monochrome lock screen matching Waybar/wlogout) and `hyprsunset` (blue-light filter, toggled from Waybar). `autostart.lua` launches Mullvad VPN's GUI itself, gated on `scripts/wait-for-tray.sh`, instead of letting the app's own "launch on start-up" race Waybar for the tray |
| `lazygit` | [lazygit](https://github.com/jesseduffield/lazygit) | Git TUI — theme colors mirror the `mono` nvim/ghostty palette |
| `mise` | [mise](https://mise.jdx.dev) | Runtime/tool version manager |
| `nvim` | [Neovim](https://neovim.io) | Editor config (Lua) |
| `rofi` | [rofi](https://github.com/davatorium/rofi) | App launcher / dmenu — vim-motion keybinds and a custom dark theme |
| `scripts` | — | Standalone helper scripts (not stowed) — `setup-cloudflare-dns.sh`, `wait-for-tray.sh` (blocks until Waybar's tray watcher is up, used by `hypr`'s autostart) |
| `systemd` | [systemd](https://systemd.io) | `hyprland-session.target` — binds the Hyprland session to `graphical-session.target` |
| `tmux` | [tmux](https://github.com/tmux/tmux) | Terminal multiplexer config |
| `waybar` | [Waybar](https://github.com/Alexays/Waybar) | Status bar — minimal i3bar-style black bottom bar, workspaces, clock, tray, custom launchers, and toggles for caffeine (idle inhibitor) and night light (`hyprsunset`) |
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

Once set up, `dotup` (a `.zshrc` function) is the everyday way to pick up
changes — `git pull` then re-run `bootstrap.sh`:

```sh
dotup             # pull + apply
dotup --dry-run   # pull + preview only
```

The rule of thumb: edit files in `~/Dotfiles`, never system config directly,
then `dotup`. `bootstrap.sh`'s idempotency is what makes that safe to run
after every change instead of tracking by hand what needs re-applying.

### By hand

```sh
stow claude doom dunst flameshot ghostty git hypr lazygit mise nvim rofi systemd tmux waybar wlogout zsh
mise install --locked
```

`mise install --locked` resolves to the exact versions and checksums in
`mise.lock` rather than whatever is newest. To bump the tools deliberately, run
`mise up` — it re-resolves the `latest` entries and rewrites the lockfile, so
the diff shows exactly what moved.

### Maintenance

Four timers keep the disk from accumulating cruft, and keep how long things
stick around short in general:

| Timer | Scope | What it does |
|---|---|---|
| `systemd-tmpfiles-clean.timer` | system, built into systemd | Ages out `/tmp` and `/var/tmp`, daily — overridden from the stock 10/30 days down to 2 (`install/etc/tmpfiles.d/tmp.conf`) |
| `paccache.timer` | system, from `pacman-contrib` | Keeps the last 3 versions of each cached package in `/var/cache/pacman/pkg`; overridden here from its default weekly to daily (`install/etc/systemd/system/paccache.timer.d/override.conf`) |
| `cliphist-wipe.timer` | user | Clears clipboard history every 2 days; day-to-day it's also capped to 50 items and ignores anything under 5 characters (`hypr`'s `autostart.lua`) |
| `zsh-history-wipe.timer` | user | Truncates `~/.zsh_history` every 2 days; `HISTSIZE`/`SAVEHIST` are also capped at 1000 |

`journald` is capped to 1 day / 100M via `/etc/systemd/journald.conf.d/10-retention.conf`
instead of growing unbounded, and coredumps (full memory snapshots of
whatever crashed) are capped to 200M and aged out after 2 days the same way
`/tmp` is (`install/etc/systemd/coredump.conf.d/`, `install/etc/tmpfiles.d/coredump.conf`).

`bootstrap.sh` installs all the drop-ins above and enables every timer;
re-running it is safe if any of them ever get disabled.

### Firewall

`nftables` ships with the desktop group but isn't enabled by anything else,
so `bootstrap.sh` installs `install/etc/nftables.conf` and enables
`nftables.service`. Unsolicited inbound traffic is dropped silently (no
reject, no ping reply — a probe sees nothing rather than "closed"); ICMPv6
keeps the specific types IPv6 needs to function (neighbor discovery, path
MTU), since those aren't an entry point.

The `forward` chain explicitly accepts `docker0`/`br-*` traffic. A published
docker-compose port arrives via `forward` after Docker's own DNAT, not
`input` — a default-drop `forward` chain with no exception there silently
breaks every published container port. Docker keeps managing its own
`iptables-nft` tables independently; this only adds a separate `inet filter`
table alongside them.

### Kernel hardening

`install/etc/sysctl.d/99-hardening.conf` sets four sysctls. Three cost
nothing in normal use: `kernel.dmesg_restrict=1` (only root can read the
kernel log - it can leak memory addresses), `kernel.kptr_restrict=2` (hides
kernel pointers from `/proc`, which make exploits easier to build), and
`kernel.sysrq=0` (disables the Alt+SysRq key combos - anyone with physical
keyboard access could otherwise reboot or kill processes with no
authentication). Named `99-` because `/etc/sysctl.d/50-default.conf` also
sets `kernel.sysrq` and later filenames win.

The fourth, `kernel.yama.ptrace_scope=2`, has a real trade-off: only root
can `ptrace` at all (Arch's default of `1` already limits it to a
process's own children, which blocks the realistic threat of one process
reading another's memory - `2` closes the gap further). The cost is
needing `sudo` for `gdb`/`strace`/`ltrace` on a process you didn't spawn
as that debugger's own child. Doesn't affect BEAM/Elixir tooling (`iex`,
`:observer`, `:dbg`) - that's VM-level introspection, not OS ptrace.

`cliphist-wipe.service` and `zsh-history-wipe.service` (see Maintenance
above) also run sandboxed - `ProtectSystem=strict` plus a single
`ReadWritePaths=` exception each, `NoNewPrivileges`, no kernel/device/namespace
access, syscalls filtered to `@system-service`. Neither needs more than
write access to the one file or directory it touches.

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
