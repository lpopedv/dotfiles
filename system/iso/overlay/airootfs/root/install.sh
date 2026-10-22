#!/usr/bin/env bash
# The live ISO's installer: a few questions on tty1, then archinstall does the
# work unattended from a config built out of the answers. Nothing here needs
# Arch knowledge - that is the point of it.
#
#   install.sh                  the wizard (started by .zlogin on tty1)
#   install.sh --answers FILE   unattended: KEY=value answers, no questions
#   install.sh --dry-run        print the generated config, touch nothing
#                               (runs on any machine with gum and jq)
set -uo pipefail

DRY=0
ANSWERS=""
while (( $# )); do
    case "$1" in
        --dry-run) DRY=1; shift ;;
        --answers) ANSWERS="${2:?--answers needs a file}"; shift 2 ;;
        *) echo "usage: $0 [--dry-run] [--answers FILE]" >&2; exit 2 ;;
    esac
done

# On the ISO the repo sits next to this script's installed copy; in a checkout
# (dry runs) it is five levels up from system/iso/overlay/airootfs/root.
DOTFILES=/root/Dotfiles
[[ -d "$DOTFILES" ]] ||
    DOTFILES="$(cd "$(dirname "$(readlink -f "${BASH_SOURCE[0]}")")/../../../../.." && pwd)"
BASE_CONFIG="$DOTFILES/system/install/archinstall.json"
VERSION="$(cat "$DOTFILES/.iso-revision" 2>/dev/null || git -C "$DOTFILES" describe --tags --always 2>/dev/null || echo unknown)"
TARGET=/mnt
WORK=/tmp/dotfiles-install
LOG="$WORK/install.log"

for cmd in gum jq; do
    command -v "$cmd" >/dev/null || { echo "$cmd is required" >&2; exit 1; }
done

# The generated configs - credentials included - sit in a root-only directory,
# and /tmp on the live system is RAM. A directory mode, not `umask 077`: the
# umask would be inherited by archinstall and make the whole new system
# root-only, so its D-Bus (not root) can't start.
umask 022
mkdir -p "$WORK"
chmod 700 "$WORK"

export GUM_CHOOSE_CURSOR_FOREGROUND=6 GUM_CHOOSE_SELECTED_FOREGROUND=6
export GUM_CHOOSE_HEADER_FOREGROUND=7 GUM_INPUT_HEADER_FOREGROUND=7
export GUM_FILTER_HEADER_FOREGROUND=7 GUM_FILTER_INDICATOR_FOREGROUND=6
export GUM_FILTER_MATCH_FOREGROUND=6 GUM_INPUT_CURSOR_FOREGROUND=6
export GUM_CONFIRM_PROMPT_FOREGROUND=7 GUM_CONFIRM_SELECTED_BACKGROUND=6
export GUM_CONFIRM_SELECTED_FOREGROUND=0

# label | console keymap | XKB layout | XKB variant. The console and Hyprland
# name layouts differently (br-abnt2 vs br), so both are carried.
KEYBOARDS='Portuguese (Brazil)|br-abnt2|br|
English (US)|us|us|
English (US, international)|us-acentos|us|intl
English (UK)|uk|gb|
Portuguese (Portugal)|pt-latin1|pt|
Spanish|es|es|
Spanish (Latin America)|la-latin1|latam|
French|fr|fr|
German|de-latin1|de|
Italian|it|it|'

# From Omarchy's installer (MIT): what useradd accepts, minus the accounts the
# base system and its services already own.
USERNAME_PATTERN='^[a-z_][a-z0-9_-]*[$]?$'
RESERVED_USERNAMES='^(root|bin|daemon|mail|ftp|http|nobody|dbus|systemd-coredump|systemd-network|systemd-oom|systemd-journal-remote|systemd-resolve|systemd-timesync|tss|uuidd|alpm|git|avahi|cups|cups-browsed|lp|_talkd|polkitd|rtkit|qemu|brltty|gluster|rpc|libvirt-qemu|pcscd|nvidia-persistenced|sddm|docker)$'
HOSTNAME_PATTERN='^[A-Za-z0-9]([A-Za-z0-9-]{0,61}[A-Za-z0-9])?$'
MIN_DISK_GIB=20

