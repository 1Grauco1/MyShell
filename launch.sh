#!/usr/bin/env bash
# G_ant Shell (Quickshell) Launcher & IPC CLI

SHELL_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
export G_ANT_ROOT="$SHELL_DIR"
export QML_IMPORT_PATH="$SHELL_DIR"
export QML2_IMPORT_PATH="$SHELL_DIR"

COMBO_FILE="$HOME/.cache/g_ant_last_combo"

mark_combo() {
    date +%s%3N > "$COMBO_FILE" 2>/dev/null || true
}

is_recent_combo() {
    if [ -f "$COMBO_FILE" ]; then
        local last_time
        last_time=$(cat "$COMBO_FILE" 2>/dev/null || echo 0)
        local now
        now=$(date +%s%3N 2>/dev/null || echo 0)
        local diff=$((now - last_time))
        if [ "$diff" -ge 0 ] && [ "$diff" -lt 550 ]; then
            return 0
        fi
    fi
    return 1
}

is_running() {
    pgrep -x "quickshell" >/dev/null 2>&1 || pgrep -x ".quickshell-wra" >/dev/null 2>&1
}

send_cmd() {
    local cmd="$1"
    if [ "$cmd" != "launcher" ]; then
        "$SHELL_DIR/scripts/super_launcher.sh" mark_combo 2>/dev/null || true
        mark_combo
    fi
    if ! is_running; then
        echo "Starting Quickshell..."
        quickshell -d -p "$SHELL_DIR" &
        sleep 0.6
    fi
    quickshell ipc -p "$SHELL_DIR" call g_ant:menu toggle "$cmd" 2>/dev/null || \
        quickshell ipc call g_ant:menu toggle "$cmd"
}


show_usage() {
    echo "G_ant Shell CLI & IPC Launch Script"
    echo ""
    echo "Usage: $0 [command/action]"
    echo ""
    echo "Actions:"
    echo "  launcher | applauncher     Toggle App Launcher"
    echo "  clipboard | clip | cliphist Toggle Clipboard Manager"
    echo "  emoji | emojis             Toggle Emoji Selector"
    echo "  dashboard | overview      Toggle Dashboard"
    echo "  wallpaper                 Toggle Wallpaper tab"
    echo "  pomodoro                  Toggle Pomodoro tab"
    echo "  translate                 Toggle Translate tab"
    echo "  wifi | network            Toggle Wi-Fi QuickSettings"
    echo "  bluetooth | bt            Toggle Bluetooth QuickSettings"
    echo "  volume | audio            Toggle Volume QuickSettings"
    echo "  powerprofile | prof       Toggle Power Profile QuickSettings"
    echo "  battery | pwr             Toggle Battery QuickSettings"
    echo "  power | sys               Toggle Power Menu"
    echo "  close | close_all         Close all active menus"
    echo "  media                     Toggle Media Player Popup"
    echo "  media-next                Next Track"
    echo "  media-prev                Previous Track"
    echo "  settings                  Toggle Settings Window"
    echo "  setconfig <key>=<value>   Set a setting at runtime (e.g. bar.height=36)"
    echo "  logs                      Show quickshell log output"
    echo "  watch                     Restart shell on config changes (needs inotifywait)"
    echo "  restart | reload          Restart Quickshell"
    echo "  stop                      Stop Quickshell"
    echo ""
}

case "$1" in
    start)
        if ! is_running; then
            echo "Starting Quickshell..."
            quickshell -d -p "$SHELL_DIR" &
        else
            echo "Quickshell is already running."
        fi
        ;;
    stop)
        echo "Stopping Quickshell..."
        pkill -x quickshell
        pkill -x .quickshell-wra
        ;;
    restart|reload)
        echo "Restarting Quickshell..."
        pkill -x quickshell
        pkill -x .quickshell-wra
        sleep 0.3
        quickshell -d -p "$SHELL_DIR" &
        ;;
    launcher|applauncher|Launcher)
        if is_recent_combo; then
            exit 0
        fi
        send_cmd "launcher"
        ;;
    mark_combo|combo)
        mark_combo
        ;;

    clipboard|clip|cliphist|Clipboard)
        send_cmd "clipboard"
        ;;
    emoji|emojis|emojiselector|Emoji)
        send_cmd "emoji"
        ;;
    pomodoro)
        send_cmd "pomodoro"
        ;;
    wifi|network)
        send_cmd "wifi"
        ;;
    bluetooth|bt)
        send_cmd "bluetooth"
        ;;
    volume|audio)
        send_cmd "volume"
        ;;
    powerprofile|prof)
        send_cmd "powerprofile"
        ;;
    battery|pwr)
        send_cmd "battery"
        ;;
    power|sys)
        send_cmd "power"
        ;;
    close|close_all)
        send_cmd "close_all"
        ;;
    media)
        send_cmd "media"
        ;;
    media-next)
        send_cmd "media-next"
        ;;
    media-prev)
        send_cmd "media-prev"
        ;;
    settings)
        send_cmd "settings"
        ;;
    logs)
        quickshell log "$@" 2>&1
        ;;
    watch)
        if ! command -v inotifywait >/dev/null 2>&1; then
            echo "watch requires 'inotifywait' (install inotify-tools), or use: $0 restart"
            exit 1
        fi
        echo "Watching $SHELL_DIR for changes... (Ctrl+C to stop)"
        quickshell -d -p "$SHELL_DIR" &
        while true; do
            inotifywait -q -r -e modify -e create -e delete \
                --exclude '\.git|settings\.json' "$SHELL_DIR" >/dev/null 2>&1
            echo "Change detected, restarting..."
            pkill -x quickshell
            pkill -x .quickshell-wra
            sleep 0.3
            quickshell -d -p "$SHELL_DIR" &
        done
        ;;
    "")
        show_usage
        ;;
    *)
        # Fallback: send arg directly as IPC command
        send_cmd "$1"
        ;;
esac
