pragma ComponentBehavior: Bound
pragma Singleton
import QtQuick
import Quickshell
import "Settings"

QtObject {
    // =====================================================
    // ================= DYNAMIC SCALING ===================
    // =====================================================
    
    // We use 1080 as our reference height and 1920 as reference width (1080p)
    readonly property real referenceHeight: 1080
    readonly property real referenceWidth: 1920
    readonly property real screenHeight: Quickshell.screens.length > 0 ? Quickshell.screens[0].height : 1080
    readonly property real screenWidth: Quickshell.screens.length > 0 ? Quickshell.screens[0].width : 1920
    
    // Scale factor: geometric mean of height and width scaling to ensure balanced scaling
    readonly property real scale: Math.sqrt((screenWidth / referenceWidth) * (screenHeight / referenceHeight))
    
    // Responsive break points
    readonly property bool isSmallScreen: screenWidth < 1000 || screenHeight < 700
    readonly property bool isMobile: screenWidth < 500 || screenHeight < 500
    readonly property bool isPortrait: screenHeight > screenWidth

    // Helper to scale values manually if needed
    function scaled(val) { 
        let s = Math.round(val * scale);
        // Ensure minimum sizes for readability on very small scales
        if (val >= 8 && s < 8) return 8;
        return s;
    }
    
    // ===== Glassmorphism & Effects =====
    readonly property real menuOpacity: AppearanceSettings.menuOpacity
    readonly property real settingsOpacity: AppearanceSettings.settingsOpacity
    readonly property color glassBackground: Qt.alpha(Colors.background, menuOpacity)
    readonly property color settingsBackground: Qt.alpha(Colors.background, settingsOpacity)
    readonly property color glassBorder: Qt.rgba(1, 1, 1, 0.15)
    readonly property color tooltipBackground: Qt.alpha(Colors.background, 0.95)
    readonly property real glassBlur: AppearanceSettings.glassBlur
    
    // ===== Animation Defaults =====
    // Tuned for a soft, fluid feel: gentle S-curve ease, slightly longer
    // durations than the old snappy OutExpo so motion reads as deliberate.
    readonly property int animFast: 260
    readonly property int animNormal: 500
    readonly property int animSlow: 750
    readonly property int animEasing: Easing.InOutCubic
    readonly property int elasticEasing: Easing.OutQuart

    // ===== Material 3 Expressive & Bubble Tokens =====
    readonly property int bubbleRadiusSmall: scaled(12)
    readonly property int bubbleRadiusMedium: scaled(20)
    readonly property int bubbleRadiusLarge: scaled(28)
    readonly property int bubbleRadiusPill: scaled(9999)

    readonly property color surfaceContainer: Colors.surface_container
    readonly property color surfaceContainerLow: Colors.surface_container_low
    readonly property color surfaceContainerHigh: Colors.surface_container_high
    readonly property color surfaceContainerHighest: Colors.surface_container_highest


    // ===== Colors =====
    readonly property color accentColor: Colors.primary
    readonly property color accentGlow: {
        try {
            return Qt.rgba(Colors.primary.r, Colors.primary.g, Colors.primary.b, 0.3);
        } catch(e) {
            return "#4dffb3b3";
        }
    }
    readonly property color shadowColor: Qt.rgba(0, 0, 0, 0.5)

    // ===== Bar =====
    readonly property int barHeight: scaled(BarSettings.height)
    readonly property int barRadius: scaled(BarSettings.radius)
    readonly property int barMarginLeft: scaled(BarSettings.marginLeft)
    readonly property int barMarginRight: scaled(BarSettings.marginRight)
    readonly property int barMarginTop: scaled(BarSettings.marginTop)
    readonly property int barMarginBottom: scaled(BarSettings.marginBottom)
    readonly property color barColor: "#00000000"
    readonly property color backgroundColor: Colors.surface_container
    readonly property color borderColor: Colors.surface_variant

    // ===== Pills =====
    readonly property int pillHeight: scaled(PillSettings.height)
    readonly property int pillRadius: scaled(PillSettings.radius)
    readonly property int pillPadding: scaled(PillSettings.padding)
    readonly property int extraPillPadding: scaled(PillSettings.extraPadding)
    readonly property color pillColor: Colors.background
    readonly property int pillSpacing: scaled(PillSettings.spacing)
    readonly property int pillGap: scaled(PillSettings.gap)
    readonly property color pillBorderColor: Colors.outline
    readonly property int pillBorderWidth: PillSettings.borderWidth
    readonly property int pillHoverBorderWidth: PillSettings.hoverBorderWidth
    readonly property color pillHoverColor: Colors.surface_variant
    
    // ===== Typography =====
    readonly property int fontSize: scaled(AppearanceSettings.fontSize)
    readonly property int iconSize: scaled(AppearanceSettings.iconSize)
    readonly property string iconFont: AppearanceSettings.iconFont
    readonly property color fontColor: Colors.on_background
    
    // ===== Menu / Popup Styling =====
    readonly property color menuBackground: Colors.background
    readonly property color menuBorder: Colors.surface_variant
    readonly property color menuHoverBorder: Colors.primary
    readonly property int menuRadius: scaled(AppearanceSettings.menuRadius)
    readonly property int cardRadius: scaled(24)
    readonly property int menuPadding: scaled(AppearanceSettings.menuPadding)
    readonly property int menuSpacing: scaled(AppearanceSettings.menuSpacing)
    readonly property color menuActiveTab: Colors.primary
    readonly property color menuInactiveTab: "transparent"
    
    // ===== Widget Specific Colors =====
    readonly property color bluetoothColor: Colors.primary
    readonly property color powerRed: Colors.error
    readonly property color powerYellow: Colors.secondary_container
    readonly property color powerGreen: Colors.tertiary

    // ===== Active States =====
    readonly property color activePillColor: Colors.surface_variant
    readonly property color activeBorderColor: Colors.primary
    readonly property color activeTextColor: Colors.on_surface
    readonly property color inactiveTextColor: Colors.outline

    // ===== Icons (Nerd Font) =====
    readonly property string volMute: "󰝟"
    readonly property string volLow: "󰕿"
    readonly property string volMid: "󰖀"
    readonly property string volHigh: "󰕾"
    readonly property string btIcon: "󰂯"
    readonly property string netUpIcon: ""
    readonly property string netDownIcon: ""


    // Shared by the bar battery pill and quick-settings cluster (keeps both in sync).
    // Bands follow the user-configured thresholds from Settings -> Battery.
    function batteryStatusIcon(percent, state, ac) {
        const isLimitActive = (state === "not charging" || state === "full" || state === "idle") && ac;
        if (isLimitActive) return "";
        if (state === "charging") return "󰂄";
        if (percent > BatterySettings.high) return "󰁹";
        if (percent > BatterySettings.midHigh) return "󰂁";
        if (percent > BatterySettings.mid) return "󰁿";
        if (percent > BatterySettings.low) return "󰁽";
        if (percent > BatterySettings.critical) return "󰁻";
        return "󰂎";
    }

    function batteryStatusColor(percent, state, ac) {
        if (state === "charging") return powerGreen;
        if (percent <= BatterySettings.critical) return Colors.error;
        return fontColor;
    }

    function volumeIcon(vol, muted) {
        if (muted) return volMute;
        if (vol >= 70) return volHigh;
        if (vol >= 30) return volMid;
        return volLow;
    }


}
