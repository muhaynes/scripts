# Powershell script to encrypt the contents of an S3 bucket with your specified credentials 
# Usage: .\encrypt-S3Objects.ps1 -creds <StoreAs Creds name> -region <region> -bucket <bucketname> -kmskey <########-####-####-####-############> <-whatif>
# KMS key must live in region you specify
# Recommendation is to run the -whatif flag to ensure you're doing what you think you're doing

param([string] $creds, [string] $region, [string] $bucket, [string] $KMSKey, [switch]$WhatIf)

$error.clear()
Import-Module "C:\Program Files (x86)\AWS Tools\PowerShell\AWSPowerShell\AWSPowerShell.psd1"
Set-AWSCredentials $creds
Set-DefaultAWSRegion $region
$encrypts = 0
$keys = (get-s3object $bucket).key

foreach ($Key in $keys) {
    

    if ((Get-S3ObjectMetadata -BucketName $bucket -Key $Key).ServerSideEncryptionMethod -ne "aws:kms") {
        if ($Whatif) {
        write-host "Found Unencrypted file $key in $bucket.. Would be encrypting it to $KMSKEy";
        $encrypts++
            }
        else {
        write-host "Found Unencrypted file $key in $bucket.. Encrypting now";
        Copy-S3Object -BucketName $bucket -Key $key -DestinationBucket $bucket -DestinationKey $key -ServerSideEncryptionKeyManagementServiceKeyId $KMSKey -ServerSideEncryption aws:kms;
        $encrypts++
            }
        }
    }

if ($error -ne $null){
    write-host $_
    exit 1
    }
elseif ($Whatif){
    write-host "OK - Number of files we would have encrypted: $encrypts"
    exit 0
    }
else {
    write-host "OK - Number of files encrypted: $encrypts"
    exit 0
    }



