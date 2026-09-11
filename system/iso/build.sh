#!/usr/bin/env bash
# Work dir defaults to /var/tmp, not /tmp: needs 10+ GB and /tmp is often tmpfs.
set -euo pipefail

DOTFILES="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
SELF="$DOTFILES/system/iso"
RELENG=/usr/share/archiso/configs/releng
WORK="${1:-/var/tmp/archiso-work}"
OUT="$SELF/out"

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
cp -r "$SELF/overlay/airootfs/." "$profile/airootfs/"

cat "$SELF/overlay/packages.extra" >> "$profile/packages.x86_64"

log "Embedding the dotfiles"
branch="$(git -C "$DOTFILES" symbolic-ref --quiet --short HEAD)" ||
    { echo "build.sh needs a branch checked out, not a detached HEAD" >&2; exit 1; }

# git clone, not cp/archive: only committed objects ship, and .git survives
# so dotup works on the installed system without a re-clone.
git clone --quiet --no-hardlinks --branch "$branch" --single-branch \
    "$DOTFILES" "$profile/airootfs/root/Dotfiles"
git -C "$profile/airootfs/root/Dotfiles" remote set-url origin \
    "$(git -C "$DOTFILES" remote get-url origin)"
printf '%s\n' "$(git -C "$DOTFILES" rev-parse --short HEAD)" \
    > "$profile/airootfs/root/Dotfiles/.iso-revision"

# mkarchiso copies with --no-preserve=mode, so every file lands 644 unless
# named in file_permissions. Derive that list from git so a new executable
# added to the repo never needs a matching edit here.
{
    printf '\nfile_permissions+=(\n'
    git -C "$DOTFILES" ls-files -s | sed -n 's/^100755 [0-9a-f]* 0\t//p' |
        while IFS= read -r f; do
            case "$f" in
                system/iso/overlay/airootfs/*)
                    printf '  ["%s"]="0:0:755"\n' "${f#system/iso/overlay/airootfs}" ;;
            esac
            printf '  ["/root/Dotfiles/%s"]="0:0:755"\n' "$f"
        done
    printf ')\n'
} >> "$profile/profiledef.sh"

log "Building"
mkdir -p "$OUT"
# mkarchiso skips finished stages on a rerun, silently reusing stale ones.
rm -rf "${WORK:?}/mkarchiso"
mkarchiso -v -w "$WORK/mkarchiso" -o "$OUT" "$profile"

log "Done"
printf '    %s\n' "$OUT"/*.iso
cat <<'EOF'

    Write it to a USB stick with:

      sudo dd if=<the .iso above> of=/dev/sdX bs=4M status=progress oflag=sync

    Check /dev/sdX with lsblk first. dd overwrites whatever you point it at.
EOF
