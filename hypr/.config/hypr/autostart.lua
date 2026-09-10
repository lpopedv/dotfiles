hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprland-session.target")

    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    -- No hyprsunset here: the bar's night-light widget owns that daemon, and a
    -- second instance cannot bind the compositor's CTM protocol.
    --
    -- Waiting for outputs first: launched bare, qs sometimes wins the race
    -- against Hyprland's own output setup, so the dock's first layer-shell
    -- commit latches a reserved zone Hyprland never recomputes - a dock that
    -- looks gone but still holds its space until its mode is toggled by
    -- hand. See scripts/wait-for-outputs.sh.
    hl.exec_cmd("$HOME/.config/hypr/scripts/wait-for-outputs.sh; qs")
    hl.exec_cmd("kbuildsycoca6")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    -- Capped at 50 items (default 750) and ignores anything under 5 chars;
    -- cliphist-wipe.timer clears it out entirely every 2 days on top
    hl.exec_cmd("wl-paste --type text --watch cliphist store -max-items 50 -min-store-length 5")
    hl.exec_cmd("wl-paste --type image --watch cliphist store -max-items 50 -min-store-length 5")
    hl.exec_cmd("flameshot")

    -- Launched explicitly here, not via Mullvad's own "launch on start-up"
    -- (disable that in the app's settings) - that path fires through
    -- systemd's xdg-desktop-autostart with no ordering against the bar, so
    -- it wins the tray-registration race often enough to matter. Waiting
    -- for the tray watcher first fixes it; see scripts/wait-for-tray.sh.
    hl.exec_cmd("$HOME/.config/hypr/scripts/wait-for-tray.sh && \"/opt/Mullvad VPN/mullvad-vpn\"")
end)

hl.on("hyprland.shutdown", function()
    os.execute("systemctl --user stop hyprland-session.target && sleep 0.1")
end)
