# Migrate-WindowsUserProfile
Migrate Windows user profile to a new machine using Microsoft USMT with a Powershell GUI.

## Setup
The USMT binaries are already present and available with the package of delivered files.
- If an error is encountered during the migration then the first suggestion is that the most recent version of the Migration Assistant be downloaded and used and you reboot your workstation.
- If the current version is already being used or you experience the same issue after a reboot please read through the rest of this file and as a final resort, reach out to your AC for additional steps.

.
+-- README.md
+-- .gitignore
+-- Run USMTGUI.bat
+-- USMTGUI.ps1
|  +-- STORAGE\ 
|  +-- USMT\
||  +-- amd64\
||  +-- arm64\
||  +-- x86\
||  +-- Scripts\
|||		+-- OldComputer\
|||		+-- NewComputer\
|||		+-- Region Scripts\
||||				+-- FL\
||||				+-- MA\
||||				+-- MW\
|||||      				+-- CurrentPCUndo\
|||||      				+-- DateProfile\
||||				+-- NA\
||||				+-- NC\
||||				+-- NE\
||||				+-- NW\
||||				+-- PN\
||||				+-- RM\
||||				+-- SO\
||||				+-- SP\
||||				+-- UK\
|  +-- Documentation\
||  +-- SPT\

## Executing the Powershell script
The parallel .bat file should be used to call on the Powershell script.
The .bat file ensures that the GUI is opened with Admin permissions.
- *If you are unable to directly run the .bat file by double clicking it then...*
			**right clicking, with your mouse >> selecting Run as administrator** is just as good.

		The following has been incorporated and is the primary executor of the script...
		PowerShell.exe -NoProfile -Command "& {Start-Process PowerShell.exe -ArgumentList '-NoProfile -ExecutionPolicy Bypass -File ""%~dp0USMTGUI.ps1""' -Verb RunAs}"

## Selection of binaries
The architecture of the machine determines the set of binaries used.
*32-bit machines have proven the most problematic
However, the age of the hardware is more indicative of potential issues. 
	Many of the problems are related to improper management. (ie.  partial deletion of profiles and those profiles not being removed via Advanced System Settings)

## Log Output
Config.xml - Configuration settings for migration.
DomainMigration.txt - TM(s) migrated.
FilesMigrated.log - List of all files exported. - Only necessary if files are missing and you need to reference if they were captured in the scanstate process.
load.log - Steps of USMT loadstate.
load_progress.log - Abbreviated USMT loadstate steps.
MigLog.xml - Detailed settings and migration file.
scan.log - Steps of USMT scanstate.
scan_progress.log - Abbreviated scanstate steps.
TempWindowsProfiles.log - Log that list the ProfileList Registry Hive, offending temporary profile and extended information about the profile. -  (This log is only created if a .bak profile exists)
TM_Encrypted.log - Log of Encrypted File(s) on your system. - These files have been skipped during the migration process to prevent issues.

## Old Computer tab options
**It's necessary to export and import with encryption turned on during both procedures.**
 -  It's also important that the password you create during the export process is not lost or the import file will be inaccessible.
  
### Data to be included for backup
Folder (data) selections are defaulted according to the suggested folders to export. - AppData, Printers, My Documents, Wallpapers, Favorites, My Pictures, Desktop
 - Extra directories, not listed can be browsed to and selected for inclusion.

### Profile(s) to Migrate
Can be selected individually.
  -or-
"Migrate all profiles logged into within this amount of time" - Defaults to 90 days but is not ticked off as active.

## New Computer tab options
Required:  That the Storage folder be located from "Save State Source" and that the OldComputer name be highlighed.
- You don't need to drill into the folder.  The program will decode the embedded logs and .mig file.

### User has verified the save state process is already completed - Proceeding with migration
Processes have been defaulted so the following is active... 
- In addition to the field being defaulted, it's also disabled so the feature cannot be turned off.

## Email Settings tab options
The default settings for WFMs SMTP have been set but can be over-ridden or added to.

