# Branding GoatAI

O `src/` é um checkout upstream. Toda customização entra como **patch** em
`src/` e é exportada para `branding/patches/`, com aplicação via
`scripts/apply-branding.sh`. Assim um `git -C src checkout .` volta ao estado
pristino e o rebase no upstream não perde nada.

## Pontos de branding do Chromium (não brandado)

| O que                    | Onde                                                              |
| ------------------------ | ----------------------------------------------------------------- |
| Nome/empresa             | `src/chrome/app/theme/chromium/BRANDING`                          |
| Strings do produto       | `src/chrome/app/chromium_strings.grd`                             |
| Strings de settings      | `src/chrome/app/settings_chromium_strings.grdp`                   |
| Ícone Linux              | `src/chrome/app/theme/chromium/linux/product_logo_48.png`         |
| Ícone janela/taskbar     | `src/chrome/app/theme/default_100_percent/chromium/product_logo_*.png` |
| New Tab Page             | `src/chrome/browser/resources/new_tab_page/`                      |
| `.desktop`               | `src/chrome/installer/linux/common/desktop.template`              |

O GN resolve `branding_path_component = "chromium"` quando
`is_chrome_branded = false`, então mantemos essa pasta e sobrescrevemos os
arquivos.

## Identidade provisória

- Produto: **GoatAI Browser**
- Short name: **GoatAI**
- Empresa: GoatAI
- Ícone base: `branding/icon.webp`

## Folders de pins (sidebar)

- Área no topo da barra vertical: subpastas de `Outros favoritos > Goatai Pins`
  viram folders; bookmarks soltos viram pins.
- Clique no folder: menu com os pins (abre em nova aba). Clique direito:
  abrir tudo / apagar; clique no fundo da barra: novo folder, fixar aba atual.
- Arrastar um pin para cima de um folder move o bookmark (drop nativo de
  bookmarks do Chromium). Soltar no espaço vazio devolve para a raiz.
- A barra fica oculta quando a sidebar está recolhida.
- Arrastar uma **aba** para cima de um folder fixa a URL como pin
  (TabDragTarget; a aba continua aberta).
- Menus abertos mantêm a sidebar expandida (lock kKeepExpanded).

## Menus e arrasto (Goatai)

- Menus usam `views::ContextMenuController` com `MenuRunner`/modelo mantidos
  como membros (não morrem junto com o escopo).
- Arrastar aba **para um folder** fixa a URL como pin (TabDragTarget). O
  contexto de drag é limitado à área das abas no Layout, para que a barra de
  folders seja um alvo independente.
- Arrastar aba nunca destaca/cria janela: o target_context é preso ao
  attached_context e o DnD de sistema fica desligado. "Move to new window"
  permanece no menu de contexto da aba.
- "Show tabs horizontally" e "Turn off auto expanding tabs" removidos dos menus.

### Cores de folder

- Clique direito no folder → submenu **Color**: Default + 9 cores (mesma
  paleta dos tab groups, rótulos de `GetTabGroupColorLabelMap`).
- A cor fica em `BookmarkModel` meta info (`goatai.color`) e tinge o ícone
  do folder. `BookmarkMetaInfoChanged` agenda o rebuild da barra.

### Remover pins

- Pin solto: clique direito no tile → **Remove pin** (ou Open).
- Pin dentro de folder: menu do folder → submenu **Remove pin** com os pins.
- Remoção usa `BookmarkModel::Remove`; a barra reconstrói via observer.
