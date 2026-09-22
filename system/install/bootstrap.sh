#!/usr/bin/env bash
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INSTALL="$DOTFILES/system/install"

DRY=0
[[ "${1:-}" == "--dry-run" ]] && DRY=1

STOW_PACKAGES=(
    doom flameshot ghostty git gtk herdr hypr lazygit mise nvim
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
for pkg in "${STOW_PACKAGES[@]}"; do
    if (( DRY )); then
        if stow -n --restow "$pkg" >/dev/null 2>&1; then
            ok "$pkg"
        else
            warn "$pkg would conflict - resolve, then: stow --restow $pkg"
        fi
    elif stow --restow "$pkg" 2>/dev/null; then
        ok "$pkg"
    else
        warn "$pkg conflicts with an existing file - resolve, then: stow --restow $pkg"
    fi
done

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
run sudo install -Dm644 "$INSTALL/etc/systemd/timesyncd.conf.d/10-cloudflare.conf" \
    /etc/systemd/timesyncd.conf.d/10-cloudflare.conf
run sudo install -Dm644 "$INSTALL/etc/systemd/resolved.conf.d/10-cloudflare-dot.conf" \
    /etc/systemd/resolved.conf.d/10-cloudflare-dot.conf

# Belt-and-suspenders: Domains=~. already makes Cloudflare authoritative.
for net in /etc/systemd/network/*.network; do
    [[ -e "$net" ]] || continue
    run sudo install -Dm644 "$INSTALL/etc/systemd/network/no-dhcp-dns.conf" \
        "${net}.d/10-no-dhcp-dns.conf"
done

# Same leak, NetworkManager's side (archinstall's nm_iwd manages links here).
run sudo install -Dm644 "$INSTALL/etc/NetworkManager/conf.d/10-no-dns.conf" \
    /etc/NetworkManager/conf.d/10-no-dns.conf

run sudo systemctl enable systemd-timesyncd.service systemd-resolved.service
# restart, not enable --now: --now is a no-op if already running, and the
# drop-ins above would never be read.
run sudo systemctl restart systemd-timesyncd.service
run sudo systemctl reload-or-restart systemd-resolved.service

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
    run sudo systemctl reload-or-restart NetworkManager
fi

log "Maintenance timers"
run sudo install -Dm644 "$INSTALL/etc/systemd/system/paccache.timer.d/override.conf" \
    /etc/systemd/system/paccache.timer.d/override.conf
run sudo systemctl daemon-reload
run sudo systemctl enable --now systemd-tmpfiles-clean.timer paccache.timer
run systemctl --user daemon-reload
run systemctl --user enable --now cliphist-wipe.timer zsh-history-wipe.timer

log "Trace retention"
run sudo install -Dm644 "$INSTALL/etc/tmpfiles.d/tmp.conf" /etc/tmpfiles.d/tmp.conf
run sudo install -Dm644 "$INSTALL/etc/tmpfiles.d/zz-coredump.conf" /etc/tmpfiles.d/zz-coredump.conf
run sudo install -Dm644 "$INSTALL/etc/systemd/journald.conf.d/10-retention.conf" \
    /etc/systemd/journald.conf.d/10-retention.conf
run sudo install -Dm644 "$INSTALL/etc/systemd/coredump.conf.d/10-retention.conf" \
    /etc/systemd/coredump.conf.d/10-retention.conf
run sudo systemctl reload-or-restart systemd-journald
run sudo systemd-tmpfiles --clean /etc/tmpfiles.d/zz-coredump.conf

log "Firewall"
run sudo install -Dm644 "$INSTALL/etc/nftables.conf" /etc/nftables.conf
run sudo systemctl enable --now nftables.service

log "Kernel hardening"
run sudo install -Dm644 "$INSTALL/etc/sysctl.d/99-hardening.conf" /etc/sysctl.d/99-hardening.conf
run sudo rm -f /etc/sysctl.d/10-hardening.conf
run sudo sysctl --system

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
    if [[ -e /etc/cmdline.d/10-root.conf ]]; then
        ok "kernel command line recorded"
    else
        tr ' ' '\n' < /proc/cmdline \
            | grep -vE '^(initrd|BOOT_IMAGE)=' \
            | paste -sd' ' \
            | sudo install -Dm644 /dev/stdin /etc/cmdline.d/10-root.conf
        ok "kernel command line recorded from /proc/cmdline"
    fi

    sudo install -Dm644 "$INSTALL/etc/mkinitcpio.d/linux.preset" /etc/mkinitcpio.d/linux.preset
    sudo install -d -m755 /boot/EFI/Linux

    if sudo test "$UKI" -nt /boot/vmlinuz-linux &&
        sudo test "$UKI" -nt /etc/cmdline.d/10-root.conf; then
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
        booted="$(bootctl status 2>/dev/null | sed -n 's/^[[:space:]]*Current Entry:[[:space:]]*//p')"
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

if id -nG "$USER" | grep -qw docker; then
    ok "$USER is in the docker group"
else
    run sudo usermod -aG docker "$USER"
    (( DRY )) || warn "log out and back in for the docker group to apply"
fi

if [[ "$(getent passwd "$USER" | cut -d: -f7)" == */zsh ]]; then
    ok "login shell is zsh"
else
    run chsh -s /usr/bin/zsh
    (( DRY )) || ok "login shell set to zsh - takes effect next login"
fi

log "Done"
