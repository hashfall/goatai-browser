# Goatai — contexto e regras do projeto

Registro de tudo que foi decidido/implementado para continuar o trabalho sem
redescobrir o contexto.

## Visão geral

- **Goatai** é um fork do Chromium **160.0.8187.0** (upstream não-branded),
  com identidade própria, tema retrô vaporwave, abas verticais, folders de
  pins, painel de IA e auto-hide da toolbar.
- Repositório: `https://github.com/hashfall/goatai-browser` (privado).
- Versão atual: **0.5.4** (`VERSION`), tag `v0.5.4`.
- Revisão do Chromium: `53b8c80407` (`windows/CHROMIUM_REVISION`).
- Commits do projeto: identidade `Goatai <dev@goatai.local>` via
  `git -c user.name=Goatai -c user.email=dev@goatai.local commit`.

## Perfil oficial (regra crítica)

`.run/profile` é o **perfil oficial** do usuário (histórico, abas, bookmarks,
extensões, chaves). **Nunca** apague, mova, limpe, renomeie ou sobrescreva
esse diretório nem partes dele (`Default/Preferences`, `Bookmarks`, `History`,
`Local Extension Settings`, etc.).

- Testes: use perfil novo em `/tmp/opencode/<nome>` ou uma cópia
  (`cp -a .run/profile /tmp/opencode/<nome>`); nunca o perfil real.
- Abrir o perfil real só para observar/screenshot, sem alterar estado.
- `--load-extension` e flags de teste podem ser usados no perfil real; reset
  não.

## Estrutura do repositório

```
src/                  checkout do Chromium (NÃO vai pro git; 29 GB)
depot_tools/          ferramentas (gn, autoninja, gclient)
scripts/              build.sh, run.sh, install-*.sh, package-appimage.sh
scripts/windows/      bootstrap.ps1, build.ps1
branding/             patch completo + recursos de marca
branding/patches/goatai-branding.patch
extensions/           external_extensions.json + goatai_ai/ (extensão do painel)
windows/              args.gn, CHROMIUM_REVISION, goatai.cmd
docs/                 BUILD_WINDOWS.md, PACKAGING_APPIMAGE.md
dist/                 AppImage/tools (gitignored)
.run/profile/         perfil oficial do usuário (gitignored)
```

## Build (Linux)

```bash
./scripts/build.sh          # autoninja chrome (paralelismo padrão)
./scripts/build.sh -j 8     # use -j 8: a máquina já crashou com carga alta
```

- `out/Default` é **component build** (`is_component_build=true`), com
  `symbol_level=1`, `chrome_pgo_phase=0`, codecs proprietários (H.264/AAC).
- Binário: `src/out/Default/goatai` (~754 MB, sem strip). `chrome` é symlink.
- O script cria o symlink e roda `scripts/install-extensions.sh`.
- Build incremental típico: 1–3 min; link completo pode passar de 10 min.
- Antes de concluir qualquer mudança: compilar e testar (regra global).

## Execução / desktop

- `~/.local/bin/goatai`:
  ```bash
  exec .../src/out/Default/goatai \
    --load-extension=.../extensions/goatai_ai \
    --user-data-dir=.../.run/profile \
    --no-first-run --no-default-browser-check "$@"
  ```
- Atalho: `~/.local/share/applications/goatai.desktop` (`scripts/install-desktop.sh`),
  `StartupWMClass=goatai`, `MimeType` de browser.
- Padrão para `http`, `https`, `text/html`, `application/xhtml+xml` via
  `~/.config/mimeapps.list`; fish tem `BROWSER=goatai`.
- App ID/WM_CLASS: `goatai` (X11 e Wayland). `CHROME_DESKTOP` padrão do
  binário é `goatai.desktop`.

## Branding, patch e versionamento

Toda customização vive em `src/` e é publicada como patch:

```bash
# após editar src/ (incluindo arquivos novos):
git -C src add -N <arquivos novos>       # senão o git diff não os inclui
git -C src diff --binary -p > branding/patches/goatai-branding.patch
git -C src apply --reverse --check ../branding/patches/goatai-branding.patch
```

- `scripts/apply-branding.sh` reaplica o patch numa árvore limpa.
- **Arquivos novos precisam de `git add -N`** antes de gerar o patch (já
  esquecemos isso uma vez; o patch ficou sem o drag chip).
- Versão: `VERSION` + tag anotada + release (`gh release create`), com
  changelog no README. Tags existentes: v0.1.0, v0.1.1, v0.2.0, v0.2.1,
  v0.3.0, v0.4.0, v0.5.0–v0.5.4.
- Commits no repo raiz; `src/` nunca é commitado.

## Funcionalidades implementadas

### Marca
- Nome **Goatai**, ícones/strings, NTP, `.desktop`.
- Binário `goatai` (`_chrome_output_name` em `chrome/BUILD.gn`); corrigir
  `chrome_symbols`/`section_embedded` para o novo nome.
- `product_logo*`, `goatai_logo.png` na NTP.

