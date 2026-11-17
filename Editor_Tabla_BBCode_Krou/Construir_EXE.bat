@echo off
title Reconstruir EditorTablaBBCode.exe (archivo unico)
cd /d "%~dp0"

set PY=
where py >nul 2>nul && set PY=py
if not defined PY where python >nul 2>nul && set PY=python
if not defined PY (
  echo [ERROR] No se encontro Python.
  echo          Instalalo desde https://www.python.org/downloads/
  echo          marcando la casilla "Add Python to PATH".
  pause
  exit /b 1
)

echo Instalando herramientas (PyInstaller y openpyxl)...
%PY% -m pip install --upgrade pyinstaller openpyxl
if errorlevel 1 (
  echo [ERROR] No se pudieron instalar las dependencias. Revisa tu conexion.
  pause
  exit /b 1
)

echo Compilando el ejecutable de archivo unico...
%PY% -m PyInstaller --onefile --noconsole --noupx --clean --name EditorTablaBBCode EditorTablaBBCode.py
if errorlevel 1 (
  echo [ERROR] Fallo la compilacion.
  pause
  exit /b 1
)

move /Y "dist\EditorTablaBBCode.exe" . >nul
if exist build rmdir /s /q build
if exist dist  rmdir /s /q dist
if exist EditorTablaBBCode.spec del /q EditorTablaBBCode.spec

echo.
echo LISTO: EditorTablaBBCode.exe quedo en esta carpeta.
echo Ese nuevo .exe ya no necesita la carpeta runtime (es de archivo unico);
echo solo debe conservar tabla_mods.json y plantilla.txt a su lado.
pause
