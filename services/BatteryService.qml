// services/BatteryService.qml
import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

pragma Singleton

Item {
    id: service

    // Core Properties
    property int percentage: -1
    property string status: "unknown"
    property bool acOnline: false
    
    // Technical Detail Properties
    property int cycleCount: 0
    property real voltage: 0.0
    property real energyRate: 0.0

    // Visibility & Notification Flags
    property bool isFullyCharged: (status === "full" || (status === "charging" && percentage >= 100))
    property bool isConservative: (status === "not charging" || status === "idle") && acOnline

    // Internal State
    property string batPath: ""
    property string acPath: ""
    property string lastStatus: ""
    property bool lastAcState: false
    property int lastThreshold: 100
    property int updatesReceived: 0
    property string timeRemaining: "Calculating..."
    property real energyNow: 0.0
    property real health: 0
    property real temp: 0

    function update() {
        if (!updateExec.running) {
            updateExec.running = true;
        }
    }

    function getIconName(p, s) {
        let name = "";
        if (s === "charging" || s === "full") {
            if (p >= 100) name = "battery-level-100-charged-symbolic";
            else if (p >= 90) name = "battery-level-90-charging-symbolic";
            else if (p >= 80) name = "battery-level-80-charging-symbolic";
            else if (p >= 70) name = "battery-level-70-charging-symbolic";
            else if (p >= 60) name = "battery-level-60-charging-symbolic";
            else if (p >= 50) name = "battery-level-50-charging-symbolic";
            else if (p >= 40) name = "battery-level-40-charging-symbolic";
            else if (p >= 30) name = "battery-level-30-charging-symbolic";
            else if (p >= 20) name = "battery-level-20-charging-symbolic";
            else if (p >= 10) name = "battery-level-10-charging-symbolic";
            else name = "battery-level-0-charging-symbolic";
        } else {
            if (p >= 100) name = "battery-level-100-symbolic";
            else if (p >= 90) name = "battery-level-90-symbolic";
            else if (p >= 80) name = "battery-level-80-symbolic";
            else if (p >= 70) name = "battery-level-70-symbolic";
            else if (p >= 60) name = "battery-level-60-symbolic";
            else if (p >= 50) name = "battery-level-50-symbolic";
            else if (p >= 40) name = "battery-level-40-symbolic";
            else if (p >= 30) name = "battery-level-30-symbolic";
            else if (p >= 20) name = "battery-level-20-symbolic";
            else if (p >= 10) name = "battery-level-10-symbolic";
            else name = "battery-level-0-symbolic";
        }
        return name;
    }

    function sendNotify(title, msg, urgency) {
        if (updatesReceived < 2 || status === "" || status === "unknown")
            return;

        let iconName = getIconName(percentage, status);
        let u = urgency || "normal";
        notifyProc.command = ["notify-send", "-u", u, "-a", "Battery", "-i", iconName, title, msg];
        notifyProc.running = false;
        notifyProc.running = true;
    }

    onAcOnlineChanged: {
        if (updatesReceived < 2) {
            lastAcState = acOnline;
            return;
        }

        if (acOnline === lastAcState) return;

        if (acOnline) {
            sendNotify("Power Connected", "Finally, I can breathe again. Thanks for the juice.");
        } else {
            sendNotify("Power Disconnected", "Running Wild. Hope you're near an outlet.");
        }
        lastAcState = acOnline;
    }

    onStatusChanged: {
        let s = status.toLowerCase().trim();
        if (updatesReceived < 2) {
            if (s !== "" && s !== "unknown") {
                lastStatus = s;
                updatesReceived++;
            }
            return;
        }

        if (s === lastStatus || s === "unknown" || s === "") return;

        if (s === "full") {
            sendNotify("Battery Full", "Charging complete. Ready to unplug.");
        } else if (s === "not charging" && acOnline) {
            sendNotify("Conservative Mode", "Charging limit reached. Staying healthy.");
        }

        lastStatus = s;
    }

    onPercentageChanged: {
        if (updatesReceived < 2) {
            if (percentage > 0) {
                if (percentage <= 1) lastThreshold = 1;
                else if (percentage <= 3) lastThreshold = 3;
                else if (percentage <= 5) lastThreshold = 5;
                else if (percentage <= 10) lastThreshold = 10;
                else if (percentage <= 20) lastThreshold = 20;
                else lastThreshold = 100;
                updatesReceived++;
            }
            return;
        }

        if (status === "charging" || status === "full" || status === "not charging") {
            if (percentage > 20 && lastThreshold !== 100) lastThreshold = 100;
            return;
        }

        if (percentage <= 1 && lastThreshold > 1) {
            sendNotify("Goodbye, Cruel World", "1%? This is it.", "critical");
            lastThreshold = 1;
        } else if (percentage <= 3 && lastThreshold > 3) {
            sendNotify("Panic Mode", "3% left.", "critical");
            lastThreshold = 3;
        } else if (percentage <= 5 && lastThreshold > 5) {
            sendNotify("Critical", "5%. PLUG. ME. IN.", "critical");
            lastThreshold = 5;
        } else if (percentage <= 10 && lastThreshold > 10) {
            sendNotify("Low Battery", "10%. Getting dangerously low.", "critical");
            lastThreshold = 10;
        } else if (percentage <= 20 && lastThreshold > 20) {
            sendNotify("Battery Warning", "20%. Just a heads up, I'm getting hungry.", "normal");
            lastThreshold = 20;
        }
    }

    Component.onCompleted: service.update()

    function formatTime(seconds) {
        if (seconds <= 0 || isNaN(seconds) || seconds === Infinity) return "N/A";
        const h = Math.floor(seconds / 3600);
        const m = Math.floor((seconds % 3600) / 60);
        return h + "h " + m + "m";
    }

    Process {
        id: updateExec
        command: ["python3", PathSettings.scriptsDir + "/battery_info.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    const data = JSON.parse(text);
                    service.acOnline = data.acOnline || false;
                    let batCount = data.count || 0;

                    if (batCount > 0) {
                        let totalNow = data.now || 0;
                        let totalFull = data.full || 0;
                        let totalDesign = data.design || 0;
                        let totalRate = data.rate || 0;

                        service.percentage = totalFull > 0 ? Math.round((totalNow / totalFull) * 100) : 0;

                        let mainStatus = "unknown";
                        if (data.statuses && data.statuses.length > 0) {
                            if (data.statuses.includes("charging")) mainStatus = "charging";
                            else if (data.statuses.includes("discharging")) mainStatus = "discharging";
                            else if (data.statuses.includes("full")) mainStatus = "full";
                            else mainStatus = data.statuses[0];
                        }
                        service.status = mainStatus;
                        service.cycleCount = data.cycles || 0;
                        service.voltage = batCount > 0 ? ((data.volt || 0) / batCount) / 1000000 : 0.0;
                        service.energyRate = totalRate;
                        service.energyNow = totalNow;
                        service.health = totalDesign > 0 ? (totalFull / totalDesign) * 100 : 0;

                        if (service.status === "discharging" && totalRate > 0) {
                            service.timeRemaining = service.formatTime((totalNow / totalRate) * 3600);
                        } else if (service.status === "charging" && totalRate > 0) {
                            service.timeRemaining = service.formatTime(((totalFull - totalNow) / totalRate) * 3600) + " to full";
                        } else {
                            service.timeRemaining = "N/A";
                        }
                    }

                    if (data.temp !== undefined) {
                        service.temp = data.temp;
                    }
                } catch (e) {}
            }
        }
    }

    Process { id: notifyProc }

    Process {
        id: udevMonitor
        command: ["udevadm", "monitor", "--subsystem-match=power_supply"]
        running: true
        stdout: SplitParser {
            onRead: (data) => udevDebounceTimer.restart()
        }
        onExited: udevDelay.start()
    }

    Timer {
        id: udevDebounceTimer
        interval: 250
        repeat: false
        onTriggered: service.update()
    }

    Timer {
        id: udevDelay
        interval: 2000
        onTriggered: udevMonitor.running = true
    }

    Timer {
        id: pollTimer
        interval: service.status === "charging" ? 15000 : 60000
        repeat: true
        running: true
        onTriggered: service.update()
        onIntervalChanged: restart()
    }

}
