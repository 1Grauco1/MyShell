pragma Singleton
import QtQuick

QtObject {
    // Core Colors
    readonly property color primary: "#b9cf83"
    readonly property color on_primary: "#263500"
    readonly property color primary_container: "#3b4d0f"
    readonly property color on_primary_container: "#d5ec9d"
    
    readonly property color secondary: "#c2caaa"
    readonly property color on_secondary: "#2c331c"
    readonly property color secondary_container: "#434a31"
    readonly property color on_secondary_container: "#dfe6c5"
    
    readonly property color tertiary: "#a1d0c7"
    readonly property color on_tertiary: "#023732"
    readonly property color tertiary_container: "#204e48"
    readonly property color on_tertiary_container: "#bcece3"
    
    readonly property color error: "#ffb4ab"
    readonly property color on_error: "#690005"
    readonly property color error_container: "#93000a"
    readonly property color on_error_container: "#ffdad6"
    
    readonly property color background: "#12140d"
    readonly property color on_background: "#e3e3d7"
    
    readonly property color surface: "#12140d"
    readonly property color on_surface: "#e3e3d7"
    readonly property color surface_variant: "#45483c"
    readonly property color on_surface_variant: "#c6c8b8"
    
    readonly property color outline: "#909284"
    readonly property color outline_variant: "#45483c"
    
    // Surface Containers (Matugen 2.x)
    readonly property color surface_container_lowest: "#0d0f08"
    readonly property color surface_container_low: "#1b1c15"
    readonly property color surface_container: "#1f2019"
    readonly property color surface_container_high: "#292b23"
    readonly property color surface_container_highest: "#34362d"
    
    readonly property color accent: "#b9cf83"

    Component.onCompleted: console.log("[Colors]: Singleton Loaded/Reloaded")
}
