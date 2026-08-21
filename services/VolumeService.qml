pragma ComponentBehavior: Bound
// services/VolumeService.qml
import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"
import ".."
pragma Singleton

Item {
    id: service

    property int outputVolume: 0
    property int micVolume: 0
    property bool muted: false
    property bool micMuted: false 
    property bool micActive: false
    property bool streamActive: false
    property bool btActive: false
    property var sinks: []
    property var sources: []
    property int activeSinkId: -1
    property int activeSourceId: -1

    // Tracks when the user last wrote a stream volume (appId -> ms). Read-backs
    // are stale races during/right after a drag, so processData ignores them.
    property var lastAppVolWrite: ({})

    readonly property alias appsModel: appModel

    function updateAppVolume(appId, vol) {
        let copy = Object.assign({}, service.lastAppVolWrite);
        copy[appId] = Date.now();
        service.lastAppVolWrite = copy;
        for (let j = 0; j < appModel.count; j++) {
            let item = appModel.get(j);
            if (item && item.appId === appId) {
                if (item.volume !== vol) appModel.setProperty(j, "volume", vol);
                return;
            }
        }
    }

    function update() {
        updateTimer.restart();
    }

    function setDefaultDevice(devId) {
        if (!devId) return;
        setDevProc.command = ["wpctl", "set-default", String(devId)];
        setDevProc.running = false;
        setDevProc.running = true;
    }

    function toggleMute() {
        setMuteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SINK@", "toggle"];
        setMuteProc.running = false;
        setMuteProc.running = true;
    }

    function setOutputVolume(val) {
        let pct = Math.max(0, Math.min(150, val));
        setOutVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", (pct / 100).toFixed(2)];
        setOutVolProc.running = false;
        setOutVolProc.running = true;
    }

    function toggleMicMute() {
        setMicMuteProc.command = ["wpctl", "set-mute", "@DEFAULT_AUDIO_SOURCE@", "toggle"];
        setMicMuteProc.running = false;
        setMicMuteProc.running = true;
    }

    function setMicVolume(val) {
        let pct = Math.max(0, Math.min(150, val));
        setMicVolProc.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SOURCE@", (pct / 100).toFixed(2)];
        setMicVolProc.running = false;
        setMicVolProc.running = true;
    }

    Process { id: setDevProc; onExited: service.update() }
    Process { id: setMuteProc; onExited: service.update() }
    Process { id: setOutVolProc; onExited: service.update() }
    Process { id: setMicMuteProc; onExited: service.update() }
    Process { id: setMicVolProc; onExited: service.update() }

    function _performUpdate() {
        if (!volExec.running) {
            volExec.running = true;
        }
        if (!streamCheckExec.running) {
            streamCheckExec.running = true;
        }
        if (Variables.quickSettingsOpen || Variables.controlCenterOpen) {
            if (!appVolExec.running) appVolExec.running = true;
            if (!devExec.running) devExec.running = true;
        }
    }

    Timer {
        id: updateTimer
        interval: 300
        onTriggered: _performUpdate()
    }

    Component.onCompleted: _performUpdate()

    ListModel {
        id: appModel
    }

    Process {
        id: appVolExec
        command: ["sh", "-c", "pw-dump 2>/dev/null | python3 " + PathSettings.scriptsDir + "/pw_app_volumes.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    const data = JSON.parse(text);
                    if (!Array.isArray(data)) {
                        if (data && typeof data === "object") {
                            processData([data]);
                        }
                        return;
                    }
                    processData(data);
                } catch (e) {}
            }
        }
    }

    function processData(data) {
        let currentIds = new Set();
        if (!data || !Array.isArray(data)) return;
        
        for (let i = 0; i < data.length; i++) {
            let app = data[i];
            if (!app || typeof app !== "object") continue;
            
            let vol = 0;
            if (app.volume) {
                try {
                    for (let channel in app.volume) {
                        let chObj = app.volume[channel];
                        if (chObj && chObj.value_percent) {
                            let v = parseInt(chObj.value_percent);
                            if (!isNaN(v)) {
                                vol = v;
                                break;
                            }
                        }
                    }
                } catch (err) {}
            }
            
            let name = "Unknown App";
            if (app.properties) {
                name = app.properties["application.name"] || app.properties["media.name"] || name;
            }
            name = String(name);
            
            let appId = app.index;
            if (appId === undefined) continue;

            let skipVol = false;
            let lastWrite = service.lastAppVolWrite[appId];
            if (lastWrite !== undefined && Date.now() - lastWrite < Constants.volumeWriteStaleness) {
                skipVol = true;
            }

            currentIds.add(appId);
            let found = false;
            for (let j = 0; j < appModel.count; j++) {
                let item = appModel.get(j);
                if (item && item.appId === appId) {
                    if (!skipVol && item.volume !== vol) appModel.setProperty(j, "volume", vol);
                    let muted = app.mute || false;
                    if (item.muted !== muted) appModel.setProperty(j, "muted", muted);
                    found = true;
                    break;
                }
            }
            
            if (!found) {
                appModel.append({
                    "appId": appId,
                    "name": name,
                    "volume": vol,
                    "muted": app.mute || false,
                    "icon": "\uf2d2"
                });
            }
        }
        
        for (let j = appModel.count - 1; j >= 0; j--) {
            let item = appModel.get(j);
            if (item && !currentIds.has(item.appId)) {
                appModel.remove(j);
            }
        }
    }

    Process {
        id: volListener
        command: ["sh", "-c", "pw-mon 2>/dev/null || pactl subscribe"]
        running: true
        stdout: SplitParser {
            onRead: (data) => {
                service.update();
            }
        }
        onExited: restartDelay.start()
    }

    Timer {
        id: restartDelay
        interval: 3000
        onTriggered: {
            service.update();
            volListener.running = true;
        }
    }

    Process {
        id: volExec
        command: ["sh", "-c", "vol=$(wpctl get-volume @DEFAULT_AUDIO_SINK@ 2>/dev/null); mic=$(wpctl get-volume @DEFAULT_AUDIO_SOURCE@ 2>/dev/null); bt=$(wpctl inspect @DEFAULT_AUDIO_SINK@ 2>/dev/null | grep -qi bluez && echo true || echo false); echo \"$vol|$mic|$bt\""]
        stdout: SplitParser {
            onRead: (data) => {
                let parts = data.split("|");
                if (parts.length < 3) return;
                let volLine = parts[0];
                let micLine = parts[1];
                let btLine = parts[2].trim();

                service.muted = volLine.includes("[MUTED]");
                let volMatch = volLine.match(/([0-9]+\.?[0-9]*)/);
                if (volMatch) service.outputVolume = Math.round(parseFloat(volMatch[1]) * 100);

                service.micMuted = micLine.includes("[MUTED]");
                let micMatch = micLine.match(/([0-9]+\.?[0-9]*)/);
                if (micMatch) service.micVolume = Math.round(parseFloat(micMatch[1]) * 100);

                service.btActive = btLine === "true";
            }
        }
    }

    Process {
        id: streamCheckExec
        command: ["python3", PathSettings.scriptsDir + "/pw_streams.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    const data = JSON.parse(text);
                    if (data.micActive !== undefined) service.micActive = data.micActive;
                    if (data.streamActive !== undefined) service.streamActive = data.streamActive;
                } catch (e) {}
            }
        }
    }

    Process {
        id: devExec
        command: ["python3", PathSettings.scriptsDir + "/pw_devices.py"]
        stdout: StdioCollector {
            onStreamFinished: {
                if (!text || text.trim() === "") return;
                try {
                    let data = JSON.parse(text);
                    if (data.sinks) service.sinks = data.sinks;
                    if (data.sources) service.sources = data.sources;
                    if (data.activeSinkId !== undefined) service.activeSinkId = data.activeSinkId;
                    if (data.activeSourceId !== undefined) service.activeSourceId = data.activeSourceId;
                } catch (e) {}
            }
        }
    }
}
