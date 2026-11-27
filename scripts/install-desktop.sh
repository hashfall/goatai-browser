#!/usr/bin/env bash
# Instala o atalho .desktop e os ícones do Goatai no menu de aplicativos.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
DATA="${XDG_DATA_HOME:-$HOME/.local/share}"
APPS="$DATA/applications"
ICONS="$DATA/icons/hicolor"
BIN="$ROOT/src/out/Default/goatai"
PROFILE="$ROOT/.run/profile"

if [ ! -x "$BIN" ]; then
  echo "binário não encontrado: $BIN (rode ./scripts/build.sh)" >&2
  exit 1
fi

mkdir -p "$APPS"
for s in 16 24 32 48 64 128 256; do
  src="$ROOT/branding/icons/product_logo_$s.png"
  dst="$ICONS/${s}x${s}/apps/goatai.png"
  if [ -f "$src" ]; then
    install -Dm644 "$src" "$dst"
  fi
done

cat > "$APPS/goatai.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Goatai
GenericName=Web Browser
Comment=Navegador Goatai baseado em Chromium
Exec=env CHROME_DESKTOP=goatai.desktop "$BIN" --user-data-dir="$PROFILE" --no-first-run --no-default-browser-check %U
Icon=goatai
Terminal=false
Categories=Network;WebBrowser;
MimeType=x-scheme-handler/http;x-scheme-handler/https;text/html;application/xhtml+xml;application/x-extension-html;application/x-extension-htm;
StartupNotify=true
StartupWMClass=chrome
EOF
chmod 644 "$APPS/goatai.desktop"

update-desktop-database "$APPS" >/dev/null 2>&1 || true
gtk-update-icon-cache -f -t "$ICONS" >/dev/null 2>&1 || true
echo "instalado: $APPS/goatai.desktop"
