@echo off
setlocal
cd /d "%~dp0"
powershell -NoProfile -ExecutionPolicy Bypass -STA -File ".\scripts\service\tray-windows-task.ps1" -RootDir "%CD%" -StateDir "%USERPROFILE%\.codexbridge"
