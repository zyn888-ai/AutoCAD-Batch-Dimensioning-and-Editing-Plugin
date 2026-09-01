@echo off
title SmartRoad AutoCAD Version Check
echo This check only reads the Autodesk registry. It does not install or modify anything.
echo.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Install-SmartRoad.ps1" -ProbeOnly
if errorlevel 1 (
    echo.
    echo No supported AutoCAD installation was detected. See the error above.
) else (
    echo.
    echo Detection completed. The listed AutoCAD versions are supported installation targets.
)
echo.
pause
