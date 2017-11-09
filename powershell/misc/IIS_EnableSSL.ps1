# This script will pull down a cert from the local CA and create https bindings for all existing IIS sites
# Assumes domain integrated Microsoft Certificate Authority and the need for SNI
# Replace Url with the LDAP address of your local CA, and template with your intended template, and run from the local webserver


$error.clear()

Import-Module Webadministration

# Pull cert from CA

$servername = ([System.Net.Dns]::GetHostByName(($env:computerName))).hostname

write-host "Working on $servername"

$cert = (get-childitem Cert:\LocalMachine\my | ?{$_.Subject -eq "CN=$servername"})

if ($cert -eq $null) {

    write-host "No local cert found, pulling one down from CA..."
    Get-Certificate -template "WebServer" -CertStoreLocation cert:\localmachine\my -subjectname "CN=$servername" -DnsName $servername -Url "ldap:///CN=SERVER-CA,DC=domain,DC=local"
    $thumbprint = (get-childitem Cert:\LocalMachine\my | ?{$_.Subject -eq "CN=$servername"}).thumbprint
    }

    elseif ($cert.notafter -lt (get-date).AddDays(60)) {
         write-host "Cert found but expiring soon; pulling new one and clearing bindings"
         $cert | remove-item
         Get-WebBinding -port 443 | Remove-WebBinding
         Get-Certificate -template "WebServer" -CertStoreLocation cert:\localmachine\my -subjectname "CN=$servername" -DnsName $servername -Url "ldap:///CN=SERVER-CA,DC=domain,DC=local"
         $thumbprint = (get-childitem Cert:\LocalMachine\my | ?{$_.Subject -eq "CN=$servername"}).thumbprint
         }

     else {
       write-host "Existing cert found; using"
       $thumbprint = $cert.Thumbprint
     }



if ($error -ne $null) {
		write-host $error
		exit 2
	}


# Get all IIS sites

$sites = get-childitem -path IIS:\sites | ?{$_.state -eq "Started"}

# Remove Default web site from array

#$sites = $sites[1..($sites.Length-1)]

# Do the needful

foreach ($site in $sites) {

    if ($site.bindings.Collection.protocol -notcontains "https") {
        write-host "Non-SSL Site found" $site.name
		# boil binding down to a hostname
		[regex]$ip="\b\d{1,3}\.\d{1,3}\.\d{1,3}\.\d{1,3}\b"
		$bindings = $site.bindings.Collection.bindinginformation
		$bindings = $bindings -replace $ip
        $hostname = $bindings.TrimStart(" ","*"," ",":"," ","8"," ","0"," ",":")
        $guid = [guid]::NewGuid().ToString("B")
        # If it's a wildcard binding, skip SNI and bind to IP
		if ($hostname -eq "") {
				netsh http delete sslcert ipport=0.0.0.0:443 > $null
				netsh http add sslcert ipport=0.0.0.0:443 certhash=$thumbprint certstorename=MY appid="$guid"
				New-WebBinding -name $site.name -Port 443 -Protocol https -SslFlags 0
		}
		elseif ($hostname -is [system.array]) {
				foreach ($h in $hostname) {
					        netsh http delete sslcert hostnameport="${h}:443" > $null
							netsh http add sslcert hostnameport="${h}:443" certhash=$thumbprint certstorename=MY appid="$guid"
							New-WebBinding -name $site.name -Protocol https -HostHeader $h -Port 443 -SslFlags 1
					}
				}
		else {
            netsh http delete sslcert hostnameport="${hostname}:443" > $null
            netsh http add sslcert hostnameport="${hostname}:443" certhash=$thumbprint certstorename=MY appid="$guid"
            New-WebBinding -name $site.name -Protocol https -HostHeader $hostname -Port 443 -SslFlags 1
		  }
		}
    }