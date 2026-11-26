// Copyright 2026 Goatai. All rights reserved.
// Use of this source code is governed by a BSD-style license.

#ifndef CHROME_BROWSER_UI_COLOR_GOATAI_COLOR_MIXER_H_
#define CHROME_BROWSER_UI_COLOR_GOATAI_COLOR_MIXER_H_

#include "ui/color/color_provider_key.h"

namespace ui {
class ColorProvider;
}

// Aplica a paleta roxo/rosa do Goatai. Deve ser o último mixer adicionado
// (depois de AddNativeChromeColorMixer) para prevalecer sobre os padrões.
void AddGoataiColorMixer(ui::ColorProvider* provider,
                         const ui::ColorProviderKey& key);

#endif  // CHROME_BROWSER_UI_COLOR_GOATAI_COLOR_MIXER_H_
