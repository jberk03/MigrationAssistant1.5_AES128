<#  
.SYNOPSIS  
    Utility for removing the file redirects of PC profile owners. 
.DESCRIPTION  
    This PowerShell tool 
    [value prompted] Region Abbreviation
    [value prompted] Store Abbreviation
    ACTIONS...
    1. reaches out to active directory for the active workstations at a store, 
    2. reaches out to active directory for the active team members at a store, 
    3. ignores laptops and offline computers, - The ignore is done by only applying actions to certain chassis.
    4. logs ignored devices,
    5. creates separate log files of actions and a complete transcript,
    6. locates which TMs have profiles on which computers,
    7. enters a pssession,
    8. loads the registry hive for the TM,
    9. alters the appropriate registry settings,
    10. unloads the registry hive for the TM,
    11. exits the pssession,
    12. Copies all networked files to the local desktop,
    13. Explicitly removes all script variables
.NOTES  
    File Name  : DirectLocally.ps1
    Version    : 1.0  
    Caveats    : A restart command should be sent to the workstations minutes prior to running the script.
                    *Logged in users lock the NTUSER.dat file
                 No PST check or creation is incorporated.  If the TM has the PSTs located in Documents\Outlook then it will be copied to the local workstation.
    Written    : 02.07.2019 by Jim.Berkenbaugh@wholefoods.com
    Updates    :
    Requires   : PowerShell V5 [or greater], (this should already be installed for Win10)
.EXAMPLE 
    Right click file and Run with PowerShell
.LINK
#>

Set-ExecutionPolicy -ExecutionPolicy Unrestricted

Clear-Host

$TodaysDate = Get-Date -Format d | foreach {$_ -replace "/", "."}
$TodaysDateTime = Get-Date -Format g | foreach {$_ -replace "/", "."}

$erroractionpreference = "SilentlyContinue"

####################################################################################################
# This enables script functionality, as it pulls the store abbr from the computername and then using 
# IF/ELSEIF conditions it locates the USER(S)($) folder for pulling data.
####################################################################################################

#Get the store's 2 letter region abbreviation

#The next line automatically pulls the region abbreviation, 
#if the script is run from a computer with the same naming convention
$RegionAbr = $env:computername.SubString(0,2)
#$regionAbr = Read-Host "Please enter a (2 letter) region abbreviation [XX]"

#Get the store's 3 letter store abbreviation

#The next line automatically pulls the store abbreviation, 
#if the script is run from a computer with the same naming convention
$storeAbr = $env:computername.SubString(2,3)
#$storeAbr = Read-Host "Please enter a (3 letter) location abbreviation [XXX]"

#Locate the userfolders directory on the fileserver
if (Test-Path \\$regionAbr$storeAbr-fs1\users$\)
	{
	$ParentFolder= "\\$regionAbr$storeAbr-fs1\users$"
	}
	elseif (Test-Path \\$regionAbr$storeAbr-fs1\users\)
	{
	$ParentFolder= "\\$regionAbr$storeAbr-fs1\users"
	}
	elseif (Test-Path \\$regionAbr$storeAbr-fs1\user$\)
	{
	$ParentFolder= "\\$regionAbr$storeAbr-fs1\user$"
	}
	elseif (Test-Path \\$regionAbr$storeAbr-fs1\user\)
	{
	$ParentFolder= "\\$regionAbr$storeAbr-fs1\user"
	}
	
####################################################################################################
# Creation of Results folder, if it doesn't exist.
# This simply ensures the recepticle for logs is available.
####################################################################################################

$Results = ".\Scripts\DL Results"
    if (!(Test-Path $Results))
        {New-Item -ItemType Directory -Force -Path $Results}

####################################################################################################
# Start the transcript log for the following actions.
####################################################################################################

Start-Transcript -Path "$Results\Transcript_$regionAbr$storeAbr$TodaysDate.log"

####################################################################################################
# In addition to other steps, this script will pull the SamAccountName of active team members in 
# the store OU.  (The SamAccountName is pulled rather than the Name because long-time TMs, married 
# or otherwise name changed individuals will have a different listing for Name in AD.)
####################################################################################################

$OUString = "LDAP://wfm.pvt/OU=Users,OU=" + $StoreAbr + ",OU=" + $regionAbr + ",OU=REGIONS,DC=wfm,DC=pvt";
$userou = [adsi] $OUString
$users = $userou.Children
$names = foreach ($i in $users) {$i.SamAccountName}

Write-Host "NUMBER OF ACTIVE TEAM MEMBER ACCOUNTS: " $names.Count -ForegroundColor White -BackgroundColor Red

Remove-Item $Results\ActiveUserAccounts.log -Force

foreach ($i in $names){

    Write-Output $i | Out-File -Filepath "$Results\ActiveUserAccounts.log" -Append
    }

