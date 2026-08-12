#!/bin/bash
# Wired-only machines have no wifi to switch - clicking the network icon there is a no-op.
nmcli -t -f TYPE device status | grep -qx "wifi" || exit 0

exec ghostty --gtk-single-instance=false --class=org.dotfiles.impala --title=Impala -e impala
