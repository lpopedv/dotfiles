#!/bin/bash
# Manual night-light toggle for hyprsunset. No hyprsunset.conf profile is
# used - this is a plain on/off switch, like GNOME's manual Night Light
# toggle.
#
# hyprsunset has no live "set temperature" IPC command from the CLI: running
# `hyprsunset -t X` while an instance is already up just starts a second
# daemon, which fails to bind the compositor's CTM control protocol ("A CTM
# manager is already running") and does nothing. So instead we kill the
# running instance and start a fresh one with the flag we want.

statefile="${XDG_RUNTIME_DIR:-/tmp}/waybar-nightlight.state"
warm_temp=4000
icon=$'\uf186'  # nf-fa-moon_o

is_active() {
    [[ -f "$statefile" ]]
}

restart_with() {
    pkill -x hyprsunset
    for _ in $(seq 1 20); do
        pgrep -x hyprsunset >/dev/null || break
        sleep 0.05
    done
    "$@" &
    disown
}

case "$1" in
    toggle)
        if is_active; then
            restart_with hyprsunset -i
            rm -f "$statefile"
        else
            restart_with hyprsunset -t "$warm_temp"
            touch "$statefile"
        fi
        ;;
    *)
        if is_active; then
            printf '{"text":"%s","tooltip":"Night light ativo (%sK)\\nClique para desativar","class":"active"}\n' "$icon" "$warm_temp"
        else
            printf '{"text":"%s","tooltip":"Night light desativado\\nClique para ativar o filtro de luz azul","class":"inactive"}\n' "$icon"
        fi
        ;;
esac
