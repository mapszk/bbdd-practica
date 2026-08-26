@echo off
setlocal
set "UV=%LOCALAPPDATA%\Microsoft\WinGet\Packages\astral-sh.uv_Microsoft.Winget.Source_8wekyb3d8bbwe\uv.exe"
if not exist "%UV%" (
    where uv >nul 2>nul
    if errorlevel 1 (
        echo No se encontro uv. Instalalo con: winget install astral-sh.uv
        pause
        exit /b 1
    )
    set "UV=uv"
)
set "UV_PROJECT_ENVIRONMENT=%LOCALAPPDATA%\PracticaSQL\venv"
set "PYTHONIOENCODING=utf-8"
set "PYTHONUTF8=1"
cd /d "%~dp0"
"%UV%" run python -m app.main %*
pause
