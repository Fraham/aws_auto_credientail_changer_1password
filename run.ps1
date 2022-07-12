[CmdletBinding()]
param (
    [Parameter()]
    [String]
    $onePassAwsItem = "aws",

    [Parameter()]
    [String]
    $onePassAwsVault = "Private",

    [Parameter()]
    [String]
    $accessKeyLabel = "accesskey",    

    [Parameter()]
    [String]
    $secretKeyLabel = "secretkey",

    [Parameter()]
    [String]
    $totpLabel = "one-time password",

    [Parameter()]
    [String]
    $mfaDeviceLabel = "mfa device"
)

$beforeAccessKey = $null
$beforeSecretKey = $null
$totp = $null
$mfaDevice = $null

$1passwordRawData = $(op item get $onePassAwsItem --vault $onePassAwsVault --format json)

if (!$?) {
    Write-Error "Something wrong when trying to retreive the item from 1Password"
    return
}

$1passwordData = ($1passwordRawData | ConvertFrom-Json).fields 

foreach ($field in $1passwordData) {
    switch ($field.label) {
        $accessKeyLabel { 
            $beforeAccessKey = $field.value
        }
        $secretKeyLabel { 
            $beforeSecretKey = $field.value 
        }
        $totpLabel { 
            $totp = $field.totp 
        }
        $mfaDeviceLabel { 
            $mfaDevice = $field.value 
        }
    }
}

if ($null -eq $beforeAccessKey) {
    Write-Error "Something wrong - no access key"
    return
}
if ($null -eq $beforeSecretKey) {
    Write-Error "Something wrong - no secret key"
    return
}
if ($null -eq $totp) {
    Write-Error "Something wrong - no totp"
    return
}
if ($null -eq $mfaDevice) {
    Write-Error "Something wrong - no mfa device"
    return
}

$env:AWS_ACCESS_KEY_ID = $beforeAccessKey
$env:AWS_SECRET_ACCESS_KEY = $beforeSecretKey
$env:AWS_SESSION_TOKEN = $null

$mfaRawData = $(aws sts get-session-token --serial-number $mfaDevice --token-code $totp)

if (!$?) {
    Write-Error "Error getting MFA session"
    return
}

$mfaCredentials = ($mfaRawData | ConvertFrom-Json ).Credentials

$env:AWS_ACCESS_KEY_ID = $mfaCredentials.AccessKeyId
$env:AWS_SECRET_ACCESS_KEY = $mfaCredentials.SecretAccessKey
$env:AWS_SESSION_TOKEN = $mfaCredentials.SessionToken

$createKeyRawData = $(aws iam create-access-key)

if (!$?) {
    Write-Error "Error creating new access key"
    return
}

$createKeyData = ($createKeyRawData | ConvertFrom-Json).AccessKey

$newAccessKey = $createKeyData.AccessKeyId
$newSecretKey = $createKeyData.SecretAccessKey

(op item edit $onePassAwsItem --vault $onePassAwsVault "$($accessKeyLabel)=$($newAccessKey)") | Out-Null
(op item edit $onePassAwsItem --vault $onePassAwsVault "$($secretKeyLabel)=$($newSecretKey)") | Out-Null

(aws iam delete-access-key --access-key-id $beforeAccessKey) | Out-Null

