#!/usr/bin/env bash
# Executa o binário compilado com um perfil separado do Chrome do sistema.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
BIN="$ROOT/src/out/Default/chrome"
# Não herdar app id de outros apps Electron/Chrome.
unset CHROME_DESKTOP
PROFILE="${GOATAI_USER_DATA_DIR:-$ROOT/.run/profile}"
mkdir -p "$PROFILE"
exec "$BIN" --user-data-dir="$PROFILE" --no-first-run --no-default-browser-check "$@"
