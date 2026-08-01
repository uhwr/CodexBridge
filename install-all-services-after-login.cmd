@echo off
setlocal
cd /d "%~dp0"

set "BRIDGE_CWD=%~1"
if not defined BRIDGE_CWD set "BRIDGE_CWD=%USERPROFILE%\Documents"

net session >nul 2>nul
if errorlevel 1 (
  echo Requesting administrator permission to install CodexBridge scheduled tasks...
  powershell -NoProfile -ExecutionPolicy Bypass -Command "Start-Process -FilePath 'cmd.exe' -Verb RunAs -ArgumentList '/c','\"\"%~f0\" \"%BRIDGE_CWD%\"\"'"
  exit /b
)

powershell -NoProfile -ExecutionPolicy Bypass -Command "'CodexBridge-Codex','CodexBridge-Weixin','CodexBridge-Weixin-Tray' | ForEach-Object { Stop-ScheduledTask -TaskName $_ -ErrorAction SilentlyContinue }"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\service\install-windows-codex-task.ps1" -DefaultCwd "%BRIDGE_CWD%"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\service\install-windows-task.ps1" -DefaultCwd "%BRIDGE_CWD%"
powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\service\install-windows-tray.ps1"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ScheduledTask -TaskName 'CodexBridge-Codex','CodexBridge-Weixin','CodexBridge-Weixin-Tray' | Select-Object TaskName,State"
