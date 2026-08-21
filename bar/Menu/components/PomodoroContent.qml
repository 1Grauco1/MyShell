pragma ComponentBehavior: Bound
import QtQuick
import QtQuick.Layouts
import "../.."
import "../../../"

Item {
    id: root

    TimerContent {
        id: timerContent
        anchors.fill: parent
    }

    function handleKeys(event) {
        timerContent.handleKeys(event);
    }
}
