<#
.SYNOPSIS
    Returns summary of current disk usage.

.DESCRIPTION
    This function returns the general usage information regarding the specified disk,
    in terms of free space, total space, and available space in percentage.

.PARAMETER DeviceID
    The device ID to be used as a filter, defaults to the home drive.

.EXAMPLE
    PS> Get_Disk_Storage_Info
    Call with default parameter, returns something like "free: 353.9GB, total: 475.7GB, per: 74.4%"

.EXAMPLE
    PS> Get_Disk_Storage_Info -DeviceID "C:"
    Call with explicit value of the DeviceID parameter.

.NOTES
    The value of DeviceID parameter should be postfixed with ":", 
    so "C:" is correct whereas "C" is not as expected.

.LINK
#>
function Get_Disk_Storage_Info {
    param (
        [string] $DeviceID = "$($env:HomeDrive)"
    )

    $disk = Get-WmiObject -Class Win32_LogicalDisk -Filter "DeviceID='$DeviceID'"
    $freeSizeGB = [math]::Round(($disk.FreeSpace / 1GB), 1)
    $totalSizeGB = [math]::Round(($disk.Size / 1GB), 1)
    $freeSizePercent = [math]::Round(($freeSizeGB / $totalSizeGB) * 100, 1)

    return "space available: $($freeSizeGB)GB, total: $($totalSizeGB)GB, per: $($freeSizePercent)%"
}

<#
.SYNOPSIS
    Returns formatted timestamp.
#>
function Get_Formatted_DateTime {
    return (Get-Date -Format "yyyy-MM-dd HH:mm:ss")
}

<#
.SYNOPSIS
    Append message, prefixed with timestamp, to log file.

.PARAMETER LogFilePath
    The full path of the target log file, defaults to cleanup.log which locates in
    the same folder as the script being executed.

.PARAMETER Message
    The message to be written to the target log file.

.EXAMPLE
    PS> Dump_Log_Message -Message "new log message"
    Dump the specified log message to the default log file.

.EXAMPLE
    PS> Dump_Log_Message -LogFilePath "$($env:HomeDrive)$($env:HomePath)\cleanup.log" -Message "new log message"
    Dump the specified log message to specified log file.

.NOTES
    Note that the script might not have permission to get access to the target log file, 
    so be sure to choose the write file location where write permission is granted.    
#>

function Dump_Log_Message {
    param (
        [string] $LogFilePath = "$PSScriptRoot\clean_junk_files.log",
        [string] $Message               
    )

    "$(Get_Formatted_DateTime) $Message" | Out-File $LogFilePath -Append #-NoNewLine
}


Set-Variable -Option ReadOnly -Name "JUNK_FOLDERS" -Value "C:\Scripts\tmp", "C:\Scripts\tmp2"

Set-Variable -Option ReadOnly -Name "DAYS_BEFORE" -Value 1


# Get all junk files older than x days
$junkFiles = Get-ChildItem -Recurse -Path $JUNK_FOLDERS -File | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DAYS_BEFORE) }


Dump_Log_Message -Message ">>> $(Get_Disk_Storage_Info)"


$totalSize = 0
$totalCount = $junkFiles.Length
foreach ($file in $junkFiles) {
    $totalSize += $file.Length
    Write-Host $file
    #Remove-Item -Force -Path $file
}

Dump_Log_Message -Message "removed $($totalCount) files $($DAYS_BEFORE) days before, freed $($totalSize) bytes" 

Dump_Log_Message -Message "<<< $(Get_Disk_Storage_Info)"