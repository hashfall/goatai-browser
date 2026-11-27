// Copyright 2026 Goatai. All rights reserved.
// Use of this source code is governed by a BSD-style license.

#include "chrome/browser/ui/views/frame/vertical_tab_strip_folder_bar.h"

#include "chrome/browser/ui/views/frame/vertical_tab_strip_region_view.h"
#include "chrome/browser/ui/views/tabs/dragging/drag_session_data.h"
#include "chrome/browser/ui/views/tabs/dragging/tab_drag_context.h"
#include "chrome/browser/ui/views/tabs/vertical/vertical_tab_strip_expand_on_hover_lock.h"

#include <algorithm>
#include <memory>
#include <set>
#include <utility>
#include <vector>

#include "base/functional/bind.h"
#include "base/hash/hash.h"
#include "base/location.h"
#include "base/strings/string_number_conversions.h"
#include "base/strings/string_util.h"
#include "base/strings/utf_string_conversions.h"
#include "base/task/sequenced_task_runner.h"
#include "chrome/browser/bookmarks/bookmark_model_factory.h"
#include "chrome/browser/profiles/profile.h"
#include "chrome/browser/ui/browser_window/public/browser_window_interface.h"
#include "chrome/browser/ui/color/chrome_color_id.h"
#include "chrome/browser/ui/tabs/tab_strip_model.h"
#include "components/bookmarks/browser/bookmark_model.h"
#include "components/bookmarks/browser/bookmark_node.h"
#include "components/bookmarks/browser/bookmark_node_data.h"
#include "components/bookmarks/common/bookmark_metrics.h"
#include "content/public/browser/web_contents.h"
#include "cc/paint/paint_flags.h"
#include "content/public/browser/page_navigator.h"
#include "ui/accessibility/ax_enums.mojom.h"
#include "ui/base/clipboard/clipboard_format_type.h"
#include "ui/base/dragdrop/drag_drop_types.h"
#include "ui/base/dragdrop/mojom/drag_drop_types.mojom.h"
#include "ui/base/dragdrop/os_exchange_data.h"
#include "ui/base/mojom/menu_source_type.mojom.h"
#include "ui/base/mojom/window_open_disposition.mojom.h"
#include "ui/menus/simple_menu_model.h"
#include "ui/color/color_id.h"
#include "ui/color/color_provider.h"
#include "ui/base/models/image_model.h"
#include "ui/gfx/canvas.h"
#include "ui/gfx/color_palette.h"
#include "ui/gfx/image/canvas_image_source.h"
#include "ui/gfx/font_list.h"
#include "ui/gfx/geometry/rounded_corners_f.h"
#include "ui/gfx/image/image.h"
#include "ui/gfx/image/image_skia.h"
#include "ui/compositor/layer_tree_owner.h"
#include "ui/views/accessibility/view_accessibility.h"
#include "ui/views/controls/menu/menu_runner.h"
#include "ui/views/controls/menu/menu_types.h"
#include "ui/views/widget/widget.h"

namespace {

constexpr int kTileSize = 32;
constexpr int kGap = 8;
constexpr int kBarVPadding = 6;
constexpr int kIconSize = 20;
constexpr char16_t kRootFolderName[] = u"Goatai Pins";
constexpr char kFolderColorMetaKey[] = "goatai.color";

struct GoataiFolderColor {
  tab_groups::TabGroupColorId id;
  const char* key;
  SkColor color;
};

constexpr GoataiFolderColor kFolderColors[] = {
    {tab_groups::TabGroupColorId::kGrey, "grey", gfx::kGoogleGrey600},
    {tab_groups::TabGroupColorId::kBlue, "blue", gfx::kGoogleBlue600},
    {tab_groups::TabGroupColorId::kRed, "red", gfx::kGoogleRed600},
    {tab_groups::TabGroupColorId::kYellow, "yellow", gfx::kGoogleYellow600},
    {tab_groups::TabGroupColorId::kGreen, "green", gfx::kGoogleGreen600},
    {tab_groups::TabGroupColorId::kPink, "pink", gfx::kGooglePink600},
    {tab_groups::TabGroupColorId::kPurple, "purple", gfx::kGooglePurple600},
    {tab_groups::TabGroupColorId::kCyan, "cyan", gfx::kGoogleCyan600},
    {tab_groups::TabGroupColorId::kOrange, "orange", gfx::kGoogleOrange600},
};

class ColorDotSource : public gfx::CanvasImageSource {
 public:
  ColorDotSource(SkColor color, bool selected)
      : gfx::CanvasImageSource(gfx::Size(16, 16)),
        color_(color),
        selected_(selected) {}

  void Draw(gfx::Canvas* canvas) override {
    cc::PaintFlags fill;
    fill.setAntiAlias(true);
    fill.setColor(color_);
    canvas->DrawCircle(gfx::PointF(8.0f, 8.0f), 7.0f, fill);
    if (selected_) {
      cc::PaintFlags stroke;
      stroke.setAntiAlias(true);
      stroke.setStyle(cc::PaintFlags::kStroke_Style);
      stroke.setStrokeWidth(1.6f);
      stroke.setColor(SK_ColorWHITE);
      canvas->DrawLine(gfx::PointF(4.5f, 8.0f), gfx::PointF(7.0f, 10.5f),
                       stroke);
      canvas->DrawLine(gfx::PointF(7.0f, 10.5f), gfx::PointF(11.5f, 5.5f),
                       stroke);
    }
  }

