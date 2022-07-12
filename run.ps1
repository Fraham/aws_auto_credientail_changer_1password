#TODO: move to params
$1passwordAwsItem = "aws"
$1passwordAwsVault = "Private"

$beforeAccessKey = $null
$beforeSecretKey = $null


$totp = $null

$1passwordRawData = $(op item get $1passwordAwsItem --vault $1passwordAwsVault --format json)

if (!$?){
    Write-Error "Something wrong"
    return
}

$1passwordData = ($1passwordRawData | ConvertFrom-Json)

$1passwordData.fields | ForEach-Object {
    if ($_.label -eq "accesskey"){
        $beforeAccessKey = $_.value
    }
    if ($_.label -eq "secretkey"){
        $beforeSecretKey = $_.value
    }
    if ($_.label -eq "one-time password"){
        $totp = $_.totp
    }
}

if ($null -eq $beforeAccessKey){
    Write-Error "Something wrong - no access key"
    return
}
if ($null -eq $beforeSecretKey){
    Write-Error "Something wrong - no secret key"
    return
}
if ($null -eq $totp){
    Write-Error "Something wrong - no totp"
    return
}

#TODO: remove these
Write-Host $beforeAccessKey
Write-Host $beforeSecretKey
Write-Host $totp

#TODO: auth mfa with aws
#TODO: create new access keys
#TODO: save new access keys to 1password
#TODO: remove the old access keys