## Scripts tab options
Anything placed in the OldComputer or NewComputer folders will execute prior to any other operations.
- The Powershell script in the MW folder reverses the redirect that was done and copies server information back to the TM's workstation.
- Additional region folders have been provided to file away scripts or tools specific to regions.

###############################
## ADVANCED VERSIONS, 
## 		MIGRATION ASSISTANT
###############################

v1.4.2

1. Identification, logging and skipping of machine encrypted files.
	MACHINE ENCRYPTED FILES CAUSE THE MIGRATION TO HALT.
	These files cause the migration to abort when otherwise confronted by the migration.
		*ALL testing has shown that these are OTS files, that are readily available from the SharePoint.  -  It's not suggested or common practice to save these locally.*
2. The naming of the email sender has been altered to more accurately reflect the vendor that will be doing the majority of the migrations.

v1.5

1. Inclusion of "/c".
		* The /c skips locked files and processes - Generally skips NON-FATAL errors that are encountered.
			**LOCKED FILES HALT THE MIGRATION OPERATION**
			Testing has shown these to be OST files, when they occur.
			Regardless, it's fine that OST files are not migrated because Outlook will rebuild this if it doesn't already exist.
			*SUGGESTED PRACTICE:*  Reboot workstations prior to running the migration. - This releases the OST and ensures all files are copied... **improving user experience.**
2. Inclusion of verbose logging.
		* The verbose switch creates a more complete, detailed log of the migration actions.
		A MigLog.log is created that has a robust log of all actions taken.
				(This is saved with the other logs.)
		*Note:*  Verbose logging is simply more comprehensive logging.
				Level,	Explanation
				0,  Only the default errors and warnings are enabled.
				1,  Enables verbose output.
				4,  Enables error and status output.
				5,  Enables verbose and status output.
				8,  Enables error output to a debugger.
				9, Enables verbose output to a debugger.
				12,  Enables error and status output to a debugger.
				13,  Enables verbose, status, and debugger output.
	*Lines 68 and 69 of the PowerShell script say the following, and just altering the number will change the Verbose level.*
							    # Verbose Level - ScanState & LoadState
    								$Script:VerboseLevel = '13'
3. Inclusion of verification of temporary windows profiles (.bak).
			**TEMPORARY WINDOWS PROFILES HALT THE MIGRATION OPERATION**
			This is a verification and logging of these profiles, if they exist.
				Existing temporary profiles will be displayed to the screen with comments on how to proceed.
				Otherwise, the Migration Assistant continues on.
				*Important:*  If the STORAGE folder already exists then this check will not run! - While the exports can overwrite a prior one, it's best practice to start fresh each time. 
						Not having a Computername folder in the STORAGE folder with the same name is ideal.
4. Inclusion of encryption verification.
			**NOT USING THE ENCRYPT FEATURE DURING THE EXPORT AND IMPORT WILL CAUSE ERRORS IN THE MIGRATION OPERATION**
			This is a verification of the encryption use.
				If the Encrypt checkbox on the GUI is not selected then a message will display for the user and migration processes will halt.
				Fix:  Simply, check the "Encrypt captured Data" (Old Computer) or "Saved data was encrypted" (New Computer) and click the Export/Import button again.
				*Note:*  This check is done during both the save and load stage.

## Manual Troubleshooting
If an error is encounter while using the Migration Assistant:
1. Goto and send the logs from [ExternalHardDrive]:/STORAGE/OldComputerName...
		- These are instrumental in discovering the root of the issue.
			*Most times the immediate error presented to users appears to point in one direction and it's actually quite different.*
2. If the migration didn't run long enough to produce logs then that in itself is telling but the logs themselves have conciderable information.

## Troubleshooting Return Codes and Error Messages
https://docs.microsoft.com/en-us/windows/deployment/usmt/usmt-return-codes#a-href-idbkmk-tscodeserrorsatroubleshooting-return-codes-and-error-messages