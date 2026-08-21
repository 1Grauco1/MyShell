pragma ComponentBehavior: Bound
import QtQuick
import Quickshell
import Quickshell.Io
import "../Settings"

pragma Singleton

Item {
    id: service

    property string storagePath: PathSettings.stateDir + "/g_ant/productivity.json"

    // --- Reactive Properties (Source of Truth) ---
    property int duration: 0
    property int remaining: 0
    property bool running: false
    property bool isBeeping: false

    // --- Pomodoro State ---
    property string phase: "focus"      // "focus" | "shortBreak" | "longBreak"
    property int completedFocus: 0      // focus sessions completed in this cycle
    property int focusLength: 1500      // 25 min
    property int shortBreakLength: 300  // 5 min
    property int longBreakLength: 900   // 15 min
    property int breakEvery: 4          // long break after this many focus sessions
    property bool autoAdvance: false    // automatically start the next phase

    readonly property bool isBreak: phase !== "focus"

    signal refreshData()

    Component.onCompleted: load()

    function phaseDuration(p) {
        if (p === "focus") return service.focusLength;
        if (p === "shortBreak") return service.shortBreakLength;
        if (p === "longBreak") return service.longBreakLength;
        return 0;
    }

    function load() {
        loadProcess.running = true
    }

    function initData(parsed) {
        if (parsed) {
            if (parsed.timer) {
                duration = Math.max(0, parsed.timer.duration || 0);
                remaining = Math.max(0, parsed.timer.remaining || 0);
                running = (parsed.timer.running === true && remaining > 0);
            }
            if (parsed.pomodoro) {
                let p = parsed.pomodoro;
                phase = (p.phase === "shortBreak" || p.phase === "longBreak") ? p.phase : "focus";
                completedFocus = Math.max(0, p.completed || 0);
                focusLength = Math.max(60, p.focusLength || 1500);
                shortBreakLength = Math.max(60, p.shortBreakLength || 300);
                longBreakLength = Math.max(60, p.longBreakLength || 900);
                breakEvery = Math.max(2, p.breakEvery || 4);
                autoAdvance = (p.autoAdvance === true);
            }
            // If a phase is not currently configured, fill remaining with its duration
            if (duration <= 0 && phaseDuration(phase) > 0) {
                duration = phaseDuration(phase);
                if (remaining <= 0) remaining = duration;
            }
        }

        isBeeping = false;
        refreshData();
    }

    function save() {
        let data = {
            timer: {
                duration: duration,
                remaining: remaining,
                running: running
            },
            pomodoro: {
                phase: phase,
                completed: completedFocus,
                focusLength: focusLength,
                shortBreakLength: shortBreakLength,
                longBreakLength: longBreakLength,
                breakEvery: breakEvery,
                autoAdvance: autoAdvance
            }
        };

        saveProcess.command = ["python3", PathSettings.scriptsDir + "/write_file.py", storagePath, JSON.stringify(data)];
        saveProcess.running = true;
    }

    // --- Timer Actions ---
    function startPhase(p) {
        stopBeeping();
        phase = p;
        duration = phaseDuration(p);
        remaining = duration;
        running = true;
        save();
    }

    function toggleTimer() {
        if (isBeeping) {
            dismissAlarm();
            return;
        }
        if (duration <= 0) {
            startPhase(phase);
            return;
        }

        running = !running;
        if (remaining <= 0) remaining = duration;
        save();
    }

    function resetTimer() {
        running = false;
        stopBeeping();
        remaining = phaseDuration(phase);
        duration = remaining;
        save();
    }

    // Advance to the next logical phase (focus -> break, break -> focus) and start it.
    function skipPhase() {
        stopBeeping();
        if (phase === "focus") {
            let next = (completedFocus > 0 && completedFocus % breakEvery === 0) ? "longBreak" : "shortBreak";
            startPhase(next);
        } else {
            startPhase("focus");
        }
    }

    // Restart the full pomodoro cycle from scratch.
    function startPomodoro() {
        stopBeeping();
        phase = "focus";
        completedFocus = 0;
        duration = focusLength;
        remaining = focusLength;
        running = true;
        save();
    }

    // Reset the cycle counter and prepare a fresh focus session (idle).
    function resetCycle() {
        if (isBeeping) stopBeeping();
        running = false;
        phase = "focus";
        completedFocus = 0;
        duration = focusLength;
        remaining = focusLength;
        save();
    }

    function dismissAlarm() {
        stopBeeping();
        running = false;
        remaining = phaseDuration(phase);
        duration = remaining;
        save();
    }

    // --- Duration Configuration (only while idle) ---
    function setFocusLength(secs) {
        if (running || isBeeping) return;
        focusLength = Math.max(60, secs);
        if (phase === "focus") { duration = focusLength; remaining = focusLength; }
        save();
    }

    function setShortBreakLength(secs) {
        if (running || isBeeping) return;
        shortBreakLength = Math.max(60, secs);
        if (phase === "shortBreak") { duration = shortBreakLength; remaining = shortBreakLength; }
        save();
    }

    function setLongBreakLength(secs) {
        if (running || isBeeping) return;
        longBreakLength = Math.max(60, secs);
        if (phase === "longBreak") { duration = longBreakLength; remaining = longBreakLength; }
        save();
    }

    function setBreakEvery(n) {
        if (running || isBeeping) return;
        breakEvery = Math.max(2, n);
        save();
    }

    function setAutoAdvance(v) {
        autoAdvance = v;
        save();
    }

    // Called when a phase's countdown reaches zero.
    function onPhaseComplete() {
        if (phase === "focus") {
            completedFocus++;
            phase = (completedFocus % breakEvery === 0) ? "longBreak" : "shortBreak";
        } else {
            phase = "focus";
        }
        remaining = phaseDuration(phase);
        duration = remaining;
        if (autoAdvance) running = true;
        save();
    }

    function stopBeeping() {
        isBeeping = false;
        beepProcess.running = false;
        shellExec.command = ["pkill", "-f", "ffplay|mpv|paplay|pw-play|canberra-gtk-play"];
        shellExec.running = true;
    }

    // --- Background Countdown ---
    Timer {
        interval: 1000
        running: service.running
        repeat: true
        onTriggered: {
            if (service.running) {
                if (service.remaining > 0) {
                    service.remaining--;
                }
                if (service.remaining === 0) {
                    service.running = false;
                    service.isBeeping = true;
                    service.onPhaseComplete();
                }

                if (service.remaining % 10 === 0 || service.remaining === 0) {
                    service.save();
                }
            }
        }
    }

    // --- Sound Loop ---
    Timer {
        id: alarmLoop
        interval: 2000
        running: service.isBeeping
        repeat: true
        triggeredOnStart: true
        onTriggered: {
            beepProcess.running = false;
            beepProcess.running = true;
        }
    }

    // Priority sound player: ffplay -> mpv -> paplay -> pw-play / canberra
    Process {
        id: beepProcess
        command: ["sh", "-c",
            "SOUND_FILE='/run/current-system/sw/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga'; " +
            "[ ! -f \"$SOUND_FILE\" ] && SOUND_FILE='/usr/share/sounds/freedesktop/stereo/alarm-clock-elapsed.oga'; " +
            "ffplay -nodisp -autoexit \"$SOUND_FILE\" 2>/dev/null || " +
            "mpv --no-video --no-terminal \"$SOUND_FILE\" 2>/dev/null || " +
            "paplay \"$SOUND_FILE\" 2>/dev/null || " +
            "pw-play \"$SOUND_FILE\" 2>/dev/null || " +
            "canberra-gtk-play -i alarm-clock-elapsed 2>/dev/null"
        ]
    }
    Process { id: shellExec }

    Process {
        id: loadProcess;
        command: ["cat", service.storagePath];
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    let parsed = JSON.parse(text);
                    initData(parsed);
                } catch(e) {
                    initData(null);
                }
            }
        }
        onExited: (exitCode) => {
            if (exitCode !== 0) initData(null);
        }
    }
    Process { id: saveProcess }
}
