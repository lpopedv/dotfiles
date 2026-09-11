if grep -Fqa 'accessibility=' /proc/cmdline &> /dev/null; then
    setopt SINGLE_LINE_ZLE
fi

~/.automated_script.sh

# script= on the kernel cmdline wins: someone passing it wants their script.
if [[ $(tty) == "/dev/tty1" && ! -e /tmp/startup_script ]]; then
    ~/install.sh
fi
