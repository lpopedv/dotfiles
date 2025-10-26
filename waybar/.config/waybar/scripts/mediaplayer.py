#!/usr/bin/env python3

import subprocess
import json
import sys

def get_player_info():
    try:
        # Get the currently playing media using playerctl
        status = subprocess.run(['playerctl', 'status'], capture_output=True, text=True).stdout.strip()
        
        if status == "":
            return None
            
        # Get player name
        player = subprocess.run(['playerctl', 'metadata', 'playerName'], capture_output=True, text=True).stdout.strip()
        if not player:
            player = "unknown"
        
        # Get title and artist
        title = subprocess.run(['playerctl', 'metadata', 'title'], capture_output=True, text=True).stdout.strip()
        artist = subprocess.run(['playerctl', 'metadata', 'artist'], capture_output=True, text=True).stdout.strip()
        
        if not title:
            title = "Unknown Title"
        if not artist:
            artist = "Unknown Artist"
            
        # Format the display text
        if len(title) > 20:
            title = title[:17] + "..."
        if len(artist) > 15:
            artist = artist[:12] + "..."
            
        text = f"{title} - {artist}"
        tooltip = f"Player: {player}\nTitle: {title}\nArtist: {artist}\nStatus: {status}"
        
        # Determine icon based on player
        if "spotify" in player.lower():
            icon = "spotify"
        elif "firefox" in player.lower() or "chromium" in player.lower() or "chrome" in player.lower():
            icon = "firefox"
        else:
            icon = "default"
            
        # Determine class based on status
        if status.lower() == "playing":
            css_class = "playing"
        elif status.lower() == "paused":
            css_class = "paused"
        else:
            css_class = "stopped"
            
        return {
            "text": text,
            "tooltip": tooltip,
            "class": css_class,
            "icon": icon
        }
        
    except Exception as e:
        return None

def main():
    player_info = get_player_info()
    
    if player_info:
        output = {
            "text": player_info["text"],
            "tooltip": player_info["tooltip"],
            "class": player_info["class"]
        }
        print(json.dumps(output))
    else:
        # No media playing
        print('{"text": "", "tooltip": "No media playing", "class": "stopped"}')

if __name__ == "__main__":
    main()