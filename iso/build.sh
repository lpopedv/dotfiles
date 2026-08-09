#!/usr/bin/env bash
# Build a live ISO that carries this repository and starts the installer for you.
#
#   sudo ./iso/build.sh            build into iso/out/
#   sudo ./iso/build.sh /mnt/big   build with the work directory elsewhere
#
# The work directory defaults to /var/tmp, not /tmp: a build needs well over
# 10 GB, and /tmp is a tmpfs on most Arch systems, which means RAM.
#
# The releng profile is copied from the installed archiso package at build
# time rather than vendored here, so archiso updates arrive on their own and
# this repo only carries the difference.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
RELENG=/usr/share/archiso/configs/releng
WORK="${1:-/var/tmp/archiso-work}"
OUT="$DOTFILES/iso/out"

log() { printf '\n\033[1m==> %s\033[0m\n' "$*"; }

if [[ $EUID -ne 0 ]]; then
    echo "mkarchiso needs root: sudo $0" >&2
    exit 1
fi

if [[ ! -d "$RELENG" ]]; then
    echo "archiso is not installed: pacman -S archiso" >&2
    exit 1
fi

profile="$WORK/profile"

log "Assembling the profile"
rm -rf "$profile"
mkdir -p "$profile"
cp -r "$RELENG/." "$profile/"
cp -r "$DOTFILES/iso/overlay/airootfs/." "$profile/airootfs/"

# Extra tools for the live environment. The target system's packages come from
# install/packages.txt long after this, so they do not belong here.
cat "$DOTFILES/iso/overlay/packages.extra" >> "$profile/packages.x86_64"

log "Embedding the dotfiles"
# git archive rather than cp: only committed content ships, so the ISO can
# never carry a stray local edit or an untracked file.
mkdir -p "$profile/airootfs/root/Dotfiles"
git -C "$DOTFILES" archive HEAD | tar -x -C "$profile/airootfs/root/Dotfiles"
printf '%s\n' "$(git -C "$DOTFILES" rev-parse --short HEAD)" \
    > "$profile/airootfs/root/Dotfiles/.iso-revision"

chmod +x "$profile/airootfs/root/install.sh"

log "Building"
mkdir -p "$OUT"
mkarchiso -v -w "$WORK/mkarchiso" -o "$OUT" "$profile"

log "Done"
printf '    %s\n' "$OUT"/*.iso
cat <<'EOF'

    Write it to a USB stick with:

      sudo dd if=<the .iso above> of=/dev/sdX bs=4M status=progress oflag=sync

    Check /dev/sdX with lsblk first. dd overwrites whatever you point it at.
EOF
