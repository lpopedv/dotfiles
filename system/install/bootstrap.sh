#!/usr/bin/env bash
# Bring a machine up to this repository's configuration.
# Safe to re-run: every step checks its own state first.
#
#   bootstrap.sh              apply
#   bootstrap.sh --dry-run    print what would change, touch nothing
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
INSTALL="$DOTFILES/system/install"

DRY=0
[[ "${1:-}" == "--dry-run" ]] && DRY=1

STOW_PACKAGES=(
    doom flameshot ghostty git gtk hypr lazygit mise nvim
    orca qt6ct quickshell rofi systemd tmux zsh
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
# gtk-4.0/libadwaita apps (Nautilus, Sushi, ...) only ever read color-scheme via
# gsettings/the Settings portal, never gtk-theme-name or prefer-dark-theme - the
# portal side of this lives in hypr/.config/xdg-desktop-portal/hyprland-portals.conf
# (routes org.freedesktop.impl.portal.Settings to xdg-desktop-portal-gtk, which is
# what actually reads these keys). GTK3 apps that skip the portal fall back to
# gtk/.config/gtk-3.0/settings.ini, stowed above.
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

log "Toolchain"
# mise.lock pins exact versions and checksums; --locked refuses to drift from it
run mise install --locked

log "Pacman"
# ParallelDownloads and ILoveCandy live in [options]; pacman.conf has no
# drop-in directory, so these are edited in place. Both are no-ops when set.
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

# Domains=~. already makes the Cloudflare servers authoritative, but a DHCP
# lease that registers its own DNS on the link is one less thing to reason about
# if it never happens.
for net in /etc/systemd/network/*.network; do
    [[ -e "$net" ]] || continue
    run sudo install -Dm644 "$INSTALL/etc/systemd/network/no-dhcp-dns.conf" \
        "${net}.d/10-no-dhcp-dns.conf"
done

# Same leak, NetworkManager's side - archinstall's nm_iwd network_config means
# NetworkManager, not systemd-networkd, manages the actual links on most
# machines this repo targets, so the drop-in above alone leaves DHCP-advertised
# DNS servers registered with resolved per-link.
run sudo install -Dm644 "$INSTALL/etc/NetworkManager/conf.d/10-no-dns.conf" \
    /etc/NetworkManager/conf.d/10-no-dns.conf

run sudo systemctl enable systemd-timesyncd.service systemd-resolved.service
# restart, not enable --now: on a machine where these already run, --now is a
# no-op and the drop-ins above would never be read
run sudo systemctl restart systemd-timesyncd.service
run sudo systemctl reload-or-restart systemd-resolved.service
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
run sudo install -Dm644 "$INSTALL/etc/tmpfiles.d/coredump.conf" /etc/tmpfiles.d/coredump.conf
run sudo install -Dm644 "$INSTALL/etc/systemd/journald.conf.d/10-retention.conf" \
    /etc/systemd/journald.conf.d/10-retention.conf
run sudo install -Dm644 "$INSTALL/etc/systemd/coredump.conf.d/10-retention.conf" \
    /etc/systemd/coredump.conf.d/10-retention.conf
run sudo systemctl reload-or-restart systemd-journald
run sudo systemd-tmpfiles --clean /etc/tmpfiles.d/coredump.conf

log "Firewall"
run sudo install -Dm644 "$INSTALL/etc/nftables.conf" /etc/nftables.conf
run sudo systemctl enable --now nftables.service

log "Kernel hardening"
run sudo install -Dm644 "$INSTALL/etc/sysctl.d/99-hardening.conf" /etc/sysctl.d/99-hardening.conf
run sudo rm -f /etc/sysctl.d/10-hardening.conf
run sudo sysctl --system

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
