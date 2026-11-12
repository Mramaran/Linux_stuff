# Linux_stuff

Settings and scripts for the ASUS TUF Gaming A15 (FA507NVR) on Ubuntu 26.04 with KDE Plasma 6 (Wayland).

## asus/

Armoury Crate-style extras. Needs `asusctl` / `asusd` installed.

| Feature | How it works |
|---|---|
| **Fn+F5** | Kernel cycles Quiet / Balanced / Performance; `asus-profile-osd` shows an on-screen icon |
| **Refresh rate** | Same service sets 60 Hz in Quiet, 144 Hz in Balanced/Performance (also at login) |
| **Fn+F4** | Bound in KDE to `asus-aura-next`: next Aura keyboard effect + on-screen icon |
| **Charger** | Plugging in keeps the current profile; unplugging still switches to Quiet |

- `asus-profile-osd`: watches `/sys/firmware/acpi/platform_profile`, shows the icon and sets the refresh rate
- `asus-profile-osd.service`: systemd **user** service that runs it with the desktop session
- `asus-aura-next`: `asusctl aura effect --next-mode` + on-screen icon
- `net.local.asus-aura.desktop`: KDE shortcut entry for Fn+F4 (the key sends "Launch (4)")
- `setup.sh`: installs all of the above and sets `change_platform_profile_on_ac: false` in
  `/etc/asusd/asusd.ron` (asks for sudo only for that)

Install: `./setup.sh` (as your normal user)

Remove:
```bash
systemctl --user disable --now asus-profile-osd
rm ~/.local/bin/asus-profile-osd ~/.local/bin/asus-aura-next \
   ~/.config/systemd/user/asus-profile-osd.service \
   ~/.local/share/applications/net.local.asus-aura.desktop
```
To let the charger switch to Performance again, set `change_platform_profile_on_ac: true` in
`/etc/asusd/asusd.ron` (stop `asusd` first, then start it again).

## touchpad/

Windows-style touchpad features.

### three-finger-gestures/
Uses the [InputActions](https://github.com/InputActions) KWin plugin.

| Gesture | Action |
|---|---|
| 3 fingers, quick flick left/right | Jump to previous app (Alt+Tab) |
| 3 fingers, slow swipe left/right | App switcher; slide to choose, lift to switch |
| 3 fingers up | Overview (like Windows Task View) |
| 3 fingers down | Show desktop |

- `config.yaml`: the gesture config (lives at `~/.config/inputactions/config.yaml`)
- `setup.sh`: copies the config and builds/installs the plugin (needs sudo, git, cmake and KWin dev headers)
- `rebuild-gestures`: run after a KDE Plasma/KWin update if gestures stop working, then log out and in
- `inputactions-install.sh`: the InputActions installer script (downloads the source from GitHub)

### edge-motion/
Keeps the cursor moving while one finger is held at any edge of the touchpad, including while dragging. libinput has no built-in option for this.

- Only reads the touchpad (never grabs it), so taps, scrolling and gestures are untouched
- Moves the cursor through a separate virtual mouse ("Touchpad Edge Motion (virtual)")
- Starts only when the finger slides into the edge from the middle, so resting palms are ignored
- Disabled whenever 2 or more fingers are down
- If it stops or crashes, the touchpad works normally

Install: `sudo ./install-edge-motion.sh` (installs `python3-evdev` and a systemd service)

Tune: edit `EDGE_FRACTION` (edge width), `SPEED` / `MIN_SPEED` (cursor speed) at the top of
`touchpad-edge-motion`, then re-run the installer.

Remove:
```bash
sudo systemctl disable --now touchpad-edge-motion
sudo rm /usr/local/bin/touchpad-edge-motion /etc/systemd/system/touchpad-edge-motion.service
```

### drag-lock/
After tap-and-drag you can lift your finger without dropping the item; tap once to drop.

- `./enable-drag-lock.sh` turns it on, `./enable-drag-lock.sh off` turns it off (no sudo)

## Other touchpad settings in use
Set in System Settings → Touchpad:
- Tap to click, two-finger tap = right-click, three-finger tap = middle-click
- Two-finger scrolling, natural (inverted) scrolling
- Disable while typing
- Pointer speed 0.6
