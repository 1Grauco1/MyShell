import "../.."
import "../../services"
import "../../Settings"
import "./components"
import QtQuick
import QtQuick.Controls 2.15
import QtQuick.Layouts
import Quickshell
import Quickshell.Services.Mpris
import Quickshell.Wayland

PanelWindow {
    id: root

    property var parentWindow: null
    property var _volumes: ({})
    property bool _windowVisible: false

    readonly property var activePlayer: MediaPlayerService.trackedPlayer
    readonly property bool hasSeek: activePlayer != null && activePlayer.positionSupported && activePlayer.length > 0
    readonly property bool volSupported: activePlayer != null && activePlayer.volumeSupported
    readonly property bool loopSupported: activePlayer != null && activePlayer.loopSupported
    readonly property bool canPlayPause: activePlayer != null && (activePlayer.canTogglePlaying || activePlayer.canPlay || activePlayer.canPause)
    readonly property bool shuffleSupported: activePlayer != null && typeof activePlayer.shuffle === "boolean"
    readonly property bool shuffleActive: shuffleSupported && activePlayer.shuffle

    visible: _windowVisible
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: MediaPlayerService.mediaShortcutMode ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "mediaplayer"
    anchors {
        top: true
        bottom: true
        left: true
        right: true
    }

    mask: Region {
        item: contentArea
    }

    MouseArea {
        anchors.fill: parent
        z: -1
        onClicked: MediaPlayerService.closeMediaPopup()
    }

    Item {
        id: contentArea
        anchors.fill: parent
    }

    Connections {
        target: MediaPlayerService
        function onMediaHoverOpenChanged() {
            if (MediaPlayerService.mediaHoverOpen) {
                closeAnim.stop();
                _windowVisible = true;
                mainCard.opacity = 0;
                mainCard.scale = 0.92;
                showAnim.restart();
                if (MediaPlayerService.mediaShortcutMode) mainCard.forceActiveFocus();
            } else {
                closeAnim.restart();
            }
        }
        function onTrackedPlayerChanged() {
            if (!MediaPlayerService.trackedPlayer && _windowVisible) {
                closeAnim.stop();
                mainCard.opacity = 0;
                _windowVisible = false;
            }
        }
    }

    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: mainCard; property: "opacity"; from: 0; to: 1; duration: Theme.animFast; easing.type: Theme.animEasing }
        NumberAnimation { target: mainCard; property: "scale"; from: 0.92; to: 1.0; duration: Theme.animNormal; easing.type: Theme.elasticEasing }
    }

    SequentialAnimation {
        id: closeAnim
        ParallelAnimation {
            NumberAnimation { target: mainCard; property: "opacity"; from: mainCard.opacity; to: 0; duration: 150; easing.type: Easing.InCubic }
            NumberAnimation { target: mainCard; property: "scale"; from: mainCard.scale; to: 0.95; duration: 150; easing.type: Easing.InCubic }
        }
        ScriptAction { script: { mainCard.opacity = 0; mainCard.scale = 0.92; root._windowVisible = false; } }
    }

    function formatTime(s) {
        if (s < 0 || isNaN(s)) return "0:00";
        let mins = Math.floor(s / 60);
        let secs = Math.floor(s % 60);
        return mins + ":" + (secs < 10 ? "0" : "") + secs;
    }

    function togglePlayback() {
        let p = MediaPlayerService.trackedPlayer;
        if (!p) return;
        if (p.canTogglePlaying) p.togglePlaying();
        else if (MediaPlayerService.isActuallyPlaying && p.canPause) p.pause();
        else if (p.canPlay) p.play();
    }

    function cycleLoop() {
        let p = MediaPlayerService.trackedPlayer;
        if (!p || !p.canControl) return;
        if (p.loopState === MprisLoopState.None) p.loopState = MprisLoopState.Track;
        else if (p.loopState === MprisLoopState.Track) p.loopState = MprisLoopState.Playlist;
        else p.loopState = MprisLoopState.None;
    }

    function toggleShuffle() {
        let p = MediaPlayerService.trackedPlayer;
        if (!p || !shuffleSupported) return;
        p.shuffle = !p.shuffle;
    }

    function launchPlayerApp() {
        let p = MediaPlayerService.trackedPlayer;
        if (!p) return;
        try {
            if (p.launchContext) {
                p.launchContext.activate();
            }
        } catch(e) {}
    }

    function toggleMute() {
        let p = MediaPlayerService.trackedPlayer;
        if (!p) return;
        if (p.volume > 0.01) {
            root._volumes[p.identity] = p.volume;
            p.volume = 0;
        } else {
            let last = root._volumes[p.identity];
            p.volume = (last && last > 0) ? last : 0.5;
        }
    }

    function adjustVolume(delta) {
        let p = MediaPlayerService.trackedPlayer;
        if (!p || !p.volumeSupported) return;
        let newVol = Math.max(0, Math.min(1, p.volume + delta));
        p.volume = newVol;
    }

    readonly property string volIcon: {
        if (!activePlayer) return Theme.volHigh;
        let v = activePlayer.volume;
        if (v <= 0.01) return Theme.volMute;
        if (v <= 0.35) return Theme.volLow;
        if (v <= 0.7) return Theme.volMid;
        return Theme.volHigh;
    }

    Rectangle {
        id: mainCard
        parent: contentArea
        anchors.centerIn: parent
        width: Theme.scaled(360)
        height: Theme.scaled(360)

        color: Theme.glassBackground
        radius: Theme.cardRadius
        border.color: Theme.glassBorder
        border.width: 1
        clip: true

        Keys.enabled: MediaPlayerService.mediaHoverOpen
        Keys.onUpPressed: {
            if (MediaPlayerService.mediaShortcutMode) root.adjustVolume(0.05);
            else MediaPlayerService.closeMediaPopup();
        }
        Keys.onDownPressed: {
            if (MediaPlayerService.mediaShortcutMode) root.adjustVolume(-0.05);
        }
        Keys.onLeftPressed: { let p = MediaPlayerService.trackedPlayer; if (p && p.canGoPrevious) p.previous(); }
        Keys.onRightPressed: { let p = MediaPlayerService.trackedPlayer; if (p && p.canGoNext) p.next(); }
        Keys.onEscapePressed: MediaPlayerService.closeMediaPopup()

        ColumnLayout {
            anchors.fill: parent
            anchors.margins: Theme.scaled(22)
            spacing: Theme.scaled(14)

            // ============ Album art ============
            Rectangle {
                id: artBox
                property bool hovered: false
                Layout.fillWidth: true
                Layout.preferredHeight: Theme.scaled(200)
                Layout.alignment: Qt.AlignHCenter
                radius: Theme.scaled(16)
                color: Theme.surface1
                clip: true

                Image {
                    id: artImg
                    anchors.fill: parent
                    fillMode: Image.PreserveAspectCrop
                    source: MediaPlayerService.trackedPlayer ? String(MediaPlayerService.trackedPlayer.trackArtUrl || "") : ""
                    opacity: (artImg.source && artImg.status === Image.Ready) ? 1 : 0
                }

                Text {
                    anchors.centerIn: parent
                    text: "󰎆"
                    font.family: Theme.iconFont
                    font.pixelSize: Theme.scaled(48)
                    color: Theme.surface2
                    visible: !artImg.source || artImg.status !== Image.Ready
                }

                Rectangle {
                    anchors.fill: parent
                    radius: Theme.scaled(16)
                    color: artBox.hovered ? Qt.rgba(0, 0, 0, 0.3) : "transparent"

                    Text {
                        anchors.centerIn: parent
                        text: MediaPlayerService.isActuallyPlaying ? "󰏤" : "󰐊"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(34)
                        color: "white"
                        opacity: artBox.hovered ? 1 : 0
                    }
                }

                MouseArea {
                    anchors.fill: parent
                    hoverEnabled: true
                    cursorShape: Qt.PointingHandCursor
                    onEntered: artBox.hovered = true
                    onExited: artBox.hovered = false
                    onClicked: root.togglePlayback()
                }
            }

            // ============ Track info (centered) ============
            ColumnLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(2)

                Item {
                    Layout.fillWidth: true
                    height: titleText.implicitHeight
                    clip: true

                    Text {
                        id: titleText
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: {
                            let p = MediaPlayerService.trackedPlayer;
                            if (!p) return "Nothing playing";
                            return MediaPlayerService.formatMediaTitle(String(p.trackTitle || "Media"), p.identity);
                        }
                        color: Theme.text
                        font.pixelSize: Theme.scaled(15)
                        font.weight: Font.DemiBold
                        horizontalAlignment: Text.AlignHCenter

                        property bool needsScroll: implicitWidth > parent.width
                        property real scrollWidth: needsScroll ? implicitWidth - parent.width + Theme.scaled(8) : 0

                        onNeedsScrollChanged: {
                            if (needsScroll) {
                                x = (parent.width - implicitWidth) / 2;
                                marqueeSeq.restart();
                            } else {
                                marqueeSeq.stop();
                                x = (parent.width - implicitWidth) / 2;
                            }
                        }

                        Component.onCompleted: x = (parent.width - implicitWidth) / 2
                    }

                    SequentialAnimation {
                        id: marqueeSeq
                        loops: Animation.Infinite
                        running: false

                        PauseAnimation { duration: 1500 }
                        NumberAnimation { target: titleText; property: "x"; from: titleText.x; to: -titleText.scrollWidth; duration: Math.max(2500, titleText.scrollWidth * 10); easing.type: Easing.Linear }
                        PauseAnimation { duration: 1500 }
                        ScriptAction { script: titleText.x = (titleText.parent.width - titleText.implicitWidth) / 2; }
                    }
                }

                Text {
                    Layout.fillWidth: true
                    horizontalAlignment: Text.AlignHCenter
                    text: {
                        let p = MediaPlayerService.trackedPlayer;
                        if (!p) return "";
                        let a = String(p.trackArtist || "");
                        if (a && a !== "undefined") return a;
                        return String(p.identity || "");
                    }
                    color: Theme.subtext0
                        font.pixelSize: Theme.scaled(12)
                        elide: Text.ElideRight
                }
            }

            // ============ Seek ============
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(6)

                Text {
                    text: root.formatTime(MediaPlayerService.currentPos)
                    color: Theme.subtext0
                    font.family: Constants.monoFont
                    font.pixelSize: Theme.scaled(10)
                    Layout.alignment: Qt.AlignVCenter
                }

                Item {
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.scaled(18)

                    Slider {
                        id: posSlider
                        visible: root.hasSeek
                        anchors.fill: parent
                        from: 0
                        to: root.hasSeek ? root.activePlayer.length : 100
                        value: MediaPlayerService.currentPos
                        enabled: root.activePlayer != null && root.activePlayer.canSeek
                        opacity: enabled ? 1 : 0.35
                        onMoved: { let p = MediaPlayerService.trackedPlayer; if (p) p.position = value }
                        padding: 0; leftPadding: 0; rightPadding: 0; topPadding: 0; bottomPadding: 0

                        background: Rectangle {
                            x: posSlider.leftPadding
                            y: posSlider.topPadding + (posSlider.availableHeight - height) / 2
                            height: Theme.scaled(4)
                            width: posSlider.availableWidth
                            radius: Theme.scaled(2)
                            color: Theme.surface1

                            Rectangle {
                                width: posSlider.visualPosition * parent.width
                                height: parent.height
                                radius: Theme.scaled(2)
                                color: Theme.accentColor
                            }
                        }
                        handle: Rectangle {
                            x: posSlider.leftPadding + posSlider.visualPosition * (posSlider.availableWidth - width)
                            y: posSlider.topPadding + (posSlider.availableHeight - height) / 2
                            width: Theme.scaled(10); height: width
                            radius: width / 2
                            color: Theme.accentColor
                            visible: posSlider.hovered || posSlider.pressed
                        }
                    }
                }

                Item {
                    id: liveBadge
                    visible: !root.hasSeek
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.scaled(14)

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Theme.scaled(4)

                        Rectangle {
                            width: Theme.scaled(5); height: Theme.scaled(5); radius: width / 2
                            color: Theme.red
                            SequentialAnimation on opacity {
                                running: liveBadge.visible
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.3; duration: 900 }
                                NumberAnimation { from: 0.3; to: 1.0; duration: 900 }
                            }
                        }

                        Text {
                            text: "LIVE"
                            color: Theme.red
                            font.family: Constants.monoFont
                            font.pixelSize: Theme.scaled(9)
                            font.weight: Font.DemiBold
                        }
                    }
                }

                Text {
                    visible: root.hasSeek
                    text: root.formatTime(root.activePlayer ? root.activePlayer.length : 0)
                    color: Theme.subtext0
                    font.family: Constants.monoFont
                    font.pixelSize: Theme.scaled(10)
                    Layout.alignment: Qt.AlignVCenter
                }
            }

            // ============ Controls ============
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(8)
                Layout.alignment: Qt.AlignHCenter

                Button {
                    flat: true
                    implicitWidth: Theme.scaled(32); implicitHeight: Theme.scaled(32)
                    enabled: root.activePlayer != null && root.activePlayer.canGoPrevious
                    opacity: enabled ? 1 : 0.25
                    onClicked: { let p = MediaPlayerService.trackedPlayer; if (p) p.previous(); }
                    contentItem: Text {
                        text: "󰒮"
                        color: Theme.text
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(15)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Item {}
                }

                Button {
                    flat: true
                    implicitWidth: Theme.scaled(44); implicitHeight: Theme.scaled(44)
                    enabled: root.canPlayPause
                    opacity: enabled ? 1 : 0.25
                    onClicked: root.togglePlayback()
                    contentItem: Text {
                        text: MediaPlayerService.isActuallyPlaying ? "󰏤" : "󰐊"
                        color: Theme.accentColor
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(22)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: width / 2
                        color: parent.hovered && parent.enabled ? Qt.alpha(Theme.accentColor, 0.1) : "transparent"
                    }
                }

                Button {
                    flat: true
                    implicitWidth: Theme.scaled(32); implicitHeight: Theme.scaled(32)
                    enabled: root.activePlayer != null && root.activePlayer.canGoNext
                    opacity: enabled ? 1 : 0.25
                    onClicked: { let p = MediaPlayerService.trackedPlayer; if (p) p.next(); }
                    contentItem: Text {
                        text: "󰒭"
                        color: Theme.text
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(15)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Item {}
                }
            }

            // ============ Secondary controls ============
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(6)
                Layout.alignment: Qt.AlignHCenter

                Button {
                    flat: true
                    visible: root.shuffleSupported
                    implicitWidth: Theme.scaled(28); implicitHeight: Theme.scaled(28)
                    onClicked: root.toggleShuffle()
                    contentItem: Text {
                        text: "󰒤"
                        color: root.shuffleActive ? Theme.accentColor : Theme.subtext0
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(13)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Item {}
                }

                Button {
                    flat: true
                    implicitWidth: Theme.scaled(28); implicitHeight: Theme.scaled(28)
                    onClicked: root.toggleMute()
                    visible: root.volSupported && MediaSettings.showVolumeControl
                    contentItem: Text {
                        text: root.volIcon
                        color: Theme.subtext0
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(13)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Item {}
                }

                Slider {
                    id: volumeSlider
                    visible: root.volSupported && MediaSettings.showVolumeControl
                    Layout.preferredWidth: Theme.scaled(70)
                    Layout.preferredHeight: Theme.scaled(16)
                    from: 0; to: 100
                    value: root.activePlayer ? root.activePlayer.volume * 100 : 0
                    onMoved: { let p = MediaPlayerService.trackedPlayer; if (p) p.volume = value / 100 }
                    padding: 0; leftPadding: 0; rightPadding: 0; topPadding: 0; bottomPadding: 0

                    background: Rectangle {
                        x: volumeSlider.leftPadding
                        y: volumeSlider.topPadding + (volumeSlider.availableHeight - height) / 2
                            height: Theme.scaled(4)
                            width: volumeSlider.availableWidth
                            radius: Theme.scaled(2)
                            color: Theme.surface1

                            Rectangle {
                                width: volumeSlider.visualPosition * parent.width
                                height: parent.height
                                radius: Theme.scaled(2)
                                color: Theme.accentColor
                            }
                        }
                        handle: Rectangle {
                            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                            y: volumeSlider.topPadding + (volumeSlider.availableHeight - height) / 2
                            width: Theme.scaled(10); height: width
                        radius: width / 2
                        color: Theme.accentColor
                        visible: volumeSlider.hovered || volumeSlider.pressed
                    }
                }

                Button {
                    flat: true
                    visible: root.loopSupported && MediaSettings.showLoopControl
                    implicitWidth: Theme.scaled(28); implicitHeight: Theme.scaled(28)
                    onClicked: root.cycleLoop()
                    contentItem: Text {
                        text: {
                            if (!root.activePlayer) return "󰑗";
                            switch (root.activePlayer.loopState) {
                            case MprisLoopState.Track: return "󰑘";
                            case MprisLoopState.Playlist: return "󰑖";
                            default: return "󰑗";
                            }
                        }
                        color: root.activePlayer && root.activePlayer.loopState !== MprisLoopState.None ? Theme.accentColor : Theme.subtext0
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(13)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Item {}
                }

                Repeater {
                    model: Mpris.players.values
                    delegate: MouseArea {
                        width: Theme.scaled(16); height: Theme.scaled(16)
                        cursorShape: Qt.PointingHandCursor
                        onClicked: MediaPlayerService.updateTrackedPlayer(modelData, true)
                        Rectangle {
                            anchors.centerIn: parent
                            width: (MediaPlayerService.trackedPlayer === modelData) ? Theme.scaled(10) : Theme.scaled(6)
                            height: width
                            radius: width / 2
                            color: (MediaPlayerService.trackedPlayer === modelData) ? Theme.accentColor : (modelData.playbackState === MprisPlaybackState.Playing ? Theme.green : Theme.surface2)
                        }
                    }
                }
            }
        }
    }
}
