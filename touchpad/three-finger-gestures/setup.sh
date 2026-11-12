#!/usr/bin/env bash
# Windows-style 3-finger gestures for KDE Plasma (InputActions KWin plugin).
# Run as your normal user; it asks for sudo when installing the plugin.
# Build tools (git, cmake, KWin dev headers) must already be installed.
set -e
cd "$(dirname "$0")"
mkdir -p ~/.config/inputactions ~/.local/share/inputactions-installer ~/.local/bin
cp config.yaml ~/.config/inputactions/config.yaml
cp inputactions-install.sh ~/.local/share/inputactions-installer/install.sh
install -m 755 rebuild-gestures ~/.local/bin/rebuild-gestures
bash ~/.local/share/inputactions-installer/install.sh --ctl --kwin --latest-stable
echo
echo "Done. Log out and back in to load the gestures."
