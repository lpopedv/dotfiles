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
# A branch for local builds, or the release tag CI checks out (a detached HEAD).
ref="$(git -C "$DOTFILES" symbolic-ref --quiet --short HEAD)" ||
    ref="$(git -C "$DOTFILES" describe --exact-match --tags HEAD 2>/dev/null)" ||
    { echo "build.sh needs a branch or a tag checked out, not a bare detached HEAD" >&2; exit 1; }
# The release tag when building one, otherwise the commit.
version="$(git -C "$DOTFILES" describe --exact-match --tags --match 'v*' HEAD 2>/dev/null)" ||
    version="$(git -C "$DOTFILES" rev-parse --short HEAD)"

# git clone, not cp/archive: only committed objects ship, and .git survives
# so `lethe update` works on the installed system without a re-clone.
# Cloned with tags: an installed machine verifies release tags against them.
git clone --quiet --no-hardlinks --branch "$ref" \
    "$DOTFILES" "$profile/airootfs/root/Dotfiles"
# HTTPS, not the SSH remote of the machine that built this: whoever installs it
# can pull releases without a GitHub key. Pushing is the owner's business.
origin="$(git -C "$DOTFILES" remote get-url origin)"
[[ "$origin" == git@github.com:* ]] && origin="https://github.com/${origin#git@github.com:}"
git -C "$profile/airootfs/root/Dotfiles" remote set-url origin "$origin"
printf '%s\n' "$version" > "$profile/airootfs/root/Dotfiles/.iso-revision"

# Named after the distro and its version, e.g. lethe-1.2.0-x86_64.iso.
# iso_label stays releng's: the boot entries find the medium by it.
sed -i -E \
    -e 's|^iso_name=.*|iso_name="lethe"|' \
    -e "s|^iso_version=.*|iso_version=\"${version#v}\"|" \
    -e 's|^iso_application=.*|iso_application="Lethe - Arch Linux + Hyprland installer"|' \
    "$profile/profiledef.sh"

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

# Checksum the image: it catches a corrupt download or USB write. Releases
# also carry a build-provenance attestation from CI (.github/workflows/release.yml)
# that proves which commit and workflow produced the image.
iso="$(ls -t "$OUT"/*.iso | head -n1)"
(cd "$OUT" && sha256sum "${iso##*/}" > "${iso##*/}.sha256")

log "Done"
printf '    %s\n    %s\n' "$iso" "$iso.sha256"
cat <<EOF

    Write it to a USB stick with:

      sudo dd if=$iso of=/dev/sdX bs=4M status=progress oflag=sync

    Check /dev/sdX with lsblk first. dd overwrites whatever you point it at.
    Then confirm the stick holds exactly this image (must match the .sha256):

      sudo head -c \$(stat -c %s $iso) /dev/sdX | sha256sum
      cat $iso.sha256
EOF
