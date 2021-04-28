# BC for < PS v3
if(!$PSScriptRoot) { $PSScriptRoot = Split-Path -parent $MyInvocation.MyCommand.Path; }

$backupDirectory = "C:\Temp\DBBackups\";

function Export-Database
{
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$TargetDatabase, [string]$TargetServer = 'localhost')

    $timestamp = get-date -format "ddMMyy_HHmm"
    $fileName = $TargetDatabase + $timestamp + ".bak"
    $targetDbBackupDirectory = Join-Path $backupDirectory $TargetDatabase;
    if (!(Test-Path $targetDbBackupDirectory)) { New-Item $targetDbBackupDirectory -ItemType Directory }
    $backupPath = Join-Path $targetDbBackupDirectory $fileName
    sqlcmd -Q "BACKUP DATABASE [$TargetDatabase] TO DISK='$backupPath' WITH COMPRESSION;" -S $TargetServer;
}

function Import-Database
{
    [CmdletBinding()]
    param([Parameter(Mandatory = $true)][string]$TargetDatabase, [string]$BackupPath, [switch]$SelectLatest, [string]$TargetServer = 'localhost')

    if (!($BackupPath -xor $SelectLatest)) { Write-Error "You must specify ONE of either -SelectLatest or -BackupPath options." -ErrorAction Stop }

    if ($SelectLatest)
    {
        $searchDir = Join-Path $backupDirectory $TargetDatabase;
        $backupFile = Get-ChildItem $searchDir | Sort-Object -Property LastAccessTime -Descending | Select-Object -First 1;
        $BackupPath = $backupFile.FullName;
        Write-Verbose "$backupFile was selected for restore."
    }

    #Get the logical file names
    $fileListTable = sqlcmd -Q "RESTORE FILELISTONLY FROM DISK='$BackupPath'" -S $TargetServer;
    $parsedLogicalNames = $fileListTable | Select-Object -Skip 2 -First 2 | ForEach-Object {$_.Split(" ") | Select-Object -First 1}
    $logicalFileName = $parsedLogicalNames[0];
    $logicalLogName = $parsedLogicalNames[1];

    $restoreSql = "ALTER DATABASE [$TargetDatabase] SET SINGLE_USER WITH ROLLBACK IMMEDIATE;
	RESTORE DATABASE [$TargetDatabase] FROM DISK='$BackupPath' WITH
		REPLACE,
		MOVE '$logicalFileName' TO 'C:\Temp\DBBackups\RAWFILES\$TargetDatabase.ldf',
		MOVE '$logicalLogName' TO 'C:\Temp\DBBackups\RAWFILES\$TargetDatabase.mdf';
	ALTER DATABASE [$TargetDatabase] SET MULTI_USER;
	GO"

    sqlcmd -Q $restoreSql -S $TargetServer;
}
