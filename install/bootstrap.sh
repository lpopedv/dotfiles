#!/usr/bin/env bash
# Bring a machine up to this repository's configuration.
# Safe to re-run: every step checks its own state first.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

STOW_PACKAGES=(
    claude doom dunst flameshot ghostty git hypr mise
    nvim rofi systemd tmux waybar wlogout zsh
)

log()  { printf '\n\033[1m==> %s\033[0m\n' "$*"; }
warn() { printf '    \033[33m!\033[0m %s\n' "$*"; }
ok()   { printf '    \033[32mok\033[0m %s\n' "$*"; }

read_list() { grep -vE '^[[:space:]]*(#|$)' "$1"; }

if [[ $EUID -eq 0 ]]; then
    echo "Run as your normal user, not root. sudo is called where needed." >&2
    exit 1
fi

log "Official packages"
read_list "$DOTFILES/install/packages.txt" |
    xargs -r sudo pacman -S --needed --noconfirm

log "AUR helper"
if command -v paru >/dev/null; then
    ok "paru already installed"
else
    build="$(mktemp -d)"
    trap 'rm -rf "$build"' EXIT
    git clone --depth 1 https://aur.archlinux.org/paru.git "$build/paru"
    (cd "$build/paru" && makepkg -si --noconfirm)
fi

log "AUR packages"
read_list "$DOTFILES/install/aur.txt" |
    xargs -r paru -S --needed --noconfirm

log "Dotfiles"
cd "$DOTFILES"
for pkg in "${STOW_PACKAGES[@]}"; do
    if stow --restow "$pkg" 2>/dev/null; then
        ok "$pkg"
    else
        warn "$pkg conflicts with an existing file - resolve, then: stow --restow $pkg"
    fi
done

log "Toolchain"
# mise.lock pins exact versions and checksums; --locked refuses to drift from it
mise install --locked

log "Pacman"
# ParallelDownloads and ILoveCandy live in [options]; pacman.conf has no
# drop-in directory, so these are edited in place. Both edits are no-ops when
# the values are already set.
sudo sed -i -E 's/^#?[[:space:]]*ParallelDownloads[[:space:]]*=.*/ParallelDownloads = 20/' /etc/pacman.conf
sudo sed -i -E 's/^#[[:space:]]*Color[[:space:]]*$/Color/' /etc/pacman.conf
if grep -qE '^ILoveCandy' /etc/pacman.conf; then
    ok "ILoveCandy"
else
    sudo sed -i '/^ParallelDownloads/a ILoveCandy' /etc/pacman.conf
    ok "ILoveCandy added"
fi

log "Time and DNS"
sudo install -Dm644 "$DOTFILES/install/etc/systemd/timesyncd.conf.d/10-cloudflare.conf" \
    /etc/systemd/timesyncd.conf.d/10-cloudflare.conf
sudo install -Dm644 "$DOTFILES/install/etc/systemd/resolved.conf.d/10-cloudflare-dot.conf" \
    /etc/systemd/resolved.conf.d/10-cloudflare-dot.conf

# Domains=~. already makes the Cloudflare servers authoritative, but a DHCP
# lease that registers its own DNS on the link is one less thing to reason
# about if it never happens.
for net in /etc/systemd/network/*.network; do
    [[ -e "$net" ]] || continue
    sudo install -Dm644 "$DOTFILES/install/etc/systemd/network/no-dhcp-dns.conf" \
        "${net}.d/10-no-dhcp-dns.conf"
done

sudo systemctl enable --now systemd-timesyncd.service systemd-resolved.service
sudo systemctl reload-or-restart systemd-resolved.service
systemctl is-active --quiet systemd-networkd && sudo networkctl reload

log "Services"
if [[ "$(readlink -f /etc/systemd/system/display-manager.service 2>/dev/null)" == *sddm* ]]; then
    ok "sddm is the display manager"
else
    sudo systemctl enable sddm.service
    ok "sddm enabled - reboot to use it"
fi

if [[ "$(systemctl is-enabled docker.service 2>/dev/null)" == enabled ]]; then
    ok "docker enabled"
else
    sudo systemctl enable --now docker.service
fi

if id -nG "$USER" | grep -qw docker; then
    ok "$USER is in the docker group"
else
    sudo usermod -aG docker "$USER"
    warn "added $USER to the docker group - log out and back in for it to apply"
fi

if [[ "$(getent passwd "$USER" | cut -d: -f7)" == */zsh ]]; then
    ok "login shell is zsh"
else
    warn "login shell is not zsh - run: chsh -s /usr/bin/zsh"
fi

log "Done"
