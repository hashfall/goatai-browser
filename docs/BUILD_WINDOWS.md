# Goatai — build no Windows

O Chromium **não compila de Linux para Windows**. Este é o caminho suportado:
um checkout no Windows, na mesma revisão usada no Linux, mais o patch do
Goatai (`branding/patches/goatai-branding.patch`).

## Requisitos

- Windows 10/11 x64 (build também funciona em ARM64, mas docs assumem x64)
- **Visual Studio 2022 Build Tools** com:
  - Desktop development with C++
  - MSVC v143 (x64/x86)
  - Windows 11 SDK (10.0.22621 ou mais novo)
  - Debugging Tools for Windows (para símbolos)
- Git for Windows e Python 3.11+
- **150 GB livres** (NTFS), 16 GB de RAM (32 GB recomendado), 8+ núcleos
- Long paths habilitado:
  ```powershell
  git config --global core.longpaths true
  ```
  e a policy de long paths do Windows ativada.
- Exclusões no Windows Defender para a pasta do checkout e `src\out`
  (build fica 2–3x mais rápido).
- Page file de pelo menos 16 GB.

## Passo a passo

```powershell
git clone https://github.com/hashfall/goatai-browser.git
cd goatai-browser

# 1) checkout do Chromium na revisão fixada + patch de branding
powershell -ExecutionPolicy Bypass -File .\scripts\windows\bootstrap.ps1

# 2) build
powershell -ExecutionPolicy Bypass -File .\scripts\windows\build.ps1
```

O primeiro passo baixa ~30 GB (Chromium `--no-history`) e roda os hooks;
o build completo leva horas e gera ~40 GB em `src\out\Release`.

## Resultado

- Executável: `src\out\Release\chrome.exe`
- Extensões padrão: `src\out\Release\extensions\external_extensions.json`
  (uBlock Origin Lite, Tampermonkey, OpenCode Browse — instalam no primeiro
  uso do perfil, baixando da Web Store)
- Atalho de execução: `windows\goatai.cmd`

> No Windows o executável ainda se chama `chrome.exe` (o rename para
> `goatai.exe` foi feito só no Linux, para não quebrar chrome_elf/instalador).
> O produto, ícone, strings e janela são **Goatai**.

## Revisão e patch

- Revisão do Chromium: `windows/CHROMIUM_REVISION`
  (`53b8c8040740a721de3f3bacab7af5467aff7dc6`)
- Patch: `branding/patches/goatai-branding.patch` (aplicado pelo bootstrap;
  se mudar o patch, rode `git -C src checkout .` antes de reaplicar)
- `windows/args.gn`: release sem PGO/LTO, H.264/AAC habilitados

## Alternativas e ajustes

- **Build mais rápido para desenvolver**: troque `is_component_build = false`
  por `true` em `windows/args.gn` (link incremental rápido, DLLs no out).
- **Mais paralelismo**: `-Jobs 12` no build.ps1 (não passe de núcleos-2 com
  16 GB de RAM).
- **Atualizar**: `git pull`, depois rode o bootstrap de novo (ele sincroniza
  na revisão fixada) e o build.
- **Assinatura/instalador**: o binário sai sem assinatura Authenticode. Para
  distribuir, gere um instalador (`mini_installer`) e assine com um
  certificado de code signing.
