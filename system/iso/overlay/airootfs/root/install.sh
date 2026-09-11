#!/usr/bin/env bash
set -uo pipefail

CONFIG=/root/Dotfiles/system/install/archinstall.json

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

# Test reachability directly: waiting on network-online.target hangs forever
# when the connection was made by hand with iwctl, which nothing pulls it in for.
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

# Not /mnt/archinstall: that was the 2.x path, now a silent no-op.
target=/mnt

skipped=()

if ! mountpoint -q "$target"; then
    printf '\n  %s is not mounted - skipping the post-install steps.\n' "$target"
    skipped+=("the repo copy" "the wifi credentials")
else
    home="$(find "$target/home" -mindepth 1 -maxdepth 1 -type d 2>/dev/null | head -1)"
    if [[ -n "$home" ]] && cp -r /root/Dotfiles "$home/Dotfiles" 2>/dev/null; then
        chown -R "$(stat -c %u "$home"):$(stat -c %g "$home")" "$home/Dotfiles"
        printf '\n  Dotfiles copied to %s\n' "${home#$target}/Dotfiles"

        # One-shot hook: flag-guarded so it fires once and retries on failure.
        if ! grep -q '.dotfiles-bootstrapped' "$home/.bash_profile" 2>/dev/null; then
            cat >> "$home/.bash_profile" <<'HOOK'

if [[ -t 0 && ! -e ~/.dotfiles-bootstrapped ]]; then
    ~/Dotfiles/system/install/bootstrap.sh && touch ~/.dotfiles-bootstrapped
fi
HOOK
            chown "$(stat -c %u "$home"):$(stat -c %g "$home")" "$home/.bash_profile"
        fi
    else
        skipped+=("the repo copy")
    fi

    # NetworkManager (nm_iwd backend) reads the same /var/lib/iwd profiles.
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

  Installed. Reboot, then log in - bootstrap.sh runs on its own the first
  time you do, no command to type.

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
