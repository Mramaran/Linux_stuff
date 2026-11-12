// Frosted-glass background for the Fokus widget on the desktop (Layan look).
// Same style as the Glass System Pill: blurred wallpaper, dark tint, light edge, top sheen, soft shadow.
// Installed into Fokus by fokus-patch.sh.
import QtQuick
import QtQuick.Effects

Item {
    id: glassRoot
    property real radius: 22

    property Item wallpaper: null
    property url wallpaperUrl: ""
    property real offX: 0
    property real offY: 0
    property real wpW: 1920
    property real wpH: 1080

    function findWallpaper() {
        var p = glassRoot.parent;
        while (p) {
            if (p.wallpaper !== undefined && p.wallpaper && p.wallpaper.width !== undefined) return p.wallpaper;
            p = p.parent;
        }
        return null;
    }
    function update() {
        if (!wallpaper) wallpaper = findWallpaper();
        if (!wallpaper) return;
        var img = wallpaper.configuration ? wallpaper.configuration.Image : "";
        if (img && String(img) !== String(wallpaperUrl)) wallpaperUrl = img;
        var p = glass.mapToItem(wallpaper, 0, 0);
        offX = p.x; offY = p.y;
        wpW = wallpaper.width; wpH = wallpaper.height;
    }
    Component.onCompleted: update()
    Timer { interval: 500; running: glassRoot.visible; repeat: true; onTriggered: glassRoot.update() }

    RectangularShadow {
        anchors.fill: glass
        radius: glass.radius
        blur: 26
        offset.y: 6
        color: Qt.rgba(0, 0, 0, 0.35)
    }

    Item {
        id: glass
        anchors.fill: parent
        readonly property real radius: glassRoot.radius
        readonly property real bleed: 40

        Item {
            id: frost
            anchors.fill: parent
            anchors.margins: -glass.bleed
            visible: false
            clip: true
            Image {
                x: -(glassRoot.offX - glass.bleed)
                y: -(glassRoot.offY - glass.bleed)
                width: glassRoot.wpW
                height: glassRoot.wpH
                source: glassRoot.wallpaperUrl
                fillMode: Image.PreserveAspectCrop
                sourceSize: Qt.size(glassRoot.wpW / 2, glassRoot.wpH / 2)
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
            visible: glassRoot.wallpaperUrl != ""
            source: frostedTex
            maskEnabled: true
            maskSource: maskRect
            maskThresholdMin: 0.5
            maskSpreadAtMin: 1.0
        }
        Rectangle {
            anchors.fill: parent
            radius: glass.radius
            color: Qt.rgba(0.07, 0.07, 0.13, glassRoot.wallpaperUrl != "" ? 0.32 : 0.62)
            border.width: 1
            border.color: Qt.rgba(1, 1, 1, 0.18)
        }
        Rectangle {
            anchors.fill: parent
            anchors.margins: 1
            radius: glass.radius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.rgba(1, 1, 1, 0.12) }
                GradientStop { position: 0.30; color: Qt.rgba(1, 1, 1, 0.03) }
                GradientStop { position: 1.0; color: Qt.rgba(1, 1, 1, 0.0) }
            }
        }
    }
}
