#!/usr/bin/env bash
# ASUS Armoury Crate-style extras for KDE Plasma (needs asusctl/asusd installed).
#  - Fn+F5 profile change -> on-screen icon + 60 Hz (Quiet) / 144 Hz (others)
#  - Fn+F4 -> next Aura keyboard effect + on-screen icon
#  - Plugging in the charger no longer forces the Performance profile
# Run as your normal user; asks for sudo only for the charger setting.
set -e
cd "$(dirname "$0")"

# 1. Scripts
mkdir -p ~/.local/bin ~/.config/systemd/user ~/.local/share/applications
install -m 755 asus-profile-osd asus-aura-next ~/.local/bin/

# 2. Profile icon + refresh-rate service (starts with the desktop session)
install -m 644 asus-profile-osd.service ~/.config/systemd/user/
systemctl --user daemon-reload
systemctl --user enable --now asus-profile-osd.service

# 3. Fn+F4 (sends the "Launch (4)" key) -> asus-aura-next
sed "s|^Exec=.*|Exec=$HOME/.local/bin/asus-aura-next|" net.local.asus-aura.desktop \
    > ~/.local/share/applications/net.local.asus-aura.desktop
kwriteconfig6 --file kglobalshortcutsrc --group services \
    --group net.local.asus-aura.desktop --key _launch "Launch (4)"
kbuildsycoca6 >/dev/null 2>&1 || true
ID="['net.local.asus-aura.desktop','_launch','ASUS Aura Next Mode','ASUS Aura Next Mode']"
gdbus call --session -d org.kde.kglobalaccel -o /kglobalaccel \
    -m org.kde.KGlobalAccel.doRegister "$ID" >/dev/null
gdbus call --session -d org.kde.kglobalaccel -o /kglobalaccel \
    -m org.kde.KGlobalAccel.setShortcut "$ID" "[16777382]" 4 >/dev/null  # Qt::Key_Launch4

# 4. Charger plug-in keeps the current profile (unplug still switches to Quiet)
if grep -q "change_platform_profile_on_ac: true" /etc/asusd/asusd.ron 2>/dev/null; then
    sudo sh -c 'systemctl stop asusd &&
        sed -i "s/change_platform_profile_on_ac: true/change_platform_profile_on_ac: false/" /etc/asusd/asusd.ron &&
        systemctl start asusd'
fi

echo "Done: Fn+F4 / Fn+F5 icons, auto refresh rate and charger setting are set up."
