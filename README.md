# AWS Auto Credential Changer For 1Password

Script to update the access keys used for the AWS CLI and then saved into a 1Password item.

## Requirements

- AWS CLI
- 1Password CLI

## Process

1. Script gets the current access keys and MFA information from 1Password
1. Creates a new AWS session
1. Creates a new set of access keys on AWS
1. Updates the 1Password item with the new keys
1. Deletes the existing key from AWS

## Usage

- Use default values
  ```powershell
  pwsh ./run.ps1
  ```
- or override any of the parameters
  ```powershell
  pwsh ./run.ps1 -onePassAwsItem 'aws' -onePassAwsVault 'Private' -accessKeyLabel 'accesskey' -secretKeyLabel 'secretaccesskey' -totpLabel 'one-time password' -mfaDeviceLabel 'mfaserial'
  ```

## Default 1Password Item setup

- Item name: `aws`
- Vault: `Private`
- AWS Access key label: `accesskey`
- AWS Secret key label: `secretaccesskey`
- One time password label: `one-time password`
- MFA Device label: `mfaserial`