 private:
  SkColor color_;
  bool selected_;
};

ui::ImageModel ColorDot(SkColor color, bool selected) {
  return ui::ImageModel::FromImageSkia(
      gfx::CanvasImageSource::MakeImageSkia<ColorDotSource>(color, selected));
}

const char* KeyForFolderColor(tab_groups::TabGroupColorId id) {
  for (const auto& entry : kFolderColors) {
    if (entry.id == id) {
      return entry.key;
    }
  }
  return nullptr;
}

SkColor ColorForFolder(const bookmarks::BookmarkNode* node,
                       SkColor fallback) {
  std::string value;
  if (!node || !node->GetMetaInfo(kFolderColorMetaKey, &value)) {
    return fallback;
  }
  for (const auto& entry : kFolderColors) {
    if (value == entry.key) {
      return entry.color;
    }
  }
  return fallback;
}

int SelectedColorCommand(const bookmarks::BookmarkNode* node) {
  std::string value;
  if (!node || !node->GetMetaInfo(kFolderColorMetaKey, &value)) {
    return 0;
  }
  for (size_t i = 0; i < std::size(kFolderColors); ++i) {
    if (value == kFolderColors[i].key) {
      return static_cast<int>(i) + 1;
    }
  }
  return 0;
}

using bookmarks::BookmarkModel;
using bookmarks::BookmarkNode;

bool IsDescendant(const BookmarkNode* node, const BookmarkNode* maybe_parent) {
  for (const BookmarkNode* p = maybe_parent; p; p = p->parent()) {
    if (p == node) {
      return true;
    }
  }
  return false;
}

std::u16string LabelForNode(const BookmarkNode* node) {
  return node->is_folder() ? node->GetTitle() : node->GetTitle();
}

// Ações de um pin solto.
class PinMenuDelegate : public ui::SimpleMenuModel::Delegate {
 public:
  PinMenuDelegate(VerticalTabStripFolderBar* bar, const BookmarkNode* node)
      : bar_(bar), node_(node) {}

  void ExecuteCommand(int command_id, int event_flags) override {
    if (!bar_ || !node_) {
      return;
    }
    if (command_id == 0) {
      bar_->OpenBookmark(node_);
    } else if (command_id == 1) {
      bar_->RemovePin(node_);
    }
  }

 private:
  raw_ptr<VerticalTabStripFolderBar> bar_;
  raw_ptr<const BookmarkNode> node_;
};

// Lista de pins para remover de um folder.
class RemovePinMenuDelegate : public ui::SimpleMenuModel::Delegate {
 public:
  RemovePinMenuDelegate(
      VerticalTabStripFolderBar* bar,
      std::vector<raw_ptr<const BookmarkNode>> nodes)
      : bar_(bar), nodes_(std::move(nodes)) {}

  void ExecuteCommand(int command_id, int event_flags) override {
    if (bar_ && command_id >= 0 &&
        command_id < static_cast<int>(nodes_.size())) {
      bar_->RemovePin(nodes_[command_id]);
    }
  }

 private:
  raw_ptr<VerticalTabStripFolderBar> bar_;
  std::vector<raw_ptr<const BookmarkNode>> nodes_;
};

// Submenu de cor do folder.
class FolderColorMenuDelegate : public ui::SimpleMenuModel::Delegate {
 public:
  FolderColorMenuDelegate(VerticalTabStripFolderBar* bar,
                          const BookmarkNode* node,
                          int selected)
      : bar_(bar), node_(node), selected_(selected) {}

  void ExecuteCommand(int command_id, int event_flags) override {
    if (!bar_ || !node_) {
      return;
    }
    if (command_id == 0) {
      bar_->SetFolderColor(node_, std::nullopt);
    } else {
      bar_->SetFolderColor(
          node_, static_cast<tab_groups::TabGroupColorId>(command_id - 1));
    }
  }

  bool IsCommandIdChecked(int command_id) const override {
    return command_id == selected_;
  }

 private:
  raw_ptr<VerticalTabStripFolderBar> bar_;
  raw_ptr<const BookmarkNode> node_;
  int selected_ = 0;
};

// Delega cliques de um menu simples para nós de bookmark.
class NodeMenuDelegate : public ui::SimpleMenuModel::Delegate {
 public:
  NodeMenuDelegate(VerticalTabStripFolderBar* bar,
                   std::vector<raw_ptr<const BookmarkNode>> nodes)
      : bar_(bar), nodes_(std::move(nodes)) {}

  void ExecuteCommand(int command_id, int event_flags) override {
    if (bar_ && command_id >= 0 &&
        command_id < static_cast<int>(nodes_.size())) {
      const bookmarks::BookmarkNode* node = nodes_[command_id];
      if (node->is_folder()) {
        bar_->OpenAllInFolder(node);
      } else {
        bar_->OpenBookmark(node);
      }
    }
  }

 private:
  raw_ptr<VerticalTabStripFolderBar> bar_;
  std::vector<raw_ptr<const BookmarkNode>> nodes_;
};

class BarMenuDelegate : public ui::SimpleMenuModel::Delegate {
 public:
  explicit BarMenuDelegate(VerticalTabStripFolderBar* bar) : bar_(bar) {}
  void ExecuteCommand(int command_id, int event_flags) override {
    if (!bar_) {
      return;
    }
    switch (command_id) {
      case kNewFolder:
        bar_->CreateFolder();
        break;
      case kPinCurrent:
        bar_->PinCurrentPage();
        break;
    }
  }
  enum Command { kNewFolder, kPinCurrent };

