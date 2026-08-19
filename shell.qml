//@ pragma UseQApplication
import QtQuick
import QtQml 2.15
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import "bar"
import "bar/Menu"
import "bar/Menu/components"
import "services"
import "Settings"
import "windows"

Scope {
    // --- IPC HANDLER FOR G_ANT:MENU ---
    IpcHandler {
        target: "g_ant:menu"

        function toggle(drawer: string): void {
            handleCommand(drawer);
        }

        function launcher(): void { handleCommand("launcher"); }
        function dashboard(): void { handleCommand("dashboard"); }
        function wallpaper(): void { handleCommand("wallpaper"); }
        function pomodoro(): void { handleCommand("pomodoro"); }
        function volume(): void { handleCommand("volume"); }
        function clipboard(): void { handleCommand("clipboard"); }
        function emoji(): void { handleCommand("emoji"); }
        function power(): void { handleCommand("power"); }
        function settings(): void { handleCommand("settings"); }
        function close(): void { handleCommand("close"); }
        function setconfig(value: string): void { handleCommand("setconfig:" + value); }
        function media(): void { handleCommand("media"); }
        function mediaNext(): void { handleCommand("media-next"); }
        function mediaPrev(): void { handleCommand("media-prev"); }
        function mediaShuffle(): void { handleCommand("media-shuffle"); }
        function mediaPlay(): void { handleCommand("media-play"); }
    }

    // --- NATIVE HYPRLAND GLOBAL SHORTCUTS ---
    GlobalShortcut { appid: "g_ant"; name: "launcher"; onPressed: handleCommand("launcher") }
    GlobalShortcut { appid: "g_ant"; name: "dashboard"; onPressed: handleCommand("dashboard") }
    GlobalShortcut { appid: "g_ant"; name: "wallpaper"; onPressed: handleCommand("wallpaper") }
    GlobalShortcut { appid: "g_ant"; name: "pomodoro"; onPressed: handleCommand("pomodoro") }
    GlobalShortcut { appid: "g_ant"; name: "volume"; onPressed: handleCommand("volume") }
    GlobalShortcut { appid: "g_ant"; name: "close"; onPressed: handleCommand("close") }
    GlobalShortcut { appid: "g_ant"; name: "clipboard"; onPressed: handleCommand("clipboard") }
    GlobalShortcut { appid: "g_ant"; name: "emoji"; onPressed: handleCommand("emoji") }
    GlobalShortcut { appid: "g_ant"; name: "power"; onPressed: handleCommand("power") }
    GlobalShortcut { appid: "g_ant"; name: "settings"; onPressed: handleCommand("settings") }
    GlobalShortcut { appid: "g_ant"; name: "media"; onPressed: handleCommand("media") }
    GlobalShortcut { appid: "g_ant"; name: "media-next"; onPressed: handleCommand("media-next") }
    GlobalShortcut { appid: "g_ant"; name: "media-prev"; onPressed: handleCommand("media-prev") }
    GlobalShortcut { appid: "g_ant"; name: "media-shuffle"; onPressed: handleCommand("media-shuffle") }
    GlobalShortcut { appid: "g_ant"; name: "media-play"; onPressed: handleCommand("media-play") }
    
    property bool settingsVisible: false

    function parseSettingValue(str: string): var {
        if (str === "true") return true;
        if (str === "false") return false;
        if (str === "null" || str === "") return null;
        let num = Number(str);
        if (!isNaN(num)) return num;
        return str;
    }

    function handleCommand(cmd) {
        let parts = cmd.split(":");
        let action = parts[0].trim();
        let lowerAction = action.toLowerCase();
        let arg = parts.length > 1 ? parts[1].trim() : "";
        let lowerArg = arg.toLowerCase();

        if (lowerAction === "launcher" || lowerAction === "toggle_launcher" || lowerAction === "applauncher") {
            DynamicIslandService.toggle("launcher");
        } else if (lowerAction === "clipboard" || lowerAction === "toggle_clipboard" || lowerAction === "clip" || lowerAction === "cliphist") {
            DynamicIslandService.toggle("clipboard");
        } else if (lowerAction === "emoji" || lowerAction === "toggle_emoji" || lowerAction === "emojis" || lowerAction === "emojiselector") {
            DynamicIslandService.toggle("emoji");
        } else if (lowerAction === "dashboard" || lowerAction === "toggle_dashboard" || lowerAction === "actionlauncher" || lowerAction === "overview") {
            let tab = "Default";
            if (lowerArg === "pomodoro") tab = "Pomodoro";
            else if (lowerArg === "wallpaper" || lowerArg === "wallpapers") tab = "Wallpaper";
            else if (lowerArg === "translate" || lowerArg === "translator") tab = "Translate";
            CenterState.toggle(tab);
        } else if (lowerAction === "quicksettings" || lowerAction === "toggle_quicksettings") {
            let tab = arg || "network";
            QuickSettingsService.toggle(tab);
        } else if (lowerAction === "wallpaper" || lowerAction === "wallpapers") {
            CenterState.toggle("Wallpaper");
        } else if (lowerAction === "pomodoro") {
            CenterState.toggle("Pomodoro");
        } else if (lowerAction === "wifi" || lowerAction === "network") {
            QuickSettingsService.toggle("network");
        } else if (lowerAction === "bluetooth" || lowerAction === "bt") {
            QuickSettingsService.toggle("bluetooth");
        } else if (lowerAction === "volume" || lowerAction === "audio") {
            QuickSettingsService.toggle("volume");
        } else if (lowerAction === "powerprofile" || lowerAction === "prof") {
            QuickSettingsService.toggle("powerprofile");
        } else if (lowerAction === "battery" || lowerAction === "pwr") {
            QuickSettingsService.toggle("battery");
        } else if (lowerAction === "power" || lowerAction === "sys") {
            QuickSettingsService.toggle("power");
        } else if (lowerAction === "settings" || lowerAction === "config") {
            settingsVisible = !settingsVisible;
        } else if (lowerAction === "setconfig" || lowerAction === "set") {
            // e.g. `quickshell ipc call g_ant:menu setconfig bar.height=36`
            if (arg) {
                let eq = arg.indexOf("=");
                let key = (eq >= 0 ? arg.slice(0, eq) : arg).trim();
                let raw = eq >= 0 ? arg.slice(eq + 1).trim() : "true";
                if (key) SettingsStore.set(key, parseSettingValue(raw));
            }
        } else if (lowerAction === "close" || lowerAction === "close_all") {
            MenuService.closeAll();
            DynamicIslandService.close();
        } else if (lowerAction === "media") {
            MediaPlayerService.toggleMediaPopup();
        } else if (lowerAction === "media-next") {
            let p = MediaPlayerService.trackedPlayer;
            if (p && p.canGoNext) p.next();
        } else if (lowerAction === "media-prev") {
            let p = MediaPlayerService.trackedPlayer;
            if (p && p.canGoPrevious) p.previous();
        } else if (lowerAction === "media-shuffle") {
            let p = MediaPlayerService.trackedPlayer;
            if (p && typeof p.shuffle === "boolean") p.shuffle = !p.shuffle;
        } else if (lowerAction === "media-play") {
            let p = MediaPlayerService.trackedPlayer;
            if (p) {
                if (p.canTogglePlaying) p.togglePlaying();
                else if (p.canPause) p.pause();
                else if (p.canPlay) p.play();
            }
        }
    }

    DismissOverlay {
        id: dismissOverlay
    }

    Connections {
        target: HyprlandService
        function onIsFullscreenChanged() {
            if (HyprlandService.isFullscreen) {
                MenuService.closeAll();
                DynamicIslandService.close();
            }
        }
    }

    Bar {
        id: bar
        controlCenterMenuRef: controlCenterLoader.item
    }

    Loader {
        id: controlCenterLoader
        active: false
        sourceComponent: Component {
            ControlCenter {
                parentWindow: bar
                visible: CenterState.qsVisible
                Component.onCompleted: CenterState.menuRef = this
            }
        }
        Connections {
            target: CenterState
            function onQsVisibleChanged() {
                if (CenterState.qsVisible && !controlCenterLoader.active)
                    controlCenterLoader.active = true;
                else if (!CenterState.qsVisible && controlCenterLoader.active)
                    controlCenterLoader.active = false;
            }
        }
    }

    MediaPlayerPopup {
        id: mediaPlayerPopup
        parentWindow: bar
    }

    Loader {
        id: quickSettingsLoader
        active: false
        sourceComponent: Component {
            QuickSettingsMenu {
                parentWindow: bar
                visible: QuickSettingsService.qsVisible
                Component.onCompleted: QuickSettingsService.menuRef = this
            }
        }
        Connections {
            target: QuickSettingsService
            function onQsVisibleChanged() {
                if (QuickSettingsService.qsVisible && !quickSettingsLoader.active)
                    quickSettingsLoader.active = true;
                else if (!QuickSettingsService.qsVisible && quickSettingsLoader.active)
                    quickSettingsLoader.active = false;
            }
        }
    }

    NotificationPopup {
        id: notificationPopup
        barRef: bar
        osdRef: osdPopup
    }

    OsdPopup {
        id: osdPopup
        barRef: bar
    }

    Loader {
        id: dynamicIslandLoader
        active: false
        sourceComponent: Component {
            DynamicIslandOverlay {
                visible: DynamicIslandService.active
            }
        }
        Connections {
            target: DynamicIslandService
            function onActiveChanged() {
                if (DynamicIslandService.active && !dynamicIslandLoader.active)
                    dynamicIslandLoader.active = true;
                else if (!DynamicIslandService.active && dynamicIslandLoader.active)
                    dynamicIslandLoader.active = false;
            }
        }
    }

    Loader {
        id: settingsLoader
        active: settingsVisible
        sourceComponent: Component {
            SettingsWindow {
                Component.onCompleted: visible = true
                onVisibleChanged: {
                    if (!visible) settingsVisible = false;
                }
            }
        }
    }
}