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
cp "$ROOT/branding/src/goatai_tab_drag_chip.h" \
   "$SRC/chrome/browser/ui/views/frame/"
cp "$ROOT/branding/src/goatai_tab_drag_chip.cc" \
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
if "limita o contexto de drag" not in t:
    t = t.replace(
        "void VerticalTabStripRegionView::Layout(PassKey) {\n"
        "  LayoutSuperclass<BaseTabStripRegionView>(this);\n",
        "void VerticalTabStripRegionView::Layout(PassKey) {\n"
        "  LayoutSuperclass<BaseTabStripRegionView>(this);\n\n"
        "  // Goatai: limita o contexto de drag à área das abas, para que os folders\n"
        "  // (acima delas) possam ser alvos de drop independentes.\n"
        "  if (TabDragContext* context = GetDragContext()) {\n"
        "    if (views::View* strip = tab_strip_view()) {\n"
        "      context->SetBoundsRect(views::View::ConvertRectToTarget(\n"
        "          strip, this, strip->GetLocalBounds()));\n"
        "    }\n"
        "  }\n", 1)
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
                  '    "goatai_tab_drag_chip.cc",\n'
                  '    "goatai_tab_drag_chip.h",\n'
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
                  '    "//components/favicon/content",\n'
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
# 6) arrasto nunca destaca para nova janela; continua na strip atual
p = src / "chrome/browser/ui/views/tabs/dragging/tab_drag_controller.cc"
t = p.read_text()
old = """    if (current_drag_target_) {
      TabDragContext* delegate_context =
          current_drag_target_->OnTabDragUpdated(*this, point_in_screen);
      if (!delegate_context && current_state_ == DragState::kDraggingWindow) {
        delegate_context = attached_context_;
      }
      target_context = delegate_context;
    }
  }
"""
if "Goatai: sem alvo = continua" not in t:
    t = t.replace(old, old + """
  // Goatai: sem alvo = continua na própria strip; nunca destaca para janela.
  if (!target_context) {
    target_context = attached_context_;
  }
""", 1)

old = """  gfx::NativeWindow local_window;
  const Liveness state = GetLocalProcessWindow(
      point_in_screen, current_state_ == DragState::kDraggingWindow,
      &local_window);
"""
if "Goatai: alguns backends" not in t:
    t = t.replace(old, old + """  if (!local_window && attached_context_ && attached_context_->GetWidget()) {
    // Goatai: alguns backends (X11/XWayland) não resolvem a janela pelo ponto.
    local_window = attached_context_->GetWidget()->GetNativeWindow();
  }
""", 1)

if "Goatai: favicon da aba segue" not in t:
    t = t.replace(
        "  last_point_in_screen_ = point_in_screen;\n",
        "  last_point_in_screen_ = point_in_screen;\n\n"
        "  // Goatai: favicon da aba segue o cursor durante o arrasto.\n"
        "  if (views::Widget* drag_widget = GetAttachedBrowserWidget()) {\n"
        "    content::WebContents* dragged_contents = nullptr;\n"
        "    if (drag_data_.source_view_index_ < drag_data_.tab_drag_data_.size()) {\n"
        "      dragged_contents =\n"
        "          drag_data_.tab_drag_data_[drag_data_.source_view_index_].contents;\n"
        "    }\n"
        "    GoataiTabDragChip::Get()->Show(drag_widget, dragged_contents,\n"
        "                                   point_in_screen);\n"
        "  }\n", 1)
if "goatai_tab_drag_chip.h" not in t:
    t = t.replace(
        '#include "chrome/browser/ui/views/tabs/dragging/tab_drag_controller.h"',
        '#include "chrome/browser/ui/views/frame/goatai_tab_drag_chip.h"\n'
        '#include "chrome/browser/ui/views/tabs/dragging/tab_drag_controller.h"')
if "GoataiTabDragChip::Get()->Hide();" not in t:
    t = t.replace("TabDragController::~TabDragController() {\n",
                  "TabDragController::~TabDragController() {\n"
                  "  GoataiTabDragChip::Get()->Hide();\n")
    t = t.replace("void TabDragController::RevertDrag() {\n",
                  "void TabDragController::RevertDrag() {\n"
                  "  GoataiTabDragChip::Get()->Hide();\n")
    t = t.replace("void TabDragController::CompleteDrag() {\n",
                  "void TabDragController::CompleteDrag() {\n"
                  "  GoataiTabDragChip::Get()->Hide();\n")
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
