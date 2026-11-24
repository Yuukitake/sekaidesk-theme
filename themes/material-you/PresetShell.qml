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
    readonly property real uiScale: Math.min(1.0, Math.max(0.74, (sh - 132) / 660.0))

    FontLoader {
        id: m3SymbolsFont
        source: m3Root.presetDirUrl !== "" ? (m3Root.presetDirUrl + "assets/MaterialSymbolsLite.ttf") : ""
    }
    readonly property string iconFontName: m3SymbolsFont.status === FontLoader.Ready ? m3SymbolsFont.name : "Segoe Fluent Icons"
    readonly property bool hasSymbols: m3SymbolsFont.status === FontLoader.Ready

    // =========================================================================
    // Material 3 Tonal Palette (end4-pC Appearance.qml structure)
    // =========================================================================
    readonly property color seedColor: themeHub ? themeHub.accentA : "#7AE0B8"
    readonly property real seedHue: (seedColor.hslHue >= 0 && seedColor.hslSaturation > 0.05) ? seedColor.hslHue : 0.43
    readonly property real secHue: (seedHue + 0.04) % 1.0
    readonly property real tertHue: (seedHue + 0.14) % 1.0
    readonly property real seedSat: Math.max(0.28, Math.min(0.68, seedColor.hslSaturation))

    readonly property color colLayer0: Qt.hsla(seedHue, seedSat * 0.25, 0.09, 0.88)
    readonly property color colLayer0Border: Qt.hsla(seedHue, seedSat * 0.28, 0.36, 0.42)
    readonly property color colLayer1: Qt.hsla(seedHue, seedSat * 0.28, 0.13, 0.90)
    readonly property color colOnLayer0: Qt.hsla(seedHue, 0.14, 0.92, 1.0)
    readonly property color colOnLayer1: Qt.hsla(seedHue, 0.16, 0.78, 1.0)

    readonly property color colPrimary: Qt.hsla(seedHue, Math.min(0.74, seedSat * 1.15), 0.78, 1.0)
    readonly property color colOnPrimary: Qt.hsla(seedHue, 0.45, 0.12, 1.0)
    readonly property color colPrimaryContainer: Qt.hsla(seedHue, seedSat * 0.48, 0.23, 0.92)
    readonly property color colOnPrimaryContainer: Qt.hsla(seedHue, 0.22, 0.93, 1.0)

    readonly property color colSecondary: Qt.hsla(secHue, seedSat * 0.82, 0.75, 1.0)
    readonly property color colSecondaryContainer: Qt.hsla(secHue, seedSat * 0.38, 0.24, 0.92)
    readonly property color colTertiary: Qt.hsla(tertHue, Math.min(0.70, seedSat * 0.95), 0.76, 1.0)
    readonly property color colTertiaryContainer: Qt.hsla(tertHue, seedSat * 0.40, 0.24, 0.92)
    readonly property color colSurfaceVariant: Qt.hsla(seedHue, seedSat * 0.22, 0.16, 0.85)
    readonly property color colOnSurfaceVariant: Qt.hsla(seedHue, 0.18, 0.82, 1.0)

    property bool dockPinned: true
    property int uptimeSeconds: 0
    property date nowDate: new Date()

    Timer {
        interval: 1000
        repeat: true
        running: !m3Root.fullscreenActive
        onTriggered: {
            m3Root.nowDate = new Date()
            m3Root.uptimeSeconds += 1
        }
    }

    function weatherQuip() {
        const desc = (WeatherService.conditionText || "").toLowerCase()
        if (desc.indexOf("rain") >= 0 || desc.indexOf("shower") >= 0)
            return { text: "• raining, grab a coffee", icon: "coffee", fb: "☕" }
        if (desc.indexOf("clear") >= 0 || desc.indexOf("sun") >= 0)
            return { text: "• good day to touch grass", icon: "eco", fb: "🌿" }
        if (desc.indexOf("cloud") >= 0 || desc.indexOf("overcast") >= 0)
            return { text: "• a bit cloudy today", icon: "cloud", fb: "☁" }
        if (desc.indexOf("snow") >= 0)
            return { text: "• snowing outside", icon: "ac_unit", fb: "❄" }
        if (WeatherService.conditionText !== "")
            return { text: "• " + WeatherService.conditionText.toLowerCase(), icon: "thermostat", fb: "🌡" }
        return { text: "• a bit cloudy today", icon: "cloud", fb: "☁" }
    }

    function wmoSymbol(code) {
        const c = Number(code) || 0
        if (c === 0) return "clear_day"
        if (c <= 3) return "partly_cloudy_day"
        if (c === 45 || c === 48) return "foggy"
        if ((c >= 51 && c <= 67) || (c >= 80 && c <= 82)) return "rainy"
        if ((c >= 71 && c <= 77) || c === 85 || c === 86) return "ac_unit"
        if (c >= 95) return "thunderstorm"
        return "cloud"
    }

    function fmtWorldTime(d, offsetHours) {
        let h = d.getUTCHours() + offsetHours
        while (h < 0) h += 24
        while (h >= 24) h -= 24
        const m = d.getUTCMinutes()
        const isDay = (h >= 6 && h < 18)
        const ap = h >= 12 ? "PM" : "AM"
        const h12 = (h % 12 === 0) ? 12 : (h % 12)
        return {
            text: (h12 < 10 ? "0" : "") + h12 + ":" + (m < 10 ? "0" : "") + m + " " + ap,
            isDay: isDay
        }
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
    // 1. end4-pC Translucent Pill Top Bar (38px, Primary Screen Top)
    // =========================================================================
    PanelWindow {
        id: m3BarWin
        visible: !m3Root.fullscreenActive
        readonly property int targetX: 0
        readonly property int targetY: 0
        readonly property int targetW: m3Root.sw
        readonly property int targetH: 38

        function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

        x: targetX; y: targetY; width: targetW; height: targetH
        reserveTopBar: !m3Root.fullscreenActive
        reserveEdge: "top"
        reserveHeight: m3Root.fullscreenActive ? 0 : 38
        blurBehind: true
        blurRadius: 24
        blurTint: m3Root.colLayer0
        color: "transparent"

        Component.onCompleted: syncGeo()
        onTargetXChanged: syncGeo()
        onTargetYChanged: syncGeo()
        onTargetWChanged: syncGeo()
        onTargetHChanged: syncGeo()
        onVisibleChanged: if (visible) syncGeo()

        Rectangle {
            anchors.fill: parent
            color: m3Root.colLayer0

            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 1; color: m3Root.colLayer0Border
            }

            // Left: System Icons + Active Window
            Row {
                anchors.left: parent.left; anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 12

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: m3Root.iconFontName; font.pixelSize: 16
                        text: m3Root.hasSymbols ? (SystemControl.wifiEnabled ? "wifi" : "wifi_off") : "📶"
                        color: SystemControl.wifiEnabled ? m3Root.colOnLayer0 : m3Root.colOnLayer1
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => SystemControl.toggleWifi()) }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: m3Root.iconFontName; font.pixelSize: 16
                        text: m3Root.hasSymbols ? (SystemControl.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled") : "ᛒ"
                        color: SystemControl.bluetoothEnabled ? m3Root.colPrimary : m3Root.colOnLayer1
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => SystemControl.toggleBluetooth()) }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: m3Root.iconFontName; font.pixelSize: 16
                        text: m3Root.hasSymbols ? (AudioService.masterMuted ? "volume_off" : "volume_up") : "🔊"
                        color: AudioService.masterMuted ? "#FFB4AB" : m3Root.colOnLayer0
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => AudioService.toggleMasterMute()) }
                    }
                }

                Rectangle {
                    width: 1; height: 14; anchors.verticalCenter: parent.verticalCenter
                    color: m3Root.colLayer0Border
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    width: Math.min(260, implicitWidth)
                    elide: Text.ElideRight
                    text: WindowTracker.activeAppName !== "" ? WindowTracker.activeAppName : "Desktop"
                    font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                    color: m3Root.colOnLayer0
                }
            }

            // Center: Weather + Workspaces Dots + Date/Clock (exact end4-pC middle row)
            Row {
                anchors.centerIn: parent
                spacing: 12

                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 5
                    visible: WeatherService.ready
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: m3Root.iconFontName; font.pixelSize: 16
                        text: m3Root.hasSymbols ? m3Root.wmoSymbol(WeatherService.weatherCode) : "☁"
                        color: m3Root.colOnLayer0
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        text: WeatherService.temperature + "°C"
                        font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                        color: m3Root.colOnLayer0
                    }
                }

                // M3 Workspace Dots Capsule
                Row {
                    anchors.verticalCenter: parent.verticalCenter
                    spacing: 6
                    Repeater {
                        model: 5
                        delegate: Rectangle {
                            required property int index
                            anchors.verticalCenter: parent.verticalCenter
                            width: index === 0 ? 18 : 14
                            height: 14; radius: 7
                            color: index === 0 ? m3Root.colOnLayer0 : Qt.rgba(1, 1, 1, 0.16)
                            Text {
                                visible: index === 0
                                anchors.centerIn: parent
                                text: "1"
                                font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.Black
                                color: m3Root.colOnPrimary
                            }
                        }
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(m3Root.nowDate, "ddd, dd/MM · hh:mm AP")
                    font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                    color: m3Root.colOnLayer0
                }
            }

            // Right: Media Pill + Presets Store + Quick Panel
            Row {
                anchors.right: parent.right; anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 8

                Rectangle {
                    height: 26
                    width: Math.min(200, m3BarMediaLbl.implicitWidth + 36)
                    radius: 13
                    color: m3Root.colSurfaceVariant
                    Row {
                        anchors.centerIn: parent; spacing: 6
                        Text {
                            anchors.verticalCenter: parent.verticalCenter
                            font.family: m3Root.iconFontName; font.pixelSize: 14
                            text: m3Root.hasSymbols ? (MediaService.hasSession && MediaService.isPlaying ? "pause" : "music_note") : "♪"
                            color: m3Root.colPrimary
                        }
                        Text {
                            id: m3BarMediaLbl
                            anchors.verticalCenter: parent.verticalCenter
                            width: Math.min(150, implicitWidth)
                            elide: Text.ElideRight
                            text: (MediaService.hasSession && MediaService.title !== "") ? MediaService.title : "No media"
                            font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.DemiBold
                            color: m3Root.colOnLayer1
                        }
                    }
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.callLater(() => MediaService.playPause())
                    }
                }

                Rectangle {
                    height: 26; width: m3BarPresetTxt.implicitWidth + 20; radius: 13
                    color: m3BarPresetMa.containsMouse ? m3Root.colPrimary : m3Root.colPrimaryContainer
                    Text {
                        id: m3BarPresetTxt
                        anchors.centerIn: parent
                        text: "Presets"
                        font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold
                        color: m3BarPresetMa.containsMouse ? m3Root.colOnPrimary : m3Root.colOnPrimaryContainer
                    }
                    MouseArea {
                        id: m3BarPresetMa
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
                    height: 26; width: 28; radius: 13
                    color: m3BarQpMa.containsMouse ? m3Root.colPrimary : m3Root.colLayer1
                    Text {
                        anchors.centerIn: parent
                        font.family: m3Root.iconFontName; font.pixelSize: 15
                        text: m3Root.hasSymbols ? "tune" : "⚙"
                        color: m3BarQpMa.containsMouse ? m3Root.colOnPrimary : m3Root.colOnLayer0
                    }
                    MouseArea {
                        id: m3BarQpMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.callLater(() => m3Root.requestQuickPanel())
                    }
                }
            }
        }
    }

    // =========================================================================
    // 2. Left Desktop Stack: UserCardWidget + WorldClockWidget (1:1 end4-pC)
    // =========================================================================
    PanelWindow {
        id: m3LeftWin
        visible: !m3Root.fullscreenActive
        desktopLayer: true
        readonly property real k: m3Root.uiScale
        readonly property int targetX: Math.round(18 * k)
        readonly property int targetY: 50
        readonly property int targetW: Math.round(276 * k)
        readonly property int targetH: Math.round((252 + 12 + 252) * k) + 4

        function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

        x: targetX; y: targetY; width: targetW; height: targetH
        color: "transparent"

        Component.onCompleted: syncGeo()
        onTargetXChanged: syncGeo()
        onTargetYChanged: syncGeo()
        onTargetWChanged: syncGeo()
        onTargetHChanged: syncGeo()
        onVisibleChanged: if (visible) syncGeo()

        Item {
            width: 276
            height: 516
            transformOrigin: Item.TopLeft
            scale: m3LeftWin.k

            Column {
                width: 276
                spacing: 12

                // ---- UserCardWidget.qml (276 x 252, radius 30) ----
                Rectangle {
                    width: 276; height: 252
                    radius: 30
                    color: Qt.rgba(m3Root.colLayer1.r, m3Root.colLayer1.g, m3Root.colLayer1.b, 0.72)
                    border.width: 1; border.color: m3Root.colLayer0Border

                    // Inner PrimaryContainer Box (exact 240px wide, y = 80)
                    Rectangle {
                        id: ucContentBox
                        x: 18
                        y: 66
                        width: 240
                        height: 168
                        radius: 18
                        color: m3Root.colPrimaryContainer

                        Column {
                            anchors {
                                top: parent.top; topMargin: 44
                                left: parent.left; leftMargin: 16
                                right: parent.right; rightMargin: 16
                            }
                            spacing: 10

                            // weatherQuip() row
                            Row {
                                width: parent.width
                                spacing: 6
                                Text {
                                    font.family: m3Root.iconFontName; font.pixelSize: 15
                                    text: m3Root.hasSymbols ? m3Root.weatherQuip().icon : m3Root.weatherQuip().fb
                                    color: m3Root.colOnPrimaryContainer
                                    opacity: 0.85
                                }
                                Text {
                                    width: parent.width - 22; elide: Text.ElideRight
                                    text: m3Root.weatherQuip().text
                                    font.family: "Segoe UI"; font.pixelSize: 12
                                    color: m3Root.colOnPrimaryContainer
                                    opacity: 0.88
                                }
                            }

                            // Pill Lock + Circular Settings + Circular Power
                            Row {
                                width: parent.width
                                spacing: 8

                                Rectangle {
                                    width: parent.width - 96; height: 40; radius: 20
                                    color: ucLockMa.containsMouse ? m3Root.colPrimary : m3Root.colOnPrimaryContainer
                                    Row {
                                        anchors.centerIn: parent; spacing: 5
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            font.family: m3Root.iconFontName; font.pixelSize: 16
                                            text: m3Root.hasSymbols ? "lock" : "🔒"
                                            color: m3Root.colPrimaryContainer
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: "Lock"
                                            font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                                            color: m3Root.colPrimaryContainer
                                        }
                                    }
                                    MouseArea {
                                        id: ucLockMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.callLater(() => SystemControl.lockScreen())
                                    }
                                }

                                Rectangle {
                                    width: 40; height: 40; radius: 20
                                    color: ucSetMa.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                                    border.width: 1; border.color: m3Root.colOnPrimaryContainer
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: m3Root.iconFontName; font.pixelSize: 17
                                        text: m3Root.hasSymbols ? "settings" : "⚙"
                                        color: m3Root.colOnPrimaryContainer
                                    }
                                    MouseArea {
                                        id: ucSetMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
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
                                    width: 40; height: 40; radius: 20
                                    color: ucPwrMa.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                                    border.width: 1; border.color: m3Root.colOnPrimaryContainer
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: m3Root.iconFontName; font.pixelSize: 17
                                        text: m3Root.hasSymbols ? "power_settings_new" : "⏻"
                                        color: m3Root.colOnPrimaryContainer
                                    }
                                    MouseArea {
                                        id: ucPwrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.callLater(() => m3Root.requestQuickPanel())
                                    }
                                }
                            }
                        }
                    }

                    // Circular Avatar Overlapping Top Edge + User@Host Header
                    Row {
                        x: 24; y: 18
                        width: 228
                        spacing: 12

                        Rectangle {
                            width: 64; height: 64; radius: 32
                            color: m3Root.colLayer0
                            border.width: 2; border.color: m3Root.colPrimary
                            clip: true
                            Image {
                                anchors.fill: parent; anchors.margins: 2
                                source: "qrc:/qml/icons/author-pfp.png"
                                fillMode: Image.PreserveAspectCrop; smooth: true
                            }
                        }

                        Column {
                            anchors.top: parent.top; anchors.topMargin: 8
                            width: 152
                            spacing: 1
                            Text {
                                width: parent.width; elide: Text.ElideRight
                                text: (WindowTracker.userName || "User") + "@" + (WindowTracker.machineName || "PC")
                                font.family: "Segoe UI"; font.pixelSize: 14; font.weight: Font.Bold
                                color: "#FFFFFF"
                            }
                            Text {
                                width: parent.width; elide: Text.ElideRight
                                text: "Up • " + (WindowTracker.uptimeText || "0m")
                                font.family: "Segoe UI"; font.pixelSize: 11
                                color: m3Root.colOnLayer1
                            }
                        }
                    }
                }

                // ---- WorldClockWidget.qml (276 x 252, radius 30) ----
                Rectangle {
                    width: 276; height: 252
                    radius: 30
                    color: m3Root.colPrimaryContainer
                    border.width: 1; border.color: m3Root.colLayer0Border

                    Column {
                        anchors.fill: parent
                        anchors.margins: 14
                        spacing: 8

                        // City + Settings Header
                        Item {
                            width: parent.width; height: 28
                            Row {
                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                spacing: 4
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    font.family: m3Root.iconFontName; font.pixelSize: 18
                                    text: m3Root.hasSymbols ? "location_on" : "📍"
                                    color: m3Root.colOnPrimaryContainer; opacity: 0.7
                                }
                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 180; elide: Text.ElideRight
                                    text: WeatherService.city || "Local Time"
                                    font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Medium
                                    color: m3Root.colOnPrimaryContainer
                                }
                            }
                            Rectangle {
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                width: 28; height: 28; radius: 14
                                color: Qt.rgba(m3Root.colLayer0.r, m3Root.colLayer0.g, m3Root.colLayer0.b, 0.35)
                                Text {
                                    anchors.centerIn: parent
                                    font.family: m3Root.iconFontName; font.pixelSize: 14
                                    text: m3Root.hasSymbols ? "settings" : "⚙"
                                    color: m3Root.colOnSurfaceVariant
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.callLater(() => {
                                        if (m3Root.themeHub) {
                                            m3Root.themeHub.landscapeContent = "settings"
                                            m3Root.themeHub.settingsSection = "presets"
                                            m3Root.themeHub.settingsOpen = true
                                        }
                                    })
                                }
                            }
                        }

                        // Large Right-Aligned Local Clock + Date
                        Column {
                            width: parent.width
                            spacing: -4
                            Text {
                                width: parent.width; horizontalAlignment: Text.AlignRight
                                text: Qt.formatDateTime(m3Root.nowDate, "hh:mm AP")
                                font.family: "Segoe UI"; font.pixelSize: 38; font.weight: Font.Bold
                                color: m3Root.colOnPrimaryContainer
                            }
                            Text {
                                width: parent.width; horizontalAlignment: Text.AlignRight
                                text: Qt.formatDateTime(m3Root.nowDate, "dddd, MMMM d yyyy")
                                font.family: "Segoe UI"; font.pixelSize: 11
                                color: m3Root.colOnPrimaryContainer; opacity: 0.72
                            }
                        }

                        // 2x2 World City Cards (120 x 52, day/night tinting matching end4-pC)
                        Grid {
                            width: parent.width
                            columns: 2; columnSpacing: 6; rowSpacing: 6

                            Repeater {
                                model: [
                                    { city: "Tokyo", tz: "+9", off: 9 },
                                    { city: "Seoul", tz: "+9", off: 9 },
                                    { city: "London", tz: "+0", off: 0 },
                                    { city: "New York", tz: "-5", off: -5 }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property var wt: m3Root.fmtWorldTime(m3Root.nowDate, modelData.off)
                                    readonly property color fg: wt.isDay ? m3Root.colOnPrimary : m3Root.colOnLayer0
                                    width: 120; height: 54; radius: 14
                                    color: wt.isDay
                                           ? m3Root.colPrimary
                                           : Qt.rgba(m3Root.colLayer0.r, m3Root.colLayer0.g, m3Root.colLayer0.b, 0.45)

                                    Column {
                                        anchors.fill: parent; anchors.margins: 8; spacing: 2
                                        Row {
                                            width: parent.width
                                            Text {
                                                width: parent.width - 26; elide: Text.ElideRight
                                                text: modelData.city
                                                font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Medium
                                                color: fg
                                            }
                                            Text {
                                                width: 26; horizontalAlignment: Text.AlignRight
                                                text: modelData.tz
                                                font.family: "Consolas"; font.pixelSize: 10
                                                color: fg; opacity: 0.65
                                            }
                                        }
                                        Item {
                                            width: parent.width; height: 18
                                            Text {
                                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                                text: wt.text
                                                font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Bold
                                                color: fg
                                            }
                                            Text {
                                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                                font.family: m3Root.iconFontName; font.pixelSize: 12
                                                text: m3Root.hasSymbols ? (wt.isDay ? "wb_sunny" : "bedtime") : (wt.isDay ? "☀" : "☾")
                                                color: fg
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

    // =========================================================================
    // 3. Right Desktop Stack: DigitalClock + Media + Weather + Resources (1:1)
    // =========================================================================
    PanelWindow {
        id: m3RightWin
        visible: !m3Root.fullscreenActive
        desktopLayer: true
        readonly property real k: m3Root.uiScale
        readonly property int targetW: Math.round(420 * k)
        readonly property int rawH: 158 + 12 + 120 + 12 + 120 + 12 + 120
        readonly property int targetH: Math.round(rawH * k) + 4
        readonly property int targetX: Math.max(Math.round(310 * k), m3Root.sw - targetW - Math.round(20 * k))
        readonly property int targetY: Math.max(46, m3Root.sh - targetH - 76)

        function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

        x: targetX; y: targetY; width: targetW; height: targetH
        color: "transparent"

        Component.onCompleted: syncGeo()
        onTargetXChanged: syncGeo()
        onTargetYChanged: syncGeo()
        onTargetWChanged: syncGeo()
        onTargetHChanged: syncGeo()
        onVisibleChanged: if (visible) syncGeo()

        Item {
            width: 420
            height: m3RightWin.rawH
            transformOrigin: Item.TopLeft
            scale: m3RightWin.k

            Column {
                width: 420
                spacing: 12

                // ---- DigitalClock.qml (Stacked HH / mm + RectangleDate) ----
                Item {
                    width: 420; height: 158

                    Column {
                        anchors.horizontalCenter: parent.horizontalCenter
                        spacing: -18

                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(m3Root.nowDate, "HH")
                            font.family: "Segoe UI"; font.pixelSize: 58; font.weight: Font.Black
                            color: m3Root.colPrimary
                        }
                        Text {
                            anchors.horizontalCenter: parent.horizontalCenter
                            text: Qt.formatDateTime(m3Root.nowDate, "mm")
                            font.family: "Segoe UI"; font.pixelSize: 58; font.weight: Font.Black
                            color: m3Root.colOnPrimaryContainer
                        }
                    }

                    Rectangle {
                        anchors.horizontalCenter: parent.horizontalCenter
                        anchors.bottom: parent.bottom
                        width: 78; height: 46; radius: 14
                        color: m3Root.colLayer1
                        border.width: 1; border.color: m3Root.colLayer0Border
                        Column {
                            anchors.centerIn: parent; spacing: 0
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDateTime(m3Root.nowDate, "MMM ddd").toUpperCase()
                                font.family: "Consolas"; font.pixelSize: 10; font.weight: Font.Bold
                                color: m3Root.colPrimary
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: Qt.formatDateTime(m3Root.nowDate, "dd")
                                font.family: "Segoe UI"; font.pixelSize: 20; font.weight: Font.Black
                                color: m3Root.colOnLayer0
                            }
                        }
                    }
                }

                // ---- MediaWidget.qml (1x3: 420 x 120, radius 30, Cookie12Sided Play) ----
                Rectangle {
                    width: 420; height: 120
                    radius: 30
                    color: m3Root.colPrimaryContainer
                    border.width: 1; border.color: m3Root.colLayer0Border
                    clip: true

                    // Left flush rounded album art square
                    Rectangle {
                        id: mwArtBox
                        x: 0; y: 0; width: 120; height: 120
                        topLeftRadius: 30; bottomLeftRadius: 30
                        topRightRadius: 0; bottomRightRadius: 0
                        color: m3Root.colLayer1
                        clip: true

                        Image {
                            anchors.fill: parent
                            visible: MediaService.artUrl !== ""
                            source: MediaService.artUrl
                            fillMode: Image.PreserveAspectCrop; smooth: true
                        }
                        Text {
                            visible: MediaService.artUrl === ""
                            anchors.centerIn: parent
                            font.family: m3Root.iconFontName; font.pixelSize: 38
                            text: m3Root.hasSymbols ? "music_note" : "♫"
                            color: m3Root.colOnPrimaryContainer; opacity: 0.78
                        }
                    }

                    Item {
                        x: 136; y: 12
                        width: 270; height: 96

                        Column {
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right
                            spacing: 2
                            Text {
                                width: parent.width; elide: Text.ElideRight
                                text: (MediaService.hasSession && MediaService.artist !== "") ? MediaService.artist : "Play"
                                font.family: "Segoe UI"; font.pixelSize: 15; font.weight: Font.DemiBold
                                color: m3Root.colOnPrimaryContainer
                            }
                            Text {
                                width: parent.width; elide: Text.ElideRight
                                text: (MediaService.hasSession && MediaService.title !== "") ? MediaService.title : "Something"
                                font.family: "Segoe UI"; font.pixelSize: 13
                                color: m3Root.colOnPrimaryContainer; opacity: 0.65
                            }
                        }

                        // end4-pC translucent controlsPill with real MaterialShape Cookie12Sided
                        Rectangle {
                            anchors.right: parent.right
                            anchors.bottom: parent.bottom
                            width: mwCtrlRow.implicitWidth + 12
                            height: 44; radius: 22
                            color: Qt.rgba(m3Root.colOnPrimaryContainer.r, m3Root.colOnPrimaryContainer.g, m3Root.colOnPrimaryContainer.b, 0.12)

                            Row {
                                id: mwCtrlRow
                                anchors.centerIn: parent
                                spacing: 4

                                Rectangle {
                                    width: 34; height: 34; radius: 17
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: mwPrevMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: m3Root.iconFontName; font.pixelSize: 18
                                        text: m3Root.hasSymbols ? "skip_previous" : "⏮"
                                        color: m3Root.colOnPrimaryContainer
                                    }
                                    MouseArea {
                                        id: mwPrevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.callLater(() => MediaService.previous())
                                    }
                                }

                                MaterialShapeBadge {
                                    anchors.verticalCenter: parent.verticalCenter
                                    shape: MaterialShape.Shape.Cookie12Sided
                                    color: m3Root.colPrimary
                                    colSymbol: m3Root.colOnPrimary
                                    iconFontFamily: m3Root.iconFontName
                                    useSymbolFont: m3Root.hasSymbols
                                    text: MediaService.isPlaying ? "pause" : "play_arrow"
                                    fallbackText: MediaService.isPlaying ? "❚❚" : "▶"
                                    iconSize: 22
                                    padding: 9
                                    implicitWidth: 40; implicitHeight: 40

                                    MouseArea {
                                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.callLater(() => MediaService.playPause())
                                    }
                                }

                                Rectangle {
                                    width: 34; height: 34; radius: 17
                                    anchors.verticalCenter: parent.verticalCenter
                                    color: mwNextMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                                    Text {
                                        anchors.centerIn: parent
                                        font.family: m3Root.iconFontName; font.pixelSize: 18
                                        text: m3Root.hasSymbols ? "skip_next" : "⏭"
                                        color: m3Root.colOnPrimaryContainer
                                    }
                                    MouseArea {
                                        id: mwNextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                        onClicked: Qt.callLater(() => MediaService.next())
                                    }
                                }
                            }
                        }
                    }
                }

                // ---- WeatherWidget.qml (1x3: 420 x 120, radius 30, Cookie12Sided + 4 pills) ----
                Rectangle {
                    width: 420; height: 120
                    radius: 30
                    color: m3Root.colPrimaryContainer
                    border.width: 1; border.color: m3Root.colLayer0Border

                    Column {
                        anchors.fill: parent; anchors.margins: 14; spacing: 8

                        Item {
                            width: parent.width; height: 48
                            Row {
                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                                spacing: 12

                                Text {
                                    anchors.verticalCenter: parent.verticalCenter
                                    text: WeatherService.ready ? (WeatherService.temperature + "°C") : "--°C"
                                    font.family: "Segoe UI"; font.pixelSize: 38; font.weight: Font.Bold
                                    color: m3Root.colPrimary
                                }

                                Column {
                                    anchors.verticalCenter: parent.verticalCenter
                                    width: 195
                                    spacing: -1
                                    Text {
                                        width: parent.width; elide: Text.ElideRight
                                        text: WeatherService.conditionText || "Fetching weather..."
                                        font.family: "Segoe UI"; font.pixelSize: 14; font.weight: Font.DemiBold
                                        color: m3Root.colOnPrimaryContainer
                                    }
                                    Text {
                                        width: parent.width; elide: Text.ElideRight
                                        text: WeatherService.city || "--"
                                        font.family: "Segoe UI"; font.pixelSize: 12
                                        color: m3Root.colOnPrimaryContainer; opacity: 0.65
                                    }
                                }
                            }

                            MaterialShapeBadge {
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                shape: MaterialShape.Shape.Cookie12Sided
                                color: m3Root.colPrimary
                                colSymbol: m3Root.colOnPrimary
                                iconFontFamily: m3Root.iconFontName
                                useSymbolFont: m3Root.hasSymbols
                                text: m3Root.wmoSymbol(WeatherService.weatherCode)
                                fallbackText: "☁"
                                iconSize: 24
                                padding: 10
                                implicitWidth: 46; implicitHeight: 46
                            }
                        }

                        Row {
                            width: parent.width; height: 36; spacing: 6
                            Repeater {
                                model: [
                                    { ic: "humidity_mid", fb: "💧", txt: WeatherService.humidity + "%" },
                                    { ic: "rainy",        fb: "🌧", txt: WeatherService.precipProb + "%" },
                                    { ic: "air",          fb: "💨", txt: WeatherService.windSpeed + " km/h" },
                                    { ic: "wb_twilight",  fb: "☀",  txt: WeatherService.sunrise || "--" }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    width: (392 - 18) / 4; height: 36; radius: 14
                                    color: m3Root.colSurfaceVariant
                                    Row {
                                        anchors.centerIn: parent; spacing: 5
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            font.family: m3Root.iconFontName; font.pixelSize: 15
                                            text: m3Root.hasSymbols ? modelData.ic : modelData.fb
                                            color: m3Root.colPrimary
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter
                                            text: modelData.txt
                                            font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold
                                            color: m3Root.colOnSurfaceVariant
                                        }
                                    }
                                }
                            }
                        }
                    }

                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.callLater(() => WeatherService.refresh())
                    }
                }

                // ---- ResourcesWidget.qml (3x StatCard: Gem / Cookie4Sided / Cookie12Sided) ----
                Row {
                    width: 420; height: 120; spacing: 12

                    Repeater {
                        model: [
                            {
                                ic: "planner_review", fb: "⚙",
                                val: WindowTracker.cpuUsage + "%",
                                lbl: "CPU",
                                shape: MaterialShape.Shape.Gem,
                                bg: m3Root.colPrimaryContainer,
                                sc: m3Root.colPrimary
                            },
                            {
                                ic: "memory", fb: "▦",
                                val: WindowTracker.ramUsage + "%",
                                lbl: "RAM",
                                shape: MaterialShape.Shape.Cookie4Sided,
                                bg: m3Root.colSecondaryContainer,
                                sc: m3Root.colSecondary
                            },
                            {
                                ic: WindowTracker.hasBattery ? "battery_full" : "thermostat",
                                fb: WindowTracker.hasBattery ? "🔋" : "🌡",
                                val: WindowTracker.hasBattery ? (WindowTracker.batteryPercent + "%") : ((WindowTracker.gpuTemp > 0 ? WindowTracker.gpuTemp : WindowTracker.cpuTemp) + "°C"),
                                lbl: WindowTracker.hasBattery ? "Battery" : "Temp",
                                shape: MaterialShape.Shape.Cookie12Sided,
                                bg: m3Root.colTertiaryContainer,
                                sc: m3Root.colTertiary
                            }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: 132; height: 120; radius: 30
                            color: modelData.bg
                            border.width: 1; border.color: m3Root.colLayer0Border

                            MaterialShapeBadge {
                                anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 14
                                shape: modelData.shape
                                color: modelData.sc
                                colSymbol: m3Root.colOnPrimary
                                iconFontFamily: m3Root.iconFontName
                                useSymbolFont: m3Root.hasSymbols
                                text: modelData.ic
                                fallbackText: modelData.fb
                                iconSize: 17
                                padding: 7
                                implicitWidth: 34; implicitHeight: 34
                            }

                            Column {
                                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                anchors.margins: 14
                                spacing: -2
                                Text {
                                    text: modelData.val
                                    font.family: "Segoe UI"; font.pixelSize: 28; font.weight: Font.Bold
                                    color: m3Root.colOnPrimaryContainer
                                }
                                Text {
                                    text: modelData.lbl
                                    font.family: "Segoe UI"; font.pixelSize: 12
                                    color: m3Root.colOnPrimaryContainer; opacity: 0.65
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 4. end4-pC Translucent Dock (Bottom Centered, File Drop Supported)
    // =========================================================================
    PanelWindow {
        id: m3DockWin
        visible: !m3Root.fullscreenActive
        acceptFileDrops: true
        blurBehind: true
        blurRadius: 26
        blurTint: m3Root.colLayer0
        color: "transparent"

        readonly property int tileCount: m3Root.m3DockApps.length + 2
        readonly property int targetW: Math.max(200, Math.min(m3Root.sw - 80, tileCount * 46 + 44))
        readonly property int targetH: 58
        readonly property int targetX: Math.round((m3Root.sw - targetW) * 0.5)
        readonly property int targetY: Math.max(48, m3Root.sh - targetH - 10)

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
            color: m3Root.colLayer0
            border.width: 1; border.color: m3Root.colLayer0Border

            Row {
                anchors.centerIn: parent
                spacing: 6

                // Pin Button (DockPinButton.qml)
                Rectangle {
                    width: 38; height: 38; radius: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: m3DockPinMa.containsMouse ? m3Root.colSurfaceVariant : "transparent"
                    Text {
                        anchors.centerIn: parent
                        font.family: m3Root.iconFontName; font.pixelSize: 18
                        text: m3Root.hasSymbols ? "keep" : "📌"
                        color: m3Root.dockPinned ? m3Root.colPrimary : m3Root.colOnLayer1
                    }
                    MouseArea {
                        id: m3DockPinMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.callLater(() => { m3Root.dockPinned = !m3Root.dockPinned })
                    }
                }

                Rectangle {
                    width: 1; height: 24; anchors.verticalCenter: parent.verticalCenter
                    color: m3Root.colLayer0Border
                }

                // App Icons
                Repeater {
                    model: m3Root.m3DockApps
                    delegate: Item {
                        required property var modelData
                        width: 40; height: 40
                        anchors.verticalCenter: parent.verticalCenter

                        Rectangle {
                            anchors.fill: parent
                            radius: 12
                            color: m3DockItMa.containsMouse ? m3Root.colSurfaceVariant : (modelData.active ? m3Root.colPrimaryContainer : "transparent")

                            Image {
                                anchors.centerIn: parent
                                width: 26; height: 26
                                source: "image://winicon/" + encodeURIComponent(modelData.target)
                                smooth: true; mipmap: true
                                scale: m3DockItMa.containsMouse ? 1.12 : 1.0
                                Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                            }

                            Rectangle {
                                visible: modelData.running
                                anchors.horizontalCenter: parent.horizontalCenter
                                anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                                width: modelData.active ? 14 : 6; height: 3; radius: 1.5
                                color: m3Root.colPrimary
                            }
                        }

                        MouseArea {
                            id: m3DockItMa
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

                Rectangle {
                    width: 1; height: 24; anchors.verticalCenter: parent.verticalCenter
                    color: m3Root.colLayer0Border
                }

                // DockAppsButton.qml
                Rectangle {
                    width: 40; height: 40; radius: 12
                    anchors.verticalCenter: parent.verticalCenter
                    color: m3DockAppsMa.containsMouse ? m3Root.colPrimary : m3Root.colLayer1
                    Text {
                        anchors.centerIn: parent
                        font.family: m3Root.iconFontName; font.pixelSize: 20
                        text: m3Root.hasSymbols ? "apps" : "⊞"
                        color: m3DockAppsMa.containsMouse ? m3Root.colOnPrimary : m3Root.colPrimary
                    }
                    MouseArea {
                        id: m3DockAppsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.callLater(() => {
                            if (m3Root.themeHub) m3Root.themeHub.spotlightOpen = !m3Root.themeHub.spotlightOpen
                        })
                    }
                }
            }
        }
    }
}
