# Dotfiles

Personal configuration for an Arch Linux + Hyprland machine, managed with [GNU Stow](https://www.gnu.org/software/stow/).
One directory per tool, one script to bring a machine up to match this repo.

## Layout

Every top-level directory except `system/` is a stow package: its contents mirror `$HOME`, so
`hypr/.config/hypr/keybinds.lua` stows to `~/.config/hypr/keybinds.lua`.

| Package     | What it configures |
|-------------|---------------------|
| `bin`       | The `dotfiles` command: updates, release channel, releases |
| `claude`    | Claude Code user settings and English-learning skills (owner machines only) |
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
| `systemd`   | User-level systemd units, timers and login-time trace cleanup (`user-tmpfiles.d`) |
| `tmux`      | Terminal multiplexer |
| `zsh`       | Shell config, prompt, aliases |

`system/` holds installer and image-building tooling — it is not stowed:

- `system/install/` — `bootstrap.sh`, package lists (`packages.txt`, `aur.txt`), the
  `archinstall.json` profile used for the initial OS install, and `etc/` drop-ins bootstrap
  installs into `/etc` (DNS-over-TLS, firewall, sysctl hardening, log retention).
- `system/iso/` — builds a custom Arch live ISO that embeds this repo and boots straight into
  a guided installer.

## Installing it

1. Download the newest `dotfiles-*.iso` and its `.sha256` from
   [Releases](https://github.com/lpopedv/dotfiles/releases) and check them:

   ```sh
   sha256sum -c dotfiles-*.iso.sha256
   gh attestation verify dotfiles-*.iso --repo lpopedv/dotfiles
   ```

   The attestation proves the image was built by this repo's release workflow from a signed tag.
2. Write it to a USB stick (`sudo dd if=dotfiles-….iso of=/dev/sdX bs=4M status=progress oflag=sync`
   — check `/dev/sdX` with `lsblk` first) and boot from it, Secure Boot off for the install.
3. Answer the installer: Wi-Fi (if no cable), keyboard, account, computer name, time zone, disk
   and whether to encrypt it. It erases the chosen disk and installs unattended.
4. Reboot and log in on the text console: `bootstrap.sh` runs by itself on that first login.
   Reboot once more and the desktop is there. `bootstrap.sh` turns Secure Boot on when the
   firmware is in setup mode.

The installer is `system/iso/overlay/airootfs/root/install.sh`: a `gum` wizard that writes an
archinstall config (based on `system/install/archinstall.json`), validates it with archinstall's
`--dry-run` before touching the disk, then runs archinstall `--silent`. It also takes
`--answers FILE` for unattended installs and `--dry-run` to print the config it would use.

Already on Arch? Clone this repo to `~/Dotfiles` and run `system/install/bootstrap.sh`
(`--dry-run` previews it). It installs official and AUR packages, stows every package above,
installs the pinned toolchain via `mise`, and applies the system hardening. Every step checks its
own state first, so it's safe to re-run at any time.

## Updates and releases

Installed machines follow **releases**: signed `vX.Y.Z` tags. The bar's update indicator lists a
new release next to package updates, and *Update* installs both. By hand:

```sh
dotfiles status            # this machine's version, and whether a newer one exists
dotfiles update            # install the newest release and re-run bootstrap.sh
dotfiles apply             # re-run bootstrap.sh without updating
```

`dotfiles update` only installs a tag signed by a key in `.github/allowed_signers` — read from
the version the machine already runs — and refuses when `~/Dotfiles` has local changes.
Per-machine tweaks belong outside the repo, where updates never touch them:
`~/.config/hypr/local.lua` (the installer puts the keyboard layout there) and
`~/.config/git/identity` (name and email).

Two settings live in the repo's own `.git/config`, so they are per machine:

- `dotfiles channel stable|edge` — `edge` follows `main` instead of releases (`dotup` keeps
  working as an alias for `dotfiles update`).
- `dotfiles owner on|off` — owner machines also get the owner-only extras: the `claude` package
  and always-on Mullvad (`system/install/aur-owner.txt`).

### Cutting a release (owner)

```sh
dotfiles release v1.2.0    # from a clean main that matches origin
```

It makes an SSH-signed tag and pushes it; `.github/workflows/release.yml` re-checks the signature
against the previous release's signers, builds the ISO in an Arch container, attests it and
publishes it with generated notes. Signing needs, in `~/.config/git/identity`:

```ini
[user]
	signingkey = ~/.ssh/<key>.pub
[gpg]
	format = ssh
[tag]
	gpgSign = true
```

and that public key in `.github/allowed_signers` (shipped in a release signed by a key already
listed there).

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
`/tmp` is usually a RAM-backed tmpfs. The image is named after the release tag checked out
(`dotfiles-1.2.0-x86_64.iso`), or the commit otherwise; releases are built by CI, not by hand.
