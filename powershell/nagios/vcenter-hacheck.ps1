# Powershell check to monitor HA status on vCenter cluster(s)
# eg. .\vcenter-hacheck.ps1 -server vcenter1.domain.com

param([string] $server)

$error.clear()
Add-PSSnapin VMware.VimAutomation.Core
connect-viserver -server $server | out-null
$alert=0

Get-Cluster | forEach {
$HA = $_.HAEnabled 

    if ($HA -like "False"){
    $alert=1
    $name = $_.name
    }
}

if ($alert -gt 0){
    Disconnect-VIServer -Confirm:$false
    write-host "HA disabled on $name"
    exit 1
    }
    elseif ($error.Count -gt 0)
    {
    Write-Output $_;
      $_="";
      Disconnect-VIServer -Confirm:$false
      exit 3;
    }
    else{
    Disconnect-VIServer -Confirm:$false
    write-host "HA enabled on all Clusters"
    exit 0
    }