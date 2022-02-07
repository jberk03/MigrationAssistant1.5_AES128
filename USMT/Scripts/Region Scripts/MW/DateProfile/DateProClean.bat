@ECHO OFF
Title Midwest User Profile Clean-Up

:: INSTRUCTIONS
:: ======================================================================
:: Navigate to the environment section below to set the variables for	
:: your needs.	

:: Add any users you wish to exclude from the wipe to the "userpreserve"
:: line below and separate them by commas.  Be careful - these are case
:: sensitive.							
::
:: A log file (.txt) will be saved to the same directory as the batch file, and 
:: is named profilecleanup.txt. For record keeping purposes the information 
:: recorded are the essential actions taken, by you.
:: FOR REITERATION, IT DOESN'T MATTER WHERE THE BATCH FILE IS SAVED.													
:: ======================================================================
:: ENVIRONMENT VARIABLES						
:: ======================================================================
	
	:: WHAT IS YOUR ACTIVE DIRECTORY DOMAIN NAME?
	:: ==================================================================
	:: This setting is used to check if an active domain user is logged
	:: into a computer and will skip their account if the script is run
	:: while they are logged in. This will prevent the users account
	:: from becoming corrupted - IE... partial removal.
	:: ==================================================================
	SET domain=wfm
	
	:: HOW MANY DAYS OLD SHOULD A PROFILE BE BEFORE DELETION?
	:: ==================================================================
	:: This setting is used to look at the "last written" timestamp on
	:: the user's profile folder in C:\Users. If that timestamp is
	:: older than the day variable set below, the account will be
	:: flagged for deletion.
	::
	:: Keep in mind that the "last written" timestamp on a profile can
	:: be renewed by the user logging into the PC. As an example, if the
	:: same user logged into the same computer every (1-2) days, their
	:: profile would be never be removed.
	:: ==================================================================
	
	:: User input prompt for inactive days
  	:: FOR /F "tokens=*" %%I IN ('TYPE CON') DO SET Inactive=%%I
  	SET /P Inactive="Enter the # of days since the profile has been active:"

  	SET days=%Inactive%
	
:: ======================================================================
:: END ENVIRONMENT VARIABLES
:: ======================================================================

::===========================================================================================================================================================
::===========================================================================================================================================================
:: DO NOT EDIT CODE BEYOND THIS POINT
::===========================================================================================================================================================
::===========================================================================================================================================================

:REPORTGEN_INIT
FOR /F "tokens=*" %%n in ('echo %date:~10,4%-%date:~4,2%-%date:~7,2% %time:~0,2%-%time:~3,2%-%time:~6,2%') DO SET TDATETIME=%%n

FOR /F "tokens=2 delims=\" %%x in ('"WMIC /Node:"%COMPUTERNAME%" ComputerSystem Get UserName | find "%domain%""') do (set user=%%x)
ECHO %TDATETIME%  START OF CLEANING...>>"%~dp0\profilecleanup.txt"
ECHO %TDATETIME%  COMPUTER CLEANED:  %Domain%\%COMPUTERNAME%>>"%~dp0\profilecleanup.txt"
ECHO %TDATETIME%  UNUSED PROFILE QUALIFIER: %days% Days>>"%~dp0\profilecleanup.txt"

:USERPRESERVE
SET userpreserve="Administrator,Default,Public,%username%"
ECHO %TDATETIME%  PROFILES PRESERVED BY EXCEPTION... %userpreserve%>>"%~dp0\profilecleanup.txt"

FOR /f "tokens=*" %%a IN ('reg query "hklm\software\microsoft\windows nt\currentversion\profilelist"^|find /i "s-1-5-21"') DO CALL :REGCHECK "%%a"
GOTO VERIFY

:REGCHECK
set SPACECHECK=
FOR /f "tokens=3,4" %%b in ('reg query %1 /v ProfileImagePath') DO SET USERREGPATH=%%b %%c
FOR /f "tokens=2" %%d in ('echo %USERREGPATH%') DO SET SPACECHECK=%%d
IF ["%SPACECHECK%"]==[""] GOTO REGCHECK2
GOTO USERCHECK

:REGCHECK2
FOR /f "tokens=3" %%g in ('reg query %1 /v ProfileImagePath') DO SET USERREGPATH=%%g
GOTO USERCHECK

:USERCHECK
FOR /f "tokens=3 delims=\" %%e in ('echo %USERREGPATH%') DO SET USERREG=%%e
FOR /f "tokens=1 delims=." %%f IN ('echo %USERREG%') DO SET USERREGPARSE=%%f
ECHO %USERPRESERVE%|find /I "%USERREGPARSE%" > NUL
IF ERRORLEVEL=1 GOTO CHECKAGE
IF ERRORLEVEL=0 GOTO SKIP

