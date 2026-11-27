#requires -Version 5.1
<#
  Compila o Goatai no Windows.

  Uso (PowerShell, na raiz do repo):
    powershell -ExecutionPolicy Bypass -File .\scripts\windows\build.ps1
    powershell -ExecutionPolicy Bypass -File .\scripts\windows\build.ps1 -Jobs 12

  Antes, rode .\scripts\windows\bootstrap.ps1.
#>
[CmdletBinding()]
param(
  [int]$Jobs = 0,
  [string]$OutDir = 'out\Release'
)

$ErrorActionPreference = 'Stop'
$Root = (Resolve-Path (Join-Path $PSScriptRoot '..\..')).Path
$env:PATH = (Join-Path $Root 'depot_tools') + ';' + $env:PATH
$env:DEPOT_TOOLS_WIN_TOOLCHAIN = '0'
$env:DEPOT_TOOLS_UPDATE = '0'

function Invoke-Step {
  param([string]$Name, [scriptblock]$Block)
  Write-Host "== $Name" -ForegroundColor Cyan
  & $Block
  if ($LASTEXITCODE -ne 0) {
    throw "Falhou: $Name (exit $LASTEXITCODE)"
  }
}

Set-Location (Join-Path $Root 'src')

if (-not (Test-Path $OutDir)) {
  New-Item -ItemType Directory -Force $OutDir | Out-Null
}
Copy-Item (Join-Path $Root 'windows\args.gn') (Join-Path $OutDir 'args.gn') -Force

Invoke-Step 'gn gen' { gn gen $OutDir }

if ($Jobs -gt 0) {
  Invoke-Step "autoninja chrome (-j $Jobs)" { autoninja -C $OutDir -j $Jobs chrome }
} else {
  Invoke-Step 'autoninja chrome' { autoninja -C $OutDir chrome }
}

# Extensões padrão (external_extensions.json ao lado do executável).
$extDir = Join-Path $OutDir 'extensions'
New-Item -ItemType Directory -Force $extDir | Out-Null
Copy-Item (Join-Path $Root 'extensions\external_extensions.json') $extDir -Force

$exe = Join-Path $OutDir 'chrome.exe'
if (Test-Path $exe) {
  Write-Host ''
  Write-Host "Build OK: $(Resolve-Path $exe)" -ForegroundColor Green
  Write-Host "Atalho/execução: $(Join-Path $Root 'windows\goatai.cmd')"
} else {
  throw "Build terminou sem $exe"
}