 private:
  raw_ptr<VerticalTabStripFolderBar> bar_;
};

class NodeContextMenuDelegate : public ui::SimpleMenuModel::Delegate {
 public:
  NodeContextMenuDelegate(VerticalTabStripFolderBar* bar,
                          const BookmarkNode* node)
      : bar_(bar), node_(node) {}
  enum Command { kOpenAll, kPinHere, kDelete };
  void ExecuteCommand(int command_id, int event_flags) override {
    if (!bar_ || !node_) {
      return;
    }
    switch (command_id) {
      case kOpenAll:
        bar_->OpenAllInFolder(node_);
        break;
      case kPinHere:
        bar_->PinCurrentPageTo(node_);
        break;
      case kDelete:
        bar_->DeleteFolder(node_);
        break;
    }
  }

 private:
  raw_ptr<VerticalTabStripFolderBar> bar_;
  raw_ptr<const BookmarkNode> node_;
};

}  // namespace

// ---------------------------------------------------------------------------
// Tiles

class GoataiBaseTile : public views::View,
                      public views::ContextMenuController {
 public:
  GoataiBaseTile(VerticalTabStripFolderBar* bar, const BookmarkNode* node)
      : bar_(bar), node_(node) {
    set_context_menu_controller(this);
    SetAccessibleRole(ax::mojom::Role::kButton);
    GetViewAccessibility().SetName(LabelForNode(node));
    SetTooltipText(LabelForNode(node));
  }

  gfx::Size CalculatePreferredSize(
      const views::SizeBounds& available_size) const override {
    return gfx::Size(kTileSize, kTileSize);
  }

  void OnThemeChanged() override {
    views::View::OnThemeChanged();
    SchedulePaint();
  }

  bool OnMousePressed(const ui::MouseEvent& event) override {
    if (!event.IsOnlyLeftMouseButton()) {
      return false;
    }
    pressed_ = true;
    return true;
  }

  void OnMouseReleased(const ui::MouseEvent& event) override {
    if (pressed_ && event.IsOnlyLeftMouseButton() &&
        HitTestPoint(event.location())) {
      Activate();
    }
    pressed_ = false;
  }

  void OnMouseEntered(const ui::MouseEvent& event) override {
    hovered_ = true;
    SchedulePaint();
  }

  void OnMouseExited(const ui::MouseEvent& event) override {
    hovered_ = false;
    SchedulePaint();
  }

  const bookmarks::BookmarkNode* GetNode() const { return node_; }
  virtual bool AcceptsTabDrop() const { return false; }
  virtual void SetTabDropHovered(bool hovered) {}

  int GetDragOperations(const gfx::Point& press_pt) override {
    if (!node_ || node_->is_folder()) {
      return ui::DragDropTypes::DRAG_NONE;
    }
    return ui::DragDropTypes::DRAG_MOVE | ui::DragDropTypes::DRAG_COPY;
  }

  void WriteDragData(const gfx::Point& press_pt,
                     ui::OSExchangeData* data) override {
    if (!node_) {
      return;
    }
    bookmarks::BookmarkNodeData(node_).Write(bar_->profile()->GetPath(), data);
  }

 protected:
  virtual void Activate() = 0;
  virtual void PaintContent(gfx::Canvas* canvas, const gfx::Rect& content) = 0;
  virtual void ShowContextMenu(const gfx::Point& point) {}

  // views::ContextMenuController:
  void ShowContextMenuForViewImpl(views::View* source,
                                  const gfx::Point& point,
                                  ui::mojom::MenuSourceType source_type) override {
    gfx::Point local = point;
    ConvertPointFromScreen(this, &local);
    ShowContextMenu(local);
  }

  void OnPaint(gfx::Canvas* canvas) override {
    const gfx::Rect bounds = GetLocalBounds();
    if (hovered_ || drop_hovered_) {
      cc::PaintFlags flags;
      flags.setAntiAlias(true);
      flags.setColor(drop_hovered_
                         ? SkColorSetA(bar_->GetColorProvider()->GetColor(
                                           ui::kColorAccent),
                                       0x66)
                         : SkColorSetA(SK_ColorWHITE, 0x24));
      canvas->DrawRoundRect(bounds, 8, flags);
    }
    PaintContent(canvas, bounds);
  }

  raw_ptr<VerticalTabStripFolderBar> bar_;
  raw_ptr<const BookmarkNode> node_;
  bool hovered_ = false;
  bool pressed_ = false;
  bool drop_hovered_ = false;
};

class GoataiPinTile : public GoataiBaseTile {
 public:
  GoataiPinTile(VerticalTabStripFolderBar* bar, const BookmarkNode* node)
      : GoataiBaseTile(bar, node) {}

 protected:
  void Activate() override { bar_->OpenBookmark(node_); }

  void ShowContextMenu(const gfx::Point& point) override {
    pin_menu_delegate_ = std::make_unique<PinMenuDelegate>(bar_, node_);
    pin_menu_ = std::make_unique<ui::SimpleMenuModel>(pin_menu_delegate_.get());
    pin_menu_->AddItem(0, u"Open");
    pin_menu_->AddSeparator(ui::NORMAL_SEPARATOR);
    pin_menu_->AddItem(1, u"Remove pin");
    pin_menu_runner_ = std::make_unique<views::MenuRunner>(
        pin_menu_.get(), views::MenuRunner::HAS_MNEMONICS);
    auto lock = bar_->AcquireKeepExpandedLock();
    pin_menu_runner_->RunMenuAt(GetWidget(), nullptr,
                                gfx::Rect(point, gfx::Size()),
                                views::MenuAnchorPosition::kTopLeft,
                                ui::mojom::MenuSourceType::kMouse);
  }