### Tema vaporwave (`chrome/browser/ui/color/goatai_color_mixer.cc`)
- Navy `#0A0420`, ciano `#05D9E8`, magenta `#FF2A6D`.
- Cantos retos em Views (`ui/views/layout/layout_provider.cc`,
  `chrome/browser/ui/layout_constants.cc`) e WebUI
  (`ui/webui/resources/cr_elements/cr_shared_vars.css`).
- Barra de endereço quadrada + borda/glow ciano (WebUI
  `webui_toolbar/location_bar.css`, foco retangular em
  `location_bar_view.cc`), chips `AI Mode` quadrados, telhas/chips da NTP.
- NTP com grade ciano, gradiente magenta, searchbox escura e sem o botão
  "Customize Goatai" (`ntp-customize-buttons { display: none !important; }`
  no bloco Goatai de `new_tab_page/app.css`).

### Abas verticais e folders
- Abas verticais e auto-expansão (`vertical_tab_strip_*`).
- Folders de pins no topo da sidebar:
  `chrome/browser/ui/views/frame/vertical_tab_strip_folder_bar.{cc,h}`;
  cores, rename, remover, dropdown com favicon+nome+X.
- Drag: pin/aba → folder; nunca destacar para nova janela. System DnD de aba
  desligado; chip de drag em `goatai_tab_drag_chip.{cc,h}` (usa
  `views::ViewTracker`, não `raw_ptr`).
- Reordenar folders: arraste um folder sobre outro (lado esquerdo insere
  antes, direito depois). Implementado em `GoataiFolderTile::GetDropCallback`
  + `BookmarkModel::Move`.
- Sidebar collapsed: o folder bar mostra **1 ícone por linha** que os folders
  ocupariam expandidos (2 rows → 2 ícones, etc.), usando a largura uncollapsed
  para calcular `per_row`.
- O folder bar acompanha o **hover**: `UpdateFolderBarCollapseState()` usa
  `controller_collapsed && !is_expanded_on_hover_`; no hover mostra
  folders+pins+"+", e volta ao collapsed ao sair (sem sumir).
- O auto-hide é congelado enquanto o botão esquerdo está pressionado/drag:
  `mouse_button_down_` no `ToolbarAutoHideController` (press/release/move com
  `EF_LEFT_MOUSE_BUTTON`); evita esconder a barra no meio do DnD.
- `ToolbarAutoHideController` é `views::WidgetObserver`: no
  `OnWidgetDestroying` chama `Shutdown()` (remove o focus listener, destrói o
  EventMonitor e zera os `raw_ptr`), senão o destrutor liberava `raw_ptr`
  pendurado e o Chromium abortava no fechamento ("Restore pages?").
- Correções de crash/drag em `tab_drag_controller.cc`.

### Auto-hide da toolbar (estilo drawer)
- `chrome/browser/ui/views/frame/toolbar_auto_hide.{cc,h}` (dono:
  `BrowserView`), criado em `BrowserView::AddedToWidget`.
- Comportamento:
  - esconde quando a página está em foco e o mouse não está na barra;
  - revela ao encostar o mouse no topo (faixa de 4 px), ou com
    **Ctrl+L/K/E/T, Alt+D, F6**;
  - fica visível com omnibox/menus/bolhas abertos (foco fora do conteúdo);
  - desligado em fullscreen (ImmersiveMode cuida).
- Animação: **500 ms**, sem fade. A barra mantém a altura cheia e desliza via
  `transform` (layer), enquanto o conteúdo acompanha via
  `BrowserView::SetToolbarAutoHideHeight()` e o layout
  `browser_view_tabbed_layout_impl.cc`.
- `BrowserView::IsToolbarVisible()` inclui `toolbar_->GetVisible()` para o
  layout recolher o espaço.
- O `CustomCornersBackground` exige layer com
  `SetFillsBoundsOpaquely(false)`.
- A ação `kActionSidePanelShowGoataiChat`/`kGoataiChat` vem da WebUI toolbar
  fixada; a entrada é registrada no startup em
  `browser_window_features.cc` (a ação não registra sozinha).
- O clique da ação WebUI dispara `Toggle` duas vezes (press/release);
  debounce de 500 ms em `SidePanelCoordinator::Toggle` para
  `kGoataiChat`.

### Moldura
- Sem o "X" de fechar a janela no Linux:
  `opaque_browser_frame_view_layout.cc` (`kClose` → `HideButton` em Linux).
  Fechar fica com o niri/atalho do sistema.

## Painel Goatai IA

- Botão de chat com sparkle na toolbar (ação fixada) abre o **side panel
  nativo** direito.
- O painel nativo (`views::WebView` + `SidePanelEntry kGoataiChat`) hospeda a
  página da extensão `extensions/goatai_ai`, porque `chrome.send` não funciona
  em WebUI TopChrome/WebView; a página de extensão tem APIs completas.
- Provedores: GPT (OpenAI), Gemini, DeepSeek, Claude; modelo editável.
- Chave: `chrome.storage.local` (disco, persiste). Não vai para páginas nem
  logs; requisições partem da extensão. (Existe um backend nativo com OSCrypt
  em `chrome/browser/ui/webui/goatai_chat/`, mas o painel usa a extensão.)
