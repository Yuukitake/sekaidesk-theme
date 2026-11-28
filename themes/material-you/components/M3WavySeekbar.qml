import QtQuick

Item {
    id: wavyRoot

    property real value: 0.0
    property bool playing: false
    property bool interactive: true
    property color activeColor: "#f2b8b5"
    property color trackColor: "#49454f"
    property color stopDotColor: activeColor
    property real trackThickness: 4.0
    property real waveAmplitude: 3.2
    property real waveLength: 26.0
    property real thumbWidth: 4.0
    property real thumbHeight: 18.0
    property real thumbGap: 6.0
    property bool showThumb: true
    property bool showStopDot: true
    property real dragFrac: 0.0
    property real settleFrac: -1
    readonly property bool dragging: wavyMa.pressed
    readonly property bool showingOverride: dragging || settleFrac >= 0
    readonly property real displayValue: dragging ? dragFrac : (settleFrac >= 0 ? settleFrac : Math.max(0, Math.min(1, value)))

    readonly property real padX: Math.max(trackThickness * 0.5 + 1, thumbWidth * 0.5 + 2)
    readonly property real usableW: Math.max(1, width - padX * 2)

    signal seekRequested(real fraction)

    Timer {
        id: wavySettleTimer
        interval: 1400
        repeat: false
        onTriggered: wavyRoot.settleFrac = -1
    }

    onValueChanged: {
        if (settleFrac >= 0 && Math.abs(value - settleFrac) < 0.04) {
            settleFrac = -1
            wavySettleTimer.stop()
        }
    }

    property real currentAmp: playing ? waveAmplitude : 0.0
    Behavior on currentAmp {
        NumberAnimation {
            duration: 280
            easing.type: Easing.OutCubic
        }
    }

    property real phase: 0.0
    NumberAnimation on phase {
        from: 0
        to: Math.PI * 2
        duration: 1550
        loops: Animation.Infinite
        running: wavyRoot.visible && wavyRoot.playing && wavyRoot.currentAmp > 0.08
    }

    onPhaseChanged: wavyCanvas.requestPaint()
    onCurrentAmpChanged: wavyCanvas.requestPaint()
    onDisplayValueChanged: wavyCanvas.requestPaint()
    onActiveColorChanged: wavyCanvas.requestPaint()
    onTrackColorChanged: wavyCanvas.requestPaint()
    onStopDotColorChanged: wavyCanvas.requestPaint()
    onWidthChanged: wavyCanvas.requestPaint()
    onHeightChanged: wavyCanvas.requestPaint()
    onVisibleChanged: if (visible) wavyCanvas.requestPaint()

    Canvas {
        id: wavyCanvas
        anchors.fill: parent
        antialiasing: true

        onPaint: {
            if (!wavyRoot.visible || width <= 2 || height <= 2)
                return
            const ctx = getContext("2d")
            ctx.clearRect(0, 0, width, height)

            const padX = wavyRoot.padX
            const usableW = wavyRoot.usableW
            const midY = height * 0.5
            const thumbX = padX + wavyRoot.displayValue * usableW
            const halfGap = wavyRoot.showThumb ? (wavyRoot.thumbWidth * 0.5 + wavyRoot.thumbGap) : 0

            // Inactive track (right of thumb)
            const inactiveStart = wavyRoot.showThumb ? Math.min(width - padX, thumbX + halfGap) : thumbX
            const inactiveEnd = width - padX
            if (inactiveEnd - inactiveStart > 1.5) {
                ctx.save()
                ctx.beginPath()
                ctx.strokeStyle = wavyRoot.trackColor
                ctx.lineWidth = wavyRoot.trackThickness
                ctx.lineCap = "round"
                ctx.moveTo(inactiveStart, midY)
                ctx.lineTo(inactiveEnd, midY)
                ctx.stroke()
                ctx.restore()
            }

            if (wavyRoot.showStopDot && (inactiveEnd - thumbX > halfGap + 4)) {
                ctx.save()
                ctx.globalAlpha = 0.75
                ctx.fillStyle = wavyRoot.stopDotColor
                ctx.beginPath()
                ctx.arc(inactiveEnd, midY, wavyRoot.trackThickness * 0.45, 0, Math.PI * 2)
                ctx.fill()
                ctx.restore()
            }

            // Active wavy track (left of thumb)
            const activeStart = padX
            const activeEnd = wavyRoot.showThumb ? Math.max(activeStart, thumbX - halfGap) : thumbX
            const activeLen = activeEnd - activeStart
            if (activeLen > 1.5) {
                ctx.save()
                ctx.strokeStyle = wavyRoot.activeColor
                ctx.lineWidth = wavyRoot.trackThickness
                ctx.lineCap = "round"
                ctx.lineJoin = "round"
                ctx.beginPath()

                if (wavyRoot.currentAmp < 0.12) {
                    ctx.moveTo(activeStart, midY)
                    ctx.lineTo(activeEnd, midY)
                } else {
                    const twoPiOverLambda = (Math.PI * 2) / Math.max(8, wavyRoot.waveLength)
                    const fadeEdge = Math.min(14, activeLen * 0.28)
                    for (let dx = 0; dx <= activeLen; dx += 1.5) {
                        let env = 1.0
                        if (activeLen > 12 && dx < 6)
                            env = 0.5 * (1 - Math.cos(Math.PI * (dx / 6)))
                        if (fadeEdge > 0.5 && (activeLen - dx) < fadeEdge) {
                            const t = Math.max(0, (activeLen - dx) / fadeEdge)
                            env = Math.min(env, 0.5 * (1 - Math.cos(Math.PI * t)))
                        }
                        const px = activeStart + dx
                        const py = midY + wavyRoot.currentAmp * env * Math.sin(dx * twoPiOverLambda - wavyRoot.phase)
                        if (dx === 0)
                            ctx.moveTo(px, py)
                        else
                            ctx.lineTo(px, py)
                    }
                    ctx.lineTo(activeEnd, midY)
                }

                ctx.stroke()
                ctx.restore()
            }
        }
    }

    Rectangle {
        id: wavyThumb
        visible: wavyRoot.showThumb
        anchors.verticalCenter: parent.verticalCenter
        width: wavyMa.pressed
               ? (wavyRoot.thumbWidth + 1.5)
               : (wavyMa.containsMouse ? (wavyRoot.thumbWidth + 0.8) : wavyRoot.thumbWidth)
        height: wavyMa.pressed
                ? (wavyRoot.thumbHeight + 3)
                : (wavyMa.containsMouse ? (wavyRoot.thumbHeight + 1.5) : wavyRoot.thumbHeight)
        radius: width * 0.5
        color: wavyRoot.activeColor
        x: Math.round(wavyRoot.padX + wavyRoot.displayValue * wavyRoot.usableW - width * 0.5)

        Behavior on width { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
        Behavior on height { NumberAnimation { duration: 140; easing.type: Easing.OutCubic } }
    }

    MouseArea {
        id: wavyMa
        anchors.fill: parent
        hoverEnabled: true
        preventStealing: true
        cursorShape: wavyRoot.interactive ? Qt.PointingHandCursor : Qt.ArrowCursor

        function fracFor(mx) {
            return Math.max(0, Math.min(1, (mx - wavyRoot.padX) / wavyRoot.usableW))
        }

        onPressed: mouse => {
            if (!wavyRoot.interactive) {
                mouse.accepted = false
                return
            }
            wavyRoot.dragFrac = fracFor(mouse.x)
        }
        onPositionChanged: mouse => {
            if (pressed && wavyRoot.interactive)
                wavyRoot.dragFrac = fracFor(mouse.x)
        }
        onReleased: mouse => {
            if (wavyRoot.interactive) {
                const f = fracFor(mouse.x)
                wavyRoot.dragFrac = f
                wavyRoot.settleFrac = f
                wavySettleTimer.restart()
                wavyRoot.seekRequested(f)
            }
        }
        onCanceled: {
            wavyRoot.settleFrac = -1
            wavySettleTimer.stop()
        }
    }
}
