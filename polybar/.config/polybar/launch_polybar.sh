if ! pgrep -x "polybar" > /dev/null; then
    polybar --reload toph &
else
    polybar-msg cmd restart toph &
fi
