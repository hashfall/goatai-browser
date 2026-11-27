// Copyright 2026 Goatai. All rights reserved.
// Use of this source code is governed by a BSD-style license.

#ifndef CHROME_BROWSER_UI_VIEWS_FRAME_GOATAI_TAB_DRAG_CHIP_H_
#define CHROME_BROWSER_UI_VIEWS_FRAME_GOATAI_TAB_DRAG_CHIP_H_

#include <memory>

#include "base/memory/raw_ptr.h"

namespace content {
class WebContents;
}
namespace gfx {
class Point;
}
namespace views {
class View;
class Widget;
}

// Pequeno "chip" com o favicon da aba seguindo o cursor durante o arrasto.
class GoataiTabDragChip {
 public:
  static GoataiTabDragChip* Get();

  void Show(views::Widget* parent_widget,
            content::WebContents* contents,
            const gfx::Point& screen_point);
  void MoveTo(const gfx::Point& screen_point);
  void Hide();

  GoataiTabDragChip() = default;
  ~GoataiTabDragChip();

 private:

  raw_ptr<views::View> host_ = nullptr;
  raw_ptr<views::View> chip_ = nullptr;
  raw_ptr<content::WebContents> contents_ = nullptr;
};

#endif  // CHROME_BROWSER_UI_VIEWS_FRAME_GOATAI_TAB_DRAG_CHIP_H_
