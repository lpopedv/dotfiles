#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INSTALL="$DOTFILES/system/install"

DRY=0
[[ "${1:-}" == "--dry-run" ]] && DRY=1

STOW_PACKAGES=(
    claude flameshot ghostty git gtk herdr hypr lazygit mise nvim
    orca qt6ct quickshell rofi systemd tmux wallpaper zsh
)

log()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
ok()   { printf '    \033[32mok\033[0m %s\n' "$*"; }
warn() { printf '    \033[33m!\033[0m %s\n' "$*"; }
plan() { printf '    \033[36mwould\033[0m %s\n' "$*"; }

run() {
    if (( DRY )); then plan "$*"; else "$@"; fi
}

read_list() { grep -vE '^[[:space:]]*(#|$)' "$1"; }

if [[ $EUID -eq 0 ]]; then
    echo "Run as your normal user, not root. sudo is called where needed." >&2
    exit 1
fi

(( DRY )) && log "DRY RUN - nothing will be modified"

if (( ! DRY )); then
    log "Sudo"
    # Asked upfront, once, with context - the alternative is a silent sudo
    # prompt buried dozens of steps in (e.g. mid Secure Boot), which on a
    # freshly-booted login looks like the terminal just hung.
    sudo -v || { echo "sudo access is required to continue" >&2; exit 1; }
fi

log "Official packages"
mapfile -t want < <(read_list "$INSTALL/packages.txt")
mapfile -t missing < <(comm -23 \
    <(printf '%s\n' "${want[@]}" | sort -u) \
    <(pacman -Qq | sort -u))
