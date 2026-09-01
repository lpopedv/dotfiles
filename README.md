# Dotfiles

Personal configuration for an Arch Linux + Hyprland machine, managed with [GNU Stow](https://www.gnu.org/software/stow/).
One directory per tool, one script to bring a machine up to match this repo.

## Layout

Every top-level directory except `system/` is a stow package: its contents mirror `$HOME`, so
`hypr/.config/hypr/keybinds.lua` stows to `~/.config/hypr/keybinds.lua`.

| Package     | What it configures |
|-------------|---------------------|
| `doom`      | Doom Emacs |
| `flameshot` | Screenshot tool |
| `ghostty`   | Terminal emulator |
| `git`       | Git identity and aliases |
| `gtk`       | GTK3/GTK4 dark-mode fallback for apps that skip the portal |
| `hypr`       | Hyprland, hypridle, hyprlock, hyprpaper — window manager and session |
| `lazygit`   | Git TUI |
| `mise`      | Runtime/toolchain version manager |
| `nvim`      | Neovim |
| `orca`      | Orca keybindings |
| `qt6ct`     | Qt6 theming |
| `quickshell`| Custom status bar, notifications, OSD, and session menu (QML) |
| `rofi`      | App launcher |
| `systemd`   | User-level systemd units and timers |
| `tmux`      | Terminal multiplexer |
| `zsh`       | Shell config, prompt, aliases |

`system/` holds installer and image-building tooling — it is not stowed:

- `system/install/` — `bootstrap.sh`, package lists (`packages.txt`, `aur.txt`), the
  `archinstall.json` profile used for the initial OS install, and `etc/` drop-ins bootstrap
  installs into `/etc` (DNS-over-TLS, firewall, sysctl hardening, log retention).
- `system/iso/` — builds a custom Arch live ISO that embeds this repo and boots straight into
  the installer.

## Bringing up a machine

1. Install Arch with `system/install/archinstall.json` as the `archinstall` profile (or boot
   a custom ISO built from `system/iso/build.sh`, which embeds this repo and the profile).
2. Clone this repo to `~/Dotfiles`.
3. Run the bootstrap script:

   ```sh
   system/install/bootstrap.sh              # apply
   system/install/bootstrap.sh --dry-run     # preview, changes nothing
   ```

   It installs official and AUR packages, stows every package above, installs the pinned
   toolchain versions via `mise`, and applies system hardening (DNS, firewall, sysctl, log
   retention, maintenance timers). Every step checks its own state first, so it's safe to
   re-run at any time.

To pull the latest changes and re-apply them, use the `dotup` shell function (defined in
`zsh/.zshrc`): it's `git pull --ff-only` followed by `bootstrap.sh`.

## Working with individual packages

Stow/unstow a single package from the repo root:

```sh
stow --restow <package>   # (re)link
stow -D <package>          # remove links
stow -n --restow <package> # dry run, reports conflicts without touching anything
```

## Building the installer ISO

```sh
sudo system/iso/build.sh [workdir]
```

Builds on top of the installed `archiso` package's `releng` profile plus `system/iso/overlay/`,
and clones this repo's current committed state (no local/untracked changes) into the image.
Needs 10+ GB of scratch space; defaults to `/var/tmp/archiso-work` rather than `/tmp` since
`/tmp` is usually a RAM-backed tmpfs.
