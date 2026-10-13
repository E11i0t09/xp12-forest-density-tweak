@echo off
rem Starts the forest density tweak (no admin rights needed)
powershell.exe -NoProfile -ExecutionPolicy Bypass -File "%~dp0XP12_ForestDensity_GlobalForestsV2.ps1"
echo.
pause
