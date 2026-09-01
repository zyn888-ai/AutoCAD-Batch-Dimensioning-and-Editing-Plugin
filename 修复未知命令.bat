@echo off
title SmartRoad Command Registration Repair
echo SmartRoad CAD Dimension Tools ^| Command registration repair
echo This repairs ZHDIMHELP and all other ZHDIM demand-load command mappings.
echo Administrator approval will be requested.
echo.
"%SystemRoot%\System32\WindowsPowerShell\v1.0\powershell.exe" -NoProfile -ExecutionPolicy Bypass -File "%~dp0Repair-CommandRegistration.ps1"
if errorlevel 1 (
    echo.
    echo REPAIR FAILED. Run the full installer first, then see Repair-Result.txt.
) else (
    echo.
    echo REPAIR AND VERIFICATION SUCCEEDED.
    echo Close every AutoCAD window and restart AutoCAD before testing ZHDIMHELP.
)
echo.
pause
