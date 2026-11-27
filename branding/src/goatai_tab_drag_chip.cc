// Copyright 2026 Goatai. All rights reserved.
// Use of this source code is governed by a BSD-style license.

#include "chrome/browser/ui/views/frame/goatai_tab_drag_chip.h"

#include "base/no_destructor.h"
#include "chrome/app/vector_icons/vector_icons.h"
#include "chrome/browser/ui/views/frame/browser_view.h"
#include "components/favicon/content/content_favicon_driver.h"
#include "content/public/browser/web_contents.h"
#include "ui/base/models/image_model.h"
#include "ui/color/color_id.h"
#include "ui/gfx/image/image.h"
#include "ui/views/background.h"
#include "ui/views/controls/image_view.h"
#include "ui/views/layout/box_layout.h"
#include "ui/views/view_class_properties.h"

namespace {

constexpr int kChipSize = 36;
constexpr int kChipOffset = 14;

class ChipView : public views::View {
 public:
  ChipView() {
    auto layout = std::make_unique<views::BoxLayout>(
        views::BoxLayout::Orientation::kVertical, gfx::Insets(8));
    layout->set_main_axis_alignment(
        views::BoxLayout::MainAxisAlignment::kCenter);
    layout->set_cross_axis_alignment(
        views::BoxLayout::CrossAxisAlignment::kCenter);
    SetLayoutManager(std::move(layout));
    SetBackground(views::CreateRoundedRectBackground(
        SkColorSetARGB(0xE6, 0x20, 0x21, 0x24), 10));
    image_ = AddChildView(std::make_unique<views::ImageView>());
    image_->SetImage(ui::ImageModel::FromVectorIcon(kGlobeIcon, ui::kColorIcon,
                                                    20));
  }

  void SetFavicon(const gfx::Image& favicon) {
    if (!favicon.IsEmpty()) {
      image_->SetImage(ui::ImageModel::FromImage(favicon));
    } else {
      image_->SetImage(
          ui::ImageModel::FromVectorIcon(kGlobeIcon, ui::kColorIcon, 20));
    }
  }

 private:
  raw_ptr<views::ImageView> image_ = nullptr;
};

}  // namespace

GoataiTabDragChip* GoataiTabDragChip::Get() {
  static base::NoDestructor<GoataiTabDragChip> chip;
  return chip.get();
}

GoataiTabDragChip::~GoataiTabDragChip() { Hide(); }

void GoataiTabDragChip::Show(views::Widget* parent_widget,
                             content::WebContents* contents,
                             const gfx::Point& screen_point) {
  if (!parent_widget) {
    return;
  }
  BrowserView* browser_view = BrowserView::GetBrowserViewForNativeWindow(
      parent_widget->GetNativeWindow());
  if (!browser_view) {
    return;
  }

  if (!chip_) {
    std::unique_ptr<views::View> chip = std::make_unique<ChipView>();
    chip_ = browser_view->AddChildView(std::move(chip));
    chip_->SetProperty(views::kViewIgnoredByLayoutKey, true);
    chip_->SetPaintToLayer();
    chip_->SetVisible(false);
  }

  if (contents != contents_) {
    contents_ = contents;
    if (contents) {
      if (auto* driver =
              favicon::ContentFaviconDriver::FromWebContents(contents)) {
        static_cast<ChipView*>(chip_.get())->SetFavicon(driver->GetFavicon());
      } else {
        static_cast<ChipView*>(chip_.get())->SetFavicon(gfx::Image());
      }
    }
  }

  MoveTo(screen_point);
  chip_->SetVisible(true);
}

void GoataiTabDragChip::MoveTo(const gfx::Point& screen_point) {
  if (!chip_ || !chip_->parent()) {
    return;
  }
  gfx::Point local = screen_point;
  views::View::ConvertPointFromScreen(chip_->parent(), &local);
  chip_->SetBounds(local.x() + kChipOffset, local.y() + kChipOffset, kChipSize,
                   kChipSize);
}

void GoataiTabDragChip::Hide() {
  contents_ = nullptr;
  if (chip_) {
    if (views::View* parent = chip_->parent()) {
      parent->RemoveChildViewT(chip_);
    }
    chip_ = nullptr;
  }
  host_ = nullptr;
}
