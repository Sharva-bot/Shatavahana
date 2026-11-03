@echo off
setlocal
cd /d "%~dp0"
title Shatavahana - Play Area

set "PY="
where python >nul 2>&1 && set "PY=python"
if not defined PY (
  py -3 -c "import sys" >nul 2>&1 && set "PY=py -3"
)
if not defined PY (
  echo [error] Python was not found. Install it from https://www.python.org/downloads/
  pause
  exit /b 1
)

echo ============================================
echo   Shatavahana - serving the play area
echo   http://127.0.0.1:8000
echo   Do not open index.html directly (file://).
echo   Close this window to stop the server.
echo ============================================
echo.

start "" powershell -NoProfile -Command "Start-Sleep -Seconds 2; Start-Process 'http://127.0.0.1:8000/'"
%PY% -m http.server 8000 --bind 127.0.0.1
if errorlevel 1 (
  echo.
  echo Port 8000 is busy - trying 8080 instead...
  start "" powershell -NoProfile -Command "Start-Sleep -Seconds 2; Start-Process 'http://127.0.0.1:8080/'"
  %PY% -m http.server 8080 --bind 127.0.0.1
)
echo.
echo Server stopped.
pause