  void PaintContent(gfx::Canvas* canvas, const gfx::Rect& content) override {
    const gfx::Image& favicon = bar_->model()->GetFavicon(node_);
    if (!favicon.IsEmpty()) {
      const int x = content.x() + (content.width() - kIconSize) / 2;
      const int y = content.y() + (content.height() - kIconSize) / 2;
      const gfx::ImageSkia image = favicon.AsImageSkia();
      canvas->DrawImageInt(image, 0, 0, image.width(), image.height(), x, y,
                           kIconSize, kIconSize, false);
      return;
    }
    static constexpr SkColor kFallbackColors[] = {
        SkColorSetRGB(0x7C, 0x3A, 0xED), SkColorSetRGB(0xE9, 0x1E, 0x63),
        SkColorSetRGB(0x25, 0x63, 0xEB), SkColorSetRGB(0xDB, 0x27, 0x77),
        SkColorSetRGB(0x0D, 0x94, 0x88), SkColorSetRGB(0xF5, 0x9E, 0x0B)};
    const std::u16string title = node_->GetTitle();
    const std::u16string letter = title.empty() ? u"?" : title.substr(0, 1);
    cc::PaintFlags bg;
    bg.setAntiAlias(true);
    bg.setColor(kFallbackColors[base::PersistentHash(node_->url().spec()) %
                                std::size(kFallbackColors)]);
    const gfx::Point center = content.CenterPoint();
    canvas->DrawCircle(center, 11, bg);
    gfx::FontList font({"sans-serif"}, gfx::Font::NORMAL, 12,
                       gfx::Font::Weight::BOLD);
    canvas->DrawStringRectWithFlags(letter, font, SK_ColorWHITE, content,
                                    gfx::Canvas::TEXT_ALIGN_CENTER);
  }

 private:
  std::unique_ptr<PinMenuDelegate> pin_menu_delegate_;
  std::unique_ptr<ui::SimpleMenuModel> pin_menu_;
  std::unique_ptr<views::MenuRunner> pin_menu_runner_;
};

class GoataiFolderTile : public GoataiBaseTile {
 public:
  GoataiFolderTile(VerticalTabStripFolderBar* bar, const BookmarkNode* node)
      : GoataiBaseTile(bar, node) {}

  // --- Drop target -------------------------------------------------------
  bool GetDropFormats(
      int* formats,
      std::set<ui::ClipboardFormatType>* format_types) override {
    *formats = ui::OSExchangeData::URL;
    format_types->insert(ui::ClipboardFormatType::BookmarkEntriesType());
    return true;
  }
  bool AreDropTypesRequired() override { return true; }

  bool CanDrop(const ui::OSExchangeData& data) override {
    bookmarks::BookmarkNodeData drag_data;
    if (!drag_data.Read(data)) {
      return false;
    }
    const BookmarkNode* dragged = drag_data.GetFirstNode(
        bar_->model(), bar_->profile()->GetPath());
    if (!dragged || dragged == node_) {
      return false;
    }
    // Não permitir mover uma pasta para dentro dela mesma.
    return !IsDescendant(dragged, node_);
  }

  void OnDragEntered(const ui::DropTargetEvent& event) override {
    drop_hovered_ = true;
    SchedulePaint();
  }
  int OnDragUpdated(const ui::DropTargetEvent& event) override {
    return ui::DragDropTypes::DRAG_MOVE;
  }
  void OnDragExited() override {
    drop_hovered_ = false;
    SchedulePaint();
  }
  DropCallback GetDropCallback(const ui::DropTargetEvent& event) override {
    drop_hovered_ = false;
    bookmarks::BookmarkNodeData drag_data;
    if (!drag_data.Read(event.data())) {
      return DropCallback();
    }
    const BookmarkNode* dragged = drag_data.GetFirstNode(
        bar_->model(), bar_->profile()->GetPath());
    if (!dragged || dragged == node_ || IsDescendant(dragged, node_)) {
      return DropCallback();
    }
    VerticalTabStripFolderBar* bar = bar_.get();
    const BookmarkNode* target = node_;
    return base::BindOnce(
        [](VerticalTabStripFolderBar* bar, const BookmarkNode* node,
           const BookmarkNode* folder, const ui::DropTargetEvent& event,
           ui::mojom::DragOperation& output,
           std::unique_ptr<ui::LayerTreeOwner> layer_owner) {
          bar->MoveInto(node, folder);
          output = ui::mojom::DragOperation::kMove;
        },
        bar, dragged, target);
  }

  bool AcceptsTabDrop() const override { return true; }
  void SetTabDropHovered(bool hovered) override {
    drop_hovered_ = hovered;
    SchedulePaint();
  }

 protected:
  void Activate() override { ShowMenu(); }

