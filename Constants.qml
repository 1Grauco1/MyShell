pragma ComponentBehavior: Bound
pragma Singleton
import QtQuick

QtObject {
    readonly property string monoFont: "JetBrains Mono"
    readonly property int dynamicIslandActiveWidth: 480
    readonly property int stallTimeout: 5000
    readonly property int volumeWriteStaleness: 1500
    readonly property int volumeTextTimeout: 3000
}
