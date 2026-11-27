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
