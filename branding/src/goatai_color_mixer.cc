// Copyright 2026 Goatai. All rights reserved.
// Use of this source code is governed by a BSD-style license.

#include "chrome/browser/ui/color/goatai_color_mixer.h"

#include <memory>

#include "base/no_destructor.h"
#include "chrome/browser/ui/color/chrome_color_id.h"
#include "ui/color/color_id.h"
#include "ui/color/color_mixer.h"
#include "ui/color/color_provider.h"
#include "ui/color/color_recipe.h"
#include "ui/color/dynamic_color/palette.h"
#include "ui/color/dynamic_color/palette_factory.h"
#include "ui/gfx/color_palette.h"

namespace {

// Paletas tonais da marca. Geradas uma única vez e cacheadas.
const ui::Palette& GoataiVioletPalette() {
  static base::NoDestructor<std::unique_ptr<ui::Palette>> palette(
      ui::GeneratePalette(SkColorSetRGB(0x7C, 0x3A, 0xED),
                          ui::ColorProviderKey::SchemeVariant::kTonalSpot));
  return **palette;
}

const ui::Palette& GoataiPinkPalette() {
  static base::NoDestructor<std::unique_ptr<ui::Palette>> palette(
      ui::GeneratePalette(SkColorSetRGB(0xEC, 0x48, 0x99),
                          ui::ColorProviderKey::SchemeVariant::kTonalSpot));
  return **palette;
}

}  // namespace

