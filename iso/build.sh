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

# mkarchiso copies the profile with `cp -af --no-preserve=ownership,mode`, so
# every file lands 644 no matter what mode it had here. Only paths named in
# file_permissions get a mode back. Naming install.sh by hand was enough to
# boot the installer, but it left every script inside the embedded repo
# unexecutable - bootstrap.sh included, which is the one command the installer
# tells you to run next.
#
# Derive the list from git instead: whatever the index calls 755 ships 755,
# and adding an executable to the repo never needs a matching edit here.
{
    printf '\nfile_permissions+=(\n'
    git -C "$DOTFILES" ls-files -s | sed -n 's/^100755 [0-9a-f]* 0\t//p' |
        while IFS= read -r f; do
            # The overlay is both a path in the repo and a path in the image.
            case "$f" in
                iso/overlay/airootfs/*)
                    printf '  ["%s"]="0:0:755"\n' "${f#iso/overlay/airootfs}" ;;
            esac
            printf '  ["/root/Dotfiles/%s"]="0:0:755"\n' "$f"
        done
    printf ')\n'
} >> "$profile/profiledef.sh"

log "Building"
mkdir -p "$OUT"
# mkarchiso records finished stages in its work directory and skips them on a
# rerun, so reusing one silently republishes the previous image no matter what
# changed in the profile. Always start from nothing.
rm -rf "${WORK:?}/mkarchiso"
mkarchiso -v -w "$WORK/mkarchiso" -o "$OUT" "$profile"

log "Done"
printf '    %s\n' "$OUT"/*.iso
cat <<'EOF'

    Write it to a USB stick with:

      sudo dd if=<the .iso above> of=/dev/sdX bs=4M status=progress oflag=sync

    Check /dev/sdX with lsblk first. dd overwrites whatever you point it at.
EOF
