import QtQuick
import Quickshell
import SekaiDesk

Item {
    id: m3Root
    visible: false

    property var themeHub: null
    property bool fullscreenActive: false
    property string presetDirUrl: ""
    property bool quickPanelOpen: false
    signal requestQuickPanel()

    readonly property int sw: (themeHub && themeHub.screenW > 0) ? themeHub.screenW : 1920
    readonly property int sh: (themeHub && themeHub.screenH > 0) ? themeHub.screenH : 1080
    readonly property bool compactH: sh < 820

    FontLoader {
        id: m3SymbolsFont
        source: m3Root.presetDirUrl !== "" ? (m3Root.presetDirUrl + "assets/MaterialSymbolsLite.ttf") : ""
    }
    readonly property string iconFontName: m3SymbolsFont.status === FontLoader.Ready ? m3SymbolsFont.name : "Segoe Fluent Icons"
    readonly property bool hasSymbols: m3SymbolsFont.status === FontLoader.Ready

    // Live Material 3 Tonal Palette extracted from active wallpaper / band accent
    readonly property color seedColor: themeHub ? themeHub.accentA : "#67D5B5"
    readonly property real seedHue: (seedColor.hslHue >= 0 && seedColor.hslSaturation > 0.05) ? seedColor.hslHue : 0.43
    readonly property real seedSat: Math.max(0.28, Math.min(0.68, seedColor.hslSaturation))

    readonly property color m3Background: Qt.hsla(seedHue, seedSat * 0.28, 0.08, 0.94)
    readonly property color m3Surface: Qt.hsla(seedHue, seedSat * 0.30, 0.13, 0.88)
    readonly property color m3SurfaceHigh: Qt.hsla(seedHue, seedSat * 0.34, 0.19, 0.92)
    readonly property color m3SurfaceBright: Qt.hsla(seedHue, seedSat * 0.36, 0.25, 0.95)
    readonly property color m3Primary: Qt.hsla(seedHue, Math.min(0.72, seedSat * 1.15), 0.78, 1.0)
    readonly property color m3PrimaryContainer: Qt.hsla(seedHue, seedSat * 0.55, 0.28, 0.96)
    readonly property color m3OnPrimary: Qt.hsla(seedHue, 0.45, 0.12, 1.0)
    readonly property color m3OnSurface: Qt.hsla(seedHue, 0.16, 0.92, 1.0)
    readonly property color m3OnSurfaceVariant: Qt.hsla(seedHue, 0.18, 0.72, 1.0)
    readonly property color m3Outline: Qt.hsla(seedHue, 0.24, 0.40, 0.42)

    property date nowDate: new Date()
    Timer {
        interval: 1000
        repeat: true
        running: !m3Root.fullscreenActive
        onTriggered: m3Root.nowDate = new Date()
    }

    function fmtTime(d, offsetHours) {
        let h = d.getUTCHours() + offsetHours
        while (h < 0) h += 24
        while (h >= 24) h -= 24
        const m = d.getUTCMinutes()
        const ap = h >= 12 ? "PM" : "AM"
        const h12 = (h % 12 === 0) ? 12 : (h % 12)
        return (h12 < 10 ? "0" : "") + h12 + ":" + (m < 10 ? "0" : "") + m + " " + ap
    }

    function fmtRate(bps) {
        const v = Number(bps) || 0
        if (v >= 1048576) return (v / 1048576).toFixed(1) + " MB/s"
        if (v >= 1024) return Math.round(v / 1024) + " KB/s"
        return Math.round(v) + " B/s"
    }

    readonly property var m3DockApps: {
        const list = []
        const seen = {}
        const pinned = AppLauncher.pinnedApps || []
        for (let i = 0; i < pinned.length; ++i) {
            const p = pinned[i]
            if (!p || !p.target) continue
            const k = p.target.toLowerCase()
            seen[k] = true
            const st = WindowTracker.stateForTarget(p.target)
            list.push({
                name: p.name || "",
                target: p.target,
                args: p.args || "",
                pinned: true,
                running: !!(st && st.running),
                active: !!(st && st.active)
            })
        }
        const running = WindowTracker.runningApps || []
        for (let r = 0; r < running.length; ++r) {
            const ra = running[r]
            if (!ra || !ra.target) continue
            const rk = ra.target.toLowerCase()
            if (!seen[rk]) {
                seen[rk] = true
                list.push({
                    name: ra.name || "",
                    target: ra.target,
                    args: "",
                    pinned: false,
                    running: true,
                    active: !!ra.active
                })
            }
        }
        return list
    }

    // =========================================================================
    // 1. M3 Translucent Top Bar (Primary Screen Top WorkArea Reserve)
    // =========================================================================
    PanelWindow {
        id: m3TopBar
        visible: !m3Root.fullscreenActive
        readonly property int targetX: 0
        readonly property int targetY: 0
        readonly property int targetW: m3Root.sw
        readonly property int targetH: 36

        function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

        x: targetX; y: targetY; width: targetW; height: targetH
        reserveTopBar: !m3Root.fullscreenActive
        reserveEdge: "top"
        reserveHeight: m3Root.fullscreenActive ? 0 : 36
        blurBehind: true
        blurRadius: 24
        blurTint: m3Root.m3Background
        color: "transparent"

        Component.onCompleted: syncGeo()
        onTargetXChanged: syncGeo()
        onTargetYChanged: syncGeo()
        onTargetWChanged: syncGeo()
        onTargetHChanged: syncGeo()
        onVisibleChanged: if (visible) syncGeo()

        Rectangle {
            anchors.fill: parent
            color: m3Root.m3Background

            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 1; color: m3Root.m3Outline
            }

            // Left Section: Launcher + Net/Audio + Active Window
            Row {
                anchors.left: parent.left; anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    height: 26; width: 32; radius: 13
                    color: m3BarAppsMa.containsMouse ? m3Root.m3SurfaceBright : m3Root.m3SurfaceHigh
                    Text {
                        anchors.centerIn: parent
                        font.family: m3Root.iconFontName
                        font.pixelSize: 16
                        text: m3Root.hasSymbols ? "apps" : "⊞"
                        color: m3Root.m3Primary
                    }
                    MouseArea {
                        id: m3BarAppsMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.callLater(() => { if (m3Root.themeHub) m3Root.themeHub.spotlightOpen = !m3Root.themeHub.spotlightOpen })
                    }
                }

                Rectangle {
                    height: 26; width: m3StatusRow.implicitWidth + 18; radius: 13
                    color: m3Root.m3Surface
                    border.width: 1; border.color: m3Root.m3Outline

                    Row {
                        id: m3StatusRow
                        anchors.centerIn: parent
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: m3Root.iconFontName; font.pixelSize: 14
                            text: m3Root.hasSymbols ? (SystemControl.wifiEnabled ? "wifi" : "wifi_off") : "WiFi"
                            color: SystemControl.wifiEnabled ? m3Root.m3Primary : m3Root.m3OnSurfaceVariant
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Consolas"; font.pixelSize: 11; font.weight: Font.Bold
                            text: "↓" + m3Root.fmtRate(WindowTracker.downloadBps)
                            color: m3Root.m3OnSurfaceVariant
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: m3Root.iconFontName; font.pixelSize: 14
                            text: m3Root.hasSymbols ? (AudioService.masterMuted ? "volume_off" : "volume_up") : "Vol"
                            color: AudioService.masterMuted ? "#FB7185" : m3Root.m3OnSurface
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.callLater(() => AudioService.toggleMasterMute())
                            }
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: "Consolas"; font.pixelSize: 11; font.weight: Font.Bold
                            text: AudioService.masterVolume + "%"
                            color: m3Root.m3OnSurface
                        }
                    }
                }

                Rectangle {
                    height: 26
                    width: Math.min(260, m3ActiveWinTxt.implicitWidth + 20)
                    radius: 13
                    color: m3Root.m3PrimaryContainer
                    visible: WindowTracker.activeAppName !== ""
                    Text {
                        id: m3ActiveWinTxt
                        anchors.centerIn: parent
                        width: parent.width - 16
                        elide: Text.ElideRight
                        horizontalAlignment: Text.AlignHCenter
                        text: WindowTracker.activeAppName || "Desktop"
                        font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                        color: m3Root.m3OnSurface
                    }
                }
            }

            // Center Pill: Weather + Date & Clock
            Rectangle {
                anchors.centerIn: parent
                height: 26
                width: m3CenterRow.implicitWidth + 24
                radius: 13
                color: m3Root.m3Surface
                border.width: 1; border.color: m3Root.m3Outline

                Row {
                    id: m3CenterRow
                    anchors.centerIn: parent
                    spacing: 10

                    Row {
                        spacing: 4
                        anchors.verticalCenter: parent.verticalCenter
                        visible: WeatherService.ready
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: m3Root.iconFontName; font.pixelSize: 14
                            text: m3Root.hasSymbols ? "partly_cloudy_day" : "☀"
                            color: m3Root.m3Primary
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: WeatherService.temperature + "°C"
                            font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold
                            color: m3Root.m3OnSurface
                        }
                    }

                    Rectangle {
                        width: 8; height: 8; radius: 4
                        anchors.verticalCenter: parent.verticalCenter
                        color: m3Root.m3Primary
                    }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDateTime(m3Root.nowDate, "ddd, dd MMM · hh:mm AP")
                        font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                        color: m3Root.m3OnSurface
                    }
                }
            }

            // Right Section: Media Chip + Presets + Quick Panel
            Row {
                anchors.right: parent.right; anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    visible: MediaService.hasSession && MediaService.title !== ""
                    height: 26
                    width: Math.min(220, m3BarMediaTxt.implicitWidth + 42)
                    radius: 13
                    color: m3Root.m3SurfaceHigh
                    border.width: 1; border.color: m3Root.m3Outline

                    Row {
                        anchors.centerIn: parent
                        spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: m3Root.iconFontName; font.pixelSize: 14
                            text: m3Root.hasSymbols ? (MediaService.isPlaying ? "pause" : "play_arrow") : (MediaService.isPlaying ? "❚❚" : "▶")
                            color: m3Root.m3Primary
                        }
                        Text {
                            id: m3BarMediaTxt
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(165, implicitWidth)
                            elide: Text.ElideRight
                            text: MediaService.title
                            font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.DemiBold
                            color: m3Root.m3OnSurface
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.callLater(() => MediaService.playPause())
                    }
                }

                Rectangle {
                    height: 26; width: m3PresetsChipTxt.implicitWidth + 24; radius: 13
                    color: m3PresetsChipMa.containsMouse ? m3Root.m3Primary : m3Root.m3SurfaceHigh
                    border.width: 1; border.color: m3Root.m3Outline
                    Text {
                        id: m3PresetsChipTxt
                        anchors.centerIn: parent
                        text: "Presets"
                        font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold
                        color: m3PresetsChipMa.containsMouse ? m3Root.m3OnPrimary : m3Root.m3OnSurface
                    }
                    MouseArea {
                        id: m3PresetsChipMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.callLater(() => {
                            if (m3Root.themeHub) {
                                m3Root.themeHub.landscapeContent = "settings"
                                m3Root.themeHub.settingsSection = "presets"
                                m3Root.themeHub.settingsOpen = true
                                ThemeStore.refreshCatalog()
                            }
                        })
                    }
                }

                Rectangle {
                    height: 26; width: 30; radius: 13
                    color: m3QPMa.containsMouse ? m3Root.m3Primary : m3Root.m3SurfaceHigh
                    border.width: 1; border.color: m3Root.m3Outline
                    Text {
                        anchors.centerIn: parent
                        font.family: m3Root.iconFontName; font.pixelSize: 15
                        text: m3Root.hasSymbols ? "tune" : "⚙"
                        color: m3QPMa.containsMouse ? m3Root.m3OnPrimary : m3Root.m3OnSurface
                    }
                    MouseArea {
                        id: m3QPMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.callLater(() => m3Root.requestQuickPanel())
                    }
                }
            }
        }
    }

    // =========================================================================
    // 2. M3 Left Desktop Widgets (UserCard + World Clock)
    // =========================================================================
    PanelWindow {
        id: m3LeftWidgets
        visible: !m3Root.fullscreenActive
        desktopLayer: true
        readonly property int targetX: 16
        readonly property int targetY: 48
        readonly property int targetW: 262
        readonly property int targetH: m3LeftCol.implicitHeight + 4

        function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

        x: targetX; y: targetY; width: targetW; height: targetH
        color: "transparent"

        Component.onCompleted: syncGeo()
        onTargetXChanged: syncGeo()
        onTargetYChanged: syncGeo()
        onTargetWChanged: syncGeo()
        onTargetHChanged: syncGeo()
        onVisibleChanged: if (visible) syncGeo()

        Column {
            id: m3LeftCol
            width: parent.width
            spacing: m3Root.compactH ? 10 : 12

            // UserCard
            Rectangle {
                width: parent.width
                height: m3Root.compactH ? 190 : 206
                radius: 22
                color: m3Root.m3Surface
                border.width: 1; border.color: m3Root.m3Outline

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: m3Root.compactH ? 8 : 10

                    Row {
                        width: parent.width
                        spacing: 12

                        Rectangle {
                            width: 52; height: 52; radius: 26
                            color: m3Root.m3PrimaryContainer
                            border.width: 2; border.color: m3Root.m3Primary
                            clip: true
                            Image {
                                anchors.fill: parent; anchors.margins: 2
                                source: "qrc:/qml/icons/author-pfp.png"
                                fillMode: Image.PreserveAspectCrop
                                smooth: true
                            }
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 64
                            spacing: 2
                            Text {
                                width: parent.width; elide: Text.ElideRight
                                text: (WindowTracker.userName || "User") + "@" + (WindowTracker.machineName || "PC")
                                font.family: "Segoe UI"; font.pixelSize: 14; font.weight: Font.Bold
                                color: m3Root.m3OnSurface
                            }
                            Text {
                                width: parent.width; elide: Text.ElideRight
                                text: "Up · " + (WindowTracker.uptimeText || "0m")
                                font.family: "Consolas"; font.pixelSize: 11; font.weight: Font.Bold
                                color: m3Root.m3OnSurfaceVariant
                            }
                            Text {
                                width: parent.width; elide: Text.ElideRight
                                text: WeatherService.ready ? (WeatherService.conditionText + " · " + WeatherService.temperature + "°C") : "Material You Active"
                                font.family: "Segoe UI"; font.pixelSize: 11
                                color: m3Root.m3Primary
                            }
                        }
                    }

                    Rectangle { width: parent.width; height: 1; color: m3Root.m3Outline }

                    Row {
                        width: parent.width
                        spacing: 8

                        Rectangle {
                            width: parent.width - 84; height: 36; radius: 18
                            color: m3LockMa.containsMouse ? m3Root.m3Primary : m3Root.m3SurfaceBright
                            Row {
                                anchors.centerIn: parent; spacing: 6
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.family: m3Root.iconFontName; font.pixelSize: 16
                                    text: m3Root.hasSymbols ? "lock" : "🔒"
                                    color: m3LockMa.containsMouse ? m3Root.m3OnPrimary : m3Root.m3OnSurface
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: "Lock"
                                    font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Bold
                                    color: m3LockMa.containsMouse ? m3Root.m3OnPrimary : m3Root.m3OnSurface
                                }
                            }
                            MouseArea {
                                id: m3LockMa
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.callLater(() => SystemControl.lockScreen())
                            }
                        }

                        Rectangle {
                            width: 36; height: 36; radius: 18
                            color: m3CfgMa.containsMouse ? m3Root.m3Primary : m3Root.m3SurfaceHigh
                            Text {
                                anchors.centerIn: parent
                                font.family: m3Root.iconFontName; font.pixelSize: 17
                                text: m3Root.hasSymbols ? "settings" : "⚙"
                                color: m3CfgMa.containsMouse ? m3Root.m3OnPrimary : m3Root.m3OnSurface
                            }
                            MouseArea {
                                id: m3CfgMa
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.callLater(() => {
                                    if (m3Root.themeHub) {
                                        m3Root.themeHub.landscapeContent = "settings"
                                        m3Root.themeHub.settingsSection = "presets"
                                        m3Root.themeHub.settingsOpen = true
                                    }
                                })
                            }
                        }

                        Rectangle {
                            width: 36; height: 36; radius: 18
                            color: m3PwrMa.containsMouse ? m3Root.m3Primary : m3Root.m3SurfaceHigh
                            Text {
                                anchors.centerIn: parent
                                font.family: m3Root.iconFontName; font.pixelSize: 17
                                text: m3Root.hasSymbols ? "power_settings_new" : "⏻"
                                color: m3PwrMa.containsMouse ? m3Root.m3OnPrimary : m3Root.m3OnSurface
                            }
                            MouseArea {
                                id: m3PwrMa
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.callLater(() => m3Root.requestQuickPanel())
                            }
                        }
                    }

                    Rectangle {
                        width: parent.width; height: 32; radius: 16
                        color: m3SwitchMa.containsMouse ? m3Root.m3PrimaryContainer : m3Root.m3Background
                        border.width: 1; border.color: m3Root.m3Outline
                        Text {
                            anchors.centerIn: parent
                            text: "Switch Preset"
                            font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold
                            color: m3Root.m3Primary
                        }
                        MouseArea {
                            id: m3SwitchMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.callLater(() => {
                                if (m3Root.themeHub) {
                                    m3Root.themeHub.landscapeContent = "settings"
                                    m3Root.themeHub.settingsSection = "presets"
                                    m3Root.themeHub.settingsOpen = true
                                    ThemeStore.refreshCatalog()
                                }
                            })
                        }
                    }
                }
            }

            // World Clock Card
            Rectangle {
                width: parent.width
                height: m3Root.compactH ? 202 : 216
                radius: 22
                color: m3Root.m3Surface
                border.width: 1; border.color: m3Root.m3Outline

                Column {
                    anchors.fill: parent
                    anchors.margins: 14
                    spacing: 6

                    Row {
                        width: parent.width; spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: m3Root.iconFontName; font.pixelSize: 15
                            text: m3Root.hasSymbols ? "location_on" : "📍"
                            color: m3Root.m3Primary
                        }
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: WeatherService.city || "Local Time"
                            font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                            color: m3Root.m3OnSurfaceVariant
                        }
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        text: Qt.formatDateTime(m3Root.nowDate, "hh:mm AP")
                        font.family: "Segoe UI"; font.pixelSize: 28; font.weight: Font.Bold
                        color: m3Root.m3OnSurface
                    }

                    Text {
                        width: parent.width
                        horizontalAlignment: Text.AlignRight
                        text: Qt.formatDateTime(m3Root.nowDate, "dddd, MMMM d yyyy")
                        font.family: "Segoe UI"; font.pixelSize: 11
                        color: m3Root.m3OnSurfaceVariant
                    }

                    Rectangle { width: parent.width; height: 1; color: m3Root.m3Outline }

                    Grid {
                        width: parent.width
                        columns: 2
                        columnSpacing: 10
                        rowSpacing: 6

                        Repeater {
                            model: [
                                { city: "Tokyo", tz: "+9", off: 9 },
                                { city: "Seoul", tz: "+9", off: 9 },
                                { city: "London", tz: "+0", off: 0 },
                                { city: "New York", tz: "-5", off: -5 }
                            ]
                            delegate: Column {
                                required property var modelData
                                width: (m3LeftWidgets.targetW - 38) * 0.5
                                spacing: 1
                                Row {
                                    width: parent.width; spacing: 4
                                    Text { text: modelData.city; font.family: "Segoe UI"; font.pixelSize: 11; color: m3Root.m3OnSurfaceVariant }
                                    Text { text: modelData.tz; font.family: "Consolas"; font.pixelSize: 10; color: m3Root.m3Primary }
                                }
                                Text {
                                    text: m3Root.fmtTime(m3Root.nowDate, modelData.off)
                                    font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Bold
                                    color: m3Root.m3OnSurface
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 3. M3 Right Desktop Widgets (Stacked Clock + Media + Weather + Gauges)
    // =========================================================================
    PanelWindow {
        id: m3RightWidgets
        visible: !m3Root.fullscreenActive
        desktopLayer: true
        readonly property int targetW: 312
        readonly property int targetH: m3RightCol.implicitHeight + 4
        readonly property int targetX: Math.max(290, m3Root.sw - targetW - 18)
        readonly property int targetY: m3Root.compactH ? 48 : Math.max(54, m3Root.sh - targetH - 86)

        function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

        x: targetX; y: targetY; width: targetW; height: targetH
        color: "transparent"

        Component.onCompleted: syncGeo()
        onTargetXChanged: syncGeo()
        onTargetYChanged: syncGeo()
        onTargetWChanged: syncGeo()
        onTargetHChanged: syncGeo()
        onVisibleChanged: if (visible) syncGeo()

        Column {
            id: m3RightCol
            width: parent.width
            spacing: m3Root.compactH ? 8 : 10

            // Stacked Bold M3 Clock + Date Pill
            Item {
                width: parent.width
                height: m3Root.compactH ? 128 : 148

                Column {
                    anchors.horizontalCenter: parent.horizontalCenter
                    spacing: m3Root.compactH ? -14 : -16

                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(m3Root.nowDate, "HH")
                        font.family: "Segoe UI"; font.pixelSize: m3Root.compactH ? 46 : 54; font.weight: Font.Black
                        color: m3Root.m3Primary
                    }
                    Text {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: Qt.formatDateTime(m3Root.nowDate, "mm")
                        font.family: "Segoe UI"; font.pixelSize: m3Root.compactH ? 46 : 54; font.weight: Font.Black
                        color: m3Root.m3OnSurface
                    }
                }

                Rectangle {
                    anchors.horizontalCenter: parent.horizontalCenter
                    anchors.bottom: parent.bottom
                    width: 74; height: 42; radius: 13
                    color: m3Root.m3SurfaceHigh
                    border.width: 1; border.color: m3Root.m3Outline
                    Column {
                        anchors.centerIn: parent
                        spacing: 0
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(m3Root.nowDate, "MMM ddd").toUpperCase()
                            font.family: "Consolas"; font.pixelSize: 10; font.weight: Font.Bold
                            color: m3Root.m3Primary
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(m3Root.nowDate, "dd")
                            font.family: "Segoe UI"; font.pixelSize: 18; font.weight: Font.Black
                            color: m3Root.m3OnSurface
                        }
                    }
                }
            }

            // Media Player Card
            Rectangle {
                width: parent.width
                height: m3Root.compactH ? 96 : 108
                radius: 22
                color: m3Root.m3Surface
                border.width: 1; border.color: m3Root.m3Outline

                Row {
                    anchors.fill: parent
                    anchors.margins: 10
                    spacing: 10

                    Rectangle {
                        width: parent.height; height: parent.height; radius: 16
                        color: m3Root.m3SurfaceHigh
                        clip: true
                        Image {
                            anchors.fill: parent
                            visible: MediaService.artUrl !== ""
                            source: MediaService.artUrl
                            fillMode: Image.PreserveAspectCrop
                            smooth: true
                        }
                        Text {
                            visible: MediaService.artUrl === ""
                            anchors.centerIn: parent
                            font.family: m3Root.iconFontName; font.pixelSize: 28
                            text: m3Root.hasSymbols ? "music_note" : "♫"
                            color: m3Root.m3Primary
                        }
                    }

                    Item {
                        width: parent.width - parent.height - 10
                        height: parent.height

                        Column {
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                            spacing: 1
                            Text {
                                width: parent.width; elide: Text.ElideRight
                                text: MediaService.hasSession && MediaService.title !== "" ? MediaService.title : "Nothing Playing"
                                font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Bold
                                color: m3Root.m3OnSurface
                            }
                            Text {
                                width: parent.width; elide: Text.ElideRight
                                text: MediaService.hasSession && MediaService.artist !== "" ? MediaService.artist : "Play audio from any app"
                                font.family: "Segoe UI"; font.pixelSize: 11
                                color: m3Root.m3OnSurfaceVariant
                            }
                        }

                        Row {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            spacing: 6

                            Rectangle {
                                width: 30; height: 30; radius: 15
                                anchors.verticalCenter: parent.verticalCenter
                                color: m3PrevMa.containsMouse ? m3Root.m3SurfaceBright : m3Root.m3SurfaceHigh
                                Text {
                                    anchors.centerIn: parent
                                    font.family: m3Root.iconFontName; font.pixelSize: 17
                                    text: m3Root.hasSymbols ? "skip_previous" : "⏮"
                                    color: m3Root.m3OnSurface
                                }
                                MouseArea {
                                    id: m3PrevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.callLater(() => MediaService.previous())
                                }
                            }

                            Rectangle {
                                width: 38; height: 38; radius: 13
                                color: m3Root.m3Primary
                                Text {
                                    anchors.centerIn: parent
                                    font.family: m3Root.iconFontName; font.pixelSize: 20
                                    text: m3Root.hasSymbols ? (MediaService.isPlaying ? "pause" : "play_arrow") : (MediaService.isPlaying ? "❚❚" : "▶")
                                    color: m3Root.m3OnPrimary
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.callLater(() => MediaService.playPause())
                                }
                            }

                            Rectangle {
                                width: 30; height: 30; radius: 15
                                anchors.verticalCenter: parent.verticalCenter
                                color: m3NextMa.containsMouse ? m3Root.m3SurfaceBright : m3Root.m3SurfaceHigh
                                Text {
                                    anchors.centerIn: parent
                                    font.family: m3Root.iconFontName; font.pixelSize: 17
                                    text: m3Root.hasSymbols ? "skip_next" : "⏭"
                                    color: m3Root.m3OnSurface
                                }
                                MouseArea {
                                    id: m3NextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.callLater(() => MediaService.next())
                                }
                            }
                        }
                    }
                }
            }

            // Weather Card
            Rectangle {
                width: parent.width
                height: m3Root.compactH ? 96 : 106
                radius: 22
                color: m3Root.m3Surface
                border.width: 1; border.color: m3Root.m3Outline

                Column {
                    anchors.fill: parent
                    anchors.margins: 13
                    spacing: 6

                    Row {
                        width: parent.width
                        spacing: 10

                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            text: WeatherService.ready ? (WeatherService.temperature + "°C") : "--°C"
                            font.family: "Segoe UI"; font.pixelSize: m3Root.compactH ? 28 : 32; font.weight: Font.Bold
                            color: m3Root.m3OnSurface
                        }

                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 125
                            spacing: 1
                            Text {
                                width: parent.width; elide: Text.ElideRight
                                text: WeatherService.conditionText || "Fetching weather..."
                                font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                                color: m3Root.m3OnSurface
                            }
                            Text {
                                width: parent.width; elide: Text.ElideRight
                                text: WeatherService.city || "Open-Meteo"
                                font.family: "Segoe UI"; font.pixelSize: 11
                                color: m3Root.m3OnSurfaceVariant
                            }
                        }

                        Rectangle {
                            width: 36; height: 36; radius: 18
                            anchors.verticalCenter: parent.verticalCenter
                            color: m3Root.m3PrimaryContainer
                            Text {
                                anchors.centerIn: parent
                                font.family: m3Root.iconFontName; font.pixelSize: 20
                                text: m3Root.hasSymbols ? "cloud" : "☁"
                                color: m3Root.m3Primary
                            }
                        }
                    }

                    Row {
                        width: parent.width
                        spacing: 14
                        Text {
                            text: "Hum " + WeatherService.humidity + "%"
                            font.family: "Consolas"; font.pixelSize: 11; color: m3Root.m3OnSurfaceVariant
                        }
                        Text {
                            text: "Wind " + WeatherService.windSpeed + " km/h"
                            font.family: "Consolas"; font.pixelSize: 11; color: m3Root.m3OnSurfaceVariant
                        }
                        Text {
                            text: "☀ " + (WeatherService.sunrise || "--")
                            font.family: "Consolas"; font.pixelSize: 11; color: m3Root.m3Primary
                        }
                    }
                }

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.callLater(() => WeatherService.refresh())
                }
            }

            // Bottom System Gauges Trio (CPU / RAM / BAT or TEMP)
            Row {
                width: parent.width
                height: m3Root.compactH ? 96 : 108
                spacing: 8

                Repeater {
                    model: [
                        {
                            label: "CPU",
                            val: WindowTracker.cpuUsage + "%",
                            icon: "memory",
                            frac: Math.max(0.05, Math.min(1.0, WindowTracker.cpuUsage / 100.0))
                        },
                        {
                            label: "RAM",
                            val: WindowTracker.ramUsage + "%",
                            icon: "storage",
                            frac: Math.max(0.05, Math.min(1.0, WindowTracker.ramUsage / 100.0))
                        },
                        {
                            label: WindowTracker.hasBattery ? "BATTERY" : "GPU TEMP",
                            val: WindowTracker.hasBattery ? (WindowTracker.batteryPercent + "%") : (WindowTracker.gpuTemp > 0 ? (WindowTracker.gpuTemp + "°C") : (WindowTracker.cpuTemp + "°C")),
                            icon: WindowTracker.hasBattery ? "battery_full" : "thermostat",
                            frac: WindowTracker.hasBattery ? Math.max(0.05, WindowTracker.batteryPercent / 100.0) : Math.max(0.1, Math.min(1.0, (WindowTracker.gpuTemp > 0 ? WindowTracker.gpuTemp : 45) / 95.0))
                        }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: (m3RightWidgets.targetW - 16) / 3
                        height: m3Root.compactH ? 96 : 108
                        radius: 20
                        color: m3Root.m3Surface
                        border.width: 1; border.color: m3Root.m3Outline

                        Rectangle {
                            width: 30; height: 30; radius: 15
                            anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 9
                            color: m3Root.m3PrimaryContainer
                            Text {
                                anchors.centerIn: parent
                                font.family: m3Root.iconFontName; font.pixelSize: 16
                                text: m3Root.hasSymbols ? modelData.icon : "●"
                                color: m3Root.m3Primary
                            }
                        }

                        Column {
                            anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                            anchors.margins: 10
                            spacing: 3

                            Text {
                                text: modelData.val
                                font.family: "Segoe UI"; font.pixelSize: 20; font.weight: Font.Bold
                                color: m3Root.m3OnSurface
                            }
                            Text {
                                text: modelData.label
                                font.family: "Consolas"; font.pixelSize: 10; font.weight: Font.Bold
                                color: m3Root.m3OnSurfaceVariant
                            }
                            Rectangle {
                                width: parent.width; height: 5; radius: 2.5
                                color: m3Root.m3Background
                                Rectangle {
                                    height: parent.height; radius: 2.5
                                    width: parent.width * modelData.frac
                                    color: m3Root.m3Primary
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 4. M3 Rounded Bottom Dock (File Drop Supported)
    // =========================================================================
    PanelWindow {
        id: m3BottomDock
        visible: !m3Root.fullscreenActive
        acceptFileDrops: true
        blurBehind: true
        blurRadius: 26
        blurTint: m3Root.m3Background
        color: "transparent"

        readonly property int tileCount: m3Root.m3DockApps.length + 1
        readonly property int targetW: Math.max(160, Math.min(m3Root.sw - 80, tileCount * 48 + 28))
        readonly property int targetH: 58
        readonly property int targetX: Math.round((m3Root.sw - targetW) * 0.5)
        readonly property int targetY: Math.max(48, m3Root.sh - targetH - 12)

        function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

        x: targetX; y: targetY; width: targetW; height: targetH

        Component.onCompleted: syncGeo()
        onTargetXChanged: syncGeo()
        onTargetYChanged: syncGeo()
        onTargetWChanged: syncGeo()
        onTargetHChanged: syncGeo()
        onVisibleChanged: if (visible) syncGeo()

        onFilesDropped: files => {
            const list = files
            Qt.callLater(() => AppLauncher.pinDroppedFiles(list))
        }

        Rectangle {
            anchors.fill: parent
            radius: 22
            color: m3Root.m3Background
            border.width: 1; border.color: m3Root.m3Outline

            Row {
                anchors.centerIn: parent
                spacing: 6

                Repeater {
                    model: m3Root.m3DockApps
                    delegate: Item {
                        required property var modelData
                        width: 42; height: 42

                        Rectangle {
                            anchors.fill: parent
                            radius: 14
                            color: m3DockItemMa.containsMouse ? m3Root.m3SurfaceBright : (modelData.active ? m3Root.m3PrimaryContainer : "transparent")
                            border.width: modelData.active ? 1 : 0
                            border.color: m3Root.m3Primary

                            Image {
                                anchors.centerIn: parent
                                width: 28; height: 28
                                source: "image://winicon/" + encodeURIComponent(modelData.target)
                                smooth: true; mipmap: true
                                scale: m3DockItemMa.containsMouse ? 1.12 : 1.0
                                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            }

                            Rectangle {
                                visible: modelData.running
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                                width: modelData.active ? 14 : 6; height: 3; radius: 1.5
                                color: m3Root.m3Primary
                            }
                        }

                        MouseArea {
                            id: m3DockItemMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                const tgt = modelData.target
                                const nm = modelData.name || tgt
                                const args = modelData.args || ""
                                const run = !!modelData.running
                                const pin = !!modelData.pinned
                                Qt.callLater(() => {
                                    if (mouse.button === Qt.RightButton) {
                                        if (pin) AppLauncher.removePinnedByTarget(tgt)
                                        else AppLauncher.addPinnedApp(nm, tgt, "")
                                    } else {
                                        if (run) WindowTracker.activateOrToggle(tgt)
                                        else AppLauncher.launch(tgt, args)
                                    }
                                })
                            }
                        }
                    }
                }

                // Launcher Drawer Tile
                Item {
                    width: 42; height: 42
                    Rectangle {
                        anchors.fill: parent; radius: 14
                        color: m3DockDrawerMa.containsMouse ? m3Root.m3Primary : m3Root.m3SurfaceHigh
                        Text {
                            anchors.centerIn: parent
                            font.family: m3Root.iconFontName; font.pixelSize: 22
                            text: m3Root.hasSymbols ? "apps" : "⊞"
                            color: m3DockDrawerMa.containsMouse ? m3Root.m3OnPrimary : m3Root.m3Primary
                        }
                    }
                    MouseArea {
                        id: m3DockDrawerMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.callLater(() => {
                            if (m3Root.themeHub) m3Root.themeHub.spotlightOpen = !m3Root.themeHub.spotlightOpen
                        })
                    }
                }
            }
        }
    }
}