####################################################################################################
# Select Workstations are being prompted for and written to...
#   - The results are counted and written to Results\ActiveWorkstations.log
####################################################################################################

$workstation = $env:computername

Write-Host "SELECT WORKSTATION BEING LOGGED..." $workstation.Count -ForegroundColor White -BackgroundColor Red

if (Test-Path $Results\ActiveWorkstations.log)
	{
	Remove-Item $Results\ActiveWorkstations.log -Force
	}

Write-Output $workstation | Out-File -Filepath "$Results\ActiveWorkstations.log" -Append
    

# Initialization of Online and Offline logs for next steps.

            If (Test-Path "$Results\OnlinePCs.log") {
                Remove-Item "$Results\OnlinePCs.log" -Force
            }

    Write-Host "FILTERING FOR ONLINE MACHINES..." -ForegroundColor White -BackgroundColor Red

# Produce a file of online workstations to work from!
# THE CHASSIS CHECK HAS BEEN REMOVED FOR THE SINGULAR HOSTNAME CHECK.
# In addition, a log file is produced with the Unreachable or laptop PCs (Results\OfflinePCs.log)
#    $ChassisType = Invoke-Command -ComputerName $workstation -Command {(Get-Wmiobject win32_SystemEnclosure | 
#                    Select Chassistypes).Chassistypes}

#    If (Test-Connection -Computername $workstation -BufferSize 32 -Count 1 -Quiet) {
#        If (($ChassisType -match 3) -or ($ChassisType -match 13) -or ($ChassisType -match 15)) {
                Write-Output $workstation | Tee-Object -FilePath "$Results\OnlinePCs.log" -Append
#                }
#            }

# Online and cleaned up text of Online workstations.
$strDevices = Get-Content ("$Results\OnlinePCs.log")

####################################################################################################
# Cleaning up Old MW setup link...
####################################################################################################

Write-Host "Removing OLD Midwest User Setup Tool Shortcut from Available $storeAbr workstations." -ForegroundColor White -BackgroundColor Red

# Conditionally removes the MW User Setup Tool folder from all location desktops.
#   - If the folder exists on active AD workstations.
foreach ($strDevice in $strDevices) {

    if (Test-Path "\\$strDevice\c$\Users\Public\Desktop\MW User Setup Tool") {
            Remove-Item "\\$strDevice\c$\Users\Public\Desktop\MW User Setup Tool" -Force -Recurse
            Write-Output "MW User Setup Tool present on $i and removed"
            }
        
                elseif (!(Test-Path "\\$strDevice\c$\Users\Public\Desktop\MW User Setup Tool")) { 
                Write-Output "MW User Setup Tool NOT present on $strDevice" }
                }

            Write-Host "THE FOLLOWING OFFLINE OR LAPTOP DEVICES HAVE BEEN IGNORED BY THIS SCRIPT..." -ForegroundColor White -BackgroundColor Red
            
            # Compare the complete list of location computers to the Online and Non Laptop computers.
            # This is a list of workstations that have been touched by this script.
            $File1 = "$Results\ActiveWorkstations.log"
            $File2 = "$Results\OnlinePCs.log"
            $Location = "$Results\IgnoredWorkstations.log"
            compare-object (get-content $File1) (get-content $File2) | Out-File $Location

            Write-Output $Location


