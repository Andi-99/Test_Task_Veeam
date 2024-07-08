Write-Host "Starting script"
$Date_Time = Get-Date -Format "dd_MM_yyyy_HH_mm_ss"

#User inputs the desired folders where the script will be running with PATH validation

[ValidateScript({
    if(-not(Test-Path -Path $_ -PathType Container))
    {
        throw 'Invalid path'
    }

    $true
})]

$folder_location = read-host -prompt "Please input the location of the folder that you want to create a backup of"

[ValidateScript({
    if(-not(Test-Path -Path $_ -PathType Container))
    {
        throw 'Invalid path'
    }

    $true
})]
$replica_folder_location = read-host -prompt "Please input the location where you want the folder's replica to be placed"

#Variables for verifying the existence of files

$backup_script_logs_existing = Get-ChildItem -Path $replica_folder_location -name backup_logs.txt

$replica_folder_existing =  Get-ChildItem -Path $replica_folder_location -name replica_folder

#verifying if the replica_folder is created

if ( $replica_folder_existing -match 'replica_folder')
{

    write-host "Folder already exists, continuing to backing of files"

} 
else {

    New-Item -Path $replica_folder_location -Name "replica_folder" -ItemType "directory"

    write-host "Created folder with the name of replica folder"

}

$replica_folder_path = Join-Path -Path $replica_folder_location -ChildPath "replica_folder"

#verifying if the logs file is created already

if ( $backup_script_logs_existing -match 'backup_logs.txt')
{

    Write-Host "Logs file already exists, continuing..."
    Add-Content -Path $replica_folder_location\backup_logs.txt -Value "New backup started at $Date_Time"

} 
else {

    New-Item -Path $replica_folder_location -Name "backup_logs.txt" -ItemType "file"
    write-host "Missing logs file, creating new file"
    Add-Content -Path $replica_folder_location\backup_logs.txt -Value "New backup started at $Date_Time"
    
}

# Get all items from the source directory, excluding the log file
$sourceItems = Get-Childitem -Path $folder_location -Recurse 

# Loop through each item in the source directory
foreach ($item in $sourceItems) {
        $replica_path = $item.FullName.Replace("$folder_location","$replica_folder_path")

#Copy the directory to replica folder
        if ($item.PSIsContainer) {        
        if (-not (Test-Path $replica_path)){
        write-host "Copying directory to replica folder"
        New-Item -Path $replica_path -ItemType "Directory"
        Add-Content -Path "$replica_folder_location\backup_logs.txt" -Value "Created directory at $item.Fullname"
            }
        } 
        else 
        {
#Copy the files to replica folder

            if (-not (Test-Path $replica_path)){

        write-host "Copying file to replica folder"
        Copy-Item -path $item.Fullname -Destination $replica_path

        Add-Content -Path $replica_folder_location\backup_logs.txt -Value "Copied file at $item.Fullname"
        }
      }
    }

#Remove items from replica_folder that are not located in the original folder

$NonSyncedItems = get-childitem -Path $replica_folder_location\replica_folder -Recurse

foreach ($item in $NonSyncedItems) {
    $replica_path = $item.FullName.Replace($replica_folder_path, $folder_location)

    if (-not (Test-Path $replica_path))
    {

    if ($item.PSIsContainer) 
        {

        remove-item -Path $item.FullName -recurse
        Add-Content -Path $replica_folder_location\backup_logs.txt -Value "Removed directory at $item.Fullname"
        } 
        else {
        Remove-Item -path $item.FullName
        Add-Content -Path $replica_folder_location\backup_logs.txt -Value "Removed file at $item.Fullname"
        }
    }
}

Add-Content -Path $replica_folder_location\backup_logs.txt -Value "Synchronization completed at $Date_Time"