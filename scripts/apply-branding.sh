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

echo "== folders de pins (abas verticais)"
cp "$ROOT/branding/src/vertical_tab_strip_folder_bar.h" \
   "$SRC/chrome/browser/ui/views/frame/"
cp "$ROOT/branding/src/vertical_tab_strip_folder_bar.cc" \
   "$SRC/chrome/browser/ui/views/frame/"

python3 - "$SRC" <<'PY'
import sys
from pathlib import Path

src = Path(sys.argv[1])

# 1) insere a barra de folders no topo da lista de abas
p = src / "chrome/browser/ui/views/frame/vertical_tab_strip_region_view.cc"
t = p.read_text()
if "vertical_tab_strip_folder_bar.h" not in t:
    t = t.replace(
        '#include "chrome/browser/ui/views/frame/vertical_tab_strip_region_view.h"',
        '#include "chrome/browser/ui/views/frame/vertical_tab_strip_region_view.h"\n'
        '#include "chrome/browser/ui/views/frame/vertical_tab_strip_folder_bar.h"', 1)
if "tabs/dragging/tab_drag_target.h" not in t:
    t = t.replace(
        '#include "chrome/browser/ui/views/frame/vertical_tab_strip_folder_bar.h"',
        '#include "chrome/browser/ui/views/frame/vertical_tab_strip_folder_bar.h"\n'
        '#include "chrome/browser/ui/views/tabs/dragging/tab_drag_target.h"', 1)
if "VerticalTabStripRegionView::GetTabDragTarget" not in t:
    t = t.replace(
        "void VerticalTabStripRegionView::Layout(PassKey) {",
        "TabDragTarget* VerticalTabStripRegionView::GetTabDragTarget(\n"
        "    const gfx::Point& point_in_screen) {\n"
        "  if (folder_bar_ && folder_bar_->GetVisible() &&\n"
        "      folder_bar_->GetBoundsInScreen().Contains(point_in_screen)) {\n"
        "    return folder_bar_;\n"
        "  }\n"
        "  return BaseTabStripRegionView::GetTabDragTarget(point_in_screen);\n"
        "}\n\n"
        "void VerticalTabStripRegionView::Layout(PassKey) {", 1)
if "folder_bar_ = folder_bar.get();" not in t:
    t = t.replace(
        "  const int region_horizontal_padding =\n"
        "      GetLayoutConstant(LayoutConstant::kVerticalTabStripHorizontalPadding);\n",
        "  const int region_horizontal_padding =\n"
        "      GetLayoutConstant(LayoutConstant::kVerticalTabStripHorizontalPadding);\n\n"
        "  // Goatai: folders de pins fixados no topo da lista de abas.\n"
        "  auto folder_bar = std::make_unique<VerticalTabStripFolderBar>(\n"
        "      browser_view->browser()->GetProfile(), browser_view->browser());\n"
        "  folder_bar_ = folder_bar.get();\n"
        "  content_area_view_->AddChildViewAt(\n"
        "      std::unique_ptr<views::View>(std::move(folder_bar)), 0);\n"
        "  folder_bar_->SetProperty(\n"
        "      views::kMarginsKey, gfx::Insets::VH(0, region_horizontal_padding));\n")
if "Goatai: folders/pins acompanham" not in t:
    t = t.replace(
        "void VerticalTabStripRegionView::AnimateExpandOnHover(bool expand) {\n"
        "  is_expanded_on_hover_ = expand;\n  ResetExpandOnHoverTimers();\n",
        "void VerticalTabStripRegionView::AnimateExpandOnHover(bool expand) {\n"
        "  is_expanded_on_hover_ = expand;\n  ResetExpandOnHoverTimers();\n\n"
        "  // Goatai: folders/pins acompanham a expansão por hover.\n"
        "  if (folder_bar_) {\n"
        "    folder_bar_->SetVisible(expand);\n"
        "  }\n")
if "Goatai: pins/folders só aparecem" not in t:
    t = t.replace(
        "  bool collapsed = state != tabs::VerticalTabStripCollapseState::kExpanded;\n",
        "  bool collapsed = state != tabs::VerticalTabStripCollapseState::kExpanded;\n\n"
        "  // Goatai: pins/folders só aparecem com a barra expandida.\n"
        "  if (folder_bar_) {\n"
        "    folder_bar_->SetVisible(!collapsed);\n"
        "  }\n", 1)
p.write_text(t)

# 2) membro e include no header da region view
p = src / "chrome/browser/ui/views/frame/vertical_tab_strip_region_view.h"
t = p.read_text()
if "class VerticalTabStripFolderBar;" not in t:
    t = t.replace("class VerticalTabStripBottomContainer;",
                  "class VerticalTabStripBottomContainer;\nclass VerticalTabStripFolderBar;")