:CHECKAGE
forfiles /p C:\Users\%USERREG% /m NTUSER.dat /d -%days%
IF %ERRORLEVEL%==0 (
	SET AGEFLAGGED=%USERREG%
	GOTO CLEAN
	)
IF %ERRORLEVEL%==1 (
	GOTO SKIP
	)

:SKIP
ECHO %TDATETIME%  Skipping Deletion of Profile (Reason: Unqualified Age or Exception): %USERREG%>>"%~dp0\profilecleanup.txt"
GOTO :EOF

:CLEAN
ECHO %TDATETIME%  Removing Profile: %AGEFLAGGED%>>"%~dp0\profilecleanup.txt"
TAKEOWN /F "C:\Users\%AGEFLAGGED%" /r /d
CACLS "C:\Users\%AGEFLAGGED%" /T /E /G SYSTEM:F Administrators:F
RD /S /Q "C:\Users\%AGEFLAGGED%" > NUL

ECHO %TDATETIME%  Cleaning Registry for Profile: %AGEFLAGGED%>>"%~dp0\profilecleanup.txt"
reg delete %1 /f
IF EXIST "C:\Users\%AGEFLAGGED%" GOTO RETRYCLEAN1
GOTO :EOF

:RETRYCLEAN1
ECHO %TDATETIME%  Retrying Removal of Profile: %AGEFLAGGED%>>"%~dp0\profilecleanup.txt"
TAKEOWN /F "C:\Users\%AGEFLAGGED%" /r /d
CACLS "C:\Users\%AGEFLAGGED%" /T /E /G SYSTEM:F Administrators:F
RD /S /Q "C:\Users\%AGEFLAGGED%" > NUL
IF EXIST "C:\Users\%AGEFLAGGED%" GOTO RETRYCLEAN2
GOTO :EOF

:RETRYCLEAN2
ECHO %TDATETIME%  Retrying Cleaning of Registry of Profile: %AGEFLAGGED%>>"%~dp0\profilecleanup.txt"
TAKEOWN /F "C:\Users\%AGEFLAGGED%" /r /d
CACLS "C:\Users\%AGEFLAGGED%" /T /E /G SYSTEM:F Administrators:F
RD /S /Q "C:\Users\%AGEFLAGGED%" > NUL
GOTO :EOF

:VERIFY
FOR /f "tokens=*" %%g IN ('reg query "hklm\software\microsoft\windows nt\currentversion\profilelist"^|find /i "s-1-5-21"') DO CALL :REGCHECKV "%%g"
GOTO REPORT

:REGCHECKV
set SPACECHECKV=
FOR /f "tokens=3,4" %%h in ('reg query %1 /v ProfileImagePath') DO SET USERREGPATHV=%%h %%i
FOR /f "tokens=2" %%j in ('echo %USERREGPATHV%') DO SET SPACECHECKV=%%j
IF ["%SPACECHECKV%"]==[""] GOTO REGCHECKV2
GOTO USERCHECKV

:REGCHECKV2
FOR /f "tokens=3" %%k in ('reg query %1 /v ProfileImagePath') DO SET USERREGPATHV=%%k
GOTO USERCHECKV

:USERCHECKV
FOR /f "tokens=3 delims=\" %%l in ('echo %USERREGPATHV%') DO SET USERREGV=%%l
FOR /f "tokens=1 delims=." %%m IN ('echo %USERREGV%') DO SET USERREGPARSEV=%%m
ECHO %USERPRESERVE%|find /I "%USERREGPARSEV%" > NUL
IF ERRORLEVEL=1 GOTO VERIFYERROR
IF ERRORLEVEL=0 GOTO :EOF

:VERIFYERROR
SET USERERROR=YES
GOTO :EOF

:REPORT
IF [%USERERROR%]==[YES] (
		set RESULT=FAILURE
)		ELSE (
		set RESULT=SUCCESS
)

:REPORTGEN
FOR /F "tokens=*" %%o in ('echo %date:~10,4%-%date:~4,2%-%date:~7,2% %time:~0,2%-%time:~3,2%-%time:~6,2%') DO SET TDATETIME=%%o
ECHO %TDATETIME%  END OF CLEANING...>>"%~dp0\profilecleanup.txt"
ECHO. ====================================================================================>>"%~dp0\profilecleanup.txt"
GOTO EXIT

:EXIT
pause
exit

:EOF