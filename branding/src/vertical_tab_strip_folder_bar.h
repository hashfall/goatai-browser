// Copyright 2026 Goatai. All rights reserved.
// Use of this source code is governed by a BSD-style license.

#ifndef CHROME_BROWSER_UI_VIEWS_FRAME_VERTICAL_TAB_STRIP_FOLDER_BAR_H_
#define CHROME_BROWSER_UI_VIEWS_FRAME_VERTICAL_TAB_STRIP_FOLDER_BAR_H_

#include <memory>
#include <vector>

#include "base/callback_list.h"
#include "base/memory/raw_ptr.h"
#include "base/timer/timer.h"
#include "components/bookmarks/browser/bookmark_model_observer.h"
#include "components/tab_groups/tab_group_color.h"
#include "ui/menus/simple_menu_model.h"
#include "chrome/browser/ui/views/tabs/dragging/tab_drag_target.h"
#include "ui/views/context_menu_controller.h"
#include "ui/base/mojom/menu_source_type.mojom-forward.h"
#include "ui/views/view.h"

class BrowserWindowInterface;

namespace ui {
class SimpleMenuModel;
}  // namespace ui
class ExpandOnHoverLock;
class TabDragContext;
class Profile;
class GoataiFolderTile;
class GoataiPinTile;

namespace bookmarks {
class BookmarkModel;
class BookmarkNode;
}  // namespace bookmarks

namespace views {
class MenuRunner;
}  // namespace views

// Barra de "folders" fixada no topo da barra de abas vertical.
//
// A árvore vive no BookmarkModel, dentro da pasta "Goatai Pins" em "Outros
// favoritos": subpastas viram folders e os bookmarks soltos viram pins.
// Arrastar um pin sobre um folder move o bookmark para dentro dele.
class VerticalTabStripFolderBar : public views::View,
                                  public bookmarks::BookmarkModelObserver,
                                  public views::ContextMenuController,
                                  public TabDragTarget {
 public:
  VerticalTabStripFolderBar(Profile* profile, BrowserWindowInterface* browser);
  VerticalTabStripFolderBar(const VerticalTabStripFolderBar&) = delete;
  VerticalTabStripFolderBar& operator=(const VerticalTabStripFolderBar&) =
      delete;
  ~VerticalTabStripFolderBar() override;

  // views::View:
  gfx::Size CalculatePreferredSize(
      const views::SizeBounds& available_size) const override;
  void Layout(PassKey) override;
  void OnThemeChanged() override;

  // bookmarks::BookmarkModelObserver:
  void BookmarkModelLoaded(bool ids_reassigned) override;
  void BookmarkModelBeingDeleted() override;
  void BookmarkNodeAdded(const bookmarks::BookmarkNode* parent,
                         size_t index,
                         bool added_by_user) override;
  void BookmarkNodeRemoved(const bookmarks::BookmarkNode* parent,
                           size_t old_index,
                           const bookmarks::BookmarkNode* node,
                           const std::set<GURL>& removed_urls,
                           const base::Location& location) override;
  void BookmarkNodeChanged(const bookmarks::BookmarkNode* node) override;
  void BookmarkMetaInfoChanged(const bookmarks::BookmarkNode* node) override;
  void BookmarkNodeFaviconChanged(const bookmarks::BookmarkNode* node) override;
  void BookmarkNodeMoved(const bookmarks::BookmarkNode* old_parent,
                         size_t old_index,
                         const bookmarks::BookmarkNode* new_parent,
                         size_t new_index) override;
  void BookmarkNodeChildrenReordered(
      const bookmarks::BookmarkNode* node) override;
  void BookmarkAllUserNodesRemoved(const std::set<GURL>& removed_urls,
                                   const base::Location& location) override;

  // views::ContextMenuController:
  void ShowContextMenuForViewImpl(views::View* source,
                                  const gfx::Point& point,
                                  ui::mojom::MenuSourceType source_type) override;

  // Ações usadas pelos tiles.
  void OpenBookmark(const bookmarks::BookmarkNode* node);
  void OpenAllInFolder(const bookmarks::BookmarkNode* folder);
  void MoveInto(const bookmarks::BookmarkNode* node,
                const bookmarks::BookmarkNode* folder);
  void CreateFolder();
  void DeleteFolder(const bookmarks::BookmarkNode* folder);
  void PinCurrentPage();
  void PinCurrentPageTo(const bookmarks::BookmarkNode* folder);
  void SetFolderColor(
      const bookmarks::BookmarkNode* folder,
      std::optional<tab_groups::TabGroupColorId> color);
  void ShowBarContextMenu(views::View* source, const gfx::Point& point);

  // TabDragTarget: permite arrastar abas para dentro de um folder.
  void OnTabDragEntered() override;
  TabDragContext* OnTabDragUpdated(TabDragTarget::DragController& controller,
                                   const gfx::Point& point_in_screen) override;
  void OnTabDragExited(const gfx::Point& point_in_screen) override;
  void OnTabDragEnded() override;
  bool CanDropTab() override;
  void HandleTabDrop(TabDragTarget::DragController& controller) override;
  base::CallbackListSubscription RegisterWillDestroyCallback(
      base::OnceClosure callback) override;

  // Mantém a sidebar expandida enquanto um menu/diálogo está aberto.
  std::unique_ptr<ExpandOnHoverLock> AcquireKeepExpandedLock();

  Profile* profile() const { return profile_; }
  bookmarks::BookmarkModel* model() const { return model_; }
  const bookmarks::BookmarkNode* root_folder() const { return root_; }

 private:
  int ComputeHeightForWidth(int width) const;
  void Rebuild();
  void ScheduleRebuild();
  void EnsureRootFolder();

  raw_ptr<Profile> profile_;
  raw_ptr<BrowserWindowInterface> browser_;
  raw_ptr<bookmarks::BookmarkModel> model_ = nullptr;
  raw_ptr<const bookmarks::BookmarkNode> root_ = nullptr;
  raw_ptr<const bookmarks::BookmarkNode> tab_drag_folder_ = nullptr;
  base::OnceClosureList on_will_destroy_callback_list_;
  std::unique_ptr<ui::SimpleMenuModel::Delegate> bar_menu_delegate_;
  std::unique_ptr<ui::SimpleMenuModel> bar_menu_model_;
  std::unique_ptr<views::MenuRunner> bar_menu_runner_;
  bool rebuilding_ = false;
  base::OneShotTimer rebuild_timer_;
};

#endif  // CHROME_BROWSER_UI_VIEWS_FRAME_VERTICAL_TAB_STRIP_FOLDER_BAR_H_
