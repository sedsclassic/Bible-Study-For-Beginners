# Get-StudyIndex.ps1
# Place this script in the folder with your HTML files and run it.
# It reads every .html file, pulls the <h1> text, and writes index.json.

$folder     = $PSScriptRoot
if (-not $folder) { $folder = (Get-Location).Path }
$outputFile = Join-Path $folder "index.json"

$results = foreach ($file in Get-ChildItem -Path $folder -Filter *.html -File | Sort-Object Name) {

    # Read as UTF-8 so characters like — and ▶ aren't mangled
    $html = Get-Content -Path $file.FullName -Raw -Encoding UTF8

    $title = $null
    if ($html -match '(?is)<h1[^>]*>(.*?)</h1>') {
        $title = $Matches[1]
        $title = $title -replace '<[^>]+>', ''                       # strip any nested tags
        $title = [System.Net.WebUtility]::HtmlDecode($title)         # decode &amp; etc.
        $title = ($title -replace '\s+', ' ').Trim()                 # collapse whitespace
    }
    else {
        Write-Warning "No <h1> found in $($file.Name)"
    }

    [PSCustomObject]@{
        filename = $file.Name
        title    = $title
    }
}

# Wrap in @() so a single file still outputs a JSON array
$json = ConvertTo-Json -InputObject @($results) -Depth 3

# Write UTF-8 without BOM (works on Windows PowerShell 5.1 and PowerShell 7+)
[System.IO.File]::WriteAllText($outputFile, $json, (New-Object System.Text.UTF8Encoding($false)))

Write-Host "Done. $(@($results).Count) file(s) written to $outputFile"