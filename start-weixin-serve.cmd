@echo off
setlocal
cd /d "%~dp0"

if not defined CODEX_REAL_BIN (
  if exist "%APPDATA%\npm\codex.cmd" (
    set "CODEX_REAL_BIN=%APPDATA%\npm\codex.cmd"
  ) else (
    for /f "delims=" %%I in ('where codex 2^>nul') do (
      if not defined CODEX_REAL_BIN set "CODEX_REAL_BIN=%%I"
    )
  )
)

if not defined CODEX_APP_SERVER_TRANSPORT set "CODEX_APP_SERVER_TRANSPORT=stdio"
if not defined CODEXBRIDGE_DEFAULT_CWD set "CODEXBRIDGE_DEFAULT_CWD=%USERPROFILE%\Documents"
if not defined CODEXBRIDGE_LOCALE set "CODEXBRIDGE_LOCALE=zh-CN"

set "BRIDGE_CWD=%~1"
if not defined BRIDGE_CWD set "BRIDGE_CWD=%CODEXBRIDGE_DEFAULT_CWD%"

npm run weixin:serve -- --cwd "%BRIDGE_CWD%"
