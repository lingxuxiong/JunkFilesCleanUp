# 背景介绍
文件转换服务是远程打印中的重要一环，用于将常见的MS Office文档转换为PDF文件。服务过程中产生临时PDF文件需要定期删除以释放磁盘空间，否则容易因磁盘空间耗尽导致文件转换失败，最终导致远程打印任务失败。此文档用于探索基于Windows系统自带的任务计划程序(Task Scheduler)和PowerShell脚本，实现定期删除临时文件的方案。此外，也可以借助其它三方工具(如[AutoDelete](https://filehippo.com/zh/download_cyber-ds-autodelete/))，实现临时文件删除。

# 任务目标
1. 实现定时检查和删除指定位置文件
2. 提供删除记录供查看和统计

目标文件
- 脚本文件：`clean_junk_files.ps1`
- 日志文件：`clean_junk_files.log`
- 配置文件：`clean_junk_files.xml`

参考文件结构
```
PS C:\Scripts> tree . /F
Folder PATH listing for volume Windows
Volume serial number is 9CAE-E5B1
C:\SCRIPTS
│  clean_junk_files.log
│  clean_junk_files.ps1
│  clean_junk_files.xml
│
└─tmp
    │  afasefea.pdf
    │  logs.txt
    │
    ├─tmp2
    │      logs.txt
    │      ooa9afry.zip
    │
    └─tmp3
            logs.txt
            sd3929df.pdf
```

# 脚本测试
基于上述文件结构，运行文件脚本`clean_junk_files.ps1`
```
powershell.exe -WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Scripts\clean_junk_files.ps1"
```
应删除在脚本`clean_junk_files.ps1`中配置的` JUNK_FOLDERS 
`目录下` DAYS_BEFORE 
`天以前的文件，
```
Set-Variable -Option ReadOnly -Name "JUNK_FOLDERS" -Value "C:\Scripts\tmp", "C:\Scripts\tmp2"
Set-Variable -Option ReadOnly -Name "DAYS_BEFORE" -Value 1 
```

并在对应的日志文件`clean_junk_files.log`中应生成如下日志信息
```
......
2024-05-17 14:44:24 >>> space available: 353.8GB, total: 475.7GB, per: 74.4%
2024-05-17 14:44:24 removed 3 files 1 days before, freed 201208815 bytes
2024-05-17 14:44:24 <<< space available: 353.8GB, total: 475.7GB, per: 74.4%
......
```
*脚本内容见附录部分*

# 设置计划任务

ChatGPT Prompt: How to schedule to execute a PowerShell script task on Windows Server 2019

通过在**任务计划程序(Task Scheduler)**中设置定时任务运行指定PowerShell脚本，实现定时检查和删除临时文件的目标。任务计划可手动设置，也可以从配置文件导入。

任务配置文件示例：`clean_junk_files.xml`

```xml
<?xml version="1.0" encoding="UTF-16"?>
<Task version="1.2" xmlns="http://schemas.microsoft.com/windows/2004/02/mit/task">
  <RegistrationInfo>
    <Date>2024-05-16T11:00:48.7215048</Date>
    <Author>lingxuxiong@foxmail.com</Author>
    <URI>\CloudPrint\FileConvert\Clean Junk Files</URI>
  </RegistrationInfo>
  <Triggers>
    <TimeTrigger>
      <Repetition>
        <Interval>PT1M</Interval>
        <Duration>P3D</Duration>
        <StopAtDurationEnd>false</StopAtDurationEnd>
      </Repetition>
      <StartBoundary>2024-05-16T11:00:13</StartBoundary>
      <Enabled>true</Enabled>
    </TimeTrigger>
  </Triggers>
  <Principals>
    <Principal id="Author">
      <UserId>S-1-5-21-3764732182-236826484-1307600189-1001</UserId>
      <LogonType>S4U</LogonType>
      <RunLevel>HighestAvailable</RunLevel>
    </Principal>
  </Principals>
  <Settings>
    <MultipleInstancesPolicy>IgnoreNew</MultipleInstancesPolicy>
    <DisallowStartIfOnBatteries>true</DisallowStartIfOnBatteries>
    <StopIfGoingOnBatteries>true</StopIfGoingOnBatteries>
    <AllowHardTerminate>true</AllowHardTerminate>
    <StartWhenAvailable>false</StartWhenAvailable>
    <RunOnlyIfNetworkAvailable>false</RunOnlyIfNetworkAvailable>
    <IdleSettings>
      <StopOnIdleEnd>true</StopOnIdleEnd>
      <RestartOnIdle>false</RestartOnIdle>
    </IdleSettings>
    <AllowStartOnDemand>true</AllowStartOnDemand>
    <Enabled>true</Enabled>
    <Hidden>true</Hidden>
    <RunOnlyIfIdle>false</RunOnlyIfIdle>
    <WakeToRun>false</WakeToRun>
    <ExecutionTimeLimit>PT72H</ExecutionTimeLimit>
    <Priority>7</Priority>
  </Settings>
  <Actions Context="Author">
    <Exec>
      <Command>powershell.exe</Command>
      <Arguments>-WindowStyle Hidden -ExecutionPolicy Bypass -File "C:\Scripts\clean_junk_files.ps1"</Arguments>
    </Exec>
  </Actions>
</Task>
```
# 附录
脚本文件：`C:\Scripts\clean_junk_files.ps1`
```poershell
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

    return "free: $($freeSizeGB)GB, total: $($totalSizeGB)GB, per: $($freeSizePercent)%"
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
        [string] $LogFilePath = "$PSScriptRoot\cleanup.log",
        [string] $Message               
    )

    "$(Get_Formatted_DateTime) $Message" | Out-File $LogFilePath -Append #-NoNewLine
}


# Specify the target folder in which the old files locate
#$FOLDER_PATH = "C:\Scripts\tmp"
Set-Variable -Option ReadOnly -Name "FOLDER_PATH" -Value "C:\Scripts\tmp" 

# Delete files older than this days
Set-Variable -Option ReadOnly -Name "DAYS_OLD" -Value 1
#$DAYS_OLD = 1

# Get the list of files in the folder
$fileList = Get-ChildItem -Path $FOLDER_PATH -File

# Enumerate files older than the config
$oldFiles = Get-ChildItem -Path $FOLDER_PATH | Where-Object { $_.LastWriteTime -lt (Get-Date).AddDays(-$DAYS_OLD) }

# Log disk info before clean up
Dump_Log_Message -Message ">>> $(Get_Disk_Storage_Info)"

# Iterate through each file and sum up their sizes
$totalSize = 0
$totalCount = 0
foreach ($file in $oldFiles) {
    $totalCount += 1
    $totalSize += $file.Length
    Remove-Item -Force -Path $file
}

# dump statistics for this clean up
# $logMessage = "Removed $($totalCount) files older than $($DAYS_OLD) days, $($totalSize) bytes in total" 
# $logMessage | Out-File $logFilePath -Append
Dump_Log_Message -Message "Removed $($totalCount) files older than $($DAYS_OLD) days, $($totalSize) bytes in total" 

# Log disk info after clean up
Dump_Log_Message -Message "<<< $(Get_Disk_Storage_Info)" 

```

