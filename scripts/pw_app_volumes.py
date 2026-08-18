#!/usr/bin/env python3
import json, sys

try:
    data = json.load(sys.stdin)
    result = []
    for obj in data:
        if obj.get("type") == "PipeWire:Interface:Node":
            props = obj.get("info", {}).get("props", {})
            if props.get("media.class") == "Stream/Output/Audio":
                name = props.get("application.name") or props.get("media.name") or "App"
                vol_pct = 100
                muted = False
                params = obj.get("info", {}).get("params", {})
                for p in params.get("Props", []):
                    if "channelVolumes" in p:
                        vols = p["channelVolumes"]
                        if vols:
                            vol_pct = int(round(max(vols) * 100))
                    if "mute" in p:
                        muted = bool(p["mute"])
                result.append({
                    "index": obj["id"],
                    "properties": {"application.name": name},
                    "volume": {"front-left": {"value_percent": str(vol_pct) + "%"}},
                    "mute": muted
                })
    print(json.dumps(result))
except Exception:
    print("[]")
