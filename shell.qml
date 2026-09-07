pragma ComponentBehavior: Bound
//@ pragma UseQApplication
import QtQuick
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
            CommandRouter.handleCommand(drawer);
        }

        function launcher(): void { CommandRouter.handleCommand("launcher"); }
        function dashboard(): void { CommandRouter.handleCommand("dashboard"); }
        function wallpaper(): void { CommandRouter.handleCommand("wallpaper"); }
        function pomodoro(): void { CommandRouter.handleCommand("pomodoro"); }
        function volume(): void { CommandRouter.handleCommand("volume"); }
        function clipboard(): void { CommandRouter.handleCommand("clipboard"); }
        function emoji(): void { CommandRouter.handleCommand("emoji"); }
        function power(): void { CommandRouter.handleCommand("power"); }
        function settings(): void { CommandRouter.handleCommand("settings"); }
        function close(): void { CommandRouter.handleCommand("close"); }
        function setconfig(value: string): void { CommandRouter.handleCommand("setconfig:" + value); }
        function media(): void { CommandRouter.handleCommand("media"); }
        function mediaNext(): void { CommandRouter.handleCommand("media-next"); }
        function mediaPrev(): void { CommandRouter.handleCommand("media-prev"); }
        function mediaShuffle(): void { CommandRouter.handleCommand("media-shuffle"); }
        function mediaPlay(): void { CommandRouter.handleCommand("media-play"); }
    }

    // --- NATIVE HYPRLAND GLOBAL SHORTCUTS ---
    GlobalShortcut { appid: "g_ant"; name: "launcher"; onPressed: CommandRouter.handleCommand("launcher") }
    GlobalShortcut { appid: "g_ant"; name: "dashboard"; onPressed: CommandRouter.handleCommand("dashboard") }
    GlobalShortcut { appid: "g_ant"; name: "wallpaper"; onPressed: CommandRouter.handleCommand("wallpaper") }
    GlobalShortcut { appid: "g_ant"; name: "pomodoro"; onPressed: CommandRouter.handleCommand("pomodoro") }
    GlobalShortcut { appid: "g_ant"; name: "volume"; onPressed: CommandRouter.handleCommand("volume") }
    GlobalShortcut { appid: "g_ant"; name: "close"; onPressed: CommandRouter.handleCommand("close") }
    GlobalShortcut { appid: "g_ant"; name: "clipboard"; onPressed: CommandRouter.handleCommand("clipboard") }
    GlobalShortcut { appid: "g_ant"; name: "emoji"; onPressed: CommandRouter.handleCommand("emoji") }
    GlobalShortcut { appid: "g_ant"; name: "power"; onPressed: CommandRouter.handleCommand("power") }
    GlobalShortcut { appid: "g_ant"; name: "settings"; onPressed: CommandRouter.handleCommand("settings") }
    GlobalShortcut { appid: "g_ant"; name: "media"; onPressed: CommandRouter.handleCommand("media") }
    GlobalShortcut { appid: "g_ant"; name: "media-next"; onPressed: CommandRouter.handleCommand("media-next") }
    GlobalShortcut { appid: "g_ant"; name: "media-prev"; onPressed: CommandRouter.handleCommand("media-prev") }
    GlobalShortcut { appid: "g_ant"; name: "media-shuffle"; onPressed: CommandRouter.handleCommand("media-shuffle") }
    GlobalShortcut { appid: "g_ant"; name: "media-play"; onPressed: CommandRouter.handleCommand("media-play") }

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
        active: CenterState.qsVisible
        sourceComponent: Component {
            ControlCenter {
                parentWindow: bar
                visible: CenterState.qsVisible
                Component.onCompleted: CenterState.menuRef = this
            }
        }
    }

    MediaPlayerPopup {
        id: mediaPlayerPopup
        parentWindow: bar
    }

    Loader {
        id: quickSettingsLoader
        active: QuickSettingsService.qsVisible
        sourceComponent: Component {
            QuickSettingsMenu {
                parentWindow: bar
                visible: QuickSettingsService.qsVisible
                Component.onCompleted: QuickSettingsService.menuRef = this
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

    Connections {
        target: VolumeService
        function onOutputVolumeChanged() {
            NotificationService.registerOSD("volume", VolumeService.outputVolume / 100);
        }
        function onMutedChanged() {
            NotificationService.registerOSD("volume", VolumeService.muted ? 0 : VolumeService.outputVolume / 100);
        }
    }

    Connections {
        target: BrightnessService
        function onBrightnessChanged() {
            NotificationService.registerOSD("brightness", BrightnessService.brightness / 100);
        }
    }

    Loader {
        id: dynamicIslandLoader
        active: DynamicIslandService.active
        sourceComponent: Component {
            DynamicIslandOverlay {
                visible: DynamicIslandService.active
            }
        }
    }

    Loader {
        id: settingsLoader
        active: CommandRouter.settingsVisible
        sourceComponent: Component {
            SettingsWindow {
                Component.onCompleted: show()
                onVisibleChanged: {
                    if (!visible) CommandRouter.settingsVisible = false;
                }
            }
        }
    }
}