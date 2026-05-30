#!/usr/bin/env bash

set -e

if [ -t 0 ]; then
  echo "No input provided (pipe JSON into this script)"
  exit 1
fi

python3 - << 'PY'
import json, sys, os

data = json.load(sys.stdin)
if isinstance(data, dict):
    data = [data]

def norm_lines(s):
    return [l.rstrip() for l in s.replace("\r\n", "\n").strip("\n").split("\n")]

def match_block(lines, pattern):
    n = len(pattern)
    for i in range(len(lines) - n + 1):
        if lines[i:i+n] == pattern:
            return i
    return -1

def apply_patch(p):
    file = p.get("file")
    find = p.get("find", "").replace("\r\n", "\n")
    replace = p.get("replace", "").replace("\r\n", "\n")

    if not file or not os.path.exists(file):
        print(f"MISS {file}")
        return

    with open(file, "r", encoding="utf-8") as f:
        content = f.read().replace("\r\n", "\n")

    lines = [l.rstrip() for l in content.split("\n")]
    find_lines = norm_lines(find)
    replace_lines = replace.strip("\n").split("\n")

    idx = match_block(lines, find_lines)

    if idx == -1:
        print(f"NO_MATCH {file}")
        return

    new_lines = lines[:idx] + replace_lines + lines[idx+len(find_lines):]

    with open(file, "w", encoding="utf-8") as f:
        f.write("\n".join(new_lines) + "\n")

    print(f"PATCHED {file}")

for p in data:
    apply_patch(p)
PY
