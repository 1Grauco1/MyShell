pragma Singleton
import "."
import QtQuick

QtObject {
    property bool enableMedia: SettingsStore.get("widget.enableMedia", true)
    onEnableMediaChanged: SettingsStore.set("widget.enableMedia", enableMedia)
    property bool enableBattery: SettingsStore.get("widget.enableBattery", true)
    onEnableBatteryChanged: SettingsStore.set("widget.enableBattery", enableBattery)
    property bool enableNetwork: SettingsStore.get("widget.enableNetwork", true)
    onEnableNetworkChanged: SettingsStore.set("widget.enableNetwork", enableNetwork)
    property bool enableResources: SettingsStore.get("widget.enableResources", true)
    onEnableResourcesChanged: SettingsStore.set("widget.enableResources", enableResources)
    property bool enablePowerProfiles: SettingsStore.get("widget.enablePowerProfiles", true)
    onEnablePowerProfilesChanged: SettingsStore.set("widget.enablePowerProfiles", enablePowerProfiles)
    property bool enableWeather: SettingsStore.get("widget.enableWeather", true)
    onEnableWeatherChanged: SettingsStore.set("widget.enableWeather", enableWeather)
    property string weatherLocation: SettingsStore.get("widget.weatherLocation", "auto")
    onWeatherLocationChanged: SettingsStore.set("widget.weatherLocation", weatherLocation)
}
