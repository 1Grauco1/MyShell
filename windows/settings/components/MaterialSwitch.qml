pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Controls
import "../../../" as Shell

Switch {
    id: control
    indicator: Rectangle {
        implicitWidth: Shell.Theme.scaled(40)
        implicitHeight: Shell.Theme.scaled(20)
        x: control.leftPadding
        y: parent.height / 2 - height / 2
        radius: Shell.Theme.scaled(10)
        color: control.checked ? Shell.Colors.primary : Shell.Colors.surface_variant
        
        Rectangle {
            x: control.checked ? parent.width - width - Shell.Theme.scaled(2) : Shell.Theme.scaled(2)
            y: Shell.Theme.scaled(2)
            width: Shell.Theme.scaled(16); height: Shell.Theme.scaled(16)
            radius: Shell.Theme.scaled(8)
            color: Shell.Colors.on_background
            Behavior on x { NumberAnimation { duration: 200 } }
        }
    }
}
