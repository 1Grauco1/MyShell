pragma Singleton
import "."
import QtQuick

QtObject {
    property int height: SettingsStore.get("bar.height", 30)
    onHeightChanged: SettingsStore.set("bar.height", height)
    property int radius: SettingsStore.get("bar.radius", 18)
    onRadiusChanged: SettingsStore.set("bar.radius", radius)
    property int marginLeft: SettingsStore.get("bar.marginLeft", 5)
    onMarginLeftChanged: SettingsStore.set("bar.marginLeft", marginLeft)
    property int marginRight: SettingsStore.get("bar.marginRight", 5)
    onMarginRightChanged: SettingsStore.set("bar.marginRight", marginRight)
    property int marginTop: SettingsStore.get("bar.marginTop", 5)
    onMarginTopChanged: SettingsStore.set("bar.marginTop", marginTop)
    property int marginBottom: SettingsStore.get("bar.marginBottom", 0)
    onMarginBottomChanged: SettingsStore.set("bar.marginBottom", marginBottom)
    property bool entryAnimation: SettingsStore.get("bar.entryAnimation", true)
    onEntryAnimationChanged: SettingsStore.set("bar.entryAnimation", entryAnimation)
    property int animationDuration: SettingsStore.get("bar.animationDuration", 350)
    onAnimationDurationChanged: SettingsStore.set("bar.animationDuration", animationDuration)
}
