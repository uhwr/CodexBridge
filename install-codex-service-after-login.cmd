@echo off
setlocal
cd /d "%~dp0"

set "BRIDGE_CWD=%~1"
if not defined BRIDGE_CWD set "BRIDGE_CWD=%USERPROFILE%\Documents"

powershell -NoProfile -ExecutionPolicy Bypass -File ".\scripts\service\install-windows-codex-task.ps1" -DefaultCwd "%BRIDGE_CWD%"
powershell -NoProfile -ExecutionPolicy Bypass -Command "Get-ScheduledTask -TaskName 'CodexBridge-Codex' | Select-Object TaskName,State"
