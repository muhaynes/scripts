# Checks for EBS snapshots for all volumes tagged with "Backup=True"
# Requires saved creds as the use you run Nagios locally
# eg. .\check_aws_snaps.ps1 -creds awsprofile1 -region us-west-1

param ([string] $creds, [string] $region)

Import-Module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"
Set-AWSCredentials -StoredCredentials $creds
Set-DefaultAWSRegion $region

$volumes = (Get-EC2Volume | ? {$_.State -eq "in-use" -and $_.Tag.Key -eq "Backup" -and $_.Tag.Value -eq "True" -and $_.CreateTime -lt ([DateTime]::Now).AddDays(-1)}).VolumeID

$snapshots = Get-EC2Snapshot -Filter @(
		@{
			name='status'
			value='completed'
		}
	) | ? {$_.Starttime -gt ([DateTime]::Now).AddDays(-1)}

$volsnaps = ($snapshots).VolumeID | select -uniq

$missing = $volumes | where {$volsnaps -notcontains $_}

if ($error.Count -gt 0) {
	Write-Output $_;
	$_="";
	exit 3
    }
elseif ($missing -ne $null) {
	write-host "WARNING: No snapshots for $missing"
	exit 1
	}
else {
	write-host "OK - All tagged volumes have snaps in the last 24hrs"
	exit 0
	}
