pragma ComponentBehavior: Bound
import "../../.."
import QtQuick
import QtQuick.Controls
import QtQuick.Layouts

ColumnLayout {
    id: root

    // ===== API =====
    property string label: ""
    property string icon: ""
    property int value: 0
    property var onChange: null
    property color sliderColor: Colors.primary

    spacing: Theme.scaled(8)
    Layout.fillWidth: true

    // --- Header Section ---
    RowLayout {
        spacing: Theme.scaled(12)
        Layout.fillWidth: true

        Rectangle {
            width: Theme.scaled(38); height: Theme.scaled(38); radius: Theme.scaled(12)
            color: Colors.surface_variant; border.color: Colors.surface_variant
            Text {
                anchors.centerIn: parent
                text: root.icon; font.family: Theme.iconFont
                font.pixelSize: Theme.scaled(18); color: root.sliderColor
            }
        }

        ColumnLayout {
            spacing: 0; Layout.fillWidth: true
            Text { 
                text: root.label.toUpperCase()
                color: Colors.primary; font.weight: Font.Black
                font.pixelSize: Theme.scaled(11); font.letterSpacing: 1.5 
            }
            Text { 
                text: root.value + "%"
                color: Colors.on_background; font.family: Constants.monoFont
                font.weight: Font.Bold; font.pixelSize: Theme.scaled(13) 
            }
        }
    }

    // --- Slider Section ---
    Slider {
        id: control
        Layout.fillWidth: true
        from: 0; to: 100
        value: 0

        // Reset all paddings for pixel-perfect alignment
        padding: 0
        leftPadding: 0
        rightPadding: 0
        topPadding: 0
        bottomPadding: 0

        readonly property real handleWidth: Theme.scaled(24)

        // No `value: root.value` binding: the model updates late and would
        // re-snap the handle mid-drag, causing jitter. Sync manually below.
        property real pendingValue: -1
        property double lastWriteMs: -2000

        onMoved: {
            pendingValue = Math.round(value);
            lastWriteMs = Date.now();
            pushTimer.restart();
        }

        onPressedChanged: {
            if (!control.pressed) {
                pushTimer.stop();
                if (pendingValue >= 0) {
                    lastWriteMs = Date.now();
                    if (root.onChange) root.onChange(pendingValue);
                    pendingValue = -1;
                }
            }
        }

        Component.onCompleted: control.value = root.value

        Connections {
            target: root
            function onValueChanged() {
                // Follow external changes, but never fight the user mid-drag
                // and ignore stale in-flight reads that land right after a
                // write (they'd snap the handle back to an old value).
                if (control.pressed) return;
                if (Date.now() - control.lastWriteMs < 800) return;
                control.value = Math.max(control.from, Math.min(control.to, root.value));
            }
        }

        // Debounce: drags emit onMoved many times per second; throttle the
        // wpctl pushes so commands don't pile up and race each other.
        Timer {
            id: pushTimer
            interval: 90
            repeat: true
            onTriggered: {
                if (control.pendingValue >= 0 && root.onChange) root.onChange(control.pendingValue);
            }
        }

        // --- THE HANDLE ---
        handle: Rectangle {
            x: control.leftPadding + control.visualPosition * (control.availableWidth - width)
            y: control.topPadding + (control.availableHeight - height) / 2
            
            implicitWidth: control.handleWidth
            implicitHeight: control.handleWidth
            radius: width / 2
            color: Colors.on_background
            border.color: root.sliderColor
            border.width: Theme.scaled(3)
            
            // Interaction feedback
            scale: control.pressed ? 1.15 : (control.hovered ? 1.05 : 1.0)
            
            Behavior on scale { NumberAnimation { duration: 150; easing.type: Easing.OutBack } }
            
            // Subtle inner dot for that "pro" look
            Rectangle {
                anchors.centerIn: parent
                width: Theme.scaled(6); height: Theme.scaled(6); radius: Theme.scaled(3)
                color: root.sliderColor; opacity: control.pressed ? 1 : 0.5
            }
        }

        // --- THE TRACK ---
        background: Rectangle {
            id: bg
            x: control.leftPadding + control.handleWidth / 2
            y: control.topPadding + (control.availableHeight - height) / 2
            width: control.availableWidth - control.handleWidth
            height: Theme.scaled(12) 
            radius: Theme.scaled(6)
            color: Colors.surface_variant
            border.color: Colors.surface_variant; border.width: 1

            // The Progress Fill
            Rectangle {
                width: control.visualPosition * parent.width
                height: parent.height
                color: root.sliderColor
                radius: Theme.scaled(6)

                // Smoothly clip the right side of the fill to match handle center
                layer.enabled: true
            }
        }
    }
}