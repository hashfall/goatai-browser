# GoatAI Browser

**Versão atual: v0.5.1** — Chromium 160.0.8187.0

Navegador baseado no Chromium (upstream, sem histórico), com branding Goatai,
tema retrô vaporwave (cantos retos, bordas neon), abas verticais e
folders de pins com perfis de cor.

## Versão

- `VERSION` / tag git `v0.5.1`
- Commit de referência: o commit imediatamente anterior à tag

### v0.5.1

- Auto-hide vira animação de "drawer": a barra recolhe/expande em 500 ms, sem
  fade de opacidade

### v0.5.0

- Toolbar desliza suavemente para fora/para dentro do topo (200 ms)
- Chave de API da IA agora fica salva no perfil (`chrome.storage.local`),
  persistindo entre reinícios
- Página fica por baixo da barra durante a animação (sem "salto" de layout)

### v0.4.0

- Toolbar com auto-hide estilo Zen: some quando a página está em foco e o
  mouse não está sobre ela
- Aparece ao encostar o mouse no topo (faixa de 4px), ao focar a omnibox e em
  atalhos como Ctrl+L/K/E/T, Alt+D e F6
- Fica visível enquanto menus, bolhas ou a própria barra estiverem em foco
- Desativado em fullscreen (o modo imersivo cuida da barra)

### v0.3.0

- Painel lateral direito **Goatai IA** com botão de toggle na toolbar
- Provedores: GPT (OpenAI), Gemini, DeepSeek e Claude (modelo editável)
- Chave de API salva no perfil (`chrome.storage.local`), sem logs
- A IA pode controlar o navegador: abrir/alternar/fechar abas, navegar,
  ler a página, clicar, digitar e rolar (toggle de permissão no painel)
- Painel é um side panel nativo que hospeda a página da extensão
  `extensions/goatai_ai` (carregada via `--load-extension`)

### v0.2.1

- App ID / WM_CLASS agora é **`goatai`** (X11 e Wayland), em minúsculas
- `CHROME_DESKTOP` padrão do binário passa a ser `goatai.desktop`
- `.desktop` com `StartupWMClass=goatai` para o agrupamento/janela corretos

### v0.2.0

- Tema retrô vaporwave: navy profundo, ciano neon e magenta
- Cantos retos em todo o navegador (Views, WebUI e páginas internas)
- Bordas/glow neon ciano na barra de endereço, chips, telhas e botões
- New Tab Page com grade ciano, gradiente magenta e busca escura quadrada
- Barra de endereço sem pill (foco retangular) e chips "AI Mode" quadrados
- Tema de cor do perfil não sobrescreve mais as superfícies da NTP
- Sidebar inicia expandida

### v0.1.1

- Corrige crash ao soltar aba no folder (dangling raw_ptr no chip de drag)
- Corrige drag com uma única aba (ramo "mover janela" retornava antes do drag)
- Mantém system DnD de aba desligado: nunca destaca para outra janela
- Dropdown do folder com favicon + nome + X alinhado
- Documenta que o drag de aba → folder funciona

### Funcionalidades em v0.1.0

- Branding Goatai (nome, ícones, strings, NTP, atalho `.desktop`)
- Tema roxo/rosa (toolbar, abas, NTP, Material)
- Abas verticais sempre ativas com expansão automática no hover
- Folders de pins na sidebar: cores, rename, remover, dropdown com favicon + X
- Drag & drop: pin → folder e aba → folder; sem destacar abas para nova janela
- Extensões padrão: OpenCode Browse, uBlock Origin Lite, Tampermonkey
- Perfil do projeto em `.run/profile`

## Estrutura

| Caminho            | Papel                                                        |
| ------------------ | ------------------------------------------------------------ |
| `src/`             | Checkout upstream do Chromium 160 (não editar à mão)         |
| `depot_tools/`     | Ferramentas oficiais (gn, autoninja, gclient)                |
| `scripts/build.sh` | Compila `chrome` no `out/Default`                            |
| `scripts/run.sh`   | Roda o binário com perfil isolado em `.run/profile`          |
| `branding/`        | Recursos de marca (ícone, nome, tema) — a definir            |

O Chromium em `src/` fica intocado; customizações do GoatAI entram como
patches e recursos próprios, para facilitar o rebase no upstream.

## Build

```bash
./scripts/build.sh          # incremental
./scripts/build.sh -j 12    # limita paralelismo
./scripts/run.sh            # abre o navegador
```

Configuração atual (`src/out/Default/args.gn`):

```gn
is_debug = false
is_component_build = true   # link incremental rápido
symbol_level = 1
blink_symbol_level = 1
chrome_pgo_phase = 0
proprietary_codecs = true   # H.264/AAC
ffmpeg_branding = "Chrome"
treat_warnings_as_errors = false
```

## Estado

