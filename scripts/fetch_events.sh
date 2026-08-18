#!/usr/bin/env bash
# Official National & Major Religious Holiday Fetcher Script for G_ant Shell Calendar Widget

YEAR=${1:-$(date +%Y)}
COUNTRY=${2:-""}

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# If country is not passed as argument, auto-detect using detect_env.sh or fallback
if [ -z "$COUNTRY" ]; then
    if [ -x "$SCRIPT_DIR/detect_env.sh" ]; then
        COUNTRY="$("$SCRIPT_DIR/detect_env.sh" | jq -r '.countryCode' 2>/dev/null)"
    fi
fi
COUNTRY="${COUNTRY:-PK}"

STATE_DIR="${XDG_STATE_HOME:-$HOME/.local/state}"
JSON_FILE="$STATE_DIR/g_ant/events.json"
mkdir -p "$STATE_DIR/g_ant"
CACHE_DIR="${XDG_CACHE_HOME:-$HOME/.cache}/g_ant_events"
mkdir -p "$CACHE_DIR"
CACHE_FILE="$CACHE_DIR/events_${YEAR}_${COUNTRY}.json"
MAX_AGE=86400 # 24 hours; holidays rarely change within a day

fetch_events() {
    TMP_DIR=$(mktemp -d)

    # 1. Fetch Official Public Holidays from Nager.Date API
    curl -sL --connect-timeout 3 "https://date.nager.at/api/v3/PublicHolidays/$YEAR/$COUNTRY" 2>/dev/null | jq -c '.[]? | select(.types | contains(["Public"])) | {date: .date, name: .name, localName: .localName, type: "national"}' > "$TMP_DIR/nager.json" &

    # 2. Fetch Major Official Religious Holidays from Aladhan API (filter ONLY major official ones)
    MAJOR_RELIGIOUS_REGEX="Eid-ul-Fitr|Eid-ul-Adha|Ashura|Mawlid|Ramadan|Arafa|Good Friday|Christmas|Easter|Diwali"

    for m in $(seq -w 1 12); do
        (
            curl -sL --connect-timeout 2 "https://api.aladhan.com/v1/gToHCalendar/$m/$YEAR" 2>/dev/null | jq -c --arg regex "$MAJOR_RELIGIOUS_REGEX" '.data[]? | select(.hijri.holidays | length > 0) | .hijri.holidays[] as $h | select($h | test($regex; "i")) | {date: (.gregorian.date | split("-") | reverse | join("-")), name: $h, localName: $h, type: "religious"}' > "$TMP_DIR/month_$m.json"
        ) &
    done

    wait

    # If Nager.Date API returned empty for this country (e.g. PK), add official country fallback holidays
    if [ ! -s "$TMP_DIR/nager.json" ] || [ $(wc -l < "$TMP_DIR/nager.json") -eq 0 ]; then
        if [ "$COUNTRY" == "PK" ]; then
            {
                echo "{\"date\":\"$YEAR-02-05\",\"name\":\"Kashmir Day\",\"localName\":\"Kashmir Day\",\"type\":\"national\"}"
                echo "{\"date\":\"$YEAR-03-23\",\"name\":\"Pakistan Day\",\"localName\":\"Pakistan Day\",\"type\":\"national\"}"
                echo "{\"date\":\"$YEAR-05-01\",\"name\":\"Labour Day\",\"localName\":\"Labour Day\",\"type\":\"national\"}"
                echo "{\"date\":\"$YEAR-08-14\",\"name\":\"Independence Day\",\"localName\":\"Independence Day\",\"type\":\"national\"}"
                echo "{\"date\":\"$YEAR-11-09\",\"name\":\"Iqbal Day\",\"localName\":\"Iqbal Day\",\"type\":\"national\"}"
                echo "{\"date\":\"$YEAR-12-25\",\"name\":\"Quaid-e-Azam Day\",\"localName\":\"Quaid-e-Azam Day\",\"type\":\"national\"}"
            } > "$TMP_DIR/fallback.json"
        fi
    fi

    # Combine and deduplicate (write atomically)
    if ls "$TMP_DIR"/*.json >/dev/null 2>&1; then
        cat "$TMP_DIR"/*.json | jq -s 'unique_by(.date + .name) | sort_by(.date)' > "$CACHE_FILE.tmp"
    else
        echo "[]" > "$CACHE_FILE.tmp"
    fi

    rm -rf "$TMP_DIR"
    mv "$CACHE_FILE.tmp" "$CACHE_FILE"
}

# Serialize concurrent fetchers; reuse stale cache if another fetch is in progress
if command -v flock >/dev/null 2>&1; then
    exec 9>"$CACHE_FILE.lock"
    if ! flock -w 30 9; then
        [ -f "$CACHE_FILE" ] || echo "[]" > "$CACHE_FILE"
        cp "$CACHE_FILE" "$JSON_FILE.tmp" 2>/dev/null && mv "$JSON_FILE.tmp" "$JSON_FILE" 2>/dev/null
        exit 0
    fi
fi

# Cache logic
if [ -f "$CACHE_FILE" ]; then
    current_time=$(date +%s)
    file_time=$(date +%s -r "$CACHE_FILE" 2>/dev/null || echo 0)
    age=$((current_time - file_time))
    if [ $age -gt $MAX_AGE ]; then
        fetch_events
    fi
else
    fetch_events
fi

# Sync the per-year cache to the fixed location QML reads from
cp "$CACHE_FILE" "$JSON_FILE.tmp" && mv "$JSON_FILE.tmp" "$JSON_FILE"
