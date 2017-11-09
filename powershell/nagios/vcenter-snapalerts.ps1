# Powershell check to monitor VM snapshot space/size in vCenter
# Will alert if snapshot is older than X days or larger than X gigs
# eg. .\vcenter-snapalerts.ps1 -server vcenter1.domain.local -days 5 -gigs 20 

param([string] $server, [string] $days, [string] $gigs)

$error.clear()

Add-PSSnapin VMware.VimAutomation.Core
connect-viserver -server $server | out-null
$alert=0
Get-VM | Get-Snapshot | Select-Object VM,Name,Created,sizeGB | ForEach{
	$vm = $_.VM
	$name = $_.Name
	$created = $_.Created
	$snapsize = [int]$_.sizeGB
	if(($created -lt (Get-Date).AddDays(-$days)) -or ($snapsize -gt $gigs)) {
        Write-Host "$vm has a snap named $name which is $snapsize GB created $created. "
        $alert=1
	} 
}

if ($alert -gt 0) {	
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
    Write-Host "Everything is good!"
    Disconnect-VIServer -Confirm:$false
    exit 0
    }
