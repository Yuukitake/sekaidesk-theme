import QtQuick
import Quickshell

Item {
    id: m3CornersRoot
    required property var m3Root
    visible: false

    component CornerPiece: PanelWindow {
        required property int cornerX
        required property int cornerY
        required property int cornerType // 0=TL, 1=TR, 2=BL, 3=BR

        function syncGeo() { setPanelGeometry(cornerX, cornerY, 18, 18) }

        visible: !m3Root.fullscreenActive
        clickThrough: true
        x: cornerX; y: cornerY; width: 18; height: 18
        blurBehind: false
        color: "transparent"

        Component.onCompleted: syncGeo()
        onCornerXChanged: syncGeo()
        onCornerYChanged: syncGeo()
        onVisibleChanged: if (visible) syncGeo()

        Canvas {
            anchors.fill: parent
            onPaint: {
                const ctx = getContext("2d")
                ctx.clearRect(0, 0, width, height)
                ctx.fillStyle = "#000000"
                ctx.beginPath()
                const r = 18
                if (cornerType === 0) {
                    ctx.moveTo(0, 0); ctx.lineTo(r, 0)
                    ctx.arc(r, r, r, -Math.PI * 0.5, Math.PI, true)
                    ctx.closePath()
                } else if (cornerType === 1) {
                    ctx.moveTo(r, 0); ctx.lineTo(r, r)
                    ctx.arc(0, r, r, 0, -Math.PI * 0.5, true)
                    ctx.closePath()
                } else if (cornerType === 2) {
                    ctx.moveTo(0, r); ctx.lineTo(0, 0)
                    ctx.arc(r, 0, r, Math.PI, Math.PI * 0.5, true)
                    ctx.closePath()
                } else {
                    ctx.moveTo(r, r); ctx.lineTo(0, r)
                    ctx.arc(0, 0, r, Math.PI * 0.5, 0, true)
                    ctx.closePath()
                }
                ctx.fill()
            }
        }
    }

    CornerPiece { cornerX: 0; cornerY: 0; cornerType: 0 }
    CornerPiece { cornerX: Math.max(0, m3Root.sw - 18); cornerY: 0; cornerType: 1 }
    CornerPiece { cornerX: 0; cornerY: Math.max(0, m3Root.sh - 18); cornerType: 2 }
    CornerPiece { cornerX: Math.max(0, m3Root.sw - 18); cornerY: Math.max(0, m3Root.sh - 18); cornerType: 3 }
}
