#!/usr/bin/env bash
set -euo pipefail

PATCH_FILE="patch.json"

if [ ! -f "$PATCH_FILE" ]; then
  echo "patch.json not found"
  exit 1
fi

python3 - << 'PY'
import json, os, difflib, sys

PATCH_FILE = "patch.json"

RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
RESET = "\033[0m"


def norm_lines(s: str):
    return [l.rstrip() for l in s.replace("\r\n", "\n").strip("\n").split("\n")]


def match_block(lines, pattern):
    n = len(pattern)
    for i in range(len(lines) - n + 1):
        if lines[i:i+n] == pattern:
            return i
    return -1


def show_diff(old, new, file):
    diff = difflib.unified_diff(
        old,
        new,
        fromfile=f"a/{file}",
        tofile=f"b/{file}",
        lineterm="",
        n=3
    )

    for line in diff:
        if line.startswith("---") or line.startswith("+++"):
            print(YELLOW + line + RESET)
        elif line.startswith("@@"):
            print(YELLOW + line + RESET)
        elif line.startswith("-"):
            print(RED + line + RESET)
        elif line.startswith("+"):
            print(GREEN + line + RESET)
        else:
            print(line)


def apply_patch(p):
    file = p.get("file")
    find = (p.get("find") or "").replace("\r\n", "\n")
    replace = (p.get("replace") or "").replace("\r\n", "\n")

    if not file:
        print(f"{RED}INVALID PATCH (no file){RESET}")
        return

    if not os.path.exists(file):
        print(f"{RED}MISS {file}{RESET}")
        return

    with open(file, "r", encoding="utf-8") as f:
        content = f.read().replace("\r\n", "\n")

    lines = content.split("\n")
    find_lines = norm_lines(find)
    repl_lines = replace.strip("\n").split("\n")

    idx = match_block(lines, find_lines)

    if idx == -1:
        print(f"{RED}NO_MATCH {file}{RESET}")

        print(YELLOW + "---- expected (first 10 lines) ----" + RESET)
        for i, l in enumerate(find_lines[:10]):
            print(i, repr(l))

        print(YELLOW + "---- file preview (first 20 lines) ----" + RESET)
        for i, l in enumerate(lines[:20]):
            print(i, repr(l))

        return

    new_lines = lines[:idx] + repl_lines + lines[idx+len(find_lines):]

    print(YELLOW + f"\n--- PATCH DIFF: {file} ---" + RESET)
    show_diff(lines, new_lines, file)

    with open(file, "w", encoding="utf-8") as f:
        f.write("\n".join(new_lines) + "\n")

    print(GREEN + f"PATCHED {file}" + RESET + "\n")


def load_json():
    try:
        with open(PATCH_FILE, "r", encoding="utf-8") as f:
            raw = f.read().strip()

        if not raw:
            print(f"{RED}EMPTY patch.json{RESET}")
            sys.exit(1)

        return json.loads(raw)

    except json.JSONDecodeError as e:
        print(f"{RED}JSON ERROR: {e}{RESET}")
        print(YELLOW + "Make sure patch.json is valid UTF-8 JSON" + RESET)
        sys.exit(1)


def main():
    data = load_json()

    if isinstance(data, dict):
        data = [data]

    if not isinstance(data, list):
        print(f"{RED}PATCH MUST BE LIST OR DICT{RESET}")
        sys.exit(1)

    for p in data:
        apply_patch(p)


if __name__ == "__main__":
    main()

PY
