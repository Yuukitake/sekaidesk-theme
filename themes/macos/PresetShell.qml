import QtQuick
import Quickshell
import SekaiDesk

Item {
    id: macRoot
    visible: false

    property var themeHub: null
    property bool fullscreenActive: false
    property string presetDirUrl: ""
    property bool quickPanelOpen: false
    signal requestQuickPanel()

    readonly property int sw: (themeHub && themeHub.screenW > 0) ? themeHub.screenW : 1920
    readonly property int sh: (themeHub && themeHub.screenH > 0) ? themeHub.screenH : 1080
    readonly property int vx: themeHub ? themeHub.virtMinX : 0
    readonly property int vy: themeHub ? themeHub.virtMinY : 0
    readonly property bool isDark: themeHub ? themeHub.phoneDarkMode : true

    readonly property color barBg: isDark ? Qt.rgba(0.11, 0.12, 0.16, 0.72) : Qt.rgba(0.95, 0.96, 0.98, 0.74)
    readonly property color barInk: isDark ? "#F5F7FA" : "#111827"
    readonly property color glassBg: isDark ? Qt.rgba(0.12, 0.14, 0.19, 0.66) : Qt.rgba(0.94, 0.96, 0.99, 0.64)
    readonly property color glassBorder: isDark ? Qt.rgba(1, 1, 1, 0.22) : Qt.rgba(0, 0, 0, 0.16)
    readonly property color glassCardBg: isDark ? Qt.rgba(0.10, 0.12, 0.17, 0.62) : Qt.rgba(0.96, 0.97, 0.99, 0.68)
    readonly property color glassMuted: isDark ? "#A8B3C5" : "#4B5563"
    readonly property color macAccent: "#3B82F6"

    property bool launchpadOpen: false
    property string launchpadQuery: ""
    property date nowDate: new Date()

    Timer {
        interval: 1000
        repeat: true
        running: !macRoot.fullscreenActive
        onTriggered: macRoot.nowDate = new Date()
    }

    function fmtRate(bps) {
        const v = Number(bps) || 0
        if (v >= 1048576) return (v / 1048576).toFixed(1) + " MB/s"
        if (v >= 1024) return Math.round(v / 1024) + " KB/s"
        return Math.round(v) + " B/s"
    }

    readonly property var macDockItems: {
        const list = []
        list.push({ kind: "launchpad", name: "Launchpad", target: "", args: "", pinned: true, running: false, active: macRoot.launchpadOpen })

        const seen = {}
        const pinned = AppLauncher.pinnedApps || []
        for (let i = 0; i < pinned.length; ++i) {
            const p = pinned[i]
            if (!p || !p.target) continue
            const k = p.target.toLowerCase()
            seen[k] = true
            const st = WindowTracker.stateForTarget(p.target)
            list.push({
                kind: "app",
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
                    kind: "app",
                    name: ra.name || "",
                    target: ra.target,
                    args: "",
                    pinned: false,
                    running: true,
                    active: !!ra.active
                })
            }
        }

        list.push({ kind: "divider", name: "", target: "", args: "", pinned: false, running: false, active: false })
        list.push({ kind: "presets", name: "Theme Store", target: "", args: "", pinned: true, running: false, active: false })
        list.push({ kind: "trash", name: TrashService.isEmpty ? "Trash (Empty)" : ("Trash (" + TrashService.itemCount + ")"), target: "", args: "", pinned: true, running: false, active: false })
        return list
    }

    readonly property var filteredLaunchpadApps: {
        const all = AppLauncher.installedApps || []
        const q = launchpadQuery.trim().toLowerCase()
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

    // =========================================================================
    // 1. macOS Finder Top Menu Bar
    // =========================================================================
    PanelWindow {
        id: macTopBar
        visible: !macRoot.fullscreenActive
        x: macRoot.vx
        y: macRoot.vy
        width: macRoot.sw
        height: 28
        reserveTopBar: !macRoot.fullscreenActive
        reserveEdge: "top"
        reserveHeight: macRoot.fullscreenActive ? 0 : 28
        blurBehind: true
        blurRadius: 28
        blurTint: macRoot.barBg
        color: "transparent"

        onWidthChanged: setPanelGeometry(macRoot.vx, macRoot.vy, macRoot.sw, 28)
        Component.onCompleted: setPanelGeometry(macRoot.vx, macRoot.vy, macRoot.sw, 28)

        Rectangle {
            anchors.fill: parent
            color: macRoot.barBg

            Rectangle {
                anchors.left: parent.left; anchors.right: parent.right; anchors.bottom: parent.bottom
                height: 1; color: macRoot.glassBorder
            }

            // Left: Logo + Bold Active App + Classic Menu Items
            Row {
                anchors.left: parent.left; anchors.leftMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 14

                Rectangle {
                    width: 24; height: 20; radius: 5
                    anchors.verticalCenter: parent.verticalCenter
                    color: macLogoMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "⌘"
                        font.family: "Segoe UI Symbol"; font.pixelSize: 15; font.weight: Font.Bold
                        color: macRoot.barInk
                    }
                    MouseArea {
                        id: macLogoMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.callLater(() => {
                            if (macRoot.themeHub) {
                                macRoot.themeHub.landscapeContent = "settings"
                                macRoot.themeHub.settingsSection = ""
                                macRoot.themeHub.settingsOpen = true
                            }
                        })
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: WindowTracker.activeAppName !== "" ? WindowTracker.activeAppName : "Finder"
                    font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.Black
                    color: macRoot.barInk
                }

                Repeater {
                    model: [
                        { label: "File", action: "explorer" },
                        { label: "Edit", action: "clipboard" },
                        { label: "View", action: "wallpapers" },
                        { label: "Go", action: "launchpad" },
                        { label: "Presets", action: "presets" }
                    ]
                    delegate: Rectangle {
                        required property var modelData
                        width: macMenuTxt.implicitWidth + 14; height: 22; radius: 5
                        anchors.verticalCenter: parent.verticalCenter
                        color: macMenuMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent"
                        Text {
                            id: macMenuTxt
                            anchors.centerIn: parent
                            text: modelData.label
                            font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                            color: macRoot.barInk
                        }
                        MouseArea {
                            id: macMenuMa
                            anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                            onClicked: {
                                const act = modelData.action
                                Qt.callLater(() => {
                                    if (act === "explorer") AppLauncher.launch("C:\\Windows\\explorer.exe", "")
                                    else if (act === "clipboard" && macRoot.themeHub) {
                                        macRoot.themeHub.clipboardOpen = true
                                        macRoot.themeHub.spotlightOpen = true
                                    } else if (act === "wallpapers" && macRoot.themeHub) {
                                        macRoot.themeHub.landscapeContent = "wallpapers"
                                        macRoot.themeHub.settingsOpen = true
                                        WallpaperService.refresh()
                                    } else if (act === "launchpad") {
                                        macRoot.launchpadOpen = !macRoot.launchpadOpen
                                    } else if (act === "presets" && macRoot.themeHub) {
                                        macRoot.themeHub.landscapeContent = "settings"
                                        macRoot.themeHub.settingsSection = "presets"
                                        macRoot.themeHub.settingsOpen = true
                                        ThemeStore.refreshCatalog()
                                    }
                                })
                            }
                        }
                    }
                }
            }

            // Right: Status Icons + Spotlight + Control Center + Clock
            Row {
                anchors.right: parent.right; anchors.rightMargin: 14
                anchors.verticalCenter: parent.verticalCenter
                spacing: 10

                // Presets Quick Pill
                Rectangle {
                    width: macPresetBtnTxt.implicitWidth + 16; height: 20; radius: 6
                    anchors.verticalCenter: parent.verticalCenter
                    color: macPresetBtnMa.containsMouse ? macRoot.macAccent : Qt.rgba(1, 1, 1, 0.14)
                    Text {
                        id: macPresetBtnTxt
                        anchors.centerIn: parent
                        text: "Presets"
                        font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Bold
                        color: macPresetBtnMa.containsMouse ? "#FFFFFF" : macRoot.barInk
                    }
                    MouseArea {
                        id: macPresetBtnMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.callLater(() => {
                            if (macRoot.themeHub) {
                                macRoot.themeHub.landscapeContent = "settings"
                                macRoot.themeHub.settingsSection = "presets"
                                macRoot.themeHub.settingsOpen = true
                                ThemeStore.refreshCatalog()
                            }
                        })
                    }
                }

                Text {
                    visible: WindowTracker.hasBattery
                    anchors.verticalCenter: parent.verticalCenter
                    text: (WindowTracker.batteryCharging ? "⚡" : "") + WindowTracker.batteryPercent + "%"
                    font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                    color: macRoot.barInk
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: SystemControl.wifiEnabled ? "Wi-Fi" : "Offline"
                    font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                    color: SystemControl.wifiEnabled ? macRoot.barInk : macRoot.glassMuted
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.callLater(() => SystemControl.toggleWifi())
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: AudioService.masterMuted ? "Muted" : ("Vol " + AudioService.masterVolume + "%")
                    font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                    color: macRoot.barInk
                    MouseArea {
                        anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.callLater(() => AudioService.toggleMasterMute())
                    }
                }

                // Spotlight Search Button
                Rectangle {
                    width: 24; height: 20; radius: 5
                    anchors.verticalCenter: parent.verticalCenter
                    color: macSpotMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "🔍"
                        font.pixelSize: 12; color: macRoot.barInk
                    }
                    MouseArea {
                        id: macSpotMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.callLater(() => {
                            if (macRoot.themeHub) macRoot.themeHub.spotlightOpen = !macRoot.themeHub.spotlightOpen
                        })
                    }
                }

                // Control Center Switch
                Rectangle {
                    width: 24; height: 20; radius: 5
                    anchors.verticalCenter: parent.verticalCenter
                    color: macCcMa.containsMouse ? Qt.rgba(1, 1, 1, 0.16) : "transparent"
                    Text {
                        anchors.centerIn: parent
                        text: "☷"
                        font.pixelSize: 13; font.weight: Font.Bold; color: macRoot.barInk
                    }
                    MouseArea {
                        id: macCcMa
                        anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                        onClicked: Qt.callLater(() => macRoot.requestQuickPanel())
                    }
                }

                Text {
                    anchors.verticalCenter: parent.verticalCenter
                    text: Qt.formatDateTime(macRoot.nowDate, "ddd MMM d   HH:mm")
                    font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.Bold
                    color: macRoot.barInk
                }
            }
        }
    }

    // =========================================================================
    // 2. macOS Frosted Glass Desktop Widgets
    // =========================================================================
    PanelWindow {
        id: macWidgetsLeft
        visible: !macRoot.fullscreenActive && !macRoot.launchpadOpen
        desktopLayer: true
        x: macRoot.vx + 22
        y: macRoot.vy + 46
        width: 280
        height: 332
        color: "transparent"

        Component.onCompleted: setPanelGeometry(macRoot.vx + 22, macRoot.vy + 46, 280, 332)

        Column {
            anchors.fill: parent
            spacing: 14

            // macOS Clock & Calendar Glass Widget
            Rectangle {
                width: parent.width; height: 158; radius: 24
                color: macRoot.glassCardBg
                border.width: 1; border.color: macRoot.glassBorder

                Column {
                    anchors.fill: parent; anchors.margins: 18; spacing: 4
                    Text {
                        text: Qt.formatDateTime(macRoot.nowDate, "dddd, MMMM d").toUpperCase()
                        font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Black
                        color: "#FB7185"
                    }
                    Text {
                        text: Qt.formatDateTime(macRoot.nowDate, "HH:mm")
                        font.family: "Segoe UI"; font.pixelSize: 52; font.weight: Font.Light
                        color: macRoot.barInk
                    }
                    Text {
                        text: (WindowTracker.userName || "User") + "'s Mac · Up " + (WindowTracker.uptimeText || "0m")
                        font.family: "Segoe UI"; font.pixelSize: 12
                        color: macRoot.glassMuted
                    }
                }
            }

            // macOS Weather Glass Widget
            Rectangle {
                width: parent.width; height: 160; radius: 24
                gradient: Gradient {
                    GradientStop { position: 0.0; color: "#D91E3A5F" }
                    GradientStop { position: 1.0; color: "#D9172554" }
                }
                border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.25)

                Column {
                    anchors.fill: parent; anchors.margins: 18; spacing: 6
                    Text {
                        text: WeatherService.city || "Local Weather"
                        font.family: "Segoe UI"; font.pixelSize: 14; font.weight: Font.Bold; color: "#FFFFFF"
                    }
                    Text {
                        text: WeatherService.ready ? (WeatherService.temperature + "°") : "--°"
                        font.family: "Segoe UI"; font.pixelSize: 44; font.weight: Font.Light; color: "#FFFFFF"
                    }
                    Text {
                        text: WeatherService.conditionText || "Click to refresh"
                        font.family: "Segoe UI"; font.pixelSize: 13; font.weight: Font.DemiBold; color: "#DBEAFE"
                    }
                    Text {
                        text: "H:" + WeatherService.tempMax + "°  L:" + WeatherService.tempMin + "°  ·  Wind " + WeatherService.windSpeed + " km/h"
                        font.family: "Segoe UI"; font.pixelSize: 11; color: "#BFDBFE"
                    }
                }

                MouseArea {
                    anchors.fill: parent; cursorShape: Qt.PointingHandCursor
                    onClicked: Qt.callLater(() => WeatherService.refresh())
                }
            }
        }
    }

    PanelWindow {
        id: macWidgetsRight
        visible: !macRoot.fullscreenActive && !macRoot.launchpadOpen
        desktopLayer: true
        x: macRoot.vx + macRoot.sw - 302
        y: macRoot.vy + 46
        width: 280
        height: 312
        color: "transparent"

        onXChanged: setPanelGeometry(macRoot.vx + macRoot.sw - 302, macRoot.vy + 46, 280, 312)
        Component.onCompleted: setPanelGeometry(macRoot.vx + macRoot.sw - 302, macRoot.vy + 46, 280, 312)

        Column {
            anchors.fill: parent
            spacing: 14

            // macOS Now Playing Glass Widget
            Rectangle {
                width: parent.width; height: 142; radius: 24
                color: macRoot.glassCardBg
                border.width: 1; border.color: macRoot.glassBorder

                Row {
                    anchors.fill: parent; anchors.margins: 14; spacing: 12
                    Rectangle {
                        width: 96; height: 114; radius: 16
                        color: Qt.rgba(1, 1, 1, 0.08); clip: true
                        Image {
                            anchors.fill: parent; visible: MediaService.artUrl !== ""
                            source: MediaService.artUrl; fillMode: Image.PreserveAspectCrop; smooth: true
                        }
                        Text {
                            visible: MediaService.artUrl === ""
                            anchors.centerIn: parent; text: "♫"; font.pixelSize: 32; color: macRoot.macAccent
                        }
                    }

                    Item {
                        width: parent.width - 108; height: 114
                        Column {
                            anchors.top: parent.top; anchors.left: parent.left; anchors.right: parent.right; spacing: 2
                            Text {
                                text: "NOW PLAYING"; font.family: "Segoe UI"; font.pixelSize: 10; font.weight: Font.Black; color: "#FB7185"
                            }
                            Text {
                                width: parent.width; elide: Text.ElideRight
                                text: MediaService.hasSession && MediaService.title !== "" ? MediaService.title : "Not Playing"
                                font.family: "Segoe UI"; font.pixelSize: 14; font.weight: Font.Bold; color: macRoot.barInk
                            }
                            Text {
                                width: parent.width; elide: Text.ElideRight
                                text: MediaService.hasSession && MediaService.artist !== "" ? MediaService.artist : "Audio idle"
                                font.family: "Segoe UI"; font.pixelSize: 12; color: macRoot.glassMuted
                            }
                        }

                        Row {
                            anchors.bottom: parent.bottom; anchors.left: parent.left; spacing: 10
                            Rectangle {
                                width: 32; height: 32; radius: 16; color: Qt.rgba(1, 1, 1, 0.12)
                                Text { anchors.centerIn: parent; text: "⏮"; font.pixelSize: 13; color: macRoot.barInk }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => MediaService.previous()) }
                            }
                            Rectangle {
                                width: 36; height: 36; radius: 18; color: macRoot.macAccent
                                Text { anchors.centerIn: parent; text: MediaService.isPlaying ? "❚❚" : "▶"; font.pixelSize: 13; color: "#FFFFFF" }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => MediaService.playPause()) }
                            }
                            Rectangle {
                                width: 32; height: 32; radius: 16; color: Qt.rgba(1, 1, 1, 0.12)
                                Text { anchors.centerIn: parent; text: "⏭"; font.pixelSize: 13; color: macRoot.barInk }
                                MouseArea { anchors.fill: parent; cursorShape: Qt.PointingHandCursor; onClicked: Qt.callLater(() => MediaService.next()) }
                            }
                        }
                    }
                }
            }

            // macOS Activity Monitor Glass Widget
            Rectangle {
                width: parent.width; height: 156; radius: 24
                color: macRoot.glassCardBg
                border.width: 1; border.color: macRoot.glassBorder

                Column {
                    anchors.fill: parent; anchors.margins: 16; spacing: 10

                    Row {
                        width: parent.width; spacing: 6
                        Text { text: "ACTIVITY MONITOR"; font.family: "Segoe UI"; font.pixelSize: 11; font.weight: Font.Black; color: macRoot.macAccent }
                        Text { text: "· ↓" + macRoot.fmtRate(WindowTracker.downloadBps); font.family: "Consolas"; font.pixelSize: 11; color: macRoot.glassMuted }
                    }

                    Repeater {
                        model: [
                            { lbl: "CPU Load", pct: WindowTracker.cpuUsage, col: "#60A5FA" },
                            { lbl: "Memory", pct: WindowTracker.ramUsage, col: "#34D399" }
                        ]
                        delegate: Column {
                            required property var modelData
                            width: 248; spacing: 4
                            Row {
                                width: parent.width
                                Text { text: modelData.lbl; font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold; color: macRoot.barInk; width: parent.width - 42 }
                                Text { text: modelData.pct + "%"; font.family: "Consolas"; font.pixelSize: 12; font.weight: Font.Bold; color: modelData.col; width: 42; horizontalAlignment: Text.AlignRight }
                            }
                            Rectangle {
                                width: parent.width; height: 7; radius: 3.5; color: Qt.rgba(1, 1, 1, 0.12)
                                Rectangle { height: parent.height; radius: 3.5; width: parent.width * Math.max(0.03, Math.min(1.0, modelData.pct / 100.0)); color: modelData.col }
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 3. macOS Frosted Glass Cosine Magnification Dock (MyDockFinder Inspired)
    // =========================================================================
    PanelWindow {
        id: macDockWin
        visible: !macRoot.fullscreenActive
        acceptFileDrops: true
        blurBehind: true
        blurRadius: 32
        blurTint: macRoot.glassBg
        color: "transparent"

        readonly property int baseSize: 50
        readonly property int maxSize: 84
        readonly property int gap: 8
        readonly property int dividerW: 8
        readonly property int shelfPadX: 14
        readonly property int shelfH: 66
        readonly property int winH: 132
        readonly property real waveRadius: 148.0

        property bool dockHovered: macDockHover.hovered
        property real pointerX: 0
        property real waveK: dockHovered ? 1.0 : 0.0
        Behavior on waveK { NumberAnimation { duration: 130; easing.type: Easing.OutCubic } }

        readonly property real idleExtent: {
            const list = macRoot.macDockItems
            let s = 0
            for (let i = 0; i < list.length; ++i) {
                s += (list[i].kind === "divider" ? dividerW : baseSize) + (i < list.length - 1 ? gap : 0)
            }
            return Math.max(120, s)
        }

        readonly property var dockLayout: {
            const list = macRoot.macDockItems
            const n = list.length
            const centers = []
            let bpos = 0
            for (let i = 0; i < n; ++i) {
                const bw = list[i].kind === "divider" ? dividerW : baseSize
                centers.push(bpos + bw * 0.5)
                bpos += bw + (i < n - 1 ? gap : 0)
            }
            const sizes = []
            const offsets = []
            let cpos = 0
            for (let i = 0; i < n; ++i) {
                let w = 0
                if (list[i].kind !== "divider" && waveK > 0.001) {
                    const dist = Math.abs(pointerX - centers[i])
                    if (dist < waveRadius)
                        w = 0.5 * (1.0 + Math.cos(Math.PI * dist / waveRadius)) * waveK
                }
                const sz = list[i].kind === "divider" ? dividerW : (baseSize + (maxSize - baseSize) * w)
                sizes.push(sz)
                offsets.push(cpos)
                cpos += sz + (i < n - 1 ? gap : 0)
            }
            return { total: Math.max(120, cpos), sizes: sizes, offsets: offsets }
        }

        readonly property int winW: Math.min(macRoot.sw - 32, Math.round(idleExtent + 160))
        readonly property int shelfW: Math.round(dockLayout.total + shelfPadX * 2)
        readonly property int shelfX: Math.round((winW - shelfW) * 0.5)
        readonly property int shelfY: winH - shelfH - 8

        x: macRoot.vx + Math.round((macRoot.sw - winW) * 0.5)
        y: macRoot.vy + macRoot.sh - winH
        width: winW
        height: winH

        blurInsetX: Math.max(0, shelfX)
        blurInsetY: shelfY
        blurInsetRight: Math.max(0, winW - (shelfX + shelfW))
        blurInsetBottom: 8

        mask: [
            {
                x: Math.max(0, shelfX - 18),
                y: dockHovered ? 0 : Math.max(0, shelfY - 4),
                width: Math.min(winW, shelfW + 36),
                height: dockHovered ? winH : (shelfH + 10)
            }
        ]

        onXChanged: setPanelGeometry(x, y, width, height)
        onWidthChanged: setPanelGeometry(x, y, width, height)
        Component.onCompleted: setPanelGeometry(x, y, width, height)

        onFilesDropped: files => {
            const list = files
            Qt.callLater(() => AppLauncher.pinDroppedFiles(list))
        }

        Item {
            id: macDockContainer
            x: macDockWin.shelfX
            y: macDockWin.shelfY
            width: macDockWin.shelfW
            height: macDockWin.shelfH

            HoverHandler {
                id: macDockHover
                onPointChanged: {
                    macDockWin.pointerX = point.position.x - macDockWin.shelfPadX
                }
            }

            // Frosted Glass Dock Background
            Rectangle {
                anchors.fill: parent
                radius: 22
                color: macRoot.glassBg
                border.width: 1
                border.color: macRoot.glassBorder

                Rectangle {
                    anchors.left: parent.left; anchors.right: parent.right; anchors.top: parent.top
                    anchors.leftMargin: 12; anchors.rightMargin: 12; anchors.topMargin: 1
                    height: 1; color: Qt.rgba(1, 1, 1, 0.28)
                }
            }

            // Dock Icons Strip
            Item {
                x: macDockWin.shelfPadX
                y: 0
                width: macDockWin.dockLayout.total
                height: macDockWin.shelfH

                Repeater {
                    model: macRoot.macDockItems
                    delegate: Item {
                        required property var modelData
                        required property int index

                        readonly property real sz: (index < macDockWin.dockLayout.sizes.length) ? macDockWin.dockLayout.sizes[index] : macDockWin.baseSize
                        readonly property real off: (index < macDockWin.dockLayout.offsets.length) ? macDockWin.dockLayout.offsets[index] : 0
                        property real bounceY: 0

                        SequentialAnimation {
                            id: macBounceAnim
                            NumberAnimation { target: macDelegateRoot; property: "bounceY"; to: -18; duration: 150; easing.type: Easing.OutQuad }
                            NumberAnimation { target: macDelegateRoot; property: "bounceY"; to: 0; duration: 240; easing.type: Easing.OutBounce }
                        }

                        id: macDelegateRoot
                        x: off
                        y: (macDockWin.shelfH - sz) - 9 + bounceY
                        width: sz
                        height: sz

                        // Divider line
                        Rectangle {
                            visible: modelData.kind === "divider"
                            anchors.centerIn: parent
                            width: 1; height: 36
                            color: macRoot.glassBorder
                        }

                        // Launchpad 3x3 Colored Grid Emblem
                        Rectangle {
                            visible: modelData.kind === "launchpad"
                            anchors.fill: parent; anchors.margins: 3; radius: Math.round(sz * 0.24)
                            color: Qt.rgba(0.16, 0.19, 0.26, 0.92)
                            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.24)
                            Grid {
                                anchors.centerIn: parent
                                width: Math.round(sz * 0.56); height: width
                                columns: 3; spacing: Math.max(2, Math.round(sz * 0.06))
                                Repeater {
                                    model: ["#60A5FA", "#F472B6", "#34D399", "#FBBF24", "#A78BFA", "#38BDF8", "#FB7185", "#4ADE80", "#F59E0B"]
                                    delegate: Rectangle {
                                        required property string modelData
                                        width: Math.max(4, Math.round(sz * 0.14)); height: width; radius: 2
                                        color: modelData
                                    }
                                }
                            }
                        }

                        // Native Windows App Icon
                        Image {
                            visible: modelData.kind === "app"
                            anchors.fill: parent; anchors.margins: 2
                            source: modelData.target !== "" ? ("image://winicon/" + encodeURIComponent(modelData.target)) : ""
                            smooth: true; mipmap: true
                        }

                        // Theme Store Icon
                        Rectangle {
                            visible: modelData.kind === "presets"
                            anchors.fill: parent; anchors.margins: 3; radius: Math.round(sz * 0.24)
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: "#3B82F6" }
                                GradientStop { position: 1.0; color: "#8B5CF6" }
                            }
                            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.28)
                            Text {
                                anchors.centerIn: parent
                                text: "🎨"
                                font.pixelSize: Math.round(sz * 0.46)
                            }
                        }

                        // Trash Icon
                        Rectangle {
                            visible: modelData.kind === "trash"
                            anchors.fill: parent; anchors.margins: 3; radius: Math.round(sz * 0.24)
                            color: TrashService.isEmpty ? Qt.rgba(0.24, 0.27, 0.34, 0.92) : Qt.rgba(0.32, 0.26, 0.22, 0.94)
                            border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.25)
                            Text {
                                anchors.centerIn: parent
                                text: TrashService.isEmpty ? "🗑" : "♻"
                                font.pixelSize: Math.round(sz * 0.46)
                                color: "#F8FAFC"
                            }
                        }

                        // Floating macOS Dock Tooltip
                        Rectangle {
                            visible: macIconMa.containsMouse && modelData.kind !== "divider" && modelData.name !== ""
                            anchors.horizontalCenter: parent.horizontalCenter
                            anchors.bottom: parent.top; anchors.bottomMargin: 10
                            width: macTipTxt.implicitWidth + 20; height: 26; radius: 8
                            color: macRoot.isDark ? Qt.rgba(0.10, 0.12, 0.16, 0.92) : Qt.rgba(0.96, 0.97, 0.99, 0.94)
                            border.width: 1; border.color: macRoot.glassBorder
                            Text {
                                id: macTipTxt
                                anchors.centerIn: parent
                                text: modelData.name
                                font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                                color: macRoot.barInk
                            }
                        }

                        // Classic macOS Bottom Running Dot
                        Rectangle {
                            visible: modelData.running
                            anchors.horizontalCenter: parent.horizontalCenter
                            y: sz + 3
                            width: modelData.active ? 8 : 5; height: 4; radius: 2
                            color: modelData.active ? "#FFFFFF" : Qt.rgba(1, 1, 1, 0.65)
                        }

                        MouseArea {
                            id: macIconMa
                            visible: modelData.kind !== "divider"
                            anchors.fill: parent
                            hoverEnabled: true
                            cursorShape: Qt.PointingHandCursor
                            acceptedButtons: Qt.LeftButton | Qt.RightButton
                            onClicked: mouse => {
                                const k = modelData.kind
                                const tgt = modelData.target || ""
                                const nm = modelData.name || tgt
                                const args = modelData.args || ""
                                const run = !!modelData.running
                                const pin = !!modelData.pinned
                                if (k === "app" && !run)
                                    macBounceAnim.restart()
                                Qt.callLater(() => {
                                    if (k === "launchpad") {
                                        macRoot.launchpadOpen = !macRoot.launchpadOpen
                                    } else if (k === "presets") {
                                        if (macRoot.themeHub) {
                                            macRoot.themeHub.landscapeContent = "settings"
                                            macRoot.themeHub.settingsSection = "presets"
                                            macRoot.themeHub.settingsOpen = true
                                            ThemeStore.refreshCatalog()
                                        }
                                    } else if (k === "trash") {
                                        if (mouse.button === Qt.RightButton) TrashService.emptyBin()
                                        else TrashService.openBin()
                                    } else if (k === "app") {
                                        if (mouse.button === Qt.RightButton) {
                                            if (pin) AppLauncher.removePinnedByTarget(tgt)
                                            else AppLauncher.addPinnedApp(nm, tgt, "")
                                        } else {
                                            if (run) WindowTracker.activateOrToggle(tgt)
                                            else AppLauncher.launch(tgt, args)
                                        }
                                    }
                                })
                            }
                        }
                    }
                }
            }
        }
    }

    // =========================================================================
    // 4. macOS Fullscreen Blurred Launchpad Overlay
    // =========================================================================
    PanelWindow {
        id: macLaunchpadWin
        visible: macRoot.launchpadOpen && !macRoot.fullscreenActive
        x: macRoot.vx
        y: macRoot.vy
        width: macRoot.sw
        height: macRoot.sh
        blurBehind: true
        blurRadius: 48
        blurTint: Qt.rgba(0.05, 0.06, 0.10, 0.72)
        color: "transparent"

        onVisibleChanged: {
            if (visible) {
                setPanelGeometry(macRoot.vx, macRoot.vy, macRoot.sw, macRoot.sh)
                macSearchInput.forceActiveFocus()
            } else {
                macRoot.launchpadQuery = ""
            }
        }
        onWindowDeactivated: macRoot.launchpadOpen = false

        Rectangle {
            anchors.fill: parent
            color: Qt.rgba(0.04, 0.05, 0.09, 0.68)

            MouseArea {
                anchors.fill: parent
                onClicked: macRoot.launchpadOpen = false
            }

            // Centered Search Pill
            Rectangle {
                id: macLpSearchBox
                anchors.horizontalCenter: parent.horizontalCenter
                y: 44
                width: 320; height: 40; radius: 20
                color: Qt.rgba(1, 1, 1, 0.14)
                border.width: 1; border.color: Qt.rgba(1, 1, 1, 0.28)

                Row {
                    anchors.fill: parent; anchors.leftMargin: 16; anchors.rightMargin: 16; spacing: 8
                    Text { anchors.verticalCenter: parent.verticalCenter; text: "🔍"; font.pixelSize: 14; color: "#E5E7EB" }
                    TextInput {
                        id: macSearchInput
                        anchors.verticalCenter: parent.verticalCenter
                        width: parent.width - 28
                        font.family: "Segoe UI"; font.pixelSize: 14; color: "#FFFFFF"
                        text: macRoot.launchpadQuery
                        onTextChanged: macRoot.launchpadQuery = text
                        Keys.onEscapePressed: macRoot.launchpadOpen = false

                        Text {
                            visible: parent.text === ""
                            text: "Search Launchpad..."
                            font.family: "Segoe UI"; font.pixelSize: 14; color: "#9CA3AF"
                        }
                    }
                }
            }

            // Launchpad Apps Grid
            Flickable {
                anchors.horizontalCenter: parent.horizontalCenter
                y: 112
                width: Math.min(parent.width - 140, 1120)
                height: parent.height - 210
                contentHeight: macLpGrid.implicitHeight + 32
                clip: true

                Grid {
                    id: macLpGrid
                    width: parent.width
                    columns: 7
                    rowSpacing: 26

                    Repeater {
                        model: macRoot.filteredLaunchpadApps
                        delegate: Item {
                            required property var modelData
                            width: macLpGrid.width / 7
                            height: 116

                            Column {
                                anchors.centerIn: parent
                                spacing: 8

                                Image {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: 64; height: 64
                                    source: modelData.target ? ("image://winicon/" + encodeURIComponent(modelData.target)) : ""
                                    smooth: true; mipmap: true
                                    scale: macLpItemMa.containsMouse ? 1.12 : 1.0
                                    Behavior on scale { NumberAnimation { duration: 120; easing.type: Easing.OutCubic } }
                                }

                                Text {
                                    anchors.horizontalCenter: parent.horizontalCenter
                                    width: Math.max(88, (macLpGrid.width / 7) - 18)
                                    horizontalAlignment: Text.AlignHCenter
                                    elide: Text.ElideRight
                                    text: modelData.name || ""
                                    font.family: "Segoe UI"; font.pixelSize: 12; font.weight: Font.DemiBold
                                    color: "#F3F4F6"
                                }
                            }

                            MouseArea {
                                id: macLpItemMa
                                anchors.fill: parent; hoverEnabled: true; cursorShape: Qt.PointingHandCursor
                                onClicked: {
                                    const tgt = modelData.target || ""
                                    const args = modelData.args || ""
                                    Qt.callLater(() => {
                                        macRoot.launchpadOpen = false
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
}
