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
    Write-Error "Something wrong"
    return
}

$1passwordData = ($1passwordRawData | ConvertFrom-Json)

$1passwordData.fields | ForEach-Object {
    #TODO: change to switch
    if ($_.label -eq $accessKeyLabel ) {
        $beforeAccessKey = $_.value
    }
    if ($_.label -eq $secretKeyLabel) {
        $beforeSecretKey = $_.value
    }
    if ($_.label -eq $totpLabel) {
        $totp = $_.totp
    }
    if ($_.label -eq $mfaDeviceLabel) {
        $mfaDevice = $_.value
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

#TODO: remove these
Write-Host $beforeAccessKey
Write-Host $beforeSecretKey
Write-Host $totp
Write-Host $mfaDevice

$env:AWS_ACCESS_KEY_ID = $beforeAccessKey
$env:AWS_SECRET_ACCESS_KEY = $beforeSecretKey
$env:AWS_SESSION_TOKEN = $null

$mfaRawData = $(aws sts get-session-token --serial-number $mfaDevice --token-code $totp)

if (!$?) {
    Write-Error "Error getting MFA session"
    return
}

$mfaCredentials = ($mfaRawData | ConvertFrom-Json ).Credentials

Write-Host $mfaCredentials

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

#TODO: remove these
Write-Host $newAccessKey
Write-Host $newSecretKey

(op item edit $onePassAwsItem --vault $onePassAwsVault "$($accessKeyLabel)=$($newAccessKey)") | Out-Null
(op item edit $onePassAwsItem --vault $onePassAwsVault "$($secretKeyLabel)=$($newSecretKey)") | Out-Null

(aws iam delete-access-key --access-key-id $beforeAccessKey) | Out-Null

