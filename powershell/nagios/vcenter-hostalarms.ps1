# Powershell check to monitor Host Alarms in vCenter
# eg. .\vcenter-hostalarms.ps1 -server vcenter1.domain.com

param([string] $server)

$error.clear()

Add-PSSnapin VMware.VimAutomation.Core
connect-viserver -server $server | out-null

$hostsystem = Get-View -ViewType HostSystem -Filter @{"OverallStatus" = "red"}
$alert=0
foreach($state in $hostsystem.triggeredAlarmState){
	$alarm = Get-View $state.Alarm
	$name = $hostsystem.Name
	$alarm = $alarm.info.name
   if ($state.OverallStatus -eq "red")
    {
		write-host "$name has triggered $alarm"
		$alert=1
	}
}
If ($alert -gt 0){
		Disconnect-VIServer -Confirm:$false
		exit 1
		} 
		elseif ($error.Count -gt 0)
    {
    Write-Output $_;
      $_="";
      Disconnect-VIServer -Confirm:$false
      exit 3;
    }
    Else
    {
		Write-Host "Everything is good!"
		Disconnect-VIServer -Confirm:$false
		exit 0
    }
