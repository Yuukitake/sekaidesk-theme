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

    // Tell SekaiDesk shell this preset owns QuickPanel (Ctrl+Alt+A) & App Launcher (Alt+Space)
    readonly property bool handlesQuickPanel: true
    readonly property bool handlesLauncher: true

    signal requestQuickPanel()
    signal requestLauncher()

    property bool sidebarOpen: false
    property double sidebarClosedAt: 0
    property string sidebarSubView: "" // "" | "wifi" | "bt" | "widgets"
    property string wifiPwSsid: ""
    property bool wifiPwVisible: false

    property bool launcherOpen: false
    property double launcherClosedAt: 0
    property string launcherQuery: ""

    property bool weatherPopupOpen: false
    property double weatherClosedAt: 0

    property bool calendarPopupOpen: false
    property double calendarClosedAt: 0
    property int calYear: (new Date()).getFullYear()
    property int calMonth: (new Date()).getMonth() // 0..11

    property bool wallpaperPickerOpen: false
    property double wallpaperClosedAt: 0

    property int widgetResetGen: 0
    property int widgetVisGen: 0

    function toggleQuickPanel(fromHotkey) {
        launcherOpen = false
        weatherPopupOpen = false
        calendarPopupOpen = false
        wallpaperPickerOpen = false
        if (!fromHotkey && !sidebarOpen && (Date.now() - sidebarClosedAt) < 280)
            return
        if (sidebarOpen) {
            sidebarClosedAt = Date.now()
            sidebarOpen = false
        } else {
            sidebarOpen = true
        }
    }

    function toggleLauncher(fromHotkey) {
        sidebarOpen = false
        weatherPopupOpen = false
        calendarPopupOpen = false
        wallpaperPickerOpen = false
        if (!fromHotkey && !launcherOpen && (Date.now() - launcherClosedAt) < 280)
            return
        if (launcherOpen) {
            launcherClosedAt = Date.now()
            launcherOpen = false
        } else {
            launcherOpen = true
        }
    }

    function toggleWeatherPopup() {
        sidebarOpen = false
        launcherOpen = false
        calendarPopupOpen = false
        wallpaperPickerOpen = false
        if (!weatherPopupOpen && (Date.now() - weatherClosedAt) < 280)
            return
        if (weatherPopupOpen) {
            weatherClosedAt = Date.now()
            weatherPopupOpen = false
        } else {
            weatherPopupOpen = true
            WeatherService.refresh()
        }
    }

    function toggleCalendarPopup() {
        sidebarOpen = false
        launcherOpen = false
        weatherPopupOpen = false
        wallpaperPickerOpen = false
        if (!calendarPopupOpen && (Date.now() - calendarClosedAt) < 280)
            return
        if (calendarPopupOpen) {
            calendarClosedAt = Date.now()
            calendarPopupOpen = false
        } else {
            calYear = nowDate.getFullYear()
            calMonth = nowDate.getMonth()
            calendarPopupOpen = true
        }
    }

    function toggleWallpaperPicker() {
        sidebarOpen = false
        launcherOpen = false
        weatherPopupOpen = false
        calendarPopupOpen = false
        if (!wallpaperPickerOpen && (Date.now() - wallpaperClosedAt) < 280)
            return
        if (wallpaperPickerOpen) {
            wallpaperClosedAt = Date.now()
            wallpaperPickerOpen = false
        } else {
            WallpaperService.refresh()
            wallpaperPickerOpen = true
        }
    }

    function isWidgetShown(key) {
        const _v = widgetVisGen
        return ConfigStore.boolValue("m3.widget." + key + ".visible", true)
    }

    function setWidgetShown(key, on) {
        ConfigStore.set("m3.widget." + key + ".visible", !!on)
        widgetVisGen += 1
    }

    function resetWidgetPositions() {
        const keys = ["userCard", "worldClock", "digitalClock", "media", "weather", "resources"]
        for (let i = 0; i < keys.length; ++i) {
            ConfigStore.set("m3.widget." + keys[i] + ".x", -9999)
            ConfigStore.set("m3.widget." + keys[i] + ".y", -9999)
            ConfigStore.set("m3.widget." + keys[i] + ".visible", true)
        }
        widgetResetGen += 1
        widgetVisGen += 1
    }

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
    // Material 3 Tonal Palette (end4-pC Appearance.qml)
    // =========================================================================
    readonly property color seedColor: themeHub ? themeHub.accentA : "#7AE0B8"
    readonly property real seedHue: (seedColor.hslHue >= 0 && seedColor.hslSaturation > 0.05) ? seedColor.hslHue : 0.43
    readonly property real secHue: (seedHue + 0.04) % 1.0
    readonly property real tertHue: (seedHue + 0.14) % 1.0
    readonly property real seedSat: Math.max(0.28, Math.min(0.68, seedColor.hslSaturation))

    readonly property color colLayer0: Qt.hsla(seedHue, seedSat * 0.25, 0.09, 0.90)
    readonly property color colLayer0Clear: Qt.hsla(seedHue, seedSat * 0.26, 0.09, 0.62)
    readonly property color colLayer0Border: Qt.hsla(seedHue, seedSat * 0.28, 0.42, 0.36)
    readonly property color colLayer1: Qt.hsla(seedHue, seedSat * 0.28, 0.14, 0.94)
    readonly property color colLayer2: Qt.hsla(seedHue, seedSat * 0.30, 0.19, 0.95)
    readonly property color colOnLayer0: Qt.hsla(seedHue, 0.14, 0.94, 1.0)
    readonly property color colOnLayer1: Qt.hsla(seedHue, 0.16, 0.80, 1.0)

    readonly property color colPrimary: Qt.hsla(seedHue, Math.min(0.74, seedSat * 1.15), 0.78, 1.0)
    readonly property color colOnPrimary: Qt.hsla(seedHue, 0.45, 0.12, 1.0)
    readonly property color colPrimaryContainer: Qt.hsla(seedHue, seedSat * 0.48, 0.23, 0.92)
    readonly property color colOnPrimaryContainer: Qt.hsla(seedHue, 0.22, 0.94, 1.0)

    readonly property color colSecondary: Qt.hsla(secHue, seedSat * 0.82, 0.75, 1.0)
    readonly property color colSecondaryContainer: Qt.hsla(secHue, seedSat * 0.38, 0.24, 0.92)
    readonly property color colTertiary: Qt.hsla(tertHue, Math.min(0.70, seedSat * 0.95), 0.76, 1.0)
    readonly property color colTertiaryContainer: Qt.hsla(tertHue, seedSat * 0.40, 0.24, 0.92)
    readonly property color colSurfaceVariant: Qt.hsla(seedHue, seedSat * 0.22, 0.17, 0.86)
    readonly property color colOnSurfaceVariant: Qt.hsla(seedHue, 0.18, 0.84, 1.0)

    readonly property bool dockPinned: themeHub ? !themeHub.dockAutoHide : true
    property date nowDate: new Date()

    Timer {
        interval: 1000
        repeat: true
        running: !m3Root.fullscreenActive
        onTriggered: m3Root.nowDate = new Date()
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

    readonly property var filteredApps: {
        const all = AppLauncher.installedApps || []
        const q = launcherQuery.trim().toLowerCase()
        if (q === "")
            return all
        const out = []
        for (let i = 0; i < all.length; ++i) {
            const a = all[i]
            if (!a || !a.name) continue
            if (a.name.toLowerCase().indexOf(q) >= 0)
                out.push(a)
        }
        return out
    }

    readonly property var calendarCells: {
        const cells = []
        const firstDay = new Date(calYear, calMonth, 1).getDay() // 0=Sun..6=Sat
        const monFirstOffset = (firstDay + 6) % 7
        const daysInMonth = new Date(calYear, calMonth + 1, 0).getDate()
        const prevMonthDays = new Date(calYear, calMonth, 0).getDate()
        const todayY = nowDate.getFullYear()
        const todayM = nowDate.getMonth()
        const todayD = nowDate.getDate()

        for (let p = monFirstOffset - 1; p >= 0; --p) {
            cells.push({ day: prevMonthDays - p, curMonth: false, isToday: false })
        }
        for (let d = 1; d <= daysInMonth; ++d) {
            cells.push({
                day: d,
                curMonth: true,
                isToday: (calYear === todayY && calMonth === todayM && d === todayD)
            })
        }
        while (cells.length < 42) {
            cells.push({ day: cells.length - (monFirstOffset + daysInMonth) + 1, curMonth: false, isToday: false })
        }
        return cells
    }

    // =========================================================================
    // Reusable Zero-Lag Draggable Desktop Widget (60fps throttled drag!)
    // =========================================================================
    component M3DraggableWidget: PanelWindow {
        id: dwWin
        required property string widgetKey
        required property int defaultX
        required property int defaultY
        required property int baseW
        required property int baseH

        readonly property real k: m3Root.uiScale
        readonly property int resetToken: m3Root.widgetResetGen
        readonly property bool isShown: m3Root.isWidgetShown(widgetKey)
        readonly property int savedX: {
            const _t = resetToken
            return ConfigStore.intValue("m3.widget." + widgetKey + ".x", -9999)
        }
        readonly property int savedY: {
            const _t = resetToken
            return ConfigStore.intValue("m3.widget." + widgetKey + ".y", -9999)
        }
        readonly property int targetX: (savedX >= 0 && savedX < m3Root.sw - 40) ? savedX : defaultX
        readonly property int targetY: (savedY >= 36 && savedY < m3Root.sh - 40) ? savedY : defaultY
        readonly property int targetW: Math.round(baseW * k)
        readonly property int targetH: Math.round(baseH * k)

        property bool draggingNow: false
        property double lastDragMs: 0

        function syncGeo() {
            if (!draggingNow)
                setPanelGeometry(targetX, targetY, targetW, targetH)
        }

        visible: !m3Root.fullscreenActive && isShown
        desktopLayer: true
        color: "transparent"

        Component.onCompleted: syncGeo()
        onTargetXChanged: syncGeo()
        onTargetYChanged: syncGeo()
        onTargetWChanged: syncGeo()
        onTargetHChanged: syncGeo()
        onVisibleChanged: if (visible) syncGeo()

        default property alias body: scaleHost.data

        Item {
            id: scaleHost
            width: dwWin.baseW
            height: dwWin.baseH
            transformOrigin: Item.TopLeft
            scale: dwWin.k

            MouseArea {
                id: dwDragMa
                anchors.fill: parent
                z: -10
                cursorShape: dwWin.draggingNow ? Qt.ClosedHandCursor : Qt.OpenHandCursor
                onPressed: {
                    dwWin.draggingNow = true
                    dwWin.lastDragMs = Date.now()
                    dwWin.beginNativeDrag(0, 44, m3Root.sw - 40, m3Root.sh - 40)
                }
                onPositionChanged: {
                    if (!dwWin.draggingNow)
                        return
                    const now = Date.now()
                    if ((now - dwWin.lastDragMs) >= 16) {
                        dwWin.lastDragMs = now
                        dwWin.stepNativeDrag()
                    }
                }
                onReleased: {
                    if (dwWin.draggingNow) {
                        dwWin.stepNativeDrag()
                        dwWin.endNativeDrag()
                        dwWin.draggingNow = false
                        ConfigStore.set("m3.widget." + dwWin.widgetKey + ".x", dwWin.x)
                        ConfigStore.set("m3.widget." + dwWin.widgetKey + ".y", dwWin.y)
                    }
                }
                onCanceled: {
                    if (dwWin.draggingNow) {
                        dwWin.endNativeDrag()
                        dwWin.draggingNow = false
                    }
                }
            }
        }
    }

    // =========================================================================
    // 1. Adaptive Top Bar (Clear Pills <-> Solid Bar + Real Window Switcher + Popups)
    // =========================================================================
    PanelWindow {
        id: m3BarWin
        visible: !m3Root.fullscreenActive
        readonly property int targetX: 0
        readonly property int targetY: 0
        readonly property int targetW: m3Root.sw
        readonly property int targetH: 40

        readonly property bool barSolid: WindowTracker.desktopOccluded || WindowTracker.topOverlap
        property real solidK: barSolid ? 1.0 : 0.0
        Behavior on solidK {
            NumberAnimation { duration: 220; easing.type: Easing.OutCubic }
        }

        function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

        x: targetX; y: targetY; width: targetW; height: targetH
        reserveTopBar: !m3Root.fullscreenActive
        reserveEdge: "top"
        reserveHeight: m3Root.fullscreenActive ? 0 : 40
        blurBehind: false
        color: "transparent"

        Component.onCompleted: syncGeo()
        onTargetXChanged: syncGeo()
        onTargetYChanged: syncGeo()
        onTargetWChanged: syncGeo()
        onTargetHChanged: syncGeo()
        onVisibleChanged: if (visible) syncGeo()

        Item {
            anchors.fill: parent

            // Full-width solid bar backdrop (fades in smoothly when an app is open/occluding desktop)
            Rectangle {
                anchors.fill: parent
                color: m3Root.colLayer0
                opacity: m3BarWin.solidK
                Rectangle {
                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                    height: 1; color: m3Root.colLayer0Border
                }
            }

            // Left Module Cluster: Wi-Fi + BT + Mute + Active App
            Rectangle {
                anchors.left: parent.left; anchors.leftMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                height: 30; width: m3BarLeftRow.implicitWidth + 22
                radius: 15
                color: Qt.rgba(m3Root.colLayer0Clear.r, m3Root.colLayer0Clear.g, m3Root.colLayer0Clear.b, 0.62 * (1.0 - m3BarWin.solidK))
                border.width: 1
                border.color: Qt.rgba(m3Root.colLayer0Border.r, m3Root.colLayer0Border.g, m3Root.colLayer0Border.b, 0.36 * (1.0 - m3BarWin.solidK))

                Row {
                    id: m3BarLeftRow
                    anchors.centerIn: parent
                    spacing: 10

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: m3Root.iconFontName; font.pixelSize: 15
                        text: m3Root.hasSymbols ? (SystemControl.wifiEnabled ? "wifi" : "wifi_off") : "📶"
                        color: SystemControl.wifiEnabled ? m3Root.colOnLayer0 : m3Root.colOnLayer1
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.callLater(() => {
                                m3Root.launcherOpen = false
                                m3Root.weatherPopupOpen = false
                                m3Root.calendarPopupOpen = false
                                m3Root.sidebarSubView = "wifi"
                                m3Root.sidebarOpen = true
                                SystemControl.refreshWifi()
                            })
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: m3Root.iconFontName; font.pixelSize: 15
                        text: m3Root.hasSymbols ? (SystemControl.bluetoothEnabled ? "bluetooth" : "bluetooth_disabled") : "ᛒ"
                        color: SystemControl.bluetoothEnabled ? m3Root.colPrimary : m3Root.colOnLayer1
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.callLater(() => {
                                m3Root.launcherOpen = false
                                m3Root.weatherPopupOpen = false
                                m3Root.calendarPopupOpen = false
                                m3Root.sidebarSubView = "bt"
                                m3Root.sidebarOpen = true
                                SystemControl.refreshBluetooth()
                            })
                        }
                    }
                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        font.family: m3Root.iconFontName; font.pixelSize: 15
                        text: m3Root.hasSymbols ? (AudioService.masterMuted ? "volume_off" : "volume_up") : "🔊"
                        color: AudioService.masterMuted ? "#FFB4AB" : m3Root.colOnLayer0
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => AudioService.toggleMasterMute()) }
                    }

                    Rectangle { width: 1; height: 14; anchors.verticalCenter: parent.verticalCenter; color: m3Root.colLayer0Border }

                    Text {
                        anchors.verticalCenter: parent.verticalCenter
                        width: Math.min(190, implicitWidth)
                        elide: Text.ElideRight
                        text: WindowTracker.activeAppName !== "" ? WindowTracker.activeAppName : "Desktop"
                        font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                        color: m3Root.colOnLayer0
                    }
                }
            }

            // Center Module Cluster: Weather Button + Live Running Window Switcher + Date/Calendar Button
            Rectangle {
                anchors.centerIn: parent
                height: 30; width: m3BarCenterRow.implicitWidth + 20
                radius: 15
                color: Qt.rgba(m3Root.colLayer0Clear.r, m3Root.colLayer0Clear.g, m3Root.colLayer0Clear.b, 0.62 * (1.0 - m3BarWin.solidK))
                border.width: 1
                border.color: Qt.rgba(m3Root.colLayer0Border.r, m3Root.colLayer0Border.g, m3Root.colLayer0Border.b, 0.36 * (1.0 - m3BarWin.solidK))

                Row {
                    id: m3BarCenterRow
                    anchors.centerIn: parent
                    spacing: 8

                    // Interactive Weather Chip
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 24; width: m3BarWthRow.implicitWidth + 12; radius: 12
                        color: (m3Root.weatherPopupOpen || m3BarWthMa.containsMouse) ? m3Root.colPrimaryContainer : "transparent"
                        Row {
                            id: m3BarWthRow; anchors.centerIn: parent; spacing: 4
                            Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 15; text: m3Root.hasSymbols ? m3Root.wmoSymbol(WeatherService.weatherCode) : "☁"; color: m3Root.weatherPopupOpen ? m3Root.colPrimary : m3Root.colOnLayer0 }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: WeatherService.ready ? (WeatherService.temperature + "°C") : "--°"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold; color: m3Root.colOnLayer0 }
                        }
                        MouseArea {
                            id: m3BarWthMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.callLater(() => m3Root.toggleWeatherPopup())
                        }
                    }

                    Rectangle { width: 1; height: 14; anchors.verticalCenter: parent.verticalCenter; color: m3Root.colLayer0Border }

                    // Material 3 Workspace Switcher Dots (end4-pC style + real Windows Virtual Desktops)
                    Row {
                        anchors.verticalCenter: parent.verticalCenter
                        spacing: 6

                        Repeater {
                            model: Math.max(5, WindowTracker.virtualDesktopCount)
                            delegate: Item {
                                required property int index
                                readonly property bool isActive: index === WindowTracker.currentVirtualDesktop
                                readonly property bool exists: index < WindowTracker.virtualDesktopCount

                                anchors.verticalCenter: parent.verticalCenter
                                width: isActive ? 24 : 10
                                height: 18
                                Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                                Rectangle {
                                    anchors.centerIn: parent
                                    width: parent.isActive ? 24 : (parent.exists ? 10 : 8)
                                    height: parent.isActive ? 18 : (parent.exists ? 10 : 8)
                                    radius: height * 0.5
                                    color: parent.isActive
                                           ? m3Root.colPrimary
                                           : (parent.exists
                                              ? Qt.rgba(m3Root.colPrimary.r, m3Root.colPrimary.g, m3Root.colPrimary.b, m3WsMa.containsMouse ? 0.85 : 0.55)
                                              : Qt.rgba(1, 1, 1, m3WsMa.containsMouse ? 0.45 : 0.22))
                                    Behavior on width { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }
                                    Behavior on height { NumberAnimation { duration: 160; easing.type: Easing.OutCubic } }

                                    Text {
                                        visible: parent.parent.isActive
                                        anchors.centerIn: parent
                                        text: String(index + 1)
                                        font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.Bold
                                        color: m3Root.colOnPrimary
                                    }
                                }

                                MouseArea {
                                    id: m3WsMa
                                    anchors.fill: parent
                                    anchors.margins: -3
                                    hoverEnabled: true
                                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                                    cursorShape: Qt.PointingHandCursor
                                    onClicked: mouse => {
                                        if (mouse.button === Qt.RightButton)
                                            Qt.callLater(() => WindowTracker.openTaskView())
                                        else
                                            Qt.callLater(() => WindowTracker.switchVirtualDesktop(index))
                                    }
                                }
                            }
                        }
                    }

                    Rectangle { width: 1; height: 14; anchors.verticalCenter: parent.verticalCenter; color: m3Root.colLayer0Border }

                    // Interactive Clock / Calendar Chip
                    Rectangle {
                        anchors.verticalCenter: parent.verticalCenter
                        height: 24; width: m3BarClkTxt.implicitWidth + 14; radius: 12
                        color: (m3Root.calendarPopupOpen || m3BarClkMa.containsMouse) ? m3Root.colPrimaryContainer : "transparent"
                        Text {
                            id: m3BarClkTxt; anchors.centerIn: parent
                            text: Qt.formatDateTime(m3Root.nowDate, "ddd, dd/MM · hh:mm AP")
                            font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                            color: m3Root.calendarPopupOpen ? m3Root.colPrimary : m3Root.colOnLayer0
                        }
                        MouseArea {
                            id: m3BarClkMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.callLater(() => m3Root.toggleCalendarPopup())
                        }
                    }
                }
            }

            // Right Module Cluster: Media + Presets + Control Center
            Rectangle {
                anchors.right: parent.right; anchors.rightMargin: 12
                anchors.verticalCenter: parent.verticalCenter
                height: 30; width: m3BarRightRow.implicitWidth + 16
                radius: 15
                color: Qt.rgba(m3Root.colLayer0Clear.r, m3Root.colLayer0Clear.g, m3Root.colLayer0Clear.b, 0.62 * (1.0 - m3BarWin.solidK))
                border.width: 1
                border.color: Qt.rgba(m3Root.colLayer0Border.r, m3Root.colLayer0Border.g, m3Root.colLayer0Border.b, 0.36 * (1.0 - m3BarWin.solidK))

                Row {
                    id: m3BarRightRow
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        height: 22; width: Math.min(185, m3BarMediaLbl.implicitWidth + 28); radius: 11
                        color: m3Root.colSurfaceVariant
                        Row {
                            anchors.centerIn: parent; spacing: 5
                            Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 13; text: m3Root.hasSymbols ? (MediaService.hasSession && MediaService.isPlaying ? "pause" : "music_note") : "♪"; color: m3Root.colPrimary }
                            Text { id: m3BarMediaLbl; anchors.verticalCenter: parent.verticalCenter; width: Math.min(145, implicitWidth); elide: Text.ElideRight; text: (MediaService.hasSession && MediaService.title !== "") ? MediaService.title : "No media"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.DemiBold; color: m3Root.colOnLayer1 }
                        }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => MediaService.playPause()) }
                    }

                    Rectangle {
                        height: 22; width: 26; radius: 11
                        color: (m3Root.wallpaperPickerOpen || m3BarWpMa.containsMouse) ? m3Root.colPrimary : m3Root.colSurfaceVariant
                        Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 14; text: m3Root.hasSymbols ? "wallpaper" : "🖼"; color: (m3Root.wallpaperPickerOpen || m3BarWpMa.containsMouse) ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                        MouseArea { id: m3BarWpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => m3Root.toggleWallpaperPicker()) }
                    }

                    Rectangle {
                        height: 22; width: m3BarPresetTxt.implicitWidth + 16; radius: 11
                        color: m3BarPresetMa.containsMouse ? m3Root.colPrimary : m3Root.colPrimaryContainer
                        Text { id: m3BarPresetTxt; anchors.centerIn: parent; text: "Presets"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3BarPresetMa.containsMouse ? m3Root.colOnPrimary : m3Root.colOnPrimaryContainer }
                        MouseArea {
                            id: m3BarPresetMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
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
                        height: 22; width: 26; radius: 11
                        color: (m3Root.sidebarOpen || m3BarQpMa.containsMouse) ? m3Root.colPrimary : m3Root.colLayer1
                        Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 14; text: m3Root.hasSymbols ? "tune" : "⚙"; color: (m3Root.sidebarOpen || m3BarQpMa.containsMouse) ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                        MouseArea { id: m3BarQpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => m3Root.toggleQuickPanel(false)) }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 2. Draggable Widget 1: UserCardWidget (276 x 252)
    // =========================================================================
    M3DraggableWidget {
        widgetKey: "userCard"
        defaultX: Math.round(18 * m3Root.uiScale)
        defaultY: 50
        baseW: 276
        baseH: 252

        Rectangle {
            width: 276; height: 252; radius: 30
            color: Qt.rgba(m3Root.colLayer1.r, m3Root.colLayer1.g, m3Root.colLayer1.b, 0.72)
            border.width: 1; border.color: m3Root.colLayer0Border

            Rectangle {
                x: 18; y: 66; width: 240; height: 168; radius: 18
                color: m3Root.colPrimaryContainer

                Column {
                    anchors { top: parent.top; topMargin: 44; left: parent.left; leftMargin: 16; right: parent.right; rightMargin: 16 }
                    spacing: 10

                    Row {
                        width: parent.width; spacing: 6
                        Text { font.family: m3Root.iconFontName; font.pixelSize: 15; text: m3Root.hasSymbols ? m3Root.weatherQuip().icon : m3Root.weatherQuip().fb; color: m3Root.colOnPrimaryContainer; opacity: 0.85 }
                        Text { width: parent.width - 22; elide: Text.ElideRight; text: m3Root.weatherQuip().text; font.family: "Segoe UI"; font.pixelSize: 12; color: m3Root.colOnPrimaryContainer; opacity: 0.88 }
                    }

                    Row {
                        width: parent.width; spacing: 8
                        Rectangle {
                            width: parent.width - 96; height: 40; radius: 20
                            color: ucLockMa.containsMouse ? m3Root.colPrimary : m3Root.colOnPrimaryContainer
                            Row {
                                anchors.centerIn: parent; spacing: 5
                                Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 16; text: m3Root.hasSymbols ? "lock" : "🔒"; color: m3Root.colPrimaryContainer }
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Lock"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold; color: m3Root.colPrimaryContainer }
                            }
                            MouseArea { id: ucLockMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => SystemControl.lockScreen()) }
                        }
                        Rectangle {
                            width: 40; height: 40; radius: 20
                            color: ucSetMa.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                            border.width: 1; border.color: m3Root.colOnPrimaryContainer
                            Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 17; text: m3Root.hasSymbols ? "widgets" : "⊞"; color: m3Root.colOnPrimaryContainer }
                            MouseArea {
                                id: ucSetMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: Qt.callLater(() => {
                                    m3Root.launcherOpen = false
                                    m3Root.sidebarSubView = "widgets"
                                    m3Root.sidebarOpen = true
                                })
                            }
                        }
                        Rectangle {
                            width: 40; height: 40; radius: 20
                            color: ucPwrMa.containsMouse ? Qt.rgba(1, 1, 1, 0.14) : "transparent"
                            border.width: 1; border.color: m3Root.colOnPrimaryContainer
                            Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 17; text: m3Root.hasSymbols ? "power_settings_new" : "⏻"; color: m3Root.colOnPrimaryContainer }
                            MouseArea { id: ucPwrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => m3Root.toggleQuickPanel(false)) }
                        }
                    }
                }
            }

            Row {
                x: 24; y: 18; width: 228; spacing: 12
                Rectangle {
                    width: 64; height: 64; radius: 32; color: m3Root.colLayer0; border.width: 2; border.color: m3Root.colPrimary; clip: true
                    Image { anchors.fill: parent; anchors.margins: 2; source: "qrc:/qml/icons/author-pfp.png"; fillMode: Image.PreserveAspectCrop; smooth: true }
                }
                Column {
                    anchors.top: parent.top; anchors.topMargin: 8; width: 152; spacing: 1
                    Text { width: parent.width; elide: Text.ElideRight; text: (WindowTracker.userName || "User") + "@" + (WindowTracker.machineName || "PC"); font.family: "Segoe UI"; font.pixelSize: 14; font.weight: Font.Bold; color: "#FFFFFF" }
                    Text { width: parent.width; elide: Text.ElideRight; text: "Up • " + (WindowTracker.uptimeText || "0m"); font.family: "Segoe UI"; font.pixelSize: 11; color: m3Root.colOnLayer1 }
                }
            }
        }
    }

    // =========================================================================
    // 3. Draggable Widget 2: WorldClockWidget (276 x 252)
    // =========================================================================
    M3DraggableWidget {
        widgetKey: "worldClock"
        defaultX: Math.round(18 * m3Root.uiScale)
        defaultY: Math.round(50 + 264 * m3Root.uiScale)
        baseW: 276
        baseH: 252

        Rectangle {
            width: 276; height: 252; radius: 30
            color: m3Root.colPrimaryContainer; border.width: 1; border.color: m3Root.colLayer0Border

            Column {
                anchors.fill: parent; anchors.margins: 14; spacing: 8
                Item {
                    width: parent.width; height: 28
                    Row {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                        Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "location_on" : "📍"; color: m3Root.colOnPrimaryContainer; opacity: 0.7 }
                        Text { anchors.verticalCenter: parent.verticalCenter; width: 180; elide: Text.ElideRight; text: WeatherService.city || "Local Time"; font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Medium; color: m3Root.colOnPrimaryContainer }
                    }
                    Rectangle {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: 28; height: 28; radius: 14
                        color: Qt.rgba(m3Root.colLayer0.r, m3Root.colLayer0.g, m3Root.colLayer0.b, 0.35)
                        Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 14; text: m3Root.hasSymbols ? "tune" : "⚙"; color: m3Root.colOnSurfaceVariant }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => m3Root.toggleQuickPanel(false)) }
                    }
                }
                Column {
                    width: parent.width; spacing: -4
                    Text { width: parent.width; horizontalAlignment: Text.AlignRight; text: Qt.formatDateTime(m3Root.nowDate, "hh:mm AP"); font.family: "Segoe UI"; font.pixelSize: 38; font.weight: Font.Bold; color: m3Root.colOnPrimaryContainer }
                    Text { width: parent.width; horizontalAlignment: Text.AlignRight; text: Qt.formatDateTime(m3Root.nowDate, "dddd, MMMM d yyyy"); font.family: "Segoe UI"; font.pixelSize: 11; color: m3Root.colOnPrimaryContainer; opacity: 0.72 }
                }
                Grid {
                    width: parent.width; columns: 2; columnSpacing: 6; rowSpacing: 6
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
                            color: wt.isDay ? m3Root.colPrimary : Qt.rgba(m3Root.colLayer0.r, m3Root.colLayer0.g, m3Root.colLayer0.b, 0.45)

                            Column {
                                anchors.fill: parent; anchors.margins: 8; spacing: 2
                                Row {
                                    width: parent.width
                                    Text { width: parent.width - 26; elide: Text.ElideRight; text: modelData.city; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Medium; color: fg }
                                    Text { width: 26; horizontalAlignment: Text.AlignRight; text: modelData.tz; font.family: "Consolas"; font.pixelSize: 10; color: fg; opacity: 0.65 }
                                }
                                Item {
                                    width: parent.width; height: 18
                                    Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: wt.text; font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Bold; color: fg }
                                    Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 12; text: m3Root.hasSymbols ? (wt.isDay ? "wb_sunny" : "bedtime") : (wt.isDay ? "☀" : "☾"); color: fg }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 4. Draggable Widget 3: DigitalClock (Tight 148 x 158 Hitbox!)
    // =========================================================================
    M3DraggableWidget {
        widgetKey: "digitalClock"
        defaultX: Math.max(Math.round(310 * m3Root.uiScale), m3Root.sw - Math.round(440 * m3Root.uiScale)) + Math.round(136 * m3Root.uiScale)
        defaultY: Math.max(46, m3Root.sh - Math.round((158 + 12 + 120 + 12 + 120 + 12 + 120) * m3Root.uiScale) - 76)
        baseW: 148
        baseH: 158

        Item {
            width: 148; height: 158
            Column {
                anchors.horizontalCenter: parent.horizontalCenter; spacing: -18
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(m3Root.nowDate, "HH"); font.family: "Segoe UI"; font.pixelSize: 58; font.weight: Font.Black; color: m3Root.colPrimary }
                Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(m3Root.nowDate, "mm"); font.family: "Segoe UI"; font.pixelSize: 58; font.weight: Font.Black; color: m3Root.colOnPrimaryContainer }
            }
            Rectangle {
                anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom
                width: 78; height: 46; radius: 14; color: m3Root.colLayer1; border.width: 1; border.color: m3Root.colLayer0Border
                Column {
                    anchors.centerIn: parent; spacing: 0
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(m3Root.nowDate, "MMM ddd").toUpperCase(); font.family: "Consolas"; font.pixelSize: 10; font.weight: Font.Bold; color: m3Root.colPrimary }
                    Text { anchors.horizontalCenter: parent.horizontalCenter; text: Qt.formatDateTime(m3Root.nowDate, "dd"); font.family: "Segoe UI"; font.pixelSize: 20; font.weight: Font.Black; color: m3Root.colOnLayer0 }
                }
            }
        }
    }

    // =========================================================================
    // 5. Draggable Widget 4: MediaWidget (420 x 120, Cookie12Sided Play)
    // =========================================================================
    M3DraggableWidget {
        widgetKey: "media"
        defaultX: Math.max(Math.round(310 * m3Root.uiScale), m3Root.sw - Math.round(440 * m3Root.uiScale))
        defaultY: Math.max(46, m3Root.sh - Math.round((120 + 12 + 120 + 12 + 120) * m3Root.uiScale) - 76)
        baseW: 420
        baseH: 120

        Rectangle {
            width: 420; height: 120; radius: 30
            color: m3Root.colPrimaryContainer; border.width: 1; border.color: m3Root.colLayer0Border; clip: true

            Rectangle {
                x: 0; y: 0; width: 120; height: 120
                topLeftRadius: 30; bottomLeftRadius: 30; topRightRadius: 0; bottomRightRadius: 0
                color: m3Root.colLayer1; clip: true
                Image { anchors.fill: parent; visible: MediaService.artUrl !== ""; source: MediaService.artUrl; fillMode: Image.PreserveAspectCrop; smooth: true }
                Text { visible: MediaService.artUrl === ""; anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 38; text: m3Root.hasSymbols ? "music_note" : "♫"; color: m3Root.colOnPrimaryContainer; opacity: 0.78 }
            }

            Item {
                x: 136; y: 12; width: 270; height: 96
                Column {
                    anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; spacing: 2
                    Text { width: parent.width; elide: Text.ElideRight; text: (MediaService.hasSession && MediaService.artist !== "") ? MediaService.artist : "Play"; font.family: "Segoe UI"; font.pixelSize: 15; font.weight: Font.DemiBold; color: m3Root.colOnPrimaryContainer }
                    Text { width: parent.width; elide: Text.ElideRight; text: (MediaService.hasSession && MediaService.title !== "") ? MediaService.title : "Something"; font.family: "Segoe UI"; font.pixelSize: 13; color: m3Root.colOnPrimaryContainer; opacity: 0.65 }
                }

                Rectangle {
                    anchors.right: parent.right; anchors.bottom: parent.bottom
                    width: mwCtrlRow.implicitWidth + 12; height: 44; radius: 22
                    color: Qt.rgba(m3Root.colOnPrimaryContainer.r, m3Root.colOnPrimaryContainer.g, m3Root.colOnPrimaryContainer.b, 0.12)

                    Row {
                        id: mwCtrlRow; anchors.centerIn: parent; spacing: 4
                        Rectangle {
                            width: 34; height: 34; radius: 17; anchors.verticalCenter: parent.verticalCenter
                            color: mwPrevMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                            Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "skip_previous" : "⏮"; color: m3Root.colOnPrimaryContainer }
                            MouseArea { id: mwPrevMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => MediaService.previous()) }
                        }
                        MaterialShapeBadge {
                            anchors.verticalCenter: parent.verticalCenter
                            shape: MaterialShape.Shape.Cookie12Sided; color: m3Root.colPrimary; colSymbol: m3Root.colOnPrimary
                            iconFontFamily: m3Root.iconFontName; useSymbolFont: m3Root.hasSymbols
                            text: MediaService.isPlaying ? "pause" : "play_arrow"; fallbackText: MediaService.isPlaying ? "❚❚" : "▶"
                            iconSize: 22; padding: 9; implicitWidth: 40; implicitHeight: 40
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => MediaService.playPause()) }
                        }
                        Rectangle {
                            width: 34; height: 34; radius: 17; anchors.verticalCenter: parent.verticalCenter
                            color: mwNextMa.containsMouse ? Qt.rgba(1, 1, 1, 0.12) : "transparent"
                            Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "skip_next" : "⏭"; color: m3Root.colOnPrimaryContainer }
                            MouseArea { id: mwNextMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => MediaService.next()) }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 6. Draggable Widget 5: WeatherWidget (420 x 120, Cookie12Sided Badge)
    // =========================================================================
    M3DraggableWidget {
        widgetKey: "weather"
        defaultX: Math.max(Math.round(310 * m3Root.uiScale), m3Root.sw - Math.round(440 * m3Root.uiScale))
        defaultY: Math.max(46, m3Root.sh - Math.round((120 + 12 + 120) * m3Root.uiScale) - 76)
        baseW: 420
        baseH: 120

        Rectangle {
            width: 420; height: 120; radius: 30
            color: m3Root.colPrimaryContainer; border.width: 1; border.color: m3Root.colLayer0Border

            Column {
                anchors.fill: parent; anchors.margins: 14; spacing: 8
                Item {
                    width: parent.width; height: 48
                    Row {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                        Text { anchors.verticalCenter: parent.verticalCenter; text: WeatherService.ready ? (WeatherService.temperature + "°C") : "--°C"; font.family: "Segoe UI"; font.pixelSize: 38; font.weight: Font.Bold; color: m3Root.colPrimary }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter; width: 195; spacing: -1
                            Text { width: parent.width; elide: Text.ElideRight; text: WeatherService.conditionText || "Fetching weather..."; font.family: "Segoe UI"; font.pixelSize: 14; font.weight: Font.DemiBold; color: m3Root.colOnPrimaryContainer }
                            Text { width: parent.width; elide: Text.ElideRight; text: WeatherService.city || "--"; font.family: "Segoe UI"; font.pixelSize: 12; color: m3Root.colOnPrimaryContainer; opacity: 0.65 }
                        }
                    }
                    MaterialShapeBadge {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        shape: MaterialShape.Shape.Cookie12Sided; color: m3Root.colPrimary; colSymbol: m3Root.colOnPrimary
                        iconFontFamily: m3Root.iconFontName; useSymbolFont: m3Root.hasSymbols
                        text: m3Root.wmoSymbol(WeatherService.weatherCode); fallbackText: "☁"
                        iconSize: 24; padding: 10; implicitWidth: 46; implicitHeight: 46
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => WeatherService.refresh()) }
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
                            width: (392 - 18) / 4; height: 36; radius: 14; color: m3Root.colSurfaceVariant
                            Row {
                                anchors.centerIn: parent; spacing: 5
                                Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 15; text: m3Root.hasSymbols ? modelData.ic : modelData.fb; color: m3Root.colPrimary }
                                Text { anchors.verticalCenter: parent.verticalCenter; text: modelData.txt; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3Root.colOnSurfaceVariant }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 7. Draggable Widget 6: ResourcesWidget (420 x 120, 3x M3 Shape Cards)
    // =========================================================================
    M3DraggableWidget {
        widgetKey: "resources"
        defaultX: Math.max(Math.round(310 * m3Root.uiScale), m3Root.sw - Math.round(440 * m3Root.uiScale))
        defaultY: Math.max(46, m3Root.sh - Math.round(120 * m3Root.uiScale) - 76)
        baseW: 420
        baseH: 120

        Row {
            width: 420; height: 120; spacing: 12
            Repeater {
                model: [
                    { ic: "planner_review", fb: "⚙", val: WindowTracker.cpuUsage + "%", lbl: "CPU", shape: MaterialShape.Shape.Gem, bg: m3Root.colPrimaryContainer, sc: m3Root.colPrimary },
                    { ic: "memory", fb: "▦", val: WindowTracker.ramUsage + "%", lbl: "RAM", shape: MaterialShape.Shape.Cookie4Sided, bg: m3Root.colSecondaryContainer, sc: m3Root.colSecondary },
                    { ic: WindowTracker.hasBattery ? "battery_full" : "thermostat", fb: WindowTracker.hasBattery ? "🔋" : "🌡", val: WindowTracker.hasBattery ? (WindowTracker.batteryPercent + "%") : ((WindowTracker.gpuTemp > 0 ? WindowTracker.gpuTemp : WindowTracker.cpuTemp) + "°C"), lbl: WindowTracker.hasBattery ? "Battery" : "Temp", shape: MaterialShape.Shape.Cookie12Sided, bg: m3Root.colTertiaryContainer, sc: m3Root.colTertiary }
                ]
                delegate: Rectangle {
                    required property var modelData
                    width: 132; height: 120; radius: 30; color: modelData.bg; border.width: 1; border.color: m3Root.colLayer0Border
                    MaterialShapeBadge {
                        anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 14
                        shape: modelData.shape; color: modelData.sc; colSymbol: m3Root.colOnPrimary
                        iconFontFamily: m3Root.iconFontName; useSymbolFont: m3Root.hasSymbols
                        text: modelData.ic; fallbackText: modelData.fb; iconSize: 17; padding: 7; implicitWidth: 34; implicitHeight: 34
                    }
                    Column {
                        anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom; anchors.margins: 14; spacing: -2
                        Text { text: modelData.val; font.family: "Segoe UI"; font.pixelSize: 28; font.weight: Font.Bold; color: m3Root.colOnPrimaryContainer }
                        Text { text: modelData.lbl; font.family: "Segoe UI"; font.pixelSize: 12; color: m3Root.colOnPrimaryContainer; opacity: 0.65 }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 8. Pure Anti-Aliased Floating Dock + Real Auto-Hide / Dodge Active Windows
    // =========================================================================
    PanelWindow {
        id: m3DockWin
        visible: !m3Root.fullscreenActive && (hideProgress < 0.99 || WindowTracker.bottomEdgeHovered)
        acceptFileDrops: true
        blurBehind: false
        color: "transparent"

        readonly property int tileCount: m3Root.m3DockApps.length + 2
        readonly property int pillW: Math.max(200, Math.min(m3Root.sw - 80, tileCount * 46 + 44))
        readonly property int pillH: 54
        readonly property int targetW: pillW + 12
        readonly property int targetH: pillH + 16
        readonly property int targetX: Math.round((m3Root.sw - targetW) * 0.5)
        readonly property int targetY: Math.max(48, m3Root.sh - targetH)

        readonly property bool dockShouldHide: m3Root.fullscreenActive
            || (!m3Root.dockPinned
                && WindowTracker.dockOverlap
                && !WindowTracker.bottomEdgeHovered
                && !m3DockHover.hovered
                && !m3Root.launcherOpen)

        property real hideProgress: dockShouldHide ? 1.0 : 0.0
        Behavior on hideProgress {
            NumberAnimation { duration: 240; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] }
        }

        clickThrough: hideProgress > 0.85

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

        Item {
            anchors.fill: parent
            HoverHandler { id: m3DockHover }

            Rectangle {
                id: m3DockPill
                x: 6
                y: 4 + Math.round(m3DockWin.hideProgress * (m3DockWin.targetH + 8))
                width: m3DockWin.pillW
                height: m3DockWin.pillH
                radius: 27
                color: m3Root.colLayer0
                border.width: 1
                border.color: m3Root.colLayer0Border
                antialiasing: true

                Row {
                    anchors.centerIn: parent
                    spacing: 6

                    Rectangle {
                        width: 38; height: 38; radius: 19; anchors.verticalCenter: parent.verticalCenter
                        color: m3DockPinMa.containsMouse ? m3Root.colSurfaceVariant : (m3Root.dockPinned ? Qt.rgba(m3Root.colPrimary.r, m3Root.colPrimary.g, m3Root.colPrimary.b, 0.16) : "transparent")
                        Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "keep" : "📌"; color: m3Root.dockPinned ? m3Root.colPrimary : m3Root.colOnLayer1 }
                        MouseArea {
                            id: m3DockPinMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.callLater(() => { if (m3Root.themeHub) m3Root.themeHub.setDockAutoHide(!m3Root.themeHub.dockAutoHide) })
                        }
                    }

                    Rectangle { width: 1; height: 22; anchors.verticalCenter: parent.verticalCenter; color: m3Root.colLayer0Border }

                    Repeater {
                        model: m3Root.m3DockApps
                        delegate: Item {
                            required property var modelData
                            width: 40; height: 40; anchors.verticalCenter: parent.verticalCenter
                            Rectangle {
                                anchors.fill: parent; radius: 14
                                color: m3DockItMa.containsMouse ? m3Root.colSurfaceVariant : (modelData.active ? m3Root.colPrimaryContainer : "transparent")
                                Image {
                                    anchors.centerIn: parent; width: 26; height: 26; asynchronous: true; cache: true; smooth: true; mipmap: true
                                    source: "image://winicon/" + encodeURIComponent(modelData.target)
                                    scale: m3DockItMa.containsMouse ? 1.12 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
                                }
                                Rectangle {
                                    visible: modelData.running
                                    anchors.horizontalCenter: parent.horizontalCenter; anchors.bottom: parent.bottom; anchors.bottomMargin: 2
                                    width: modelData.active ? 14 : 6; height: 3; radius: 1.5; color: m3Root.colPrimary
                                }
                            }
                            MouseArea {
                                id: m3DockItMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; acceptedButtons: Qt.LeftButton | Qt.RightButton
                                onClicked: mouse => {
                                    const tgt = modelData.target; const nm = modelData.name || tgt; const args = modelData.args || ""
                                    const run = !!modelData.running; const pin = !!modelData.pinned
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

                    Rectangle { width: 1; height: 22; anchors.verticalCenter: parent.verticalCenter; color: m3Root.colLayer0Border }

                    Rectangle {
                        width: 40; height: 40; radius: 20; anchors.verticalCenter: parent.verticalCenter
                        color: (m3Root.launcherOpen || m3DockAppsMa.containsMouse) ? m3Root.colPrimary : m3Root.colLayer1
                        Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 20; text: m3Root.hasSymbols ? "apps" : "⊞"; color: (m3Root.launcherOpen || m3DockAppsMa.containsMouse) ? m3Root.colOnPrimary : m3Root.colPrimary }
                        MouseArea { id: m3DockAppsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => m3Root.toggleLauncher(false)) }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 9. Native end4-pC Right Sidebar (Wi-Fi/BT/Widgets + Reliable Esc Focus)
    // =========================================================================
    PanelWindow {
        id: m3SidebarWin
        property real slideK: m3Root.sidebarOpen ? 1.0 : 0.0
        Behavior on slideK {
            NumberAnimation { duration: 280; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] }
        }

        visible: (m3Root.sidebarOpen || slideK > 0.01) && !m3Root.fullscreenActive
        readonly property int targetW: 438
        readonly property int targetH: Math.max(500, m3Root.sh - 56)
        readonly property int targetX: m3Root.sw - targetW - 8
        readonly property int targetY: 46

        function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

        x: targetX; y: targetY; width: targetW; height: targetH
        blurBehind: false
        color: "transparent"

        Timer {
            id: sbFocusTimer
            interval: 45
            repeat: false
            onTriggered: {
                if (m3Root.sidebarOpen) {
                    m3SidebarWin.focusActivate()
                    sbCard.forceActiveFocus()
                    sbFocusRetryTimer.restart()
                }
            }
        }
        Timer {
            id: sbFocusRetryTimer
            interval: 120
            repeat: false
            onTriggered: {
                if (m3Root.sidebarOpen && m3Root.wifiPwSsid === "" && !sbCard.activeFocus) {
                    m3SidebarWin.focusActivate()
                    sbCard.forceActiveFocus()
                }
            }
        }

        Component.onCompleted: syncGeo()
        onTargetXChanged: syncGeo()
        onTargetYChanged: syncGeo()
        onTargetWChanged: syncGeo()
        onTargetHChanged: syncGeo()
        onVisibleChanged: {
            if (visible) {
                syncGeo()
                focusActivate()
                sbCard.forceActiveFocus()
                sbFocusTimer.restart()
            } else {
                sbFocusTimer.stop()
                sbFocusRetryTimer.stop()
                m3Root.sidebarSubView = ""
                m3Root.wifiPwSsid = ""
                m3Root.wifiPwVisible = false
                wifiPwInput.text = ""
            }
        }
        onWindowDeactivated: {
            if (m3Root.sidebarOpen) {
                m3Root.sidebarClosedAt = Date.now()
                m3Root.sidebarOpen = false
            }
        }

        Rectangle {
            id: sbCard
            focus: true
            x: Math.round((1.0 - m3SidebarWin.slideK) * (m3SidebarWin.targetW + 16))
            y: 0
            width: parent.width; height: parent.height
            radius: 26
            color: m3Root.colLayer1
            border.width: 1; border.color: m3Root.colLayer0Border
            clip: true

            Keys.onEscapePressed: {
                if (m3Root.wifiPwSsid !== "") {
                    m3Root.wifiPwSsid = ""
                    wifiPwInput.text = ""
                } else if (m3Root.sidebarSubView !== "") {
                    m3Root.sidebarSubView = ""
                } else {
                    m3Root.sidebarClosedAt = Date.now()
                    m3Root.sidebarOpen = false
                }
            }

            // ---- MAIN SIDEBAR VIEW ----
            Column {
                visible: m3Root.sidebarSubView === ""
                anchors.fill: parent; anchors.margins: 16; spacing: 12

                Item {
                    width: parent.width; height: 36
                    Row {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                        Rectangle {
                            width: 32; height: 32; radius: 16; color: m3Root.colPrimaryContainer
                            Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 17; text: m3Root.hasSymbols ? "bolt" : "⚡"; color: m3Root.colPrimary }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter; spacing: -1
                            Text { text: "Control Center"; font.family: "Segoe UI"; font.pixelSize: 14; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                            Text { text: "Up • " + (WindowTracker.uptimeText || "0m"); font.family: "Segoe UI"; font.pixelSize: 11; color: m3Root.colOnLayer1 }
                        }
                    }

                    Row {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                        Repeater {
                            model: [
                                { act: "wallpaper", ic: "wallpaper", fb: "🖼" },
                                { act: "widgets", ic: "widgets", fb: "⊞" },
                                { act: "settings", ic: "settings", fb: "⚙" },
                                { act: "lock", ic: "lock", fb: "🔒" },
                                { act: "sleep", ic: "bedtime", fb: "☾" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: 32; height: 32; radius: 16
                                color: sbHdrMa.containsMouse ? m3Root.colPrimaryContainer : m3Root.colLayer2
                                Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 16; text: m3Root.hasSymbols ? modelData.ic : modelData.fb; color: m3Root.colOnLayer0 }
                                MouseArea {
                                    id: sbHdrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const act = modelData.act
                                        Qt.callLater(() => {
                                            if (act === "wallpaper") { m3Root.toggleWallpaperPicker() }
                                            else if (act === "widgets") m3Root.sidebarSubView = "widgets"
                                            else if (act === "lock") { m3Root.sidebarClosedAt = Date.now(); m3Root.sidebarOpen = false; SystemControl.lockScreen() }
                                            else if (act === "sleep") { m3Root.sidebarClosedAt = Date.now(); m3Root.sidebarOpen = false; SystemControl.sleepPc() }
                                            else if (act === "settings" && m3Root.themeHub) {
                                                m3Root.sidebarClosedAt = Date.now()
                                                m3Root.sidebarOpen = false
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
                    }
                }

                // 3x2 Quick Toggles
                Grid {
                    width: parent.width; columns: 2; columnSpacing: 8; rowSpacing: 8

                    Rectangle {
                        width: (sbCard.width - 40) * 0.5; height: 54; radius: 27
                        color: SystemControl.wifiEnabled ? m3Root.colPrimary : m3Root.colLayer2
                        Row {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                            Rectangle {
                                width: 32; height: 32; radius: 16; anchors.verticalCenter: parent.verticalCenter
                                color: SystemControl.wifiEnabled ? Qt.rgba(0, 0, 0, 0.14) : m3Root.colLayer0
                                Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? (SystemControl.wifiEnabled ? "wifi" : "wifi_off") : "📶"; color: SystemControl.wifiEnabled ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => SystemControl.toggleWifi()) }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter; width: parent.width - 68; spacing: 0
                                Text { width: parent.width; elide: Text.ElideRight; text: "Wi-Fi"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: SystemControl.wifiEnabled ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                                Text { width: parent.width; elide: Text.ElideRight; text: SystemControl.wifiStatusText !== "" ? SystemControl.wifiStatusText : (SystemControl.wifiEnabled ? "Networks..." : "Off"); font.family: "Segoe UI"; font.pixelSize: 10; color: SystemControl.wifiEnabled ? m3Root.colOnPrimary : m3Root.colOnLayer1; opacity: 0.8 }
                            }
                            Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "chevron_right" : "›"; color: SystemControl.wifiEnabled ? m3Root.colOnPrimary : m3Root.colOnLayer1 }
                        }
                        MouseArea {
                            anchors.left: parent.left; anchors.leftMargin: 44; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.callLater(() => { m3Root.sidebarSubView = "wifi"; SystemControl.refreshWifi() })
                        }
                    }

                    Rectangle {
                        width: (sbCard.width - 40) * 0.5; height: 54; radius: 27
                        color: SystemControl.bluetoothEnabled ? m3Root.colPrimary : m3Root.colLayer2
                        Row {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                            Rectangle {
                                width: 32; height: 32; radius: 16; anchors.verticalCenter: parent.verticalCenter
                                color: SystemControl.bluetoothEnabled ? Qt.rgba(0, 0, 0, 0.14) : m3Root.colLayer0
                                Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "bluetooth" : "ᛒ"; color: SystemControl.bluetoothEnabled ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => SystemControl.toggleBluetooth()) }
                            }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter; width: parent.width - 68; spacing: 0
                                Text { width: parent.width; elide: Text.ElideRight; text: "Bluetooth"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: SystemControl.bluetoothEnabled ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                                Text { width: parent.width; elide: Text.ElideRight; text: SystemControl.bluetoothEnabled ? (SystemControl.bluetoothDevices.length + " dev") : "Off"; font.family: "Segoe UI"; font.pixelSize: 10; color: SystemControl.bluetoothEnabled ? m3Root.colOnPrimary : m3Root.colOnLayer1; opacity: 0.8 }
                            }
                            Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "chevron_right" : "›"; color: SystemControl.bluetoothEnabled ? m3Root.colOnPrimary : m3Root.colOnLayer1 }
                        }
                        MouseArea {
                            anchors.left: parent.left; anchors.leftMargin: 44; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom
                            cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.callLater(() => { m3Root.sidebarSubView = "bt"; SystemControl.refreshBluetooth() })
                        }
                    }

                    Repeater {
                        model: [
                            { id: "mute", title: AudioService.masterMuted ? "Muted" : "Sound On", sub: AudioService.masterVolume + "%", active: !AudioService.masterMuted, ic: AudioService.masterMuted ? "volume_off" : "volume_up", fb: "🔊" },
                            { id: "dock", title: "Auto-Hide Dock", sub: m3Root.dockPinned ? "Pinned" : "Dodge", active: !m3Root.dockPinned, ic: "dock_to_bottom", fb: "▁" },
                            { id: "widgets", title: "Desktop Widgets", sub: "Toggle & Reset", active: false, ic: "widgets", fb: "⊞" },
                            { id: "theme", title: "Dark Mode", sub: SystemControl.darkMode ? "Dark" : "Light", active: SystemControl.darkMode, ic: "dark_mode", fb: "☾" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: (sbCard.width - 40) * 0.5; height: 54; radius: 27
                            color: modelData.active ? m3Root.colPrimary : m3Root.colLayer2
                            Row {
                                anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 12; spacing: 10
                                Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 20; text: m3Root.hasSymbols ? modelData.ic : modelData.fb; color: modelData.active ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter; width: parent.width - 36; spacing: 0
                                    Text { width: parent.width; elide: Text.ElideRight; text: modelData.title; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: modelData.active ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                                    Text { width: parent.width; elide: Text.ElideRight; text: modelData.sub; font.family: "Segoe UI"; font.pixelSize: 10; color: modelData.active ? m3Root.colOnPrimary : m3Root.colOnLayer1; opacity: 0.8 }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const tid = modelData.id
                                    Qt.callLater(() => {
                                        if (tid === "mute") AudioService.toggleMasterMute()
                                        else if (tid === "dock" && m3Root.themeHub) m3Root.themeHub.setDockAutoHide(!m3Root.themeHub.dockAutoHide)
                                        else if (tid === "widgets") m3Root.sidebarSubView = "widgets"
                                        else if (tid === "theme") SystemControl.toggleDarkMode()
                                    })
                                }
                            }
                        }
                    }
                }

                // Volume + Brightness Sliders
                Rectangle {
                    width: parent.width; height: SystemControl.brightnessSupported ? 104 : 56; radius: 22; color: m3Root.colLayer2
                    Column {
                        anchors.fill: parent; anchors.margins: 12; spacing: 10
                        Item {
                            width: parent.width; height: 32
                            Rectangle {
                                anchors.fill: parent; radius: 16; color: m3Root.colLayer0
                                Rectangle { height: parent.height; radius: 16; width: Math.max(32, parent.width * (AudioService.masterVolume / 100.0)); color: m3Root.colPrimary }
                                Row {
                                    anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                                    Text { font.family: m3Root.iconFontName; font.pixelSize: 17; text: m3Root.hasSymbols ? "volume_up" : "🔊"; color: AudioService.masterVolume > 18 ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                                    Text { text: "Volume " + AudioService.masterVolume + "%"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: AudioService.masterVolume > 28 ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    function applyVol(mx) { const pct = Math.round(Math.max(0, Math.min(1, mx / Math.max(1, width))) * 100); Qt.callLater(() => AudioService.setMasterVolume(pct)) }
                                    onPressed: mouse => applyVol(mouse.x)
                                    onPositionChanged: mouse => { if (pressed) applyVol(mouse.x) }
                                }
                            }
                        }
                        Item {
                            visible: SystemControl.brightnessSupported; width: parent.width; height: 32
                            Rectangle {
                                anchors.fill: parent; radius: 16; color: m3Root.colLayer0
                                Rectangle { height: parent.height; radius: 16; width: Math.max(32, parent.width * (SystemControl.brightness / 100.0)); color: m3Root.colSecondary }
                                Row {
                                    anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                                    Text { font.family: m3Root.iconFontName; font.pixelSize: 17; text: m3Root.hasSymbols ? "brightness_6" : "☀"; color: SystemControl.brightness > 18 ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                                    Text { text: "Brightness " + SystemControl.brightness + "%"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: SystemControl.brightness > 28 ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    function applyBri(mx) { const pct = Math.round(Math.max(0, Math.min(1, mx / Math.max(1, width))) * 100); Qt.callLater(() => SystemControl.setBrightness(pct)) }
                                    onPressed: mouse => applyBri(mouse.x)
                                    onPositionChanged: mouse => { if (pressed) applyBri(mouse.x) }
                                }
                            }
                        }
                    }
                }

                // Quick Preset Switcher (smooth crossfade veil!)
                Row {
                    width: parent.width; height: 34; spacing: 6
                    Repeater {
                        model: ThemeStore.presets
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool isCur: ThemeStore.activePreset === modelData.id
                            readonly property bool isInst: !!modelData.installed
                            width: (sbCard.width - 32 - Math.max(0, ThemeStore.presets.length - 1) * 6) / Math.max(1, ThemeStore.presets.length)
                            height: 34; radius: 17
                            color: isCur ? m3Root.colPrimary : m3Root.colLayer2
                            Text {
                                anchors.centerIn: parent; width: parent.width - 10; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                text: modelData.id === "pjsk" ? "PJSK" : (modelData.id === "material-you" ? "Material You" : (modelData.name || modelData.id))
                                font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold
                                color: isCur ? m3Root.colOnPrimary : m3Root.colOnLayer0
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const pid = modelData.id; const inst = isInst
                                    Qt.callLater(() => {
                                        m3Root.sidebarClosedAt = Date.now()
                                        m3Root.sidebarOpen = false
                                        if (inst && m3Root.themeHub) {
                                            m3Root.themeHub.requestPresetSwitch(pid)
                                        } else if (m3Root.themeHub) {
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
                }

                // Notifications Center
                Rectangle {
                    width: parent.width; height: Math.max(110, sbCard.height - 392); radius: 22; color: m3Root.colLayer2; clip: true
                    Column {
                        anchors.fill: parent; anchors.margins: 14; spacing: 8
                        Item {
                            width: parent.width; height: 26
                            Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "Notifications (" + NotificationService.notifications.length + ")"; font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                            Rectangle {
                                visible: NotificationService.notifications.length > 0; anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                width: 68; height: 24; radius: 12; color: m3Root.colLayer0
                                Text { anchors.centerIn: parent; text: "Clear"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3Root.colPrimary }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => NotificationService.clearAll()) }
                            }
                        }
                        Text { visible: NotificationService.notifications.length === 0; width: parent.width; height: parent.height - 40; horizontalAlignment: Text.AlignHCenter; verticalAlignment: Text.AlignVCenter; text: "All caught up"; font.family: "Segoe UI"; font.pixelSize: 13; color: m3Root.colOnLayer1 }
                        ListView {
                            visible: NotificationService.notifications.length > 0; width: parent.width; height: parent.height - 34; spacing: 6; clip: true
                            model: NotificationService.notifications
                            delegate: Rectangle {
                                required property var modelData
                                width: ListView.view.width; height: 54; radius: 14; color: m3Root.colLayer1
                                Column {
                                    anchors.fill: parent; anchors.margins: 10; spacing: 2
                                    Text { width: parent.width; elide: Text.ElideRight; text: modelData.title || modelData.appName || "Notification"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                                    Text { width: parent.width; elide: Text.ElideRight; text: modelData.body || ""; font.family: "Segoe UI"; font.pixelSize: 11; color: m3Root.colOnLayer1 }
                                }
                            }
                        }
                    }
                }
            }

            // ---- SUB-VIEW: WI-FI NETWORKS & PASSWORD ----
            Column {
                visible: m3Root.sidebarSubView === "wifi"
                anchors.fill: parent; anchors.margins: 16; spacing: 12

                Item {
                    width: parent.width; height: 36
                    Row {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                        Rectangle {
                            width: 34; height: 34; radius: 17; color: m3Root.colLayer2
                            Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "arrow_back" : "←"; color: m3Root.colOnLayer0 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => { m3Root.sidebarSubView = ""; m3Root.wifiPwSsid = ""; sbCard.forceActiveFocus() }) }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: "Wi-Fi Networks"; font.family: "Segoe UI"; font.pixelSize: 15; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                            Text { text: SystemControl.wifiScanning ? "Scanning..." : (SystemControl.wifiStatusText || "Ready"); font.family: "Segoe UI"; font.pixelSize: 11; color: m3Root.colPrimary }
                        }
                    }
                    Row {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                        Rectangle {
                            width: 34; height: 34; radius: 17; color: m3Root.colLayer2
                            Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "refresh" : "↻"; color: m3Root.colOnLayer0 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => SystemControl.refreshWifi()) }
                        }
                        Rectangle {
                            width: 58; height: 34; radius: 17; color: SystemControl.wifiEnabled ? m3Root.colPrimary : m3Root.colLayer2
                            Text { anchors.centerIn: parent; text: SystemControl.wifiEnabled ? "ON" : "OFF"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Black; color: SystemControl.wifiEnabled ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => SystemControl.toggleWifi()) }
                        }
                    }
                }

                Rectangle {
                    visible: m3Root.wifiPwSsid !== ""
                    width: parent.width; height: 112; radius: 18
                    color: m3Root.colLayer2; border.width: 1; border.color: m3Root.colPrimary

                    Column {
                        anchors.fill: parent; anchors.margins: 12; spacing: 8
                        Text { width: parent.width; elide: Text.ElideRight; text: "Enter password for \"" + m3Root.wifiPwSsid + "\""; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                        Row {
                            width: parent.width; height: 34; spacing: 8
                            Rectangle {
                                width: parent.width - 134; height: 34; radius: 12; color: m3Root.colLayer0; border.width: 1; border.color: m3Root.colLayer0Border
                                TextInput {
                                    id: wifiPwInput
                                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 36; verticalAlignment: TextInput.AlignVCenter
                                    font.family: "Segoe UI"; font.pixelSize: 13; color: m3Root.colOnLayer0
                                    echoMode: m3Root.wifiPwVisible ? TextInput.Normal : TextInput.Password
                                    Keys.onEscapePressed: { m3Root.wifiPwSsid = ""; text = ""; sbCard.forceActiveFocus() }
                                    Keys.onReturnPressed: {
                                        const s = m3Root.wifiPwSsid; const pw = wifiPwInput.text
                                        if (pw !== "") { m3Root.wifiPwSsid = ""; wifiPwInput.text = ""; Qt.callLater(() => SystemControl.connectWifiWithPassword(s, pw)) }
                                    }
                                }
                                Rectangle {
                                    anchors.right: parent.right; anchors.rightMargin: 4; anchors.verticalCenter: parent.verticalCenter
                                    width: 28; height: 26; radius: 10; color: "transparent"
                                    Text {
                                        anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 17
                                        text: m3Root.hasSymbols ? (m3Root.wifiPwVisible ? "visibility" : "visibility_off") : (m3Root.wifiPwVisible ? "👁" : "••")
                                        color: m3Root.wifiPwVisible ? m3Root.colPrimary : m3Root.colOnLayer1
                                    }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { m3Root.wifiPwVisible = !m3Root.wifiPwVisible } }
                                }
                            }
                            Rectangle {
                                width: 78; height: 34; radius: 12; color: m3Root.colPrimary
                                Text { anchors.centerIn: parent; text: "Connect"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colOnPrimary }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const s = m3Root.wifiPwSsid; const pw = wifiPwInput.text
                                        if (pw !== "") { m3Root.wifiPwSsid = ""; wifiPwInput.text = ""; Qt.callLater(() => SystemControl.connectWifiWithPassword(s, pw)) }
                                    }
                                }
                            }
                            Rectangle {
                                width: 40; height: 34; radius: 12; color: m3Root.colLayer0
                                Text { anchors.centerIn: parent; text: "×"; font.family: "Segoe UI"; font.pixelSize: 15; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { m3Root.wifiPwSsid = ""; wifiPwInput.text = ""; sbCard.forceActiveFocus() } }
                            }
                        }
                    }
                }

                ListView {
                    width: parent.width; height: parent.height - (m3Root.wifiPwSsid !== "" ? 172 : 48)
                    spacing: 6; clip: true; model: SystemControl.wifiNetworks
                    Text { visible: SystemControl.wifiNetworks.length === 0; anchors.centerIn: parent; text: SystemControl.wifiScanning ? "Scanning nearby networks..." : "No networks found"; font.family: "Segoe UI"; font.pixelSize: 13; color: m3Root.colOnLayer1 }
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isConnecting: SystemControl.wifiConnectingSsid !== "" && (SystemControl.wifiConnectingSsid === modelData.ssid || SystemControl.wifiConnectingSsid === modelData.profile)
                        readonly property bool isKnown: !!(modelData.profile && modelData.profile !== "") || !modelData.secured
                        width: ListView.view.width; height: 50; radius: 16
                        color: modelData.connected ? m3Root.colPrimaryContainer : (isConnecting ? m3Root.colSecondaryContainer : m3Root.colLayer2)
                        border.width: modelData.connected ? 1 : 0; border.color: m3Root.colPrimary

                        Row {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10; spacing: 10
                            Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 19; text: m3Root.hasSymbols ? "wifi" : "📶"; color: modelData.connected ? m3Root.colPrimary : m3Root.colOnLayer0 }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter; width: parent.width - (isKnown ? 112 : 56); spacing: 1
                                Text { width: parent.width; elide: Text.ElideRight; text: modelData.ssid || "Hidden Network"; font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                                Text { width: parent.width; elide: Text.ElideRight; text: (modelData.connected ? "Connected · " : (isConnecting ? "Connecting... · " : "")) + (modelData.signal || 0) + "%" + (modelData.secured ? " · Secured" : " · Open"); font.family: "Segoe UI"; font.pixelSize: 10; color: m3Root.colOnLayer1 }
                            }
                            Text { visible: !!modelData.secured; anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 15; text: m3Root.hasSymbols ? "lock" : "🔒"; color: m3Root.colOnLayer1 }
                            Rectangle {
                                visible: !!(modelData.profile && modelData.profile !== ""); anchors.verticalCenter: parent.verticalCenter; width: 52; height: 26; radius: 13; color: m3Root.colLayer0
                                Text { anchors.centerIn: parent; text: "Forget"; font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFB4AB" }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { const prof = modelData.profile; Qt.callLater(() => SystemControl.forgetWifi(prof)) } }
                            }
                        }
                        MouseArea {
                            anchors.left: parent.left; anchors.right: parent.right; anchors.rightMargin: (modelData.profile && modelData.profile !== "") ? 64 : 0
                            anchors.top: parent.top; anchors.bottom: parent.bottom; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const ssid = modelData.ssid || ""; const prof = modelData.profile || ""
                                const sec = !!modelData.secured; const conn = !!modelData.connected
                                if (conn) return
                                if (!sec || prof !== "") { Qt.callLater(() => SystemControl.connectWifi(prof !== "" ? prof : ssid)) }
                                else { m3Root.wifiPwSsid = ssid; m3Root.wifiPwVisible = false; wifiPwInput.text = ""; wifiPwInput.forceActiveFocus() }
                            }
                        }
                    }
                }
            }

            // ---- SUB-VIEW: BLUETOOTH DEVICES ----
            Column {
                visible: m3Root.sidebarSubView === "bt"
                anchors.fill: parent; anchors.margins: 16; spacing: 12

                Item {
                    width: parent.width; height: 36
                    Row {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                        Rectangle {
                            width: 34; height: 34; radius: 17; color: m3Root.colLayer2
                            Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "arrow_back" : "←"; color: m3Root.colOnLayer0 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => { m3Root.sidebarSubView = ""; sbCard.forceActiveFocus() }) }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter
                            Text { text: "Bluetooth"; font.family: "Segoe UI"; font.pixelSize: 15; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                            Text { text: SystemControl.btScanning ? "Scanning..." : (SystemControl.bluetoothDevices.length + " paired device(s)"); font.family: "Segoe UI"; font.pixelSize: 11; color: m3Root.colPrimary }
                        }
                    }
                    Row {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                        Rectangle {
                            width: 34; height: 34; radius: 17; color: m3Root.colLayer2
                            Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "add" : "+"; color: m3Root.colOnLayer0 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => SystemControl.openAddDeviceDialog()) }
                        }
                        Rectangle {
                            width: 34; height: 34; radius: 17; color: m3Root.colLayer2
                            Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "refresh" : "↻"; color: m3Root.colOnLayer0 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => SystemControl.scanBluetooth()) }
                        }
                        Rectangle {
                            width: 58; height: 34; radius: 17; color: SystemControl.bluetoothEnabled ? m3Root.colPrimary : m3Root.colLayer2
                            Text { anchors.centerIn: parent; text: SystemControl.bluetoothEnabled ? "ON" : "OFF"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Black; color: SystemControl.bluetoothEnabled ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => SystemControl.toggleBluetooth()) }
                        }
                    }
                }

                ListView {
                    width: parent.width; height: parent.height - 48; spacing: 6; clip: true; model: SystemControl.bluetoothDevices
                    Text { visible: SystemControl.bluetoothDevices.length === 0; anchors.centerIn: parent; text: SystemControl.btScanning ? "Scanning Bluetooth devices..." : "No paired devices · Click + to pair"; font.family: "Segoe UI"; font.pixelSize: 13; color: m3Root.colOnLayer1 }
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool canForget: (modelData.paired !== false) && !!(modelData.address && modelData.address !== "" && modelData.address !== "0")
                        width: ListView.view.width; height: 50; radius: 16; color: modelData.connected ? m3Root.colPrimaryContainer : m3Root.colLayer2
                        Row {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10; spacing: 10
                            Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 19; text: m3Root.hasSymbols ? "bluetooth" : "ᛒ"; color: modelData.connected ? m3Root.colPrimary : m3Root.colOnLayer0 }
                            Column {
                                anchors.verticalCenter: parent.verticalCenter; width: parent.width - (canForget ? 96 : 36); spacing: 1
                                Text { width: parent.width; elide: Text.ElideRight; text: modelData.name || "Unknown Device"; font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                                Text { width: parent.width; elide: Text.ElideRight; text: modelData.connected ? "Connected" : (modelData.type || "Paired"); font.family: "Segoe UI"; font.pixelSize: 10; color: m3Root.colOnLayer1 }
                            }
                            Rectangle {
                                visible: canForget; anchors.verticalCenter: parent.verticalCenter; width: 52; height: 26; radius: 13; color: m3Root.colLayer0
                                Text { anchors.centerIn: parent; text: "Forget"; font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.Bold; color: "#FFB4AB" }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { const addr = modelData.address; Qt.callLater(() => SystemControl.forgetBluetooth(addr)) } }
                            }
                        }
                    }
                }
            }

            // ---- SUB-VIEW: DESKTOP WIDGETS MANAGER ----
            Column {
                visible: m3Root.sidebarSubView === "widgets"
                anchors.fill: parent; anchors.margins: 16; spacing: 12

                Item {
                    width: parent.width; height: 36
                    Row {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                        Rectangle {
                            width: 34; height: 34; radius: 17; color: m3Root.colLayer2
                            Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "arrow_back" : "←"; color: m3Root.colOnLayer0 }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => { m3Root.sidebarSubView = ""; sbCard.forceActiveFocus() }) }
                        }
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "Desktop Widgets"; font.family: "Segoe UI"; font.pixelSize: 15; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                    }
                    Rectangle {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: 112; height: 34; radius: 17; color: m3Root.colPrimaryContainer
                        Text { anchors.centerIn: parent; text: "Reset Layout"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colPrimary }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => m3Root.resetWidgetPositions()) }
                    }
                }

                Column {
                    width: parent.width; spacing: 8
                    Repeater {
                        model: [
                            { key: "userCard",     name: "User Card",     sub: "Avatar, uptime, weather quip & quick actions", ic: "account_circle", fb: "👤" },
                            { key: "worldClock",   name: "World Clock",   sub: "Local time & 4 day/night city cards",         ic: "public",         fb: "🌐" },
                            { key: "digitalClock", name: "Digital Clock", sub: "Stacked HH / mm & date badge",                ic: "schedule",       fb: "🕒" },
                            { key: "media",        name: "Media Player",  sub: "Album cover & Cookie12Sided controls",        ic: "music_note",     fb: "♫" },
                            { key: "weather",      name: "Weather Card",  sub: "Temperature, condition & 4 metric pills",     ic: "cloud",          fb: "☁" },
                            { key: "resources",    name: "System Stats",  sub: "CPU Gem, RAM & Temp/Battery cards",           ic: "memory",         fb: "⚙" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool shown: m3Root.isWidgetShown(modelData.key)
                            width: sbCard.width - 32; height: 58; radius: 20
                            color: shown ? m3Root.colPrimaryContainer : m3Root.colLayer2
                            border.width: shown ? 1 : 0; border.color: m3Root.colPrimary

                            Row {
                                anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 12
                                Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 20; text: m3Root.hasSymbols ? modelData.ic : modelData.fb; color: shown ? m3Root.colPrimary : m3Root.colOnLayer1 }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter; width: parent.width - 88; spacing: 1
                                    Text { width: parent.width; elide: Text.ElideRight; text: modelData.name; font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                                    Text { width: parent.width; elide: Text.ElideRight; text: modelData.sub; font.family: "Segoe UI"; font.pixelSize: 10; color: m3Root.colOnLayer1 }
                                }
                                Rectangle {
                                    anchors.verticalCenter: parent.verticalCenter; width: 46; height: 26; radius: 13; color: shown ? m3Root.colPrimary : m3Root.colLayer0
                                    Rectangle {
                                        width: 20; height: 20; radius: 10; anchors.verticalCenter: parent.verticalCenter
                                        x: shown ? 23 : 3; color: shown ? m3Root.colOnPrimary : m3Root.colOnLayer1
                                        Behavior on x { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }
                                    }
                                }
                            }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { const k = modelData.key; const nextOn = !shown; Qt.callLater(() => m3Root.setWidgetShown(k, nextOn)) }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 10. TopBar Weather Forecast Popup
    // =========================================================================
    PanelWindow {
        id: m3WeatherPopupWin
        property real popK: m3Root.weatherPopupOpen ? 1.0 : 0.0
        Behavior on popK { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        visible: (m3Root.weatherPopupOpen || popK > 0.01) && !m3Root.fullscreenActive
        readonly property int targetW: 344
        readonly property int targetH: 292
        readonly property int targetX: Math.round((m3Root.sw - targetW) * 0.5)
        readonly property int targetY: 46

        function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

        x: targetX; y: targetY; width: targetW; height: targetH
        blurBehind: false; color: "transparent"

        Timer {
            id: wthFocusTimer; interval: 45; repeat: false
            onTriggered: { if (m3Root.weatherPopupOpen) { m3WeatherPopupWin.focusActivate(); wthPopCard.forceActiveFocus() } }
        }

        Component.onCompleted: syncGeo()
        onTargetXChanged: syncGeo()
        onTargetYChanged: syncGeo()
        onVisibleChanged: {
            if (visible) { syncGeo(); focusActivate(); wthPopCard.forceActiveFocus(); wthFocusTimer.restart() }
            else wthFocusTimer.stop()
        }
        onWindowDeactivated: {
            if (m3Root.weatherPopupOpen) { m3Root.weatherClosedAt = Date.now(); m3Root.weatherPopupOpen = false }
        }

        Rectangle {
            id: wthPopCard
            focus: true
            anchors.fill: parent; radius: 26
            color: m3Root.colLayer1; border.width: 1; border.color: m3Root.colLayer0Border
            opacity: m3WeatherPopupWin.popK; scale: 0.94 + 0.06 * m3WeatherPopupWin.popK
            Keys.onEscapePressed: { m3Root.weatherClosedAt = Date.now(); m3Root.weatherPopupOpen = false }

            Column {
                anchors.fill: parent; anchors.margins: 16; spacing: 12

                Item {
                    width: parent.width; height: 58
                    Row {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 12
                        Text { anchors.verticalCenter: parent.verticalCenter; text: WeatherService.ready ? (WeatherService.temperature + "°C") : "--°C"; font.family: "Segoe UI"; font.pixelSize: 40; font.weight: Font.Bold; color: m3Root.colPrimary }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter; spacing: 1
                            Text { text: WeatherService.conditionText || "Weather"; font.family: "Segoe UI"; font.pixelSize: 14; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                            Text { text: (WeatherService.city || "--") + " · Feels like " + WeatherService.feelsLike + "°C"; font.family: "Segoe UI"; font.pixelSize: 11; color: m3Root.colOnLayer1 }
                        }
                    }
                    MaterialShapeBadge {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                        shape: MaterialShape.Shape.Cookie12Sided; color: m3Root.colPrimary; colSymbol: m3Root.colOnPrimary
                        iconFontFamily: m3Root.iconFontName; useSymbolFont: m3Root.hasSymbols
                        text: m3Root.wmoSymbol(WeatherService.weatherCode); fallbackText: "☁"
                        iconSize: 24; padding: 10; implicitWidth: 46; implicitHeight: 46
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => WeatherService.refresh()) }
                    }
                }

                Grid {
                    width: parent.width; columns: 2; columnSpacing: 8; rowSpacing: 8
                    Repeater {
                        model: [
                            { ic: "humidity_mid", fb: "💧", k: "Humidity", v: WeatherService.humidity + "%" },
                            { ic: "rainy",        fb: "🌧", k: "Precipitation", v: WeatherService.precipProb + "%" },
                            { ic: "air",          fb: "💨", k: "Wind", v: WeatherService.windSpeed + " km/h " + (WeatherService.windDirection || "") },
                            { ic: "wb_sunny",     fb: "☀",  k: "UV Index · H/L", v: "UV " + WeatherService.uvIndex + " · " + WeatherService.tempMax + "°/" + WeatherService.tempMin + "°" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: (wthPopCard.width - 40) * 0.5; height: 58; radius: 18; color: m3Root.colLayer2
                            Row {
                                anchors.fill: parent; anchors.margins: 10; spacing: 8
                                Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? modelData.ic : modelData.fb; color: m3Root.colPrimary }
                                Column {
                                    anchors.verticalCenter: parent.verticalCenter; width: parent.width - 30; spacing: 1
                                    Text { width: parent.width; elide: Text.ElideRight; text: modelData.k; font.family: "Segoe UI"; font.pixelSize: 10; color: m3Root.colOnLayer1 }
                                    Text { width: parent.width; elide: Text.ElideRight; text: modelData.v; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                                }
                            }
                        }
                    }
                }

                Rectangle {
                    width: parent.width; height: 40; radius: 20; color: m3Root.colPrimaryContainer
                    Item {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16
                        Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: "☀ Sunrise " + (WeatherService.sunrise || "--") + "   🌙 Sunset " + (WeatherService.sunset || "--"); font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold; color: m3Root.colOnPrimaryContainer }
                        Text { anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; text: "↻ Refresh"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3Root.colPrimary }
                    }
                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => WeatherService.refresh()) }
                }
            }
        }
    }

    // =========================================================================
    // 11. TopBar Interactive Calendar Popup
    // =========================================================================
    PanelWindow {
        id: m3CalendarPopupWin
        property real popK: m3Root.calendarPopupOpen ? 1.0 : 0.0
        Behavior on popK { NumberAnimation { duration: 180; easing.type: Easing.OutCubic } }

        visible: (m3Root.calendarPopupOpen || popK > 0.01) && !m3Root.fullscreenActive
        readonly property int targetW: 328
        readonly property int targetH: 368
        readonly property int targetX: Math.round((m3Root.sw - targetW) * 0.5)
        readonly property int targetY: 46

        function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

        x: targetX; y: targetY; width: targetW; height: targetH
        blurBehind: false; color: "transparent"

        Timer {
            id: calFocusTimer; interval: 45; repeat: false
            onTriggered: { if (m3Root.calendarPopupOpen) { m3CalendarPopupWin.focusActivate(); calPopCard.forceActiveFocus() } }
        }

        Component.onCompleted: syncGeo()
        onTargetXChanged: syncGeo()
        onTargetYChanged: syncGeo()
        onVisibleChanged: {
            if (visible) { syncGeo(); focusActivate(); calPopCard.forceActiveFocus(); calFocusTimer.restart() }
            else calFocusTimer.stop()
        }
        onWindowDeactivated: {
            if (m3Root.calendarPopupOpen) { m3Root.calendarClosedAt = Date.now(); m3Root.calendarPopupOpen = false }
        }

        Rectangle {
            id: calPopCard
            focus: true
            anchors.fill: parent; radius: 26
            color: m3Root.colLayer1; border.width: 1; border.color: m3Root.colLayer0Border
            opacity: m3CalendarPopupWin.popK; scale: 0.94 + 0.06 * m3CalendarPopupWin.popK
            Keys.onEscapePressed: { m3Root.calendarClosedAt = Date.now(); m3Root.calendarPopupOpen = false }

            Column {
                anchors.fill: parent; anchors.margins: 16; spacing: 10

                // Live Clock + Date Header
                Column {
                    width: parent.width; spacing: 1
                    Text { text: Qt.formatDateTime(m3Root.nowDate, "hh:mm:ss AP"); font.family: "Segoe UI"; font.pixelSize: 26; font.weight: Font.Bold; color: m3Root.colPrimary }
                    Text { text: Qt.formatDateTime(m3Root.nowDate, "dddd, MMMM d, yyyy"); font.family: "Segoe UI"; font.pixelSize: 12; color: m3Root.colOnLayer1 }
                }

                // Month Navigation
                Item {
                    width: parent.width; height: 32
                    Text {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter
                        text: Qt.formatDate(new Date(m3Root.calYear, m3Root.calMonth, 1), "MMMM yyyy")
                        font.family: "Segoe UI"; font.pixelSize: 14; font.weight: Font.Bold; color: m3Root.colOnLayer0
                    }
                    Row {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                        Rectangle {
                            width: 28; height: 28; radius: 14; color: m3Root.colLayer2
                            Text { anchors.centerIn: parent; text: "‹"; font.pixelSize: 16; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (m3Root.calMonth === 0) { m3Root.calMonth = 11; m3Root.calYear -= 1 }
                                    else m3Root.calMonth -= 1
                                }
                            }
                        }
                        Rectangle {
                            width: 48; height: 28; radius: 14; color: m3Root.colPrimaryContainer
                            Text { anchors.centerIn: parent; text: "Today"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3Root.colPrimary }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: { m3Root.calYear = m3Root.nowDate.getFullYear(); m3Root.calMonth = m3Root.nowDate.getMonth() }
                            }
                        }
                        Rectangle {
                            width: 28; height: 28; radius: 14; color: m3Root.colLayer2
                            Text { anchors.centerIn: parent; text: "›"; font.pixelSize: 16; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    if (m3Root.calMonth === 11) { m3Root.calMonth = 0; m3Root.calYear += 1 }
                                    else m3Root.calMonth += 1
                                }
                            }
                        }
                    }
                }

                // Weekday Labels
                Row {
                    width: parent.width; height: 22
                    Repeater {
                        model: ["Mo", "Tu", "We", "Th", "Fr", "Sa", "Su"]
                        delegate: Text {
                            required property string modelData
                            width: (calPopCard.width - 32) / 7
                            horizontalAlignment: Text.AlignHCenter
                            text: modelData; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3Root.colPrimary
                        }
                    }
                }

                // 6x7 Month Grid
                Grid {
                    width: parent.width; columns: 7; rowSpacing: 4
                    Repeater {
                        model: m3Root.calendarCells
                        delegate: Item {
                            required property var modelData
                            width: (calPopCard.width - 32) / 7
                            height: 32
                            Rectangle {
                                anchors.centerIn: parent; width: 30; height: 30; radius: 15
                                color: modelData.isToday ? m3Root.colPrimary : "transparent"
                                Text {
                                    anchors.centerIn: parent
                                    text: modelData.day
                                    font.family: "Segoe UI"; font.pixelSize: 12; font.weight: modelData.isToday ? Font.Black : Font.DemiBold
                                    color: modelData.isToday ? m3Root.colOnPrimary : m3Root.colOnLayer0
                                    opacity: modelData.isToday ? 1.0 : (modelData.curMonth ? 0.92 : 0.30)
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 12. Silky Smooth M3 Search Overview / Virtualized GridView (Alt+Space)
    // =========================================================================
    PanelWindow {
        id: m3LauncherWin
        property real popK: m3Root.launcherOpen ? 1.0 : 0.0
        Behavior on popK {
            NumberAnimation { duration: 220; easing.type: Easing.BezierSpline; easing.bezierCurve: [0.05, 0.7, 0.1, 1, 1, 1] }
        }

        visible: (m3Root.launcherOpen || popK > 0.01) && !m3Root.fullscreenActive
        readonly property int targetW: Math.min(820, m3Root.sw - 80)
        readonly property int targetH: Math.min(580, m3Root.sh - 130)
        readonly property int targetX: Math.round((m3Root.sw - targetW) * 0.5)
        readonly property int targetY: Math.round((m3Root.sh - targetH) * 0.44)

        function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

        x: targetX; y: targetY; width: targetW; height: targetH
        blurBehind: false
        color: "transparent"

        Timer {
            id: launcherFocusTimer
            interval: 45
            repeat: false
            onTriggered: {
                if (m3Root.launcherOpen) {
                    m3LauncherWin.focusActivate()
                    m3SearchInput.forceActiveFocus()
                    launcherFocusRetryTimer.restart()
                }
            }
        }
        Timer {
            id: launcherFocusRetryTimer
            interval: 120
            repeat: false
            onTriggered: {
                if (m3Root.launcherOpen && !m3SearchInput.activeFocus) {
                    m3LauncherWin.focusActivate()
                    m3SearchInput.forceActiveFocus()
                }
            }
        }

        Component.onCompleted: syncGeo()
        onTargetXChanged: syncGeo()
        onTargetYChanged: syncGeo()
        onTargetWChanged: syncGeo()
        onTargetHChanged: syncGeo()
        onVisibleChanged: {
            if (visible) {
                syncGeo()
                focusActivate()
                m3SearchInput.forceActiveFocus()
                launcherFocusTimer.restart()
            } else {
                launcherFocusTimer.stop()
                launcherFocusRetryTimer.stop()
                searchDebounceTimer.stop()
                m3SearchInput.text = ""
                m3Root.launcherQuery = ""
            }
        }
        onWindowDeactivated: {
            if (m3Root.launcherOpen) {
                m3Root.launcherClosedAt = Date.now()
                m3Root.launcherOpen = false
            }
        }

        Timer {
            id: searchDebounceTimer
            interval: 60
            repeat: false
            onTriggered: m3Root.launcherQuery = m3SearchInput.text
        }

        Rectangle {
            anchors.fill: parent
            radius: 28
            color: m3Root.colLayer1
            border.width: 1; border.color: m3Root.colLayer0Border
            opacity: m3LauncherWin.popK
            scale: 0.94 + 0.06 * m3LauncherWin.popK

            Column {
                anchors.fill: parent; anchors.margins: 18; spacing: 14

                Rectangle {
                    width: parent.width; height: 48; radius: 24
                    color: m3Root.colLayer0; border.width: 1; border.color: m3Root.colPrimary

                    Row {
                        anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 10
                        Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 20; text: m3Root.hasSymbols ? "search" : "🔍"; color: m3Root.colPrimary }
                        TextInput {
                            id: m3SearchInput
                            anchors.verticalCenter: parent.verticalCenter
                            width: parent.width - 42
                            font.family: "Segoe UI"; font.pixelSize: 15; color: m3Root.colOnLayer0
                            onTextChanged: searchDebounceTimer.restart()
                            Keys.onEscapePressed: {
                                m3Root.launcherClosedAt = Date.now()
                                m3Root.launcherOpen = false
                            }
                            Keys.onReturnPressed: {
                                searchDebounceTimer.stop()
                                m3Root.launcherQuery = text
                                if (m3Root.filteredApps.length > 0) {
                                    const first = m3Root.filteredApps[0]
                                    const tgt = first.target || ""; const args = first.args || ""
                                    Qt.callLater(() => {
                                        m3Root.launcherClosedAt = Date.now()
                                        m3Root.launcherOpen = false
                                        AppLauncher.launch(tgt, args)
                                    })
                                }
                            }
                            Text {
                                visible: parent.text === ""
                                text: "Search apps..."
                                font.family: "Segoe UI"; font.pixelSize: 15; color: m3Root.colOnLayer1; opacity: 0.6
                            }
                        }
                    }
                }

                GridView {
                    id: m3AppGridView
                    width: parent.width
                    height: parent.height - 62
                    cellWidth: Math.floor(width / 6)
                    cellHeight: 102
                    cacheBuffer: 320
                    clip: true
                    boundsBehavior: Flickable.StopAtBounds
                    model: m3Root.filteredApps

                    delegate: Item {
                        required property var modelData
                        width: m3AppGridView.cellWidth
                        height: m3AppGridView.cellHeight

                        Rectangle {
                            anchors.fill: parent; anchors.margins: 4; radius: 18
                            color: m3AppTileMa.containsMouse ? m3Root.colPrimaryContainer : "transparent"

                            Column {
                                anchors.centerIn: parent; width: parent.width - 12; spacing: 6
                                Image {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 44; height: 44
                                    asynchronous: true; cache: true; smooth: true; mipmap: true
                                    source: modelData.target ? ("image://winicon/" + encodeURIComponent(modelData.target)) : ""
                                    scale: m3AppTileMa.containsMouse ? 1.10 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                }
                                Text {
                                    width: parent.width; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight
                                    text: modelData.name || ""
                                    font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.DemiBold; color: m3Root.colOnLayer0
                                }
                            }

                            MouseArea {
                                id: m3AppTileMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const tgt = modelData.target || ""; const args = modelData.args || ""
                                    Qt.callLater(() => {
                                        m3Root.launcherClosedAt = Date.now()
                                        m3Root.launcherOpen = false
                                        AppLauncher.launch(tgt, args)
                                    })
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 11. Material 3 Wallpaper Picker (GridView + Folder + Random + Apply)
    // =========================================================================
    PanelWindow {
        id: m3WallpaperWin
        visible: m3Root.wallpaperPickerOpen
        readonly property int targetW: 740
        readonly property int targetH: 480
        readonly property int targetX: Math.round((m3Root.sw - targetW) * 0.5)
        readonly property int targetY: Math.round((m3Root.sh - targetH) * 0.48)

        function syncGeo() { setPanelGeometry(targetX, targetY, targetW, targetH) }

        x: targetX; y: targetY; width: targetW; height: targetH
        blurBehind: false
        color: "transparent"

        Timer {
            id: wpFocusTimer
            interval: 45
            repeat: false
            onTriggered: {
                if (m3Root.wallpaperPickerOpen) {
                    m3WallpaperWin.focusActivate()
                    wpCard.forceActiveFocus()
                    wpFocusRetryTimer.restart()
                }
            }
        }
        Timer {
            id: wpFocusRetryTimer
            interval: 120
            repeat: false
            onTriggered: {
                if (m3Root.wallpaperPickerOpen && !wpCard.activeFocus) {
                    m3WallpaperWin.focusActivate()
                    wpCard.forceActiveFocus()
                }
            }
        }

        Component.onCompleted: syncGeo()
        onTargetXChanged: syncGeo()
        onTargetYChanged: syncGeo()
        onTargetWChanged: syncGeo()
        onTargetHChanged: syncGeo()
        onVisibleChanged: {
            if (visible) {
                syncGeo()
                focusActivate()
                wpCard.forceActiveFocus()
                wpFocusTimer.restart()
            } else {
                wpFocusTimer.stop()
                wpFocusRetryTimer.stop()
            }
        }
        onWindowDeactivated: {
            if (m3Root.wallpaperPickerOpen) {
                m3Root.wallpaperClosedAt = Date.now()
                m3Root.wallpaperPickerOpen = false
            }
        }

        Rectangle {
            id: wpCard
            focus: true
            anchors.fill: parent
            radius: 28
            color: m3Root.colLayer1
            border.width: 1; border.color: m3Root.colLayer0Border
            clip: true

            Keys.onEscapePressed: {
                m3Root.wallpaperClosedAt = Date.now()
                m3Root.wallpaperPickerOpen = false
            }

            Column {
                anchors.fill: parent; anchors.margins: 18; spacing: 14

                Item {
                    width: parent.width; height: 38
                    Row {
                        anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 10
                        Rectangle {
                            width: 34; height: 34; radius: 17; color: m3Root.colPrimaryContainer
                            Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "wallpaper" : "🖼"; color: m3Root.colPrimary }
                        }
                        Column {
                            anchors.verticalCenter: parent.verticalCenter; spacing: -1
                            Text { text: "Wallpapers"; font.family: "Segoe UI"; font.pixelSize: 16; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                            Text {
                                width: 320; elide: Text.ElideMiddle
                                text: (WallpaperService.directoryShort || "Pictures") + " • " + ((WallpaperService.wallpapers || []).length) + " images"
                                font.family: "Segoe UI"; font.pixelSize: 11; color: m3Root.colOnLayer1
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                        Repeater {
                            model: [
                                { act: "folder", ic: "folder_open", fb: "📁" },
                                { act: "random", ic: "shuffle", fb: "🔀" },
                                { act: "refresh", ic: "refresh", fb: "↻" },
                                { act: "close", ic: "close", fb: "✕" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: 32; height: 32; radius: 16
                                color: wpHdrMa.containsMouse ? m3Root.colPrimaryContainer : m3Root.colLayer2
                                Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 16; text: m3Root.hasSymbols ? modelData.ic : modelData.fb; color: m3Root.colOnLayer0 }
                                MouseArea {
                                    id: wpHdrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const act = modelData.act
                                        Qt.callLater(() => {
                                            if (act === "folder") WallpaperService.pickFolder()
                                            else if (act === "random") WallpaperService.nextRandomWallpaper()
                                            else if (act === "refresh") WallpaperService.refresh()
                                            else if (act === "close") { m3Root.wallpaperClosedAt = Date.now(); m3Root.wallpaperPickerOpen = false }
                                        })
                                    }
                                }
                            }
                        }
                    }
                }

                Item {
                    width: parent.width
                    height: parent.height - 52

                    Column {
                        visible: (WallpaperService.wallpapers || []).length === 0
                        anchors.centerIn: parent; spacing: 12
                        Text { anchors.horizontalCenter: parent.horizontalCenter; font.family: m3Root.iconFontName; font.pixelSize: 38; text: m3Root.hasSymbols ? "photo_library" : "🖼"; color: m3Root.colOnLayer1; opacity: 0.7 }
                        Text { anchors.horizontalCenter: parent.horizontalCenter; text: "No wallpapers found in this folder"; font.family: "Segoe UI"; font.pixelSize: 13; color: m3Root.colOnLayer1 }
                        Rectangle {
                            anchors.horizontalCenter: parent.horizontalCenter
                            width: 146; height: 36; radius: 18
                            color: m3Root.colPrimary
                            Text { anchors.centerIn: parent; text: "Choose Folder"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colOnPrimary }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => WallpaperService.pickFolder()) }
                        }
                    }

                    GridView {
                        id: m3WpGridView
                        visible: (WallpaperService.wallpapers || []).length > 0
                        anchors.fill: parent
                        cellWidth: 230
                        cellHeight: 138
                        cacheBuffer: 420
                        clip: true
                        boundsBehavior: Flickable.StopAtBounds
                        model: WallpaperService.wallpapers || []

                        delegate: Item {
                            required property var modelData
                            readonly property bool isCurrent: WallpaperService.currentWallpaper === modelData.path
                            width: m3WpGridView.cellWidth
                            height: m3WpGridView.cellHeight

                            Rectangle {
                                anchors.fill: parent; anchors.margins: 5; radius: 16
                                color: m3Root.colLayer2
                                border.width: isCurrent ? 3 : (wpTileMa.containsMouse ? 2 : 1)
                                border.color: isCurrent ? m3Root.colPrimary : (wpTileMa.containsMouse ? m3Root.colSecondary : m3Root.colLayer0Border)
                                clip: true

                                Image {
                                    anchors.fill: parent
                                    source: modelData.fileUrl || ""
                                    sourceSize: Qt.size(280, 160)
                                    fillMode: Image.PreserveAspectCrop
                                    asynchronous: true
                                    cache: true
                                    smooth: true
                                }

                                Rectangle {
                                    anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                                    height: 34
                                    gradient: Gradient {
                                        GradientStop { position: 0.0; color: "transparent" }
                                        GradientStop { position: 1.0; color: Qt.rgba(0, 0, 0, 0.78) }
                                    }
                                    Text {
                                        anchors { left: parent.left; leftMargin: 10; right: parent.right; rightMargin: 10; bottom: parent.bottom; bottomMargin: 6 }
                                        elide: Text.ElideRight
                                        text: modelData.name || ""
                                        font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.DemiBold
                                        color: "#FFFFFF"
                                    }
                                }

                                Rectangle {
                                    visible: isCurrent
                                    anchors.top: parent.top; anchors.right: parent.right; anchors.margins: 8
                                    width: 24; height: 24; radius: 12
                                    color: m3Root.colPrimary
                                    Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 15; text: m3Root.hasSymbols ? "check" : "✓"; color: m3Root.colOnPrimary }
                                }

                                MouseArea {
                                    id: wpTileMa
                                    anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const p = modelData.path || ""
                                        if (p !== "")
                                            Qt.callLater(() => WallpaperService.requestWallpaperChange(p))
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
