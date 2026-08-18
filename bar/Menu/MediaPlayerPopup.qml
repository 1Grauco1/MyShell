import "../.."
import "../../services"
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
    property real anchorX: 0
    property var _volumes: ({})
    property bool _windowVisible: false

    readonly property var activePlayer: MediaPlayerService.trackedPlayer
    readonly property bool hasSeek: activePlayer != null && activePlayer.positionSupported && activePlayer.length > 0
    readonly property bool volSupported: activePlayer != null && activePlayer.volumeSupported
    readonly property bool loopSupported: activePlayer != null && activePlayer.loopSupported
    readonly property bool canPlayPause: activePlayer != null && (activePlayer.canTogglePlaying || activePlayer.canPlay || activePlayer.canPause)

    visible: _windowVisible
    color: "transparent"

    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.exclusiveZone: 0
    WlrLayershell.keyboardFocus: MediaPlayerService.mediaShortcutMode ? WlrKeyboardFocus.Exclusive : WlrKeyboardFocus.None
    WlrLayershell.namespace: "mediaplayer"
    anchors {
        top: true
        left: true
        right: true
    }

    WlrLayershell.margins {
        top: Theme.barMarginTop + Theme.barHeight + Theme.scaled(4)
    }

    implicitHeight: Theme.scaled(190)

    // Input mask: just the card itself
    mask: Region {
        item: mainCard
    }

    Connections {
        target: MediaPlayerService
        function onMediaHoverOpenChanged() {
            if (MediaPlayerService.mediaHoverOpen) {
                closeAnim.stop();
                _windowVisible = true;
                mainCard.opacity = 0;
                mainCard.scale = 0.92;
                mainCard.y = -Theme.scaled(6);
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

    // --- Open animation: scale up + fade in + slide down ---
    ParallelAnimation {
        id: showAnim
        NumberAnimation { target: mainCard; property: "opacity"; from: 0; to: 1; duration: Theme.animFast; easing.type: Theme.animEasing }
        NumberAnimation { target: mainCard; property: "scale"; from: 0.92; to: 1.0; duration: Theme.animNormal; easing.type: Theme.elasticEasing }
        NumberAnimation { target: mainCard; property: "y"; from: -Theme.scaled(6); to: 0; duration: Theme.animNormal; easing.type: Theme.elasticEasing }
    }

    // --- Close animation: scale down + fade out + slide up ---
    SequentialAnimation {
        id: closeAnim
        ParallelAnimation {
            NumberAnimation { target: mainCard; property: "opacity"; from: mainCard.opacity; to: 0; duration: 180; easing.type: Easing.InCubic }
            NumberAnimation { target: mainCard; property: "scale"; from: mainCard.scale; to: 0.95; duration: 180; easing.type: Easing.InCubic }
            NumberAnimation { target: mainCard; property: "y"; from: mainCard.y; to: -Theme.scaled(4); duration: 180; easing.type: Easing.InCubic }
        }
        ScriptAction { script: { mainCard.opacity = 0; mainCard.scale = 0.92; mainCard.y = -Theme.scaled(6); root._windowVisible = false; } }
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

    readonly property string playerIcon: {
        if (!activePlayer) return "";
        let id = activePlayer.identity ? activePlayer.identity.toLowerCase() : "";
        if (id.includes("firefox") || id.includes("zen")) return "󰗀";
        if (id.includes("chrom") || id.includes("brave") || id.includes("vivaldi") || id.includes("opera") || id.includes("edge")) return "󰖟";
        if (id.includes("spotify")) return "󰓇";
        if (id.includes("vlc") || id.includes("celluloid")) return "󰕼";
        if (id.includes("mpv")) return "󰐔";
        if (id.includes("youtube")) return "󰗃";
        return "󰎈";
    }

    Rectangle {
        id: mainCard
        anchors.top: parent.top
        x: {
            let winW = screen ? screen.width : Theme.screenWidth;
            let center = root.anchorX > 0 ? root.anchorX : winW / 2;
            return Math.max(Theme.scaled(10), Math.min(center - width / 2, winW - width - Theme.scaled(10)));
        }
        width: Math.min(Theme.scaled(460), (screen ? screen.width : Theme.screenWidth) - Theme.scaled(20))
        height: Theme.scaled(172)

        color: Theme.glassBackground
        radius: Theme.cardRadius
        border.color: Theme.glassBorder
        border.width: 1
        clip: true

        // --- Drop shadow layer ---
        Rectangle {
            id: cardShadow
            anchors.fill: parent
            anchors.margins: -1
            radius: parent.radius + 1
            color: "transparent"
            border.color: Qt.rgba(0, 0, 0, 0.25)
            border.width: Theme.scaled(3)
            z: -1
            opacity: 0.6
        }

        // --- Subtle accent glow at top edge ---
        Rectangle {
            anchors.top: parent.top
            anchors.left: parent.left
            anchors.right: parent.right
            height: Theme.scaled(2)
            radius: Theme.cardRadius
            gradient: Gradient {
                GradientStop { position: 0.0; color: Qt.alpha(Theme.accentColor, 0.4) }
                GradientStop { position: 0.5; color: Qt.alpha(Theme.accentColor, 0.15) }
                GradientStop { position: 1.0; color: "transparent" }
            }
        }

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
            anchors.margins: Theme.scaled(16)
            spacing: Theme.scaled(9)

            // ============ Row 1: Album art + track info ============
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(14)

                // --- Album art (click to play/pause) ---
                Rectangle {
                    id: artBox
                    property bool hovered: false
                    width: Theme.scaled(64)
                    height: Theme.scaled(64)
                    radius: Theme.scaled(16)
                    color: Theme.surface1
                    clip: true
                    Layout.alignment: Qt.AlignVCenter

                    border.color: Qt.alpha(Theme.accentColor, MediaPlayerService.isActuallyPlaying ? 0.55 : 0.0)
                    border.width: 1
                    Behavior on border.color { ColorAnimation { duration: Theme.animFast } }

                    // --- Art shadow for depth ---
                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: -2
                        radius: parent.radius + 2
                        color: "transparent"
                        border.color: Qt.rgba(0, 0, 0, 0.2)
                        border.width: Theme.scaled(2)
                        z: -1
                    }

                    Image {
                        id: artImg
                        anchors.fill: parent
                        fillMode: Image.PreserveAspectCrop
                        source: MediaPlayerService.trackedPlayer ? String(MediaPlayerService.trackedPlayer.trackArtUrl || "") : ""
                        opacity: (artImg.source && artImg.status === Image.Ready) ? 1 : 0
                        Behavior on opacity { NumberAnimation { duration: 250 } }
                    }

                    Text {
                        anchors.centerIn: parent
                        text: "󰎆"
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(24)
                        color: Theme.surface2
                        visible: !artImg.source || artImg.status !== Image.Ready
                    }

                    // Darken + play/pause overlay on hover
                    Rectangle {
                        anchors.fill: parent
                        radius: Theme.scaled(16)
                        color: artBox.hovered ? Qt.rgba(0, 0, 0, 0.35) : "transparent"
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }

                        Text {
                            anchors.centerIn: parent
                            text: MediaPlayerService.isActuallyPlaying ? "󰏤" : "󰐊"
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(20)
                            color: "white"
                            opacity: artBox.hovered ? 1 : 0
                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
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

                // --- Title / artist / player badge ---
                ColumnLayout {
                    Layout.fillWidth: true
                    Layout.alignment: Qt.AlignVCenter
                    spacing: Theme.scaled(2)

                    // --- Title with marquee scroll for long text ---
                    Item {
                        Layout.fillWidth: true
                        height: titleText.implicitHeight + Theme.scaled(2)
                        clip: true

                        Text {
                            id: titleText
                            text: {
                                let p = MediaPlayerService.trackedPlayer;
                                if (!p) return "Nothing playing";
                                return MediaPlayerService.formatMediaTitle(String(p.trackTitle || "Media"), p.identity);
                            }
                            color: Theme.text
                            font.pixelSize: Theme.scaled(14.5)
                            font.weight: Font.DemiBold
                            anchors.verticalCenter: parent.verticalCenter

                            property bool needsScroll: implicitWidth > parent.width
                            property real scrollWidth: needsScroll ? implicitWidth - parent.width + Theme.scaled(12) : 0

                            onNeedsScrollChanged: {
                                if (needsScroll) {
                                    x = 0;
                                    marqueeSeq.restart();
                                } else {
                                    marqueeSeq.stop();
                                    x = 0;
                                }
                            }
                        }

                        SequentialAnimation {
                            id: marqueeSeq
                            loops: Animation.Infinite
                            running: false

                            PauseAnimation { duration: 1500 }
                            NumberAnimation { target: titleText; property: "x"; from: 0; to: -titleText.scrollWidth; duration: Math.max(2500, titleText.scrollWidth * 10); easing.type: Easing.Linear }
                            PauseAnimation { duration: 1500 }
                            ScriptAction { script: titleText.x = 0; }
                        }
                    }

                    // --- Artist / Album row ---
                    RowLayout {
                        Layout.fillWidth: true
                        spacing: Theme.scaled(6)

                        Text {
                            Layout.fillWidth: true
                            text: {
                                let p = MediaPlayerService.trackedPlayer;
                                if (!p) return "";
                                let a = String(p.trackArtist || "");
                                let al = String(p.trackAlbum || "");
                                if (a && a !== "undefined" && al && al !== "undefined") return a + " — " + al;
                                if (a && a !== "undefined") return a;
                                if (al && al !== "undefined") return al;
                                return String(p.identity || "");
                            }
                            color: Theme.subtext0
                            font.pixelSize: Theme.scaled(11.5)
                            elide: Text.ElideRight
                        }

                        // --- Player identity badge ---
                        Rectangle {
                            visible: root.activePlayer && root.activePlayer.identity
                            width: playerBadgeRow.implicitWidth + Theme.scaled(10)
                            height: Theme.scaled(16)
                            radius: Theme.scaled(8)
                            color: Qt.alpha(Theme.accentColor, 0.12)
                            border.color: Qt.alpha(Theme.accentColor, 0.2)
                            border.width: 1
                            Layout.alignment: Qt.AlignVCenter

                            RowLayout {
                                id: playerBadgeRow
                                anchors.centerIn: parent
                                spacing: Theme.scaled(3)

                                Text {
                                    text: root.playerIcon
                                    font.family: Theme.iconFont
                                    font.pixelSize: Theme.scaled(9)
                                    color: Theme.accentColor
                                }

                                Text {
                                    text: root.activePlayer ? root.activePlayer.identity : ""
                                    color: Theme.accentColor
                                    font.pixelSize: Theme.scaled(8)
                                    font.weight: Font.DemiBold
                                    elide: Text.ElideRight
                                    Layout.maximumWidth: Theme.scaled(60)
                                }
                            }
                        }
                    }
                }
            }

            // ============ Row 2: Seek / live ============
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

                Slider {
                    id: posSlider
                    visible: root.hasSeek
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.scaled(20)
                    Layout.alignment: Qt.AlignVCenter
                    from: 0
                    to: root.hasSeek ? root.activePlayer.length : 100
                    value: MediaPlayerService.currentPos
                    enabled: root.activePlayer != null && root.activePlayer.canSeek
                    opacity: enabled ? 1 : 0.45
                    onMoved: { let p = MediaPlayerService.trackedPlayer; if (p) p.position = value }
                    padding: 0; leftPadding: 0; rightPadding: 0; topPadding: 0; bottomPadding: 0

                    background: Rectangle {
                        x: posSlider.leftPadding
                        y: posSlider.topPadding + (posSlider.availableHeight - height) / 2
                        height: posSlider.hovered || posSlider.pressed ? Theme.scaled(6) : Theme.scaled(4)
                        width: posSlider.availableWidth
                        radius: Theme.scaled(3)
                        color: Theme.surface1
                        Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                        Rectangle {
                            width: posSlider.visualPosition * parent.width
                            height: parent.height
                            radius: Theme.scaled(3)
                            gradient: Gradient {
                                GradientStop { position: 0.0; color: Theme.blue }
                                GradientStop { position: 1.0; color: Theme.lavender }
                            }
                        }
                    }
                    handle: Rectangle {
                        x: posSlider.leftPadding + posSlider.visualPosition * (posSlider.availableWidth - width)
                        y: posSlider.topPadding + (posSlider.availableHeight - height) / 2
                        width: posSlider.hovered || posSlider.pressed ? Theme.scaled(14) : Theme.scaled(10)
                        height: width
                        radius: width / 2
                        color: Colors.on_primary
                        visible: true
                        opacity: posSlider.hovered || posSlider.pressed ? 1 : 0
                        Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                        Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                    }
                }

                // Live badge for streams without a seekable length
                Item {
                    id: liveBadge
                    visible: !root.hasSeek
                    Layout.fillWidth: true
                    Layout.preferredHeight: Theme.scaled(16)

                    RowLayout {
                        anchors.centerIn: parent
                        spacing: Theme.scaled(5)

                        Rectangle {
                            width: Theme.scaled(7); height: Theme.scaled(7); radius: width / 2
                            color: Theme.red
                            SequentialAnimation on opacity {
                                running: liveBadge.visible
                                loops: Animation.Infinite
                                NumberAnimation { from: 1.0; to: 0.2; duration: 900 }
                                NumberAnimation { from: 0.2; to: 1.0; duration: 900 }
                            }
                        }

                        Text {
                            text: "LIVE"
                            color: Theme.red
                            font.family: Constants.monoFont
                            font.pixelSize: Theme.scaled(10)
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

            // ============ Row 3: Controls ============
            RowLayout {
                Layout.fillWidth: true
                spacing: Theme.scaled(4)
                Layout.alignment: Qt.AlignVCenter

                // --- Previous ---
                Button {
                    flat: true
                    implicitWidth: Theme.scaled(30); implicitHeight: Theme.scaled(30)
                    enabled: root.activePlayer != null && root.activePlayer.canGoPrevious
                    opacity: enabled ? 1 : 0.35
                    onClicked: { let p = MediaPlayerService.trackedPlayer; if (p) p.previous(); }
                    contentItem: Text {
                        text: "󰒮"
                        color: Theme.text
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(14)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered && parent.enabled ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                        radius: 999
                        scale: parent.pressed ? 0.9 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                }

                // --- Play / Pause (accent) ---
                Button {
                    flat: true
                    implicitWidth: Theme.scaled(40); implicitHeight: Theme.scaled(40)
                    enabled: root.canPlayPause
                    opacity: enabled ? 1 : 0.35
                    onClicked: root.togglePlayback()
                    contentItem: Text {
                        text: MediaPlayerService.isActuallyPlaying ? "󰏤" : "󰐊"
                        color: Colors.on_primary
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(18)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        radius: width / 2
                        gradient: Gradient {
                            GradientStop { position: 0.0; color: Theme.blue }
                            GradientStop { position: 1.0; color: Theme.lavender }
                        }
                        scale: parent.pressed ? 0.92 : (parent.hovered && parent.enabled ? 1.08 : 1.0)
                        Behavior on scale { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                    }
                }

                // --- Next ---
                Button {
                    flat: true
                    implicitWidth: Theme.scaled(30); implicitHeight: Theme.scaled(30)
                    enabled: root.activePlayer != null && root.activePlayer.canGoNext
                    opacity: enabled ? 1 : 0.35
                    onClicked: { let p = MediaPlayerService.trackedPlayer; if (p) p.next(); }
                    contentItem: Text {
                        text: "󰒭"
                        color: Theme.text
                        font.family: Theme.iconFont
                        font.pixelSize: Theme.scaled(14)
                        horizontalAlignment: Text.AlignHCenter
                        verticalAlignment: Text.AlignVCenter
                    }
                    background: Rectangle {
                        color: parent.hovered && parent.enabled ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                        radius: 999
                        scale: parent.pressed ? 0.9 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                }

                Item { Layout.fillWidth: true }

                // --- Volume (mute toggle + slider) ---
                RowLayout {
                    visible: root.volSupported
                    spacing: Theme.scaled(4)
                    Layout.alignment: Qt.AlignVCenter

                    Button {
                        flat: true
                        implicitWidth: Theme.scaled(28); implicitHeight: Theme.scaled(28)
                        onClicked: root.toggleMute()
                        contentItem: Text {
                            text: root.volIcon
                            color: Theme.subtext0
                            font.family: Theme.iconFont
                            font.pixelSize: Theme.scaled(13)
                            horizontalAlignment: Text.AlignHCenter
                            verticalAlignment: Text.AlignVCenter
                        }
                        background: Rectangle {
                            color: parent.hovered ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                            radius: 999
                            scale: parent.pressed ? 0.9 : 1.0
                            Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                            Behavior on color { ColorAnimation { duration: Theme.animFast } }
                        }
                    }

                    Slider {
                        id: volumeSlider
                        Layout.preferredWidth: Theme.scaled(80)
                        Layout.preferredHeight: Theme.scaled(18)
                        from: 0; to: 100
                        value: root.activePlayer ? root.activePlayer.volume * 100 : 0
                        onMoved: { let p = MediaPlayerService.trackedPlayer; if (p) p.volume = value / 100 }
                        padding: 0; leftPadding: 0; rightPadding: 0; topPadding: 0; bottomPadding: 0

                        background: Rectangle {
                            x: volumeSlider.leftPadding
                            y: volumeSlider.topPadding + (volumeSlider.availableHeight - height) / 2
                            height: volumeSlider.hovered || volumeSlider.pressed ? Theme.scaled(6) : Theme.scaled(4)
                            width: volumeSlider.availableWidth
                            radius: Theme.scaled(3)
                            color: Theme.surface1
                            Behavior on height { NumberAnimation { duration: 150; easing.type: Easing.OutCubic } }

                            Rectangle {
                                width: volumeSlider.visualPosition * parent.width
                                height: parent.height
                                radius: Theme.scaled(3)
                                color: Theme.accentColor
                            }
                        }
                        handle: Rectangle {
                            x: volumeSlider.leftPadding + volumeSlider.visualPosition * (volumeSlider.availableWidth - width)
                            y: volumeSlider.topPadding + (volumeSlider.availableHeight - height) / 2
                            width: volumeSlider.hovered || volumeSlider.pressed ? Theme.scaled(14) : Theme.scaled(10)
                            height: width
                            radius: width / 2
                            color: Colors.on_primary
                            visible: true
                            opacity: volumeSlider.hovered || volumeSlider.pressed ? 1 : 0
                            Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                            Behavior on opacity { NumberAnimation { duration: Theme.animFast } }
                        }
                    }
                }

                // --- Loop cycle: none -> track -> playlist ---
                Button {
                    flat: true
                    visible: root.loopSupported
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
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                    background: Rectangle {
                        color: parent.hovered ? Qt.rgba(255, 255, 255, 0.1) : "transparent"
                        radius: 999
                        scale: parent.pressed ? 0.9 : 1.0
                        Behavior on scale { NumberAnimation { duration: 100; easing.type: Easing.OutCubic } }
                        Behavior on color { ColorAnimation { duration: Theme.animFast } }
                    }
                }

                // --- Player switcher dots ---
                RowLayout {
                    spacing: Theme.scaled(2)
                    Layout.alignment: Qt.AlignVCenter

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
                                Behavior on width { NumberAnimation { duration: Theme.animFast; easing.type: Theme.animEasing } }
                                Behavior on color { ColorAnimation { duration: Theme.animFast } }
                            }
                        }
                    }
                }
            }
        }
    }
}
