@echo off
set "ROOT=%~dp0.."
"%ROOT%\src\out\Release\chrome.exe" --user-data-dir="%ROOT%\.run\profile" --no-first-run --no-default-browser-check %*
