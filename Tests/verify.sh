#!/bin/sh
set -eu
PROJECT_DIR=$(CDPATH= cd -- "$(dirname -- "$0")/.." && pwd)
VERIFY_DIR=$(mktemp -d "${TMPDIR:-/tmp}/worddaily-verify.XXXXXX")
trap 'rm -rf "$VERIFY_DIR"' EXIT
swiftc -module-cache-path "$VERIFY_DIR/cache" \
  "$PROJECT_DIR/Shared/WordEntry.swift" \
  "$PROJECT_DIR/Shared/DailySchedule.swift" \
  "$PROJECT_DIR/App/SavedWordsStore.swift" \
  "$PROJECT_DIR/Tests/main.swift" -o "$VERIFY_DIR/verify"
"$VERIFY_DIR/verify" "$PROJECT_DIR/Shared/words.json"
