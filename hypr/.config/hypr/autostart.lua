hl.on("hyprland.start", function()
    hl.exec_cmd("systemctl --user start hyprland-session.target")

    hl.exec_cmd("hyprpaper")
    hl.exec_cmd("hypridle")
    -- no hyprsunset: the bar's night-light widget owns that daemon (only one can bind the CTM protocol)
    hl.exec_cmd("qs")
    hl.exec_cmd("kbuildsycoca6")
    hl.exec_cmd("/usr/lib/polkit-kde-authentication-agent-1")
    hl.exec_cmd("wl-paste --type text --watch cliphist store -max-items 50 -min-store-length 5")
    hl.exec_cmd("wl-paste --type image --watch cliphist store -max-items 50 -min-store-length 5")
    hl.exec_cmd("flameshot")

    -- launched via wait-for-tray.sh, not Mullvad's own autostart, to avoid a tray-registration race
    hl.exec_cmd("$HOME/.config/hypr/scripts/wait-for-tray.sh && \"/opt/Mullvad VPN/mullvad-vpn\"")
end)

hl.on("hyprland.shutdown", function()
    os.execute("systemctl --user stop hyprland-session.target && sleep 0.1")
end)
