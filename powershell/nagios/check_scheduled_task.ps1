# Checks last run-time and status of specifed Windows Scheduled task, alerts if not successful or hasn't run in X days 
# Task name requires full path
# eg. .\check_scheduled_task.ps1 -server server1.domain.com -task "\Microsoft\Windows\WindowsUpdate\Automatic App Update" -days 1

param ([string] $server, [string] $task, [string] $days)

$tasks = schtasks /query /v /s $server /fo CSV | ConvertFrom-CSV
$mytask =  $tasks | Where-Object {$_.TaskName -eq "$task"}
$lastrun = ($mytask).'Last Run Time'
$result = ($mytask).'Last Result'

if ($lastrun -eq "N/A") {
	write-host "Potential issue, no last run time. Can occur with a new task"
	exit 1
	}
if ($result -ne 0) {
	write-host "Warning: Scheduled Task Failure - result code $result"
	exit 1
	}
elseif ($lastrun -lt ((get-date).AddDays(-$days)).ToString("M/dd/yyyy hh:mm:ss tt")) {
	write-host "Warning: Behind schedule, last run was $lastrun!"
	exit 1		
	}
else {
	write-host "All good, last run time of $lastrun"
	exit 0
	}