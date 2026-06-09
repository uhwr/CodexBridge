@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\service\install-windows-tray.ps1" -RootDir "%CD%" -StateDir "%USERPROFILE%\.codexbridge"
