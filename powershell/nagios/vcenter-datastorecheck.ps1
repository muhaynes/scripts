# Powershell check to monitor vCenter Datastores based on Gigabytes remaining
# eg. .\vcenter-datastorecheck.ps1 -server vcenter1.domain.com -warn 30 -crit 20

param([string] $server, [int] $warn, [int] $crit)
$error.clear()
$warnalert = 0
$critalert = 0

Add-PSSnapin VMware.VimAutomation.Core
connect-viserver -server $server | out-null

get-datastore | foreach {
    $freeGB =  [decimal]::round($_.FreeSpaceGB)
    $name = $_.name
    if ($_.FreeSpaceGB -lt $crit) {
        $critalert = 1
        $output = "CRIT: $name has $freeGB GB remaining!"
    }
    elseif ($_.FreeSpaceGB -lt $warn) {
        $warnalert = 1
        $output = "WARN: $name has $freeGB GB remaining!"
    }
}

if ($critalert -gt 0) {
    write-host $output
    Disconnect-VIServer -Confirm:$false
    exit 2
    }
elseif ($warnalert -gt 0) {
    write-host $output
    Disconnect-VIServer -Confirm:$false
    exit 1
    }
elseif ($error.Count -gt 0) {
    Write-Output $_;
    $_="";
    Disconnect-VIServer -Confirm:$false
    exit 3;
    }
else {
    write-host "OK, all datastores above $warn GB free"
    Disconnect-VIServer -Confirm:$false
    exit 0
    }
    