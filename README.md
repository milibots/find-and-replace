# find-and-replace (h.sh)

A minimal, strict CLI tool for safe JSON-based find & replace across files.

Built for:
- AI patch systems
- CI/CD automation
- DevOps scripting
- Remote code editing workflows

---

## 🚀 Features

- ✔ JSON-based patch format
- ✔ Multiline safe matching
- ✔ Block-based replace engine (not fragile string replace)
- ✔ Handles indentation + whitespace differences
- ✔ CRLF / LF normalization
- ✔ Safe failure (no partial corruption)
- ✔ No dependencies except Python 3

---

## 📦 Install

```bash id="r1md02"
curl -fsSL https://raw.githubusercontent.com/milibots/find-and-replace/main/h.sh -o h.sh
chmod +x h.sh
