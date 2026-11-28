import QtQuick
import Quickshell
import SekaiDesk

PanelWindow {
    id: m3DockMenuWin
    required property var m3Root

    readonly property var itemData: m3Root.dockMenuItem || ({})
    readonly property bool isRunning: !!itemData.running
    readonly property bool isPinned: !!itemData.pinned

    property real popK: m3Root.dockMenuOpen ? 1.0 : 0.0
    Behavior on popK {
        NumberAnimation {
            duration: m3Root.dockMenuOpen ? 220 : 150
            easing.type: Easing.BezierSpline
            easing.bezierCurve: m3Root.dockMenuOpen
                                ? [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                                : [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]
        }
    }

    visible: m3Root.dockMenuOpen || popK > 0.01
    readonly property int targetW: 236
    readonly property int targetH: isRunning ? 268 : 186
    readonly property int targetX: Math.max(12, Math.min(m3Root.sw - targetW - 12, m3Root.dockMenuAnchorX - Math.round(targetW * 0.5)))
    readonly property int targetY: Math.max(48, m3Root.sh - targetH - 88)

    function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

    x: targetX; y: targetY; width: targetW; height: targetH
    blurBehind: false
    color: "transparent"

    Timer {
        id: dmFocusTimer
        interval: 45
        repeat: false
        onTriggered: {
            if (m3Root.dockMenuOpen) {
                m3DockMenuWin.focusActivate()
                dmCard.forceActiveFocus()
                dmFocusRetryTimer.restart()
            }
        }
    }
    Timer {
        id: dmFocusRetryTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (m3Root.dockMenuOpen && !dmCard.activeFocus) {
                m3DockMenuWin.focusActivate()
                dmCard.forceActiveFocus()
            }
        }
    }

    Component.onCompleted: {
        syncGeo()
        if (m3Root.dockMenuOpen) {
            focusActivate()
            dmCard.forceActiveFocus()
            dmFocusTimer.restart()
        }
    }
    onTargetXChanged: syncGeo()
    onTargetYChanged: syncGeo()
    onTargetHChanged: syncGeo()
    onVisibleChanged: {
        if (visible) {
            syncGeo()
            if (m3Root.dockMenuOpen) {
                focusActivate()
                dmCard.forceActiveFocus()
                dmFocusTimer.restart()
            }
        } else {
            dmFocusTimer.stop()
            dmFocusRetryTimer.stop()
        }
    }
    onWindowDeactivated: {
        if (m3Root.dockMenuOpen) {
            m3Root.dockMenuClosedAt = Date.now()
            m3Root.dockMenuOpen = false
        }
    }

    Rectangle {
        id: dmCard
        focus: true
        x: 0
        y: Math.round((1.0 - m3DockMenuWin.popK) * 14)
        width: parent.width
        height: parent.height
        radius: 22
        color: m3Root.colLayer1
        border.width: 1
        border.color: m3Root.colLayer0Border
        opacity: m3DockMenuWin.popK
        scale: 0.92 + 0.08 * m3DockMenuWin.popK
        clip: true

        Keys.onEscapePressed: {
            m3Root.dockMenuClosedAt = Date.now()
            m3Root.dockMenuOpen = false
        }

        Column {
            anchors.fill: parent
            anchors.margins: 10
            spacing: 4

            // Header Row: App Icon + Name + Badge
            Item {
                width: parent.width; height: 40
                Row {
                    anchors.fill: parent; anchors.leftMargin: 6; anchors.rightMargin: 6; spacing: 10
                    Image {
                        width: 24; height: 24; anchors.verticalCenter: parent.verticalCenter
                        asynchronous: true; cache: true; smooth: true; mipmap: true
                        source: m3DockMenuWin.itemData.target ? ("image://winicon/" + encodeURIComponent(m3DockMenuWin.itemData.target)) : ""
                    }
                    Column {
                        width: parent.width - 36; anchors.verticalCenter: parent.verticalCenter; spacing: 0
                        Text { width: parent.width; elide: Text.ElideRight; text: m3DockMenuWin.itemData.name || "App"; font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                        Text {
                            text: (m3DockMenuWin.isPinned ? "Pinned" : "Unpinned") + (m3DockMenuWin.isRunning ? " • Running" : "")
                            font.family: "Segoe UI"; font.pixelSize: 10; color: m3Root.colPrimary
                        }
                    }
                }
            }

            Rectangle { width: parent.width; height: 1; color: m3Root.colLayer0Border }

            // Launch / New Window
            Rectangle {
                width: parent.width; height: 34; radius: 14
                color: dmLaunchMa.containsMouse ? m3Root.colPrimaryContainer : "transparent"
                Row {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                    Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 17; text: m3Root.hasSymbols ? "open_in_new" : "↗"; color: m3Root.colPrimary }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: m3DockMenuWin.isRunning ? "Open New Window" : "Launch"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold; color: m3Root.colOnLayer0 }
                }
                MouseArea {
                    id: dmLaunchMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const tgt = m3DockMenuWin.itemData.target || ""; const args = m3DockMenuWin.itemData.args || ""
                        Qt.callLater(() => {
                            m3Root.dockMenuClosedAt = Date.now()
                            m3Root.dockMenuOpen = false
                            if (tgt !== "") AppLauncher.launch(tgt, args)
                        })
                    }
                }
            }

            // Pin / Unpin
            Rectangle {
                width: parent.width; height: 34; radius: 14
                color: dmPinMa.containsMouse ? m3Root.colPrimaryContainer : "transparent"
                Row {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                    Text {
                        anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 17
                        text: m3Root.hasSymbols ? (m3DockMenuWin.isPinned ? "keep_off" : "keep") : "📌"
                        color: m3DockMenuWin.isPinned ? "#FFB4AB" : m3Root.colPrimary
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: m3DockMenuWin.isPinned ? "Remove from Taskbar" : "Pin to Taskbar"
                        font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                        color: m3Root.colOnLayer0
                    }
                }
                MouseArea {
                    id: dmPinMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const tgt = m3DockMenuWin.itemData.target || ""
                        const nm = m3DockMenuWin.itemData.name || tgt
                        const ar = m3DockMenuWin.itemData.args || ""
                        const wasPinned = m3DockMenuWin.isPinned
                        Qt.callLater(() => {
                            m3Root.dockMenuClosedAt = Date.now()
                            m3Root.dockMenuOpen = false
                            if (tgt === "") return
                            if (wasPinned) AppLauncher.removePinnedByTarget(tgt)
                            else AppLauncher.addPinnedApp(nm, tgt, ar)
                        })
                    }
                }
            }

            // Open File Location
            Rectangle {
                width: parent.width; height: 34; radius: 14
                color: dmLocMa.containsMouse ? m3Root.colPrimaryContainer : "transparent"
                Row {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                    Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 17; text: m3Root.hasSymbols ? "folder_open" : "📁"; color: m3Root.colOnLayer1 }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Open File Location"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold; color: m3Root.colOnLayer0 }
                }
                MouseArea {
                    id: dmLocMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const tgt = m3DockMenuWin.itemData.target || ""
                        Qt.callLater(() => {
                            m3Root.dockMenuClosedAt = Date.now()
                            m3Root.dockMenuOpen = false
                            if (tgt !== "") AppLauncher.revealInExplorer(tgt)
                        })
                    }
                }
            }

            Rectangle { visible: m3DockMenuWin.isRunning; width: parent.width; height: 1; color: m3Root.colLayer0Border }

            // Minimize
            Rectangle {
                visible: m3DockMenuWin.isRunning
                width: parent.width; height: 34; radius: 14
                color: dmMinMa.containsMouse ? m3Root.colPrimaryContainer : "transparent"
                Row {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                    Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 17; text: m3Root.hasSymbols ? "minimize" : "—"; color: m3Root.colOnLayer1 }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Minimize"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold; color: m3Root.colOnLayer0 }
                }
                MouseArea {
                    id: dmMinMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const tgt = m3DockMenuWin.itemData.target || ""
                        Qt.callLater(() => {
                            m3Root.dockMenuClosedAt = Date.now()
                            m3Root.dockMenuOpen = false
                            const wins = WindowTracker.windowsForTarget(tgt) || []
                            for (let i = 0; i < wins.length; ++i)
                                WindowTracker.minimizeHwnd(wins[i].hwnd)
                        })
                    }
                }
            }

            // Close Window
            Rectangle {
                visible: m3DockMenuWin.isRunning
                width: parent.width; height: 34; radius: 14
                color: dmClsMa.containsMouse ? "#93000A" : "transparent"
                Row {
                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 10
                    Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 17; text: m3Root.hasSymbols ? "close" : "✕"; color: dmClsMa.containsMouse ? "#FFDAD6" : "#FFB4AB" }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Close Window"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold; color: dmClsMa.containsMouse ? "#FFDAD6" : "#FFB4AB" }
                }
                MouseArea {
                    id: dmClsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                    onClicked: {
                        const tgt = m3DockMenuWin.itemData.target || ""
                        Qt.callLater(() => {
                            m3Root.dockMenuClosedAt = Date.now()
                            m3Root.dockMenuOpen = false
                            const wins = WindowTracker.windowsForTarget(tgt) || []
                            for (let i = 0; i < wins.length; ++i)
                                WindowTracker.closeHwnd(wins[i].hwnd)
                        })
                    }
                }
            }
        }
    }
}
