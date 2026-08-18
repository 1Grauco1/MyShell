#!/usr/bin/env bash
# Keyless translation via Google's unofficial translate endpoint.
# Usage: translate.sh <src> <tgt> <text...>
#   <src> = language code, or "auto" for automatic detection
# Prints JSON: {"translatedText": "...", "detectedLang": "xx", "sourceText": "..."}
# On failure prints: {"error": "..."}

set -o pipefail

SRC="${1:-auto}"
TGT="${2:-en}"
shift 2
TEXT="$*"

if [ -z "$TEXT" ]; then
  echo '{"translatedText":"","detectedLang":"","sourceText":""}'
  exit 0
fi

ENCODED=$(printf '%s' "$TEXT" | jq -sRr @uri)

RESP=$(curl -s --max-time 8 \
  "https://translate.googleapis.com/translate_a/single?client=gtx&dt=t&sl=${SRC}&tl=${TGT}&q=${ENCODED}" 2>/dev/null)

if [ -z "$RESP" ]; then
  echo '{"error":"Network request failed"}'
  exit 1
fi

echo "$RESP" | jq -r --arg src "$TEXT" '
  ([ .[0][]? | .[0] // "" ] | join("")) as $t
  | { translatedText: $t, detectedLang: (.[2] // ""), sourceText: $src }' \
  || echo '{"error":"Could not parse translation response"}'
