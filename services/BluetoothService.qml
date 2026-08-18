pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

Item {
    id: root

    // --- State Variables ---
    property var devices: []
    property int deviceCount: devices.length
    property bool powered: false
    property bool connected: false
    property bool scanning: false
    property bool serviceActive: true
    property bool isServiceEnabled: false
    property string state: "Idle"
    
    readonly property bool isPerformingAction: actionExec.running || powerExec.running || scanExec.running || oneShotScan.running || _actionInProgress || startupToggleExec.running
    readonly property bool isRefreshing: statusExec.running
    property bool busy: isPerformingAction || isRefreshing
    
    property bool _actionInProgress: false

    // Primary connected device info
    property string connectedName: ""
    property string connectedAddress: ""
    property int connectedBattery: -1
    property string connectedIcon: "bluetooth"

    function refresh(full) {
        if (statusExec.running) return;
        let doFull = (full !== undefined) ? full : Variables.quickSettingsOpen;
        statusExec.command = ["python3", PathSettings.scriptsDir + "/bt_status.py", doFull ? "full" : ""];
        statusExec.running = true;
    }

    Process {
        id: statusExec
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    let data = JSON.parse(text);
                    root.powered = data.powered || false;
                    root.scanning = data.scanning || false;
                    root.connected = data.connected || false;
                    root.connectedName = data.connectedName || "";
                    root.connectedAddress = data.connectedAddress || "";
                    root.connectedBattery = data.connectedBattery !== undefined ? data.connectedBattery : -1;
                    root.connectedIcon = data.connectedIcon || "bluetooth";
                    root.serviceActive = data.serviceActive || false;
                    root.isServiceEnabled = data.isServiceEnabled || false;

                    if (!root.serviceActive) {
                        root.state = "Service Error";
                    } else if (root.state === "Service Error" || root.state === "Idle" || root.state === "Scanning") {
                        root.state = root.scanning ? "Scanning" : "Idle";
                    }

                    if (data.devices && Array.isArray(data.devices)) {
                        updateModel(data.devices);
                    }
                } catch (e) {}
            }
        }
    }

    function toggleStartup() {
        let target = !isServiceEnabled;
        startupToggleExec.command = ["pkexec", "systemctl", target ? "enable" : "disable", "bluetooth.service"];
        startupToggleExec.running = true;
    }

    Process {
        id: startupToggleExec
        onExited: (exitCode) => {
            if (exitCode === 0) {
                root.refresh(false);
            }
        }
    }

    function restartService() {
        root.state = "Restarting Service";
        actionExec.command = ["pkexec", "systemctl", "restart", "bluetooth"];
        actionExec.running = true;
    }

    function updateModel(newDevices) {
        newDevices.sort((a, b) => {
            if (a.connected !== b.connected) return a.connected ? -1 : 1;
            if (a.paired !== b.paired) return a.paired ? -1 : 1;
            return a.name.localeCompare(b.name);
        });
        root.devices = newDevices;
    }

    function togglePower() {
        if (isPerformingAction) return;
        let newState = !powered;
        root.state = newState ? "Powering On" : "Powering Off";
        _actionInProgress = true;
        root.powered = newState;
        
        powerExec.command = ["bluetoothctl", "power", newState ? "on" : "off"];
        powerExec.running = true;
    }

    function toggleScan() {
        if (isPerformingAction) return;
        let target = !scanning;
        root.state = target ? "Starting Scan" : "Stopping Scan";
        root.scanning = target;
        
        scanExec.command = ["bluetoothctl", "scan", target ? "on" : "off"];
        scanExec.running = true;
    }

    function startScan() {
        if (!powered || scanning || isPerformingAction) return;
        root.state = "Starting Scan";
        root.scanning = true;
        scanExec.command = ["bluetoothctl", "scan", "on"];
        scanExec.running = true;
    }

    function stopScan() {
        if (!scanning || isPerformingAction) return;
        root.state = "Stopping Scan";
        root.scanning = false;
        scanExec.command = ["bluetoothctl", "scan", "off"];
        scanExec.running = true;
    }

    function action(mode, addr) {
        if (isPerformingAction) return;
        if (!addr || !/^[0-9A-Fa-f:]{17}$/.test(addr)) return;
        root.state = mode.charAt(0).toUpperCase() + mode.slice(1) + "ing...";

        let cmd = "";
        if (mode === "connect") {
             cmd = `(bluetoothctl trust "$1" && (bluetoothctl pair "$1" || true) && bluetoothctl connect "$1") || bluetoothctl connect "$1"`;
        } else if (mode === "pair") {
             cmd = `bluetoothctl trust "$1" && (bluetoothctl pair "$1" || true)`;
        } else if (mode === "disconnect") {
             cmd = `bluetoothctl disconnect "$1"`;
        } else if (mode === "remove") {
             cmd = `bluetoothctl remove "$1"`;
        }

        actionExec.command = ["sh", "-c", cmd, "bluetoothctl", addr];
        actionExec.running = true;
    }

    Process { id: oneShotScan; command: ["sh", "-c", "bluetoothctl --timeout 10 scan on & bluetoothctl --timeout 10 discoverable on; wait"] }
    
    Timer {
        id: postActionPoll
        interval: 1000
        repeat: true
        property int count: 0
        onTriggered: {
            refresh(true);
            count++;
            if (count >= 3) stop();
        }
        function trigger() {
            count = 0;
            restart();
        }
    }

    Process { id: powerExec; onExited: { _actionInProgress = false; root.state = "Idle"; postActionPoll.trigger(); } }
    Process { id: scanExec; onExited: { root.state = "Idle"; postActionPoll.trigger(); } }
    Process { id: actionExec; onExited: { root.state = "Idle"; postActionPoll.trigger(); } }

    // Event-driven Bluetooth Monitor
    Process {
        id: btMonitor
        command: ["bluetoothctl", "monitor"]
        running: true
        stdout: SplitParser {
            onRead: (data) => root.refresh(false)
        }
        onExited: restartBtMon.start()
    }

    Timer {
        id: restartBtMon
        interval: 3000
        onTriggered: btMonitor.running = true
    }

    Timer {
        id: btStartupTimer
        interval: 800
        running: true
        repeat: false
        onTriggered: root.refresh(false)
    }
}