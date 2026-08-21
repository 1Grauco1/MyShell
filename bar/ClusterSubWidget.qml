pragma ComponentBehavior: Bound
import ".."
import "../.."
import QtQuick
import QtQuick.Layouts

Item {
    id: root

    property alias iconText: iconLabel.text
    property color iconColor: Theme.fontColor
    property color hoverIconColor: iconColor
    property alias label: labelItem.text
    property alias labelVisible: labelItem.visible
    property alias labelColor: labelItem.color
    property alias labelFont: labelItem.font

    signal clicked(var mouse)

    height: Theme.scaled(28)
    implicitHeight: Theme.scaled(28)
    implicitWidth: contentRow.implicitWidth + Theme.scaled(10)
    Layout.preferredWidth: implicitWidth
    Layout.preferredHeight: implicitHeight
    Layout.alignment: Qt.AlignVCenter

    Rectangle {
        anchors.fill: parent
        radius: height / 2
        color: mouseArea.containsMouse ? Theme.surfaceContainerHigh : "transparent"

        Behavior on color { ColorAnimation { duration: 150 } }
    }

    RowLayout {
        id: contentRow
        anchors.centerIn: parent
        spacing: Theme.scaled(4)

        Text {
            id: iconLabel
            font.family: Theme.iconFont
            font.pixelSize: Theme.scaled(Theme.iconSize + 1)
            color: mouseArea.containsMouse ? root.hoverIconColor : root.iconColor
            Layout.alignment: Qt.AlignVCenter

            Behavior on color { ColorAnimation { duration: 150 } }
        }

        Text {
            id: labelItem
            visible: false
            font.pixelSize: Theme.fontSize
            font.family: Constants.monoFont
            Layout.alignment: Qt.AlignVCenter
        }
    }

    MouseArea {
        id: mouseArea
        anchors.fill: parent
        hoverEnabled: true
        cursorShape: Qt.PointingHandCursor
        acceptedButtons: Qt.LeftButton | Qt.RightButton
        onClicked: (mouse) => root.clicked(mouse)
    }
}
