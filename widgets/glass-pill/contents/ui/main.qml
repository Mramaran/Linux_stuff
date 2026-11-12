/*
 * Glass System Pill — compact system monitor for KDE Plasma 6 (Layan palette).
 *
 *  - On the desktop: frosted-glass pill with CPU / GPU / RAM / Temp rings.
 *  - In a vertical panel: tall column with rings, details, spinning fans and network.
 *    (The panel itself provides the blurred glass background.)
 * Hover any item for details.
 */
import QtQuick
import QtQuick.Layouts
import QtQuick.Shapes
import QtQuick.Effects
import QtQuick.Controls as QQC2
import org.kde.plasma.plasmoid
import org.kde.plasma.core as PlasmaCore
import org.kde.ksysguard.sensors as Sensors

PlasmoidItem {
    id: root

    Plasmoid.backgroundHints: PlasmaCore.Types.NoBackground
    preferredRepresentation: fullRepresentation

    readonly property bool vertical: Plasmoid.formFactor === PlasmaCore.Types.Vertical

    // ---- palette (Layan) ------------------------------------------------
    readonly property color cBlue:   "#4285f4"
    readonly property color cViolet: "#8657f5"
    readonly property color cPink:   "#ff80e0"
    readonly property color cCyan:   "#4fb6e0"
    readonly property color cGreen:  "#80e6a0"
    readonly property color cAmber:  "#ffbe5a"
    readonly property color cRed:    "#ff5a6e"
    readonly property color cDim:    Qt.rgba(1, 1, 1, 0.62)

    // ---- sensors ----------------------------------------------------------
    Sensors.Sensor { id: cpuUse;   sensorId: "cpu/all/usage";                updateRateLimit: 1000 }
    Sensors.Sensor { id: cpuTemp;  sensorId: "cpu/all/averageTemperature";   updateRateLimit: 1000 }
    Sensors.Sensor { id: cpuFreq;  sensorId: "cpu/all/averageFrequency";     updateRateLimit: 2000 }
    Sensors.Sensor { id: gpuUse;   sensorId: "gpu/gpu1/usage";               updateRateLimit: 1000 }
    Sensors.Sensor { id: gpuTemp;  sensorId: "gpu/gpu1/temperature";         updateRateLimit: 1000 }
    Sensors.Sensor { id: gpuPower; sensorId: "gpu/gpu1/power";               updateRateLimit: 2000 }
    Sensors.Sensor { id: memPct;   sensorId: "memory/physical/usedPercent";  updateRateLimit: 1000 }
    Sensors.Sensor { id: memUsed;  sensorId: "memory/physical/used";         updateRateLimit: 2000 }
    Sensors.Sensor { id: memTotal; sensorId: "memory/physical/total";        updateRateLimit: 10000 }
    Sensors.Sensor { id: fanCpu;   sensorId: "lmsensors/asus-isa-000a/fan1"; updateRateLimit: 2000 }
    Sensors.Sensor { id: fanGpu;   sensorId: "lmsensors/asus-isa-000a/fan2"; updateRateLimit: 2000 }
    Sensors.Sensor { id: netDown;  sensorId: "network/all/download";         updateRateLimit: 1000 }
    Sensors.Sensor { id: netUp;    sensorId: "network/all/upload";           updateRateLimit: 1000 }

    function num(s) { var v = Number(s.value); return isNaN(v) ? 0 : v; }
    function hotColor(t) { return t >= 85 ? cRed : (t >= 72 ? cAmber : cCyan); }
    readonly property real maxTemp: Math.max(num(cpuTemp), num(gpuTemp))

    // short formats for the narrow panel
    function shortRate(bytes) {               // bytes/s -> "340K", "1.2M"
        if (bytes >= 1048576) return (bytes / 1048576).toFixed(bytes >= 10485760 ? 0 : 1) + "M";
        if (bytes >= 1024) return Math.round(bytes / 1024) + "K";
        return Math.round(bytes) + "B";
    }
    function shortRpm(r) { return r >= 1000 ? (r / 1000).toFixed(1) + "k" : Math.round(r); }
    function shortGiB(b) { return (b / 1073741824).toFixed(1) + "G"; }
    function shortGHz(mhz) { return (mhz / 1000).toFixed(1) + "G"; }

    readonly property string cpuDetail: "CPU  " + cpuUse.formattedValue + "\nClock  " + cpuFreq.formattedValue
                                        + "\nTemp  " + cpuTemp.formattedValue + "\nFan  " + fanCpu.formattedValue
    readonly property string gpuDetail: "RTX 4060  " + gpuUse.formattedValue + "\nPower  " + gpuPower.formattedValue
                                        + "\nTemp  " + gpuTemp.formattedValue + "\nFan  " + fanGpu.formattedValue
    readonly property string memDetail: "Memory  " + memUsed.formattedValue + " / " + memTotal.formattedValue
    readonly property string tempDetail: "CPU  " + cpuTemp.formattedValue + "\nGPU  " + gpuTemp.formattedValue

    // ---- reusable pieces ----------------------------------------------------
    component Dial: Item {
        id: dial
        property real fraction: 0
        property color accent: "white"
        property string valueText: ""
        readonly property real stroke: Math.max(3, width * 0.09)
        property real shown: fraction
        Behavior on shown { NumberAnimation { duration: 700; easing.type: Easing.OutCubic } }

        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                strokeColor: Qt.rgba(1, 1, 1, 0.12)
                strokeWidth: dial.stroke
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: dial.width / 2; centerY: dial.height / 2
                    radiusX: (dial.width - dial.stroke) / 2; radiusY: radiusX
                    startAngle: -90; sweepAngle: 360
                }
            }
        }
        Shape {
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            layer.enabled: true
            layer.effect: MultiEffect {
                shadowEnabled: true
                shadowColor: dial.accent
                shadowBlur: 0.6
                shadowOpacity: 0.65
                shadowHorizontalOffset: 0
                shadowVerticalOffset: 0
            }
            ShapePath {
                strokeColor: dial.accent
                strokeWidth: dial.stroke
                fillColor: "transparent"
                capStyle: ShapePath.RoundCap
                PathAngleArc {
                    centerX: dial.width / 2; centerY: dial.height / 2
                    radiusX: (dial.width - dial.stroke) / 2; radiusY: radiusX
                    startAngle: -90
                    sweepAngle: Math.max(0.5, Math.min(1, dial.shown) * 360)
                }
            }
        }
        Text {
            anchors.centerIn: parent
            text: dial.valueText
            color: "white"
            font.pixelSize: Math.round(dial.width * 0.28)
            font.weight: Font.DemiBold
        }
    }

    // 3-blade fan that spins faster with higher RPM
    component Fan: Item {
        id: fan
        property real rpm: 0
        property color accent: root.cCyan
        function pt(c, rad, ang) {
            return (c + rad * Math.cos(ang)).toFixed(2) + " " + (c + rad * Math.sin(ang)).toFixed(2);
        }
        function bladePath() {
            var c = width / 2, r = width * 0.46, out = "";
            for (var i = 0; i < 3; ++i) {
                var a = i * 2 * Math.PI / 3;
                out += "M " + pt(c, r * 0.18, a) + " Q " + pt(c, r * 0.95, a - 0.35) + " " + pt(c, r, a + 0.55)
                     + " Q " + pt(c, r * 0.55, a + 0.75) + " " + pt(c, r * 0.18, a + 0.9) + " Z ";
            }
            return out;
        }
        Shape {
            id: blades
            anchors.fill: parent
            preferredRendererType: Shape.CurveRenderer
            ShapePath {
                fillColor: fan.accent
                strokeColor: "transparent"
                // three curved blades around the centre
                PathSvg { path: fan.bladePath() }
            }
            RotationAnimator on rotation {
                from: 0; to: 360
                loops: Animation.Infinite
                // ~2000 RPM -> one turn every ~1.2 s (slowed down so it is visible, not a blur)
                duration: fan.rpm > 0 ? Math.max(350, 2400000 / fan.rpm) : 100000
                running: fan.rpm > 0 && fan.visible
            }
        }
        Rectangle {
            anchors.centerIn: parent
            width: fan.width * 0.2; height: width; radius: width / 2
            color: Qt.rgba(1, 1, 1, 0.85)
        }
    }

    // ---- desktop pill -------------------------------------------------------
    component Ring: Item {
        id: ring
        property real fraction: 0
        property color accent: "white"
        property string valueText: ""
        property string label: ""
        property string detail: ""
        Layout.fillHeight: true
        Layout.preferredWidth: height * 0.82
        readonly property real d: Math.min(width, height - labelText.height - 2)

        Dial {
            id: dialItem
            width: ring.d; height: ring.d
            anchors.horizontalCenter: parent.horizontalCenter
            anchors.top: parent.top
            fraction: ring.fraction; accent: ring.accent; valueText: ring.valueText
        }
        Text {
            id: labelText
            anchors.top: dialItem.bottom
            anchors.topMargin: 2
            anchors.horizontalCenter: parent.horizontalCenter
            text: ring.label
            color: root.cDim
            font.pixelSize: Math.max(9, Math.round(ring.d * 0.17))
            font.letterSpacing: 1
            font.capitalization: Font.AllUppercase
        }
        HoverHandler { id: hover }
        QQC2.ToolTip { visible: hover.hovered && ring.detail.length > 0; delay: 250; text: ring.detail }
    }

    component PillView: Item {
        id: pill
        property Item wallpaper: null
        property url wallpaperUrl: ""
        property real offX: 0
        property real offY: 0
        property real wpW: 1920
        property real wpH: 1080
        function findWallpaper() {
            var p = pill.parent;
            while (p) {
                if (p.wallpaper !== undefined && p.wallpaper && p.wallpaper.width !== undefined) return p.wallpaper;
                p = p.parent;
            }
            return null;
        }
        function updateBlurRect() {
            if (!wallpaper) wallpaper = findWallpaper();
            if (!wallpaper) return;
            var img = wallpaper.configuration ? wallpaper.configuration.Image : "";
            if (img && String(img) !== String(wallpaperUrl)) wallpaperUrl = img;
            var p = glass.mapToItem(wallpaper, 0, 0);
            offX = p.x; offY = p.y;
            wpW = wallpaper.width; wpH = wallpaper.height;
        }
        Component.onCompleted: updateBlurRect()
        Timer { interval: 500; running: true; repeat: true; onTriggered: pill.updateBlurRect() }

        RectangularShadow {
            anchors.fill: glass
            radius: glass.radius
            blur: 22
            offset.y: 5
            color: Qt.rgba(0, 0, 0, 0.35)
        }

        Item {
            id: glass
            anchors.fill: parent
            anchors.margins: 8
            readonly property real radius: height / 2
            readonly property real bleed: 40

            Item {
                id: frost
                anchors.fill: parent
                anchors.margins: -glass.bleed
                visible: false
                clip: true
                Image {
                    x: -(pill.offX - glass.bleed)
                    y: -(pill.offY - glass.bleed)
                    width: pill.wpW
                    height: pill.wpH
                    source: pill.wallpaperUrl
                    fillMode: Image.PreserveAspectCrop
                    sourceSize: Qt.size(pill.wpW / 2, pill.wpH / 2)
                    asynchronous: true
                }
            }
            MultiEffect {
                id: frosted
                anchors.fill: frost
                source: frost
                visible: false
                blurEnabled: true
                blur: 1.0
                blurMax: 56
                saturation: 0.2
                brightness: -0.03
            }
            ShaderEffectSource {
                id: frostedTex
                sourceItem: frosted
                sourceRect: Qt.rect(glass.bleed, glass.bleed, glass.width, glass.height)
                visible: false
            }
            Rectangle {
                id: maskRect
                anchors.fill: parent
                radius: glass.radius
                color: "white"
                visible: false
                layer.enabled: true
            }
            MultiEffect {
                anchors.fill: parent
                visible: pill.wallpaperUrl != ""
                source: frostedTex
                maskEnabled: true
                maskSource: maskRect
                maskThresholdMin: 0.5
                maskSpreadAtMin: 1.0
            }
            Rectangle {
                anchors.fill: parent
                radius: glass.radius
                color: Qt.rgba(0.07, 0.07, 0.13, pill.wallpaperUrl != "" ? 0.30 : 0.62)
                border.width: 1
                border.color: Qt.rgba(1, 1, 1, 0.18)
            }
            Rectangle {
                anchors.fill: parent
                anchors.margins: 1
                radius: glass.radius
                gradient: Gradient {
                    GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.13) }
                    GradientStop { position: 0.45; color: Qt.rgba(1, 1, 1, 0.03) }
                    GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
                }
            }

            RowLayout {
                anchors.fill: parent
                anchors.leftMargin: glass.radius * 0.55
                anchors.rightMargin: glass.radius * 0.55
                anchors.topMargin: glass.height * 0.12
                anchors.bottomMargin: glass.height * 0.08
                spacing: 0
                Ring { label: "CPU"; accent: root.cBlue; fraction: root.num(cpuUse) / 100
                       valueText: Math.round(root.num(cpuUse)); detail: root.cpuDetail }
                Item { Layout.fillWidth: true }
                Ring { label: "GPU"; accent: root.cViolet; fraction: root.num(gpuUse) / 100
                       valueText: Math.round(root.num(gpuUse)); detail: root.gpuDetail }
                Item { Layout.fillWidth: true }
                Ring { label: "RAM"; accent: root.cPink; fraction: root.num(memPct) / 100
                       valueText: Math.round(root.num(memPct)); detail: root.memDetail }
                Item { Layout.fillWidth: true }
                Ring { label: "Temp"; accent: root.hotColor(root.maxTemp)
                       fraction: Math.max(0, (root.maxTemp - 30) / 70)
                       valueText: Math.round(root.maxTemp) + "°"; detail: root.tempDetail }
            }
        }
    }

    // ---- vertical panel column -----------------------------------------------
    component Section: ColumnLayout {
        id: sec
        property string label: ""
        property string detail: ""
        spacing: 3
        Layout.fillWidth: true
        HoverHandler { id: secHover }
        QQC2.ToolTip { visible: secHover.hovered && sec.detail.length > 0; delay: 250; text: sec.detail }
    }
    component Caption: Text {
        Layout.alignment: Qt.AlignHCenter
        color: root.cDim
        font.pixelSize: 10
        font.letterSpacing: 0.5
    }
    component Divider: Rectangle {
        Layout.alignment: Qt.AlignHCenter
        Layout.preferredWidth: 26
        Layout.preferredHeight: 1
        Layout.topMargin: 4
        Layout.bottomMargin: 4
        color: Qt.rgba(1, 1, 1, 0.14)
    }

    component PanelView: ColumnLayout {
        id: col
        spacing: 2
        readonly property real dialSize: Math.min(width - 14, 46)

        Item { Layout.preferredHeight: 6 }

        Section {
            detail: root.cpuDetail
            Caption { text: "CPU"; font.capitalization: Font.AllUppercase; font.letterSpacing: 1.2 }
            Dial { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: col.dialSize; Layout.preferredHeight: col.dialSize
                   accent: root.cBlue; fraction: root.num(cpuUse) / 100; valueText: Math.round(root.num(cpuUse)) }
            Caption { text: root.shortGHz(root.num(cpuFreq)) + "Hz" }
        }
        Divider {}
        Section {
            detail: root.gpuDetail
            Caption { text: "GPU"; font.capitalization: Font.AllUppercase; font.letterSpacing: 1.2 }
            Dial { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: col.dialSize; Layout.preferredHeight: col.dialSize
                   accent: root.cViolet; fraction: root.num(gpuUse) / 100; valueText: Math.round(root.num(gpuUse)) }
            Caption { text: Math.round(root.num(gpuPower)) + " W" }
        }
        Divider {}
        Section {
            detail: root.memDetail
            Caption { text: "RAM"; font.capitalization: Font.AllUppercase; font.letterSpacing: 1.2 }
            Dial { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: col.dialSize; Layout.preferredHeight: col.dialSize
                   accent: root.cPink; fraction: root.num(memPct) / 100; valueText: Math.round(root.num(memPct)) }
            Caption { text: root.shortGiB(root.num(memUsed)) }
        }
        Divider {}
        Section {
            detail: root.tempDetail
            Caption { text: "TEMP"; font.letterSpacing: 1.2 }
            Dial { Layout.alignment: Qt.AlignHCenter; Layout.preferredWidth: col.dialSize; Layout.preferredHeight: col.dialSize
                   accent: root.hotColor(root.maxTemp); fraction: Math.max(0, (root.maxTemp - 30) / 70)
                   valueText: Math.round(root.maxTemp) + "°" }
            Caption { text: Math.round(root.num(cpuTemp)) + "·" + Math.round(root.num(gpuTemp)) }
        }
        Divider {}
        Section {
            detail: "CPU fan  " + fanCpu.formattedValue + "\nGPU fan  " + fanGpu.formattedValue
            Caption { text: "FANS"; font.letterSpacing: 1.2 }
            RowLayout {
                Layout.alignment: Qt.AlignHCenter
                spacing: 6
                Fan { Layout.preferredWidth: 18; Layout.preferredHeight: 18; rpm: root.num(fanCpu); accent: root.cBlue }
                Fan { Layout.preferredWidth: 18; Layout.preferredHeight: 18; rpm: root.num(fanGpu); accent: root.cViolet }
            }
            Caption { text: root.shortRpm(Math.max(root.num(fanCpu), root.num(fanGpu))) }
        }
        Divider {}
        Section {
            detail: "Download  " + netDown.formattedValue + "\nUpload  " + netUp.formattedValue
            Caption { text: "NET"; font.letterSpacing: 1.2 }
            Text { Layout.alignment: Qt.AlignHCenter; text: "↓ " + root.shortRate(root.num(netDown))
                   color: root.cGreen; font.pixelSize: 11; font.weight: Font.DemiBold }
            Text { Layout.alignment: Qt.AlignHCenter; text: "↑ " + root.shortRate(root.num(netUp))
                   color: root.cAmber; font.pixelSize: 11; font.weight: Font.DemiBold }
        }

        Item { Layout.preferredHeight: 6 }
    }

    // ---- representation ------------------------------------------------------
    fullRepresentation: Item {
        id: full
        Layout.minimumWidth: root.vertical ? 48 : 240
        Layout.minimumHeight: root.vertical ? (loader.item ? loader.item.implicitHeight : 400) : 64
        Layout.preferredWidth: root.vertical ? 64 : 380
        Layout.preferredHeight: root.vertical ? (loader.item ? loader.item.implicitHeight : 400) : 96
        Layout.maximumHeight: root.vertical ? Layout.preferredHeight : -1

        Loader {
            id: loader
            anchors.fill: parent
            sourceComponent: root.vertical ? panelComp : pillComp
        }
        Component { id: pillComp; PillView {} }
        Component { id: panelComp; PanelView {} }
    }
}