if "folder_bar_" not in t:
    t = t.replace("  raw_ptr<views::View> content_area_view_ = nullptr;",
                  "  raw_ptr<views::View> content_area_view_ = nullptr;\n"
                  "  raw_ptr<VerticalTabStripFolderBar> folder_bar_ = nullptr;")
if "VerticalTabStripFolderBar* GetFolderBar()" not in t:
    t = t.replace("  VerticalTabStripBottomContainer* GetBottomContainer() {",
                  "  VerticalTabStripFolderBar* GetFolderBar() { return folder_bar_; }\n\n"
                  "  TabDragTarget* GetTabDragTarget(\n"
                  "      const gfx::Point& point_in_screen) override;\n\n"
                  "  VerticalTabStripBottomContainer* GetBottomContainer() {")
p.write_text(t)

# 3) BUILD.gn
p = src / "chrome/browser/ui/views/frame/BUILD.gn"
t = p.read_text()
if "vertical_tab_strip_folder_bar.cc" not in t:
    t = t.replace('  sources = [ "vertical_tab_strip_region_view.cc" ]',
                  '  sources = [\n'
                  '    "vertical_tab_strip_folder_bar.cc",\n'
                  '    "vertical_tab_strip_folder_bar.h",\n'
                  '    "vertical_tab_strip_region_view.cc",\n  ]')
    t = t.replace('    "//components/tabs:public",\n    "//ui/base",',
                  '    "//components/tabs:public",\n'
                  '    "//ui/accessibility:ax_enums_mojo",\n    "//ui/base",')
    t = t.replace('    "//ui/base/metadata",\n    "//ui/events",\n    "//ui/gfx/geometry",',
                  '    "//ui/base/metadata",\n    "//ui/events",\n'
                  '    "//ui/gfx",\n    "//ui/gfx/geometry",')
    t = t.replace('    "//chrome/browser/ui:ui_features",\n    "//chrome/browser/ui/actions:actions_headers",',
                  '    "//chrome/browser/bookmarks:impl",\n'
                  '    "//chrome/browser/profiles:profile",\n'
                  '    "//chrome/browser/ui:ui_features",\n'
                  '    "//chrome/browser/ui/actions:actions_headers",')
    t = t.replace('    "//chrome/browser/ui/web_applications",\n    "//ui/base/dragdrop:types",',
                  '    "//chrome/browser/ui/web_applications",\n'
                  '    "//components/bookmarks/browser",\n'
                  '    "//content/public/browser",\n'
                  '    "//ui/base/clipboard",\n'
                  '    "//ui/base/dragdrop:types",\n'
                  '    "//ui/color",')
    p.write_text(t)

if 'tabs/dragging:tab_drag_target' not in t:
    t = t.replace(
        '    "//chrome/browser/ui/views/tabs/common:impl",',
        '    "//chrome/browser/ui/views/tabs/common:impl",\n'
        '    "//chrome/browser/ui/views/tabs/dragging:tab_drag_target",')
    p.write_text(t)

# 4) expandir no hover sempre ligado, sem opção
p = src / "chrome/browser/ui/tabs/vertical_tab_strip_state_controller_impl.cc"
t = p.read_text()
if "Goatai: expansão automática sempre ligada" not in t:
    t = t.replace(
        "  is_expand_on_hover_enabled_ =\n"
        "      pref_service_->GetBoolean(prefs::kVerticalTabsExpandOnHoverEnabled);",
        "  // Goatai: expansão automática sempre ligada.\n"
        "  is_expand_on_hover_enabled_ = true;")
    t = t.replace(
        "bool VerticalTabStripStateControllerImpl::IsExpandOnHoverEnabled() const {\n"
        "  return is_expand_on_hover_enabled_;\n}",
        "bool VerticalTabStripStateControllerImpl::IsExpandOnHoverEnabled() const {\n"
        "  // Goatai: expansão automática sempre ligada.\n  return true;\n}")
p.write_text(t)

# 5) esconde o toggle nas configurações
p = src / "chrome/browser/resources/settings/appearance_page/appearance_page.html.ts"
t = p.read_text()
if 'hidden pref-key="vertical_tabs.expand_on_hover"' not in t:
    t = t.replace('        <settings-toggle-button id="showVerticalTabsExpandOnHover"\n'
                  '            pref-key="vertical_tabs.expand_on_hover"',
                  '        <settings-toggle-button id="showVerticalTabsExpandOnHover"\n'
                  '            hidden pref-key="vertical_tabs.expand_on_hover"')
    p.write_text(t)
