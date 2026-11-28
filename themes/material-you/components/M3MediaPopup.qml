import QtQuick
import QtQuick.Effects
import Quickshell
import SekaiDesk

PanelWindow {
    id: m3MediaPopupWin
    required property var m3Root

    visible: m3Root.mediaPopupOpen
    readonly property int targetW: 368
    readonly property int targetH: (MediaService.players || []).length > 1 ? 230 : 196
    readonly property int targetX: Math.max(12, m3Root.sw - targetW - 14)
    readonly property int targetY: 46

    function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

    function fmtSec(sec) {
        const s = Math.max(0, Math.floor(Number(sec) || 0))
        const m = Math.floor(s / 60)
        const r = s % 60
        return m + ":" + (r < 10 ? "0" : "") + r
    }

    x: targetX; y: targetY; width: targetW; height: targetH
    blurBehind: false
    color: "transparent"

    Timer {
        id: mediaFocusTimer
        interval: 45
        repeat: false
        onTriggered: {
            if (m3Root.mediaPopupOpen) {
                m3MediaPopupWin.focusActivate()
                mediaPopCard.forceActiveFocus()
                mediaFocusRetryTimer.restart()
            }
        }
    }
    Timer {
        id: mediaFocusRetryTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (m3Root.mediaPopupOpen && !mediaPopCard.activeFocus) {
                m3MediaPopupWin.focusActivate()
                mediaPopCard.forceActiveFocus()
            }
        }
    }

    Component.onCompleted: syncGeo()
    onTargetXChanged: syncGeo()
    onTargetYChanged: syncGeo()
    onTargetHChanged: syncGeo()
    onVisibleChanged: {
        if (visible) {
            syncGeo()
            focusActivate()
            mediaPopCard.forceActiveFocus()
            mediaFocusTimer.restart()
        } else {
            mediaFocusTimer.stop()
            mediaFocusRetryTimer.stop()
        }
    }
    onWindowDeactivated: {
        if (m3Root.mediaPopupOpen) {
            m3Root.mediaPopupClosedAt = Date.now()
            m3Root.mediaPopupOpen = false
        }
    }

    Rectangle {
        id: mediaPopCard
        focus: true
        anchors.fill: parent
        radius: 26
        color: m3Root.colLayer1
        border.width: 1; border.color: m3Root.colLayer0Border

        Keys.onEscapePressed: {
            m3Root.mediaPopupClosedAt = Date.now()
            m3Root.mediaPopupOpen = false
        }

        Column {
            anchors.fill: parent; anchors.margins: 16; spacing: 12

            Row {
                width: parent.width; spacing: 12

                Rectangle {
                    width: 82; height: 82; radius: 18
                    color: m3Root.colPrimaryContainer

                    Rectangle {
                        id: mpArtMask
                        anchors.fill: parent
                        radius: 18
                        visible: false
                        layer.enabled: true
                    }

                    Item {
                        anchors.fill: parent
                        visible: MediaService.artUrl !== ""
                        layer.enabled: visible
                        layer.effect: MultiEffect {
                            maskEnabled: true
                            maskSource: mpArtMask
                        }
                        Image {
                            anchors.fill: parent
                            source: MediaService.artUrl || ""
                            fillMode: Image.PreserveAspectCrop
                            asynchronous: true; cache: true; smooth: true
                        }
                    }

                    Text {
                        visible: MediaService.artUrl === ""
                        anchors.centerIn: parent
                        font.family: m3Root.iconFontName; font.pixelSize: 30
                        text: m3Root.hasSymbols ? "music_note" : "♪"
                        color: m3Root.colPrimary
                    }
                }

                Column {
                    width: parent.width - 94
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 3
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        text: (MediaService.hasSession && MediaService.title !== "") ? MediaService.title : "No Media Playing"
                        font.family: "Segoe UI"; font.pixelSize: 14; font.weight: Font.Bold; color: m3Root.colOnLayer0
                    }
                    Text {
                        width: parent.width; elide: Text.ElideRight
                        text: (MediaService.artist !== "") ? MediaService.artist : (MediaService.sourceApp || "Idle")
                        font.family: "Segoe UI"; font.pixelSize: 12; color: m3Root.colOnLayer1
                    }

                    Row {
                        spacing: 8; topPadding: 6
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: mpPrevMa.containsMouse ? m3Root.colPrimaryContainer : m3Root.colLayer2
                            Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 17; text: m3Root.hasSymbols ? "skip_previous" : "⏮"; color: m3Root.colOnLayer0 }
                            MouseArea { id: mpPrevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => MediaService.previous()) }
                        }
                        Rectangle {
                            width: 46; height: 34
                            radius: MediaService.isPlaying ? 12 : 17
                            Behavior on radius { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }
                            color: m3Root.colPrimary
                            Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 20; text: m3Root.hasSymbols ? (MediaService.isPlaying ? "pause" : "play_arrow") : (MediaService.isPlaying ? "⏸" : "▶"); color: m3Root.colOnPrimary }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => MediaService.playPause()) }
                        }
                        Rectangle {
                            width: 32; height: 32; radius: 16
                            color: mpNextMa.containsMouse ? m3Root.colPrimaryContainer : m3Root.colLayer2
                            Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 17; text: m3Root.hasSymbols ? "skip_next" : "⏭"; color: m3Root.colOnLayer0 }
                            MouseArea { id: mpNextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => MediaService.next()) }
                        }
                    }
                }
            }

            // Seekbar + timestamps
            Column {
                width: parent.width; spacing: 4
                M3WavySeekbar {
                    id: mpWavySeek
                    width: parent.width
                    height: 22
                    value: (MediaService.durationSec > 0) ? Math.max(0, Math.min(1, MediaService.positionSec / MediaService.durationSec)) : 0
                    playing: MediaService.hasSession && MediaService.isPlaying
                    interactive: MediaService.canSeek && MediaService.durationSec > 0
                    activeColor: m3Root.colPrimary
                    trackColor: m3Root.colSurfaceVariant
                    onSeekRequested: frac => {
                        if (MediaService.canSeek && MediaService.durationSec > 0)
                            MediaService.seek(frac * MediaService.durationSec)
                    }
                }
                Item {
                    width: parent.width; height: 14
                    Text { anchors.left: parent.left; text: m3MediaPopupWin.fmtSec(mpWavySeek.dragging ? (mpWavySeek.displayValue * MediaService.durationSec) : MediaService.positionSec); font.family: "Segoe UI"; font.pixelSize: 10; color: m3Root.colOnLayer1 }
                    Text { anchors.right: parent.right; text: m3MediaPopupWin.fmtSec(MediaService.durationSec); font.family: "Segoe UI"; font.pixelSize: 10; color: m3Root.colOnLayer1 }
                }
            }

            // Multi-player switcher chips
            Row {
                visible: (MediaService.players || []).length > 1
                width: parent.width; spacing: 6; clip: true
                Repeater {
                    model: MediaService.players || []
                    delegate: Rectangle {
                        required property var modelData
                        height: 22; width: Math.min(110, mpPlTxt.implicitWidth + 16); radius: 11
                        color: modelData.active ? m3Root.colPrimaryContainer : m3Root.colLayer2
                        Text { id: mpPlTxt; anchors.centerIn: parent; width: Math.min(94, implicitWidth); elide: Text.ElideRight; text: modelData.name || modelData.appId || "Player"; font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.DemiBold; color: modelData.active ? m3Root.colPrimary : m3Root.colOnLayer1 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => MediaService.selectSession(modelData.appId || "")) }
                    }
                }
            }
        }
    }
}
