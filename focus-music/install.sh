#!/usr/bin/env bash
# Install focus-music and hook it into the Fokus pomodoro widget (KDE Plasma 6).
#   Focus starts      -> music fades in (keeps playing if already on, e.g. after pause)
#   Focus time is up  -> music keeps playing
#   Break started     -> music fades out
#   Stop pressed      -> music fades out
#   Pause / resume    -> music pauses / resumes (via fokus-patch.sh)
# Needs: vlc (cvlc), pactl, curl, python3. Run as your normal user (no sudo).
set -e
cd "$(dirname "$0")"
./download-music.sh     # calm + lo-fi music into ~/Music/Focus (one time, ~250 MB)
install -m 755 focus-music focus-music-start.sh focus-music-stop.sh focus-music-pause.sh ~/.local/bin/
./fokus-patch.sh        # pause hook + right-click music menu + glass look

F=plasma-org.kde.plasma.desktop-appletsrc
read -r C A < <(awk -F'[][]' '/^\[Containments\]\[[0-9]+\]\[Applets\]\[[0-9]+\]$/{c=$4;a=$8}
                             /^plugin=com.dv.fokus$/{print c" "a; exit}' ~/.config/$F)
if [ -z "${A:-}" ]; then
    echo "Fokus widget not found on the desktop; add it, then run this again."; exit 1
fi
w() { kwriteconfig6 --file $F --group Containments --group "$C" --group Applets --group "$A" \
          --group Configuration --group General --key "$1" "$2"; }

cp ~/.config/$F ~/.config/$F.bak-before-focusmusic
systemctl --user stop plasma-plasmashell
w start_focus_script_enabled true; w start_focus_script_filepath "$HOME/.local/bin/focus-music-start.sh"
w start_break_script_enabled true; w start_break_script_filepath "$HOME/.local/bin/focus-music-stop.sh"
w stop_script_enabled true;        w stop_script_filepath "$HOME/.local/bin/focus-music-stop.sh"
w pause_script_enabled true;       w pause_script_filepath "$HOME/.local/bin/focus-music-pause.sh"
systemctl --user start plasma-plasmashell
echo "Done. Start a focus session in Fokus to hear it. Change sound: focus-music mode lofi"
