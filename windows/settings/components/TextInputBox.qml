pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../../../" as Shell

Rectangle {
    id: control
    width: Shell.Theme.scaled(150)
    height: Shell.Theme.scaled(32)
    radius: Shell.Theme.scaled(8)
    color: Shell.Colors.surface_variant
    
    property alias text: input.text
    signal accepted(string text)

    TextInput {
        id: input
        anchors.fill: parent
        anchors.leftMargin: Shell.Theme.scaled(10)
        verticalAlignment: TextInput.AlignVCenter
        color: Shell.Colors.on_background
        font.pixelSize: Shell.Theme.scaled(14)
        onAccepted: control.accepted(text)
    }
}
