pragma ComponentBehavior: Bound
import ".."
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications
import "../windows" as Win

pragma Singleton

Item {
    id: root

    property alias notifications: historyModel

    signal notificationReceived(var notifData)
    signal notificationUpdated(var notifData)
    signal notificationDismissed(real id)
    signal osdReceived(string type, real value)

    function updateOSDValue(type, value) {
        let percent = Math.round(value * 100);
        if (type === "volume")
            shellExec.command = ["wpctl", "set-volume", "@DEFAULT_AUDIO_SINK@", percent + "%"];
        else if (type === "brightness")
            shellExec.command = ["brightnessctl", "set", percent + "%"];
        shellExec.running = false;
        shellExec.running = true;
    }

    function clearAll() {
        for (let i = 0; i < historyModel.count; i++) {
            let n = historyModel.get(i);
            if (!n) continue;
            if (Array.isArray(n.originalNotifs)) {
                for (let on of n.originalNotifs) {
                    if (on) on.dismiss();
                }
            } else if (n.originalNotif) {
                n.originalNotif.dismiss();
            }
        }
        historyModel.clear();
    }

    function removeNotification(notifId) {
        for (let i = 0; i < historyModel.count; i++) {
            if (historyModel.get(i).id === notifId) {
                let n = historyModel.get(i);
                if (Array.isArray(n.originalNotifs)) {
                    for (let on of n.originalNotifs) {
                        if (on) on.dismiss();
                    }
                } else if (n.originalNotif) {
                    n.originalNotif.dismiss();
                }
                historyModel.remove(i);
                break;
            }
        }
        root.notificationDismissed(notifId);
    }

    function dismissNotification(notifId) {
        root.notificationDismissed(notifId);
    }

    ListModel {
        id: historyModel
    }

    Process {
        id: shellExec
    }

    NotificationServer {
        id: server
        imageSupported: true

        onNotification: (notif) => {
            // OSD Filtering
            let syncHint = notif.hints["x-canonical-private-synchronous"] || "";
            let category = notif.hints["category"] || notif.category || "";
            
            if (syncHint === "volume" || syncHint === "brightness" || category === "volume" || category === "brightness") {
                let type = (syncHint === "volume" || category === "volume") ? "volume" : "brightness";
                let text = (notif.summary || "") + " " + (notif.body || "");
                let match = text.match(/(\d+)%/);
                let isMuted = text.toLowerCase().includes("muted") || text.toLowerCase().includes("mute");
                if (match || isMuted) {
                    let val = isMuted ? 0 : (parseInt(match[1]) / 100);
                    root.osdReceived(type, val);
                    notif.dismiss();
                    return;
                }
            }

            // Duplicate Filtering
            let isBattery = (notif.appName === "Battery");
            let isCaffeine = (notif.appName === "Caffeine");
            if (!isBattery && !isCaffeine) {
                for (let i = 0; i < historyModel.count; i++) {
                    let item = historyModel.get(i);
                    if (item.summary === notif.summary && item.body === notif.body && item.appName === notif.appName) {
                        notif.dismiss();
                        return;
                    }
                }
            }

            // Dynamic Icon Candidate Resolution via IconsFetcher
            let rawIcon = notif.appIcon || "";
            let rawImg = notif.image || "";
            let candidates = [];

            if (rawImg !== "") {
                candidates.push(rawImg.startsWith("file://") || rawImg.startsWith("/") ? (rawImg.startsWith("file://") ? rawImg : "file://" + rawImg) : rawImg);
            }

            let fetcherCandidates = Win.IconsFetcher.getIconCandidates(notif.appName || "", notif.desktopEntry || "", rawIcon);
            for (let cand of fetcherCandidates) {
                candidates.push(cand);
            }

            let validCandidates = candidates.filter((v, i, a) => v && v !== "" && a.indexOf(v) === i);

            let notifData = {
                "id": Date.now() * 1000 + Math.floor(Math.random() * 1000),
                "summary": notif.summary || "",
                "body": notif.body || "",
                "appIcon": validCandidates.length > 0 ? validCandidates[0] : "",
                "iconCandidates": validCandidates,
                "rawIcon": rawIcon,
                "appName": notif.appName || "System",
                "desktopEntry": notif.desktopEntry || "",
                "count": 1,
                "receivedAt": Date.now(),
                "originalNotifs": [notif],
                "originalNotif": notif
            };

            let merged = false;

            if (!isBattery && !isCaffeine) {
                // Single-app collapse: merge into the newest item from the same app
                // within the window, bumping its counter instead of stacking items.
                const window = 20000;
                if (historyModel.count > 0) {
                    let prev = historyModel.get(0);
                    if (prev && prev.appName === notifData.appName && Date.now() - (prev.receivedAt || 0) < window) {
                        prev.summary = notifData.summary;
                        prev.body = notifData.body;
                        prev.appIcon = notifData.appIcon;
                        prev.iconCandidates = notifData.iconCandidates;
                        prev.rawIcon = notifData.rawIcon;
                        prev.desktopEntry = notifData.desktopEntry;
                        prev.count = (prev.count || 1) + 1;
                        prev.receivedAt = notifData.receivedAt;
                        if (!Array.isArray(prev.originalNotifs)) prev.originalNotifs = [prev.originalNotif];
                        prev.originalNotifs.push(notif);
                        prev.originalNotif = notif;
                        historyModel.set(0, prev);
                        root.notificationUpdated(prev);
                        merged = true;
                    }
                }
                if (!merged) {
                    historyModel.insert(0, notifData);
                }
            }
            if (!merged) {
                root.notificationReceived(notifData);
            }
        }
    }
}