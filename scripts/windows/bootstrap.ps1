#requires -Version 5.1
<#
  Prepara o checkout do Chromium no Windows para o Goatai.

  Uso (PowerShell, na raiz do repo):
    powershell -ExecutionPolicy Bypass -File .\scripts\windows\bootstrap.ps1

  Requisitos: Git for Windows, Python 3.11+, Visual Studio 2022 Build Tools
  com "Desktop development with C++" e Windows 11 SDK, ~150 GB livres,
  16 GB+ de RAM. Ver docs/BUILD_WINDOWS.md.
#>
[CmdletBinding()]
param(
  [string]$Revision = (Get-Content (Join-Path $PSScriptRoot '..\..\windows\CHROMIUM_REVISION') -Raw).Trim()
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
Set-Location $Root

function Invoke-Step {
  param([string]$Name, [scriptblock]$Block)
  Write-Host "== $Name" -ForegroundColor Cyan
  & $Block
  if ($LASTEXITCODE -ne 0) {
    throw "Falhou: $Name (exit $LASTEXITCODE)"
  }
}

if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
  throw 'Git não encontrado no PATH. Instale o Git for Windows.'
}
if (-not (Get-Command python -ErrorAction SilentlyContinue)) {
  throw 'Python não encontrado no PATH. Instale Python 3.11+.'
}

if (-not (Test-Path (Join-Path $Root 'depot_tools'))) {
  Invoke-Step 'clonar depot_tools' {
    git clone --depth=1 https://chromium.googlesource.com/chromium/tools/depot_tools.git (Join-Path $Root 'depot_tools')
  }
}

$env:PATH = (Join-Path $Root 'depot_tools') + ';' + $env:PATH
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = '0'   # usa o Visual Studio local
$env:DEPOT_TOOLS_UPDATE = '0'

if (-not (Test-Path (Join-Path $Root 'src'))) {
  Invoke-Step 'fetch chromium (--no-history)' {
    fetch --nohooks --no-history chromium
  }
}

Invoke-Step "sync na revisão $Revision" {
  gclient sync --revision "src@$Revision" --no-history --nohooks
}

Invoke-Step 'gclient runhooks' {
  gclient runhooks
}

$patch = Join-Path $Root 'branding\patches\goatai-branding.patch'
Push-Location (Join-Path $Root 'src')
try {
  git apply --check $patch 2>$null
  if ($LASTEXITCODE -eq 0) {
    Invoke-Step 'aplicar patch de branding' { git apply $patch }
  } else {
    git apply --reverse --check $patch 2>$null
    if ($LASTEXITCODE -eq 0) {
      Write-Host '== patch de branding já aplicado' -ForegroundColor Yellow
    } else {
      throw 'O patch de branding não aplica nem está aplicado. Confira a revisão do Chromium.'
    }
  }
} finally {
  Pop-Location
}

Write-Host ''
Write-Host 'Checkout pronto. Agora rode:' -ForegroundColor Green
Write-Host '  powershell -ExecutionPolicy Bypass -File .\scripts\windows\build.ps1'
