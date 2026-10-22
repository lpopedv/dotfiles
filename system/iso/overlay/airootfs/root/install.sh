#!/usr/bin/env bash
# Lethe's installer, on the live ISO's tty1: a few questions, then archinstall
# does the work unattended from a config built out of the answers. Nothing here
# needs Arch knowledge - that is the point of it.
#
#   install.sh                  the wizard (started by .zlogin on tty1)
#   install.sh --answers FILE   unattended: KEY=value answers, no questions
#   install.sh --dry-run        print the generated config, touch nothing
#                               (runs on any machine with gum and jq)
#
# On the ISO it re-launches itself inside kmscon - a userspace console with
# real font rendering - so the first screen already looks like the desktop.
set -uo pipefail

SELF="$(readlink -f "${BASH_SOURCE[0]}")"
ARGS=("$@")
DRY=0
ANSWERS=""
IN_KMSCON=0
while (( $# )); do
    case "$1" in
        --dry-run) DRY=1; shift ;;
        --answers) ANSWERS="${2:?--answers needs a file}"; shift 2 ;;
        --in-kmscon) IN_KMSCON=1; shift ;;
        *) echo "usage: $0 [--dry-run] [--answers FILE]" >&2; exit 2 ;;
    esac
done

# On the ISO the repo sits next to this script's installed copy; in a checkout
# (dry runs) it is five levels up from system/iso/overlay/airootfs/root.
DOTFILES=/root/Dotfiles
[[ -d "$DOTFILES" ]] || DOTFILES="$(cd "$(dirname "$SELF")/../../../../.." && pwd)"
BASE_CONFIG="$DOTFILES/system/install/archinstall.json"
VERSION="$(cat "$DOTFILES/.iso-revision" 2>/dev/null || git -C "$DOTFILES" describe --tags --always 2>/dev/null || echo unknown)"
TARGET=/mnt
WORK=/tmp/lethe-install
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

# ---------------------------------------------------------------- look

# The desktop's colors (quickshell/Theme.qml), given to the 16 console palette
# slots so every screen uses them by index - the only color kind both kmscon
# and the kernel console render faithfully. Slots keep their usual meaning
# where the theme has one (red, green, yellow); blue is repurposed as the
# theme's "subtle" grey, the one shade the 16 slots lack.
PALETTE=(000000 cc5f5f 7abc5c d2a24c 6b6b6b b762bc 5bbfb1 999999
         333333 d89179 9bd183 d8c288 7fa6d4 ce8ad2 83d4c5 ffffff)
C_RED=1 C_AMBER=3 C_SUBTLE=4 C_FG=7 C_LINE=8 C_WHITE=15
FONT="JetBrainsMono Nerd Font"

# The kernel console's built-in font has no rounded corners or check marks.
if [[ "${TERM:-}" == linux ]]; then
    G_OK="+" G_CUR=">" G_TODO="-" G_FULL="=" G_EMPTY="-" G_SEG="==" G_DOT="-" G_X="x" BORDER=normal
else
    G_OK="✓" G_CUR="›" G_TODO="○" G_FULL="━" G_EMPTY="─" G_SEG="━━━━" G_DOT="·" G_X="✕" BORDER=rounded
fi

STEPS=(Keyboard Network Account Computer Disk Review)

# Raw ANSI for the parts redrawn many times a second (gum per frame is slow).
fg() { local n="$1"; (( n < 8 )) && printf '\e[%dm' $(( 30 + n )) || printf '\e[%dm' $(( 90 + n - 8 )); }
RESET=$'\e[0m' BOLD=$'\e[1m'

