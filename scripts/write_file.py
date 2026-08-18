#!/usr/bin/env python3
"""Atomic file writer for g_ant-shell QML services.

Usage: write_file.py <path> <payload>

Writes payload to <path> via a temporary file + os.replace so partial
writes are never observable. Replaces the various inline `python3 -c`
one-liners previously embedded in QML.
"""
import os
import sys


def main() -> int:
    if len(sys.argv) != 3:
        print("usage: write_file.py <path> <payload>", file=sys.stderr)
        return 1
    path, payload = sys.argv[1], sys.argv[2]
    try:
        os.makedirs(os.path.dirname(path) or ".", exist_ok=True)
        tmp = path + ".tmp"
        with open(tmp, "w") as f:
            f.write(payload)
        os.replace(tmp, path)
    except OSError as e:
        print(f"write_file.py: {e}", file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
