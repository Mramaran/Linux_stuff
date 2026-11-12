#!/usr/bin/env bash
# Patches the Fokus pomodoro widget (com.dv.fokus) for focus-music:
#   1. pause hook      - pausing the timer runs a "pause" script (Fokus has none of its own)
#   2. music menu      - right-click: Focus music on/off, Calm / Lo-fi / Mix, music folder, volume
#   3. glass look      - frosted-glass background on the desktop, matching the Layan theme
# Safe to run again: an already-patched Fokus is rebuilt from its saved originals (*.orig);
# a fresh or updated Fokus has its files saved as the new originals first.
# Afterwards restart Plasma:  systemctl --user restart plasma-plasmashell
set -e
cd "$(dirname "$0")"
D="${XDG_DATA_HOME:-$HOME/.local/share}/plasma/plasmoids/com.dv.fokus/contents"
QML="$D/ui/main.qml"
XML="$D/config/main.xml"
[ -f "$QML" ] && [ -f "$XML" ] || { echo "Fokus widget not installed at $D"; exit 1; }

if grep -q "linux_stuff:\|pause_script_enabled" "$QML"; then
    [ -f "$QML.orig" ] && [ -f "$XML.orig" ] || { echo "Patched Fokus without saved originals; reinstall Fokus first."; exit 1; }
    cp "$QML.orig" "$QML"; cp "$XML.orig" "$XML"          # start again from the originals
else
    cp "$QML" "$QML.orig"; cp "$XML" "$XML.orig"          # fresh/updated Fokus: save originals
fi
install -m 644 fokus/FokusGlass.qml "$D/ui/FokusGlass.qml"

python3 -I - "$QML" "$XML" <<'PY'
import sys
qml_path, xml_path = sys.argv[1], sys.argv[2]
qml = open(qml_path, encoding="utf-8-sig").read()
xml = open(xml_path).read()
done = []

def patch(text, old, new, what):
    if text.count(old) != 1:
        sys.exit(f"Could not find the spot for '{what}'; Fokus may have changed. Nothing was written.")
    return text.replace(old, new)

# ---- 1. pause hook ---------------------------------------------------------
if "pause_script_enabled" not in qml:
    qml = patch(qml,
        "    function pause() {\n        doNotDisturbDisable();\n        timer.stop();\n",
        "    function pause() {\n        doNotDisturbDisable();\n        timer.stop();\n        executeScript(3);\n",
        "pause()")
    qml = patch(qml,
        "    function executeScript(state) {\n        switch (state) {\n",
        "    function executeScript(state) {\n        switch (state) {\n"
        "        case 3:\n"
        "            if (plasmoid.configuration.pause_script_enabled)\n"
        "                executable.exec([\"sh\", plasmoid.configuration.pause_script_filepath]);\n"
        "            break;\n",
        "executeScript()")
    done.append("pause hook")
if "pause_script_enabled" not in xml:
    anchor = '        <entry name="stop_script_filepath" type="String">'
    xml = patch(xml, anchor,
        '        <entry name="pause_script_filepath" type="String">\n'
        '            <default></default>\n'
        '        </entry>\n'
        '        <entry name="pause_script_enabled" type="Bool">\n'
        '            <default>false</default>\n'
        '        </entry>\n\n' + anchor,
        "config entries")

