import QtQuick
import QtQuick.Effects
import Quickshell
import SekaiDesk
import "components"

Item {
    id: m3Root
    readonly property var shellRef: m3Root
    visible: false

    property var themeHub: null
    property bool fullscreenActive: false
    property string presetDirUrl: ""
    property bool quickPanelOpen: false

    // Tell SekaiDesk shell this preset owns QuickPanel, Launcher, OSD & Notifications
    readonly property bool handlesQuickPanel: true
    readonly property bool handlesLauncher: true
    readonly property bool handlesOsd: true
    readonly property bool handlesNotifications: true

    signal requestQuickPanel()
    signal requestLauncher()

    property bool sidebarOpen: false
    property double sidebarClosedAt: 0
    property string sidebarClosedSubView: ""
    property string sidebarSubView: "" // "" | "wifi" | "bt" | "audio" | "display" | "widgets" | "worldclock"
    property string sbBottomTab: "notifs" // "notifs" | "calendar" | "todo" | "pomo"
    property int selMonIdx: 0
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

    property bool sessionScreenOpen: false
    property double sessionClosedAt: 0

    property bool mediaPopupOpen: false
    property double mediaPopupClosedAt: 0

    property bool clipboardPopupOpen: false
    property double clipboardClosedAt: 0

    property bool presetStoreOpen: false
    property double presetStoreClosedAt: 0
    property bool presetStoreMounted: false

    property int widgetResetGen: 0
    property int widgetVisGen: 0

    // Configurable World Clock Cities (persisted in ConfigStore)
    property int worldClockEditSlot: 0
    readonly property var worldCityPresets: [
        { city: "Ho Chi Minh", tz: "+7",  off: 7 },
        { city: "Tokyo",       tz: "+9",  off: 9 },
        { city: "Seoul",       tz: "+9",  off: 9 },
        { city: "Singapore",   tz: "+8",  off: 8 },
        { city: "Taipei",      tz: "+8",  off: 8 },
        { city: "Hong Kong",   tz: "+8",  off: 8 },
        { city: "Bangkok",     tz: "+7",  off: 7 },
        { city: "Sydney",      tz: "+11", off: 11 },
        { city: "London",      tz: "+0",  off: 0 },
        { city: "Paris",       tz: "+1",  off: 1 },
        { city: "Berlin",      tz: "+1",  off: 1 },
        { city: "Moscow",      tz: "+3",  off: 3 },
        { city: "Dubai",       tz: "+4",  off: 4 },
        { city: "New Delhi",   tz: "+5.5", off: 5.5 },
        { city: "New York",    tz: "-5",  off: -5 },
        { city: "Los Angeles", tz: "-8",  off: -8 },
        { city: "Chicago",     tz: "-6",  off: -6 },
        { city: "Toronto",     tz: "-5",  off: -5 },
        { city: "Sao Paulo",   tz: "-3",  off: -3 },
        { city: "UTC",         tz: "+0",  off: 0 }
    ]
    property var worldCities: {
        try {
            const raw = ConfigStore.stringValue("m3.worldClock.cities", "")
            if (raw !== "") {
                const parsed = JSON.parse(raw)
                if (Array.isArray(parsed) && parsed.length === 4)
                    return parsed
            }
        } catch (e) {}
        return [
            { city: "Tokyo",    tz: "+9", off: 9 },
            { city: "Seoul",    tz: "+9", off: 9 },
            { city: "London",   tz: "+0", off: 0 },
            { city: "New York", tz: "-5", off: -5 }
        ]
    }
    function setWorldCity(slot, entry) {
        if (slot < 0 || slot >= 4 || !entry) return
        const next = worldCities.slice(0)
        next[slot] = { city: entry.city, tz: entry.tz, off: entry.off }
        worldCities = next
        ConfigStore.set("m3.worldClock.cities", JSON.stringify(next))
    }

    // Persistent Todo List + Pomodoro state
    property var m3Todos: {
        try {
            const raw = ConfigStore.stringValue("m3.todos", "[]")
            const parsed = JSON.parse(raw)
            return Array.isArray(parsed) ? parsed : []
        } catch (e) { return [] }
    }
    function saveTodos(list) {
        m3Todos = list
        ConfigStore.set("m3.todos", JSON.stringify(list))
    }
    function addTodo(text) {
        const t = (text || "").trim()
        if (t === "") return
        const next = m3Todos.slice(0)
        next.unshift({ text: t, done: false })
        saveTodos(next)
    }
    function toggleTodo(idx) {
        if (idx < 0 || idx >= m3Todos.length) return
        const next = m3Todos.slice(0)
        next[idx] = { text: next[idx].text, done: !next[idx].done }
        saveTodos(next)
    }
    function removeTodo(idx) {
        if (idx < 0 || idx >= m3Todos.length) return
        const next = m3Todos.slice(0)
        next.splice(idx, 1)
        saveTodos(next)
    }

    property int pomoSeconds: 25 * 60
    property bool pomoRunning: false
    property bool pomoBreak: false
    function fmtPomo(sec) {
        const s = Math.max(0, Math.floor(sec))
        const m = Math.floor(s / 60)
        const r = s % 60
        return (m < 10 ? "0" : "") + m + ":" + (r < 10 ? "0" : "") + r
    }
    Timer {
        id: m3PomoTimer
        interval: 1000
        repeat: true
        running: m3Root.pomoRunning
        onTriggered: {
            if (m3Root.pomoSeconds > 0) {
                m3Root.pomoSeconds -= 1
            } else {
                m3Root.pomoRunning = false
                m3Root.pomoBreak = !m3Root.pomoBreak
                m3Root.pomoSeconds = m3Root.pomoBreak ? 5 * 60 : 25 * 60
            }
        }
    }

    function closeAllPopups() {
        sidebarOpen = false
        launcherOpen = false
        weatherPopupOpen = false
        calendarPopupOpen = false
        wallpaperPickerOpen = false
        sessionScreenOpen = false
        mediaPopupOpen = false
        clipboardPopupOpen = false
        presetStoreOpen = false
    }

    function togglePresetStore() {
        const wasOpen = presetStoreOpen
        closeAllPopups()
        if (!wasOpen && (Date.now() - presetStoreClosedAt) < 380)
            return
        if (wasOpen) {
            presetStoreClosedAt = Date.now()
            presetStoreOpen = false
        } else {
            presetStoreMounted = true
            ThemeStore.refreshCatalog()
            presetStoreOpen = true
        }
    }

    function toggleSidebarView(view) {
        const wasOpen = sidebarOpen
        const prevView = sidebarSubView
        closeAllPopups()
        if (wasOpen && prevView === view) {
            sidebarClosedSubView = view
            sidebarClosedAt = Date.now()
            sidebarOpen = false
            return false
        }
        if (!wasOpen && (Date.now() - sidebarClosedAt) < 380 && sidebarClosedSubView === view)
            return false
        sidebarSubView = view
        sidebarOpen = true
        return true
    }

    function toggleQuickPanel(fromHotkey) {
        const wasOpen = sidebarOpen
        const prevView = sidebarSubView
        closeAllPopups()
        if (!fromHotkey && !wasOpen && (Date.now() - sidebarClosedAt) < 380)
            return
        if (wasOpen) {
            sidebarClosedSubView = prevView
            sidebarClosedAt = Date.now()
            sidebarOpen = false
        } else {
            sidebarSubView = ""
            sidebarOpen = true
        }
    }

    function toggleLauncher(fromHotkey) {
        const wasOpen = launcherOpen
        closeAllPopups()
        if (!fromHotkey && !wasOpen && (Date.now() - launcherClosedAt) < 380)
            return
        if (wasOpen) {
            launcherClosedAt = Date.now()
            launcherOpen = false
        } else {
            launcherOpen = true
        }
    }

    function toggleWeatherPopup() {
        const wasOpen = weatherPopupOpen
        closeAllPopups()
        if (!wasOpen && (Date.now() - weatherClosedAt) < 380)
            return
        if (wasOpen) {
            weatherClosedAt = Date.now()
            weatherPopupOpen = false
        } else {
            weatherPopupOpen = true
            WeatherService.refresh()
        }
    }

    function toggleCalendarPopup() {
        const wasOpen = calendarPopupOpen
        closeAllPopups()
        if (!wasOpen && (Date.now() - calendarClosedAt) < 380)
            return
        if (wasOpen) {
            calendarClosedAt = Date.now()
            calendarPopupOpen = false
        } else {
            calYear = nowDate.getFullYear()
            calMonth = nowDate.getMonth()
            calendarPopupOpen = true
        }
    }

    function toggleWallpaperPicker() {
        const wasOpen = wallpaperPickerOpen
        closeAllPopups()
        if (!wasOpen && (Date.now() - wallpaperClosedAt) < 380)
            return
        if (wasOpen) {
            wallpaperClosedAt = Date.now()
            wallpaperPickerOpen = false
        } else {
            WallpaperService.refresh()
            wallpaperPickerOpen = true
        }
    }

    function toggleSessionScreen() {
        const wasOpen = sessionScreenOpen
        closeAllPopups()
        if (!wasOpen && (Date.now() - sessionClosedAt) < 380)
            return
        if (wasOpen) {
            sessionClosedAt = Date.now()
            sessionScreenOpen = false
        } else {
            sessionScreenOpen = true
        }
    }

    function toggleMediaPopup() {
        const wasOpen = mediaPopupOpen
        closeAllPopups()
        if (!wasOpen && (Date.now() - mediaPopupClosedAt) < 380)
            return
        if (wasOpen) {
            mediaPopupClosedAt = Date.now()
            mediaPopupOpen = false
        } else {
            mediaPopupOpen = true
        }
    }

    function toggleClipboardPopup() {
        const wasOpen = clipboardPopupOpen
        closeAllPopups()
        if (!wasOpen && (Date.now() - clipboardClosedAt) < 380)
            return
        if (wasOpen) {
            clipboardClosedAt = Date.now()
            clipboardPopupOpen = false
        } else {
            clipboardPopupOpen = true
        }
    }

    function isWidgetShown(key) {
        const _v = widgetVisGen
        const defVis = (key !== "calendar" && key !== "notes" && key !== "todo")
        return ConfigStore.boolValue("m3.widget." + key + ".visible", defVis)
    }

    function setWidgetShown(key, on) {
        ConfigStore.set("m3.widget." + key + ".visible", !!on)
        widgetVisGen += 1
    }

    function resetWidgetPositions() {
        const keys = ["userCard", "worldClock", "digitalClock", "cookieClock", "media", "weather", "resources", "calendar", "notes", "todo"]
        for (let i = 0; i < keys.length; ++i) {
            ConfigStore.set("m3.widget." + keys[i] + ".x", -9999)
            ConfigStore.set("m3.widget." + keys[i] + ".y", -9999)
            const defVis = (keys[i] !== "calendar" && keys[i] !== "notes" && keys[i] !== "todo")
            ConfigStore.set("m3.widget." + keys[i] + ".visible", defVis)
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

        property bool allowFocus: false
        property bool draggingNow: false
        property double lastDragMs: 0

        function syncGeo() {
            if (!draggingNow)
                setPanelGeometry(targetX, targetY, targetW, targetH)
        }

        visible: !m3Root.fullscreenActive && isShown
        desktopLayer: true
        desktopAllowFocus: allowFocus
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
                                if (m3Root.toggleSidebarView("wifi"))
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
                                if (m3Root.toggleSidebarView("bt"))
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
                        color: (m3Root.mediaPopupOpen || m3BarMediaMa.containsMouse) ? m3Root.colPrimaryContainer : m3Root.colSurfaceVariant
                        Row {
                            anchors.centerIn: parent; spacing: 5
                            Text {
                                anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 13
                                text: m3Root.hasSymbols ? (MediaService.hasSession && MediaService.isPlaying ? "pause" : "music_note") : "♪"
                                color: m3Root.colPrimary
                                MouseArea { anchors.fill: parent; anchors.margins: -3; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => MediaService.playPause()) }
                            }
                            Text { id: m3BarMediaLbl; anchors.verticalCenter: parent.verticalCenter; width: Math.min(145, implicitWidth); elide: Text.ElideRight; text: (MediaService.hasSession && MediaService.title !== "") ? MediaService.title : "No media"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.DemiBold; color: m3Root.colOnLayer1 }
                        }
                        MouseArea { id: m3BarMediaMa; anchors.left: parent.left; anchors.leftMargin: 22; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => m3Root.toggleMediaPopup()) }
                    }

                    Rectangle {
                        height: 22; width: 26; radius: 11
                        color: (m3Root.clipboardPopupOpen || m3BarClipMa.containsMouse) ? m3Root.colPrimary : m3Root.colSurfaceVariant
                        Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 13; text: m3Root.hasSymbols ? "content_paste" : "📋"; color: (m3Root.clipboardPopupOpen || m3BarClipMa.containsMouse) ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                        MouseArea { id: m3BarClipMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => m3Root.toggleClipboardPopup()) }
                    }

                    Rectangle {
                        height: 22; width: 26; radius: 11
                        color: (m3Root.wallpaperPickerOpen || m3BarWpMa.containsMouse) ? m3Root.colPrimary : m3Root.colSurfaceVariant
                        Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 14; text: m3Root.hasSymbols ? "wallpaper" : "🖼"; color: (m3Root.wallpaperPickerOpen || m3BarWpMa.containsMouse) ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                        MouseArea { id: m3BarWpMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => m3Root.toggleWallpaperPicker()) }
                    }

                    Rectangle {
                        height: 22; width: m3BarWpBtnTxt.implicitWidth + 16; radius: 11
                        color: (m3Root.sidebarOpen && m3Root.sidebarSubView === "widgets" || m3BarWidgetsMa.containsMouse) ? m3Root.colPrimary : m3Root.colSurfaceVariant
                        Text { id: m3BarWpBtnTxt; anchors.centerIn: parent; text: "Widgets"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: (m3Root.sidebarOpen && m3Root.sidebarSubView === "widgets" || m3BarWidgetsMa.containsMouse) ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                        MouseArea {
                            id: m3BarWidgetsMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.callLater(() => m3Root.toggleSidebarView("widgets"))
                        }
                    }

                    Rectangle {
                        height: 22; width: m3BarPresetTxt.implicitWidth + 16; radius: 11
                        color: (m3Root.presetStoreOpen || m3BarPresetMa.containsMouse) ? m3Root.colPrimary : m3Root.colPrimaryContainer
                        Text { id: m3BarPresetTxt; anchors.centerIn: parent; text: "Presets"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: (m3Root.presetStoreOpen || m3BarPresetMa.containsMouse) ? m3Root.colOnPrimary : m3Root.colOnPrimaryContainer }
                        MouseArea {
                            id: m3BarPresetMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.callLater(() => m3Root.togglePresetStore())
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
                                onClicked: Qt.callLater(() => m3Root.toggleSidebarView("widgets"))
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
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: Qt.callLater(() => {
                                m3Root.worldClockEditSlot = 0
                                m3Root.toggleSidebarView("worldclock")
                            })
                        }
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
                        model: m3Root.worldCities
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
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
                            MouseArea {
                                anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const sl = index
                                    Qt.callLater(() => {
                                        if (m3Root.sidebarOpen && m3Root.sidebarSubView === "worldclock" && m3Root.worldClockEditSlot !== sl) {
                                            m3Root.worldClockEditSlot = sl
                                        } else {
                                            m3Root.worldClockEditSlot = sl
                                            m3Root.toggleSidebarView("worldclock")
                                        }
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

            Item {
                x: 10; y: 10; width: 100; height: 100

                Rectangle {
                    id: mwArtMask
                    anchors.fill: parent
                    radius: 22
                    visible: false
                    layer.enabled: true
                }

                Rectangle {
                    anchors.fill: parent
                    radius: 22
                    color: m3Root.colLayer1
                }

                Item {
                    anchors.fill: parent
                    visible: MediaService.artUrl !== ""
                    layer.enabled: visible
                    layer.effect: MultiEffect {
                        maskEnabled: true
                        maskSource: mwArtMask
                    }
                    Image {
                        anchors.fill: parent
                        source: MediaService.artUrl
                        fillMode: Image.PreserveAspectCrop
                        asynchronous: true
                        cache: true
                        smooth: true
                    }
                }

                Text {
                    visible: MediaService.artUrl === ""
                    anchors.centerIn: parent
                    font.family: m3Root.iconFontName; font.pixelSize: 36
                    text: m3Root.hasSymbols ? "music_note" : "♫"
                    color: m3Root.colOnPrimaryContainer; opacity: 0.78
                }
            }

            Item {
                x: 124; y: 12; width: 282; height: 96
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
        function fmtSpeed(bps) {
            const b = Math.max(0, Number(bps) || 0)
            if (b >= 1048576) return (b / 1048576).toFixed(1) + " MB/s"
            return Math.round(b / 1024) + " KB/s"
        }

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
            SystemControl.setNetSpeedActive(visible)
            if (visible) {
                syncGeo()
                focusActivate()
                sbCard.forceActiveFocus()
                sbFocusTimer.restart()
            } else {
                sbFocusTimer.stop()
                sbFocusRetryTimer.stop()
                if (!m3Root.sidebarOpen)
                    m3Root.sidebarSubView = ""
                m3Root.wifiPwSsid = ""
                m3Root.wifiPwVisible = false
                wifiPwInput.text = ""
            }
        }
        onWindowDeactivated: {
            if (m3Root.sidebarOpen) {
                m3Root.sidebarClosedSubView = m3Root.sidebarSubView
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
                            Text {
                                text: "Up " + (WindowTracker.uptimeText || "0m") + " • ↓ " + m3SidebarWin.fmtSpeed(SystemControl.downloadBps) + " ↑ " + m3SidebarWin.fmtSpeed(SystemControl.uploadBps)
                                font.family: "Segoe UI"; font.pixelSize: 10; color: m3Root.colOnLayer1
                            }
                        }
                    }

                    Row {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                        Repeater {
                            model: [
                                { act: "wallpaper", ic: "wallpaper", fb: "🖼" },
                                { act: "widgets", ic: "widgets", fb: "⊞" },
                                { act: "settings", ic: "settings", fb: "⚙" },
                                { act: "session", ic: "power_settings_new", fb: "⏻" }
                            ]
                            delegate: Rectangle {
                                required property var modelData
                                width: 32; height: 32; radius: 16
                                color: sbHdrMa.containsMouse ? m3Root.colPrimaryContainer : m3Root.colLayer2
                                Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 16; text: m3Root.hasSymbols ? modelData.ic : modelData.fb; color: modelData.act === "session" ? "#FFB4AB" : m3Root.colOnLayer0 }
                                MouseArea {
                                    id: sbHdrMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                    onClicked: {
                                        const act = modelData.act
                                        Qt.callLater(() => {
                                            if (act === "wallpaper") { m3Root.toggleWallpaperPicker() }
                                            else if (act === "widgets") m3Root.sidebarSubView = "widgets"
                                            else if (act === "session") m3Root.toggleSessionScreen()
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
                            { id: "game",    title: GameModeService.autoDetect ? "Game ON" : "Game Mode", sub: GameModeService.autoDetect ? "Auto Detect" : "Standby", active: GameModeService.autoDetect, ic: "sports_esports", fb: "🎮" },
                            { id: "awake",   title: "Keep Awake", sub: SystemControl.keepAwake ? "Screen On" : "Normal", active: SystemControl.keepAwake, ic: "coffee", fb: "☕" },
                            { id: "theme",   title: "Dark Mode", sub: SystemControl.darkMode ? "Dark" : "Light", active: SystemControl.darkMode, ic: "dark_mode", fb: "☾" },
                            { id: "display", title: "Display", sub: SystemControl.monitors.length + " monitor(s) ›", active: false, ic: "desktop_windows", fb: "🖥" }
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
                                        if (tid === "game") GameModeService.autoDetect = !GameModeService.autoDetect
                                        else if (tid === "awake") SystemControl.toggleKeepAwake()
                                        else if (tid === "theme") SystemControl.toggleDarkMode()
                                        else if (tid === "display") m3Root.sidebarSubView = "display"
                                    })
                                }
                            }
                        }
                    }
                }

                // Speaker + Mic + Multi-Monitor Brightness Sliders
                Rectangle {
                    id: sbSlidersCard
                    readonly property int rowCount: 1 + (AudioService.micSupported ? 1 : 0) + (SystemControl.brightnessSupported ? 1 : 0)
                    readonly property var activeMon: {
                        const mons = SystemControl.monitors || []
                        return (m3Root.selMonIdx >= 0 && m3Root.selMonIdx < mons.length) ? mons[m3Root.selMonIdx] : null
                    }
                    readonly property int activeBri: activeMon ? Number(activeMon.brightness || 0) : SystemControl.brightness
                    width: parent.width
                    height: 24 + rowCount * 34 + Math.max(0, rowCount - 1) * 8
                    radius: 22; color: m3Root.colLayer2

                    Column {
                        anchors.fill: parent; anchors.margins: 12; spacing: 8

                        // Speaker row + Mixer button
                        Row {
                            width: parent.width; height: 34; spacing: 8
                            Rectangle {
                                width: parent.width - 42; height: 34; radius: 17; color: m3Root.colLayer0
                                Rectangle { height: parent.height; radius: 17; width: Math.max(34, parent.width * ((AudioService.masterMuted ? 0 : AudioService.masterVolume) / 100.0)); color: AudioService.masterMuted ? "#93000A" : m3Root.colPrimary }
                                Row {
                                    anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                                    Text {
                                        font.family: m3Root.iconFontName; font.pixelSize: 17
                                        text: m3Root.hasSymbols ? (AudioService.masterMuted ? "volume_off" : "volume_up") : "🔊"
                                        color: AudioService.masterMuted ? "#FFDAD6" : (AudioService.masterVolume > 18 ? m3Root.colOnPrimary : m3Root.colOnLayer0)
                                        MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => AudioService.toggleMasterMute()) }
                                    }
                                    Text { text: AudioService.masterMuted ? "Muted" : ("Speaker " + AudioService.masterVolume + "%"); font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: AudioService.masterMuted ? "#FFDAD6" : (AudioService.masterVolume > 28 ? m3Root.colOnPrimary : m3Root.colOnLayer0) }
                                }
                                MouseArea {
                                    anchors.left: parent.left; anchors.leftMargin: 36; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; cursorShape: Qt.PointingHandCursor
                                    function applyVol(mx) { const pct = Math.round(Math.max(0, Math.min(1, (mx + 36) / Math.max(1, parent.width))) * 100); Qt.callLater(() => AudioService.setMasterVolume(pct)) }
                                    onPressed: mouse => applyVol(mouse.x)
                                    onPositionChanged: mouse => { if (pressed) applyVol(mouse.x) }
                                }
                            }
                            Rectangle {
                                width: 34; height: 34; radius: 17; color: m3Root.colLayer0
                                Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 17; text: m3Root.hasSymbols ? "tune" : "🎚"; color: m3Root.colPrimary }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    onClicked: Qt.callLater(() => {
                                        AudioService.refreshOutputDevices()
                                        AudioService.refreshSessions()
                                        m3Root.sidebarSubView = "audio"
                                    })
                                }
                            }
                        }

                        // Mic row
                        Item {
                            visible: AudioService.micSupported
                            width: parent.width; height: 34
                            Rectangle {
                                anchors.fill: parent; radius: 17; color: m3Root.colLayer0
                                Rectangle { height: parent.height; radius: 17; width: Math.max(34, parent.width * ((AudioService.micMuted ? 0 : AudioService.micVolume) / 100.0)); color: AudioService.micMuted ? "#93000A" : m3Root.colTertiary }
                                Row {
                                    anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                                    Text {
                                        font.family: m3Root.iconFontName; font.pixelSize: 17
                                        text: m3Root.hasSymbols ? (AudioService.micMuted ? "mic_off" : "mic") : "🎙"
                                        color: AudioService.micMuted ? "#FFDAD6" : (AudioService.micVolume > 18 ? m3Root.colOnPrimary : m3Root.colOnLayer0)
                                        MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => AudioService.toggleMicMute()) }
                                    }
                                    Text { text: AudioService.micMuted ? "Mic Muted" : ("Mic " + AudioService.micVolume + "%"); font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: AudioService.micMuted ? "#FFDAD6" : (AudioService.micVolume > 28 ? m3Root.colOnPrimary : m3Root.colOnLayer0) }
                                }
                                MouseArea {
                                    anchors.left: parent.left; anchors.leftMargin: 36; anchors.right: parent.right; anchors.top: parent.top; anchors.bottom: parent.bottom; cursorShape: Qt.PointingHandCursor
                                    function applyMic(mx) { const pct = Math.round(Math.max(0, Math.min(1, (mx + 36) / Math.max(1, parent.width))) * 100); Qt.callLater(() => AudioService.setMicVolume(pct)) }
                                    onPressed: mouse => applyMic(mouse.x)
                                    onPositionChanged: mouse => { if (pressed) applyMic(mouse.x) }
                                }
                            }
                        }

                        // Brightness row (+ M1/M2 monitor chips)
                        Row {
                            visible: SystemControl.brightnessSupported
                            width: parent.width; height: 34; spacing: 6
                            Rectangle {
                                width: parent.width - ((SystemControl.monitors || []).length > 1 ? ((SystemControl.monitors || []).length * 36 + 6) : 0)
                                height: 34; radius: 17; color: m3Root.colLayer0
                                Rectangle { height: parent.height; radius: 17; width: Math.max(34, parent.width * (sbSlidersCard.activeBri / 100.0)); color: m3Root.colSecondary }
                                Row {
                                    anchors.left: parent.left; anchors.leftMargin: 12; anchors.verticalCenter: parent.verticalCenter; spacing: 8
                                    Text { font.family: m3Root.iconFontName; font.pixelSize: 17; text: m3Root.hasSymbols ? "brightness_6" : "☀"; color: sbSlidersCard.activeBri > 18 ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                                    Text { text: "Brightness " + sbSlidersCard.activeBri + "%"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: sbSlidersCard.activeBri > 28 ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                                }
                                MouseArea {
                                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                                    function applyBri(mx) {
                                        const pct = Math.round(Math.max(0, Math.min(1, mx / Math.max(1, width))) * 100)
                                        const mon = sbSlidersCard.activeMon
                                        if (mon) Qt.callLater(() => SystemControl.setMonitorBrightness(mon.index, pct))
                                        else Qt.callLater(() => SystemControl.setBrightness(pct))
                                    }
                                    onPressed: mouse => applyBri(mouse.x)
                                    onPositionChanged: mouse => { if (pressed) applyBri(mouse.x) }
                                }
                            }
                            Row {
                                visible: (SystemControl.monitors || []).length > 1
                                spacing: 4
                                Repeater {
                                    model: SystemControl.monitors || []
                                    delegate: Rectangle {
                                        required property var modelData
                                        required property int index
                                        width: 32; height: 34; radius: 14
                                        color: m3Root.selMonIdx === index ? m3Root.colPrimary : m3Root.colLayer0
                                        Text { anchors.centerIn: parent; text: "M" + (index + 1); font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3Root.selMonIdx === index ? m3Root.colOnPrimary : m3Root.colOnLayer1 }
                                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: m3Root.selMonIdx = index }
                                    }
                                }
                            }
                        }
                    }
                }

                // Prominent Desktop Widgets Button + Quick Preset Switcher
                Row {
                    width: parent.width; height: 34; spacing: 6
                    Rectangle {
                        width: 116; height: 34; radius: 17
                        color: sbWidgetsBtnMa.containsMouse ? m3Root.colSecondary : m3Root.colSecondaryContainer
                        Row {
                            anchors.centerIn: parent; spacing: 5
                            Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 15; text: m3Root.hasSymbols ? "widgets" : "⊞"; color: sbWidgetsBtnMa.containsMouse ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Widgets"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: sbWidgetsBtnMa.containsMouse ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                        }
                        MouseArea { id: sbWidgetsBtnMa; anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor; onClicked: m3Root.sidebarSubView = "widgets" }
                    }
                    Repeater {
                        model: ThemeStore.presets
                        delegate: Rectangle {
                            required property var modelData
                            readonly property bool isCur: ThemeStore.activePreset === modelData.id
                            readonly property bool isInst: !!modelData.installed
                            width: (sbCard.width - 32 - 122 - Math.max(0, ThemeStore.presets.length - 1) * 6) / Math.max(1, ThemeStore.presets.length)
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
                                        } else {
                                            m3Root.togglePresetStore()
                                        }
                                    })
                                }
                            }
                        }
                    }
                }

                // Bottom Tabbed Group: Notifications | Calendar | Todo | Pomodoro
                Rectangle {
                    width: parent.width
                    height: Math.max(130, sbCard.height - 294 - sbSlidersCard.height)
                    radius: 22; color: m3Root.colLayer2; clip: true
                    Column {
                        anchors.fill: parent; anchors.margins: 12; spacing: 8

                        // Tab Bar
                        Row {
                            width: parent.width; height: 28; spacing: 4
                            Repeater {
                                model: [
                                    { id: "notifs", lbl: "Notifs (" + NotificationService.notifications.length + ")" },
                                    { id: "calendar", lbl: "Calendar" },
                                    { id: "todo", lbl: "Todo" },
                                    { id: "pomo", lbl: m3Root.pomoRunning ? m3Root.fmtPomo(m3Root.pomoSeconds) : "Focus" }
                                ]
                                delegate: Rectangle {
                                    required property var modelData
                                    readonly property bool sel: m3Root.sbBottomTab === modelData.id
                                    width: (parent.width - 12) / 4; height: 28; radius: 14
                                    color: sel ? m3Root.colPrimary : m3Root.colLayer1
                                    Text { anchors.centerIn: parent; width: parent.width - 8; horizontalAlignment: Text.AlignHCenter; elide: Text.ElideRight; text: modelData.lbl; font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.Bold; color: sel ? m3Root.colOnPrimary : m3Root.colOnLayer1 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: m3Root.sbBottomTab = modelData.id }
                                }
                            }
                        }

                        // TAB 1: Notifications
                        Item {
                            visible: m3Root.sbBottomTab === "notifs"
                            width: parent.width; height: parent.height - 36
                            Rectangle {
                                visible: NotificationService.notifications.length > 0; z: 2
                                anchors.right: parent.right; anchors.top: parent.top
                                width: 64; height: 22; radius: 11; color: m3Root.colLayer0
                                Text { anchors.centerIn: parent; text: "Clear"; font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.Bold; color: m3Root.colPrimary }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => NotificationService.clearAll()) }
                            }
                            Text { visible: NotificationService.notifications.length === 0; anchors.centerIn: parent; text: "All caught up"; font.family: "Segoe UI"; font.pixelSize: 13; color: m3Root.colOnLayer1 }
                            ListView {
                                visible: NotificationService.notifications.length > 0
                                anchors.fill: parent; spacing: 6; clip: true
                                model: NotificationService.notifications
                                delegate: Rectangle {
                                    required property var modelData
                                    width: ListView.view.width; height: 52; radius: 14; color: m3Root.colLayer1
                                    Column {
                                        anchors.fill: parent; anchors.margins: 10; spacing: 2
                                        Text { width: parent.width; elide: Text.ElideRight; text: modelData.title || modelData.appName || "Notification"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                                        Text { width: parent.width; elide: Text.ElideRight; text: modelData.body || ""; font.family: "Segoe UI"; font.pixelSize: 11; color: m3Root.colOnLayer1 }
                                    }
                                }
                            }
                        }

                        // TAB 2: Mini Calendar
                        Column {
                            visible: m3Root.sbBottomTab === "calendar"
                            width: parent.width; height: parent.height - 36; spacing: 4
                            Item {
                                width: parent.width; height: 24
                                Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: Qt.formatDate(new Date(m3Root.calYear, m3Root.calMonth, 1), "MMMM yyyy"); font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                                Row {
                                    anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                                    Rectangle { width: 22; height: 22; radius: 11; color: m3Root.colLayer1; Text { anchors.centerIn: parent; text: "‹"; color: m3Root.colOnLayer0; font.weight: Font.Bold } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (m3Root.calMonth === 0) { m3Root.calMonth = 11; m3Root.calYear -= 1 } else m3Root.calMonth -= 1 } } }
                                    Rectangle { width: 22; height: 22; radius: 11; color: m3Root.colLayer1; Text { anchors.centerIn: parent; text: "›"; color: m3Root.colOnLayer0; font.weight: Font.Bold } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (m3Root.calMonth === 11) { m3Root.calMonth = 0; m3Root.calYear += 1 } else m3Root.calMonth += 1 } } }
                                }
                            }
                            Grid {
                                width: parent.width; columns: 7; rowSpacing: 2; columnSpacing: 2
                                Repeater {
                                    model: ["M", "T", "W", "T", "F", "S", "S"]
                                    delegate: Text { required property string modelData; width: (parent.width - 12) / 7; horizontalAlignment: Text.AlignHCenter; text: modelData; font.family: "Segoe UI"; font.pixelSize: 9; font.weight: Font.Bold; color: m3Root.colPrimary }
                                }
                                Repeater {
                                    model: m3Root.calendarCells
                                    delegate: Rectangle {
                                        required property var modelData
                                        width: (parent.width - 12) / 7; height: 22; radius: 11
                                        color: modelData.isToday ? m3Root.colPrimary : "transparent"
                                        Text { anchors.centerIn: parent; text: String(modelData.day); font.family: "Segoe UI"; font.pixelSize: 10; font.weight: modelData.isToday ? Font.Bold : Font.Normal; color: modelData.isToday ? m3Root.colOnPrimary : m3Root.colOnLayer0; opacity: modelData.curMonth ? 1.0 : 0.35 }
                                    }
                                }
                            }
                        }

                        // TAB 3: Persistent Todo
                        Column {
                            visible: m3Root.sbBottomTab === "todo"
                            width: parent.width; height: parent.height - 36; spacing: 8
                            Row {
                                width: parent.width; height: 32; spacing: 6
                                Rectangle {
                                    width: parent.width - 62; height: 32; radius: 16; color: m3Root.colLayer0; border.width: 1; border.color: m3Root.colLayer0Border
                                    TextInput {
                                        id: sbTodoInput
                                        anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; verticalAlignment: TextInput.AlignVCenter
                                        font.family: "Segoe UI"; font.pixelSize: 12; color: m3Root.colOnLayer0
                                        Keys.onReturnPressed: { if (text.trim() !== "") { m3Root.addTodo(text); text = "" } }
                                        Text { visible: parent.text === ""; text: "Add a task..."; font.family: "Segoe UI"; font.pixelSize: 12; color: m3Root.colOnLayer1; opacity: 0.6 }
                                    }
                                }
                                Rectangle {
                                    width: 56; height: 32; radius: 16; color: m3Root.colPrimary
                                    Text { anchors.centerIn: parent; text: "Add"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3Root.colOnPrimary }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (sbTodoInput.text.trim() !== "") { m3Root.addTodo(sbTodoInput.text); sbTodoInput.text = "" } } }
                                }
                            }
                            ListView {
                                width: parent.width; height: parent.height - 40; spacing: 6; clip: true
                                model: m3Root.m3Todos
                                delegate: Rectangle {
                                    required property var modelData
                                    required property int index
                                    width: ListView.view.width; height: 36; radius: 14; color: m3Root.colLayer1
                                    Row {
                                        anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 8; spacing: 8
                                        Rectangle {
                                            width: 18; height: 18; radius: 9; anchors.verticalCenter: parent.verticalCenter
                                            color: modelData.done ? m3Root.colPrimary : "transparent"; border.width: 2; border.color: m3Root.colPrimary
                                            Text { visible: !!modelData.done; anchors.centerIn: parent; text: "✓"; font.pixelSize: 10; font.weight: Font.Bold; color: m3Root.colOnPrimary }
                                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: m3Root.toggleTodo(index) }
                                        }
                                        Text {
                                            width: parent.width - 54; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight
                                            text: modelData.text || ""; font.family: "Segoe UI"; font.pixelSize: 12; font.strikeout: !!modelData.done
                                            color: m3Root.colOnLayer0; opacity: modelData.done ? 0.5 : 1.0
                                        }
                                        Text {
                                            anchors.verticalCenter: parent.verticalCenter; text: "✕"; font.pixelSize: 12; color: "#FFB4AB"
                                            MouseArea { anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor; onClicked: m3Root.removeTodo(index) }
                                        }
                                    }
                                }
                            }
                        }

                        // TAB 4: Pomodoro Focus Timer
                        Column {
                            visible: m3Root.sbBottomTab === "pomo"
                            width: parent.width; height: parent.height - 36; spacing: 10
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter; spacing: 6
                                Rectangle {
                                    width: 84; height: 26; radius: 13; color: !m3Root.pomoBreak ? m3Root.colPrimaryContainer : m3Root.colLayer1
                                    Text { anchors.centerIn: parent; text: "Focus 25m"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: !m3Root.pomoBreak ? m3Root.colPrimary : m3Root.colOnLayer1 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { m3Root.pomoRunning = false; m3Root.pomoBreak = false; m3Root.pomoSeconds = 25 * 60 } }
                                }
                                Rectangle {
                                    width: 84; height: 26; radius: 13; color: m3Root.pomoBreak ? m3Root.colPrimaryContainer : m3Root.colLayer1
                                    Text { anchors.centerIn: parent; text: "Break 5m"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3Root.pomoBreak ? m3Root.colPrimary : m3Root.colOnLayer1 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { m3Root.pomoRunning = false; m3Root.pomoBreak = true; m3Root.pomoSeconds = 5 * 60 } }
                                }
                            }
                            Text {
                                anchors.horizontalCenter: parent.horizontalCenter
                                text: m3Root.fmtPomo(m3Root.pomoSeconds)
                                font.family: "Segoe UI"; font.pixelSize: 38; font.weight: Font.Black; color: m3Root.colPrimary
                            }
                            Row {
                                anchors.horizontalCenter: parent.horizontalCenter; spacing: 10
                                Rectangle {
                                    width: 96; height: 34; radius: 17; color: m3Root.colPrimary
                                    Text { anchors.centerIn: parent; text: m3Root.pomoRunning ? "Pause" : "Start"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colOnPrimary }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: m3Root.pomoRunning = !m3Root.pomoRunning }
                                }
                                Rectangle {
                                    width: 78; height: 34; radius: 17; color: m3Root.colLayer1
                                    Text { anchors.centerIn: parent; text: "Reset"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                                    MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { m3Root.pomoRunning = false; m3Root.pomoSeconds = m3Root.pomoBreak ? 5 * 60 : 25 * 60 } }
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

            // ---- SUB-VIEW: AUDIO OUTPUT & PER-APP MIXER ----
            Column {
                visible: m3Root.sidebarSubView === "audio"
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
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "Sound & Volume Mixer"; font.family: "Segoe UI"; font.pixelSize: 15; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                    }
                    Rectangle {
                        anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; width: 34; height: 34; radius: 17; color: m3Root.colLayer2
                        Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "refresh" : "↻"; color: m3Root.colOnLayer0 }
                        MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => { AudioService.refreshOutputDevices(); AudioService.refreshSessions() }) }
                    }
                }

                Text { text: "Output Device"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colPrimary }
                Column {
                    width: parent.width; spacing: 6
                    Repeater {
                        model: AudioService.outputDevices || []
                        delegate: Rectangle {
                            required property var modelData
                            width: sbCard.width - 32; height: 42; radius: 16
                            color: modelData.isDefault ? m3Root.colPrimaryContainer : m3Root.colLayer2
                            border.width: modelData.isDefault ? 1 : 0; border.color: m3Root.colPrimary
                            Row {
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 8
                                Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? "speaker" : "🔊"; color: modelData.isDefault ? m3Root.colPrimary : m3Root.colOnLayer1 }
                                Text { anchors.verticalCenter: parent.verticalCenter; width: parent.width - 36; elide: Text.ElideRight; text: modelData.name || "Output"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { const did = modelData.id || ""; if (did !== "") Qt.callLater(() => AudioService.setDefaultOutputDevice(did)) } }
                        }
                    }
                }

                Text { text: "App Volume Mixer"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colPrimary }
                ListView {
                    width: parent.width; height: Math.max(120, parent.height - 108 - ((AudioService.outputDevices || []).length * 48))
                    spacing: 8; clip: true; model: AudioService.sessions || []
                    Text { visible: (AudioService.sessions || []).length === 0; anchors.centerIn: parent; text: "No active audio apps"; font.family: "Segoe UI"; font.pixelSize: 12; color: m3Root.colOnLayer1 }
                    delegate: Rectangle {
                        required property var modelData
                        width: ListView.view.width; height: 54; radius: 18; color: m3Root.colLayer2
                        Row {
                            anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 12; spacing: 10
                            Rectangle {
                                width: 32; height: 32; radius: 16; anchors.verticalCenter: parent.verticalCenter
                                color: modelData.muted ? "#93000A" : m3Root.colLayer0
                                Text { anchors.centerIn: parent; font.family: m3Root.iconFontName; font.pixelSize: 16; text: m3Root.hasSymbols ? (modelData.muted ? "volume_off" : "volume_up") : "🔊"; color: modelData.muted ? "#FFDAD6" : m3Root.colPrimary }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { const sid = modelData.id || ""; if (sid !== "") Qt.callLater(() => AudioService.toggleAppMute(sid)) } }
                            }
                            Column {
                                width: parent.width - 42; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                                Item {
                                    width: parent.width; height: 16
                                    Text { anchors.left: parent.left; width: parent.width - 40; elide: Text.ElideRight; text: modelData.name || "App"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                                    Text { anchors.right: parent.right; text: (modelData.volume || 0) + "%"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3Root.colPrimary }
                                }
                                Rectangle {
                                    width: parent.width; height: 8; radius: 4; color: m3Root.colLayer0
                                    Rectangle { width: Math.max(8, parent.width * ((modelData.muted ? 0 : (modelData.volume || 0)) / 100.0)); height: parent.height; radius: 4; color: m3Root.colPrimary }
                                    MouseArea {
                                        anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor
                                        function applyApp(mx) { const sid = modelData.id || ""; const pct = Math.round(Math.max(0, Math.min(1, mx / Math.max(1, width))) * 100); if (sid !== "") Qt.callLater(() => AudioService.setAppVolume(sid, pct)) }
                                        onPressed: mouse => applyApp(mouse.x)
                                        onPositionChanged: mouse => { if (pressed) applyApp(mouse.x) }
                                    }
                                }
                            }
                        }
                    }
                }
            }

            // ---- SUB-VIEW: DISPLAY MODE & MULTI-MONITOR BRIGHTNESS ----
            Column {
                visible: m3Root.sidebarSubView === "display"
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
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "Display & Monitors"; font.family: "Segoe UI"; font.pixelSize: 15; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                    }
                }

                Text { text: "Projection Mode"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colPrimary }
                Grid {
                    width: parent.width; columns: 2; columnSpacing: 8; rowSpacing: 8
                    Repeater {
                        model: [
                            { mode: "internal", label: "PC Screen Only", ic: "laptop" },
                            { mode: "clone",    label: "Duplicate",      ic: "content_copy" },
                            { mode: "extend",   label: "Extend",         ic: "view_column" },
                            { mode: "external", label: "Second Screen",  ic: "tv" }
                        ]
                        delegate: Rectangle {
                            required property var modelData
                            width: (sbCard.width - 40) * 0.5; height: 48; radius: 20; color: m3Root.colLayer2
                            Row {
                                anchors.centerIn: parent; spacing: 8
                                Text { font.family: m3Root.iconFontName; font.pixelSize: 18; text: m3Root.hasSymbols ? modelData.ic : "🖥"; color: m3Root.colPrimary }
                                Text { text: modelData.label; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { const md = modelData.mode; Qt.callLater(() => SystemControl.setDisplayMode(md)) } }
                        }
                    }
                }

                Text { text: "Monitors Brightness"; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colPrimary }
                Column {
                    width: parent.width; spacing: 8
                    Repeater {
                        model: SystemControl.monitors || []
                        delegate: Rectangle {
                            required property var modelData
                            width: sbCard.width - 32; height: 54; radius: 18; color: m3Root.colLayer2
                            Column {
                                anchors.fill: parent; anchors.margins: 10; spacing: 6
                                Item {
                                    width: parent.width; height: 16
                                    Text { anchors.left: parent.left; text: (modelData.name || ("Monitor " + (modelData.index + 1))); font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                                    Text { anchors.right: parent.right; text: (modelData.brightness || 0) + "%"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold; color: m3Root.colSecondary }
                                }
                                Rectangle {
                                    width: parent.width; height: 10; radius: 5; color: m3Root.colLayer0
                                    Rectangle { width: Math.max(10, parent.width * ((modelData.brightness || 0) / 100.0)); height: parent.height; radius: 5; color: m3Root.colSecondary }
                                    MouseArea {
                                        anchors.fill: parent; anchors.margins: -4; cursorShape: Qt.PointingHandCursor
                                        function applyM(mx) { const idx = modelData.index; const pct = Math.round(Math.max(0, Math.min(1, mx / Math.max(1, width))) * 100); Qt.callLater(() => SystemControl.setMonitorBrightness(idx, pct)) }
                                        onPressed: mouse => applyM(mouse.x)
                                        onPositionChanged: mouse => { if (pressed) applyM(mouse.x) }
                                    }
                                }
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

                ListView {
                    width: parent.width; height: parent.height - 48; spacing: 8; clip: true
                    model: [
                        { key: "userCard",     name: "User Card",     sub: "Avatar, uptime, weather quip & quick actions", ic: "account_circle", fb: "👤" },
                        { key: "worldClock",   name: "World Clock",   sub: "Local time & 4 day/night city cards",         ic: "public",         fb: "🌐" },
                        { key: "digitalClock", name: "Digital Clock", sub: "Stacked HH / mm & date badge",                ic: "schedule",       fb: "🕒" },
                        { key: "cookieClock",  name: "Cookie Clock",  sub: "12-sided M3 analog clock & date pill",        ic: "pace",           fb: "🍪" },
                        { key: "media",        name: "Media Player",  sub: "Album cover & Cookie12Sided controls",        ic: "music_note",     fb: "♫" },
                        { key: "weather",      name: "Weather Card",  sub: "Temperature, condition & 4 metric pills",     ic: "cloud",          fb: "☁" },
                        { key: "resources",    name: "System Stats",  sub: "CPU Gem, RAM & Temp/Battery cards",           ic: "memory",         fb: "⚙" },
                        { key: "calendar",     name: "Calendar",      sub: "Interactive desktop monthly calendar",        ic: "calendar_month", fb: "📅" },
                        { key: "notes",        name: "Sticky Notes",  sub: "Editable Material 3 desktop scratchpad",      ic: "sticky_note_2",  fb: "📝" },
                        { key: "todo",         name: "Todo & Focus",  sub: "Synced tasks & Pomodoro timer",               ic: "checklist",      fb: "☑" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool shown: m3Root.isWidgetShown(modelData.key)
                        width: ListView.view.width; height: 56; radius: 20
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

            // ---- SUB-VIEW: WORLD CLOCK CITIES PICKER ----
            Column {
                visible: m3Root.sidebarSubView === "worldclock"
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
                        Text { anchors.verticalCenter: parent.verticalCenter; text: "World Clock Cities"; font.family: "Segoe UI"; font.pixelSize: 15; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                    }
                }

                // 4 Slot Selector Chips
                Grid {
                    width: parent.width; columns: 2; columnSpacing: 8; rowSpacing: 8
                    Repeater {
                        model: m3Root.worldCities
                        delegate: Rectangle {
                            required property var modelData
                            required property int index
                            readonly property bool activeSlot: m3Root.worldClockEditSlot === index
                            width: (sbCard.width - 40) * 0.5; height: 42; radius: 16
                            color: activeSlot ? m3Root.colPrimary : m3Root.colLayer2
                            Row {
                                anchors.fill: parent; anchors.leftMargin: 12; anchors.rightMargin: 10; spacing: 6
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "#" + (index + 1); font.family: "Consolas"; font.pixelSize: 11; font.weight: Font.Bold; color: activeSlot ? m3Root.colOnPrimary : m3Root.colPrimary }
                                Text { anchors.verticalCenter: parent.verticalCenter; width: parent.width - 28; elide: Text.ElideRight; text: modelData.city; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: activeSlot ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                            }
                            MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: m3Root.worldClockEditSlot = index }
                        }
                    }
                }

                Text { text: "Select City for Slot #" + (m3Root.worldClockEditSlot + 1); font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold; color: m3Root.colPrimary }

                ListView {
                    width: parent.width; height: parent.height - 178; spacing: 6; clip: true
                    model: m3Root.worldCityPresets
                    delegate: Rectangle {
                        required property var modelData
                        readonly property bool isSelectedHere: m3Root.worldCities[m3Root.worldClockEditSlot] && m3Root.worldCities[m3Root.worldClockEditSlot].city === modelData.city
                        width: ListView.view.width; height: 44; radius: 14
                        color: isSelectedHere ? m3Root.colPrimaryContainer : m3Root.colLayer2
                        border.width: isSelectedHere ? 1 : 0; border.color: m3Root.colPrimary
                        Row {
                            anchors.fill: parent; anchors.leftMargin: 14; anchors.rightMargin: 14; spacing: 8
                            Text { anchors.verticalCenter: parent.verticalCenter; width: parent.width - 70; elide: Text.ElideRight; text: modelData.city; font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                            Text { anchors.verticalCenter: parent.verticalCenter; width: 62; horizontalAlignment: Text.AlignRight; text: "UTC " + modelData.tz; font.family: "Consolas"; font.pixelSize: 11; color: m3Root.colPrimary }
                        }
                        MouseArea {
                            anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                            onClicked: { const ent = modelData; Qt.callLater(() => m3Root.setWorldCity(m3Root.worldClockEditSlot, ent)) }
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

    // =========================================================================
    // 12. Extra Draggable Desktop Widgets (CookieClock, Calendar, Notes, Todo)
    // =========================================================================
    M3DraggableWidget {
        widgetKey: "cookieClock"
        defaultX: Math.round(m3Root.sw - 420 * m3Root.uiScale)
        defaultY: 50
        baseW: 184
        baseH: 184

        M3CookieClock {
            m3Root: shellRef
        }
    }

    Loader {
        active: m3Root.isWidgetShown("calendar")
        sourceComponent: Component {
            M3DraggableWidget {
                widgetKey: "calendar"
                defaultX: Math.round(310 * m3Root.uiScale)
                defaultY: 50
                baseW: 276
                baseH: 260

                Rectangle {
                    width: 276; height: 260; radius: 28
                    color: Qt.rgba(m3Root.colLayer1.r, m3Root.colLayer1.g, m3Root.colLayer1.b, 0.78)
                    border.width: 1; border.color: m3Root.colLayer0Border

                    Column {
                        anchors.fill: parent; anchors.margins: 16; spacing: 8
                        Item {
                            width: parent.width; height: 26
                            Text { anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; text: Qt.formatDate(new Date(m3Root.calYear, m3Root.calMonth, 1), "MMMM yyyy"); font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                            Row {
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter; spacing: 4
                                Rectangle { width: 24; height: 24; radius: 12; color: m3Root.colLayer2; Text { anchors.centerIn: parent; text: "‹"; color: m3Root.colOnLayer0; font.weight: Font.Bold } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (m3Root.calMonth === 0) { m3Root.calMonth = 11; m3Root.calYear -= 1 } else m3Root.calMonth -= 1 } } }
                                Rectangle { width: 24; height: 24; radius: 12; color: m3Root.colLayer2; Text { anchors.centerIn: parent; text: "›"; color: m3Root.colOnLayer0; font.weight: Font.Bold } MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: { if (m3Root.calMonth === 11) { m3Root.calMonth = 0; m3Root.calYear += 1 } else m3Root.calMonth += 1 } } }
                            }
                        }
                        Grid {
                            width: parent.width; columns: 7; rowSpacing: 4; columnSpacing: 2
                            Repeater {
                                model: ["M", "T", "W", "T", "F", "S", "S"]
                                delegate: Text { required property string modelData; width: (parent.width - 12) / 7; horizontalAlignment: Text.AlignHCenter; text: modelData; font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.Bold; color: m3Root.colPrimary }
                            }
                            Repeater {
                                model: m3Root.calendarCells
                                delegate: Rectangle {
                                    required property var modelData
                                    width: (parent.width - 12) / 7; height: 25; radius: 12
                                    color: modelData.isToday ? m3Root.colPrimary : "transparent"
                                    Text { anchors.centerIn: parent; text: String(modelData.day); font.family: "Segoe UI"; font.pixelSize: 11; font.weight: modelData.isToday ? Font.Bold : Font.Normal; color: modelData.isToday ? m3Root.colOnPrimary : m3Root.colOnLayer0; opacity: modelData.curMonth ? 1.0 : 0.35 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    Loader {
        active: m3Root.isWidgetShown("notes")
        sourceComponent: Component {
            M3DraggableWidget {
                id: m3NotesWidget
                widgetKey: "notes"
                allowFocus: true
                defaultX: Math.round(310 * m3Root.uiScale)
                defaultY: Math.round(330 * m3Root.uiScale)
                baseW: 276
                baseH: 210

                Rectangle {
                    width: 276; height: 210; radius: 28
                    color: Qt.rgba(m3Root.colLayer1.r, m3Root.colLayer1.g, m3Root.colLayer1.b, 0.78)
                    border.width: 1; border.color: m3Root.colLayer0Border

                    Column {
                        anchors.fill: parent; anchors.margins: 16; spacing: 8
                        Row {
                            spacing: 8
                            Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 17; text: m3Root.hasSymbols ? "sticky_note_2" : "📝"; color: m3Root.colPrimary }
                            Text { anchors.verticalCenter: parent.verticalCenter; text: "Quick Notes"; font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                        }
                        Rectangle {
                            width: parent.width; height: parent.height - 32; radius: 16; color: m3Root.colLayer0; clip: true
                            border.width: m3NotesEdit.activeFocus ? 1 : 0; border.color: m3Root.colPrimary

                            MouseArea {
                                anchors.fill: parent
                                z: 2
                                cursorShape: Qt.IBeamCursor
                                onPressed: mouse => {
                                    mouse.accepted = false
                                    m3NotesWidget.focusActivate()
                                    m3NotesEdit.forceActiveFocus()
                                }
                            }

                            TextEdit {
                                id: m3NotesEdit
                                anchors.fill: parent; anchors.margins: 10
                                wrapMode: TextEdit.Wrap
                                selectByMouse: true
                                activeFocusOnPress: true
                                font.family: "Segoe UI"; font.pixelSize: 12; color: m3Root.colOnLayer0
                                text: ConfigStore.stringValue("m3.notes.text", "")
                                onTextChanged: ConfigStore.set("m3.notes.text", text)
                                Text { visible: parent.text === ""; text: "Click to write..."; font.family: "Segoe UI"; font.pixelSize: 12; color: m3Root.colOnLayer1; opacity: 0.5 }
                            }
                        }
                    }
                }
            }
        }
    }

    Loader {
        active: m3Root.isWidgetShown("todo")
        sourceComponent: Component {
            M3DraggableWidget {
                widgetKey: "todo"
                defaultX: Math.round(310 * m3Root.uiScale)
                defaultY: Math.round(560 * m3Root.uiScale)
                baseW: 276
                baseH: 240

                Rectangle {
                    width: 276; height: 240; radius: 28
                    color: Qt.rgba(m3Root.colLayer1.r, m3Root.colLayer1.g, m3Root.colLayer1.b, 0.78)
                    border.width: 1; border.color: m3Root.colLayer0Border

                    Column {
                        anchors.fill: parent; anchors.margins: 16; spacing: 8
                        Item {
                            width: parent.width; height: 26
                            Row {
                                anchors.left: parent.left; anchors.verticalCenter: parent.verticalCenter; spacing: 6
                                Text { anchors.verticalCenter: parent.verticalCenter; font.family: m3Root.iconFontName; font.pixelSize: 17; text: m3Root.hasSymbols ? "checklist" : "☑"; color: m3Root.colPrimary }
                                Text { anchors.verticalCenter: parent.verticalCenter; text: "Todo (" + m3Root.m3Todos.length + ")"; font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Bold; color: m3Root.colOnLayer0 }
                            }
                            Rectangle {
                                anchors.right: parent.right; anchors.verticalCenter: parent.verticalCenter
                                width: 72; height: 24; radius: 12; color: m3Root.pomoRunning ? m3Root.colPrimary : m3Root.colLayer2
                                Text { anchors.centerIn: parent; text: m3Root.fmtPomo(m3Root.pomoSeconds); font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.Bold; color: m3Root.pomoRunning ? m3Root.colOnPrimary : m3Root.colOnLayer0 }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: m3Root.pomoRunning = !m3Root.pomoRunning }
                            }
                        }
                        ListView {
                            width: parent.width; height: parent.height - 34; spacing: 5; clip: true
                            model: m3Root.m3Todos
                            Text { visible: m3Root.m3Todos.length === 0; anchors.centerIn: parent; text: "Add tasks in Control Center"; font.family: "Segoe UI"; font.pixelSize: 11; color: m3Root.colOnLayer1; opacity: 0.7 }
                            delegate: Rectangle {
                                required property var modelData
                                required property int index
                                width: ListView.view.width; height: 32; radius: 12; color: m3Root.colLayer2
                                Row {
                                    anchors.fill: parent; anchors.leftMargin: 10; anchors.rightMargin: 10; spacing: 8
                                    Rectangle {
                                        width: 16; height: 16; radius: 8; anchors.verticalCenter: parent.verticalCenter
                                        color: modelData.done ? m3Root.colPrimary : "transparent"; border.width: 2; border.color: m3Root.colPrimary
                                        Text { visible: !!modelData.done; anchors.centerIn: parent; text: "✓"; font.pixelSize: 9; font.weight: Font.Bold; color: m3Root.colOnPrimary }
                                        MouseArea { anchors.fill: parent; anchors.margins: -3; cursorShape: Qt.PointingHandCursor; onClicked: m3Root.toggleTodo(index) }
                                    }
                                    Text { width: parent.width - 26; anchors.verticalCenter: parent.verticalCenter; elide: Text.ElideRight; text: modelData.text || ""; font.family: "Segoe UI"; font.pixelSize: 11; font.strikeout: !!modelData.done; color: m3Root.colOnLayer0; opacity: modelData.done ? 0.5 : 1.0 }
                                }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 13. Material 3 Expressive Overlays (On-demand lazy popups + OSD/Toasts/Corners)
    // =========================================================================
    Loader { active: m3Root.sessionScreenOpen; sourceComponent: Component { M3SessionScreen { m3Root: shellRef } } }
    Loader { active: m3Root.mediaPopupOpen; sourceComponent: Component { M3MediaPopup { m3Root: shellRef } } }
    Loader { active: m3Root.clipboardPopupOpen; sourceComponent: Component { M3ClipboardPopup { m3Root: shellRef } } }
    Loader { active: m3Root.presetStoreMounted; sourceComponent: Component { M3PresetStoreModal { m3Root: shellRef } } }
    M3OsdPopup { m3Root: shellRef }
    M3NotifPopup { m3Root: shellRef }
    M3ScreenCorners { m3Root: shellRef }
}
