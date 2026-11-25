import QtQuick
import Quickshell
import SekaiDesk

PanelWindow {
    id: m3NotifPopWin
    required property var m3Root

    property var toasts: []
    property int nextSeq: 1

    readonly property int targetW: 344
    readonly property int targetH: Math.max(84, toasts.length * 88)
    readonly property int targetX: Math.max(12, m3Root.sw - targetW - 14)
    readonly property int targetY: 46

    function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

    visible: !m3Root.fullscreenActive && toasts.length > 0 && !m3Root.sidebarOpen
    x: targetX; y: targetY; width: targetW; height: targetH
    blurBehind: false
    color: "transparent"

    Component.onCompleted: syncGeo()
    onTargetXChanged: syncGeo()
    onTargetHChanged: syncGeo()
    onVisibleChanged: if (visible) syncGeo()

    function dismissSeq(seq) {
        const next = []
        for (let i = 0; i < toasts.length; ++i) {
            if (toasts[i].seq !== seq) next.push(toasts[i])
        }
        toasts = next
    }

    Timer {
        interval: 1000
        repeat: true
        running: m3NotifPopWin.toasts.length > 0
        onTriggered: {
            const now = Date.now()
            const next = []
            for (let i = 0; i < m3NotifPopWin.toasts.length; ++i) {
                if (now - m3NotifPopWin.toasts[i].ts < 5200)
                    next.push(m3NotifPopWin.toasts[i])
            }
            if (next.length !== m3NotifPopWin.toasts.length)
                m3NotifPopWin.toasts = next
        }
    }

    Connections {
        target: NotificationService
        function onNewNotificationReceived(item) {
            if (!item) return
            const entry = {
                seq: m3NotifPopWin.nextSeq++,
                ts: Date.now(),
                app: item.app || item.appName || "Notification",
                title: item.title || "",
                body: item.body || ""
            }
            const next = [entry].concat(m3NotifPopWin.toasts).slice(0, 3)
            m3NotifPopWin.toasts = next
        }
    }

    Column {
        anchors.fill: parent
        spacing: 8

        Repeater {
            model: m3NotifPopWin.toasts
            delegate: Rectangle {
                required property var modelData
                width: parent.width; height: 78; radius: 22
                color: m3Root.colLayer1
                border.width: 1; border.color: m3Root.colLayer0Border

                Row {
                    anchors.fill: parent; anchors.margins: 12; spacing: 10
                    Rectangle {
                        width: 36; height: 36; radius: 18
                        anchors.verticalCenter: parent.verticalCenter
                        color: m3Root.colPrimaryContainer
                        Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "notifications" : "🔔"; color: m3Root.colPrimary }
                    }
                    Column {
                        width: parent.width - 74
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 2
                        Text { width: parent.width; elide: Text.ElideRight; text: modelData.app + (modelData.title !== "" ? (" · " + modelData.title) : ""); font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                        Text { width: parent.width; elide: Text.ElideRight; text: modelData.body || ""; font.family: "Segoe UI"; font.pixelSize: 11; color: m3Root.colOnLayer1 }
                    }
                    Rectangle {
                        width: 24; height: 24; radius: 12
                        anchors.verticalCenter: parent.verticalCenter
                        color: "transparent"
                        Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 14; text: m3Root.hasSymbols ? "close" : "✕"; color: m3Root.colOnLayer1 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: m3NotifPopWin.dismissSeq(modelData.seq) }
                    }
                }
            }
        }
    }
}
