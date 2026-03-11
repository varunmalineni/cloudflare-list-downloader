# Cloudflare List Downloader

PowerShell script to export Cloudflare **Custom Lists** to CSV through an interactive menu.

## Features

- Retrieves all Cloudflare custom lists in an account
- Displays them in a numbered menu
- Lets you choose which list to download
- Automatically handles pagination
- Exports the selected list to CSV

## Requirements

- Windows PowerShell
- Cloudflare API token
- Cloudflare Account ID

## Create the API Token

1. Log in to the Cloudflare dashboard
2. Go to **Manage account → Account API Tokens**
3. Click **Create token**
4. Choose **Create Custom Token**
5. Add permission: **Account → Filter Lists → Read**
6. Scope it to your account
7. Create the token and copy it

## Find Your Account ID

Example dashboard URL:

`https://dash.cloudflare.com/ACCOUNT_ID/configurations/lists/LIST_ID`

The first value after `dash.cloudflare.com/` is your **Account ID**.

## Configure the Script

Update these values in the script:

```powershell
$TOKEN = "PASTE_YOUR_TOKEN_HERE"
$ACCOUNT_ID = "PASTE_YOUR_ACCOUNT_ID_HERE"
```

## Run

```powershell
.\Download-CloudflareLists.ps1
```

Select the list number and the script exports the list as a CSV.

## Security

Do **not** commit real API tokens to GitHub.

Replace with:

```powershell
$TOKEN = "PASTE_YOUR_TOKEN_HERE"
```