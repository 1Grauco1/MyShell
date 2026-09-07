pragma ComponentBehavior: Bound
// services/BrightnessService.qml
import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

pragma Singleton

Item {
    id: service

    property int brightness: -1
    property bool hasBacklight: false

    function update() {
        if (!readExec.running) {
            readExec.running = true;
        }
    }

    function setBrightness(percent) {
        let pct = Math.max(0, Math.min(100, Math.round(percent)));
        setExec.command = ["sh", "-c", "b=" + pct + "; for d in /sys/class/backlight/*; do test -w \"$d/brightness\" || continue; m=$(cat \"$d/max_brightness\" 2>/dev/null); test -n \"${m:-}\" || continue; v=$(( b * m / 100 )); echo $v > \"$d/brightness\" 2>/dev/null && break; done"];
        setExec.running = false;
        setExec.running = true;
    }

    Process { id: setExec; onExited: service.update() }

    Process {
        id: readExec
        command: ["sh", "-c", "for d in /sys/class/backlight/*; do test -r \"$d/brightness\" || continue; b=$(cat \"$d/brightness\" 2>/dev/null); m=$(cat \"$d/max_brightness\" 2>/dev/null); test -n \"${b:-}\" -a -n \"${m:-}\" || continue; if test $m -gt 0; then p=$(( b * 100 / m )); else p=0; fi; echo \"$p\"; break; done; exit 0"]
        stdout: SplitParser {
            onRead: (data) => {
                let line = data.trim();
                if (line === "") {
                    service.hasBacklight = false;
                    return;
                }
                let pct = parseInt(line);
                if (isNaN(pct)) return;
                service.hasBacklight = true;
                if (pct !== service.brightness) {
                    service.brightness = pct;
                }
            }
        }
    }

    Timer {
        id: pollTimer
        interval: 500
        repeat: true
        running: true
        onTriggered: service.update()
    }

    Component.onCompleted: service.update()
}
