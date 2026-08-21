pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Services.Mpris
import "../Settings"
import ".."

pragma Singleton

Item {
    id: service

    // --- Core Unified State ---
    property var trackedPlayer: null
    property var pinnedPlayer: null
    property bool isActuallyPlaying: false
    property real currentPos: 0
    property string currentTrackId: ""
    property bool mediaFocus: true
    
    // --- "Unbreakable" Variables ---
    property var _playerStack: ([])        
    property var _playerStates: ({})       
    property bool _initialized: false
    property bool _isResetting: false
    
    // --- Configuration: Fickle Sources ---
    readonly property var fickleIdentities: [
        "zen", "chrom", "fox", "brave", "vivaldi", "opera", "edge", 
        "chromium", "webkit", "anime", "youtube", "netflix", "twitch", "crunchyroll"
    ]
    
    // --- Configuration: Blacklist (Chat apps, etc) ---
    readonly property var blacklistIdentities: [
        "whatsapp", "telegram", "messenger", "discord", "slack", "chating", "chat"
    ]

    // --- Helper Logic ---
    function formatMediaTitle(title, identity) {
        if (!title) return "Unknown Media";
        let id = identity ? identity.toLowerCase() : "";
        
        if (id.includes("mpv") || id.includes("vlc") || id.includes("celluloid")) {
            title = title.replace(/\.(mp3|mp4|mkv|avi|flac|wav|ogg|webm|mov|m4a|wmv|mpg|mpeg)$/i, "");
            title = title.replace(/\s*[\(\[].*?[\)\]]/g, "");
        }
        
        title = title.replace(/ - YouTube$/i, "");
        title = title.replace(/ — Mozilla Firefox$/i, "");
        title = title.replace(/ - Google Chrome$/i, "");
        
        title = title.trim() || "Media";
        if (MediaSettings.truncateTrackTitle && title.length > MediaSettings.maxTrackTitleLength)
            title = title.slice(0, MediaSettings.maxTrackTitleLength) + "\u2026";
        return title;
    }

    function formatMediaMetadata(fullText, limit, overflowThreshold) {
        if (!fullText) return "";
        let lim = limit || 34;
        let thresh = (overflowThreshold !== undefined) ? overflowThreshold : 5;
        
        if (fullText.length <= lim + thresh) {
            return fullText;
        }
        
        let target = fullText.substring(0, lim);
        let lastSpace = target.lastIndexOf(" ");
        if (lastSpace > 8) {
            return target.substring(0, lastSpace) + "...";
        }
        return target.substring(0, lim - 3) + "...";
    }

    function isFickle(player) {
        if (!player) return false;
        let id = player.identity.toLowerCase();
        let title = (player.trackTitle || "").toLowerCase();
        for (let i = 0; i < fickleIdentities.length; i++) {
            let term = fickleIdentities[i];
            if (id.includes(term) || title.includes(term)) return true;
        }
        return false;
    }
    
    function isBlacklisted(player) {
        if (!player) return false;
        let id = player.identity.toLowerCase();
        for (let i = 0; i < blacklistIdentities.length; i++) {
            if (id.includes(blacklistIdentities[i])) return true;
        }
        return false;
    }

    function manageFocus(newPlayer) {
        if (!newPlayer || !_initialized || !MediaSettings.autoManageMediaFocus || !service.mediaFocus) return;
        if (newPlayer.playbackState !== MprisPlaybackState.Playing) return;
        if (isBlacklisted(newPlayer)) return;

        let players = Mpris.players.values;
        for (let i = 0; i < players.length; i++) {
            let other = players[i];
            if (other && other !== newPlayer && other.playbackState === MprisPlaybackState.Playing) {
                if (service.trackedPlayer === other && !isBlacklisted(other)) {
                    let idx = _playerStack.indexOf(other);
                    if (idx !== -1) _playerStack.splice(idx, 1);
                    _playerStack.push(other);
                }
                other.pause();
            }
        }
    }

    function updateTrackedPlayer(newPlayer, userAction) {
        if (!newPlayer) return;
        
        if (newPlayer.playbackState === MprisPlaybackState.Playing) {
            manageFocus(newPlayer);
        }

        if (service.trackedPlayer !== newPlayer) {
            service.trackedPlayer = newPlayer;
            service.currentTrackId = ""; 
            service._lastPos = -1;
            // Show the new player's position immediately instead of the old
            // player's for up to a heartbeat tick (~1s) after switching.
            service.currentPos = (newPlayer.position !== undefined) ? Number(newPlayer.position) : 0.0;
        }

        // An explicit user selection (e.g. player dots) is respected: the
        // heartbeat won't auto-switch away from a player the user chose,
        // even if it is paused.
        if (userAction) service.pinnedPlayer = newPlayer;
    }

    // --- Heartbeat Engine ---
    property real _lastPos: -1
    Timer {
        id: engineTimer
        interval: 1000
        running: Mpris.players.values.length > 0
        repeat: true
        onTriggered: {
            let players = Mpris.players.values;
            let now = Date.now();

            for (let i = 0; i < players.length; i++) {
                let p = players[i];
                let id = p.identity; 
                let state = _playerStates[id] || { pos: -1, advancing: false, lastMove: now };
                
                let moved = (p.position !== state.pos);
                state.advancing = moved;
                if (moved) state.lastMove = now;
                state.pos = p.position;
                state.stalled = (now - state.lastMove > Constants.stallTimeout);
                
                _playerStates[id] = state;
            }

            if (!trackedPlayer) {
                isActuallyPlaying = false;
                return;
            }

            let currentState = _playerStates[trackedPlayer.identity];
            
            if (trackedPlayer.playbackState === MprisPlaybackState.Playing) {
                if (isFickle(trackedPlayer)) {
                    isActuallyPlaying = (currentState && currentState.advancing && !currentState.stalled);
                } else {
                    isActuallyPlaying = true;
                }
            } else {
                isActuallyPlaying = false;
            }

            if (!_isResetting) {
                currentPos = (trackedPlayer && trackedPlayer.position !== undefined) ? Number(trackedPlayer.position) : 0.0;
            }

            // Never steal focus from a player the user explicitly picked and
            // left paused; only auto-switch when it is stopped or was never pinned.
            const pinnedPaused = service.pinnedPlayer
                    && service.pinnedPlayer === trackedPlayer
                    && trackedPlayer.playbackState === MprisPlaybackState.Paused;

            if (!pinnedPaused && (trackedPlayer.playbackState !== MprisPlaybackState.Playing || (isFickle(trackedPlayer) && !isActuallyPlaying))) {
                let better = players.find(p => {
                    let s = _playerStates[p.identity];
                    return p.playbackState === MprisPlaybackState.Playing && s && s.advancing && !s.stalled && !isBlacklisted(p);
                });
                if (better && better !== trackedPlayer) updateTrackedPlayer(better);
            }
        }
    }

    Timer {
        id: resetTimer
        repeat: false
        onTriggered: {
            if (trackedPlayer) currentPos = trackedPlayer.position;
            _isResetting = false;
        }
    }

    function triggerReset() {
        _isResetting = true;
        currentPos = 0;
        resetTimer.interval = isFickle(trackedPlayer) ? 2000 : 800;
        resetTimer.restart();
    }

    // --- Media Popup (keyboard shortcut / IPC only) ---
    property bool mediaHoverOpen: false
    property bool mediaShortcutMode: false

    // Force-close the media popup
    function closeMediaPopup() {
        mediaHoverOpen = false;
        mediaShortcutMode = false;
    }

    // Toggle the media popup (used by keyboard shortcut / IPC)
    function toggleMediaPopup() {
        if (mediaHoverOpen) {
            closeMediaPopup();
        } else {
            if (!trackedPlayer) return;
            mediaShortcutMode = true;
            mediaHoverOpen = true;
        }
    }

    onTrackedPlayerChanged: {
        if (!trackedPlayer && mediaHoverOpen) closeMediaPopup();
    }

    // --- Event Handlers ---
    Instantiator {
        model: Mpris.players
        onObjectAdded: (key, obj) => {
            if (service.mediaFocus && (!service.trackedPlayer || obj.playbackState === MprisPlaybackState.Playing))
                updateTrackedPlayer(obj);
        }
        onObjectRemoved: (key, obj) => {
            let idx = _playerStack.indexOf(obj);
            if (idx !== -1) _playerStack.splice(idx, 1);
            
            if (service.pinnedPlayer === obj) service.pinnedPlayer = null;
            
            if (service.trackedPlayer === obj) {
                let players = Mpris.players.values;
                let next = players.find(p => p.playbackState === MprisPlaybackState.Playing && !isBlacklisted(p));
                
                service.trackedPlayer = next ? next : (players.length > 0 ? players[0] : null);
            }
        }
        delegate: Connections {
            required property var modelData

            target: modelData
            
            function onPlaybackStateChanged() {
                if (modelData.playbackState === MprisPlaybackState.Playing) {
                    updateTrackedPlayer(modelData);
                } else if (service.trackedPlayer === modelData) {
                    let players = Mpris.players.values;
                    let active = players.find(p => p !== modelData && p.playbackState === MprisPlaybackState.Playing && !isBlacklisted(p));

                    if (active && service.mediaFocus) {
                        updateTrackedPlayer(active);
                    } else if (modelData.playbackState === MprisPlaybackState.Stopped && service.mediaHoverOpen) {
                        if (service.pinnedPlayer === modelData) service.pinnedPlayer = null;
                        service.closeMediaPopup();
                    }
                }
            }
            
            function onMetadataChanged() {
                if (modelData.playbackState === MprisPlaybackState.Playing) {
                    updateTrackedPlayer(modelData);
                }
                
                if (service.trackedPlayer === modelData) {
                    let newId = String(modelData.trackTitle + modelData.trackArtist);
                    if (newId !== service.currentTrackId) {
                        service.currentTrackId = newId;
                        service.triggerReset();
                    }
                }
            }
        }
    }

    Timer {
        id: initTimer
        interval: 1000
        running: true
        repeat: false
        onTriggered: _initialized = true
    }

    Component.onCompleted: {
        if (!service.mediaFocus) return;
        let players = Mpris.players.values;
        let active = players.find(p => p.playbackState === MprisPlaybackState.Playing && !isBlacklisted(p));
        if (active) {
            updateTrackedPlayer(active);
        } else if (players.length > 0) {
            trackedPlayer = players[0];
        }
    }
}