  void ShowContextMenu(const gfx::Point& point) override {
    node_menu_delegate_ = std::make_unique<NodeContextMenuDelegate>(bar_, node_);
    menu_model_ = std::make_unique<ui::SimpleMenuModel>(node_menu_delegate_.get());
    menu_model_->AddItem(NodeContextMenuDelegate::kOpenAll, u"Open all");
    menu_model_->AddItem(NodeContextMenuDelegate::kPinHere,
                         u"Pin current tab here");

    color_menu_delegate_ = std::make_unique<FolderColorMenuDelegate>(
        bar_, node_, SelectedColorCommand(node_));
    color_submenu_ = std::make_unique<ui::SimpleMenuModel>(
        color_menu_delegate_.get());
    const int selected = SelectedColorCommand(node_);
    color_submenu_->AddItemWithIcon(
        0, u"Default",
        ColorDot(gfx::kGoogleGrey500, selected == 0));
    const auto& labels = tab_groups::GetTabGroupColorLabelMap();
    for (const auto& entry : kFolderColors) {
      const int command = static_cast<int>(entry.id) + 1;
      const auto it = labels.find(entry.id);
      color_submenu_->AddItemWithIcon(
          command, it != labels.end() ? it->second : std::u16string(),
          ColorDot(entry.color, selected == command));
    }
    menu_model_->AddSubMenu(100, u"Color", color_submenu_.get());

    std::vector<raw_ptr<const BookmarkNode>> pins;
    for (const auto& child : node_->children()) {
      if (child->is_url()) {
        pins.emplace_back(child.get());
      }
    }
    if (!pins.empty()) {
      remove_menu_delegate_ =
          std::make_unique<RemovePinMenuDelegate>(bar_, pins);
      remove_submenu_ = std::make_unique<ui::SimpleMenuModel>(
          remove_menu_delegate_.get());
      for (size_t i = 0; i < pins.size(); ++i) {
        remove_submenu_->AddItem(static_cast<int>(i),
                                 pins[i]->GetTitle());
      }
      menu_model_->AddSubMenu(101, u"Remove pin", remove_submenu_.get());
    }

    menu_model_->AddSeparator(ui::NORMAL_SEPARATOR);
    menu_model_->AddItem(NodeContextMenuDelegate::kDelete, u"Delete folder");
    menu_runner_ = std::make_unique<views::MenuRunner>(
        menu_model_.get(), views::MenuRunner::HAS_MNEMONICS);
    auto lock = bar_->AcquireKeepExpandedLock();
    menu_runner_->RunMenuAt(GetWidget(), nullptr,
                            gfx::Rect(point, gfx::Size()),
                            views::MenuAnchorPosition::kTopLeft,
                            ui::mojom::MenuSourceType::kMouse);
  }

  void PaintContent(gfx::Canvas* canvas, const gfx::Rect& content) override {
    cc::PaintFlags flags;
    flags.setAntiAlias(true);
    flags.setStyle(cc::PaintFlags::kStroke_Style);
    flags.setStrokeWidth(1.6f);
    flags.setColor(ColorForFolder(
        node_, bar_->GetColorProvider()->GetColor(kColorToolbarButtonIcon)));
    const gfx::RectF body(content.x() + 5.0f, content.y() + 9.0f,
                          content.width() - 10.0f, content.height() - 14.0f);
    canvas->DrawRoundRect(body, 2.5f, flags);
    canvas->DrawLine(gfx::Point(content.x() + 8, content.y() + 9),
                     gfx::Point(content.x() + 12, content.y() + 5), flags);
    canvas->DrawLine(gfx::Point(content.x() + 12, content.y() + 5),
                     gfx::Point(content.x() + 19, content.y() + 5), flags);
    canvas->DrawLine(gfx::Point(content.x() + 19, content.y() + 5),
                     gfx::Point(content.x() + 22, content.y() + 9), flags);
  }

  void ShowMenu() {
    auto delegate = std::make_unique<NodeMenuDelegate>(
        bar_, std::vector<raw_ptr<const BookmarkNode>>{});
    auto model = std::make_unique<ui::SimpleMenuModel>(delegate.get());
    if (node_->children().empty()) {
      model->AddItem(0, u"Empty folder");
      model->SetEnabledAt(0, false);
    } else {
      for (size_t i = 0; i < node_->children().size(); ++i) {
        const BookmarkNode* child = node_->children()[i].get();
        model->AddItem(static_cast<int>(i),
                       child->is_folder()
                           ? (child->GetTitle() + u" (folder)")
                           : child->GetTitle());
      }
    }
    menu_delegate_ = std::move(delegate);
    menu_model_ = std::move(model);
    menu_runner_ = std::make_unique<views::MenuRunner>(
        menu_model_.get(), views::MenuRunner::HAS_MNEMONICS);
    auto lock = bar_->AcquireKeepExpandedLock();
    menu_runner_->RunMenuAt(GetWidget(), nullptr, GetLocalBounds(),
                            views::MenuAnchorPosition::kTopLeft,
                            ui::mojom::MenuSourceType::kMouse);
  }

 private:
  std::unique_ptr<NodeMenuDelegate> menu_delegate_;
  std::unique_ptr<NodeContextMenuDelegate> node_menu_delegate_;
  std::unique_ptr<FolderColorMenuDelegate> color_menu_delegate_;
  std::unique_ptr<ui::SimpleMenuModel> color_submenu_;
  std::unique_ptr<RemovePinMenuDelegate> remove_menu_delegate_;
  std::unique_ptr<ui::SimpleMenuModel> remove_submenu_;
  std::unique_ptr<ui::SimpleMenuModel> menu_model_;
  std::unique_ptr<views::MenuRunner> menu_runner_;
};

