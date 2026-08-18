import QtQuick
import QtQuick.Layouts
import "../.."
import "../../../"
import "../../../services"

Item {
    id: root

    Layout.fillWidth: true
    Layout.fillHeight: true

    property bool settingsOpen: false

    readonly property real ringSize: Theme.isSmallScreen ? Theme.scaled(200) : Theme.scaled(240)
    readonly property real ringWidth: Theme.scaled(8)

    readonly property color phaseColor: {
        if (ProductivityService.isBeeping) return Theme.powerRed;
        if (ProductivityService.phase === "shortBreak") return Theme.green;
        if (ProductivityService.phase === "longBreak") return Theme.lavender;
        return Theme.accentColor;
    }

    function phaseLabel() {
        if (ProductivityService.isBeeping) return "Done";
        if (ProductivityService.phase === "shortBreak") return "Short Break";
        if (ProductivityService.phase === "longBreak") return "Long Break";
        return "Focus";
    }

    function timeString() {
        let m = Math.floor(ProductivityService.remaining / 60);
        let s = ProductivityService.remaining % 60;
        return m + ":" + s.toString().padStart(2, '0');
    }

    function phaseProgress() {
        let d = ProductivityService.duration;
        if (d <= 0) return 0;
        return Math.max(0, Math.min(1, ProductivityService.remaining / d));
    }

    function filledDots() {
        let n = ProductivityService.completedFocus % ProductivityService.breakEvery;
        if (n === 0 && ProductivityService.phase === "longBreak") return ProductivityService.breakEvery;
        return n;
    }

    function minLabel(secs) {
        let m = Math.round(secs / 60);
        return m + "m";
    }

    // Keyboard shortcuts (dispatched from the ControlCenter via PomodoroContent)
    function handleKeys(event) {
        if (event.key === Qt.Key_Space) {
            ProductivityService.toggleTimer();
            event.accepted = true;
        } else if (event.key === Qt.Key_R) {
            ProductivityService.resetTimer();
            event.accepted = true;
        } else if (event.key === Qt.Key_S) {
            ProductivityService.skipPhase();
            event.accepted = true;
        }
    }

    // Close the settings panel automatically when a session starts
    Connections {
        target: ProductivityService
        function onRunningChanged() {
            if (ProductivityService.running) root.settingsOpen = false;
        }
    }

    // --- SETTINGS GEAR (only while idle) ---
    Rectangle {
        id: gearBtn
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: -Theme.scaled(4)
        anchors.rightMargin: -Theme.scaled(4)
        width: Theme.scaled(30)
        height: Theme.scaled(30)
        radius: width / 2
        visible: !ProductivityService.running && !ProductivityService.isBeeping
        color: gearMouse.containsMouse ? Theme.surfaceContainerHigh : "transparent"
        Behavior on color { ColorAnimation { duration: Theme.animFast } }

        Text {
            anchors.centerIn: parent
            text: "󰘚"
            font.family: Theme.iconFont
            font.pixelSize: Theme.scaled(14)
            color: root.settingsOpen ? Theme.accentColor : (gearMouse.containsMouse ? Theme.text : Theme.subtext1)
            Behavior on color { ColorAnimation { duration: Theme.animFast } }
        }
        MouseArea {
            id: gearMouse
            anchors.fill: parent
            hoverEnabled: true
            onClicked: root.settingsOpen = !root.settingsOpen
        }
    }

    ColumnLayout {
        anchors.centerIn: parent
        width: parent.width * 0.92
        spacing: Theme.scaled(14)

        // --- PHASE LABEL ---
        Text {
            Layout.alignment: Qt.AlignHCenter
            text: root.phaseLabel().toUpperCase()
            font.pixelSize: Theme.scaled(10)
            font.weight: Font.Black
            font.letterSpacing: 3
            color: root.phaseColor
            Behavior on color { ColorAnimation { duration: 250 } }
        }

        // --- PROGRESS RING (click toggles) ---
        Item {
            Layout.alignment: Qt.AlignHCenter
            width: root.ringSize
            height: root.ringSize

            Canvas {
                id: ring
                anchors.fill: parent
                property real progress: root.phaseProgress()

                onPaint: {
                    let ctx = getContext("2d");
                    ctx.reset();
                    let c = width / 2;
                    let r = c - root.ringWidth / 2;
                    ctx.lineCap = "round";

                    ctx.beginPath();
                    ctx.arc(c, c, r, 0, Math.PI * 2);
                    ctx.strokeStyle = Qt.rgba(1, 1, 1, 0.08);
                    ctx.lineWidth = root.ringWidth;
                    ctx.stroke();

                    if (progress > 0) {
                        ctx.beginPath();
                        ctx.arc(c, c, r, -Math.PI / 2, -Math.PI / 2 + progress * Math.PI * 2);
                        ctx.strokeStyle = root.phaseColor;
                        ctx.lineWidth = root.ringWidth;
                        ctx.stroke();
                    }
                }

                onProgressChanged: requestPaint()
            }

            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.scaled(2)
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: root.timeString()
                    font.pixelSize: Theme.isSmallScreen ? Theme.scaled(44) : Theme.scaled(54)
                    font.weight: Font.Black
                    font.letterSpacing: 1
                    color: ProductivityService.isBeeping ? Theme.powerRed : Theme.text
                    Behavior on color { ColorAnimation { duration: 250 } }
                }
                Text {
                    Layout.alignment: Qt.AlignHCenter
                    text: ProductivityService.isBreak ? "break" : "session"
                    font.pixelSize: Theme.scaled(9)
                    font.weight: Font.Bold
                    font.letterSpacing: 3
                    color: Theme.subtext1
                }
            }

            MouseArea {
                id: ringMouse
                anchors.fill: parent
                hoverEnabled: true
                cursorShape: Qt.PointingHandCursor
                onClicked: ProductivityService.toggleTimer()
            }
        }

        // --- CYCLE DOTS ---
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.scaled(7)
            Repeater {
                model: ProductivityService.breakEvery
                delegate: Rectangle {
                    width: Theme.scaled(7)
                    height: Theme.scaled(7)
                    radius: width / 2
                    color: index < root.filledDots() ? root.phaseColor : Qt.rgba(1, 1, 1, 0.12)
                    Behavior on color { ColorAnimation { duration: 300 } }
                }
            }
        }

        // --- CONTROLS ---
        RowLayout {
            Layout.alignment: Qt.AlignHCenter
            spacing: Theme.scaled(26)

            Text {
                text: "Skip"
                font.pixelSize: Theme.scaled(11)
                font.weight: Font.Bold
                color: skipHover.containsMouse ? Theme.text : Theme.subtext1
                MouseArea {
                    id: skipHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ProductivityService.skipPhase()
                }
            }

            // Play / Pause / Dismiss
            Rectangle {
                width: Theme.scaled(62)
                height: Theme.scaled(62)
                radius: width / 2
                color: ProductivityService.isBeeping ? Theme.powerRed : root.phaseColor
                Behavior on color { ColorAnimation { duration: 250 } }

                SequentialAnimation on scale {
                    running: ProductivityService.isBeeping
                    loops: Animation.Infinite
                    NumberAnimation { from: 1.0; to: 0.92; duration: 500 }
                    NumberAnimation { from: 0.92; to: 1.0; duration: 500 }
                }

                Text {
                    anchors.centerIn: parent
                    text: ProductivityService.isBeeping ? "󰂚" : (ProductivityService.running ? "󰏤" : "󰐊")
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(26)
                    color: Theme.base
                    anchors.horizontalCenterOffset: (!ProductivityService.running && !ProductivityService.isBeeping) ? 3 : 0
                }

                MouseArea {
                    anchors.fill: parent
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ProductivityService.toggleTimer()
                }
            }

            Text {
                text: "Reset"
                font.pixelSize: Theme.scaled(11)
                font.weight: Font.Bold
                color: resetHover.containsMouse ? Theme.text : Theme.subtext1
                MouseArea {
                    id: resetHover
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: ProductivityService.resetTimer()
                }
            }
        }

        // --- COLLAPSIBLE SETTINGS ---
        Rectangle {
            Layout.fillWidth: true
            height: root.settingsOpen ? settingsCol.implicitHeight + Theme.scaled(10) : 0
            clip: true
            radius: Theme.scaled(12)
            color: Qt.rgba(0, 0, 0, 0.22)
            Behavior on height { NumberAnimation { duration: 220; easing.type: Easing.OutCubic } }

            ColumnLayout {
                id: settingsCol
                anchors.fill: parent
                anchors.margins: Theme.scaled(5)
                spacing: Theme.scaled(6)
                opacity: root.settingsOpen ? 1 : 0
                Behavior on opacity { NumberAnimation { duration: 160 } }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.scaled(8)

                    Step { label: "FOCUS"; value: root.minLabel(ProductivityService.focusLength); onDec: ProductivityService.setFocusLength(ProductivityService.focusLength - 300); onInc: ProductivityService.setFocusLength(ProductivityService.focusLength + 300) }
                    Step { label: "BREAK"; value: root.minLabel(ProductivityService.shortBreakLength); onDec: ProductivityService.setShortBreakLength(ProductivityService.shortBreakLength - 60); onInc: ProductivityService.setShortBreakLength(ProductivityService.shortBreakLength + 60) }
                    Step { label: "LONG"; value: root.minLabel(ProductivityService.longBreakLength); onDec: ProductivityService.setLongBreakLength(ProductivityService.longBreakLength - 300); onInc: ProductivityService.setLongBreakLength(ProductivityService.longBreakLength + 300) }
                }

                RowLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignHCenter
                    spacing: Theme.scaled(8)

                    Step { label: "CYCLE"; value: "x" + ProductivityService.breakEvery; onDec: ProductivityService.setBreakEvery(ProductivityService.breakEvery - 1); onInc: ProductivityService.setBreakEvery(ProductivityService.breakEvery + 1) }

                    Rectangle {
                        implicitHeight: Theme.scaled(34)
                        implicitWidth: autoText.implicitWidth + Theme.scaled(24)
                        radius: Theme.scaled(10)
                        color: ProductivityService.autoAdvance ? Qt.alpha(Theme.accentColor, 0.2) : Theme.surface0
                        border.color: ProductivityService.autoAdvance ? Theme.accentColor : "transparent"
                        border.width: 1
                        Text {
                            id: autoText
                            anchors.centerIn: parent
                            text: "AUTO"
                            font.pixelSize: Theme.scaled(10)
                            font.weight: Font.Black
                            font.letterSpacing: 1
                            color: ProductivityService.autoAdvance ? Theme.accentColor : Theme.subtext1
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ProductivityService.setAutoAdvance(!ProductivityService.autoAdvance)
                        }
                    }

                    Rectangle {
                        implicitHeight: Theme.scaled(34)
                        implicitWidth: cycleText.implicitWidth + Theme.scaled(24)
                        radius: Theme.scaled(10)
                        color: Theme.surface0
                        Text {
                            id: cycleText
                            anchors.centerIn: parent
                            text: "New Cycle"
                            font.pixelSize: Theme.scaled(10)
                            font.weight: Font.Black
                            font.letterSpacing: 1
                            color: Theme.subtext1
                        }
                        MouseArea {
                            anchors.fill: parent
                            cursorShape: Qt.PointingHandCursor
                            onClicked: ProductivityService.resetCycle()
                        }
                    }
                }
            }
        }
    }

    component Step: Rectangle {
        id: step
        signal inc()
        signal dec()
        property string label
        property string value

        implicitHeight: Theme.scaled(34)
        implicitWidth: Theme.scaled(140)
        radius: Theme.scaled(10)
        color: Theme.surface0
        border.color: Theme.glassBorder
        border.width: 1

        RowLayout {
            anchors.fill: parent
            anchors.leftMargin: Theme.scaled(10)
            anchors.rightMargin: Theme.scaled(10)
            spacing: Theme.scaled(8)

            Text {
                text: step.label
                font.pixelSize: Theme.scaled(9)
                font.weight: Font.Black
                font.letterSpacing: 1
                color: Theme.subtext1
            }
            Item { Layout.fillWidth: true }
            Text {
                text: "−"
                font.pixelSize: Theme.scaled(14)
                font.weight: Font.Bold
                color: minus.containsMouse ? Theme.text : Theme.subtext1
                MouseArea {
                    id: minus
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: step.dec()
                }
            }
            Text {
                text: step.value
                font.pixelSize: Theme.scaled(11)
                font.weight: Font.Black
                color: Theme.text
                horizontalAlignment: Text.AlignHCenter
                Layout.minimumWidth: Theme.scaled(34)
            }
            Text {
                text: "+"
                font.pixelSize: Theme.scaled(14)
                font.weight: Font.Bold
                color: plus.containsMouse ? Theme.text : Theme.subtext1
                MouseArea {
                    id: plus
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onClicked: step.inc()
                }
            }
        }
    }
}
