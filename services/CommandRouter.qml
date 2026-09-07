pragma ComponentBehavior: Bound
pragma Singleton

import QtQuick
import Quickshell
import "./"
import "../Settings"

QtObject {
    id: router

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
            settingsVisible = false;
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
}