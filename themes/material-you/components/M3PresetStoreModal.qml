import QtQuick
import Quickshell
import SekaiDesk
import ".."

PanelWindow {
    id: m3StoreWin
    required property var m3Root

    property real popK: m3Root.presetStoreOpen ? 1.0 : 0.0
    Behavior on popK {
        NumberAnimation {
            duration: m3Root.presetStoreOpen ? 300 : 200
            easing.type: Easing.BezierSpline
            easing.bezierCurve: m3Root.presetStoreOpen
                                ? [0.05, 0.7, 0.1, 1.0, 1.0, 1.0]
                                : [0.3, 0.0, 0.8, 0.15, 1.0, 1.0]
        }
    }

    visible: m3Root.presetStoreOpen || popK > 0.01
    readonly property int targetW: 840
    readonly property int targetH: 520
    readonly property int targetX: Math.round((m3Root.sw - targetW) * 0.5)
    readonly property int targetY: Math.round((m3Root.sh - targetH) * 0.46)

    function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

    x: targetX; y: targetY; width: targetW; height: targetH
    blurBehind: false
    color: "transparent"

    Timer {
        id: storeFocusTimer
        interval: 45
        repeat: false
        onTriggered: {
            if (m3Root.presetStoreOpen) {
                m3StoreWin.focusActivate()
                storeCard.forceActiveFocus()
                storeFocusRetryTimer.restart()
            }
        }
    }
    Timer {
        id: storeFocusRetryTimer
        interval: 120
        repeat: false
        onTriggered: {
            if (m3Root.presetStoreOpen && !storeCard.activeFocus) {
                m3StoreWin.focusActivate()
                storeCard.forceActiveFocus()
            }
        }
    }

    Component.onCompleted: {
        syncGeo()
        if (m3Root.presetStoreOpen) {
            focusActivate()
            storeCard.forceActiveFocus()
            storeFocusTimer.restart()
        }
    }
    onTargetXChanged: syncGeo()
    onTargetYChanged: syncGeo()
    onVisibleChanged: {
        if (visible) {
            syncGeo()
            if (m3Root.presetStoreOpen) {
                focusActivate()
                storeCard.forceActiveFocus()
                storeFocusTimer.restart()
            }
        } else {
            storeFocusTimer.stop()
            storeFocusRetryTimer.stop()
        }
    }
    onWindowDeactivated: {
        if (m3Root.presetStoreOpen) {
            m3Root.presetStoreClosedAt = Date.now()
            m3Root.presetStoreOpen = false
        }
    }

    Rectangle {
        id: storeCard
        focus: true
        x: 0
        y: Math.round((1.0 - m3StoreWin.popK) * 18)
        width: parent.width
        height: parent.height
        radius: 30
        color: m3Root.colLayer1
        border.width: 1
        border.color: m3Root.colLayer0Border
        opacity: m3StoreWin.popK
        scale: 0.90 + 0.10 * m3StoreWin.popK
        clip: true

        Keys.onEscapePressed: {
            m3Root.presetStoreClosedAt = Date.now()
            m3Root.presetStoreOpen = false
        }

        Column {
            anchors.fill: parent
            anchors.margins: 20
            spacing: 14

            // Header with Expressive MaterialShape Badge + Actions
            Item {
                width: parent.width
                height: 44

                Row {
                    anchors.left: parent.left
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 12

                    Item {
                        width: 40; height: 40
                        anchors.verticalCenter: parent.verticalCenter
                        MaterialShape {
                            anchors.centerIn: parent
                            implicitSize: 40
                            shape: MaterialShape.Shape.Cookie12Sided
                            color: m3Root.colPrimaryContainer
                            rotation: m3Root.presetStoreOpen ? 18 : 0
                            Behavior on rotation { NumberAnimation { duration: 420; easing.type: Easing.OutCubic } }
                        }
                        Text {
                            anchors.centerIn: parent
                            font.family: m3Root.iconFontName; font.pixelSize: 20
                            text: m3Root.hasSymbols ? "palette" : "🎨"
                            color: m3Root.colPrimary
                        }
                    }

                    Column {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 0
                        Text {
                            text: "Presets & Theme Store"
                            font.family: "Segoe UI"; font.pixelSize: 17; font.weight: Font.Bold
                            color: m3Root.colOnLayer0
                        }
                        Text {
                            width: 390; elide: Text.ElideRight
                            text: ThemeStore.errorMessage !== ""
                                  ? ThemeStore.errorMessage
                                  : (ThemeStore.statusMessage || ("Active: " + ThemeStore.activePreset))
                            font.family: "Segoe UI"; font.pixelSize: 11
                            color: ThemeStore.errorMessage !== "" ? "#FFB4AB" : m3Root.colOnLayer1
                        }
                    }
                }

                Row {
                    anchors.right: parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 8

                    Rectangle {
                        height: 34; width: openDirRow.implicitWidth + 20; radius: 17
                        color: openDirMa.containsMouse ? m3Root.colPrimaryContainer : m3Root.colLayer2
                        Row {
                            id: openDirRow; anchors.centerIn: parent; spacing: 6
                            Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 16; text: m3Root.hasSymbols ? "folder_open" : "📁"; color: m3Root.colOnLayer0 }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Folder"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                        }
                        MouseArea { id: openDirMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => ThemeStore.openThemesFolder()) }
                    }

                    Rectangle {
                        height: 34; width: refStoreRow.implicitWidth + 20; radius: 17
                        color: refStoreMa.containsMouse ? m3Root.colPrimaryContainer : m3Root.colLayer2
                        Row {
                            id: refStoreRow; anchors.centerIn: parent; spacing: 6
                            Text {
                                anchors.verticalCenter: parent.verticalCenter
                                font.family: m3Root.iconFontName; font.pixelSize: 16
                                text: m3Root.hasSymbols ? "refresh" : "↻"
                                color: m3Root.colPrimary
                                RotationAnimation on rotation {
                                    from: 0; to: 360; duration: 850
                                    loops: Animation.Infinite
                                    running: ThemeStore.refreshing
                                }
                            }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: ThemeStore.refreshing ? "Syncing" : "Refresh"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                        }
                        MouseArea { id: refStoreMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => ThemeStore.refreshCatalog()) }
                    }

                    Rectangle {
                        height: 34; width: deepSetRow.implicitWidth + 20; radius: 17
                        color: deepSetMa.containsMouse ? m3Root.colPrimaryContainer : m3Root.colLayer2
                        Row {
                            id: deepSetRow; anchors.centerIn: parent; spacing: 6
                            Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 16; text: m3Root.hasSymbols ? "settings" : "⚙"; color: m3Root.colOnLayer0 }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Settings"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                        }
                        MouseArea {
                            id: deepSetMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.callLater(() => {
                                m3Root.presetStoreClosedAt = Date.now()
                                m3Root.presetStoreOpen = false
                                if (m3Root.themeHub) {
                                    m3Root.themeHub.landscapeContent = "settings"
                                    m3Root.themeHub.settingsSection = "general"
                                    m3Root.themeHub.settingsOpen = true
                                }
                            })
                        }
                    }

                    Rectangle {
                        width: 34; height: 34; radius: 17
                        color: closeStoreMa.containsMouse ? m3Root.colPrimaryContainer : m3Root.colLayer2
                        Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "close" : "✕"; color: m3Root.colOnLayer0 }
                        MouseArea {
                            id: closeStoreMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: { m3Root.presetStoreClosedAt = Date.now(); m3Root.presetStoreOpen = false }
                        }
                    }
                }
            }

            // Active Status Banner
            Rectangle {
                width: parent.width; height: 36; radius: 18
                color: m3Root.colLayer0
                border.width: 1; border.color: m3Root.colLayer0Border

                Row {
                    anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                    Rectangle {
                        height: 22; width: actChipTxt.implicitWidth + 16; radius: 11
                        color: m3Root.colPrimaryContainer
                        Text { id: actChipTxt; anchors.centerIn: parent; text: "ACTIVE · " + String(ThemeStore.activePreset || "pjsk").toUpperCase(); font.family: "Consolas"; font.pixelSize: 10; font.weight: Font.Bold; color: m3Root.colPrimary }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: ((ThemeStore.presets || []).length) + " presets available · Instant live hot-swap"
                        font.family: "Segoe UI"; font.pixelSize: 11; color: m3Root.colOnLayer1
                    }
                }
            }

            // 2-Column Expressive Preset Cards Grid
            GridView {
                id: m3StoreGrid
                width: parent.width
                height: parent.height - 108
                cellWidth: 400
                cellHeight: 244
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: ThemeStore.presets || []

                delegate: Item {
                    required property var modelData
                    readonly property string pid: modelData.id || ""
                    readonly property bool isActive: ThemeStore.activePreset === pid
                    readonly property bool isInst: !!modelData.installed
                    readonly property bool isBusy: ThemeStore.busyPresetId === pid
                    readonly property color colA: modelData.previewColorA || m3Root.colPrimaryContainer
                    readonly property color colB: modelData.previewColorB || m3Root.colPrimary

                    width: m3StoreGrid.cellWidth
                    height: m3StoreGrid.cellHeight

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 6
                        radius: 26
                        color: m3Root.colLayer2
                        border.width: isActive ? 2 : 1
                        border.color: isActive ? m3Root.colPrimary : m3Root.colLayer0Border
                        scale: cardHoverMa.containsMouse ? 1.015 : 1.0
                        Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        MouseArea { id: cardHoverMa; anchors.fill: parent; hoverEnabled: true; acceptedButtons: Qt.NoButton }

                        Column {
                            anchors.fill: parent
                            anchors.margins: 12
                            spacing: 10

                            // Gradient Banner
                            Rectangle {
                                width: parent.width
                                height: 78
                                radius: 20
                                clip: true
                                gradient: Gradient {
                                    orientation: Gradient.Horizontal
                                    GradientStop { position: 0.0; color: colA }
                                    GradientStop { position: 1.0; color: colB }
                                }

                                // Soft M3 decorative shapes
                                Rectangle {
                                    x: parent.width - 54; y: -22; width: 96; height: 96; radius: 48
                                    color: Qt.rgba(1, 1, 1, 0.14)
                                }
                                MaterialShape {
                                    x: parent.width - 68; y: 12
                                    implicitSize: 58
                                    shape: pid === "pjsk" ? MaterialShape.Shape.SoftBurst : MaterialShape.Shape.Cookie9Sided
                                    color: Qt.rgba(1, 1, 1, 0.18)
                                }

                                // Subtle dark legibility scrim on bottom-left
                                Rectangle {
                                    anchors.fill: parent
                                    gradient: Gradient {
                                        orientation: Gradient.Horizontal
                                        GradientStop { position: 0.0; color: Qt.rgba(0, 0, 0, 0.42) }
                                        GradientStop { position: 0.75; color: Qt.rgba(0, 0, 0, 0.12) }
                                        GradientStop { position: 1.0; color: "transparent" }
                                    }
                                }

                                Column {
                                    anchors.left: parent.left; anchors.leftMargin: 14; anchors.verticalCenter: parent.verticalCenter
                                    width: parent.width - 120
                                    spacing: 2
                                    Text {
                                        width: parent.width; elide: Text.ElideRight
                                        text: modelData.name || pid
                                        font.family: "Segoe UI"; font.pixelSize: 16; font.weight: Font.Bold
                                        color: "#FFFFFF"
                                    }
                                    Text {
                                        width: parent.width; elide: Text.ElideRight
                                        text: "by " + (modelData.author || "Yuukitake") + " • " + (modelData.license || "MIT") + (modelData.sizeKb ? (" • " + modelData.sizeKb + " KB") : "")
                                        font.family: "Segoe UI"; font.pixelSize: 10
                                        color: Qt.rgba(1, 1, 1, 0.85)
                                    }
                                }

                                Row {
                                    anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 10
                                    spacing: 6
                                    Rectangle {
                                        visible: isActive
                                        height: 20; width: actTagTxt.implicitWidth + 12; radius: 10
                                        color: m3Root.colPrimary
                                        Text { id: actTagTxt; anchors.centerIn: parent; text: "ACTIVE"; font.family: "Consolas"; font.pixelSize: 9; font.weight: Font.Bold; color: m3Root.colOnPrimary }
                                    }
                                    Rectangle {
                                        height: 20; width: verTagTxt.implicitWidth + 12; radius: 10
                                        color: Qt.rgba(0, 0, 0, 0.45)
                                        Text { id: verTagTxt; anchors.centerIn: parent; text: "v" + (modelData.version || "1.0"); font.family: "Consolas"; font.pixelSize: 9; font.weight: Font.Bold; color: "#FFFFFF" }
                                    }
                                }
                            }

                            // Description
                            Text {
                                width: parent.width
                                height: 34
                                wrapMode: Text.WordWrap
                                maximumLineCount: 2
                                elide: Text.ElideRight
                                text: modelData.description || ""
                                font.family: "Segoe UI"; font.pixelSize: 11
                                color: m3Root.colOnLayer1
                            }

                            // Tags Row
                            Row {
                                width: parent.width; height: 22; spacing: 6; clip: true
                                Repeater {
                                    model: (modelData.tags || []).slice(0, 4)
                                    delegate: Rectangle {
                                        required property string modelData
                                        height: 20; width: tagLbl.implicitWidth + 14; radius: 10
                                        color: m3Root.colLayer0
                                        Text { id: tagLbl; anchors.centerIn: parent; text: modelData; font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.DemiBold; color: m3Root.colPrimary }
                                    }
                                }
                            }

                            // Progress bar when downloading OR Action Row
                            Item {
                                width: parent.width
                                height: 38

                                Rectangle {
                                    visible: isBusy
                                    anchors.fill: parent
                                    radius: 19
                                    color: m3Root.colLayer0
                                    Rectangle {
                                        height: parent.height
                                        width: Math.max(38, parent.width * Math.max(0.05, Math.min(1.0, ThemeStore.downloadProgress)))
                                        radius: 19
                                        color: m3Root.colPrimary
                                        Behavior on width { NumberAnimation { duration: 120 } }
                                    }
                                    Text {
                                        anchors.centerIn: parent
                                        text: "Downloading... " + Math.round(ThemeStore.downloadProgress * 100) + "%"
                                        font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold
                                        color: m3Root.colOnLayer0
                                    }
                                }

                                Row {
                                    visible: !isBusy
                                    anchors.fill: parent
                                    spacing: 8

                                    Rectangle {
                                        width: (isInst && pid !== "pjsk") ? (parent.width - 46) : parent.width
                                        height: 38
                                        radius: 19
                                        color: isActive
                                               ? m3Root.colPrimaryContainer
                                               : (actBtnMa.containsMouse ? m3Root.colPrimary : (isInst ? m3Root.colLayer0 : m3Root.colPrimary))
                                        border.width: isActive ? 1 : 0
                                        border.color: m3Root.colPrimary
                                        scale: actBtnMa.pressed ? 0.96 : 1.0
                                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }

                                        Text {
                                            anchors.centerIn: parent
                                            text: isActive
                                                  ? "✓ Currently Active"
                                                  : (isInst ? "Apply Preset" : "Download Preset")
                                            font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold
                                            color: isActive
                                                   ? m3Root.colPrimary
                                                   : (actBtnMa.containsMouse || !isInst ? m3Root.colOnPrimary : m3Root.colOnLayer0)
                                        }

                                        MouseArea {
                                            id: actBtnMa
                                            anchors.fill: parent
                                            hoverEnabled: true
                                            cursorShape: isActive ? Qt.ArrowCursor : Qt.PointingHandCursor
                                            onClicked: {
                                                if (isActive) return
                                                const idToRun = pid
                                                const installed = isInst
                                                Qt.callLater(() => {
                                                    if (installed) {
                                                        m3Root.presetStoreClosedAt = Date.now()
                                                        m3Root.presetStoreOpen = false
                                                        if (m3Root.themeHub)
                                                            m3Root.themeHub.requestPresetSwitch(idToRun)
                                                    } else {
                                                        ThemeStore.installPreset(idToRun)
                                                    }
                                                })
                                            }
                                        }
                                    }

                                    Rectangle {
                                        visible: isInst && pid !== "pjsk"
                                        width: 38; height: 38; radius: 19
                                        color: delBtnMa.containsMouse ? "#93000A" : m3Root.colLayer0
                                        Text {
                                            anchors.centerIn: parent
                                            font.family: m3Root.iconFontName; font.pixelSize: 17
                                            text: m3Root.hasSymbols ? "delete" : "🗑"
                                            color: delBtnMa.containsMouse ? "#FFDAD6" : "#FFB4AB"
                                        }
                                        MouseArea {
                                            id: delBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                            onClicked: { const idToDel = pid; Qt.callLater(() => ThemeStore.removePreset(idToDel)) }
                                        }
                                    }
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
