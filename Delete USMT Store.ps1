# Main Working Directory
$Working = split-path $SCRIPT:MyInvocation.MyCommand.Path -parent

# USMT Store
$USMTStorage = "$Working\STORAGE"

# All Migration Folders
$CompFolders = (Get-ChildItem -Path $USMTStorage).PSPath

#Loop through all folders
ForEach($CompFolder in $CompFolders){
    
    #Runtime variables
    $CompName = $CompFolder.Split("\")[-1]

    # Look for scanstate and loadstate
    If((Test-Path "$CompFolder\SAVESTATE.log") -and (Test-Path "$CompFolder\LOADSTATE.log")){
    
        # Write host
        Write-Host "The PC '$CompName' did a backup and restore, checking if the restore was a success.."

            # Load Progress of PC backup and restore
            $LogContent = Get-Content -Path "$CompFolder\PROGRESS.log"

            # Backup and Restore Successful
            if($LogContent -like "*, totalPercentageCompleted, 100*"){
            
                # Remove the folder
                Write-Host "The user '$CompName' did a successfull restore, purging the export folder."

                Remove-Item -Path $CompFolder -Force

            }else{

                # Skip
                Write-Host "The migration to '$CompName' have done an unsuccessfull restore, skipping deletion.."
            }
        }
    }