if (( ${#missing[@]} )); then
    run sudo pacman -S --needed --noconfirm "${missing[@]}"
    (( DRY )) || ok "${#missing[@]} installed"
else
    ok "all ${#want[@]} already installed"
fi

log "AUR helper"
if command -v paru >/dev/null; then
    ok "paru already installed"
elif (( DRY )); then
    plan "build paru from the AUR"
else
    build="$(mktemp -d)"
    trap 'rm -rf "$build"' EXIT
    git clone --depth 1 https://aur.archlinux.org/paru.git "$build/paru"
    (cd "$build/paru" && makepkg -si --noconfirm)
fi

log "AUR packages"
if command -v paru >/dev/null; then
    mapfile -t aur < <(read_list "$INSTALL/aur.txt")
    mapfile -t aur_missing < <(comm -23 \
        <(printf '%s\n' "${aur[@]}" | sort -u) \
        <(pacman -Qq | sort -u))
    if (( ${#aur_missing[@]} )); then
        run paru -S --needed --noconfirm "${aur_missing[@]}"
    else
        ok "all ${#aur[@]} already installed"
    fi
else
    plan "install ${*:-AUR packages} once paru exists"
fi

log "Dotfiles"
cd "$DOTFILES"
# Every package is stowed with --no-folding. Left to fold, stow turns a
# directory it fully owns into one symlink into this repo, and whatever a
# program then writes there lands in the repo: herdr's sessions, logs and
# sockets, Claude Code's transcripts, `systemctl --user enable`'s absolute,
# user-specific links. --no-folding keeps every directory real and links only
# files; on --restow it also unfolds a directory an earlier run folded.

# Enablement links that installs from before --no-folding left in the repo.
# They hold the absolute path of whichever user created them, so they're
# dropped, not moved - systemctl --user enable below recreates them in $HOME.
for wants in "$DOTFILES"/systemd/.config/systemd/user/*.wants; do
    [[ -d "$wants" ]] && run rm -rf "$wants"
done

for pkg in "${STOW_PACKAGES[@]}"; do
    # Anything else programs wrote through a folded directory is named by
    # .gitignore: moved out to where the program looks for it. mv, not cp - a
    # same-filesystem rename keeps a running server's socket reachable. When
    # $HOME already has the path, that one is live and the repo's is stale.
    mapfile -d '' -t state < <(find "$pkg" ! -type d -print0 | git check-ignore --stdin -z)
    if (( ${#state[@]} )); then
        # Unlinked first: while folded, the $HOME path *is* the repo file.
        run stow -D "$pkg"
        for f in "${state[@]}"; do
            target="$HOME/${f#"$pkg"/}"
            # -ef: never delete what is, through a fold, the very same file.
            if [[ (-e "$target" || -L "$target") && ! "$target" -ef "$f" ]]; then
                run rm -f "$f"
            else
                run mkdir -p "$(dirname "$target")"
                run mv "$f" "$target"
            fi
        done
        # git doesn't track empty directories, so none of these are source.
        run find "$pkg" -mindepth 1 -type d -empty -delete
        (( DRY )) || ok "$pkg: moved ${#state[@]} runtime files out of the repo"
    fi

    if (( DRY )); then
        if stow -n --no-folding --restow "$pkg" >/dev/null 2>&1; then
            ok "$pkg"
        else
            warn "$pkg would conflict - resolve, then: stow --no-folding --restow $pkg"
        fi
    elif stow --no-folding --restow "$pkg" 2>/dev/null; then
        ok "$pkg"
    else
        warn "$pkg conflicts with an existing file - resolve, then: stow --no-folding --restow $pkg"
    fi
done

# A program that saves by writing a new file and renaming it over the old one
# replaces its symlink with a regular file: its changes stop reaching the repo
# and stow refuses the package. Named explicitly so it's clear what to merge.
while IFS= read -r -d '' f; do
    target="$HOME/${f#*/}"
    if [[ -f "$target" && "$(readlink -f "$target")" != "$DOTFILES/$f" ]]; then
        warn "~/${f#*/} is a regular file, not a link into the repo - diff it against $f, keep one, re-run"
    fi
done < <(git ls-files -z -- "${STOW_PACKAGES[@]}")

log "Desktop appearance"
# gtk4/libadwaita apps read theme only via gsettings/the portal, not these
# keys directly; see hypr/xdg-desktop-portal and gtk/gtk-3.0/settings.ini.
if [[ "$(gsettings get org.gnome.desktop.interface color-scheme 2>/dev/null)" == "'prefer-dark'" ]]; then
    ok "color-scheme = prefer-dark"
else
    run gsettings set org.gnome.desktop.interface color-scheme 'prefer-dark'
fi
if [[ "$(gsettings get org.gnome.desktop.interface gtk-theme 2>/dev/null)" == "'Adwaita'" ]]; then
    ok "gtk-theme = Adwaita"
else
    run gsettings set org.gnome.desktop.interface gtk-theme 'Adwaita'
fi
# Icon theme has three readers that must agree: gsettings/portal (gtk4),
# gtk-3.0/settings.ini (gtk3), qt6ct.conf (Qt, incl. quickshell). Only this one
# needs to be set imperatively.
if [[ "$(gsettings get org.gnome.desktop.interface icon-theme 2>/dev/null)" == "'Papirus-Dark'" ]]; then
    ok "icon-theme = Papirus-Dark"
else
    run gsettings set org.gnome.desktop.interface icon-theme 'Papirus-Dark'
fi
# Recent files and app-usage stats are a record of what was opened, read by
# GNOME/gtk4 apps from here. gtk3 apps get the same from settings.ini.
for key in remember-recent-files remember-app-usage; do
    if [[ "$(gsettings get org.gnome.desktop.privacy "$key" 2>/dev/null)" == false ]]; then
        ok "$key = false"
    else
        run gsettings set org.gnome.desktop.privacy "$key" false
    fi
done

log "Toolchain"
run mise install --locked

log "Pacman"
# No drop-in directory for pacman.conf, so these are edited in place.
if grep -qE '^ParallelDownloads = 20$' /etc/pacman.conf; then
    ok "ParallelDownloads = 20"
else
    run sudo sed -i -E 's/^#?[[:space:]]*ParallelDownloads[[:space:]]*=.*/ParallelDownloads = 20/' /etc/pacman.conf
fi
if grep -qE '^ILoveCandy' /etc/pacman.conf; then
    ok "ILoveCandy"
else
    run sudo sed -i '/^ParallelDownloads/a ILoveCandy' /etc/pacman.conf
fi
if grep -qE '^Color' /etc/pacman.conf; then
    ok "Color"
else
    run sudo sed -i -E 's/^#[[:space:]]*Color[[:space:]]*$/Color/' /etc/pacman.conf
fi

log "Time and DNS"
run sudo install -Dm644 "$INSTALL/etc/systemd/resolved.conf.d/10-cloudflare-dot.conf" \
    /etc/systemd/resolved.conf.d/10-cloudflare-dot.conf
run sudo install -Dm644 "$INSTALL/etc/systemd/resolved.conf.d/20-no-multicast.conf" \
    /etc/systemd/resolved.conf.d/20-no-multicast.conf

# Without these, a link's DHCP-advertised DNS (the ISP's) sits next to the
# global Cloudflare servers and gets queried too - there is no Domains=~.
for net in /etc/systemd/network/*.network; do
    [[ -e "$net" ]] || continue
    run sudo install -Dm644 "$INSTALL/etc/systemd/network/no-dhcp-dns.conf" \
        "${net}.d/10-no-dhcp-dns.conf"
done

# Same leak, NetworkManager's side (archinstall's nm_iwd manages links here).
run sudo install -Dm644 "$INSTALL/etc/NetworkManager/conf.d/10-no-dns.conf" \
    /etc/NetworkManager/conf.d/10-no-dns.conf
# Per-boot MAC/DHCP/IPv6 identity, no hostname sent. Wired is NetworkManager's
# (applied by the restart below); Wi-Fi is iwd's, which only reads its config
# at startup - restarted on change, dropping Wi-Fi for a moment.
run sudo install -Dm644 "$INSTALL/etc/NetworkManager/conf.d/20-privacy.conf" \
    /etc/NetworkManager/conf.d/20-privacy.conf
if cmp -s "$INSTALL/etc/iwd/main.conf" /etc/iwd/main.conf; then
    ok "iwd randomizes the Wi-Fi MAC"
else
    run sudo install -Dm644 "$INSTALL/etc/iwd/main.conf" /etc/iwd/main.conf
    run sudo systemctl try-restart iwd.service
fi

run sudo systemctl enable systemd-resolved.service
# restart, not enable --now: --now is a no-op if already running, and the
# drop-ins above would never be read.
run sudo systemctl reload-or-restart systemd-resolved.service

# Time: chrony with NTS instead of timesyncd (no NTS support). The two are
# declared Conflicts=, so starting chronyd stops timesyncd; disabling it keeps
# it from coming back at boot.
if [[ "$(systemctl is-enabled systemd-timesyncd.service 2>/dev/null)" == enabled ]]; then
    run sudo systemctl disable --now systemd-timesyncd.service
fi
if [[ -e /etc/systemd/timesyncd.conf.d/10-cloudflare.conf ]]; then
    run sudo rm /etc/systemd/timesyncd.conf.d/10-cloudflare.conf
fi
if cmp -s "$INSTALL/etc/chrony.conf" /etc/chrony.conf; then
    ok "chrony uses NTS"
else
    run sudo install -Dm644 "$INSTALL/etc/chrony.conf" /etc/chrony.conf
    run sudo systemctl try-restart chronyd.service
fi
if [[ "$(systemctl is-enabled chronyd.service 2>/dev/null)" == enabled ]]; then
    ok "chronyd enabled"
else
    run sudo systemctl enable --now chronyd.service
fi

# dns=none means nothing writes /etc/resolv.conf; point it at resolved's stub.
if [[ "$(readlink -f /etc/resolv.conf 2>/dev/null)" == /run/systemd/resolve/stub-resolv.conf ]]; then
    ok "resolv.conf -> systemd-resolved stub"
else
    run sudo ln -rsf /run/systemd/resolve/stub-resolv.conf /etc/resolv.conf
fi

if systemctl is-active --quiet systemd-networkd; then
    run sudo networkctl reload
fi
if systemctl is-active --quiet NetworkManager; then
    # restart, not reload-or-restart: the dns=none + systemd-resolved=false
    # change reconfigures the DNS plugin, which only a full restart applies. A
    # reload silently leaves the link's DHCP-advertised DNS registered in
    # resolved - the exact leak these drop-ins exist to close.
    run sudo systemctl restart NetworkManager
    # A restart keeps the already-active wired link's MAC; the per-boot one
    # from 20-privacy.conf takes over from the next activation (or boot).
fi

log "Maintenance timers"
run sudo install -Dm644 "$INSTALL/etc/systemd/system/paccache.timer.d/override.conf" \
    /etc/systemd/system/paccache.timer.d/override.conf
run sudo systemctl daemon-reload
run sudo systemctl enable --now systemd-tmpfiles-clean.timer paccache.timer fstrim.timer
run systemctl --user daemon-reload
run systemctl --user enable --now cliphist-wipe.timer zsh-history-wipe.timer

log "Trace retention"
# The rule throughout: on an unencrypted SSD a deleted file is only unlinked,
# its blocks linger until trimmed - so traces go to RAM (tmpfs, volatile) and
# never reach the disk, rather than being written and wiped later.
run sudo install -Dm644 "$INSTALL/etc/tmpfiles.d/tmp.conf" /etc/tmpfiles.d/tmp.conf
run sudo install -Dm644 "$INSTALL/etc/tmpfiles.d/pacman-log.conf" /etc/tmpfiles.d/pacman-log.conf

# Storage=volatile: the journal lives in /run. Storage= is only read at
# startup, so a change needs a restart, not a reload.
if cmp -s "$INSTALL/etc/systemd/journald.conf.d/10-retention.conf" \
    /etc/systemd/journald.conf.d/10-retention.conf; then
    ok "journal is volatile"
else
    run sudo install -Dm644 "$INSTALL/etc/systemd/journald.conf.d/10-retention.conf" \
        /etc/systemd/journald.conf.d/10-retention.conf
    run sudo systemctl restart systemd-journald
fi

# Storage=none: core dumps are neither kept nor processed. The zz-coredump
# tmpfiles rule only aged out dumps that are no longer written.
run sudo install -Dm644 "$INSTALL/etc/systemd/coredump.conf.d/10-retention.conf" \
    /etc/systemd/coredump.conf.d/10-retention.conf
run sudo rm -f /etc/tmpfiles.d/zz-coredump.conf
# The directory is world-readable: no sudo just to look, even in a dry run.
if [[ -n "$(find /var/lib/systemd/coredump -mindepth 1 -print -quit 2>/dev/null)" ]]; then
    run sudo find /var/lib/systemd/coredump -mindepth 1 -delete
fi

# Directories whose whole content is a trace, not state anything needs across
# a boot: logs, last logins, NetworkManager's leases and seen access points.
volatile_units=(var-log.mount var-lib-lastlog.mount var-lib-NetworkManager.mount)
for unit in "${volatile_units[@]}"; do
    run sudo install -Dm644 "$INSTALL/etc/systemd/system/$unit" "/etc/systemd/system/$unit"
done
run sudo systemctl daemon-reload
for unit in "${volatile_units[@]}"; do
    dir="$(systemd-escape --unescape --path "${unit%.mount}")"
    if [[ "$(findmnt -no FSTYPE --mountpoint "$dir" 2>/dev/null)" == tmpfs ]]; then
        ok "$dir is tmpfs"
        continue
    fi
    # Mounting over the old contents would only hide them, not delete them.
    run sudo find "$dir" -xdev -mindepth 1 -delete
    run sudo systemctl enable "$unit"
    if mountpoint -q "$dir"; then
        # /var/log: archinstall's @log subvolume is mounted there and can't be
        # swapped out under running loggers. The unit wins from the next boot.
        (( DRY )) || warn "$dir becomes tmpfs at the next reboot"
    else
        run sudo systemctl start "$unit"
    fi
done

# Once /var/log is tmpfs, the subvolume fstab still lists for it is never
# mounted again - but it keeps whatever was logged between the wipe above and
# that reboot. Mounted aside to empty it; a no-op on later runs.
if [[ "$(findmnt -no FSTYPE --mountpoint /var/log 2>/dev/null)" == tmpfs ]] &&
    read -r src fstype opts < <(findmnt --fstab -no SOURCE,FSTYPE,OPTIONS --mountpoint /var/log 2>/dev/null) &&
    [[ "$fstype" != tmpfs ]]; then
    if (( DRY )); then
        plan "empty the disk-backed /var/log ($src) behind the tmpfs"
    else
        aside="$(sudo mktemp -d)"
        sudo mount -t "$fstype" -o "$opts" "$src" "$aside"
        if [[ -n "$(sudo find "$aside" -mindepth 1 -print -quit)" ]]; then
            sudo find "$aside" -mindepth 1 -delete
            ok "emptied the disk-backed /var/log ($src)"
        else
            ok "disk-backed /var/log ($src) is empty"
        fi
        sudo umount "$aside"
        sudo rmdir "$aside"
    fi
fi

# Chromium is only a fallback browser: its whole profile lives in RAM (see
# user-tmpfiles.d/traces.conf) and is wiped at exit too. Zen keeps history and
# bookmarks - they drive URL-bar autocomplete; what goes is form history, at
# exit. Its disk cache already lives in ~/.cache (tmpfs). Zen can't drop its
# download list alone: it's part of History in Firefox-based browsers.
run sudo install -Dm644 "$INSTALL/etc/chromium/policies/managed/amnesic.json" \
    /etc/chromium/policies/managed/amnesic.json
# Zen also gets ECH (encrypted SNI: the network sees only the CDN, not the
# site) via the system resolver's HTTPS records - DNS-over-TLS already - with
# its own DNS-over-HTTPS kept off, so a VPN's resolver is never bypassed.
# Zen reads /etc/zen/policies/policies.json *instead of* the policies.json its
# package ships (the system file wins outright), so the package's own
# policies (e.g. DisableAppUpdate) are merged in underneath ours. A Zen update
# that changes them is picked up by the next run.
zen_pkg_policies=/opt/zen-browser-bin/distribution/policies.json
if [[ -e "$zen_pkg_policies" ]]; then
    zen_policies="$(python3 -I - "$zen_pkg_policies" "$INSTALL/etc/zen/policies/policies.json" <<'PY'
import json, sys
pkg, ours = (json.load(open(p)) for p in sys.argv[1:])
merged = pkg.setdefault("policies", {})
for key, value in ours["policies"].items():
    if isinstance(value, dict) and isinstance(merged.get(key), dict):
        merged[key] = {**merged[key], **value}
    else:
        merged[key] = value
print(json.dumps(pkg, indent=2))
PY
)"
    if cmp -s <(printf '%s\n' "$zen_policies") /etc/zen/policies/policies.json; then
        ok "Zen policies up to date"
    elif (( DRY )); then
        plan "install /etc/zen/policies/policies.json"
    else
        printf '%s\n' "$zen_policies" | sudo install -Dm644 /dev/stdin /etc/zen/policies/policies.json
        warn "Zen policies changed - restart Zen to apply them"
    fi
fi

# The greeter no longer preselects the last user; drop the one already saved.
run sudo install -Dm644 "$INSTALL/etc/sddm.conf.d/10-amnesic.conf" /etc/sddm.conf.d/10-amnesic.conf
if (( DRY )); then
    plan "drop any saved last user from /var/lib/sddm/state.conf"
elif sudo grep -q '^User=' /var/lib/sddm/state.conf 2>/dev/null; then
    sudo sed -i '/^User=/d' /var/lib/sddm/state.conf
fi

# ~/.cache on tmpfs: thumbnails, browser caches and download caches never touch
# the disk and are gone on reboot. Installed toolchains (mise, pnpm store,
# Claude Code) live in ~/.local/share and are untouched. Generated rather than
# shipped in etc/: the unit name and the uid/gid are derived from this user.
cache_unit="$(systemd-escape --path --suffix=mount "$HOME/.cache")"
cache_conf="[Unit]
Description=Volatile ~/.cache (tmpfs)

[Mount]
What=tmpfs
Where=$HOME/.cache
Type=tmpfs
Options=nosuid,nodev,size=4G,mode=0700,uid=$(id -u),gid=$(id -g)

[Install]
WantedBy=local-fs.target"
if cmp -s <(printf '%s\n' "$cache_conf") "/etc/systemd/system/$cache_unit"; then
    ok "$cache_unit up to date"
elif (( DRY )); then
    plan "install /etc/systemd/system/$cache_unit"
else
    printf '%s\n' "$cache_conf" | sudo install -Dm644 /dev/stdin "/etc/systemd/system/$cache_unit"
    sudo systemctl daemon-reload
fi
if [[ "$(findmnt -no FSTYPE "$HOME/.cache" 2>/dev/null)" == tmpfs ]]; then
    ok "~/.cache is tmpfs"
else
    # Mounting over the old directory would only hide it, not delete it.
    run find "$HOME/.cache" -xdev -mindepth 1 -delete
    run sudo systemctl enable --now "$cache_unit"
    (( DRY )) || warn "~/.cache is now tmpfs - restart running apps (or reboot) so they drop the old cache"
fi

# Login shell is zsh (history already in tmpfs, see zsh/.zshrc); bash only runs
# for the first-boot bootstrap and the odd script, so the same rule is enforced
# in its rc. ~/.bashrc isn't stowed - it's archinstall's skel copy.
bash_hist='HISTFILE=${XDG_RUNTIME_DIR:-/dev/shm}/bash_history'
if grep -qxF "$bash_hist" "$HOME/.bashrc" 2>/dev/null; then
    ok "bash history in tmpfs"
elif (( DRY )); then
    plan "point bash HISTFILE at tmpfs in ~/.bashrc"
else
    printf '\n%s\n' "$bash_hist" >> "$HOME/.bashrc"
fi
if [[ -e "$HOME/.bash_history" ]]; then
    run rm -f "$HOME/.bash_history"
fi

# Applies systemd/.config/user-tmpfiles.d at every user-manager start. Shipped
# with preset "enabled" but archinstall leaves it disabled.
if systemctl --user is-enabled --quiet systemd-tmpfiles-setup.service; then
    ok "user tmpfiles applied at login"
else
    run systemctl --user enable systemd-tmpfiles-setup.service
fi
# Applied now too, not just from the next login: turns the state directories
# it lists into symlinks into RAM (removing what's there) right away.
run systemd-tmpfiles --user --create

log "Firewall"
run sudo install -Dm644 "$INSTALL/etc/nftables.conf" /etc/nftables.conf
run sudo systemctl enable --now nftables.service
# Loaded directly, not restarted: --now is a no-op when already running, and
# the unit's stop flushes the whole ruleset, Docker's tables included. The
# file's own "destroy table" makes this an atomic swap of just inet filter.
run sudo nft -f /etc/nftables.conf

log "Kernel hardening"
run sudo install -Dm644 "$INSTALL/etc/sysctl.d/99-hardening.conf" /etc/sysctl.d/99-hardening.conf
run sudo rm -f /etc/sysctl.d/10-hardening.conf
run sudo sysctl --system
# Kernel command-line hardening (KSPP memory-hygiene flags) as a drop-in, not
# an edit: mkinitcpio concatenates /etc/cmdline.d/*.conf into the UKI. Only
# installed on change - the mtime must stay stable because the Secure Boot
# section below compares the UKI against it to decide whether to rebuild.
if cmp -s "$INSTALL/etc/cmdline.d/20-hardening.conf" /etc/cmdline.d/20-hardening.conf; then
    ok "kernel cmdline hardening up to date"
else
    run sudo install -Dm644 "$INSTALL/etc/cmdline.d/20-hardening.conf" /etc/cmdline.d/20-hardening.conf
fi
if cmp -s "$INSTALL/etc/cmdline.d/40-tpm.conf" /etc/cmdline.d/40-tpm.conf; then
    ok "TPM measured-OS mode off (systemd 262 NvPCR failures)"
else
    run sudo install -Dm644 "$INSTALL/etc/cmdline.d/40-tpm.conf" /etc/cmdline.d/40-tpm.conf
fi
# Lockdown only where every module can still load: Arch signs the modules it
# ships with the kernel, never out-of-tree ones (packaged into extramodules/,
# DKMS-built into updates/). Machine-dependent - a laptop may need nvidia.
unsigned=$(find /usr/lib/modules -name '*.ko*' \( -path '*/extramodules*/*' \
    -o -path '/usr/lib/modules/*/updates/*' \) -printf '%f\n' | sort -u | paste -sd' ')
if [[ -n "$unsigned" ]]; then
    warn "kernel lockdown off: out-of-tree modules can't load under it ($unsigned)"
    if [[ -e /etc/cmdline.d/30-lockdown.conf ]]; then
        run sudo rm /etc/cmdline.d/30-lockdown.conf
    fi
elif cmp -s "$INSTALL/etc/cmdline.d/30-lockdown.conf" /etc/cmdline.d/30-lockdown.conf; then
    ok "kernel lockdown (integrity) configured"
else
    run sudo install -Dm644 "$INSTALL/etc/cmdline.d/30-lockdown.conf" /etc/cmdline.d/30-lockdown.conf
fi
run sudo install -Dm644 "$INSTALL/etc/pacman.d/hooks/90-lockdown-modules.hook" \
    /etc/pacman.d/hooks/90-lockdown-modules.hook
# Takes effect only on the next boot: the command line is baked into the UKI.
# Built the way mkinitcpio builds it (non-comment lines, joined by spaces).
want_cmdline="$(grep -ha -- '^[^#]' /etc/cmdline.d/*.conf | tr -s '\n' ' ')"
if [[ "${want_cmdline% }" != "$(tr -d '\n' < /proc/cmdline)" ]]; then
    warn "kernel command line changed - active after the next reboot"
fi

log "Secure Boot"
# vmlinuz-linux is deliberately never signed (would leave the old type-1 entry
# bootable with an unverified initramfs) and the old boot entry is deliberately
# never deleted (only warned about) - this script doesn't retire it for you.
UKI=/boot/EFI/Linux/arch-linux.efi

if (( DRY )); then
    plan "record the kernel command line in /etc/cmdline.d/10-root.conf"
    plan "install the UKI mkinitcpio preset and build $UKI"
    plan "create Secure Boot keys with sbctl and sign the UKI and systemd-boot"
    plan "enroll those keys into the firmware, if it is in setup mode"
elif ! command -v sbctl >/dev/null; then
    warn "sbctl is not installed - skipping Secure Boot"
else
    # root= is machine-specific: derived from the running system, not shipped here.
    # archinstall's /etc/kernel/cmdline is preferred over /proc/cmdline as the
    # source, then removed: mkinitcpio concatenates it with /etc/cmdline.d, so
    # keeping both embeds every parameter twice.
    rebuild=0
    if [[ -e /etc/cmdline.d/10-root.conf ]]; then
        ok "kernel command line recorded"
    elif [[ -e /etc/kernel/cmdline ]]; then
        sudo install -Dm644 /etc/kernel/cmdline /etc/cmdline.d/10-root.conf
        ok "kernel command line recorded from /etc/kernel/cmdline"
    else
        tr ' ' '\n' < /proc/cmdline \
            | grep -vE '^(initrd|BOOT_IMAGE)=' \
            | awk '!seen[$0]++' \
            | paste -sd' ' \
            | sudo install -Dm644 /dev/stdin /etc/cmdline.d/10-root.conf
        ok "kernel command line recorded from /proc/cmdline"
    fi
    if [[ -e /etc/kernel/cmdline ]]; then
        sudo rm /etc/kernel/cmdline
        rebuild=1
        ok "removed /etc/kernel/cmdline (duplicated /etc/cmdline.d)"
    fi

    sudo install -Dm644 "$INSTALL/etc/mkinitcpio.d/linux.preset" /etc/mkinitcpio.d/linux.preset
    sudo install -d -m755 /boot/EFI/Linux

    if (( ! rebuild )) &&
        sudo test "$UKI" -nt /boot/vmlinuz-linux &&
        sudo test "$UKI" -nt /etc/cmdline.d &&
        [[ -z "$(sudo find /etc/cmdline.d -name '*.conf' -newer "$UKI")" ]]; then
        ok "unified kernel image is up to date"
    else
        sudo mkinitcpio -P
    fi

    if sudo test -d /var/lib/sbctl/keys; then
        ok "Secure Boot keys exist"
    else
        sudo sbctl create-keys
    fi

    # -s records the file so sbctl's pacman hook re-signs it after upgrades.
    for efi in "$UKI" /boot/EFI/systemd/systemd-bootx64.efi /boot/EFI/BOOT/BOOTX64.EFI; do
        sudo test -e "$efi" || continue
        sudo sbctl sign -s "$efi" >/dev/null || warn "could not sign $efi"
    done
    ok "UKI and boot loader signed"

    # --microsoft: without these certs, firmware refuses to init option ROMs
    # (most discrete GPUs, some NICs) once Secure Boot is on.
    # sudo, not a plain read: unprivileged bootctl exits non-zero on the ESP
    # permission-denied reads, and pipefail+set-e would silently kill the
    # script here, skipping everything after (including enabling sddm).
    sb="$(sudo bootctl status 2>/dev/null | sed -n 's/^[[:space:]]*Secure Boot:[[:space:]]*//p')"
    case "$sb" in
        *enabled*)
            ok "Secure Boot is enabled" ;;
        *"(setup)"*)
            if sudo sbctl enroll-keys --microsoft; then
                ok "keys enrolled - turn Secure Boot on in the firmware setup, then reboot"
            else
                warn "enrolling the keys failed - Secure Boot stays off, nothing is broken"
            fi ;;
        *)
            warn "firmware is not in setup mode ($sb) - clear the platform key in the firmware setup, then re-run" ;;
    esac

    if [[ -n "$(sudo find /boot/loader/entries -maxdepth 1 -name '*.conf' -print -quit 2>/dev/null)" ]]; then
        # sudo, same reason as the sb= read above: a plain bootctl exits non-zero
        # on the ESP's permission-denied reads and pipefail+set-e kills the script
        # here, before the Services section below ever runs.
        booted="$(sudo bootctl status 2>/dev/null | sed -n 's/^[[:space:]]*Current Entry:[[:space:]]*//p')"
        if [[ "$booted" == arch-linux.efi ]]; then
            warn "booted from the UKI - retire the old path: sudo rm /boot/loader/entries/*.conf /boot/initramfs-linux*.img"
        else
            warn "still booted from $booted - reboot into arch-linux.efi, then retire the old entry"
        fi
    fi
fi

log "Services"
if [[ "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" == *sddm* ]]; then
    ok "sddm is the display manager"
else
    run sudo systemctl enable sddm.service
    (( DRY )) || ok "sddm enabled - reboot to use it"
fi

if [[ "$(systemctl is-enabled docker.service 2>/dev/null)" == enabled ]]; then
    ok "docker enabled"
else
    run sudo systemctl enable --now docker.service
fi

# Published ports default to 127.0.0.1: Docker DNATs before nftables' input
# chain, so a bare "5432:5432" would otherwise reach the LAN past the firewall.
# Only restarted on change - a restart bounces every running container.
if cmp -s "$INSTALL/etc/docker/daemon.json" /etc/docker/daemon.json; then
    ok "docker publishes on 127.0.0.1"
else
    run sudo install -Dm644 "$INSTALL/etc/docker/daemon.json" /etc/docker/daemon.json
    run sudo systemctl restart docker.service
fi

if id -nG "$USER" | grep -qw docker; then
    ok "$USER is in the docker group"
else
    run sudo usermod -aG docker "$USER"
    (( DRY )) || warn "log out and back in for the docker group to apply"
fi

# A root account with an empty password is a free "su" (Arch's PAM allows
# nullok). A set password is left alone: locking it would also lock the
# emergency shell, and with the command line sealed in the signed UKI the only
# way back in would be a live USB.
if (( DRY )); then
    plan "check that root has a password or is locked"
else
    case "$(sudo passwd -S root | awk '{print $2}')" in
        NP) sudo passwd -l root >/dev/null; warn "root had an empty password - locked it" ;;
        L)  ok "root account is locked" ;;
        *)  ok "root has a password" ;;
    esac
fi

if [[ "$(getent passwd "$USER" | cut -d: -f7)" == */zsh ]]; then
    ok "login shell is zsh"
else
    run chsh -s /usr/bin/zsh
    (( DRY )) || ok "login shell set to zsh - takes effect next login"
fi

log "Done"