- [x] depot_tools + checkout `--no-history`
- [x] hooks (`gclient runhooks`)
- [x] primeiro build do `chrome`
- [x] primeira execução validada (headless e headful no niri)
- [x] branding Goatai (nome, ícones 1x/2x, NTP, strings, `.info`)
- [x] tema roxo/rosa (frame, toolbar, abas, NTP, Material primary/secondary)
- [x] abas verticais estilo Zen/Arc (recolhida por padrão, expande no hover)
- [x] folders de pins no topo da sidebar (drag & drop para mover pins)
- [x] extensões padrão (OpenCode Browse, uBlock Origin Lite, Tampermonkey)
- [x] atalho `.desktop` + ícones no menu de aplicativos
- [ ] instalação empacotada (AppImage/deb)
- [ ] ajustes de UX do NTP (wallpaper / atalhos)

## Extensões padrão

`extensions/external_extensions.json` define as extensões pré-instaladas via
`external_update_url` (baixadas do Chrome Web Store no primeiro uso do perfil):

| Extensão | ID |
| --- | --- |
| OpenCode Browse | `mfnicocicmmlkpjnaffgihfjhdgjkdjg` |
| uBlock Origin Lite | `ddkiahejlhfcafbddmgiahcphecmpfh` |
| Tampermonkey | `dhdgffkkebhmkfjojejmpbldmpobfkfo` |

`scripts/install-extensions.sh` copia o JSON para
`src/out/Default/extensions/`, de onde o Chromium lê (`DIR_EXTERNAL_EXTENSIONS`).
`build.sh` e `run.sh` chamam esse script automaticamente.

Obs.: o uBlock Origin clássico é MV2 e o Chromium 160 o desabilita
(`ShouldDisableLegacyExtensions()`); a versão MV3 oficial é o uBlock Origin Lite.

## Atalho no menu

```bash
./scripts/install-desktop.sh
```

Instala `~/.local/share/applications/goatai.desktop` (nome **Goatai**, ícone
`goatai`, perfil `.run/profile`) e os PNGs em
`~/.local/share/icons/hicolor/*/apps/goatai.png`.

## Binário

O artefato principal é **`src/out/Default/goatai`**. Um symlink
`src/out/Default/chrome` aponta para ele por compatibilidade com
ferramentas/scripts do Chromium. `run.sh` e o atalho `.desktop` usam `goatai`.

## Comando e navegador padrão

- Comando: `goatai` (script em `~/.local/bin/goatai`, instalado manualmente)
- Associações: `goatai.desktop` é o padrão para `http`, `https`, `text/html` e
  `application/xhtml+xml` em `~/.config/mimeapps.list`
- Fish: `BROWSER=goatai` em `~/.config/fish/config.fish`

## Windows

O Chromium não compila de Linux para Windows. Para uma build nativa no
Windows, siga `docs/BUILD_WINDOWS.md` e use os scripts
`scripts/windows/bootstrap.ps1` e `scripts/windows/build.ps1`.

## Tema retrô vaporwave

Tema embutido, quadrado e com bordas neon (não depende de extensão):

- Paleta navy profundo (`#0A0420`), ciano neon (`#05D9E8`) e magenta (`#FF2A6D`)
  em `goatai_color_mixer.cc`.
- Cantos retos em todo o navegador: `LayoutProvider` zera os raios do Views,
  `layout_constants.cc` zera abas/toolbar, e o WebUI compartilhado
  (`cr_shared_vars.css`) zera os raios das páginas internas.
- Barra de endereço da WebUI (`webui_toolbar/location_bar.css`) quadrada, com
  borda ciano permanente e glow; chips/botões da toolbar também quadrados.
- New Tab Page com grade ciano, gradiente magenta, busca escura com borda neon,
  telhas, chips e "Customize Goatai" quadrados.
- O tema de cor do perfil é ignorado nas superfícies da NTP (telhas, chips,
  composebox) para a paleta Goatai sempre valer.

Para voltar ao visual padrão, reverta o patch:
`git -C src checkout ...` ou reaplique a árvore limpa e rode
`scripts/apply-branding.sh`.

## Painel Goatai IA

O ícone de chat com sparkle na toolbar abre o painel lateral direito.

- **Provedores**: GPT, Gemini, DeepSeek e Claude. O nome do modelo é editável
  para acompanhar atualizações dos provedores.
- **Chave de API**: guardada no perfil em `chrome.storage.local` (disco),
  então permanece entre reinícios. Não vai para páginas visitadas nem para
  logs. A segurança depende do acesso ao seu usuário no sistema.
- **Controle do navegador**: com "Permitir que a IA controle o navegador"
  ligado, ela pode abrir/alternar/fechar abas, navegar, ler o texto da página,
  clicar por seletor ou texto, digitar e rolar. Desligue o toggle para usar
  apenas como chat.
- A extensão fica em `extensions/goatai_ai` e é carregada pelo `goatai`
  (`--load-extension`). O painel nativo apenas hospeda essa página; as
  requisições saem do processo da extensão.

## Toolbar com auto-hide

A barra superior desliza para fora do topo quando você está usando a página e o
mouse não está sobre ela (animação de 500 ms, sem fade). Para trazê-la de volta:

- encoste o mouse na borda superior da janela (faixa de 4px);
- use Ctrl+L / Ctrl+K / Ctrl+E / Ctrl+T, Alt+D ou F6.

Ela permanece visível enquanto a omnibox ou qualquer menu/bolha da barra
estiverem abertos, e também enquanto o mouse estiver sobre ela. Em fullscreen
o auto-hide é desligado (o modo imersivo do Chromium assume).
