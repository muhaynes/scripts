# Checks remote Windows system CPU & Memory via WMI and reports highest utililzation process if warn/crit
# Use variables -servername -memwarn -memcrit -cpuq and -cpup to define critera of check
# Values are based on percentage utilized 
# eg. .\resourcecheck.ps1 -servername server1.domain.local -CPUp 90 -CPUq 0 -memwarn 80 -memcrit 90

param([string] $servername, [int] $memwarn, [int] $memcrit, [int] $CPUq, [int] $CPUp)

$error.clear()
$memalarm = 0
$cpualarm = 0 
$alarm = 0

$TotalRAM = (get-WMIObject win32_operatingsystem -computername $servername | Measure-Object TotalVisibleMemorySize -sum).sum / 1024
$FreeRAM = ((get-WMIObject -computername $servername -class win32_operatingsystem).freephysicalmemory) / 1024
$UsedRAM = (($TotalRAM) - ($FreeRAM))
$RAMPercentUsed = ([math]::truncate(($UsedRAM) / ($TotalRAM) * 100))
if ($RAMPercentUsed -gt $memcrit) {
	$memhog = (get-process | sort-object WS -descending | select-object -first 1)
	$memhogname = ($memhog).processname
	$memhogid = ($memhog).Id
	$memalarm = 2
	$output1 = "CRITICAL: Memory is $RAMPercentUsed% used. $memhogname is using the most resources, its PID is $memhogid. | Memory=$RAMPercentUsed%;;;0"
	}
	elseif ($RAMPercentUsed -gt $memwarn) {
	$memhog = (get-process -computername $servername | sort-object WS -descending | select-object -first 1)
	$memhogname = ($memhog).processname
	$memhogid = ($memhog).Id
	$memalarm = 1
	$output1 = "WARN: Memory is $RAMPercentUsed% used. $memhogname is using the most resources, its PID is $memhogid. | Memory=$RAMPercentUsed%;;;0; "
	}

$CPUQueue = (Get-WmiObject -computername $servername Win32_PerfRawData_PerfOS_System).ProcessorQueueLength
$CPUpercent = (Get-WmiObject -computername $servername win32_processor | Measure-Object -property LoadPercentage -Average).Average
if (($CPUQueue -gt $CPUq) -and ($CPUpercent -gt $CPUp)) {
	$cpuhog = (get-process -computername $servername | sort-object CPU -descending | select-object -first 1)
	$cpuhogname = ($cpuhog).processname
	$cpuhogid = ($cpuhog).Id
	$cpualarm = 2
	$output2 = "CRITICAL: CPU Queue = $CPUQueue CPU% = $CPUpercent. $cpuhogname is using the most resources, its PID is $cpuhogid | CPU=$CPUpercent%;;;0; CPU Queue=$CPUQueue;;;0; "
	}
$alarm = $cpualarm + $memalarm
$output = $output1 + $output2

if ($error.Count -gt 0) {
    Write-Output $_;
    $_=""
    exit 3
	}
elseif ($alarm -ge 2) {
	write-host $output
	exit 2
	}
elseif ($alarm -eq 1) {
	write-host $output
	exit 1
	}
else {
	write-host "OK: Memory is $RAMPercentUsed % used, CPU % is $CPUpercent and CPU Queue is $CPUQueue | Memory=$RAMPercentUsed%;;;0; CPU=$CPUpercent%;;;0; CPU Queue=$CPUQueue;;;0;"
	exit 0
	}

	
	
	
	
	
	