# Everything sits in one centred column W wide, PAD from the left edge.
layout() {
    read -r ROWS COLS < <(stty size 2>/dev/null </dev/tty || echo "24 80")
    W=$(( COLS - 8 < 64 ? COLS - 8 : 64 ))
    PAD=$(( (COLS - W) / 2 ))
    TOP=$(( ROWS > 40 ? ROWS / 6 : 1 ))
    export GUM_CHOOSE_PADDING="0 0 0 $PAD" GUM_INPUT_PADDING="0 0 0 $PAD"
    export GUM_FILTER_PADDING="0 0 0 $PAD" GUM_CONFIRM_PADDING="0 0 0 $PAD"
    export GUM_SPIN_PADDING="0 0 0 $PAD" GUM_INPUT_WIDTH="$W" GUM_FILTER_WIDTH="$W"
}

theme_gum() {
    export GUM_CHOOSE_CURSOR="$G_CUR " GUM_CHOOSE_CURSOR_FOREGROUND=$C_WHITE
    export GUM_CHOOSE_ITEM_FOREGROUND=$C_FG GUM_CHOOSE_SELECTED_FOREGROUND=$C_WHITE
    export GUM_CHOOSE_HEADER="" GUM_CHOOSE_SHOW_HELP=false GUM_CHOOSE_HEIGHT=10

    export GUM_INPUT_PROMPT="$G_CUR " GUM_INPUT_PROMPT_FOREGROUND=$C_WHITE
    export GUM_INPUT_CURSOR_FOREGROUND=$C_WHITE GUM_INPUT_PLACEHOLDER_FOREGROUND=$C_LINE
    export GUM_INPUT_HEADER_FOREGROUND=$C_FG GUM_INPUT_SHOW_HELP=false

    export GUM_FILTER_PROMPT="$G_CUR " GUM_FILTER_PROMPT_FOREGROUND=$C_WHITE
    export GUM_FILTER_INDICATOR="$G_CUR" GUM_FILTER_INDICATOR_FOREGROUND=$C_WHITE
    export GUM_FILTER_MATCH_FOREGROUND=$C_WHITE GUM_FILTER_TEXT_FOREGROUND=$C_FG
    export GUM_FILTER_CURSOR_TEXT_FOREGROUND=$C_WHITE GUM_FILTER_HEADER_FOREGROUND=$C_FG
    export GUM_FILTER_PLACEHOLDER_FOREGROUND=$C_LINE GUM_FILTER_SHOW_HELP=false GUM_FILTER_HEIGHT=10

    export GUM_CONFIRM_PROMPT_FOREGROUND=$C_WHITE GUM_CONFIRM_SHOW_HELP=false
    export GUM_CONFIRM_SELECTED_BACKGROUND=$C_WHITE GUM_CONFIRM_SELECTED_FOREGROUND=0
    export GUM_CONFIRM_UNSELECTED_BACKGROUND=$C_LINE GUM_CONFIRM_UNSELECTED_FOREGROUND=$C_FG

    export GUM_SPIN_SPINNER=minidot GUM_SPIN_SPINNER_FOREGROUND=$C_WHITE GUM_SPIN_TITLE_FOREGROUND=$C_FG
}

# The kernel console (no kmscon): load the palette into its 16 slots.
console_palette() {
    local i
    for i in "${!PALETTE[@]}"; do printf '\e]P%X%s' "$i" "${PALETTE[$i]}"; done
    printf '\e[0m\e[H\e[2J'
}

# CLICOLOR_FORCE: these also run into pipes and $(...), where gum would
# otherwise decide there is no terminal and drop the colors.
center() {   # center COLOR TEXT [bold]
    CLICOLOR_FORCE=1 gum style --width "$COLS" --align center --foreground "$1" ${3:+--bold} "$2"
}

col() {      # col COLOR TEXT... - left-aligned in the column
    local color="$1"
    shift
    CLICOLOR_FORCE=1 gum style --padding "0 0 0 $PAD" --foreground "$color" "$@"
}

# Pinned to the bottom row - only on screens without a prompt: gum clears
# everything below itself while it draws.
footer() {
    printf '\e7\e[%d;1H' "$ROWS"
    center "$C_LINE" "$1"
    printf '\e8'
}

