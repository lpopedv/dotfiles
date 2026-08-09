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

  When it finishes, choose Exit - NOT Reboot. Reboot restarts the machine
  from inside archinstall, before this script can put the dotfiles and the
  wifi credentials on the new system. Reboot yourself once it returns here.

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

# archinstall mounts the new system here. Not /mnt/archinstall: that was the
# 2.x path, and pointing at it made every step below a silent no-op.
target=/mnt

# Both steps are best effort - the install itself already succeeded, and
# archinstall may have unmounted the target on the way out. But they are the
# difference between a usable first boot and one with no repo and no wifi, so
# say out loud when they do not happen.
skipped=()

if ! mountpoint -q "$target"; then
    printf '\n  %s is not mounted - skipping the post-install steps.\n' "$target"
    skipped+=("the repo copy" "the wifi credentials")
else
    # Leave the repo on the installed system so the next step needs neither the
    # network nor a clone.
    home="$(find "$target/home" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)"
    if [[ -n "$home" ]] && cp -r /root/Dotfiles "$home/Dotfiles" 2>/dev/null; then
        chown -R "$(stat -c %u "$home"):$(stat -c %g "$home")" "$home/Dotfiles"
        printf '\n  Dotfiles copied to %s\n' "${home#$target}/Dotfiles"
    else
        skipped+=("the repo copy")
    fi

    # Carry the wifi across. Whatever iwctl connected to on the live ISO is a
    # profile under /var/lib/iwd; archinstall.json asks for the nm_iwd backend,
    # so NetworkManager reads the same directory on the installed system and
    # reconnects on its own at first boot.
    if compgen -G '/var/lib/iwd/*.psk' >/dev/null; then
        if install -d -m 700 "$target/var/lib/iwd" &&
            install -m 600 /var/lib/iwd/*.psk "$target/var/lib/iwd/"; then
            printf '  Wifi credentials copied - it should reconnect at first boot.\n'
        else
            skipped+=("the wifi credentials")
        fi
    fi
fi

cat <<'EOF'

  Installed. Reboot, log in, then:

      ~/Dotfiles/install/bootstrap.sh

EOF

for item in "${skipped[@]}"; do
    case "$item" in
        "the repo copy")
            printf '  Heads up: %s failed. Clone the repo before bootstrapping.\n' "$item" ;;
        "the wifi credentials")
            printf '  Heads up: %s were not copied. Connect with: nmcli device wifi connect SSID --ask\n' "$item" ;;
    esac
done
(( ${#skipped[@]} )) && printf '\n'
exit 0
