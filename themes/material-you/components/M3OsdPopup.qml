import QtQuick
import Quickshell
import SekaiDesk

PanelWindow {
    id: m3OsdWin
    required property var m3Root

    property bool osdVisible: false
    property string osdKind: "volume"
    property int osdValue: 0
    property bool osdMuted: false

    readonly property int targetW: 268
    readonly property int targetH: 56
    readonly property int targetX: Math.round((m3Root.sw - targetW) * 0.5)
    readonly property int targetY: m3Root.sh - 134

    function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

    visible: !m3Root.fullscreenActive && osdVisible
    clickThrough: true
    x: targetX; y: targetY; width: targetW; height: targetH
    blurBehind: false
    color: "transparent"

    Component.onCompleted: syncGeo()
    onTargetXChanged: syncGeo()
    onTargetYChanged: syncGeo()
    onVisibleChanged: if (visible) syncGeo()

    Timer {
        id: osdHideTimer
        interval: 1600
        repeat: false
        onTriggered: m3OsdWin.osdVisible = false
    }

    Connections {
        target: AudioService
        function onOsdRequested(kind, value, muted) {
            m3OsdWin.osdKind = kind || "volume"
            m3OsdWin.osdValue = Math.max(0, Math.min(100, Math.round(Number(value) || 0)))
            m3OsdWin.osdMuted = !!muted
            m3OsdWin.osdVisible = true
            osdHideTimer.restart()
        }
    }

    Rectangle {
        anchors.fill: parent
        radius: 28
        color: m3Root.colLayer1
        border.width: 1; border.color: m3Root.colLayer0Border

        Row {
            anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 10

            Rectangle {
                width: 34; height: 34; radius: 17
                anchors.verticalCenter: parent.verticalCenter
                color: m3OsdWin.osdMuted ? "#93000A" : m3Root.colPrimaryContainer
                Text {
                    anchors.centerIn: parent
                    font.family: m3Root.iconFontName; font.pixelSize: 18
                    text: {
                        if (!m3Root.hasSymbols)
                            return m3OsdWin.osdKind === "mic" ? "🎙" : (m3OsdWin.osdKind === "brightness" ? "☀" : "🔊")
                        if (m3OsdWin.osdKind === "mic")
                            return m3OsdWin.osdMuted ? "mic_off" : "mic"
                        if (m3OsdWin.osdKind === "brightness")
                            return "light_mode"
                        return m3OsdWin.osdMuted ? "volume_off" : "volume_up"
                    }
                    color: m3OsdWin.osdMuted ? "#FFDAD6" : m3Root.colPrimary
                }
            }

            Rectangle {
                width: parent.width - 84
                height: 10; radius: 5
                anchors.verticalCenter: parent.verticalCenter
                color: m3Root.colSurfaceVariant

                Rectangle {
                    width: Math.max(10, parent.width * ((m3OsdWin.osdMuted ? 0 : m3OsdWin.osdValue) / 100.0))
                    height: parent.height; radius: 5
                    color: m3OsdWin.osdMuted ? "#FFB4AB" : m3Root.colPrimary
                    Behavior on width { NumberAnimation { duration: 90; easing.type: Easing.OutCubic } }
                }
            }

            Text {
                width: 30; horizontalAlignment: Text.AlignRight
                anchors.verticalCenter: parent.verticalCenter
                text: m3OsdWin.osdMuted ? "Mute" : (m3OsdWin.osdValue + "%")
                font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold
                color: m3Root.colOnLayer0
            }
        }
    }
}
