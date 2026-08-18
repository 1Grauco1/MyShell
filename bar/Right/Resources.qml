// bar/Right/Resources.qml
import ".."
import "../.."
import "../../services"
import QtQuick
import QtQuick.Layouts
import Quickshell

Item {
    id: root

    height: Theme.pillHeight
    implicitHeight: Theme.pillHeight
    Layout.preferredHeight: Theme.pillHeight
    Layout.alignment: Qt.AlignVCenter
    implicitWidth: outerContainer.width

    // Outer Glass Container matching QuickSettingsCluster exactly
    Rectangle {
        id: outerContainer
        height: Theme.pillHeight
        implicitHeight: Theme.pillHeight
        width: catSprite.width + Theme.scaled(18)
        implicitWidth: width
        radius: height / 2
        color: Theme.pillColor
        border.color: Theme.glassBorder
        border.width: 1
        clip: true

        MouseArea {
            anchors.fill: parent
            hoverEnabled: true
            cursorShape: Qt.PointingHandCursor
            onClicked: (mouse) => {
                if (mouse.button === Qt.LeftButton)
                    QuickSettingsService.toggle("powerprofile");
            }
        }

        // Power Profile Animated Avatar Sub-Widget
        AnimatedImage {
            id: catSprite
            anchors.centerIn: parent
            source: "../../assets/power.gif"
            width: Theme.scaled(35)
            height: Theme.scaled(35)
            fillMode: Image.PreserveAspectFit
        }
    }
}
