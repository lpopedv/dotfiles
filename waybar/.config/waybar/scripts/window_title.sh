title=$(hyprctl activewindow -j 2>/dev/null | jq -r '.title // empty')

if [[ -z "$title" ]]; then
    echo "Desktop"
else
    echo "$title"
fi
