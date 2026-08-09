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

# pacstrap needs a working network. Test reachability directly rather than
# waiting on network-online.target: nothing pulls that target in on the live
# ISO when the connection was made by hand with iwctl, so waiting on it hangs
# forever on exactly the machines that need wifi.
printf '\n  checking the network...\n'
if ! curl -sf --max-time 8 -o /dev/null https://archlinux.org; then
    cat <<'EOF'

  No network. For wifi:

      iwctl
      device wlan0 set-property Powered on     (if it is off)
      station wlan0 scan
      station wlan0 get-networks
      station wlan0 connect YOUR_NETWORK
      exit

  If the device is missing entirely, try: rfkill unblock wifi
  Then run ~/install.sh again.

EOF
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
