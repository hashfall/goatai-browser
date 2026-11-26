#!/usr/bin/env bash
# Aplica o branding Goatai sobre o checkout upstream em src/.
# Idempotente: pode rodar de novo após um sync.
set -euo pipefail
ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
SRC="$ROOT/src"
I="$ROOT/branding/icons"
T="$SRC/chrome/app/theme"

echo "== ícones"
cp "$I/product_logo_16.png"   "$T/chromium/product_logo_16.png"
cp "$I/product_logo_22_mono.png" "$T/chromium/product_logo_22_mono.png"
cp "$I/product_logo_24.png"   "$T/chromium/product_logo_24.png"
cp "$I/product_logo_48.png"   "$T/chromium/product_logo_48.png"
cp "$I/product_logo_64.png"   "$T/chromium/product_logo_64.png"
cp "$I/product_logo_128.png"  "$T/chromium/product_logo_128.png"
cp "$I/product_logo_256.png"  "$T/chromium/product_logo_256.png"

cp "$I/product_logo_24.png"  "$T/chromium/linux/product_logo_24.png"
cp "$I/product_logo_48.png"  "$T/chromium/linux/product_logo_48.png"
cp "$I/product_logo_64.png"  "$T/chromium/linux/product_logo_64.png"
cp "$I/product_logo_128.png" "$T/chromium/linux/product_logo_128.png"
cp "$I/product_logo_256.png" "$T/chromium/linux/product_logo_256.png"
cp "$I/product_logo_32.xpm"  "$T/chromium/linux/product_logo_32.xpm"

cp "$I/product_logo_16.png" "$T/default_100_percent/chromium/product_logo_16.png"
cp "$I/product_logo_32.png" "$T/default_100_percent/chromium/product_logo_32.png"
cp "$I/product_logo_name_22.png"       "$T/default_100_percent/chromium/product_logo_name_22.png"
cp "$I/product_logo_name_22_white.png" "$T/default_100_percent/chromium/product_logo_name_22_white.png"

cp "$I/2x/product_logo_16.png" "$T/default_200_percent/chromium/product_logo_16.png"
cp "$I/2x/product_logo_32.png" "$T/default_200_percent/chromium/product_logo_32.png"
cp "$I/2x/product_logo_name_22.png"       "$T/default_200_percent/chromium/product_logo_name_22.png"
cp "$I/2x/product_logo_name_22_white.png" "$T/default_200_percent/chromium/product_logo_name_22_white.png"

echo "== BRANDING"
cat > "$T/chromium/BRANDING" <<'EOF'
COMPANY_FULLNAME=Goatai
COMPANY_SHORTNAME=Goatai
PRODUCT_FULLNAME=Goatai
PRODUCT_SHORTNAME=Goatai
PRODUCT_INSTALLER_FULLNAME=Goatai
PRODUCT_INSTALLER_SHORTNAME=Goatai
COPYRIGHT=Copyright @LASTCHANGE_YEAR@ Goatai. All rights reserved.
MAC_BUNDLE_ID=ai.goatai.browser
MAC_CREATOR_CODE=Cr24
MAC_TEAM_ID=
EOF

echo "== strings"
python3 - "$SRC" <<'PY'
import sys
from pathlib import Path

src = Path(sys.argv[1])
files = [
    src / "chrome/app/chromium_strings.grd",
    src / "chrome/app/settings_chromium_strings.grdp",
]
keep = [
    "The Chromium Authors",
    "Chromium Authors",
    "ChromiumOS",
    "Chromium OS",
    "Chromium project",
    "Chromium open source",
    "Chromium Web Store",
]

for f in files:
    t = f.read_text()
    if "Goatai" in t:
        print("já aplicado:", f.name)
        continue
    t = t.replace("Chromium", "Goatai")
    for k in keep:
        t = t.replace(k.replace("Chromium", "Goatai"), k)
    f.write_text(t)
    print("branded:", f.name)
PY

echo "== New Tab Page"
NTP="$SRC/chrome/browser/resources/new_tab_page"
mkdir -p "$NTP/images"
cp "$I/ntp_logo.png" "$NTP/images/goatai_logo.png"

python3 - "$NTP" <<'PY'
import sys
from pathlib import Path

ntp = Path(sys.argv[1])

# 1) logo central: usa a cabra em vez do logo do Google
css = ntp / "logo.css"
t = css.read_text()
t = t.replace(
    "url(chrome://resources/cr_components/searchbox/icons/google_logo.svg)",
    "url('images/goatai_logo.png')")
t = t.replace(
    "url(chrome://resources/cr_components/searchbox/icons/google_logo_26/google_logo.svg)",
    "url('images/goatai_logo.png')")
t = t.replace("  height: 92px;\n  width: 272px;", "  height: 96px;\n  width: 96px;")
t = t.replace("  height: 82px;\n  width: 270px;", "  height: 96px;\n  width: 96px;")
css.write_text(t)

# 2) o arquivo precisa ser servido pelo WebUI
gn = ntp / "BUILD.gn"
t = gn.read_text()
if '"images/goatai_logo.png"' not in t:
    t = t.replace('    "shared_vars.css",\n  ]',
                  '    "shared_vars.css",\n    "images/goatai_logo.png",\n  ]')
    gn.write_text(t)
PY

echo "== meta"
python3 - "$SRC" <<'PY'
import sys
from pathlib import Path

src = Path(sys.argv[1])
f = src / "chrome/installer/linux/common/chromium-browser.info"
t = f.read_text()
t = t.replace('MENUNAME="Chromium Web Browser"', 'MENUNAME="Goatai"')
f.write_text(t)
print("chromium-browser.info ok")
PY

echo "pronto. rode ./scripts/build.sh"
