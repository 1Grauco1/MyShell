pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

pragma Singleton

Item {
    id: root

    readonly property string home: PathSettings.home
    readonly property string wallpaperDir: "file://" + home + "/Pictures/Wallpapers"
    readonly property string animationDir: "file://" + home + "/Videos/Animated"
    readonly property string thumbDir: PathSettings.cacheDir + "/wallpaper_thumbs"
    readonly property string scriptPath: PathSettings.scriptsDir + "/generate_thumbnails.py"

    readonly property var transitionTypes: ["fade", "wipe", "grow", "center", "outer", "right", "left", "top", "bottom"]

    function getRandomTransition() {
        return transitionTypes[Math.floor(Math.random() * transitionTypes.length)];
    }

    function applyWallpaper(path) {
        let cleanPath = path.replace("file://", "");
        let transition = getRandomTransition();

        applyProcess.command = ["swww", "img", cleanPath, 
            "--transition-type", transition, 
            "--transition-fps", "60", 
            "--transition-duration", "0.5"
        ];
        applyProcess.running = true;

        saveHistory.command = ["python3", PathSettings.scriptsDir + "/write_file.py", PathSettings.configDir + "/current_wallpaper.txt", cleanPath];
        saveHistory.running = true;
    }


    function generate() {
        if (!thumbGen.running) {
            thumbGen.running = true;
        }
    }

    Process { id: applyProcess }
    Process { id: saveHistory }

    Process {
        id: thumbGen
        command: ["python3", root.scriptPath]
        Component.onCompleted: running = true
    }
}