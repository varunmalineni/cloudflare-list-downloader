$TOKEN = "YOUR_BEARER_TOKEN"
$ACCOUNT_ID = "YOUR_ACCOUNT_ID"

# =========================
# Cloudflare List Downloader
# =========================


$headers = @{
    Authorization = "Bearer $TOKEN"
    "Content-Type" = "application/json"
}

function Get-CloudflareLists {
    param (
        [string]$AccountId,
        [hashtable]$Headers
    )

    $uri = "https://api.cloudflare.com/client/v4/accounts/$AccountId/rules/lists"

    $response = Invoke-RestMethod -Method GET -Uri $uri -Headers $Headers

    if (-not $response.success) {
        throw "Failed to retrieve lists from Cloudflare."
    }

    return @($response.result)
}

function Get-AllListItems {
    param (
        [string]$AccountId,
        [string]$ListId,
        [hashtable]$Headers
    )

    $allItems = @()
    $cursor = $null

    do {
        $uri = "https://api.cloudflare.com/client/v4/accounts/$AccountId/rules/lists/$ListId/items?per_page=500"

        if ($cursor) {
            $uri += "&cursor=$cursor"
        }

        $response = Invoke-RestMethod -Method GET -Uri $uri -Headers $Headers

        if (-not $response.success) {
            throw "Failed to retrieve items for list ID $ListId"
        }

        $allItems += @($response.result)

        if ($response.result_info -and $response.result_info.cursors) {
            $cursor = $response.result_info.cursors.after
        }
        else {
            $cursor = $null
        }
    }
    while ($cursor)

    return $allItems
}

function Sanitize-FileName {
    param (
        [string]$Name
    )

    $invalidChars = [System.IO.Path]::GetInvalidFileNameChars()
    $safeName = $Name

    foreach ($char in $invalidChars) {
        $safeName = $safeName.Replace($char, "_")
    }

    return $safeName
}

try {
    Write-Host ""
    Write-Host "Getting Cloudflare lists..." -ForegroundColor Cyan

    $lists = Get-CloudflareLists -AccountId $ACCOUNT_ID -Headers $headers

    if (-not $lists -or $lists.Count -eq 0) {
        Write-Host "No lists found." -ForegroundColor Yellow
        exit
    }

    $sortedLists = $lists | Sort-Object name

    Write-Host ""
    Write-Host "Available lists:" -ForegroundColor Green
    Write-Host "----------------"

    for ($i = 0; $i -lt $sortedLists.Count; $i++) {
        $itemCount = if ($null -ne $sortedLists[$i].num_items) { $sortedLists[$i].num_items } else { "?" }
        $kind = if ($null -ne $sortedLists[$i].kind) { $sortedLists[$i].kind } else { "unknown" }

        Write-Host ("{0}. {1} [{2}] ({3} items)" -f ($i + 1), $sortedLists[$i].name, $kind, $itemCount)
    }

    Write-Host ""
    $selection = Read-Host "Enter the number of the list you want to download"

    if (-not ($selection -match '^\d+$')) {
        throw "Invalid selection. Please enter a valid number."
    }

    $selectionNumber = [int]$selection

    if ($selectionNumber -lt 1 -or $selectionNumber -gt $sortedLists.Count) {
        throw "Selection out of range."
    }

    $selectedList = $sortedLists[$selectionNumber - 1]

    Write-Host ""
    Write-Host "Selected list: $($selectedList.name)" -ForegroundColor Cyan
    Write-Host "Downloading items..." -ForegroundColor Cyan

    $items = Get-AllListItems -AccountId $ACCOUNT_ID -ListId $selectedList.id -Headers $headers

    if (-not $items -or $items.Count -eq 0) {
        Write-Host "The selected list is empty." -ForegroundColor Yellow
        exit
    }

    $exportRows = foreach ($item in $items) {
        [PSCustomObject]@{
            value       = if ($item.ip) { $item.ip } elseif ($item.hostname) { $item.hostname } elseif ($item.asn) { $item.asn } else { $null }
            comment     = $item.comment
            created_on  = $item.created_on
            modified_on = $item.modified_on
        }
    }

    $safeFileName = Sanitize-FileName -Name $selectedList.name
    $outputFile = ".\{0}.csv" -f $safeFileName

    $exportRows | Export-Csv -Path $outputFile -NoTypeInformation -Encoding UTF8

    Write-Host ""
    Write-Host "Done. Exported $($exportRows.Count) items to $outputFile" -ForegroundColor Green
}
catch {
    Write-Host ""
    Write-Host "Error: $($_.Exception.Message)" -ForegroundColor Red
}