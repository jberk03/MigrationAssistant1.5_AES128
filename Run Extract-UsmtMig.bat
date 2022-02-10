@echo off
cls
echo Running the Mig Extraction as an Admin...

REM  This is will launch the Mig Extraction in Administrator mode.

REM  powershell.exe -STA -nologo -file "%~dp0Extract-UsmtMig.ps1"

REM  Forcing to open the Powershell in Admin. mode.  -  TMs will be prompted for elevated credentials
REM  or simply with a UAC prompt.

PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0Extract-UsmtMig.ps1""' -Verb RunAs}"
