@echo off
title SmartRoad CAD Dimension Tools Installer
echo SmartRoad CAD Dimension Tools ^| Copyright 2026 SEU-Ni Zongyu
echo Detecting AutoCAD 2019-2022. Administrator approval will be requested.
echo.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-SmartRoad.ps1"
if errorlevel 1 (
    echo.
    echo INSTALLATION FAILED. See the error above and Install-Result.txt.
) else (
    echo.
    echo INSTALLATION AND VERIFICATION SUCCEEDED.
    echo Restart AutoCAD 2019, 2020, 2021, or 2022 before using the plugin.
)
echo.
pause
