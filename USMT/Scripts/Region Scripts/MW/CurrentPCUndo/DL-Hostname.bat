@echo off
cls
echo Running the Redirect Undo as an Admin...

REM  This is will launch the accomanying powershell in Administrator mode.

REM  powershell.exe -STA -nologo -file "%~dp0DL-Hostname.ps1"

REM  Forcing to open the Powershell in Admin. mode.  -  TMs will be prompted for elevated credentials
REM  or simply with a UAC prompt.
PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Unsigned -File ""%~dp0DL-Hostname.ps1""' -Verb RunAs}"
