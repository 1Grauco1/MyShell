pragma Singleton
import QtQuick

QtObject {
    // Core Colors
    readonly property color primary: "#efbf6d"
    readonly property color on_primary: "#422c00"
    readonly property color primary_container: "#5f4100"
    readonly property color on_primary_container: "#ffdeaa"
    
    readonly property color secondary: "#dbc3a1"
    readonly property color on_secondary: "#3c2e16"
    readonly property color secondary_container: "#54442a"
    readonly property color on_secondary_container: "#f8dfbb"
    
    readonly property color tertiary: "#b4cea5"
    readonly property color on_tertiary: "#213619"
    readonly property color tertiary_container: "#364d2d"
    readonly property color on_tertiary_container: "#d0ebc0"
    
    readonly property color error: "#ffb4ab"
    readonly property color on_error: "#690005"
    readonly property color error_container: "#93000a"
    readonly property color on_error_container: "#ffdad6"
    
    readonly property color background: "#17130b"
    readonly property color on_background: "#ece1d4"
    
    readonly property color surface: "#17130b"
    readonly property color on_surface: "#ece1d4"
    readonly property color surface_variant: "#4e4539"
    readonly property color on_surface_variant: "#d2c5b4"
    
    readonly property color outline: "#9a8f80"
    readonly property color outline_variant: "#4e4539"
    
    // Surface Containers (Matugen 2.x)
    readonly property color surface_container_lowest: "#120e07"
    readonly property color surface_container_low: "#201b13"
    readonly property color surface_container: "#241f17"
    readonly property color surface_container_high: "#2f2921"
    readonly property color surface_container_highest: "#3a342b"
    
    readonly property color accent: "#efbf6d"

    Component.onCompleted: console.log("[Colors]: Singleton Loaded/Reloaded")
}