class GoataiNewFolderTile : public GoataiBaseTile {
 public:
  GoataiNewFolderTile(VerticalTabStripFolderBar* bar, const BookmarkNode* root)
      : GoataiBaseTile(bar, root) {
    GetViewAccessibility().SetName(u"New folder");
    SetTooltipText(u"New folder");
  }

 protected:
  void Activate() override { bar_->CreateFolder(); }

  void PaintContent(gfx::Canvas* canvas, const gfx::Rect& content) override {
    cc::PaintFlags flags;
    flags.setAntiAlias(true);
    flags.setStyle(cc::PaintFlags::kStroke_Style);
    flags.setStrokeWidth(1.6f);
    flags.setColor(ColorForFolder(
        node_, bar_->GetColorProvider()->GetColor(kColorToolbarButtonIcon)));
    const gfx::RectF body(content.x() + 5.0f, content.y() + 9.0f,
                          content.width() - 10.0f, content.height() - 14.0f);
    canvas->DrawRoundRect(body, 2.5f, flags);
    canvas->DrawLine(gfx::Point(content.x() + 8, content.y() + 9),
                     gfx::Point(content.x() + 12, content.y() + 5), flags);
    canvas->DrawLine(gfx::Point(content.x() + 12, content.y() + 5),
                     gfx::Point(content.x() + 19, content.y() + 5), flags);
    canvas->DrawLine(gfx::Point(content.x() + 19, content.y() + 5),
                     gfx::Point(content.x() + 22, content.y() + 9), flags);
    // "+" no canto inferior direito.
    const gfx::Point c(content.CenterPoint());
    canvas->DrawLine(gfx::Point(c.x() - 1, c.y() + 5),
                     gfx::Point(c.x() + 7, c.y() + 5), flags);
    canvas->DrawLine(gfx::Point(c.x() + 3, c.y() + 1),
                     gfx::Point(c.x() + 3, c.y() + 9), flags);
  }

  void ShowContextMenu(const gfx::Point& point) override {
    bar_->ShowBarContextMenu(this, point);
  }
};

// ---------------------------------------------------------------------------
// Bar

VerticalTabStripFolderBar::VerticalTabStripFolderBar(
    Profile* profile,
    BrowserWindowInterface* browser)
    : profile_(profile), browser_(browser) {
  SetNotifyEnterExitOnChild(true);
  set_context_menu_controller(this);
  model_ = BookmarkModelFactory::GetForBrowserContext(profile_);
  if (model_) {
    model_->AddObserver(this);
  }
  EnsureRootFolder();
  Rebuild();
}

VerticalTabStripFolderBar::~VerticalTabStripFolderBar() {
  on_will_destroy_callback_list_.Notify();
  if (model_) {
    model_->RemoveObserver(this);
  }
}

void VerticalTabStripFolderBar::EnsureRootFolder() {
  if (!model_ || !model_->loaded() || root_) {
    return;
  }
  const BookmarkNode* other = model_->other_node();
  for (const auto& child : other->children()) {
    if (child->is_folder() && child->GetTitle() == kRootFolderName) {
      root_ = child.get();
      return;
    }
  }
  root_ = model_->AddFolder(other, other->children().size(), kRootFolderName);
}

void VerticalTabStripFolderBar::Rebuild() {
  if (rebuilding_) {
    return;
  }
  rebuilding_ = true;
  RemoveAllChildViews();
  root_ = nullptr;
  EnsureRootFolder();
  if (root_) {
    for (const auto& child : root_->children()) {
      if (child->is_folder()) {
        std::unique_ptr<views::View> tile =
            std::make_unique<GoataiFolderTile>(this, child.get());
        AddChildView(std::move(tile));
      }
    }
    for (const auto& child : root_->children()) {
      if (!child->is_folder()) {
        std::unique_ptr<views::View> tile =
            std::make_unique<GoataiPinTile>(this, child.get());
        AddChildView(std::move(tile));
      }
    }
    std::unique_ptr<views::View> new_tile =
        std::make_unique<GoataiNewFolderTile>(this, root_);
    AddChildView(std::move(new_tile));
  }
  rebuilding_ = false;
  InvalidateLayout();
  SchedulePaint();
}

void VerticalTabStripFolderBar::ScheduleRebuild() {
  if (rebuild_timer_.IsRunning()) {
    return;
  }
  rebuild_timer_.Start(
      FROM_HERE, base::Milliseconds(30),
      base::BindOnce(&VerticalTabStripFolderBar::Rebuild,
                     base::Unretained(this)));
}

gfx::Size VerticalTabStripFolderBar::CalculatePreferredSize(
    const views::SizeBounds& available_size) const {
  const int width = available_size.width().value_or(
      kTileSize + 2 * kBarVPadding);
  return gfx::Size(width, ComputeHeightForWidth(width));
}

int VerticalTabStripFolderBar::ComputeHeightForWidth(int width) const {
  const int count = static_cast<int>(children().size());
  if (count == 0) {
    return 0;
  }
  const int per_row = std::max(1, (width + kGap) / (kTileSize + kGap));
  const int rows = (count + per_row - 1) / per_row;
  return rows * kTileSize + (rows - 1) * kGap + 2 * kBarVPadding;
}

