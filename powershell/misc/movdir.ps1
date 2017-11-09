# Script to move specified folder between disks. Creates junction at old location, inherits folder structure on destination disk
# Place in PATH for best results
# eg: .\movdir.ps1 -path c:\games\game1 -destination E:

Param(
  [string]$path,
  [string]$target
)

if ($path -eq ""-or $target -eq "") {
	write-host "Usage: movdir.ps1 -path <existing location> -target <new drive>, eg. movdir.ps1 -path c:\games\game1 -target E:"
	exit 1
	}

$src = get-item $path 
$dst = get-item $target
$disk = $dst.root
$folder = $src.fullname
$folder = $folder -replace "(^[a-zA-Z]:\\)",""
$destination = "$disk"+"$folder"
$testdst = get-item $destination -erroraction 'silentlycontinue'

if ($testdst -ne $null) {
		if ($testdst.linktype -eq "Junction") {
			[ValidateSet('Y','N')]$Answer = Read-Host "There is an existing link here, remove and relocated data? (Y/N)"
				if ($Answer -eq "N") {
					write-host "Aborting."
					exit 1			
				}
				else {
					write-host "Removing existing Junction..."
					cmd /c rmdir $testdst
				}
		}
		else {
			write-host "Error, $testdst exists and is not a Junction. Aborting."
			exit 1		
		}
    }


if ($src -eq $null -or $dst -eq $null) {
    Write-host "Folder doesn't exist, aborting" 
    exit 3
    }

[ValidateSet('Y','N')]$Answer = Read-Host "This will move $src to  $destination, continue? (Y/N)"


if ($Answer -eq "N") {
    Write-host "Aborting" 
    exit 3
    }

write-host "Moving $src to $destination..."

move-item $src -Destination $destination -force 

write-host "Creating Symbolic link to new physical location"

New-Item -Path $src -ItemType Junction -Value $destination




    