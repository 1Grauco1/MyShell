pragma Singleton
import "."
import QtQuick
import Quickshell
import Quickshell.Io

QtObject {
    id: store

    readonly property string storePath: PathSettings.shellDir + "/settings.json"
    property var values: ({})
    property bool _loaded: false

    readonly property var settingsFile: FileView {
        path: store.storePath
        blockLoading: true
        printErrors: false
    }

    property var saveTimer: Timer {
        id: debounceTimer
        interval: 500
        onTriggered: store.flush()
    }

    property var writeProc: Process { id: writer }

    Component.onCompleted: ensureLoaded()

    // Synchronous (blocking) read on first use so Settings singletons can
    // initialize their persisted values eagerly during construction.
    function ensureLoaded() {
        if (store._loaded) return;
        store._loaded = true;
        try {
            let raw = settingsFile.text();
            store.values = (raw && raw.trim() !== "") ? (JSON.parse(raw) || {}) : {};
        } catch (e) {
            store.values = {};
        }
    }

    function get(key, defaultValue) {
        ensureLoaded();
        return (key in store.values) ? store.values[key] : defaultValue;
    }

    function set(key, value) {
        ensureLoaded();
        store.values[key] = value;
        debounceTimer.restart();
    }

    function flush() {
        let payload = JSON.stringify(store.values);
        writer.command = [
            "python3", PathSettings.scriptsDir + "/write_file.py",
            storePath,
            payload
        ];
        writer.running = false;
        writer.running = true;
    }
}
