pragma ComponentBehavior: Bound
pragma Singleton
import "."
import QtQuick
import Quickshell.Io

QtObject {
    id: store

    readonly property string storePath: PathSettings.shellDir + "/settings.json"
    property var values: ({})
    property bool _loaded: false

    // Writes go through setText(), which is async and atomic (tmp file + rename)
    // by default, replacing the old external python3 writer.
    readonly property var settingsFile: FileView {
        path: store.storePath
        blockLoading: true
        printErrors: false
        onSaveFailed: (error) => console.warn("[SettingsStore]: save failed:", error)
    }

    property var saveTimer: Timer {
        id: debounceTimer
        interval: 500
        onTriggered: store.flush()
    }

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
        settingsFile.setText(JSON.stringify(store.values));
    }
}
