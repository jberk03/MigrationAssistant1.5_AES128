@echo off
cls
echo Running the Migration Tool as an Admin...

REM  This is will launch USMT GUI in Administrator mode.

REM  powershell.exe -STA -nologo -file "%~dp0USMTGUI.ps1"

REM  Forcing to open the Powershell in Admin. mode.  -  TMs will be prompted for elevated credentials
REM  or simply with a UAC prompt.

PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0USMTGUI.ps1""' -Verb RunAs}"
