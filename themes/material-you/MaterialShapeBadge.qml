import QtQuick

Item {
    id: badgeRoot
    property var shape: MaterialShape.Shape.Cookie12Sided
    property color color: "#A7F3D0"
    property color colSymbol: "#064E3B"
    property string text: ""
    property string fallbackText: "●"
    property string iconFontFamily: "Segoe Fluent Icons"
    property bool useSymbolFont: true
    property int iconSize: 18
    property int padding: 8

    implicitWidth: iconSize + padding * 2
    implicitHeight: iconSize + padding * 2

    MaterialShape {
        anchors.fill: parent
        shape: badgeRoot.shape
        color: badgeRoot.color
        implicitSize: Math.min(badgeRoot.width, badgeRoot.height)
    }

    Text {
        anchors.centerIn: parent
        font.family: badgeRoot.iconFontFamily
        font.pixelSize: badgeRoot.iconSize
        text: badgeRoot.useSymbolFont ? badgeRoot.text : badgeRoot.fallbackText
        color: badgeRoot.colSymbol
    }
}
