#!/usr/bin/env bash
# Touchpad drag lock (KDE Plasma, Wayland): after tap-and-drag you can lift
# your finger without dropping the item; tap once to drop.
# Usage: ./enable-drag-lock.sh        -> turn on
#        ./enable-drag-lock.sh off    -> turn off
set -e
value=true
[ "$1" = "off" ] && value=false

get() { qdbus6 org.kde.KWin "$1" org.freedesktop.DBus.Properties.Get org.kde.KWin.InputDevice "$2" 2>/dev/null || true; }

for dev in $(qdbus6 org.kde.KWin /org/kde/KWin/InputDevice org.kde.KWin.InputDeviceManager.ListPointers); do
    path=/org/kde/KWin/InputDevice/$dev
    [ "$(get "$path" touchpad)" = "true" ] || continue
    name=$(get "$path" name)
    vendor=$(get "$path" vendor)
    product=$(get "$path" product)
    # Apply now
    gdbus call --session -d org.kde.KWin -o "$path" -m org.freedesktop.DBus.Properties.Set \
        org.kde.KWin.InputDevice tapDragLock "<$value>" >/dev/null
    # Keep after reboot
    kwriteconfig6 --file kcminputrc --group Libinput --group "$vendor" --group "$product" \
        --group "$name" --key TapDragLock "$value"
    echo "Drag lock $value for: $name"
done
