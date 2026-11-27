#!/usr/bin/env bash
# Instala as extensões padrão do Goatai via external_extensions.json.
# O Chromium lê <dir do binário>/extensions/external_extensions.json e baixa
# os CRX do Chrome Web Store no primeiro uso de cada perfil.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DEST="$ROOT/src/out/Default/extensions"
mkdir -p "$DEST"
cp "$ROOT/extensions/external_extensions.json" "$DEST/external_extensions.json"
