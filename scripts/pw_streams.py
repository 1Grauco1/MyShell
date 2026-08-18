#!/usr/bin/env python3
import json, subprocess

result = {"outputVolume": 0, "muted": False, "micVolume": 0, "micMuted": False, "micActive": False, "btActive": False}

try:
    out = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SINK@"], text=True, stderr=subprocess.DEVNULL)
    result["muted"] = "[MUTED]" in out
    import re
    m = re.search(r"([0-9]+\.?[0-9]*)", out)
    if m:
        result["outputVolume"] = round(float(m.group(1)) * 100)
except Exception:
    pass

try:
    out = subprocess.check_output(["wpctl", "get-volume", "@DEFAULT_AUDIO_SOURCE@"], text=True, stderr=subprocess.DEVNULL)
    result["micMuted"] = "[MUTED]" in out
    import re
    m = re.search(r"([0-9]+\.?[0-9]*)", out)
    if m:
        result["micVolume"] = round(float(m.group(1)) * 100)
except Exception:
    pass

try:
    insp = subprocess.check_output(["wpctl", "inspect", "@DEFAULT_AUDIO_SINK@"], text=True, stderr=subprocess.DEVNULL)
    result["btActive"] = "bluez" in insp.lower()
except Exception:
    pass

try:
    dump = json.loads(subprocess.check_output(["pw-dump"], stderr=subprocess.DEVNULL))
    result["micActive"] = any(
        obj.get("type") == "PipeWire:Interface:Node" and
        obj.get("info", {}).get("props", {}).get("media.class") == "Stream/Input/Audio"
        for obj in dump
    )
    result["streamActive"] = any(
        obj.get("type") == "PipeWire:Interface:Node" and
        obj.get("info", {}).get("props", {}).get("media.class") == "Stream/Output/Audio"
        for obj in dump
    )
except Exception:
    pass

print(json.dumps(result))