# 6) arrastar aba nunca destaca para nova janela (só menu de contexto)
p = src / "chrome/browser/ui/views/tabs/common/tab_drag_handler.cc"
t = p.read_text()
old_detach = """bool TabDragHandler::IsTabDetachable(const views::View* view) const {
  if (const auto* tab_view = views::AsViewClass<TabView>(view)) {
    return !web_app::IsPinnedHomeTab(base::to_address(tab_strip_model_),
                                     tab_view->GetTabInterface());
  }
  return true;
}"""
new_detach = """bool TabDragHandler::IsTabDetachable(const views::View* view) const {
  // Goatai: arrastar nunca destaca a aba para outra janela. Mover para uma
  // nova janela continua disponível no menu de contexto da aba.
  return false;
}"""
if old_detach in t:
    p.write_text(t.replace(old_detach, new_detach))

# 7) bloqueia a criação de nova janela no drop do arrasto
p = src / "chrome/browser/ui/views/tabs/dragging/tab_drag_controller.cc"
t = p.read_text()
old_detach_start = """TabDragController::DetachIntoNewBrowserAndRunMoveLoop(
    gfx::Point point_in_screen) {
"""
if "Goatai: arrastar aba nunca cria" not in t:
    t = t.replace(old_detach_start,
                  old_detach_start +
                  "  // Goatai: arrastar aba nunca cria/destaca uma nova janela.\n"
                  "  // Mover para nova janela fica no menu de contexto da aba.\n"
                  "  return Liveness::kAlive;\n", 1)
    p.write_text(t)

# 8) remove dos menus as opções de horizontal e de desligar auto-expand
p = src / "chrome/browser/ui/tabs/tab_menu_model.cc"
t = p.read_text()
start_marker = ("  if (controller) {\n"
                "    AddSeparator(ui::NORMAL_SEPARATOR);\n"
                "    const int switch_to_horizontal_id =")
if start_marker in t:
    start = t.index(start_marker)
    end = t.index("  // Append extension items for the 'tab' context", start)
    t = t[:start] + "  // Goatai: sem opção de voltar para abas horizontais.\n\n" + t[end:]
    p.write_text(t)

p = src / "chrome/browser/ui/views/frame/system_menu_model_builder.cc"
t = p.read_text()
old = ("      model->AddItemWithStringId(IDC_TOGGLE_VERTICAL_TABS,\n"
       "                                 switch_to_horizontal_id);\n\n"
       "      model->AddItemWithStringId(IDC_TOGGLE_VERTICAL_TABS_COLLAPSE,")
new = ("      // Goatai: sem opção horizontal; auto-expand é obrigatório.\n"
       "      model->AddItemWithStringId(IDC_TOGGLE_VERTICAL_TABS_COLLAPSE,")
if old in t:
    t = t.replace(old, new)
old = ("      model->AddItemWithStringId(\n"
       "          IDC_TOGGLE_VERTICAL_TABS_EXPAND_ON_HOVER,\n"
       "          controller->IsExpandOnHoverEnabled()\n"
       "              ? IDS_VERTICAL_TABS_DISABLE_EXPAND_ON_HOVER\n"
       "              : IDS_VERTICAL_TABS_ENABLE_EXPAND_ON_HOVER);\n"
       "      model->SetElementIdentifierAt(\n"
       "          model->GetIndexOfCommandId(IDC_TOGGLE_VERTICAL_TABS_EXPAND_ON_HOVER)\n"
       "              .value(),\n"
       "          kToggleVerticalTabsExpandOnHoverElementId);\n")
if old in t:
    t = t.replace(old, "")
old = ("    model->SetElementIdentifierAt(\n"
       "        model->GetIndexOfCommandId(IDC_TOGGLE_VERTICAL_TABS).value(),\n"
       "        kToggleVerticalTabsElementId);\n")
if old in t:
    t = t.replace(old, "")
p.write_text(t)

p = src / "chrome/browser/ui/toolbar/app_menu_model.cc"
t = p.read_text()
start_marker = ("  if (auto* controller = tabs::VerticalTabStripStateController::From(browser)) {\n"
                "    if (controller->ShouldDisplayVerticalTabs()) {")
if start_marker in t:
    start = t.index(start_marker)
    end = t.index("  if (CustomizeChromePageHandler::IsSupported(", start)
    t = t[:start] + "  // Goatai: abas sempre verticais, sem toggle.\n" + t[end:]
    p.write_text(t)

print("folders/expand ok")
PY