# Answers, preset by --answers or filled in by the wizard.
keyboard_label="Portuguese (Brazil)"
username="" password="" full_name="" email=""
hostname="$(jq -r '.hostname // "archlinux"' "$BASE_CONFIG")"
timezone="$(jq -r '.timezone // "UTC"' "$BASE_CONFIG")"
disk="" encrypt=yes wifi_ssid="" wifi_passphrase=""
unattended=0

# ---------------------------------------------------------------- ui helpers

say()   { gum style --padding "0 2" "$@"; }
dim()   { gum style --padding "0 2" --foreground 8 "$@"; }
fail()  { gum style --padding "0 2" --foreground 1 "$@"; }

screen() {
    clear
    gum style --border rounded --border-foreground 6 --padding "1 4" --margin "1 2" \
        "$(gum style --bold --foreground 6 'dotfiles') $(gum style --foreground 8 "$VERSION")" \
        "Arch Linux + Hyprland"
    [[ -n "${1:-}" ]] && gum style --padding "0 2" --bold "$1" && echo
}

# Ctrl+C or Esc in any prompt lands here: leave for a shell, or carry on.
maybe_quit() {
    if gum confirm --default=false --affirmative "Quit to a shell" --negative "Keep going" \
        "Leave the installer?"; then
        echo
        say "Run ~/install.sh to start again."
        exit 1
    fi
}

# ask VAR gum-subcommand args... - stores gum's output in VAR. Returns non-zero
# after a cancelled prompt so the caller re-asks.
ask() {
    local __var="$1" __out
    shift
    if __out="$(gum "$@")"; then
        printf -v "$__var" '%s' "$__out"
        return 0
    fi
    maybe_quit
    return 1
}

# ---------------------------------------------------------------- answers file

load_answers() {
    [[ -r "$ANSWERS" ]] || { echo "can't read $ANSWERS" >&2; exit 1; }
    # Parsed, never sourced: values are data, not shell.
    local key value
    while IFS='=' read -r key value; do
        [[ -z "$key" || "$key" == \#* ]] && continue
        case "$key" in
            KEYBOARD)        keyboard_label="$value" ;;
            USERNAME)        username="$value" ;;
            PASSWORD)        password="$value" ;;
            FULL_NAME)       full_name="$value" ;;
            EMAIL)           email="$value" ;;
            HOSTNAME)        hostname="$value" ;;
            TIMEZONE)        timezone="$value" ;;
            DISK)            disk="$value" ;;
            ENCRYPT)         encrypt="$value" ;;
            WIFI_SSID)       wifi_ssid="$value" ;;
            WIFI_PASSPHRASE) wifi_passphrase="$value" ;;
            *) echo "unknown answer: $key" >&2; exit 1 ;;
        esac
    done < "$ANSWERS"
    for key in username password disk; do
        [[ -n "${!key}" ]] || { echo "answers file needs ${key^^}" >&2; exit 1; }
    done
    [[ -n "$(keyboard_field 2)" ]] || { echo "unknown KEYBOARD: $keyboard_label" >&2; exit 1; }
    [[ "$encrypt" == yes || "$encrypt" == no ]] || { echo "ENCRYPT must be yes or no" >&2; exit 1; }
    unattended=1
}

# ---------------------------------------------------------------- network

