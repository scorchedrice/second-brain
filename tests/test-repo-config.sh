#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

grep -Fxq '.DS_Store' "$ROOT/.gitignore"
grep -Fxq '.obsidian/*' "$ROOT/.gitignore"
grep -Fxq '!.obsidian/app.json' "$ROOT/.gitignore"
grep -Eq '"attachmentFolderPath"[[:space:]]*:[[:space:]]*"raw/assets"' \
  "$ROOT/.obsidian/app.json"

printf 'repo config: PASS\n'
