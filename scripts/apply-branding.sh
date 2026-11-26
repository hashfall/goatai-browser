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
# 1.1) mantém a arte colorida no tema escuro (sem virar silhueta)
old_single = """:host([single-colored]) #logo {
  -webkit-mask-image: var(--ntp-logo-image);
  -webkit-mask-repeat: no-repeat;
  -webkit-mask-size: 100%;
  background-color: var(--ntp-logo-color);
}"""
new_single = """:host([single-colored]) #logo {
  background-image: var(--ntp-logo-image);
  background-repeat: no-repeat;
  background-size: 100%;
}"""
t = t.replace(old_single, new_single)
css.write_text(t)

# 2) o arquivo precisa ser servido pelo WebUI
gn = ntp / "BUILD.gn"
t = gn.read_text()
if '"images/goatai_logo.png"' not in t:
    t = t.replace('    "shared_vars.css",\n  ]',
                  '    "shared_vars.css",\n    "images/goatai_logo.png",\n  ]')
    gn.write_text(t)

# 3) brilho roxo/rosa de fundo, sobre a cor de tema (claro e escuro)
html = ntp / "new_tab_page.html"
t = html.read_text()
if "rgba(124, 58, 237" not in t:
    overlay = (
        "        background-image:\n"
        "            radial-gradient(circle at 18% 0%,"
        " rgba(124, 58, 237, .30), transparent 55%),\n"
        "            radial-gradient(circle at 85% 8%,"
        " rgba(236, 72, 153, .22), transparent 50%);\n"
    )
    t = t.replace(
        "        background: $i18n{backgroundColor};\n        margin: 0;",
        "        background: $i18n{backgroundColor};\n" + overlay +
        "        margin: 0;")
    html.write_text(t)

# 4) gradiente de marca no conteúdo da NTP
appcss = ntp / "app.css"
t = appcss.read_text()
old_rhs = (
    ":host(:not([show-background-image_])) #rhsContent {\n"
    "  background-color: var(--color-new-tab-page-background);\n"
    "}")
new_rhs = (
    ":host(:not([show-background-image_])) #rhsContent {\n"
    "  background-color: var(--color-new-tab-page-background);\n"
    "  background-image:\n"
    "      radial-gradient(circle at 18% 0%,"
    " rgba(124, 58, 237, .28), transparent 60%),\n"
    "      radial-gradient(circle at 88% 6%,"
    " rgba(236, 72, 153, .20), transparent 55%);\n"
    "}")
if old_rhs in t:
    appcss.write_text(t.replace(old_rhs, new_rhs))
PY

echo "== paleta roxo/rosa"
cp "$ROOT/branding/src/goatai_color_mixer.h"  "$SRC/chrome/browser/ui/color/"
cp "$ROOT/branding/src/goatai_color_mixer.cc" "$SRC/chrome/browser/ui/color/"

python3 - "$SRC" <<'PY'
import sys
from pathlib import Path

src = Path(sys.argv[1])

gn = src / "chrome/browser/ui/color/BUILD.gn"
t = gn.read_text()
if '"goatai_color_mixer.cc"' not in t:
    t = t.replace('    "chrome_color_provider_utils.cc",\n',
                  '    "chrome_color_provider_utils.cc",\n'
                  '    "goatai_color_mixer.cc",\n'
                  '    "goatai_color_mixer.h",\n')
    gn.write_text(t)

mixers = src / "chrome/browser/ui/color/chrome_color_mixers.cc"
t = mixers.read_text()
if "goatai_color_mixer.h" not in t:
    t = t.replace(
        '#include "chrome/browser/ui/color/chrome_color_provider_utils.h"\n',
        '#include "chrome/browser/ui/color/chrome_color_provider_utils.h"\n'
        '#include "chrome/browser/ui/color/goatai_color_mixer.h"\n')
    mixers.write_text(t)
t = mixers.read_text()
if "AddGoataiColorMixer" not in t:
    t = t.replace(
        "  AddNativeChromeColorMixer(provider, key);\n",
        "  AddNativeChromeColorMixer(provider, key);\n\n"
        "  // Paleta Goatai por cima de todos os mixers padrão.\n"
        "  AddGoataiColorMixer(provider, key);\n")
    mixers.write_text(t)
print("color mixers ok")
PY

echo "== abas verticais por padrão"
python3 - "$SRC" <<'PY'
import sys
from pathlib import Path

src = Path(sys.argv[1])
p = src / "chrome/browser/ui/tabs/tab_strip_prefs.cc"
t = p.read_text()
t = t.replace(
    "registry->RegisterBooleanPref(prefs::kVerticalTabsEnabled, false);",
    "// Goatai: abas verticais por padrão.\n"
    "  registry->RegisterBooleanPref(prefs::kVerticalTabsEnabled, true);")
t = t.replace(
    "registry->RegisterBooleanPref(prefs::kVerticalTabsCollapsedState, false);",
    "// Goatai: barra vertical recolhida (expande ao passar o mouse).\n"
    "  registry->RegisterBooleanPref(prefs::kVerticalTabsCollapsedState, true);")
p.write_text(t)
print("tab_strip_prefs ok")

# Sempre vertical, ignorando pref de perfis antigos.
p = src / "chrome/browser/ui/tabs/vertical_tab_strip_state_controller_impl.cc"
t = p.read_text()
old = """bool VerticalTabStripStateControllerImpl::ShouldDisplayVerticalTabs() const {
  return is_vertical_tabs_enabled_;
}"""
new = """bool VerticalTabStripStateControllerImpl::ShouldDisplayVerticalTabs() const {
  // Goatai: abas sempre verticais; o layout horizontal não é usado.
  return true;
}"""
if old in t:
    p.write_text(t.replace(old, new))

# Esconde o seletor de posição da barra de abas.
p = src / ("chrome/browser/resources/settings/appearance_page/"
           "appearance_page.html.ts")
t = p.read_text()
old = """    <div class="cr-row">
      <div class="flex cr-padded-text" aria-hidden="true">
        $i18n{tabStripPosition}
      </div>"""
new = """    <!-- Goatai: abas sempre verticais; seletor removido. -->
    <div class="cr-row" hidden>
      <div class="flex cr-padded-text" aria-hidden="true">
        $i18n{tabStripPosition}
      </div>"""
if old in t:
    p.write_text(t.replace(old, new))
print("vertical-only ok")
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
