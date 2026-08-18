// services/CenterState.qml
import QtQuick
import Quickshell
import "../Settings"
import "./"

pragma Singleton

Item {
    id: root

    property bool qsVisible: false
    property bool mediaVisible: false
    property var menuRef: null
    property string activeTab: "Default"
    property rect anchorRect: Qt.rect(0, 0, 0, 0)

    onQsVisibleChanged: {
        Variables.controlCenterOpen = qsVisible || mediaVisible;
        if (qsVisible) {
            if (typeof QuickSettingsService !== "undefined") QuickSettingsService.close();
            mediaVisible = false;
            if (typeof MediaPlayerService !== "undefined") MediaPlayerService.closeMediaPopup();
        }
    }
    onMediaVisibleChanged: Variables.controlCenterOpen = qsVisible || mediaVisible

    function open(tab, rect) {
        let targetTab = (tab && tab !== "") ? tab : "Default";
        activeTab = targetTab;
        if (rect !== undefined) anchorRect = rect;
        
        if (typeof DynamicIslandService !== "undefined") DynamicIslandService.close();
        if (typeof QuickSettingsService !== "undefined") QuickSettingsService.close();
        mediaVisible = false;
        if (typeof MediaPlayerService !== "undefined") MediaPlayerService.closeMediaPopup();
        
        qsVisible = true;
        if (menuRef) menuRef.visible = true;
    }

    function toggleMedia(rect) {
        if (mediaVisible) {
            close();
        } else {
            close();
            if (typeof QuickSettingsService !== "undefined") QuickSettingsService.close();
            if (rect !== undefined) anchorRect = rect;
            mediaVisible = true;
        }
    }

    function toggle(tab, rect) {
        let targetTab = (tab && tab !== "") ? tab : "Default";
        if (qsVisible && activeTab === targetTab) {
            close();
        } else {
            open(targetTab, rect);
        }
    }

    function close() {
        qsVisible = false;
        mediaVisible = false;
        if (menuRef) menuRef.visible = false;
        if (typeof MediaPlayerService !== "undefined") MediaPlayerService.closeMediaPopup();
    }
}
