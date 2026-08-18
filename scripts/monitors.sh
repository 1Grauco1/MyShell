#!/usr/bin/env bash
# Monitor resolution helper for G_ant Shell.
#   monitors.sh list
#   monitors.sh apply <name> <WxH[@RR]>
#   monitors.sh apply-saved

ACTION="${1:-list}"
NAME="$2"
RES="$3"

SETTINGS_FILE="${G_ANT_ROOT:-$HOME/.config/quickshell}/settings.json"

apply_resolution() {
    local mon_name="$1"
    local mon_res="$2"
    local pos="auto"
    local scale="1"

    if command -v hyprctl >/dev/null 2>&1; then
        local cur
        cur=$(hyprctl monitors -j 2>/dev/null)
        if [ -n "$cur" ]; then
            local parsed_pos parsed_scale
            parsed_pos=$(echo "$cur" | jq -r --arg n "$mon_name" '.[] | select(.name==$n) | "\(.x),\(.y)"' 2>/dev/null)
            parsed_scale=$(echo "$cur" | jq -r --arg n "$mon_name" '.[] | select(.name==$n) | .scale' 2>/dev/null)
            [ "$parsed_pos" = "null" ] || [ -z "$parsed_pos" ] || pos="$parsed_pos"
            [ "$parsed_scale" = "null" ] || [ -z "$parsed_scale" ] || scale="$parsed_scale"
        fi
        hyprctl keyword monitor "$mon_name,$mon_res,$pos,$scale" >/dev/null 2>&1
    fi
}

case "$ACTION" in
    list)
        if command -v hyprctl >/dev/null 2>&1; then
            hyprctl monitors -j 2>/dev/null | jq '[.[] | {
                name: .name,
                description: .description,
                width: .width,
                height: .height,
                refreshRate: (.refreshRate | round),
                x: .x,
                y: .y,
                scale: .scale,
                focused: .focused
            }]'
        else
            echo "[]"
        fi
        ;;
    apply)
        if [ -z "$NAME" ] || [ -z "$RES" ]; then
            echo "usage: monitors.sh apply <name> <WxH[@RR]>" >&2
            exit 1
        fi
        apply_resolution "$NAME" "$RES"
        ;;
    apply-saved)
        [ -f "$SETTINGS_FILE" ] || exit 0
        jq -r 'to_entries[] |
            select(.key | startswith("monitor.")) |
            select(.key | endswith(".resolution")) |
            "\(.key)=\(.value)"' "$SETTINGS_FILE" | while IFS= read -r line; do
            key="${line%%=*}"
            value="${line#*=}"
            mon_name="${key#monitor.}"
            mon_name="${mon_name%.resolution}"
            if [ -n "$value" ] && [ "$value" != "Native" ] && [ "$value" != "auto" ]; then
                apply_resolution "$mon_name" "$value"
            fi
        done
        ;;
    *)
        echo "unknown action: $ACTION" >&2
        exit 1
        ;;
esac
