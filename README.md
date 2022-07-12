# AWS Auto Credential Changer For 1Password

Script to update the access keys used for the AWS CLI and then saved into a 1Password item.

## Requirements

* AWS CLI
* 1Password CLI

## Process

1. Script gets the current access keys and MFA information from 1Password
1. Creates a new AWS session
1. Creates a new set of access keys on AWS
1. Updates the 1Password item with the new keys
1. Deletes the existing key from AWS

## Usage

TODO: this section

## 1Password Item setup

TODO: this section