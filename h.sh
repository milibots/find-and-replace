python3 - << 'PY'
import json, sys, os, difflib

data = json.load(sys.stdin)
if isinstance(data, dict):
    data = [data]

RED = "\033[91m"
GREEN = "\033[92m"
YELLOW = "\033[93m"
RESET = "\033[0m"

def norm_lines(s):
    return [l.rstrip() for l in s.replace("\r\n", "\n").strip("\n").split("\n")]

def match_block(lines, pattern):
    n = len(pattern)
    for i in range(len(lines) - n + 1):
        if lines[i:i+n] == pattern:
            return i
    return -1

def show_diff(old_lines, new_lines, file):
    diff = difflib.unified_diff(
        old_lines,
        new_lines,
        fromfile=f"a/{file}",
        tofile=f"b/{file}",
        lineterm=""
    )
    for line in diff:
        if line.startswith("-") and not line.startswith("---"):
            print(RED + line + RESET)
        elif line.startswith("+") and not line.startswith("+++"):
            print(GREEN + line + RESET)
        elif line.startswith("@@"):
            print(YELLOW + line + RESET)
        else:
            print(line)

def apply_patch(p):
    file = p.get("file")
    find = p.get("find", "").replace("\r\n", "\n")
    replace = p.get("replace", "").replace("\r\n", "\n")

    if not file or not os.path.exists(file):
        print(f"{RED}MISS {file}{RESET}")
        return

    with open(file, "r", encoding="utf-8") as f:
        content = f.read().replace("\r\n", "\n")

    lines = content.split("\n")
    find_lines = norm_lines(find)
    replace_lines = replace.strip("\n").split("\n")

    idx = match_block(lines, find_lines)

    if idx == -1:
        print(f"{RED}NO_MATCH {file}{RESET}")
        return

    new_lines = lines[:idx] + replace_lines + lines[idx+len(find_lines):]

    print(f"\n{YELLOW}--- PATCH DIFF: {file} ---{RESET}")
    show_diff(lines, new_lines, file)

    with open(file, "w", encoding="utf-8") as f:
        f.write("\n".join(new_lines) + "\n")

    print(f"{GREEN}PATCHED {file}{RESET}\n")

for p in data:
    apply_patch(p)
PY