online() { curl -sf --max-time 8 -o /dev/null https://archlinux.org; }

wifi_device() {
    local dev
    for dev in /sys/class/net/*; do
        [[ -d "$dev/wireless" ]] && { basename "$dev"; return 0; }
    done
    return 1
}

# iwctl prints a table with ANSI colors; keep only the network names. Names may
# contain spaces, so the trailing security and signal columns are cut instead.
wifi_networks() {
    iwctl station "$1" get-networks 2>/dev/null |
        sed -E 's/\x1b\[[0-9;]*m//g' | tail -n +5 |
        sed -E 's/^[[:space:]>]*//; s/[[:space:]]+(psk|open|8021x|wep)[[:space:]]+[*]*[[:space:]]*$//' |
        grep -v '^[[:space:]-]*$'
}

wifi_connect() {
    local dev="$1" ssid="$2" pass="$3"
    # The passphrase shows in argv for a moment; on a single-user live system
    # with nothing else running that is accepted to keep iwctl non-interactive.
    if [[ -n "$pass" ]]; then
        iwctl --passphrase "$pass" station "$dev" connect "$ssid" >/dev/null 2>&1
    else
        iwctl station "$dev" connect "$ssid" >/dev/null 2>&1
    fi
}

step_network() {
    screen "Network"
    if gum spin --spinner dot --title "  Checking the connection..." -- bash -c "$(declare -f online); online"; then
        return 0
    fi
    (( DRY )) && { dim "Offline - a dry run carries on anyway."; sleep 1; return 0; }

    local dev
    rfkill unblock wifi 2>/dev/null
    if ! dev="$(wifi_device)"; then
        fail "No internet connection and no Wi-Fi card found."
        say "Plug in a network cable, then press Enter to check again."
        read -r _
        return 1
    fi

    if (( unattended )) && [[ -n "$wifi_ssid" ]]; then
        wifi_connect "$dev" "$wifi_ssid" "$wifi_passphrase"
        sleep 3
        online && return 0
        echo "could not connect to $wifi_ssid" >&2
        exit 1
    fi

    iwctl device "$dev" set-property Powered on >/dev/null 2>&1
    gum spin --spinner dot --title "  Looking for Wi-Fi networks..." -- \
        bash -c "iwctl station '$dev' scan >/dev/null 2>&1; sleep 4"

    local networks ssid pass=""
    networks="$(wifi_networks "$dev")"
    if [[ -z "$networks" ]]; then
        fail "No Wi-Fi networks in range."
        say "Press Enter to scan again."
        read -r _
        return 1
    fi
    ask ssid choose --header "Pick your Wi-Fi network" <<< "$networks" || return 1
    ask pass input --password --header "Password for $ssid (leave empty if open)" || return 1

    gum spin --spinner dot --title "  Connecting to $ssid..." -- \
        bash -c "$(declare -f wifi_connect); wifi_connect '$dev' \"\$1\" \"\$2\"; sleep 3" _ "$ssid" "$pass"
    if online; then
        return 0
    fi
    fail "Couldn't get online through $ssid - check the password and try again."
    sleep 2
    return 1
}

# ---------------------------------------------------------------- questions

keyboard_field() {   # keyboard_field N -> field N of the chosen layout's row
    awk -F'|' -v l="$keyboard_label" -v n="$1" '$1 == l { print $n }' <<< "$KEYBOARDS"
}

step_keyboard() {
    screen "Keyboard"
    ask keyboard_label choose --header "Which keyboard layout do you use?" \
        --selected "$keyboard_label" < <(cut -d'|' -f1 <<< "$KEYBOARDS") || return 1
    # loadkeys only works on a real console, not in a terminal emulator.
    if (( ! DRY )) && [[ "$(tty)" == /dev/tty[0-9]* ]]; then
        loadkeys "$(keyboard_field 2)" 2>/dev/null
    fi
}

step_account() {
    local again
    screen "Your account"
    while :; do
        ask username input --header "Username (lowercase, for logging in)" \
            --placeholder "e.g. alice" --value "$username" || continue
        if [[ ! "$username" =~ $USERNAME_PATTERN ]]; then
            fail "Use lowercase letters, digits, - and _, starting with a letter."
        elif [[ "$username" =~ $RESERVED_USERNAMES ]]; then
            fail "\"$username\" belongs to the system - pick another."
        else
            break
        fi
    done
    while :; do
        ask password input --password --header "Password (also unlocks the disk if encrypted)" || continue
        ask again input --password --header "Same password again" || continue
        if [[ "$password" != "$again" ]]; then
            fail "The passwords don't match - once more."
        elif (( ${#password} < 8 )); then
            # Also the disk passphrase when encrypting, chosen only later.
            fail "Use at least 8 characters."
        else
            break
        fi
    done
    ask full_name input --header "Your name, for git commits (optional)" --value "$full_name" || :
    ask email input --header "Your email, for git commits (optional)" --value "$email" || :
}

step_machine() {
    screen "This computer"
    while :; do
        ask hostname input --header "Computer name, as seen on the network" --value "$hostname" || continue
        [[ "$hostname" =~ $HOSTNAME_PATTERN ]] && break
        fail "Letters, digits and - only, up to 63 characters."
    done
    ask timezone filter --header "Time zone (type to search)" --value "$timezone" \
        --select-if-one < <(timedatectl list-timezones) || return 1
}

# The disk the live system booted from must never be offered.
boot_disk() {
    local src
    src="$(findmnt -no SOURCE /run/archiso/bootmnt 2>/dev/null)" || return 0
    lsblk -npo PKNAME "$src" 2>/dev/null | head -n1
}

disk_choices() {
    local skip name size model parts
    skip="$(boot_disk)"
    while read -r name; do
        [[ "$name" == "$skip" || "$name" == /dev/zram* ]] && continue
        size="$(lsblk -dno SIZE "$name" | tr -d ' ')"
        model="$(lsblk -dno MODEL "$name" | sed 's/[[:space:]]*$//')"
        parts="$(lsblk -nro TYPE,FSTYPE "$name" | awk '$1 == "part" { printf "%s%s", s, ($2 == "" ? "unknown" : $2); s = ", " }')"
        printf '%s  %s  %s%s\n' "$name" "$size" "${model:-disk}" "${parts:+  [$parts]}"
    done < <(lsblk -dnpo NAME,TYPE,RO | awk '$2 == "disk" && $3 == 0 { print $1 }')
}

step_disk() {
    screen "Where to install"
    local choices choice gib
    choices="$(disk_choices)"
    if [[ -z "$choices" ]]; then
        fail "No disk to install on was found."
        say "Press Enter to look again."
        read -r _
        return 1
    fi
    ask choice choose --header "Pick the disk. EVERYTHING on it will be erased." <<< "$choices" || return 1
    disk="${choice%% *}"
    gib=$(( $(lsblk -bdno SIZE "$disk") / 1024**3 ))
    if (( gib < MIN_DISK_GIB )); then
        fail "$disk is ${gib} GiB - at least ${MIN_DISK_GIB} GiB is needed."
        sleep 2
        return 1
    fi

    local enc
    ask enc choose --header "Encrypt the disk?" \
        "Yes, encrypt it (recommended)" "No, leave it unencrypted" || return 1
    if [[ "$enc" == Yes* ]]; then encrypt=yes; else encrypt=no; fi
}

disk_label() {
    printf '%s (%s %s)' "$1" "$(lsblk -dno SIZE "$1" | tr -d ' ')" \
        "$(lsblk -dno MODEL "$1" | sed 's/[[:space:]]*$//')"
}

step_confirm() {
    screen "Ready to install"
    {
        printf 'Keyboard     %s\n' "$keyboard_label"
        printf 'Username     %s\n' "$username"
        printf 'Name         %s\n' "${full_name:-(skipped)}"
        printf 'Email        %s\n' "${email:-(skipped)}"
        printf 'Computer     %s\n' "$hostname"
        printf 'Time zone    %s\n' "$timezone"
        printf 'Disk         %s\n' "$(disk_label "$disk")"
        printf 'Encryption   %s\n' "$([[ $encrypt == yes ]] && echo 'LUKS2, unlocked with your password' || echo off)"
    } | gum style --padding "0 4"
    echo
    gum style --padding "0 2" --foreground 1 --bold "Everything on $(disk_label "$disk") will be erased."
    echo
    gum confirm --default=false --affirmative "Erase and install" --negative "Change something" \
        "Install now?"
}

# ---------------------------------------------------------------- config

# yescrypt via libcrypt - the hash Arch's own passwd writes. openssl's SHA-512
# crypt is the fallback should libcrypt's gensalt be unavailable.
hash_password() {
    # printf, not <<<: a here-string appends a newline that would become part
    # of the password.
    printf '%s' "$1" | python3 -I -c '
import ctypes, sys
lib = ctypes.CDLL("libcrypt.so.2")
lib.crypt_gensalt.restype = lib.crypt.restype = ctypes.c_char_p
salt = lib.crypt_gensalt(b"$y$", 0, None, 0)
out = lib.crypt(sys.stdin.buffer.read(), salt) if salt else None
if not out or out.startswith(b"*"):
    sys.exit(1)
print(out.decode())
' 2>/dev/null || printf '%s\n' "$1" | openssl passwd -6 -stdin
}

uuid() { cat /proc/sys/kernel/random/uuid; }

# One ESP and one btrfs partition with archinstall's own subvolume layout,
# sizes in MiB so every boundary is 1 MiB-aligned; archinstall keeps the last
# MiB free for the backup GPT header.
write_config() {
    local bytes sector total_mib root_mib esp_id root_id
    if (( DRY )) && [[ ! -b "$disk" ]]; then bytes=$(( 64 * 1024**3 )); sector=512
    else bytes="$(lsblk -bdno SIZE "$disk")"; sector="$(lsblk -dno LOG-SEC "$disk" | tr -d ' ')"
    fi
    total_mib=$(( bytes / 1024**2 ))
    root_mib=$(( total_mib - 1 - 1025 ))
    esp_id="$(uuid)" root_id="$(uuid)"

    jq --arg disk "$disk" --argjson sector "$sector" --argjson root_mib "$root_mib" \
        --arg esp_id "$esp_id" --arg root_id "$root_id" --arg encrypt "$encrypt" \
        --arg hostname "$hostname" --arg timezone "$timezone" --arg keymap "$(keyboard_field 2)" '
        def size($unit; $value): { sector_size: { unit: "B", value: $sector }, unit: $unit, value: $value };
        def part($id; $start; $len; $fs; $mnt; $flags; $opts; $subvols): {
            obj_id: $id, status: "create", type: "primary", dev_path: null,
            start: size("MiB"; $start), size: size("MiB"; $len),
            fs_type: $fs, mountpoint: $mnt, flags: $flags, mount_options: $opts, btrfs: $subvols
        };
        . + {
            hostname: $hostname,
            timezone: $timezone,
            locale_config: (.locale_config + { kb_layout: $keymap }),
            disk_config: ({
                config_type: "default_layout",
                device_modifications: [{
                    device: $disk,
                    wipe: true,
                    partitions: [
                        part($esp_id; 1; 1024; "fat32"; "/boot"; ["boot", "esp"]; []; []),
                        part($root_id; 1025; $root_mib; "btrfs"; null; []; ["compress=zstd"]; [
                            { name: "@",     mountpoint: "/" },
                            { name: "@home", mountpoint: "/home" },
                            { name: "@log",  mountpoint: "/var/log" },
                            { name: "@pkg",  mountpoint: "/var/cache/pacman/pkg" }
                        ])
                    ]
                }]
            } + (if $encrypt == "yes"
                 then { disk_encryption: { encryption_type: "luks", partitions: [$root_id] } }
                 else {} end))
        }' "$BASE_CONFIG" > "$WORK/user_configuration.json"

    # No root password: the account gets sudo, and bootstrap.sh keeps root
    # locked. The disk passphrase has to be plaintext - archinstall feeds it to
    # cryptsetup - which is why this file never leaves RAM.
    jq -n --arg user "$username" --arg hash "$(hash_password "$password")" \
        --arg luks "$([[ $encrypt == yes ]] && printf '%s' "$password")" '
        { users: [{ username: $user, enc_password: $hash, sudo: true, groups: [] }] }
        + (if $luks != "" then { encryption_password: $luks } else {} end)
        ' > "$WORK/user_credentials.json"
}

# ---------------------------------------------------------------- install

run_archinstall() {
    archinstall --config "$WORK/user_configuration.json" \
        --creds "$WORK/user_credentials.json" --silent "$@"
}

# Run as root on the live system; ownership comes from the new home itself.
post_install() {
    local home="$TARGET/home/$username" owner skipped=()
    owner="$(stat -c %u:%g "$home" 2>/dev/null)" || {
        fail "$home is missing - the dotfiles were not copied. Clone them after logging in."
        return
    }

    cp -a "$DOTFILES" "$home/Dotfiles" && chown -R "$owner" "$home/Dotfiles" ||
        skipped+=("the dotfiles")

    # Per-machine files, outside the repo so updates never touch them.
    install -d -o "${owner%:*}" -g "${owner#*:}" -m 755 \
        "$home/.config" "$home/.config/git" "$home/.config/hypr"
    if [[ -n "$full_name$email" ]]; then
        [[ -n "$full_name" ]] && git config -f "$home/.config/git/identity" user.name "$full_name"
        [[ -n "$email" ]] && git config -f "$home/.config/git/identity" user.email "$email"
        chown "$owner" "$home/.config/git/identity"
        chmod 644 "$home/.config/git/identity"
    fi
    local variant
    variant="$(keyboard_field 4)"
    install -o "${owner%:*}" -g "${owner#*:}" -m 644 /dev/stdin "$home/.config/hypr/local.lua" <<EOF
-- This machine's own Hyprland settings. Not part of the dotfiles repo, so
-- updates never touch it; loaded last, so whatever is set here wins.
-- The installer put your keyboard here - add anything else you like.
hl.config({
    input = {
        kb_layout  = "$(keyboard_field 3)",
        kb_variant = "$variant",
    },
})
EOF

    # First login runs bootstrap.sh once (flag-guarded, so it retries if it fails).
    install -o "${owner%:*}" -g "${owner#*:}" -m 644 /dev/stdin "$home/.bash_profile" <<'EOF'
[[ -f ~/.bashrc ]] && . ~/.bashrc

if [[ -t 0 && ! -e ~/.dotfiles-bootstrapped ]]; then
    ~/Dotfiles/system/install/bootstrap.sh && touch ~/.dotfiles-bootstrapped
fi
EOF
    # Even that first bash session keeps its history off the disk; bootstrap.sh
    # enforces the same line on every later run.
    printf '\n%s\n' 'HISTFILE=${XDG_RUNTIME_DIR:-/dev/shm}/bash_history' >> "$home/.bashrc"
    chown "$owner" "$home/.bashrc"

    # NetworkManager (nm_iwd backend) reads the same /var/lib/iwd profiles.
    if compgen -G '/var/lib/iwd/*.psk' >/dev/null; then
        install -d -m 700 "$TARGET/var/lib/iwd" &&
            install -m 600 /var/lib/iwd/*.psk "$TARGET/var/lib/iwd/" ||
            skipped+=("the Wi-Fi password")
    fi

    for item in "${skipped[@]}"; do
        fail "Copying $item failed - see $LOG."
    done
}

step_install() {
    screen "Installing"
    write_config

    if (( DRY )); then
        dim "Dry run - nothing is installed. archinstall would get:"
        echo
        jq . "$WORK/user_configuration.json"
        jq '.users[].enc_password = "<redacted>"
            | if has("encryption_password") then .encryption_password = "<redacted>" else . end' \
            "$WORK/user_credentials.json"
        if command -v archinstall >/dev/null && [[ $EUID -eq 0 ]]; then
            run_archinstall --dry-run && say "archinstall accepts this config."
        fi
        rm -rf "$WORK"
        exit 0
    fi

    # archinstall's own dry run parses and validates everything (layout,
    # alignment, encryption) before a single byte of the disk is touched.
    if ! run_archinstall --dry-run > "$LOG" 2>&1; then
        fail "The install config was rejected - nothing was changed on the disk."
        tail -n 15 "$LOG"
        say "Full log: $LOG"
        exit 1
    fi

    say "This takes a few minutes. Grab a coffee."
    echo
    run_archinstall 2>&1 | tee -a "$LOG"
    if (( PIPESTATUS[0] != 0 )) || ! mountpoint -q "$TARGET"; then
        echo
        fail "The installation failed. Full log: $LOG"
        say "The shell is yours - run ~/install.sh to try again."
        exit 1
    fi

    post_install
    rm -f "$WORK"/user_*.json
}

step_done() {
    local minutes=$(( SECONDS / 60 )) seconds=$(( SECONDS % 60 ))
    screen "Done in ${minutes}m ${seconds}s"
    say "Remove the USB stick, then reboot."
    echo
    say "After the reboot, log in with $(gum style --bold "$username") on the text screen:"
    say "the desktop sets itself up on that first login (about 10 minutes),"
    say "then reboot once more and you are in."
    echo
    if (( unattended )); then
        sleep 5
    else
        gum confirm --affirmative "Reboot now" --negative "Stay in the live system" "Reboot?" || exit 0
    fi
    umount -R "$TARGET" 2>/dev/null
    reboot
}

# ---------------------------------------------------------------- main

main() {
    [[ -n "$ANSWERS" ]] && load_answers

    if (( ! unattended )); then
        screen
        say "Welcome! A few questions and this computer runs these dotfiles."
        dim "Ctrl+C at any question to leave for a shell."
        echo
        gum confirm --affirmative "Start" --negative "Shell" "Ready?" || exit 0
    fi

    until step_network; do :; done
    if (( ! unattended )); then
        while :; do
            until step_keyboard; do :; done
            step_account
            until step_machine; do :; done
            until step_disk; do :; done
            step_confirm && break
        done
    fi
    step_install
    step_done
}

main