void VerticalTabStripFolderBar::Layout(PassKey) {
  const int bar_width = width();
  const int count = static_cast<int>(children().size());
  if (count == 0) {
    return;
  }
  const int per_row = std::max(1, (bar_width + kGap) / (kTileSize + kGap));
  int y = kBarVPadding;
  int index = 0;
  for (views::View* child : children()) {
    const int col = index % per_row;
    if (col == 0) {
      const int row_count = std::min(per_row, count - index);
      int x = (bar_width - (row_count * kTileSize +
                            (row_count - 1) * kGap)) / 2;
      for (int i = 0; i < row_count; ++i) {
        views::View* tile = children()[index + i];
        tile->SetBounds(x, y, kTileSize, kTileSize);
        x += kTileSize + kGap;
      }
      y += kTileSize + kGap;
    }
    ++index;
  }
}

void VerticalTabStripFolderBar::OnThemeChanged() {
  views::View::OnThemeChanged();
  SchedulePaint();
}

void VerticalTabStripFolderBar::OnTabDragEntered() {}

TabDragContext* VerticalTabStripFolderBar::OnTabDragUpdated(
    TabDragTarget::DragController& controller,
    const gfx::Point& point_in_screen) {
  GoataiFolderTile* target = nullptr;
  for (views::View* child : children()) {
    auto* tile = static_cast<GoataiBaseTile*>(child);
    if (tile->AcceptsTabDrop() &&
        child->GetBoundsInScreen().Contains(point_in_screen)) {
      target = static_cast<GoataiFolderTile*>(child);
      break;
    }
  }
  for (views::View* child : children()) {
    auto* tile = static_cast<GoataiBaseTile*>(child);
    if (tile->AcceptsTabDrop()) {
      tile->SetTabDropHovered(child == target);
    }
  }
  tab_drag_folder_ = target ? target->GetNode() : nullptr;
  if (auto* region = views::AsViewClass<VerticalTabStripRegionView>(
          parent() ? parent()->parent() : nullptr)) {
    if (TabDragContext* context = region->GetDragContext()) {
      return context;
    }
  }
  return const_cast<TabDragContext*>(controller.GetAttachedContext());
}

void VerticalTabStripFolderBar::OnTabDragExited(
    const gfx::Point& point_in_screen) {
  tab_drag_folder_ = nullptr;
  for (views::View* child : children()) {
    static_cast<GoataiBaseTile*>(child)->SetTabDropHovered(false);
  }
}

void VerticalTabStripFolderBar::OnTabDragEnded() {
  tab_drag_folder_ = nullptr;
  for (views::View* child : children()) {
    static_cast<GoataiBaseTile*>(child)->SetTabDropHovered(false);
  }
}

bool VerticalTabStripFolderBar::CanDropTab() {
  return tab_drag_folder_ != nullptr;
}

void VerticalTabStripFolderBar::HandleTabDrop(
    TabDragTarget::DragController& controller) {
  if (!tab_drag_folder_ || !model_) {
    return;
  }
  const DragSessionData& data = controller.GetSessionData();
  for (const TabDragData& drag : data.tab_drag_data_) {
    content::WebContents* contents = drag.contents;
    if (!contents) {
      continue;
    }
    const GURL url = contents->GetLastCommittedURL();
    if (!url.is_valid() || url.SchemeIs("chrome")) {
      continue;
    }
    bool exists = false;
    for (const auto& child : tab_drag_folder_->children()) {
      if (child->is_url() && child->url() == url) {
        exists = true;
        break;
      }
    }
    if (!exists) {
      model_->AddNewURL(tab_drag_folder_,
                        tab_drag_folder_->children().size(),
                        contents->GetTitle(), url);
    }
  }
  OnTabDragEnded();
}

base::CallbackListSubscription
VerticalTabStripFolderBar::RegisterWillDestroyCallback(
    base::OnceClosure callback) {
  return on_will_destroy_callback_list_.Add(std::move(callback));
}

std::unique_ptr<ExpandOnHoverLock>
VerticalTabStripFolderBar::AcquireKeepExpandedLock() {
  auto* region = views::AsViewClass<VerticalTabStripRegionView>(
      parent() ? parent()->parent() : nullptr);
  if (!region) {
    return nullptr;
  }
  return region->GetExpandOnHoverLock(ExpandOnHoverLockType::kKeepExpanded);
}

void VerticalTabStripFolderBar::OpenBookmark(const BookmarkNode* node) {
  if (!node || !node->is_url() || !browser_) {
    return;
  }
  content::OpenURLParams params =
      content::OpenURLParams::CreateBrowserInitiated(
          node->url(), ui::mojom::WindowOpenDisposition::kNewForegroundTab,
          ui::PAGE_TRANSITION_AUTO_BOOKMARK);
  browser_->OpenURL(params, /*navigation_handle_callback=*/{});
}

void VerticalTabStripFolderBar::OpenAllInFolder(const BookmarkNode* folder) {
  if (!folder) {
    return;
  }
  for (const auto& child : folder->children()) {
    if (child->is_url()) {
      OpenBookmark(child.get());
    }
  }
}

void VerticalTabStripFolderBar::MoveInto(const BookmarkNode* node,
                                         const BookmarkNode* folder) {
  if (!model_ || !node || !folder || node == folder ||
      IsDescendant(node, folder)) {
    return;
  }
  model_->Move(node, folder, folder->children().size());
}

void VerticalTabStripFolderBar::CreateFolder() {
  EnsureRootFolder();
  if (!root_) {
    return;
  }
  int number = 1;
  for (const auto& child : root_->children()) {
    if (child->is_folder() &&
        base::StartsWith(child->GetTitle(), u"Folder ",
                         base::CompareCase::SENSITIVE)) {
      ++number;
    }
  }
  model_->AddFolder(root_, root_->children().size(),
                    u"Folder " + base::NumberToString16(number));
}