####################################################################################################
# This tests and applies changes to all accounts to all non-laptop, online workstations.
#      Actions...
#      - Tests for existance of Online file,
#      - Attempted alteration of each account on each workstation,
#           - Loop foreach workstation,
#           - Loop foreach individual,
#      - Tests for existance of NTUSER.DAT,
#      - Writes intended alterations,
#           - Enters PSRemoting,
#           - Invokes commands,
#           - Uses $using: to advance variables across sessions,
#           - Loads the HKU with the NTUSER.DAT,
#           - Alters registry settings to ensure the TM is directed locally,
#           - Calls on garbage collection,
#           - Unloads and commits the registry changes,
#           - Closes the remote PSSession,
#      - Does another quick TM check and copies to the local folders from the server contents
####################################################################################################

        # First test for the existance of the OnlinePC log
        # If the file exists then search for the NTUSER.DAT file on said workstation.
        If (Test-Path "$Results\OnlinePCs.log") {
            ForEach ($strDevice in $strDevices) {
                        ForEach ($i in $names) {
                If (Test-Path "\\$strDevice\C$\users\$i\NTUSER.DAT") {
                            # This logs the altered users.
                            Write-Output "Located a profile for $i on $strDevice" | Tee-Object -FilePath "$Results\ProfileExistance.log" -Append
                            Write-Output "ACTIONS:  Locally directing connections and Copying for $i on $strDevice" | Tee-Object -FilePath "$Results\ProfileExistance.log" -Append

                            # Requires that you open the PSRemoting for the next steps.
                            Enter-PSSession -ComputerName $strDevice

                            # Use of "$using:" to advance variable values into Invoke-Command of PSSession
                            Invoke-Command -Computer $strDevice -Command {
                            $using:i,
                            $using:strDevice,
                            $using:Parentfolder

                            # Load ntuser.dat - Load hive to provide editable data.
                            Reg load HKU\$Using:i "c:\users\$Using:i\NTUSER.DAT"

                            (REG ADD "HKEY_USERS\$using:i\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /f /v Desktop /t REG_EXPAND_SZ /d '%USERPROFILE\Desktop')
                            (REG ADD "HKEY_USERS\$using:i\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /f /v Favorites /t REG_EXPAND_SZ /d '%USERPROFILE\Favorites')
                            (REG ADD "HKEY_USERS\$using:i\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /f /v Personal /t REG_EXPAND_SZ /d '%USERPROFILE\Documents')
                            (REG ADD "HKEY_USERS\$using:i\Software\Microsoft\Windows\CurrentVersion\Explorer\User Shell Folders" /f /v "My Pictures" /t REG_EXPAND_SZ /d '%USERPROFILE\Pictures') 
                                                        
                                # Fundamentals of Garbage Collection...
                                    # Enables you to develop your application without having to free memory.
                                    # Allocates objects on the managed heap efficiently.
                                    # Reclaims objects that are no longer being used, clears their memory, and keeps the memory available for future allocations. Managed objects automatically get clean content to start with, so their constructors do not have to initialize every data field.
                                    # Provides memory safety by making sure that an object cannot use the content of another object.
                                # Conditions of use...
                                    # The system has low physical memory. This is detected by either the low memory notification from the OS or low memory indicated by the host.
                                    # The memory that is used by allocated objects on the managed heap surpasses an acceptable threshold. This threshold is continuously adjusted as the process runs.
                                    # The GC.Collect method is called. In almost all cases, you do not have to call this method, because the garbage collector runs continuously. This method is primarily used for unique situations and testing.
                                    # https://docs.microsoft.com/en-us/dotnet/standard/garbage-collection/fundamentals

                                # Trigger immediate garbage collection of all generations
                                [gc]::Collect()

                                # Unload ntuser.dat - This will commit the registry changes.
                                Reg unload HKU\$Using:i

                                }

                                # Close remote session.
                                Exit-PSSession

                                }

                                If (Test-Path "\\$strDevice\C$\users\$i") {
                                xcopy /Y /C /E /D "$Parentfolder\$i\Desktop" "\\$strDevice\c$\users\$i\Desktop"
		                        xcopy /Y /C /E /D "$Parentfolder\$i\Favorites" "\\$strDevice\c$\users\$i\Favorites" 
		                        xcopy /Y /C /E /D "$Parentfolder\$i\My Documents" "\\$strDevice\c$\users\$i\Documents"

                               }
                            }
                        }
                    }

            Write-Output "A transcript file of these operations has been saved"

            Write-Output "This operation is COMPLETE!"

            Stop-Transcript

# Explicitly, clean-up variables
# Intention, start with a clean slate when pushing to multiple stores.
# Otherwise, to ensure the variables are clean... close your ise window and reopen.

if ($TodaysDate) { Remove-Variable -Name TodaysDate -Scope Global -Force }
if ($TodaysDateTime) { Remove-Variable -Name TodaysDateTime -Scope Global -Force }
if ($storeAbr) { Remove-Variable -Name storeAbr -Scope Global -Force }
if ($ParentFolder) { Remove-Variable -Name ParentFolder -Scope Global -Force }
if ($OUString) { Remove-Variable -Name OUString -Scope Global -Force }
if ($userou) { Remove-Variable -Name userou -Scope Global -Force }
if ($workstationsou) { Remove-Variable -Name workstationsou -Scope Global -Force }
if ($Results) { Remove-Variable -Name Results -Scope Global -Force }
if ($regionAbr) { Remove-Variable -Name regionAbr -Scope Global -Force }
if ($storeAbr) { Remove-Variable -Name storeAbr -Scope Global -Force }
if ($names) { Remove-Variable -Name names -Scope Global -Force }
if ($i) { Remove-Variable -Name i -Scope Global -Force }
if ($workstation) { Remove-Variable -Name workstation -Scope Global -Force }
if ($File1) { Remove-Variable -Name File1 -Scope Global -Force }
if ($File2) { Remove-Variable -Name File2 -Scope Global -Force }
if ($Location) { Remove-Variable -Name Location -Scope Global -Force }
if ($ChassisType) { Remove-Variable -Name ChassisType -Scope Global -Force }
if ($strDevices) { Remove-Variable -Name strDevices -Scope Global -Force }
if ($strDevice) { Remove-Variable -Name strDevice -Scope Global -Force }