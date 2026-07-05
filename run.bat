@echo off
chcp 65001 >nul
cd /d "%~dp0"
echo ============================================
echo   Scanning Python download/install records
echo   Please wait, this may take a minute...
echo ============================================
echo.
powershell -NoProfile -ExecutionPolicy Bypass -File "%~dp0find_records.ps1"
echo.
echo   Done. A list was saved to your Desktop.
echo.
pause
