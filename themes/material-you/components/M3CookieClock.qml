import QtQuick
import ".."

Item {
    id: cookieClk
    required property var m3Root
    width: 184
    height: 184

    readonly property int hrs: m3Root.nowDate.getHours() % 12
    readonly property int mins: m3Root.nowDate.getMinutes()
    readonly property int secs: m3Root.nowDate.getSeconds()

    MaterialShape {
        anchors.centerIn: parent
        implicitSize: 184
        shape: MaterialShape.Shape.Cookie12Sided
        color: m3Root.colPrimaryContainer
        borderWidth: 2
        borderColor: m3Root.colLayer0Border
    }

    // Hour tick dots
    Repeater {
        model: 12
        delegate: Rectangle {
            required property int index
            readonly property real ang: (index * 30 - 90) * Math.PI / 180.0
            x: cookieClk.width * 0.5 + Math.cos(ang) * 66 - width * 0.5
            y: cookieClk.height * 0.5 + Math.sin(ang) * 66 - height * 0.5
            width: (index % 3 === 0) ? 6 : 4
            height: width
            radius: width * 0.5
            color: (index % 3 === 0) ? m3Root.colPrimary : m3Root.colOnPrimaryContainer
            opacity: (index % 3 === 0) ? 0.95 : 0.45
        }
    }

    // Date pill at 6 o'clock
    Rectangle {
        anchors.horizontalCenter: parent.horizontalCenter
        y: 120
        width: dateTxt.implicitWidth + 14
        height: 20
        radius: 10
        color: m3Root.colLayer0
        Text {
            id: dateTxt
            anchors.centerIn: parent
            text: Qt.formatDateTime(m3Root.nowDate, "ddd dd").toUpperCase()
            font.family: "Segoe UI"; font.pixelSize: 9; font.weight: Font.Bold
            color: m3Root.colPrimary
        }
    }

    // Hour hand
    Rectangle {
        width: 7
        height: 44
        radius: 3.5
        color: m3Root.colOnPrimaryContainer
        x: cookieClk.width * 0.5 - width * 0.5
        y: cookieClk.height * 0.5 - height + 4
        transformOrigin: Item.Bottom
        rotation: (cookieClk.hrs + cookieClk.mins / 60.0) * 30.0
    }

    // Minute hand
    Rectangle {
        width: 5
        height: 62
        radius: 2.5
        color: m3Root.colPrimary
        x: cookieClk.width * 0.5 - width * 0.5
        y: cookieClk.height * 0.5 - height + 4
        transformOrigin: Item.Bottom
        rotation: (cookieClk.mins + cookieClk.secs / 60.0) * 6.0
    }

    // Second hand
    Rectangle {
        width: 2
        height: 68
        radius: 1
        color: m3Root.colTertiary
        x: cookieClk.width * 0.5 - width * 0.5
        y: cookieClk.height * 0.5 - height + 12
        transformOrigin: Item.Bottom
        rotation: cookieClk.secs * 6.0
    }

    // Center cap
    Rectangle {
        anchors.centerIn: parent
        width: 12; height: 12; radius: 6
        color: m3Root.colPrimary
        border.width: 2; border.color: m3Root.colLayer0
    }
}
