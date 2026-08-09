#!/usr/bin/env bash
# Runs on tty1 when the live ISO boots. Starts archinstall with this repo's
# configuration prefilled, then hands over to the TUI so a human answers the
# questions that should not be answered by a file: the disk, the user and the
# passwords.
set -uo pipefail

CONFIG=/root/Dotfiles/install/archinstall.json

printf '\n\033[1m  Arch installer\033[0m\n'
printf '  dotfiles %s\n\n' "$(cat /root/Dotfiles/.iso-revision 2>/dev/null || echo unknown)"
cat <<'EOF'
  Everything except disks and credentials is already answered.
  You will be asked for:

    - Disks        pick the device, choose btrfs
    - Users        your account and its password
    - Root         the root password

  Then choose Install.

EOF

read -rp '  Press enter to start, or Ctrl-C for a shell: ' _

# pacstrap needs a working network; the ISO may still be bringing it up.
printf '\n  waiting for the network...\n'
systemctl is-system-running --wait >/dev/null 2>&1
if ! systemd-run --pty --quiet -p Wants=network-online.target \
    -p After=network-online.target true >/dev/null 2>&1; then
    printf '  network is not up. Connect it, then run: %s\n' "$0"
    exit 1
fi

archinstall --config "$CONFIG"
rt=$?

if (( rt != 0 )); then
    printf '\n  archinstall exited with %d. The shell is yours.\n' "$rt"
    exit "$rt"
fi

# Best effort: leave the repo on the installed system so the next step does not
# need the network or a clone. Never fail the run over it - the same repo is a
# git clone away, and archinstall may already have unmounted the target.
target=/mnt/archinstall
home="$(find "$target/home" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)"
if [[ -n "$home" ]]; then
    if cp -r /root/Dotfiles "$home/Dotfiles" 2>/dev/null; then
        chown -R "$(stat -c %u "$home"):$(stat -c %g "$home")" "$home/Dotfiles"
        printf '\n  Dotfiles copied to %s\n' "${home#$target}/Dotfiles"
    fi
fi

cat <<'EOF'

  Installed. Reboot, log in, then:

      ~/Dotfiles/install/bootstrap.sh

  If Dotfiles is not in your home directory, clone it first.

EOF
