# Remote Check Windows host Disk space via WMI
# WARNING: will attempt to clean temp files upon warning condition - PLEASE REVIEW DISK CLEAN BELOW BEFORE RUNNING 
# Values are based on percentage utilized, you must include a static GB remaining value as well
# eg. .\diskcheck.ps1 -server server1.domain.com -warnpct 80 -critpct 90 -warngb 10 -critgb 5

param([string] $Server, [int] $warnpct, [int] $critpct, [int] $warngb, [int] $critgb)

$alertcrit = 0
$alertwarn = 0  
$error.clear()
$disks = Get-WmiObject -ComputerName $Server -Class Win32_LogicalDisk -Filter "DriveType = 3";

foreach($disk in $disks) {
	$deviceID = $disk.DeviceID;
	[float]$size = $disk.Size;
	[float]$freespace = $disk.FreeSpace;

	$percentFree = [Math]::Round(($freespace / $size) * 100, 2);
	$sizeGB = [Math]::Round($size / 1073741824, 2);
	$freeSpaceGB = [Math]::Round($freespace / 1073741824, 2);
	if($percentFree -lt $critpct -and $freeSpaceGB -lt $critgb) {
		Write-Host "CRITICAL $deviceID = $percentFree % Free! | $deviceID=$percentFree%;;;0;";
		$alertcrit = 1
		}
	elseif($percentFree -lt $warnpct -and $freeSpaceGB -lt $warngb) {
        #Attempt to clean Disk - ****PLEASE REVIEW BEFORE PRODUCTION USE****
		$oldTime = [int]7 # Specifies min age of a files to remove
		# Create array containing all user profile folders
		$colProfiles = Get-ChildItem "\\$server\c$\Users\" -Name -force -ErrorAction SilentlyContinue
		$colProfiles = $colProfiles -ne "All Users"
		$colProfiles = $colProfiles -ne "Default"
		$colProfiles = $colProfiles -ne "Default User"

		# Removes temporary files from each user profile folder
		ForEach ( $objProfile in $colProfiles ) {
			# Remove all files and folders in user's Temp folder. The -force switch on Get-ChildItem gets hidden directories as well.
			Get-ChildItem "\\$server\c$\Users\$objProfile\AppData\Local\Temp\*" -recurse -force -ErrorAction SilentlyContinue | WHERE {($_.CreationTime -le $(Get-Date).AddDays(-$oldTime))} | remove-item -force -recurse -ErrorAction SilentlyContinue
			# Remove all files and folders in user's Temporary Internet Files. 
			Get-ChildItem "\\$server\c$\Users\$objProfile\AppData\Local\Microsoft\Windows\Temporary Internet Files\*" -recurse -force -ErrorAction SilentlyContinue | WHERE {($_.CreationTime -le $(Get-Date).AddDays(-$oldTime))} | remove-item -force -recurse -ErrorAction SilentlyContinue
		}
		# Cleans Windows Temp directory
		Get-ChildItem "\\$server\c$\Windows\Temp\*" -recurse -force -ErrorAction SilentlyContinue | WHERE {($_.CreationTime -le $(Get-Date).AddDays(-$oldTime))} | remove-item -force -recurse -ErrorAction SilentlyContinue

		# Cleans Standard Temp directory
		Get-ChildItem "\\$server\c$\Temp\*" -recurse -force -ErrorAction SilentlyContinue | WHERE {($_.CreationTime -le $(Get-Date).AddDays(-$oldTime))} | remove-item -force -recurse -ErrorAction SilentlyContinue

		# Cleans IIS Logs if applicable
		Get-ChildItem "\\$server\c$\inetpub\logs\LogFiles\*" -recurse -force -ErrorAction SilentlyContinue | WHERE {($_.CreationTime -le $(Get-Date).AddDays(-$oldTime))} | remove-item -force -recurse -ErrorAction SilentlyContinue

		# Empties the Recycle Bin
		Get-ChildItem "\\$server\c$\`$RECYCLE.BIN\*" -recurse -force -ErrorAction SilentlyContinue | WHERE {($_.CreationTime -le $(Get-Date).AddDays(-$oldTime))} | remove-item -force -recurse -ErrorAction SilentlyContinue
		
		# Now we notify as per normal 
		Write-Host  "WARNING $deviceID = $percentFree % Free! | $deviceID=$percentFree%;;;0;";
		$alertwarn = 1
		}
	else {
			Write-Host "$deviceID=$percentFree% Free | $deviceID=$percentFree%;;;0;"
		 }
}

if ($alertcrit -gt 0) {
	exit 2
	}
elseif ($alertwarn -gt 0) {
	exit 1
	}
elseif ($error.Count -gt 0) {
	Write-Output $_;
	$_="";
	exit 3;
	}
else {
	exit 0
	}

