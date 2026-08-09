# Overrides the releng .zlogin. Keeps its two behaviours - the screen reader
# fix and the script= kernel parameter hook - and adds the installer on tty1.

if grep -Fqa 'accessibility=' /proc/cmdline &> /dev/null; then
    setopt SINGLE_LINE_ZLE
fi

~/.automated_script.sh

# script= on the kernel command line wins: it is the documented way to override
# what a live ISO does, and someone passing it wants their script, not ours.
if [[ $(tty) == "/dev/tty1" && ! -e /tmp/startup_script ]]; then
    ~/install.sh
fi