# Step dots: done and current in white, the rest in the line color.
progress() {
    local i out="" n="$1"
    for i in "${!STEPS[@]}"; do
        if (( i <= n )); then out+="$(fg "$C_WHITE")$G_SEG"; else out+="$(fg "$C_LINE")$G_SEG"; fi
        (( i < ${#STEPS[@]} - 1 )) && out+=" "
    done
    gum style --width "$COLS" --align center "$out$RESET"
}

brand() {
    printf '\e[H\e[2J'
    printf '\n%.0s' $(seq 1 "$TOP")
    center "$C_WHITE" "l e t h e" bold
    center "$C_SUBTLE" "arch linux $G_DOT hyprland $G_DOT $VERSION"
    echo
}

# screen STEP TITLE SUBTITLE - a fresh page for one step of the wizard.
screen() {
    layout
    brand
    if [[ -n "$1" ]]; then
        progress "$1"
        echo
        echo
    fi
    col "$C_WHITE" --bold "$2"
    [[ -n "${3:-}" ]] && col "$C_SUBTLE" "$3"
    echo
}

# One answered field, left on the page as the next one is asked.
answered() {
    printf '%*s%s%-18s%s%s%s\n' "$PAD" "" "$(fg "$C_SUBTLE")" "$1" "$(fg "$C_WHITE")" "$2" "$RESET"
}

fail() { col "$C_RED" "$G_X  $*"; }
note() { col "$C_SUBTLE" "$*"; }

# Ctrl+C or Esc in any prompt lands here: leave for a shell, or carry on.
maybe_quit() {
    echo
    if gum confirm --default=false --affirmative "Quit to a shell" --negative "Keep going" \
        "Leave the installer?"; then
        printf '\e[H\e[2J'
        echo "Run ~/install.sh to start again."
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

# ---------------------------------------------------------------- kmscon

# Font size from the first connected screen's width: ~90 columns of glyph
# height across, so a 4K panel isn't drawn with a 1080p font.
font_px() {
    local status width=1920 px
    for status in /sys/class/drm/card*-*/status; do
        [[ "$(cat "$status" 2>/dev/null)" == connected ]] || continue
        width="$(head -n1 "${status%/status}/modes" 2>/dev/null | cut -dx -f1)"
        break
    done
    [[ "$width" =~ ^[0-9]+$ ]] || width=1920
    px=$(( width / 90 ))
    (( px < 16 )) && px=16
    (( px > 40 )) && px=40
    echo "$px"
}

# Runs this script inside kmscon on VT 8 - past the six VTs logind hands a
# getty, so nothing else claims it. The keyboard is kmscon's (xkb), so
# picking a layout relaunches it with that layout - it has to be right before
# a single password is typed. Returns non-zero if kmscon never got us running,
# so the caller falls back to the kernel console.
run_in_kmscon() {
    local names=(black red green yellow blue magenta cyan light-grey dark-grey light-red
                 light-green light-yellow light-blue light-magenta light-cyan white)
    local flags=() i hex layout="" variant=""
    for i in "${!names[@]}"; do
        hex="${PALETTE[$i]}"
        flags+=("--palette-${names[$i]}=$((16#${hex:0:2})),$((16#${hex:2:2})),$((16#${hex:4:2}))")
    done
    flags+=("--palette-foreground=153,153,153" "--palette-background=0,0,0")

    while :; do
        rm -f "$WORK/started" "$WORK/relaunch"
        kmscon --vt=8 --switchvt --oneshot --no-issue --no-reset-env --term=xterm-256color \
            --font-engine=pango --font-name="$FONT" --font-size="$(font_px)" \
            --palette=custom "${flags[@]}" ${layout:+--xkb-layout="$layout"} \
            ${variant:+--xkb-variant="$variant"} \
            --login -- "$SELF" --in-kmscon "${ARGS[@]}" 2>>"$WORK/kmscon.log"
        chvt 1 2>/dev/null
        [[ -f "$WORK/started" ]] || return 1
        [[ -f "$WORK/relaunch" ]] || return 0
        IFS='|' read -r layout variant < "$WORK/relaunch"
    done
}

# ---------------------------------------------------------------- answers file

keyboard_field() {   # keyboard_field N -> field N of the chosen layout's row
    awk -F'|' -v l="$keyboard_label" -v n="$1" '$1 == l { print $n }' <<< "$KEYBOARDS"
}

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

# ---------------------------------------------------------------- welcome

step_welcome() {
    layout
    printf '\e[H\e[2J'
    printf '\n%.0s' $(seq 1 $(( ROWS / 2 - 5 > 1 ? ROWS / 2 - 5 : 1 )))
    # The wordmark types itself out, then the rule under it draws.
    local word="l e t h e" i
    printf '\e[?25l'
    for (( i = 1; i <= ${#word}; i += 2 )); do
        printf '\r'
        center "$C_WHITE" "$(printf '%-*s' "${#word}" "${word:0:i}")" bold | tr -d '\n'
        sleep 0.045
    done
    echo
    for (( i = 1; i <= 13; i += 2 )); do
        printf '\r'
        center "$C_LINE" "$(printf '%*s' "$i" '' | sed "s/ /$G_EMPTY/g")" | tr -d '\n'
        sleep 0.02
    done
    echo
    printf '\e[?25h'
    center "$C_SUBTLE" "arch linux $G_DOT hyprland"
    echo
    echo
    center "$C_FG" "A few questions, then this computer is yours."
    echo
    gum confirm --affirmative "Begin" --negative "Shell" \
        --padding "0 0 0 $(( (COLS - 22) / 2 ))" "" || exit 0
}

# ---------------------------------------------------------------- keyboard

step_keyboard() {
    screen 0 "Keyboard" "Which layout is printed on your keys?"
    local before="$keyboard_label"
    ask keyboard_label choose --selected "$keyboard_label" < <(cut -d'|' -f1 <<< "$KEYBOARDS") || return 1
    printf '%s\n' "$keyboard_label" > "$WORK/keyboard"

    if (( IN_KMSCON )); then
        # kmscon reads its layout at start: relaunch it with this one, unless it
        # already runs it (a relaunch picks up here with the choice made).
        if [[ "$keyboard_label" != "$before" || ! -f "$WORK/keyboard-applied" ]]; then
            printf '%s|%s\n' "$(keyboard_field 3)" "$(keyboard_field 4)" > "$WORK/relaunch"
            printf '%s\n' "$keyboard_label" > "$WORK/keyboard-applied"
            exit 0
        fi
    elif (( ! DRY )) && [[ "$(tty)" == /dev/tty[0-9]* ]]; then
        loadkeys "$(keyboard_field 2)" 2>/dev/null
    fi
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
    screen 1 "Network" "Everything is downloaded fresh, so we need internet."
    if gum spin --title "Checking the connection" -- bash -c "$(declare -f online); online"; then
        answered "Connection" "online"
        sleep 0.6
        return 0
    fi
    (( DRY )) && { note "Offline - a dry run carries on anyway."; sleep 1; return 0; }

    local dev
    rfkill unblock wifi 2>/dev/null
    if ! dev="$(wifi_device)"; then
        fail "No connection, and no Wi-Fi card to make one."
        note "Plug in a network cable - this checks again in a moment."
        sleep 5
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
    gum spin --title "Looking for Wi-Fi networks" -- \
        bash -c "iwctl station '$dev' scan >/dev/null 2>&1; sleep 4"

    local networks ssid pass=""
    networks="$(wifi_networks "$dev")"
    if [[ -z "$networks" ]]; then
        fail "No Wi-Fi networks in range."
        sleep 2
        return 1
    fi
    ask ssid choose --header "" <<< "$networks" || return 1
    answered "Wi-Fi" "$ssid"
    ask pass input --password --header "Password (empty for an open network)" || return 1

    gum spin --title "Connecting to $ssid" -- \
        bash -c "$(declare -f wifi_connect); wifi_connect '$dev' \"\$1\" \"\$2\"; sleep 3" _ "$ssid" "$pass"
    online && return 0
    fail "Couldn't get online through $ssid - check the password."
    sleep 2
    return 1
}

# ---------------------------------------------------------------- questions

step_account() {
    local again
    screen 2 "Your account" "How you'll sign in. The password also unlocks the disk."
    while :; do
        ask username input --header "Username" --placeholder "lowercase, e.g. alice" --value "$username" || continue
        if [[ ! "$username" =~ $USERNAME_PATTERN ]]; then
            fail "Lowercase letters, digits, - and _, starting with a letter."
        elif [[ "$username" =~ $RESERVED_USERNAMES ]]; then
            fail "\"$username\" belongs to the system - pick another."
        else
            break
        fi
    done
    answered "Username" "$username"
    while :; do
        ask password input --password --header "Password" --placeholder "at least 8 characters" || continue
        ask again input --password --header "Same password again" || continue
        if [[ "$password" != "$again" ]]; then
            fail "Those don't match - once more."
        elif (( ${#password} < 8 )); then
            fail "At least 8 characters, please."
        else
            break
        fi
    done
    answered "Password" "$(printf '%*s' "${#password}" '' | tr ' ' '•')"
    ask full_name input --header "Your name, for git commits" --placeholder "optional" --value "$full_name" || :
    [[ -n "$full_name" ]] && answered "Name" "$full_name"
    ask email input --header "Your email, for git commits" --placeholder "optional" --value "$email" || :
    [[ -n "$email" ]] && answered "Email" "$email"
    sleep 0.4
}

step_machine() {
    screen 3 "This computer" "Its name on the network, and where it keeps time."
    while :; do
        ask hostname input --header "Computer name" --value "$hostname" || continue
        [[ "$hostname" =~ $HOSTNAME_PATTERN ]] && break
        fail "Letters, digits and - only, up to 63 characters."
    done
    answered "Computer name" "$hostname"
    ask timezone filter --header "Time zone" --placeholder "type a city" --value "$timezone" \
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
        parts="$(lsblk -nro TYPE,FSTYPE "$name" | awk '$1 == "part" { printf "%s%s", s, ($2 == "" ? "?" : $2); s = ", " }')"
        printf '%-14s %8s   %s%s\n' "$name" "$size" "${model:-disk}" "${parts:+   ($parts)}"
    done < <(lsblk -dnpo NAME,TYPE,RO | awk '$2 == "disk" && $3 == 0 { print $1 }')
}

step_disk() {
    screen 4 "Where to install" "The disk you pick is erased completely."
    local choices choice gib
    choices="$(disk_choices)"
    if [[ -z "$choices" ]]; then
        fail "No disk to install on was found."
        sleep 3
        return 1
    fi
    ask choice choose <<< "$choices" || return 1
    disk="${choice%% *}"
    gib=$(( $(lsblk -bdno SIZE "$disk") / 1024**3 ))
    if (( gib < MIN_DISK_GIB )); then
        fail "$disk is ${gib} GiB - at least ${MIN_DISK_GIB} GiB is needed."
        sleep 2
        return 1
    fi
    answered "Disk" "$disk"

    local enc
    echo
    col "$C_FG" "Encrypt it? Nobody can read your files without the password,"
    col "$C_FG" "even with the disk out of the computer."
    echo
    ask enc choose "Yes, encrypt it (recommended)" "No" || return 1
    if [[ "$enc" == Yes* ]]; then encrypt=yes; else encrypt=no; fi
}

# Model names run long ("WD_BLACK SN750 SE 500GB"): cut to fit the summary.
disk_label() {
    local model
    model="$(lsblk -dno MODEL "$1" | sed 's/[[:space:]]*$//')"
    (( ${#model} > 16 )) && model="${model:0:15}…"
    printf '%s  %s  %s' "$1" "$(lsblk -dno SIZE "$1" | tr -d ' ')" "$model"
}

step_confirm() {
    screen 5 "Ready when you are" "Check everything once more."
    local v s
    v="$(fg "$C_WHITE")" s="$(fg "$C_SUBTLE")"
    {
        printf '%s%-14s%s%s\n' "$s" Keyboard "$v" "$keyboard_label"
        printf '%s%-14s%s%s\n' "$s" Username "$v" "$username"
        [[ -n "$full_name" ]] && printf '%s%-14s%s%s\n' "$s" Name "$v" "$full_name"
        [[ -n "$email" ]] && printf '%s%-14s%s%s\n' "$s" Email "$v" "$email"
        printf '%s%-14s%s%s\n' "$s" Computer "$v" "$hostname"
        printf '%s%-14s%s%s\n' "$s" "Time zone" "$v" "$timezone"
        printf '%s%-14s%s%s\n' "$s" Disk "$v" "$(disk_label "$disk")"
        printf '%s%-14s%s%s' "$s" Encryption "$v" "$([[ $encrypt == yes ]] && echo 'on, with your password' || echo off)"
    } | gum style --border "$BORDER" --border-foreground "$C_LINE" --padding "1 3" \
        --margin "0 0 0 $PAD" --width "$W"
    echo
    col "$C_RED" "$G_X  Everything on $disk will be erased."
    echo
    gum confirm --default=false --affirmative "Erase & install" --negative "Change something" ""
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

PHASES=("Preparing the disk" "Installing the base system" "Setting up boot"
        "Creating your account" "Installing the rest" "Done")

# Reads archinstall's output so far and prints "PHASE DONE TOTAL PACKAGE":
# the phase from the markers archinstall logs (only ever moving forward), and
# pacman's "(n/N) installing pkg" lines for the package bar.
install_state() {
    tail -c 400000 "$LOG" 2>/dev/null | tr '\r' '\n' | sed 's/\x1b\[[0-9;?]*[A-Za-z]//g' | awk '
        BEGIN { p = 0; n = 0; t = 0; pkg = "" }
        /Installing packages:/ { if (p < 1) p = 1; else if (p >= 3) p = 4; n = 0; t = 0; pkg = "" }
        /Adding bootloader/    { if (p < 2) p = 2; n = 0; t = 0 }
        /Creating user/        { if (p < 3) p = 3; n = 0; t = 0 }
        /Installation completed/ { p = 5 }
        match($0, /\( *[0-9]+\/[0-9]+\) (installing|upgrading|reinstalling) [^ .]+/) {
            s = substr($0, RSTART + 1, RLENGTH - 1)
            gsub(/^ +/, "", s)
            split(s, a, /[\/) ]+/)
            n = a[1] + 0; t = a[2] + 0; pkg = a[4]
        }
        END { print p, n, t, (pkg == "" ? "-" : pkg) }'
}

draw_install() {   # draw_install PHASE DONE TOTAL PACKAGE FRAME
    local phase="$1" n="$2" t="$3" pkg="$4" frame="$5" i row=$(( TOP + 6 )) line
    local spin=(⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏)
    [[ "${TERM:-}" == linux ]] && spin=('|' '/' '-' '\')
    for i in 0 1 2 3 4; do
        if (( i < phase )); then
            line="$(fg "$C_FG")$G_OK  ${PHASES[$i]}"
        elif (( i == phase )); then
            line="$(fg "$C_WHITE")${spin[frame % ${#spin[@]}]}  $BOLD${PHASES[$i]}"
        else
            line="$(fg "$C_LINE")$G_TODO  ${PHASES[$i]}"
        fi
        printf '\e[%d;1H\e[2K%*s%s%s' "$row" "$PAD" "" "$line" "$RESET"
        row=$(( row + 1 ))
        # The package bar sits under whichever phase is installing packages.
        if (( i == phase && t > 0 )); then
            local bar=$(( W - 16 )) filled
            filled=$(( n * bar / t ))
            printf '\e[%d;1H\e[2K%*s%s%s%s%s  %s%3d%%%s' "$row" "$(( PAD + 3 ))" "" \
                "$(fg "$C_WHITE")" "$(printf "%${filled}s" '' | sed "s/ /$G_FULL/g")" \
                "$(fg "$C_LINE")" "$(printf "%$(( bar - filled ))s" '' | sed "s/ /$G_EMPTY/g")" \
                "$(fg "$C_FG")" $(( n * 100 / t )) "$RESET"
            printf '\e[%d;1H\e[2K%*s%s%s%s' $(( row + 1 )) "$(( PAD + 3 ))" "" \
                "$(fg "$C_SUBTLE")" "$n of $t  $G_DOT  $pkg" "$RESET"
            row=$(( row + 2 ))
        elif (( i == phase )); then
            printf '\e[%d;1H\e[2K\e[%d;1H\e[2K' "$row" $(( row + 1 ))
            row=$(( row + 2 ))
        fi
    done
    local secs=$(( SECONDS - install_started ))
    printf '\e[%d;1H\e[2K' $(( row + 1 ))
    center "$C_SUBTLE" "$(printf '%d:%02d' $(( secs / 60 )) $(( secs % 60 )))"
}

# Run as root on the live system; ownership comes from the new home itself.
post_install() {
    local home="$TARGET/home/$username" owner skipped=()
    owner="$(stat -c %u:%g "$home" 2>/dev/null)" || {
        skipped+=("the dotfiles (no $home)")
        printf '%s\n' "${skipped[@]}" > "$WORK/skipped"
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
    install -o "${owner%:*}" -g "${owner#*:}" -m 644 /dev/stdin "$home/.config/hypr/local.lua" <<EOF
-- This machine's own Hyprland settings. Not part of the dotfiles repo, so
-- updates never touch it; loaded last, so whatever is set here wins.
-- The installer put your keyboard here - add anything else you like.
hl.config({
    input = {
        kb_layout  = "$(keyboard_field 3)",
        kb_variant = "$(keyboard_field 4)",
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
    (( ${#skipped[@]} )) && printf '%s\n' "${skipped[@]}" > "$WORK/skipped"
}

install_failed() {
    printf '\e[?25h'
    screen "" "Something went wrong" "Nothing after this point was changed. The log has the details."
    tail -n 12 "$LOG" | sed 's/\x1b\[[0-9;?]*[A-Za-z]//g' | cut -c1-$(( W - 6 )) |
        gum style --border "$BORDER" --border-foreground "$C_LINE" --foreground "$C_SUBTLE" \
            --padding "0 2" --margin "0 0 0 $PAD" --width "$W"
    echo
    note "Full log: $LOG"
    note "Run ~/install.sh to try again."
    exit 1
}

step_install() {
    write_config

    if (( DRY )); then
        screen "" "Dry run" "Nothing is installed. archinstall would get:"
        jq . "$WORK/user_configuration.json"
        jq '.users[].enc_password = "<redacted>"
            | if has("encryption_password") then .encryption_password = "<redacted>" else . end' \
            "$WORK/user_credentials.json"
        if command -v archinstall >/dev/null && [[ $EUID -eq 0 ]]; then
            run_archinstall --dry-run && note "archinstall accepts this config."
        fi
        rm -rf "$WORK"
        exit 0
    fi

    screen "" "Installing" "$(disk_label "$disk")"
    # archinstall's own dry run parses and validates everything (layout,
    # alignment, encryption) before a single byte of the disk is touched.
    if ! gum spin --title "Checking the plan" -- \
        bash -c "archinstall --config '$WORK/user_configuration.json' --creds '$WORK/user_credentials.json' --silent --dry-run > '$LOG' 2>&1"; then
        install_failed
    fi

    footer "this takes a few minutes  $G_DOT  the computer can stay unattended"
    install_started=$SECONDS
    printf '\e[?25l'
    run_archinstall < /dev/null >> "$LOG" 2>&1 &
    local pid=$! frame=0 state
    while kill -0 "$pid" 2>/dev/null; do
        layout
        read -r -a state < <(install_state)
        draw_install "${state[@]}" "$frame"
        frame=$(( frame + 1 ))
        sleep 0.15
    done
    wait "$pid" || install_failed
    mountpoint -q "$TARGET" || install_failed

    draw_install 4 0 0 - "$frame"
    post_install
    draw_install 5 0 0 - 0
    printf '\e[?25h'
    rm -f "$WORK"/user_*.json
}

step_done() {
    local secs=$(( SECONDS - ${install_started:-0} ))
    layout
    printf '\e[H\e[2J'
    printf '\n%.0s' $(seq 1 $(( ROWS / 2 - 8 > 1 ? ROWS / 2 - 8 : 1 )))
    gum style --width "$COLS" --align center --foreground "$C_WHITE" --bold \
        "$(CLICOLOR_FORCE=1 gum style --border "$BORDER" --border-foreground "$C_LINE" --padding "0 2" "$G_OK")"
    echo
    center "$C_WHITE" "Installed" bold
    center "$C_SUBTLE" "in $(( secs / 60 ))m $(( secs % 60 ))s"
    echo
    echo
    center "$C_FG" "Remove the USB stick and reboot."
    center "$C_FG" "Then sign in as $username on the text screen: the desktop"
    center "$C_FG" "sets itself up on that first login, about ten minutes."
    if [[ -s "$WORK/skipped" ]]; then
        echo
        while read -r item; do center "$C_AMBER" "Couldn't copy $item - see $LOG"; done < "$WORK/skipped"
    fi
    echo
    echo
    if (( unattended )); then
        sleep 5
    else
        gum confirm --affirmative "Reboot" --negative "Stay here" \
            --padding "0 0 0 $(( (COLS - 24) / 2 ))" "" || exit 0
    fi
    umount -R "$TARGET" 2>/dev/null
    reboot
}

# ---------------------------------------------------------------- main

main() {
    # On the ISO's console: move into kmscon first, if this machine can run it.
    if (( ! IN_KMSCON )); then
        # A new run starts from the welcome screen, with a fresh keyboard choice.
        rm -f "$WORK/keyboard-applied"
        if (( ! DRY )) && [[ "$(tty)" == /dev/tty[0-9]* ]]; then
            if command -v kmscon >/dev/null && compgen -G '/dev/dri/card*' >/dev/null &&
                run_in_kmscon; then
                echo "Left the installer. Run ~/install.sh to start it again."
                exit 0
            fi
            console_palette
        fi
    fi
    (( IN_KMSCON )) && touch "$WORK/started"

    theme_gum
    [[ -n "$ANSWERS" ]] && load_answers

    if (( ! unattended )); then
        # A kmscon relaunch for the keyboard layout resumes after that step.
        if [[ -f "$WORK/keyboard-applied" ]]; then
            keyboard_label="$(cat "$WORK/keyboard-applied")"
        else
            step_welcome
            until step_keyboard; do :; done
        fi
    fi

    until step_network; do :; done
    if (( ! unattended )); then
        while :; do
            step_account
            until step_machine; do :; done
            until step_disk; do :; done
            step_confirm && break
            until step_keyboard; do :; done
        done
    fi
    step_install
    step_done
}

main