void AddGoataiColorMixer(ui::ColorProvider* provider,
                         const ui::ColorProviderKey& key) {
  const bool dark =
      key.color_mode == ui::ColorProviderKey::ColorMode::kDark;
  ui::ColorMixer& mixer = provider->AddMixer();

  // Paleta da marca (Goatai): violeta profundo + magenta.
  const SkColor frame =
      dark ? SkColorSetRGB(0x16, 0x08, 0x26) : SkColorSetRGB(0x4C, 0x1D, 0x95);
  const SkColor frame_inactive =
      dark ? SkColorSetRGB(0x1E, 0x0B, 0x33) : SkColorSetRGB(0x43, 0x19, 0x86);
  const SkColor toolbar =
      dark ? SkColorSetRGB(0x2A, 0x0F, 0x4D) : SkColorSetRGB(0x5B, 0x21, 0xB6);
  const SkColor ntp_background =
      dark ? SkColorSetRGB(0x16, 0x08, 0x26) : SkColorSetRGB(0xF7, 0xF1, 0xFF);
  const SkColor ntp_text =
      dark ? SkColorSetRGB(0xF3, 0xE8, 0xFF) : SkColorSetRGB(0x2A, 0x0B, 0x4D);
  const SkColor ntp_link =
      dark ? SkColorSetRGB(0xFF, 0x7A, 0xB8) : SkColorSetRGB(0xD8, 0x1B, 0x60);
  const SkColor ntp_header =
      dark ? SkColorSetRGB(0xC4, 0xB5, 0xFD) : SkColorSetRGB(0x6D, 0x28, 0xD9);
  const SkColor accent =
      dark ? SkColorSetRGB(0xFF, 0x5C, 0xA8) : SkColorSetRGB(0xE9, 0x1E, 0x63);
  const SkColor secondary =
      dark ? SkColorSetRGB(0xA7, 0x8B, 0xFA) : SkColorSetRGB(0x7C, 0x3A, 0xED);
  const SkColor primary_container =
      dark ? SkColorSetRGB(0x3B, 0x14, 0x66) : SkColorSetRGB(0xED, 0xE4, 0xFF);
  const SkColor on_primary_container =
      dark ? SkColorSetRGB(0xF3, 0xE8, 0xFF) : SkColorSetRGB(0x2A, 0x0B, 0x4D);
  const SkColor secondary_container =
      dark ? SkColorSetRGB(0x2E, 0x10, 0x55) : SkColorSetRGB(0xFC, 0xE7, 0xF2);

  // Moldura, barra de abas e toolbar.
  mixer[ui::kColorFrameActive] = {frame};
  mixer[ui::kColorFrameInactive] = {frame_inactive};
  mixer[kColorToolbar] = {toolbar};
  mixer[kColorToolbarBackgroundSubtleEmphasis] = {toolbar};
  mixer[kColorToolbarText] = {SK_ColorWHITE};
  mixer[kColorToolbarButtonIcon] = {SK_ColorWHITE};
  mixer[kColorToolbarButtonIconDefault] = {SK_ColorWHITE};
  mixer[kColorToolbarButtonIconHovered] = {SK_ColorWHITE};
  mixer[kColorToolbarButtonIconInactive] =
      {SkColorSetA(SK_ColorWHITE, 0xB3)};

  // Abas.
  mixer[kColorTabBackgroundActiveFrameActive] = {toolbar};
  mixer[kColorTabBackgroundActiveFrameInactive] = {toolbar};
  mixer[kColorTabBackgroundInactiveFrameActive] = {frame};
  mixer[kColorTabBackgroundInactiveFrameInactive] = {frame_inactive};
  mixer[kColorTabForegroundActiveFrameActive] = {SK_ColorWHITE};
  mixer[kColorTabForegroundActiveFrameInactive] = {SK_ColorWHITE};
  mixer[kColorTabForegroundInactiveFrameActive] =
      {SkColorSetA(SK_ColorWHITE, 0xCC)};
  mixer[kColorTabForegroundInactiveFrameInactive] =
      {SkColorSetA(SK_ColorWHITE, 0x99)};

  // Barra de favoritos acompanha a toolbar.
  mixer[kColorBookmarkBarBackground] = {toolbar};
  mixer[kColorBookmarkBarForeground] = {SK_ColorWHITE};
  mixer[kColorBookmarkButtonIcon] = {SK_ColorWHITE};

  // New Tab Page.
  mixer[kColorNewTabPageBackground] = {ntp_background};
  mixer[kColorNewTabPageText] = {ntp_text};
  mixer[kColorNewTabPageLink] = {ntp_link};
  mixer[kColorNewTabPageHeader] = {ntp_header};

  // Omnibox (a pílula grande da barra de endereço).
  mixer[ui::kColorSysOmniboxContainer] = {primary_container};
  mixer[kColorLocationBarBackground] = {primary_container};
  mixer[kColorLocationBarBackgroundHovered] = {primary_container};
  mixer[kColorLocationBarBorder] = {accent};

  // Destaques (foco, botões, seleção, links de WebUI).
  mixer[ui::kColorAccent] = {accent};
  mixer[ui::kColorSysPrimary] = {accent};
  mixer[ui::kColorSysOnPrimary] = {SK_ColorWHITE};
  mixer[ui::kColorSysPrimaryContainer] = {primary_container};
  mixer[ui::kColorSysOnPrimaryContainer] = {on_primary_container};
  mixer[ui::kColorSysSecondary] = {secondary};
  mixer[ui::kColorSysOnSecondary] = {SK_ColorWHITE};
  mixer[ui::kColorSysSecondaryContainer] = {secondary_container};
  mixer[ui::kColorSysOnSecondaryContainer] = {on_primary_container};

  // Substitui a paleta Material padrão (azul) pela paleta Goatai. Isso
  // recolore todas as superfícies Material que derivam dos ref colors.
  const ui::TonalPalette& purple = GoataiVioletPalette().primary();
  mixer[ui::kColorRefPrimary0] = {purple.get(0)};
  mixer[ui::kColorRefPrimary10] = {purple.get(10)};
  mixer[ui::kColorRefPrimary20] = {purple.get(20)};
  mixer[ui::kColorRefPrimary25] = {purple.get(25)};
  mixer[ui::kColorRefPrimary30] = {purple.get(30)};
  mixer[ui::kColorRefPrimary40] = {purple.get(40)};
  mixer[ui::kColorRefPrimary50] = {purple.get(50)};
  mixer[ui::kColorRefPrimary60] = {purple.get(60)};
  mixer[ui::kColorRefPrimary70] = {purple.get(70)};
  mixer[ui::kColorRefPrimary80] = {purple.get(80)};
  mixer[ui::kColorRefPrimary90] = {purple.get(90)};
  mixer[ui::kColorRefPrimary95] = {purple.get(95)};
  mixer[ui::kColorRefPrimary99] = {purple.get(99)};
  mixer[ui::kColorRefPrimary100] = {purple.get(100)};

  const ui::TonalPalette& pink = GoataiPinkPalette().primary();
  mixer[ui::kColorRefSecondary0] = {pink.get(0)};
  mixer[ui::kColorRefSecondary10] = {pink.get(10)};
  mixer[ui::kColorRefSecondary12] = {pink.get(12)};
  mixer[ui::kColorRefSecondary15] = {pink.get(15)};
  mixer[ui::kColorRefSecondary20] = {pink.get(20)};
  mixer[ui::kColorRefSecondary25] = {pink.get(25)};
  mixer[ui::kColorRefSecondary30] = {pink.get(30)};
  mixer[ui::kColorRefSecondary35] = {pink.get(35)};
  mixer[ui::kColorRefSecondary40] = {pink.get(40)};
  mixer[ui::kColorRefSecondary50] = {pink.get(50)};
  mixer[ui::kColorRefSecondary60] = {pink.get(60)};
  mixer[ui::kColorRefSecondary70] = {pink.get(70)};
  mixer[ui::kColorRefSecondary80] = {pink.get(80)};
  mixer[ui::kColorRefSecondary90] = {pink.get(90)};
  mixer[ui::kColorRefSecondary95] = {pink.get(95)};
  mixer[ui::kColorRefSecondary99] = {pink.get(99)};
  mixer[ui::kColorRefSecondary100] = {pink.get(100)};
}
