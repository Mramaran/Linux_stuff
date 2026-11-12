#!/bin/sh
# Installs Windows-style touchpad edge motion. Run with sudo.
# Undo: sudo systemctl disable --now touchpad-edge-motion &&
#       sudo rm /usr/local/bin/touchpad-edge-motion /etc/systemd/system/touchpad-edge-motion.service
set -e
cd "$(dirname "$0")"
apt-get install -y python3-evdev
python3 -m py_compile touchpad-edge-motion
install -m 755 touchpad-edge-motion /usr/local/bin/touchpad-edge-motion
install -m 644 touchpad-edge-motion.service /etc/systemd/system/touchpad-edge-motion.service
systemctl daemon-reload
systemctl enable --now touchpad-edge-motion
sleep 1
systemctl is-active touchpad-edge-motion
