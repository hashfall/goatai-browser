#!/usr/bin/env bash
# Aplica os patches de branding GoatAI sobre o checkout upstream.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
PATCHES="$ROOT/branding/patches"
cd "$ROOT/src"
shopt -s nullglob
found=0
for p in "$PATCHES"/*.patch; do
  found=1
  echo "== aplicando $(basename "$p")"
  git apply --3way "$p"
done
[ "$found" = 1 ] || echo "nenhum patch em branding/patches/"
