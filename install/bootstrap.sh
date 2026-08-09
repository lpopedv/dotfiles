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