- Controle do navegador (toggle no painel): abrir/alternar/fechar abas,
  navegar/voltar/avançar/recarregar, ler página, clicar (seletor/texto),
  digitar, rolar. Loop de ações JSON com máx. 8 passos.
- A extensão é copiada pelo AppRun para um caminho fixo
  (`~/.config/goatai/extensions/goatai_ai`) porque o ID de extensão unpacked
  depende do caminho; sem isso a chave salva se perderia.
- Arquivos: `extensions/goatai_ai/{manifest.json,panel.html,panel.css,panel.js}`.

## AppImage (Linux)

```bash
./scripts/package-appimage.sh
```

- Saída: `dist/Goatai-<versão>-x86_64.AppImage` (~275 MB).
- Inclui binário, `.so` componentizadas, `.pak`, `icudtl.dat`, snapshots,
  `resources/`, `hyphen-data/`, locales en-US/pt-BR/es, extensões padrão e a
  Goatai IA.
- `strip` só nas cópias; originais intactos.
- Perfil: `~/.config/goatai/profile` (`GOATAI_USER_DATA_DIR` para outro).
- `AppRun` passa `--disable-setuid-sandbox` (namespace sandbox).
- Sem FUSE2: `APPIMAGE_EXTRACT_AND_RUN=1`.
- **Não** anexar AppImage às releases públicas: codecs proprietários
  (H.264/AAC). O pacote é para uso local; detalhes em
  `docs/PACKAGING_APPIMAGE.md`.

## Windows

- **Não** compila de Linux; precisa de Windows real (VS 2022 Build Tools,
  SDK, 150 GB, long paths).
- `docs/BUILD_WINDOWS.md`; `scripts/windows/bootstrap.ps1` (fetch na revisão
  fixa + patch) e `build.ps1` (gn/ninja + extensões).
- `windows/args.gn` release **não-componente**, sem PGO/LTO.
- No Windows o exe ainda é `chrome.exe` (rename só no Linux para não quebrar
  chrome_elf/instalador).
- Instalador (`mini_installer`) e assinatura ficam para depois.

## Privacidade / telemetria

- Build não-branded, sem `use_official_google_api_keys`: UMA, upload de
  crash, variations e RLZ **não** estão ativos; não é o pipeline comercial do
  Chrome.
- Auditoria ociosa (perfil temp, extensões off, about:blank) mostrou:
  `update.googleapis.com`, CDNs `gvt1` (component updater),
  `clients2.google.com/time` (Network Time), warm-up do Google
  (`www.google.com/search/warmup.html`, `async/folae`) e `fonts.gstatic.com`.
  Nada de UMA/crash/variations.
- Se quiser cortar: `--disable-component-update`,
  `--disable-background-networking`, trocar o motor de busca.

## Testes e armadilhas do ambiente

- **Use perfil temporário**; nunca o `.run/profile`.
- `/tmp` é tmpfs de 9.7 GB: perfis de teste enchem rápido; limpe
  `/tmp/opencode/<perfis>` após usar. "database or disk is full" derruba o
  browser (shortcuts DB).
- Janela em multi-monitor: `xdotool getwindowgeometry` pode dar posição
  `1920,0`; clicks precisam do offset da janela. Prefira `import -window <id>`
  para capturar.
- A janela pode ser redimensionada pelo niri (936/1888 px); escolha a janela
  com `WIDTH > 600` e ignore os helpers 10x10.
- Side panel: o botão da toolbar é uma **ação WebUI fixada**; o clique chega
  via `SidePanelCoordinator::Toggle`. Para testar sem clique, use
  `--goatai-open-chat` (switch de dev).
- O painel da IA precisa de `--load-extension`; o launcher já passa.
- `--ozone-platform=x11` para capturas/clicks via XWayland; sem ele a janela é
  Wayland e o xdotool não a vê.
- Build com paralelismo alto já derrubou o PC; use `-j 8`.
- `gn gen` quebra se o rename do binário não ajustar `chrome_symbols` e
  `section_embedded`.
- WebUI normal (`content::WebUIController`) tem `chrome.send`; TopChrome/
  BrowserUI não tem. Por isso o painel usa página de extensão.
- `CustomCornersBackground` + layer: `fills_bounds_opaquely` deve ser false.
- Extensão unpacked: ID depende do caminho; mantenha o caminho estável.

## Comandos úteis

```bash
# build + rodar
./scripts/build.sh -j 8
./scripts/run.sh

# patch
git -C src add -N <novos>
git -C src diff --binary -p > branding/patches/goatai-branding.patch
git -C src apply --reverse --check ../branding/patches/goatai-branding.patch

# appimage
./scripts/package-appimage.sh

# release
VERSION=... ; git tag -a vX.Y.Z -m "..." && git push origin main vX.Y.Z
gh release create vX.Y.Z --title ... --notes ... [asset]
```

## Próximos passos possíveis

- Build Windows + `mini_installer` (máquina Windows).
- Streaming das respostas da IA.
- Confirmação antes de `type`/`click` sensíveis e botão "parar".
- Build release não-componente para um AppImage menor.
