#!/usr/bin/env bash
# Empacota o Goatai em um AppImage (x86_64).
#
# Uso:
#   ./scripts/package-appimage.sh
#
# Saída:
#   dist/Goatai-<versão>-x86_64.AppImage
#
# Requisitos: build em src/out/Default, mksquashfs/strip e curl.
set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
OUT="$ROOT/src/out/Default"
VERSION="$(cat "$ROOT/VERSION")"
DIST="$ROOT/dist"
APPDIR="$DIST/Goatai.AppDir"
TOOLS="$DIST/.tools"
APP="$APPDIR/usr/lib/goatai"
ARCH="x86_64"

if [[ ! -x "$OUT/goatai" ]]; then
  echo "erro: $OUT/goatai não existe; compile antes (./scripts/build.sh)" >&2
  exit 1
fi

echo "== limpando AppDir"
rm -rf "$APPDIR"
mkdir -p "$APP" "$APPDIR/usr/share/applications" "$APPDIR/usr/share/icons/hicolor/256x256/apps"

echo "== copiando runtime (binário, libs, recursos)"
# Binário e recursos principais.
cp -a "$OUT/goatai" "$APP/"
for f in chrome_100_percent.pak chrome_200_percent.pak resources.pak icudtl.dat \
         snapshot_blob.bin v8_context_snapshot.bin chrome_crashpad_handler \
         chrome-sandbox vk_swiftshader_icd.json headless_command_resources.pak; do
  [[ -e "$OUT/$f" ]] && cp -a "$OUT/$f" "$APP/"
done

# Bibliotecas componentizadas (o binário usa RUNPATH $ORIGIN).
shopt -s nullglob
for so in "$OUT"/*.so "$OUT"/*.so.*; do
  [[ "$so" == *.TOC ]] && continue
  cp -a "$so" "$APP/"
done
shopt -u nullglob

# Dados auxiliares.
cp -a "$OUT/resources" "$APP/" 2>/dev/null || true
cp -a "$OUT/hyphen-data" "$APP/" 2>/dev/null || true

# Locales: apenas os idiomas que interessam (reduz ~110 MB).
mkdir -p "$APP/locales"
for loc in en-US pt-BR es; do
  [[ -f "$OUT/locales/$loc.pak" ]] && cp -a "$OUT/locales/$loc.pak" "$APP/locales/"
done

# Extensões externas (uBOL, Tampermonkey, OpenCode Browse) e a Goatai IA.
mkdir -p "$APP/extensions"
[[ -f "$ROOT/extensions/external_extensions.json" ]] && \
  cp -a "$ROOT/extensions/external_extensions.json" "$APP/extensions/"
cp -a "$ROOT/extensions/goatai_ai" "$APP/extensions/"

echo "== strip (cópia; os originais ficam intactos)"
find "$APP" -maxdepth 1 -type f \
  \( -name '*.so' -o -name '*.so.*' -o -name 'goatai' -o -name 'chrome_crashpad_handler' \) \
  -exec strip --strip-unneeded {} + 2>/dev/null || true

echo "== AppRun / desktop / ícone"
cat > "$APPDIR/AppRun" <<'EOF'
#!/bin/sh
set -e
HERE="$(dirname "$(readlink -f "$0")")"
APP="$HERE/usr/lib/goatai"
CONFIG_DIR="${XDG_CONFIG_HOME:-$HOME/.config}/goatai"
PROFILE="${GOATAI_USER_DATA_DIR:-$CONFIG_DIR/profile}"

# Extensão Goatai IA num caminho fixo: o ID da extensão depende do caminho,
# então copiamos para o perfil para a chave salva continuar valendo.
EXT_DST="$CONFIG_DIR/extensions/goatai_ai"
EXT_SRC="$APP/extensions/goatai_ai"
if [ ! -f "$EXT_DST/manifest.json" ] || \
   [ "$EXT_SRC/manifest.json" -nt "$EXT_DST/manifest.json" ]; then
  mkdir -p "$EXT_DST"
  cp -a "$EXT_SRC/." "$EXT_DST/"
fi

export CHROME_DESKTOP=goatai.desktop
exec "$APP/goatai" \
  --user-data-dir="$PROFILE" \
  --load-extension="$EXT_DST" \
  --no-first-run --no-default-browser-check \
  --disable-setuid-sandbox \
  "$@"
EOF
chmod +x "$APPDIR/AppRun"

cat > "$APPDIR/goatai.desktop" <<'EOF'
[Desktop Entry]
Version=1.0
Type=Application
Name=Goatai
GenericName=Web Browser
Comment=Navegador Goatai baseado em Chromium
Exec=goatai %U
Icon=goatai
Terminal=false
Categories=Network;WebBrowser;
MimeType=x-scheme-handler/http;x-scheme-handler/https;text/html;application/xhtml+xml;
StartupNotify=true
StartupWMClass=goatai
EOF
cp "$APPDIR/goatai.desktop" "$APPDIR/usr/share/applications/"

if [[ ! -f "$DIST/goatai.png" ]]; then
  if command -v magick >/dev/null 2>&1; then
    magick "$ROOT/goatai.webp" -resize 256x256 "$DIST/goatai.png"
  else
    convert "$ROOT/goatai.webp" -resize 256x256 "$DIST/goatai.png"
  fi
fi
cp "$DIST/goatai.png" "$APPDIR/goatai.png"
cp "$DIST/goatai.png" "$APPDIR/usr/share/icons/hicolor/256x256/apps/goatai.png"

echo "== appimagetool"
TOOL="$TOOLS/appimagetool-$ARCH.AppImage"
if [[ ! -x "$TOOL" ]]; then
  mkdir -p "$TOOLS"
  curl -L --fail --retry 3 -o "$TOOL" \
    "https://github.com/AppImage/appimagetool/releases/download/continuous/appimagetool-$ARCH.AppImage"
  chmod +x "$TOOL"
fi
if [[ ! -x "$TOOLS/squashfs-root/AppRun" ]]; then
  (cd "$TOOLS" && "$TOOL" --appimage-extract >/dev/null)
fi

echo "== gerando AppImage"
OUTPUT="$DIST/Goatai-$VERSION-$ARCH.AppImage"
rm -f "$OUTPUT"
ARCH="$ARCH" "$TOOLS/squashfs-root/AppRun" "$APPDIR" "$OUTPUT" --comp zstd
chmod +x "$OUTPUT"

echo "== pronto: $OUTPUT"
ls -lh "$OUTPUT"
