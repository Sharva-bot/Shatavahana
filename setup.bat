@echo off
setlocal
cd /d "%~dp0"
title Shatavahana - Model Play Area

echo ============================================
echo   Shatavahana - one time setup and launch
echo ============================================
echo.

set "PY="
for %%v in (3.12 3.11 3.13 3.10) do (
  if not defined PY (
    py -%%v -c "import sys" >nul 2>&1 && set "PY=py -%%v"
  )
)
if not defined PY (
  where python >nul 2>&1 && set "PY=python"
)
if not defined PY (
  echo [error] Python 3.9+ was not found.
  echo         Install it from https://www.python.org/downloads/ and run setup.bat again.
  pause
  exit /b 1
)

set "PYMAJ="
for /f "tokens=1,2" %%a in ('%PY% -c "import sys; print(sys.version_info[0], sys.version_info[1])"') do (
  set "PYMAJ=%%a"
  set "PYMIN=%%b"
)
if not defined PYMAJ (
  echo [error] Could not query the Python version.
  pause
  exit /b 1
)
if %PYMAJ% LSS 3 (
  echo [error] Python 3.9+ is required.
  pause
  exit /b 1
)

echo [1/3] Installing dependencies (ultralytics, onnx, onnxruntime)...
%PY% -m pip install --upgrade pip --disable-pip-version-check >nul 2>&1
%PY% -m pip install --no-input ultralytics onnx onnxruntime lap
if errorlevel 1 (
  echo [retry] Permission issue detected - installing for the current user only...
  %PY% -m pip install --no-input --user ultralytics onnx onnxruntime lap
)
if errorlevel 1 (
  echo.
  echo [error] Dependency install failed. Check your internet connection.
  echo         If PyTorch has no wheel for your Python version, install Python 3.12
  echo         from https://www.python.org/downloads/ and run setup.bat again.
  pause
  exit /b 1
)

echo.
echo [2/3] Converting .pt models to .onnx for the browser play area...
%PY% convert_models.py
if errorlevel 1 (
  echo.
  echo [warn] Some models could not be converted. The play area still works
  echo        with any .onnx files that already exist in this folder.
)

echo.
echo [3/3] Starting local static server at http://127.0.0.1:8000
echo       (No backend - this only serves index.html and the model files.)
echo       Close this window to stop the server.
echo.

start "" powershell -NoProfile -Command "Start-Sleep -Seconds 2; Start-Process 'http://127.0.0.1:8000/'"
%PY% -m http.server 8000 --bind 127.0.0.1
if errorlevel 1 (
  echo.
  echo [error] Could not start the server. Port 8000 may already be in use.
  pause
)

