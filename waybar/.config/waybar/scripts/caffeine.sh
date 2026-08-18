#!/bin/bash
# Manual caffeine toggle: holds a systemd idle inhibitor so hypridle's
# lock/dpms-off/suspend listeners don't fire while active (they already
# respect systemd inhibitors - see hypridle.conf's general block).
# Only inhibits "idle", not "sleep", so manual suspend (wlogout, power
# button) still works while caffeine is on.

pidfile="${XDG_RUNTIME_DIR:-/tmp}/waybar-caffeine.pid"
icon=$'\U000f06ca'  # nf-md-coffee_outline - matches nightlight's thin-line nf-fa-moon_o

is_active() {
    [[ -f "$pidfile" ]] && kill -0 "$(cat "$pidfile" 2>/dev/null)" 2>/dev/null
}

case "$1" in
    toggle)
        if is_active; then
            kill "$(cat "$pidfile")" 2>/dev/null
            rm -f "$pidfile"
        else
            systemd-inhibit --what=idle --who=waybar --why="Caffeine mode (manual)" sleep infinity &
            disown
            echo $! > "$pidfile"
        fi
        ;;
    *)
        if is_active; then
            printf '{"text":"%s","tooltip":"Caffeine ativo - bloqueio e suspensão automáticos desativados\\nClique para desativar","class":"active"}\n' "$icon"
        else
            printf '{"text":"%s","tooltip":"Caffeine desativado\\nClique para impedir bloqueio/suspensão automáticos","class":"inactive"}\n' "$icon"
        fi
        ;;
esac