# ---- 2. music menu ---------------------------------------------------------
if "[linux_stuff:music-menu]" not in qml:
    qml = patch(qml,
        "    property ExecUtil executable\n",
        "    property ExecUtil executable\n"
        "\n"
        "    // [linux_stuff:music-menu] focus-music settings shown in the right-click menu\n"
        "    property string musicMode: \"calm\"\n"
        "    property int musicVolume: 35\n"
        "    property bool musicEnabled: true\n"
        "    function musicExec(args) {\n"
        "        executable.exec([\"sh\", \"-c\", \"\\\"$HOME/.local/bin/focus-music\\\" \" + args + \" >/dev/null 2>&1; \\\"$HOME/.local/bin/focus-music\\\" get\"],\n"
        "            function(cmd, exitCode, exitStatus, stdout) { musicParse(stdout); });\n"
        "    }\n"
        "    function musicParse(out) {\n"
        "        var f = String(out).trim().split(/\\s+/);\n"
        "        if (f.length >= 3) { musicMode = f[0]; musicVolume = parseInt(f[1]); musicEnabled = f[2] === \"1\"; }\n"
        "    }\n"
        "    function musicSetMode(m) { musicMode = m; musicExec(\"mode \" + m); }\n"
        "    function musicSetVolume(v) { musicVolume = v; musicExec(\"volume \" + v); }\n"
        "    function musicSetEnabled(on) {\n"
        "        musicEnabled = on;\n"
        "        // Turning it on during a running focus session starts the music right away.\n"
        "        musicExec(on ? ((timer.running && !isBreak()) ? \"enable; \\\"$HOME/.local/bin/focus-music\\\" start\" : \"enable\") : \"disable\");\n"
        "    }\n"
        "    Timer { interval: 1500; running: true; onTriggered: root.musicExec(\"status\") }\n",
        "music properties")
    anchor = ("            visible: !flowmodoroModeEnabled && currentPreset >= TimerLogic.presetCount()\n"
              "        }\n"
              "    ]\n")
    def act(text, extra):
        return "        PlasmaCore.Action {\n" + "".join("            " + l + "\n" for l in [f"text: {text}"] + extra) + "        },\n"
    def mode(text, key, icon):
        return act(f'i18n("{text}")', [f'icon.name: "{icon}"', "checkable: true",
                   f'checked: root.musicMode === "{key}"', "enabled: root.musicEnabled",
                   f'onTriggered: root.musicSetMode("{key}")'])
    def vol(text, v, icon):
        return act(f'i18n("{text}")', [f'icon.name: "{icon}"', "checkable: true",
                   f"checked: root.musicVolume === {v}", "enabled: root.musicEnabled",
                   f"onTriggered: root.musicSetVolume({v})"])
    menu = ("        },\n"
            "        // [linux_stuff:music-menu] actions\n"
            "        PlasmaCore.Action {\n            isSeparator: true\n        },\n"
            + act('i18n("Focus music")', ['icon.name: "media-album-cover"', "checkable: true",
                  "checked: root.musicEnabled", "onTriggered: root.musicSetEnabled(!root.musicEnabled)"])
            + mode("Calm piano & ambient", "calm", "weather-few-clouds-night")
            + mode("Lo-fi beats", "lofi", "audio-headphones")
            + mode("Mix (both)", "mix", "media-playlist-shuffle")
            + act('i18n("Open music folder…")', ['icon.name: "folder-music"',
                  'onTriggered: executable.exec(["sh", "-c", "mkdir -p \\"$HOME/Music/Focus\\" && xdg-open \\"$HOME/Music/Focus\\""])'])
            + "        PlasmaCore.Action {\n            isSeparator: true\n        },\n"
            + vol("Volume: Low", 20, "audio-volume-low")
            + vol("Volume: Medium", 35, "audio-volume-medium")
            + vol("Volume: High", 55, "audio-volume-high"))
    menu = menu.rstrip(",\n") + "\n    ]\n"
    qml = patch(qml, anchor,
        "            visible: !flowmodoroModeEnabled && currentPreset >= TimerLogic.presetCount()\n" + menu,
        "right-click menu")
    done.append("music menu")

# ---- 3. glass look ---------------------------------------------------------
if "[linux_stuff:glass]" not in qml:
    qml = patch(qml,
        "    Plasmoid.backgroundHints: PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground\n",
        "    // [linux_stuff:glass] own frosted background on the desktop, theme background in panels\n"
        "    Plasmoid.backgroundHints: Plasmoid.formFactor === PlasmaCore.Types.Planar\n"
        "        ? PlasmaCore.Types.NoBackground\n"
        "        : (PlasmaCore.Types.DefaultBackground | PlasmaCore.Types.ConfigurableBackground)\n",
        "backgroundHints")
    qml = patch(qml,
        "    fullRepresentation: Item {\n        id: fullRoot\n",
        "    fullRepresentation: Item {\n        id: fullRoot\n\n"
        "        FokusGlass {   // [linux_stuff:glass]\n"
        "            anchors.fill: parent\n"
        "            anchors.margins: -Kirigami.Units.largeSpacing\n"
        "            z: -1\n"
        "            visible: Plasmoid.formFactor === PlasmaCore.Types.Planar\n"
        "        }\n",
        "glass background")
    done.append("glass look")

open(qml_path, "w", encoding="utf-8").write(qml)
open(xml_path, "w").write(xml)
print("Applied: " + (", ".join(done) if done else "nothing (already patched)"))
PY
