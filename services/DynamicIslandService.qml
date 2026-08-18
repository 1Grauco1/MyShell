import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"
import "./"

pragma Singleton

QtObject {
    id: root

    property string activeMode: "" // "", "launcher", "clipboard", "emoji"
    readonly property bool active: activeMode !== ""
    property string query: ""
    property int selectedIndex: 0
    property string selectedCategory: "All"

    // --- LAUNCHER DATA ---
    property string storagePath: (Quickshell.env("XDG_STATE_HOME") || (Quickshell.env("HOME") + "/.local/state")) + "/g_ant/app_usage.json"
    property var usageMap: ({})
    property var allAppsCache: []
    property var displayedApps: []

    // --- CLIPBOARD DATA ---
    property var rawClipHistory: []
    property var displayedClips: []

    // --- EMOJI DATA ---
    property var allEmojisCache: []
    property var displayedEmojis: []
    readonly property string jsonPath: (Quickshell.env("G_ANT_ROOT") || (Quickshell.env("HOME") + "/.config/quickshell")) + "/assets/emojis.json"
    readonly property var emojiCategories: ["All", "Smileys", "People", "Animals", "Food", "Activities", "Travel", "Objects", "Symbols", "Flags"]

    // --- HELPER PROCESSES ---
    property var execProc: Process { id: execProc }
    property var clipProc: Process { id: clipProc }
    property var emojiProc: Process { id: emojiProc }

    // Desktop entries connection
    property var appConn: Connections {
        target: DesktopEntries.applications
        function onValuesChanged() { root.rebuildAppCache(); }
        function onRowsInserted() { root.rebuildAppCache(); }
        function onModelReset() { root.rebuildAppCache(); }
    }

    // App usage loader
    property var loadUsageProc: Process {
        id: loadUsage
        command: ["cat", root.storagePath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.usageMap = JSON.parse(text) || {};
                } catch(e) {
                    root.usageMap = {};
                }
                if (root.activeMode === "launcher") root.rebuildFiltered();
            }
        }
        onExited: (code) => {
            if (code !== 0 && root.activeMode === "launcher") root.rebuildFiltered();
        }
    }

    // App usage saver
    property var saveUsageProc: Process { id: saveUsage }

    // Cliphist loader
    property var loadClipProc: Process {
        id: loadClip
        command: ["sh", "-c", "cliphist list"]
        stdout: StdioCollector {
            onStreamFinished: {
                root.parseCliphistOutput(text);
            }
        }
    }

    // Emoji loader
    property var loadEmojiProc: Process {
        id: loadEmoji
        command: ["cat", root.jsonPath]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(text) || [];
                    root.buildEmojiCache(parsed);
                } catch(e) {
                    root.allEmojisCache = [];
                    root.rebuildFiltered();
                }
            }
        }
    }

    property var diStartupTimer: Timer {
        id: diStartupTimer
        interval: 300
        running: true
        repeat: false
        onTriggered: loadUsage.running = true
    }

    Component.onCompleted: {
        rebuildAppCache();
    }

    // --- CONTROLS ---

    function open(mode) {
        let validMode = mode || "launcher";
        if (validMode !== "launcher" && validMode !== "clipboard" && validMode !== "emoji") {
            validMode = "launcher";
        }
        
        CenterState.close();
        QuickSettingsService.close();

        query = "";
        selectedIndex = 0;
        selectedCategory = "All";
        activeMode = validMode;

        if (validMode === "launcher") {
            if (allAppsCache.length === 0) rebuildAppCache();
            else rebuildFiltered();
        } else if (validMode === "clipboard") {
            loadClipHistory();
        } else if (validMode === "emoji") {
            if (allEmojisCache.length === 0) {
                loadEmoji.running = false;
                loadEmoji.running = true;
            } else {
                rebuildFiltered();
            }
        }
    }

    function close() {
        activeMode = "";
        query = "";
        selectedIndex = 0;
    }

    function toggle(mode) {
        if (activeMode === mode || (mode === "" && active)) {
            close();
        } else {
            open(mode);
        }
    }

    function setMode(mode) {
        if (activeMode === mode) return;
        query = "";
        selectedIndex = 0;
        activeMode = mode;
        if (mode === "clipboard" && rawClipHistory.length === 0) {
            loadClipHistory();
        } else if (mode === "emoji" && allEmojisCache.length === 0) {
            loadEmoji.running = false;
            loadEmoji.running = true;
        } else {
            rebuildFiltered();
        }
    }

    function cycleMode() {
        if (activeMode === "launcher") setMode("clipboard");
        else if (activeMode === "clipboard") setMode("emoji");
        else setMode("launcher");
    }

    function setCategory(cat) {
        selectedCategory = cat;
        selectedIndex = 0;
        rebuildFiltered();
    }

    // --- REBUILD FILTERED RESULTS ---

    function rebuildFiltered() {
        selectedIndex = 0;
        if (activeMode === "launcher") rebuildLauncherFiltered();
        else if (activeMode === "clipboard") rebuildClipboardFiltered();
        else if (activeMode === "emoji") rebuildEmojiFiltered();
    }

    // --- LAUNCHER LOGIC ---

    function rebuildAppCache() {
        let rawApps = DesktopEntries.applications.values || [];
        let cache = [];

        for (let i = 0; i < rawApps.length; i++) {
            let entry = rawApps[i];
            if (!entry || !entry.name || entry.noDisplay) continue;

            let name = entry.name || "";
            let appId = entry.id || "";
            let genericName = entry.genericName || "";
            let comment = entry.comment || "";
            let categories = entry.categories || "";

            cache.push({
                entry: entry,
                id: appId,
                idLower: appId.toLowerCase(),
                name: name,
                nameLower: name.toLowerCase(),
                icon: entry.icon || "",
                genericName: genericName,
                comment: comment,
                searchKey: (name + " " + appId + " " + genericName + " " + comment + " " + categories).toLowerCase()
            });
        }

        allAppsCache = cache;
        if (activeMode === "launcher") rebuildLauncherFiltered();
    }

    function tokenizeMath(str) {
        let tokens = [];
        let i = 0;
        while (i < str.length) {
            let ch = str[i];
            if (/\s/.test(ch)) { i++; continue; }
            if (/[0-9.]/.test(ch)) {
                let j = i;
                while (j < str.length && /[0-9.]/.test(str[j])) j++;
                let raw = str.slice(i, j);
                if (!/^\d*\.?\d+$/.test(raw)) return null;
                tokens.push({ type: "num", value: parseFloat(raw) });
                i = j;
                continue;
            }
            if ("+-*/%^".indexOf(ch) !== -1) { tokens.push({ type: "op", value: ch }); i++; continue; }
            if (ch === "(") { tokens.push({ type: "lparen" }); i++; continue; }
            if (ch === ")") { tokens.push({ type: "rparen" }); i++; continue; }
            return null;
        }
        return tokens;
    }

    function parseMath(tokens) {
        let pos = 0;
        function peek() { return tokens[pos]; }

        function parsePrimary() {
            let t = peek();
            if (!t) return NaN;
            if (t.type === "num") { pos++; return t.value; }
            if (t.type === "lparen") {
                pos++;
                let v = parseExpr();
                if (peek() && peek().type === "rparen") { pos++; return v; }
                return NaN;
            }
            if (t.type === "op" && (t.value === "+" || t.value === "-")) {
                pos++;
                let v = parsePrimary();
                return t.value === "-" ? -v : v;
            }
            return NaN;
        }

        function parsePow() {
            let left = parsePrimary();
            let t = peek();
            if (t && t.type === "op" && t.value === "^") {
                pos++;
                return Math.pow(left, parsePow());
            }
            return left;
        }

        function parseMul() {
            let left = parsePow();
            while (true) {
                let t = peek();
                if (t && t.type === "op" && (t.value === "*" || t.value === "/" || t.value === "%")) {
                    pos++;
                    let right = parsePow();
                    if (t.value === "*") left = left * right;
                    else if (t.value === "/") left = right === 0 ? Infinity : left / right;
                    else left = left % right;
                } else break;
            }
            return left;
        }

        function parseExpr() {
            let left = parseMul();
            while (true) {
                let t = peek();
                if (t && t.type === "op" && (t.value === "+" || t.value === "-")) {
                    pos++;
                    let right = parseMul();
                    left = t.value === "+" ? left + right : left - right;
                } else break;
            }
            return left;
        }

        let result = parseExpr();
        if (pos !== tokens.length) return NaN;
        return result;
    }

    function evalMath(expr) {
        try {
            let clean = expr.trim();
            if (!/^[\d\s\+\-\*\/\%\(\)\.\^]+$/.test(clean)) return null;
            if (!/[\+\-\*\/\%\^]/.test(clean)) return null;

            let tokens = tokenizeMath(clean);
            if (!tokens) return null;

            let val = parseMath(tokens);
            if (typeof val !== "number" || !isFinite(val)) return null;
            let formatted = Number.isInteger(val) ? val.toString() : val.toFixed(4).replace(/\.?0+$/, '');
            return formatted;
        } catch(e) {}
        return null;
    }

    function rebuildLauncherFiltered() {
        let q = query.toLowerCase().trim();

        if (q === "") {
            displayedApps = [];
            return;
        }

        let results = [];

        // Math calculation
        let mathRes = evalMath(query);
        if (mathRes !== null) {
            results.push({
                isMath: true,
                result: mathRes,
                name: query.trim() + " = " + mathRes,
                genericName: "Calculation Result (Press Enter to copy)",
                icon: "calculator",
                id: "math_calc",
                score: 100000
            });
        }

        // Filter pre-indexed apps
        for (let i = 0; i < allAppsCache.length; i++) {
            let app = allAppsCache[i];
            let nameLower = app.nameLower;
            let idLower = app.idLower;

            if (app.searchKey.includes(q)) {
                let usage = usageMap[app.id] || 0;
                let score = usage * 1000;

                if (nameLower === q) score += 5000;
                else if (nameLower.startsWith(q)) score += 2000;
                else if (nameLower.includes(q)) score += 1000;
                else if (idLower.includes(q)) score += 500;

                results.push({
                    isMath: false,
                    entry: app.entry,
                    id: app.id,
                    name: app.name,
                    nameLower: nameLower,
                    icon: app.icon,
                    genericName: app.genericName,
                    comment: app.comment,
                    score: score
                });
            }
        }

        results.sort((a, b) => {
            if (b.score !== a.score) return b.score - a.score;
            let an = a.nameLower;
            let bn = b.nameLower;
            return an < bn ? -1 : (an > bn ? 1 : 0);
        });

        displayedApps = results.slice(0, 4);
    }

    function saveAppUsage() {
        saveUsage.command = [
            "python3", PathSettings.scriptsDir + "/write_file.py",
            storagePath,
            JSON.stringify(usageMap)
        ];
        saveUsage.running = true;
    }

    function recordAppUsage(appId) {
        if (!appId) return;
        let count = usageMap[appId] || 0;
        usageMap[appId] = count + 1;
        saveAppUsage();
    }

    function launchApp(appItem) {
        if (!appItem) return;
        
        if (appItem.isMath) {
            execProc.command = ["sh", "-c", "printf '%s' \"$1\" | wl-copy 2>/dev/null || true", "--", appItem.result];
            execProc.running = true;
            close();
            return;
        }

        if (appItem.entry) {
            recordAppUsage(appItem.id);
            appItem.entry.execute();
            close();
        }
    }

    // --- CLIPBOARD LOGIC ---

    function loadClipHistory() {
        loadClip.running = false;
        loadClip.running = true;
    }

    function parseCliphistOutput(text) {
        if (!text) {
            rawClipHistory = [];
            rebuildClipboardFiltered();
            return;
        }

        let lines = text.split("\n");
        let items = [];

        for (let i = 0; i < lines.length; i++) {
            let line = lines[i];
            if (!line.trim()) continue;

            let tabIdx = line.indexOf("\t");
            if (tabIdx !== -1) {
                let clipId = line.substring(0, tabIdx).trim();
                let clipText = line.substring(tabIdx + 1);

                items.push({
                    id: clipId,
                    preview: clipText,
                    searchKey: clipText.toLowerCase()
                });
            }
        }

        rawClipHistory = items;
        rebuildClipboardFiltered();
    }

    function rebuildClipboardFiltered() {
        let q = query.toLowerCase().trim();

        if (q === "") {
            displayedClips = rawClipHistory.slice(0, 15);
            return;
        }

        let results = [];
        for (let i = 0; i < rawClipHistory.length; i++) {
            let item = rawClipHistory[i];
            if (item.searchKey.includes(q)) {
                results.push(item);
            }
        }

        displayedClips = results.slice(0, 15);
    }

    function copyClipItem(clipItem) {
        if (!clipItem || !clipItem.id) return;
        clipProc.command = ["sh", "-c", "cliphist decode \"$1\" | wl-copy", "--", clipItem.id];
        clipProc.running = true;
        close();
    }

    function deleteClipItem(clipItem) {
        if (!clipItem || !clipItem.id) return;
        clipProc.command = ["sh", "-c", "python3 -c 'import sys; print(sys.argv[1] + chr(9) + sys.argv[2], end=\"\")' \"$1\" \"$2\" | cliphist delete", "--", clipItem.id, clipItem.preview];
        clipProc.running = true;
        loadClipHistory();
    }

    // --- EMOJI LOGIC ---

    function buildEmojiCache(rawList) {
        let cache = [];
        for (let i = 0; i < rawList.length; i++) {
            let item = rawList[i];
            if (!item) continue;
            let emojiChar = item.char || item.emoji || "";
            if (!emojiChar) continue;
            let name = item.name || "";
            let category = item.cat || item.category || "All";
            let keywords = Array.isArray(item.tags || item.keywords) ? (item.tags || item.keywords).join(" ") : (item.tags || item.keywords || "");

            cache.push({
                emoji: emojiChar,
                name: name,
                category: category,
                keywords: keywords,
                searchKey: (name + " " + category + " " + keywords).toLowerCase()
            });
        }
        allEmojisCache = cache;
        rebuildEmojiFiltered();
    }

    function rebuildEmojiFiltered() {
        let q = query.toLowerCase().trim();
        let cat = selectedCategory;

        let results = [];
        for (let i = 0; i < allEmojisCache.length; i++) {
            let item = allEmojisCache[i];
            
            if (cat !== "All" && item.category !== cat) continue;

            if (q === "" || item.searchKey.includes(q)) {
                results.push(item);
            }
        }

        displayedEmojis = results.slice(0, 120);
    }

    function copyEmoji(emojiChar) {
        if (!emojiChar) return;
        emojiProc.command = ["sh", "-c", "printf '%s' \"$1\" | wl-copy", "--", emojiChar];
        emojiProc.running = true;
        close();
    }
}

