<#
.SYNOPSIS
Regenerates the "Command Reference" section of README.md from the module's actual exported functions.

.DESCRIPTION
Reads the real exported commands from PiHoleShell.psm1 (not just what's documented) and builds a
markdown table per category, using each function's own comment-based help synopsis and its
'#Work In Progress' marker (if present) for the 🚧 flag. Writes the result between the
<!-- COMMAND-REFERENCE:START --> / <!-- COMMAND-REFERENCE:END --> markers in README.md, leaving
everything else in the file untouched. Exits with a non-zero code if README.md wasn't already
up to date, so it can be used as a CI freshness check as well as a local regeneration tool.
#>
[CmdletBinding()]
param (
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..')),
    [switch]$Check
)

$ErrorActionPreference = 'Stop'

$displayNames = [ordered]@{
    Actions           = 'Actions'
    DnsControl        = 'DNS Control'
    GroupManagement   = 'Group Management'
    ListManagement    = 'List Management'
    Metrics           = 'Metrics'
    Config            = 'Configuration & Diagnostics'
    Padd              = 'Configuration & Diagnostics'
    FTLInformation    = 'Configuration & Diagnostics'
    Teleporter        = 'Configuration & Diagnostics'
    Authentication    = 'Authentication'
}
$categoryOrder = @('Actions', 'DnsControl', 'GroupManagement', 'ListManagement', 'Metrics', 'Config', 'Authentication')
$categoryIntros = @{
    Authentication = 'Session handling is automatic for every command above, but these are available for managing sessions directly:'
}

$modulePath = Join-Path $RepoRoot 'PiHoleShell/PiHoleShell.psm1'
$publicPath = Join-Path $RepoRoot 'PiHoleShell/Public'
$readmePath = Join-Path $RepoRoot 'README.md'

Import-Module $modulePath -Force
$exported = [System.Collections.Generic.HashSet[string]]::new([string[]](Get-Module PiHoleShell).ExportedCommands.Keys)

function Get-CleanSynopsis {
    param([string]$FunctionName)

    $help = Get-Help -Name $FunctionName -ErrorAction SilentlyContinue
    # Get-Help sometimes bleeds a standalone '#Work In Progress' comment that trails the closing
    # '#>' into the Synopsis text itself; that's already surfaced separately via the WIP flag.
    $rawSynopsis = ($help.Synopsis | Out-String) -replace '(?im)^\s*Work In Progress\s*$', ''
    $synopsis = ($rawSynopsis -replace '\s+', ' ').Trim()

    if ([string]::IsNullOrWhiteSpace($synopsis) -or $synopsis -match '^https?://' -or $synopsis -eq $FunctionName) {
        return $null
    }
    return $synopsis
}

$functionsByCategory = [ordered]@{}
foreach ($category in $categoryOrder) { $functionsByCategory[$category] = [System.Collections.Generic.List[object]]::new() }

Get-ChildItem -Path $publicPath -Filter '*.ps1' -Recurse | Sort-Object BaseName | ForEach-Object {
    $name = $_.BaseName
    if (-not $exported.Contains($name)) { return }

    $rawCategory = $_.Directory.Name
    $category = if ($categoryOrder -contains $rawCategory) { $rawCategory } else { 'Config' }

    $content = Get-Content -Path $_.FullName -Raw
    $isWip = $content -match '#\s*Work In Progress'
    $synopsis = Get-CleanSynopsis -FunctionName $name
    if (-not $synopsis) { $synopsis = '_No description yet_' }

    $functionsByCategory[$category].Add([PSCustomObject]@{
            Name     = $name
            Synopsis = $synopsis
            IsWip    = $isWip
        })
}

$sections = [System.Collections.Generic.List[string]]::new()
foreach ($category in $categoryOrder) {
    $functions = $functionsByCategory[$category]
    if ($functions.Count -eq 0) { continue }

    $sections.Add("### $($displayNames[$category])")
    $sections.Add('')
    if ($categoryIntros.ContainsKey($category)) {
        $sections.Add($categoryIntros[$category])
        $sections.Add('')
    }
    $sections.Add('| Function | Description |')
    $sections.Add('|---|---|')
    foreach ($fn in $functions) {
        $flag = if ($fn.IsWip) { ' 🚧' } else { '' }
        $sections.Add("| ``$($fn.Name)``$flag | $($fn.Synopsis) |")
    }
    $sections.Add('')
}

$generated = ($sections -join "`n").TrimEnd()

$readme = Get-Content -Path $readmePath -Raw
$startMarker = '<!-- COMMAND-REFERENCE:START -->'
$endMarker = '<!-- COMMAND-REFERENCE:END -->'

if ($readme -notmatch [regex]::Escape($startMarker) -or $readme -notmatch [regex]::Escape($endMarker)) {
    throw "README.md is missing the $startMarker / $endMarker markers."
}

$pattern = [regex]::Escape($startMarker) + '(?s).*?' + [regex]::Escape($endMarker)
$replacement = "$startMarker`n$generated`n$endMarker"
$newReadme = [regex]::Replace($readme, $pattern, { $replacement })

if ($Check) {
    if ($newReadme -ne $readme) {
        Write-Error 'README.md command reference is out of date. Run tools/Update-ReadmeCommandReference.ps1 to refresh it.'
        exit 1
    }
    Write-Output 'README.md command reference is up to date.'
    exit 0
}

if ($newReadme -ne $readme) {
    Set-Content -Path $readmePath -Value $newReadme -NoNewline
    Write-Output 'README.md command reference updated.'
}
else {
    Write-Output 'README.md command reference already up to date.'
}
