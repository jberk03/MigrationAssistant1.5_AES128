@echo off
cls
echo Running the Deletion of the Old USMT Stores as an Admin...

REM  This is will launch USMT GUI in Administrator mode.

REM  powershell.exe -STA -nologo -file "%~dp0Delete USMT Store.ps1"

REM  Forcing to open the Powershell in Admin. mode.  -  TMs will be prompted for elevated credentials
REM  or simply with a UAC prompt.

PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0Delete USMT Store.ps1""' -Verb RunAs}"

Pause