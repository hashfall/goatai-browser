#!/usr/bin/env bash
# Compila o GoatAI Browser (Chromium) usando o depot_tools local.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
export PATH="$ROOT/depot_tools:$PATH"
export DEPOT_TOOLS_UPDATE=0
cd "$ROOT/src"
autoninja -C out/Default "$@" chrome
"$ROOT/scripts/install-extensions.sh"
