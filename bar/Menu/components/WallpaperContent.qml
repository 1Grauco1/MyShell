import QtQuick
import QtQuick.Layouts
import QtQuick.Controls
import Qt.labs.folderlistmodel
import Quickshell
import Quickshell.Io
import "../../../"
import "../../../services"
import "../../../Settings"

ColumnLayout {
    id: root
    spacing: Theme.scaled(20)

    property int refreshTrigger: 0
    property string activeSubTab: "Wallpaper"
    property bool thumbnailsReady: false
    property int selectedIndex: 0

    function handleKeys(event) {
        let cols = 4;
        let isAnimated = (root.activeSubTab === "Animated");
        let model = isAnimated ? animFolderModel : wallFolderModel;
        let maxIdx = model.count - 1;

        if (maxIdx < 0) return;

        if (event.key === Qt.Key_Right) {
            root.selectedIndex = Math.min(root.selectedIndex + 1, maxIdx);
            event.accepted = true;
        } else if (event.key === Qt.Key_Left) {
            root.selectedIndex = Math.max(root.selectedIndex - 1, 0);
            event.accepted = true;
        } else if (event.key === Qt.Key_Down) {
            root.selectedIndex = Math.min(root.selectedIndex + cols, maxIdx);
            event.accepted = true;
        } else if (event.key === Qt.Key_Up) {
            root.selectedIndex = Math.max(root.selectedIndex - cols, 0);
            event.accepted = true;
        } else if (event.key === Qt.Key_Tab) {
            root.selectedIndex = (root.selectedIndex + 1) > maxIdx ? 0 : root.selectedIndex + 1;
            event.accepted = true;
        } else if (event.key === Qt.Key_Backtab) {
            root.selectedIndex = (root.selectedIndex - 1) < 0 ? maxIdx : root.selectedIndex - 1;
            event.accepted = true;
        } else if (event.key === Qt.Key_Enter || event.key === Qt.Key_Return || event.key === 16777220) {
            let path = model.get(root.selectedIndex, "fileUrl");
            if (path) {
                let pathString = path.toString();
                if (root.activeSubTab === "Wallpaper") applyWallpaper(pathString);
                else if (root.activeSubTab === "Animated") applyVideo(pathString);
            }
            event.accepted = true;
        }
    }

    onVisibleChanged: { if (visible) refreshThumbnails(); }

    function refreshThumbnails() {
        thumbnailsReady = false;
        thumbGen.running = false;
        thumbGen.running = true;
    }

    readonly property string logPath: (PathSettings.home + "/.local/state/g_ant/g_ant.log")
    readonly property string scriptsPath: PathSettings.scriptsDir

    function ensureDaemon() {
        awwwDaemon.running = false;
        awwwDaemon.running = true;
    }

    // --- SUB-TABS ---
    RowLayout {
        Layout.fillWidth: true
        spacing: Theme.scaled(10)
        
        Repeater {
            model: ["Wallpaper", "Animated"]
            delegate: Rectangle {
                width: Theme.scaled(100); height: Theme.scaled(32); radius: Theme.scaled(10)
                color: root.activeSubTab === modelData ? Theme.accentColor : (subTabMouse.containsMouse ? Theme.surface1 : Theme.surface0)
                border.color: Theme.glassBorder
                scale: subTabMouse.pressed ? 0.95 : 1.0
                Behavior on scale { NumberAnimation { duration: 100 } }
                Behavior on color { ColorAnimation { duration: 200 } }

                Text { 
                    anchors.centerIn: parent
                    text: modelData
                    font.pixelSize: Theme.scaled(11)
                    font.weight: Font.Black
                    color: root.activeSubTab === modelData ? Theme.base : (subTabMouse.containsMouse ? Theme.text : Theme.subtext1)
                }
                MouseArea { 
                    id: subTabMouse
                    anchors.fill: parent
                    hoverEnabled: true
                    onClicked: {
                        root.activeSubTab = modelData;
                        root.selectedIndex = 0;
                    }
                }
            }
        }
        Item { Layout.fillWidth: true }
        
        // Thumbnail Generation Status
        RowLayout {
            spacing: Theme.scaled(8)
            visible: thumbGen.running
            Text {
                text: "󱑐"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(14); color: Theme.blue
                RotationAnimator on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: thumbGen.running }
            }
            Text { text: "Updating..."; font.pixelSize: Theme.scaled(10); font.weight: Font.Black; color: Theme.subtext1 }
        }
        
        // Refresh Button
        Rectangle {
            width: Theme.scaled(32); height: Theme.scaled(32); radius: Theme.scaled(8)
            color: refreshMouse.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
            visible: !thumbGen.running
            Text { anchors.centerIn: parent; text: "󰑐"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(16); color: refreshMouse.containsMouse ? Theme.text : Theme.subtext1 }
            MouseArea { id: refreshMouse; anchors.fill: parent; hoverEnabled: true; onClicked: refreshThumbnails() }
        }
    }

    // --- GRID AREA ---
    Item {
        Layout.fillWidth: true
        Layout.fillHeight: true
        clip: true

        Flickable {
            id: wallFlickable
            anchors.fill: parent
            contentHeight: wallFlow.height
            visible: root.activeSubTab !== "Animated"
            clip: true
            ScrollBar.vertical: ScrollBar { width: 4; policy: ScrollBar.AsNeeded }

            Connections {
                target: root
                function onSelectedIndexChanged() {
                    let item = wallRepeater.itemAt(root.selectedIndex);
                    if (item) {
                        let itemPos = item.y;
                        if (itemPos < wallFlickable.contentY) wallFlickable.contentY = itemPos;
                        else if (itemPos + item.height > wallFlickable.contentY + wallFlickable.height) wallFlickable.contentY = itemPos + item.height - wallFlickable.height;
                    }
                }
            }

            Flow {
                id: wallFlow
                width: parent.width
                spacing: Theme.scaled(15)
                Repeater {
                    id: wallRepeater
                    model: FolderListModel {
                        id: wallFolderModel
                        folder: WallpaperService.wallpaperDir
                        nameFilters: ["*.jpg", "*.png", "*.jpeg", "*.webp"]
                        onCountChanged: if (root.visible) refreshThumbnails();
                    }
                    delegate: Rectangle {
                        width: (wallFlow.width - Theme.scaled(45)) / 4
                        height: width * 0.6
                        radius: Theme.scaled(13)
                        color: Theme.surface1
                        clip: true
                        property bool isFocused: index === root.selectedIndex
                        border.color: isFocused ? Theme.accentColor : Theme.glassBorder
                        border.width: isFocused ? 3 : 1
                        
                        Loader {
                            id: thumbLoader; anchors.fill: parent
                            sourceComponent: (fileName && root.thumbnailsReady) ? thumbComponent : undefined
                            Component {
                                id: thumbComponent
                                Image {
                                    anchors.fill: parent; anchors.margins: 2
                                    source: (fileName && fileName.lastIndexOf('.') > 0) ? ("file://" + Quickshell.env("HOME") + "/.cache/wallpaper_thumbs/" + fileName.substring(0, fileName.lastIndexOf('.')) + ".png") : ""
                                    fillMode: Image.PreserveAspectCrop; cache: false; asynchronous: true
                                    opacity: status === Image.Ready ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 400 } }
                                }
                            }
                        }
                        
                        Text {
                            anchors.centerIn: parent; text: "󱑐"; font.family: Theme.iconFont; font.pixelSize: Theme.scaled(20); color: Theme.blue
                            visible: !root.thumbnailsReady || (thumbLoader.item && thumbLoader.item.status !== Image.Ready)
                            RotationAnimator on rotation { from: 0; to: 360; duration: 1000; loops: Animation.Infinite; running: parent.visible }
                        }
                        
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onEntered: root.selectedIndex = index
                            onClicked: { 
                                let pathString = fileUrl.toString();
                                if (root.activeSubTab === "Wallpaper") applyWallpaper(pathString); 
                            }
                            Rectangle {
                                anchors.fill: parent; radius: Theme.scaled(12)
                                color: parent.containsMouse ? Qt.rgba(1,1,1,0.1) : "transparent"
                            }
                        }                    }
                }
            }

            // Empty state placeholder for Wallpapers
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.scaled(10)
                visible: wallFolderModel.count === 0 && !thumbGen.running
                Text {
                    text: "󰉏"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(48)
                    color: Theme.surface2
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "Directory is empty"
                    font.pixelSize: Theme.scaled(14)
                    font.weight: Font.Bold
                    color: Theme.subtext1
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "~/Pictures/Wallpapers"
                    font.pixelSize: Theme.scaled(11)
                    color: Theme.surface2
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }

        Flickable {
            id: animFlickable
            anchors.fill: parent
            contentHeight: animFlow.height
            visible: root.activeSubTab === "Animated"
            clip: true
            ScrollBar.vertical: ScrollBar { width: 4; policy: ScrollBar.AsNeeded }

            Flow {
                id: animFlow
                width: parent.width
                spacing: Theme.scaled(15)
                Repeater {
                    id: animRepeater
                    model: FolderListModel {
                        id: animFolderModel
                        folder: WallpaperService.animationDir
                        nameFilters: ["*.mp4", "*.mkv", "*.webm"]
                        onCountChanged: if (root.visible) refreshThumbnails();
                    }
                    delegate: Rectangle {
                        width: (animFlow.width - Theme.scaled(45)) / 4
                        height: width * 0.6
                        radius: Theme.scaled(12)
                        color: Theme.surface1
                        clip: true
                        property bool isFocused: index === root.selectedIndex
                        border.color: isFocused ? Theme.accentColor : Theme.glassBorder
                        border.width: isFocused ? 3 : 1
                        
                        Loader {
                            id: animThumbLoader; anchors.fill: parent
                            sourceComponent: (fileName && root.thumbnailsReady) ? animThumbComponent : undefined
                            Component {
                                id: animThumbComponent
                                Image {
                                    anchors.fill: parent; anchors.margins: 2
                                    source: (fileName && fileName.lastIndexOf('.') > 0) ? ("file://" + Quickshell.env("HOME") + "/.cache/animation_thumbs/" + fileName.substring(0, fileName.lastIndexOf('.')) + ".png") : ""
                                    fillMode: Image.PreserveAspectCrop; cache: false; asynchronous: true
                                    opacity: status === Image.Ready ? 1.0 : 0.0
                                    Behavior on opacity { NumberAnimation { duration: 400 } }
                                }
                            }
                        }
                        MouseArea {
                            anchors.fill: parent; hoverEnabled: true
                            onEntered: root.selectedIndex = index
                            onClicked: applyVideo(fileUrl.toString())
                        }
                    }
                }
            }

            // Empty state placeholder for Animated Videos
            ColumnLayout {
                anchors.centerIn: parent
                spacing: Theme.scaled(10)
                visible: animFolderModel.count === 0 && !thumbGen.running
                Text {
                    text: "󰕧"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(48)
                    color: Theme.surface2
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "Directory is empty"
                    font.pixelSize: Theme.scaled(14)
                    font.weight: Font.Bold
                    color: Theme.subtext1
                    Layout.alignment: Qt.AlignHCenter
                }
                Text {
                    text: "~/Videos/Animations"
                    font.pixelSize: Theme.scaled(11)
                    color: Theme.surface2
                    Layout.alignment: Qt.AlignHCenter
                }
            }
        }
    }

    // --- LOGIC FUNCTIONS ---
    function applyWallpaper(path) {
        killMpv.running = true; ensureDaemon(); 
        let cleanPath = path.replace("file://", "");
        saveCurrentWall.path = cleanPath; saveCurrentWall.running = true;
        wallDelay.wallPath = cleanPath;
        wallDelay.wallTransition = WallpaperService.getRandomTransition();
        wallDelay.start();
    }
    function applyVideo(path) {
        killawww.running = true; killMpv.running = true;
        videoDelay.videoPath = path.replace("file://", ""); videoDelay.start();
    }
    function log(msg) { logger.command = ["sh", "-c", "echo '[$(date +%T)] " + msg + "' >> " + logPath]; logger.running = true; }

    Timer { id: wallDelay; property string wallPath: ""; property string wallTransition: "fade"; interval: 300; onTriggered: { setWall.command = ["sh", "-c", "awww img --resize=crop '" + wallPath + "' --transition-type " + wallTransition + " --transition-duration 0.5 --transition-fps 60 >> " + root.logPath + " 2>&1 && " + PathSettings.scriptsDir + "/g_ant-theme.sh --autoselect"]; setWall.running = true; } }
    Timer { id: videoDelay; property string videoPath: ""; interval: 400; onTriggered: { mpvProcess.command = ["sh", "-c", "MON=$(hyprctl monitors -j | python3 -c 'import json,sys; print(json.load(sys.stdin)[0][\"name\"])' 2>/dev/null); [ -z \"$MON\" ] && MON=eDP-1; mpvpaper -vsf -o 'no-audio loop' \"$MON\" '" + videoPath + "' >> " + root.logPath + " 2>&1"]; mpvProcess.running = true; CenterState.close(); } }

    Process { id: logger }
    Process { id: awwwDaemon; command: ["sh", "-c", "pgrep -x awww-daemon >/dev/null || (mkdir -p \"$HOME/.local/state/g_ant\" && awww-daemon >> \"$HOME/.local/state/g_ant/g_ant.log\" 2>&1)"] }
    Process { id: setWall; onExited: { CenterState.close(); } }
    Process { id: killawww; command: ["killall", "awww-daemon"] }
    Process { id: killMpv; command: ["killall", "mpvpaper"] }
    Process { id: mpvProcess }
    Process { id: saveCurrentWall; property string path: ""; command: ["sh", "-c", "mkdir -p " + Quickshell.env("HOME") + "/.config && echo '" + path + "' > " + Quickshell.env("HOME") + "/.config/current_wallpaper.txt"] }
    Process { id: thumbGen; command: ["python3", (Quickshell.env("G_ANT_ROOT") ? Quickshell.env("G_ANT_ROOT") : Quickshell.env("HOME") + "/.config/quickshell") + "/services/generate_thumbnails.py"]; onRunningChanged: { if (!running) { root.thumbnailsReady = true; root.refreshTrigger++; } } }
    Component.onCompleted: refreshThumbnails()

    function resetScroll() {
        root.activeSubTab = "Wallpaper";
        root.selectedIndex = 0;
        wallFlickable.contentY = 0;
        animFlickable.contentY = 0;
    }
}
