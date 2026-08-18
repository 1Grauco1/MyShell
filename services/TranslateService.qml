// services/TranslateService.qml
import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

pragma Singleton

Item {
    id: service

    property var result: null
    property bool translating: false

    readonly property string scriptPath: PathSettings.scriptsDir + "/translate.sh"

    function translate(sourceLang, targetLang, text) {
        if (!text || text.trim() === "") return;
        service.result = null;
        service.translating = true;
        proc.command = ["bash", scriptPath, sourceLang, targetLang, text];
        proc.running = false;
        proc.running = true;
    }

    function copyText(text) {
        if (!text) return;
        copyProc.command = ["python3", "-c",
            "import sys, subprocess; subprocess.run(['wl-copy', '-t', 'text/plain'], input=sys.argv[1].encode())",
            text];
        copyProc.running = false;
        copyProc.running = true;
    }

    Process {
        id: proc
        stdout: StdioCollector {
            onStreamFinished: {
                service.translating = false;
                if (!text || text.trim() === "") {
                    service.result = { error: "No response from translator" };
                    return;
                }
                try {
                    service.result = JSON.parse(text);
                } catch (e) {
                    service.result = { error: "Invalid response" };
                }
            }
        }
    }

    Process {
        id: copyProc
    }
}
