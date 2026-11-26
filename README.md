# GoatAI Browser

Navegador baseado no Chromium (upstream, sem histórico).

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
- [ ] primeiro build do `chrome`
- [ ] primeira execução validada
- [ ] branding GoatAI (nome, ícone, new tab page)
