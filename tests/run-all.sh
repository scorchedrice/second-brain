#!/usr/bin/env bash
set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"

for test_file in \
  tests/test-repo-config.sh \
  tests/test-lint-wiki.sh \
  tests/test-vault-structure.sh \
  tests/test-templates.sh \
  tests/test-agent-schema.sh \
  tests/test-readme.sh; do
  printf '==> %s\n' "$test_file"
  bash "$ROOT/$test_file"
done

printf 'all tests: PASS\n'