void VerticalTabStripFolderBar::RemovePin(const BookmarkNode* node) {
  if (!model_ || !node || !node->is_url() || node == root_ ||
      !node->parent()) {
    return;
  }
  model_->Remove(node, bookmarks::metrics::BookmarkEditSource::kUser,
                 FROM_HERE);
}

void VerticalTabStripFolderBar::SetFolderColor(
    const BookmarkNode* folder,
    std::optional<tab_groups::TabGroupColorId> color) {
  if (!model_ || !folder || !folder->is_folder()) {
    return;
  }
  if (!color.has_value()) {
    model_->DeleteNodeMetaInfo(folder, kFolderColorMetaKey);
    return;
  }
  const char* key = KeyForFolderColor(color.value());
  if (key) {
    model_->SetNodeMetaInfo(folder, kFolderColorMetaKey, key);
  }
}

void VerticalTabStripFolderBar::DeleteFolder(const BookmarkNode* folder) {
  if (!model_ || !folder || folder == root_ || !folder->parent() ||
      folder->is_permanent_node()) {
    return;
  }
  model_->Remove(folder, bookmarks::metrics::BookmarkEditSource::kUser,
                 FROM_HERE);
}

void VerticalTabStripFolderBar::PinCurrentPage() {
  EnsureRootFolder();
  PinCurrentPageTo(root_);
}

void VerticalTabStripFolderBar::PinCurrentPageTo(
    const bookmarks::BookmarkNode* folder) {
  if (!folder || !folder->is_folder() || !browser_) {
    return;
  }
  content::WebContents* contents =
      browser_->GetTabStripModel()->GetActiveWebContents();
  if (!contents) {
    return;
  }
  const GURL url = contents->GetVisibleURL();
  if (!url.is_valid() || url.SchemeIs("chrome")) {
    return;
  }
  model_->AddNewURL(folder, folder->children().size(), contents->GetTitle(),
                    url);
}

void VerticalTabStripFolderBar::ShowBarContextMenu(views::View* source,
                                                   const gfx::Point& point) {
  bar_menu_delegate_ = std::make_unique<BarMenuDelegate>(this);
  bar_menu_model_ =
      std::make_unique<ui::SimpleMenuModel>(bar_menu_delegate_.get());
  bar_menu_model_->AddItem(BarMenuDelegate::kPinCurrent, u"Pin current tab");
  bar_menu_model_->AddSeparator(ui::NORMAL_SEPARATOR);
  bar_menu_model_->AddItem(BarMenuDelegate::kNewFolder, u"New folder");
  bar_menu_runner_ = std::make_unique<views::MenuRunner>(
      bar_menu_model_.get(), views::MenuRunner::HAS_MNEMONICS);
  auto lock = AcquireKeepExpandedLock();
  bar_menu_runner_->RunMenuAt(
      source->GetWidget(), nullptr, gfx::Rect(point, gfx::Size()),
      views::MenuAnchorPosition::kTopLeft, ui::mojom::MenuSourceType::kMouse);
}

void VerticalTabStripFolderBar::ShowContextMenuForViewImpl(
    views::View* source,
    const gfx::Point& point,
    ui::mojom::MenuSourceType source_type) {
  ShowBarContextMenu(source, point);
}

// --- BookmarkModelObserver ------------------------------------------------

void VerticalTabStripFolderBar::BookmarkModelLoaded(bool ids_reassigned) {
  root_ = nullptr;
  // Adicionar nós durante o callback de load viola checks do
  // BookmarkMergedSurfaceService; agenda para depois do load.
  ScheduleRebuild();
}

void VerticalTabStripFolderBar::BookmarkModelBeingDeleted() {
  model_ = nullptr;
  root_ = nullptr;
}

void VerticalTabStripFolderBar::BookmarkNodeAdded(const BookmarkNode* parent,
                                                  size_t index,
                                                  bool added_by_user) {
  ScheduleRebuild();
}

void VerticalTabStripFolderBar::BookmarkNodeRemoved(
    const BookmarkNode* parent,
    size_t old_index,
    const BookmarkNode* node,
    const std::set<GURL>& removed_urls,
    const base::Location& location) {
  if (node == root_) {
    root_ = nullptr;
  }
  ScheduleRebuild();
}

void VerticalTabStripFolderBar::BookmarkNodeChanged(const BookmarkNode* node) {
  ScheduleRebuild();
}

void VerticalTabStripFolderBar::BookmarkMetaInfoChanged(
    const BookmarkNode* node) {
  ScheduleRebuild();
}

void VerticalTabStripFolderBar::BookmarkNodeFaviconChanged(
    const BookmarkNode* node) {
  SchedulePaint();
}

void VerticalTabStripFolderBar::BookmarkNodeMoved(
    const BookmarkNode* old_parent,
    size_t old_index,
    const BookmarkNode* new_parent,
    size_t new_index) {
  ScheduleRebuild();
}

void VerticalTabStripFolderBar::BookmarkNodeChildrenReordered(
    const BookmarkNode* node) {
  ScheduleRebuild();
}

void VerticalTabStripFolderBar::BookmarkAllUserNodesRemoved(
    const std::set<GURL>& removed_urls,
    const base::Location& location) {
  root_ = nullptr;
  ScheduleRebuild();
}
