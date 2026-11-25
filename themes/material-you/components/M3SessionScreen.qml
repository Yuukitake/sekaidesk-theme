import QtQuick
import Quickshell
import SekaiDesk

PanelWindow {
    id: m3SessionWin
    required property var m3Root

    visible: m3Root.sessionScreenOpen
    readonly property int targetX: 0
    readonly property int targetY: 0
    readonly property int targetW: m3Root.sw
    readonly property int targetH: m3Root.sh

    function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

    x: targetX; y: targetY; width: targetW; height: targetH
    blurBehind: false
    color: "transparent"

    Timer {
        id: sessFocusTimer
        interval: 45
        repeat: false
        onTriggered: {
            if (m3Root.sessionScreenOpen) {
                m3SessionWin.focusActivate()
                sessCard.forceActiveFocus()
                sessFocusRetryTimer.restart()
            }
        }
    }
    Timer {
        id: sessFocusRetryTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (m3Root.sessionScreenOpen && !sessCard.activeFocus) {
                m3SessionWin.focusActivate()
                sessCard.forceActiveFocus()
            }
        }
    }

    Component.onCompleted: syncGeo()
    onTargetWChanged: syncGeo()
    onTargetHChanged: syncGeo()
    onVisibleChanged: {
        if (visible) {
            syncGeo()
            focusActivate()
            sessCard.forceActiveFocus()
            sessFocusTimer.restart()
        } else {
            sessFocusTimer.stop()
            sessFocusRetryTimer.stop()
        }
    }
    onWindowDeactivated: {
        if (m3Root.sessionScreenOpen) {
            m3Root.sessionClosedAt = Date.now()
            m3Root.sessionScreenOpen = false
        }
    }

    Rectangle {
        id: sessCard
        focus: true
        anchors.fill: parent
        color: Qt.rgba(0.04, 0.05, 0.08, 0.80)

        Keys.onEscapePressed: {
            m3Root.sessionClosedAt = Date.now()
            m3Root.sessionScreenOpen = false
        }

        MouseArea {
            anchors.fill: parent
            onClicked: {
                m3Root.sessionClosedAt = Date.now()
                m3Root.sessionScreenOpen = false
            }
        }

        Column {
            anchors.centerIn: parent
            spacing: 24

            Column {
                anchors.horizontalCenter: parent.horizontalCenter
                spacing: 4
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: Qt.formatDateTime(m3Root.nowDate, "hh:mm AP")
                    font.family: "Segoe UI"; font.pixelSize: 38; font.weight: Font.Bold
                    color: m3Root.colOnLayer0
                }
                Text {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: "Session & Power"
                    font.family: "Segoe UI"; font.pixelSize: 13
                    color: m3Root.colOnLayer1
                }
            }

            Grid {
                anchors.horizontalCenter: parent.horizontalCenter
                columns: 3
                columnSpacing: 18
                rowSpacing: 18

                Repeater {
                    model: [
                        { act: "lock", label: "Lock", ic: "lock", fb: "🔒", danger: false },
                        { act: "sleep", label: "Sleep", ic: "bedtime", fb: "☾", danger: false },
                        { act: "hibernate", label: "Hibernate", ic: "downloading", fb: "⏾", danger: false },
                        { act: "restart", label: "Restart", ic: "restart_alt", fb: "↻", danger: true },
                        { act: "shutdown", label: "Shut Down", ic: "power_settings_new", fb: "⏻", danger: true },
                        { act: "signout", label: "Sign Out", ic: "logout", fb: "↪", danger: false }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: 112; height: 112; radius: 32
                        color: sessBtnMa.containsMouse
                               ? (modelData.danger ? "#93000A" : m3Root.colPrimary)
                               : m3Root.colLayer1
                        border.width: 1
                        border.color: sessBtnMa.containsMouse ? "transparent" : m3Root.colLayer0Border
                        scale: sessBtnMa.pressed ? 0.94 : (sessBtnMa.containsMouse ? 1.04 : 1.0)
                        Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }

                        Column {
                            anchors.centerIn: parent; spacing: 8
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                font.family: m3Root.iconFontName; font.pixelSize: 30
                                text: m3Root.hasSymbols ? modelData.ic : modelData.fb
                                color: sessBtnMa.containsMouse
                                       ? (modelData.danger ? "#FFDAD6" : m3Root.colOnPrimary)
                                       : (modelData.danger ? "#FFB4AB" : m3Root.colPrimary)
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: modelData.label
                                font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                                color: sessBtnMa.containsMouse
                                       ? (modelData.danger ? "#FFDAD6" : m3Root.colOnPrimary)
                                       : m3Root.colOnLayer0
                            }
                        }

                        MouseArea {
                            id: sessBtnMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const act = modelData.act
                                Qt.callLater(() => {
                                    m3Root.sessionClosedAt = Date.now()
                                    m3Root.sessionScreenOpen = false
                                    if (act === "lock") SystemControl.lockScreen()
                                    else if (act === "sleep") SystemControl.sleepPc()
                                    else if (act === "hibernate") SystemControl.hibernatePc()
                                    else if (act === "restart") SystemControl.restartPc()
                                    else if (act === "shutdown") SystemControl.shutdownPc()
                                    else if (act === "signout") SystemControl.signOut()
                                })
                            }
                        }
                    }
                }
            }
        }
    }
}
