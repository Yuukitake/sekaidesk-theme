import QtQuick
import Quickshell
import SekaiDesk

PanelWindow {
    id: m3ClipWin
    required property var m3Root

    visible: m3Root.clipboardPopupOpen
    readonly property int targetW: 368
    readonly property int targetH: 430
    readonly property int targetX: Math.max(12, m3Root.sw - targetW - 14)
    readonly property int targetY: 46

    function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

    x: targetX; y: targetY; width: targetW; height: targetH
    blurBehind: false
    color: "transparent"

    Timer {
        id: clipFocusTimer
        interval: 45
        repeat: false
        onTriggered: {
            if (m3Root.clipboardPopupOpen) {
                m3ClipWin.focusActivate()
                clipCard.forceActiveFocus()
                clipFocusRetryTimer.restart()
            }
        }
    }
    Timer {
        id: clipFocusRetryTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (m3Root.clipboardPopupOpen && !clipCard.activeFocus) {
                m3ClipWin.focusActivate()
                clipCard.forceActiveFocus()
            }
        }
    }

    Component.onCompleted: syncGeo()
    onTargetXChanged: syncGeo()
    onTargetYChanged: syncGeo()
    onVisibleChanged: {
        if (visible) {
            syncGeo()
            focusActivate()
            clipCard.forceActiveFocus()
            clipFocusTimer.restart()
        } else {
            clipFocusTimer.stop()
            clipFocusRetryTimer.stop()
        }
    }
    onWindowDeactivated: {
        if (m3Root.clipboardPopupOpen) {
            m3Root.clipboardClosedAt = Date.now()
            m3Root.clipboardPopupOpen = false
        }
    }

    Rectangle {
        id: clipCard
        focus: true
        anchors.fill: parent
        radius: 26
        color: m3Root.colLayer1
        border.width: 1; border.color: m3Root.colLayer0Border

        Keys.onEscapePressed: {
            m3Root.clipboardClosedAt = Date.now()
            m3Root.clipboardPopupOpen = false
        }

        Column {
            anchors.fill: parent; anchors.margins: 16; spacing: 12

            Item {
                width: parent.width; height: 34
                Row {
                    anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                    Rectangle {
                        width: 30; height: 30; radius: 15; color: m3Root.colPrimaryContainer
                        Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 16; text: m3Root.hasSymbols ? "content_paste" : "📋"; color: m3Root.colPrimary }
                    }
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "Clipboard (" + ClipboardService.count + ")"; font.family: "Segoe UI"; font.pixelSize: 14; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                }

                Rectangle {
                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                    width: 68; height: 26; radius: 13
                    color: m3Root.colLayer2
                    Text { anchors.centerIn: parent; text: "Clear"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.DemiBold; color: m3Root.colOnLayer1 }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => ClipboardService.clearUnpinned()) }
                }
            }

            Item {
                width: parent.width
                height: parent.height - 46

                Text {
                    visible: ClipboardService.count === 0
                    anchors.centerIn: parent
                    text: "Clipboard history is empty"
                    font.family: "Segoe UI"; font.pixelSize: 12; color: m3Root.colOnLayer1; opacity: 0.75
                }

                ListView {
                    anchors.fill: parent
                    spacing: 8
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: ClipboardService.history || []

                    delegate: Rectangle {
                        required property var modelData
                        required property int index
                        width: ListView.view.width
                        height: modelData.isImage ? 76 : 58
                        radius: 16
                        color: clipRowMa.containsMouse ? m3Root.colPrimaryContainer : m3Root.colLayer2
                        border.width: modelData.pinned ? 1 : 0
                        border.color: m3Root.colPrimary

                        MouseArea {
                            id: clipRowMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const idx = index
                                Qt.callLater(() => {
                                    ClipboardService.copyIndex(idx)
                                    m3Root.clipboardClosedAt = Date.now()
                                    m3Root.clipboardPopupOpen = false
                                })
                            }
                        }

                        Row {
                            anchors.fill: parent; anchors.margins: 10; spacing: 10

                            Rectangle {
                                visible: !!modelData.isImage
                                width: 56; height: 56; radius: 10; clip: true
                                color: m3Root.colSurfaceVariant
                                Image {
                                    anchors.fill: parent
                                    source: modelData.imageUrl || ""
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true; cache: true
                                }
                            }

                            Column {
                                width: parent.width - (modelData.isImage ? 128 : 62)
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 2
                                Text {
                                    width: parent.width
                                    maximumLineCount: 2; wrapMode: Text.WrapAnywhere; elide: Text.ElideRight
                                    text: modelData.preview || modelData.text || "(image)"
                                    font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.DemiBold
                                    color: m3Root.colOnLayer0
                                }
                                Text {
                                    text: modelData.time || ""
                                    font.family: "Segoe UI"; font.pixelSize: 10; color: m3Root.colOnLayer1
                                }
                            }

                            Row {
                                anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                Rectangle {
                                    width: 24; height: 24; radius: 12
                                    color: modelData.pinned ? m3Root.colPrimary : "transparent"
                                    Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 14; text: m3Root.hasSymbols ? "push_pin" : "📌"; color: modelData.pinned ? m3Root.colOnPrimary : m3Root.colOnLayer1 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => ClipboardService.togglePin(index)) }
                                }
                                Rectangle {
                                    width: 24; height: 24; radius: 12; color: "transparent"
                                    Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 14; text: m3Root.hasSymbols ? "delete" : "✕"; color: "#FFB4AB" }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => ClipboardService.removeIndex(index)) }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
