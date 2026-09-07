#!/usr/bin/env bash
# Keyless translation via Google's clients5 dict-chrome-ex endpoint.
# Usage: translate.sh <src> <tgt> <text...>
#   <src> = language code, or "auto" for automatic detection
# Prints JSON: {"translatedText": "...", "detectedLang": "xx", "sourceText": "..."}
# On failure prints: {"error": "..."}
#
# Note: the old translate_a/single?client=gtx endpoint returns HTTP 429
# (abuse page); clients5.google.com with client=dict-chrome-ex still works.
# Response shape varies: [["text","lang"]] with sl=auto, ["chunk",...] otherwise.

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

RESP=$(curl -sf --max-time 8 \
  "https://clients5.google.com/translate_a/t?client=dict-chrome-ex&sl=${SRC}&tl=${TGT}&q=${ENCODED}" 2>/dev/null)

if [ -z "$RESP" ]; then
  echo '{"error":"Network request failed"}'
  exit 1
fi

echo "$RESP" | jq -r --arg src "$TEXT" '
  def emit($t; $l): { translatedText: $t, detectedLang: $l, sourceText: $src };
  if (.[0] | type) == "array"
  then ([.[] | .[0] // ""] | join("")) as $t
       | (.[0][1] // "") as $l
       | emit($t; $l)
  else (map(. // "") | join("")) as $t
       | emit($t; "")
  end' \
  || echo '{"error":"Could not parse translation response"}'
