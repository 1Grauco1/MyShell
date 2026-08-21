pragma ComponentBehavior: Bound
pragma Singleton
import "."
import QtQuick
import Quickshell.Io

Item {
    id: hyprlandSettings
    
    property int gapsIn: SettingsStore.get("hyprland.gapsIn", 2)
    property int gapsOut: SettingsStore.get("hyprland.gapsOut", 6)
    property int gapsWorkspaces: SettingsStore.get("hyprland.gapsWorkspaces", 20)
    property int borderSize: SettingsStore.get("hyprland.borderSize", 2)
    property int rounding: SettingsStore.get("hyprland.rounding", 13)
    property int shadowRange: SettingsStore.get("hyprland.shadowRange", 12)
    property real blurVibrancy: SettingsStore.get("hyprland.blurVibrancy", 0.5)
    property int barMargins: SettingsStore.get("hyprland.barMargins", 10)
    
    // Logic to apply changes in real-time
    onGapsInChanged: { apply("general:gaps_in", gapsIn); SettingsStore.set("hyprland.gapsIn", gapsIn); }
    onGapsOutChanged: { apply("general:gaps_out", gapsOut); SettingsStore.set("hyprland.gapsOut", gapsOut); }
    onGapsWorkspacesChanged: { apply("general:gaps_workspaces", gapsWorkspaces); SettingsStore.set("hyprland.gapsWorkspaces", gapsWorkspaces); }
    onBorderSizeChanged: { apply("general:border_size", borderSize); SettingsStore.set("hyprland.borderSize", borderSize); }
    onRoundingChanged: { apply("decoration:rounding", rounding); SettingsStore.set("hyprland.rounding", rounding); }
    onShadowRangeChanged: { apply("decoration:shadow:range", shadowRange); SettingsStore.set("hyprland.shadowRange", shadowRange); }
    onBlurVibrancyChanged: { apply("decoration:blur:vibrancy", blurVibrancy); SettingsStore.set("hyprland.blurVibrancy", blurVibrancy); }
    
    function apply(key, value) {
        exec.command = ["hyprctl", "keyword", key, value.toString()];
        exec.running = true;
    }
    
    // Apply persisted values once at startup (batched into a single process)
    Component.onCompleted: {
        exec.command = ["sh", "-c",
            "hyprctl keyword general:gaps_in " + gapsIn + ";" +
            "hyprctl keyword general:gaps_out " + gapsOut + ";" +
            "hyprctl keyword general:gaps_workspaces " + gapsWorkspaces + ";" +
            "hyprctl keyword general:border_size " + borderSize + ";" +
            "hyprctl keyword decoration:rounding " + rounding + ";" +
            "hyprctl keyword decoration:shadow:range " + shadowRange + ";" +
            "hyprctl keyword decoration:blur:vibrancy " + blurVibrancy
        ];
        exec.running = true;
    }
    
    Process { id: exec }
}
