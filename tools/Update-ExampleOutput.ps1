<#
.SYNOPSIS
Regenerates docs/EXAMPLES.md with real, captured output from every exported PiHoleShell function.

.DESCRIPTION
Runs each exported function against a real Pi-hole server (using tests/IntegrationConfig.local.ps1
for credentials, same as the integration tests) and captures its actual output into a per-function
Markdown section, grouped the same way as README.md's Command Reference.

State-changing functions that create/update/delete a real resource (groups, lists, sessions) do so
against a clearly-named throwaway resource ("PiHoleShellDocsExample...") that is removed immediately
after its output is captured - the same create/verify/cleanup pattern already used throughout this
module's own integration tests.

Functions with real, non-trivial side effects on a live system (rebuilding gravity, restarting the
DNS resolver, flushing the network/query log tables, toggling DNS blocking) are NOT invoked by
default. Pass -IncludeDisruptive to also live-capture those; without it, their sections keep a
static, dated example that was captured previously and is embedded in this script.

.PARAMETER IncludeDisruptive
Also live-run functions with real side effects on a running Pi-hole server: gravity rebuild, DNS
service restart, network/query-log flush, and DNS blocking toggle. Off by default.

.PARAMETER RepoRoot
Path to the repository root. Defaults to the parent of this script's folder.
#>
[CmdletBinding()]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingWriteHost', '', Justification = 'Console progress/status output for an interactive tool script, not module code.')]
[Diagnostics.CodeAnalysis.SuppressMessageAttribute('PSAvoidUsingEmptyCatchBlock', '', Justification = 'Invoke-Quietly intentionally swallows errors for best-effort setup/cleanup calls that are not the example being documented.')]
param (
    [switch]$IncludeDisruptive,
    [string]$RepoRoot = (Resolve-Path (Join-Path $PSScriptRoot '..'))
)

$ErrorActionPreference = 'Stop'

$modulePath = Join-Path $RepoRoot 'PiHoleShell/PiHoleShell.psm1'
$configPath = Join-Path $RepoRoot 'tests/IntegrationConfig.local.ps1'
$outputPath = Join-Path $RepoRoot 'docs/EXAMPLES.md'

if (-not (Test-Path $configPath)) {
    throw "Missing $configPath - copy it from tests/IntegrationConfig.example.ps1 and fill in your real Pi-hole server details first."
}

Import-Module $modulePath -Force
. $configPath
# $PiHoleServer, $PiHoleToken, $PiHoleIgnoreSsl are now set by the config file above.

$categoryOrder = [ordered]@{
    Actions         = 'Actions'
    DnsControl      = 'DNS Control'
    GroupManagement = 'Group Management'
    ListManagement  = 'List Management'
    Metrics         = 'Metrics'
    Config          = 'Configuration & Diagnostics'
    Authentication  = 'Authentication'
}
$sectionsByCategory = [ordered]@{}
foreach ($key in $categoryOrder.Keys) { $sectionsByCategory[$key] = [System.Collections.Generic.List[object]]::new() }

function Add-Example {
    param (
        [Parameter(Mandatory)] [string]$Category,
        [Parameter(Mandatory)] [string]$FunctionName,
        [Parameter(Mandatory)] [string]$Invocation,
        [string]$Note,
        $Result,
        [switch]$Skipped,
        [string]$StaticOutput
    )

    if ($Skipped -and $StaticOutput) {
        $output = "$StaticOutput`n`n_(A real example captured previously - not re-run by default since this function has a real side effect on a live server. Pass -IncludeDisruptive to capture a fresh one.)_"
    }
    elseif ($Skipped) {
        $output = "_Not captured this run - re-run with -IncludeDisruptive to include a live example._"
    }
    elseif ($null -eq $Result -or ($Result -is [array] -and $Result.Count -eq 0)) {
        $output = '(no output)'
    }
    else {
        $items = @($Result)
        $truncated = $items.Count -gt 5
        $shown = if ($truncated) { $items | Select-Object -First 5 } else { $items }
        $output = ($shown | Format-List | Out-String).TrimEnd()
        if ($truncated) {
            $output += "`n`n_(showing 5 of $($items.Count) results)_"
        }
    }

    $sectionsByCategory[$Category].Add([PSCustomObject]@{
            FunctionName = $FunctionName
            Invocation   = $Invocation
            Note         = $Note
            Output       = $output
        })
}

function Invoke-Quietly {
    # Runs a state-changing call purely for its side effect (setup/cleanup between examples)
    # without that call itself becoming a documented example.
    param([scriptblock]$ScriptBlock)
    try { & $ScriptBlock | Out-Null } catch { }
}

Write-Host "Capturing example output against $PiHoleServer ..."

#region Authentication
Add-Example -Category Authentication -FunctionName 'Get-PiHoleCurrentAuthSession' `
    -Invocation 'Get-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Password $Password' `
    -Result (Get-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl)

# Remove-PiHoleAuthSession/-CurrentAuthSession both end a session, so each needs its own throwaway
# session to remove rather than the one the documented call itself would otherwise need to log in
# with - removing your only active session out from under yourself isn't something to demonstrate.
$null = & (Get-Module PiHoleShell) { param($s, $p, $i) Request-PiHoleAuth -PiHoleServer $s -Password $p -IgnoreSsl $i } $PiHoleServer $PiHoleToken $PiHoleIgnoreSsl
Start-Sleep -Seconds 1
# Excludes CurrentSession (Get-PiHoleCurrentAuthSession's own transient session for this very
# call) so this reliably picks $extraSid1 above rather than the session used to look it up.
$extraSessionId = (Get-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl | Where-Object { -not $_.CurrentSession } | Sort-Object LoginAt -Descending | Select-Object -First 1).Id
Add-Example -Category Authentication -FunctionName 'Remove-PiHoleAuthSession' `
    -Invocation "Remove-PiHoleAuthSession -PiHoleServer `$PiHoleServer -Password `$Password -Id $extraSessionId" `
    -Note 'Deletes a session by its ID (as shown by Get-PiHoleCurrentAuthSession), not the caller''s own session.' `
    -Result (Remove-PiHoleAuthSession -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl -Id $extraSessionId)

$extraSid2 = & (Get-Module PiHoleShell) { param($s, $p, $i) Request-PiHoleAuth -PiHoleServer $s -Password $p -IgnoreSsl $i } $PiHoleServer $PiHoleToken $PiHoleIgnoreSsl
Add-Example -Category Authentication -FunctionName 'Remove-PiHoleCurrentAuthSession' `
    -Invocation 'Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid' `
    -Note 'The internal best-effort logout every other function calls automatically when it finishes - it never produces output, even on failure (a warning only). Shown here for completeness since it is still a publicly exported function.' `
    -Result $null
Invoke-Quietly { Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $extraSid2 -IgnoreSsl $PiHoleIgnoreSsl }
#endregion

#region DnsControl
Add-Example -Category DnsControl -FunctionName 'Get-PiHoleDnsBlockingStatus' `
    -Invocation 'Get-PiHoleDnsBlockingStatus -PiHoleServer $PiHoleServer -Password $Password' `
    -Result (Get-PiHoleDnsBlockingStatus -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl)

if ($IncludeDisruptive) {
    Add-Example -Category DnsControl -FunctionName 'Set-PiHoleDnsBlocking' `
        -Invocation 'Set-PiHoleDnsBlocking -PiHoleServer $PiHoleServer -Password $Password -Blocking False -TimeInSeconds 5' `
        -Note 'Temporarily disables blocking, then it re-enables automatically after the given time.' `
        -Result (Set-PiHoleDnsBlocking -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl -Blocking False -TimeInSeconds 5)
    Start-Sleep -Seconds 6
}
else {
    Add-Example -Category DnsControl -FunctionName 'Set-PiHoleDnsBlocking' `
        -Invocation 'Set-PiHoleDnsBlocking -PiHoleServer $PiHoleServer -Password $Password -Blocking False -TimeInSeconds 60' -Skipped
}
#endregion

#region Config
Add-Example -Category Config -FunctionName 'Get-PiHoleConfig' `
    -Invocation 'Get-PiHoleConfig -PiHoleServer $PiHoleServer -Password $Password' `
    -Result (Get-PiHoleConfig -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl)

Add-Example -Category Config -FunctionName 'Get-PiHolePadd' `
    -Invocation 'Get-PiHolePadd -PiHoleServer $PiHoleServer -Password $Password' `
    -Result (Get-PiHolePadd -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl)

foreach ($fn in 'Get-PiHoleInfoHost', 'Get-PiHoleInfoSystem', 'Get-PiHoleInfoFtl', 'Get-PiHoleInfoSensors', 'Get-PiHoleInfoDatabase', 'Get-PiHoleInfoVersion', 'Get-PiHoleInfoMetrics') {
    Add-Example -Category Config -FunctionName $fn `
        -Invocation "$fn -PiHoleServer `$PiHoleServer -Password `$Password" `
        -Result (& $fn -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl)
}

Add-Example -Category Config -FunctionName 'Get-PiHoleInfoClient' `
    -Invocation 'Get-PiHoleInfoClient -PiHoleServer $PiHoleServer' `
    -Note 'Does not require -Password - the API does not authenticate this endpoint.' `
    -Result (Get-PiHoleInfoClient -PiHoleServer $PiHoleServer -IgnoreSsl $PiHoleIgnoreSsl)

Add-Example -Category Config -FunctionName 'Get-PiHoleInfoLogin' `
    -Invocation 'Get-PiHoleInfoLogin -PiHoleServer $PiHoleServer' `
    -Note 'Does not require -Password - the API does not authenticate this endpoint (it is meant to be usable before logging in).' `
    -Result (Get-PiHoleInfoLogin -PiHoleServer $PiHoleServer -IgnoreSsl $PiHoleIgnoreSsl)

Add-Example -Category Config -FunctionName 'Get-PiHoleInfoMessage' `
    -Invocation 'Get-PiHoleInfoMessage -PiHoleServer $PiHoleServer -Password $Password' `
    -Result (Get-PiHoleInfoMessage -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl)

Add-Example -Category Config -FunctionName 'Get-PiHoleInfoMessageCount' `
    -Invocation 'Get-PiHoleInfoMessageCount -PiHoleServer $PiHoleServer -Password $Password' `
    -Result (Get-PiHoleInfoMessageCount -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl)

$dummyMessageId = 999999
Remove-PiHoleInfoMessage -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl -MessageId $dummyMessageId -Confirm:$false -ErrorVariable removeMessageError -ErrorAction SilentlyContinue | Out-Null
Add-Example -Category Config -FunctionName 'Remove-PiHoleInfoMessage' `
    -Invocation 'Remove-PiHoleInfoMessage -PiHoleServer $PiHoleServer -Password $Password -MessageId 3' `
    -Note 'Diagnosis messages arise from real FTL warnings and cannot be manufactured on demand, so this example shows the error for a message ID that does not exist rather than a fabricated success.' `
    -Result $(if ($removeMessageError) { [PSCustomObject]@{ Error = $removeMessageError[-1].Exception.Message } })

Add-Example -Category Config -FunctionName 'Get-PiHoleLogWebserver' `
    -Invocation 'Get-PiHoleLogWebserver -PiHoleServer $PiHoleServer -Password $Password' `
    -Result (Get-PiHoleLogWebserver -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl)

$teleporterFolder = Join-Path ([System.IO.Path]::GetTempPath()) 'PiHoleShellDocsExample'
if (Test-Path $teleporterFolder) { Remove-Item $teleporterFolder -Recurse -Force }
New-Item -ItemType Directory -Path $teleporterFolder | Out-Null
Add-Example -Category Config -FunctionName 'Get-PiHoleTeleporterDownload' `
    -Invocation 'Get-PiHoleTeleporterDownload -PiHoleServer $PiHoleServer -Password $Password -FolderPath "C:\Backups" -FileName "pihole-backup"' `
    -Note 'FolderPath/FileName are yours to choose; the captured output below used a scratch temp folder for this run instead of C:\Backups.' `
    -Result (Get-PiHoleTeleporterDownload -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl -FolderPath $teleporterFolder -FileName 'pihole-backup')
Remove-Item $teleporterFolder -Recurse -Force
#endregion

#region GroupManagement
$docsGroupName = 'PiHoleShellDocsExampleGroup'
Invoke-Quietly { Remove-PiHoleGroup -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl -GroupName $docsGroupName -WarningAction SilentlyContinue }

Add-Example -Category GroupManagement -FunctionName 'New-PiHoleGroup' `
    -Invocation "New-PiHoleGroup -PiHoleServer `$PiHoleServer -Password `$Password -GroupName `"$docsGroupName`" -Comment `"Example group`"" `
    -Result (New-PiHoleGroup -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl -GroupName $docsGroupName -Comment 'Example group')

# Same settle-time reasoning as the list section below - give the test server a moment before
# relying on the group just being created.
Start-Sleep -Seconds 3

Add-Example -Category GroupManagement -FunctionName 'Get-PiHoleGroup' `
    -Invocation 'Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password' `
    -Result (Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl)

Add-Example -Category GroupManagement -FunctionName 'Update-PiHoleGroup' `
    -Invocation "Update-PiHoleGroup -PiHoleServer `$PiHoleServer -Password `$Password -GroupName `"$docsGroupName`" -Enabled `$false" `
    -Result (Update-PiHoleGroup -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl -GroupName $docsGroupName -Enabled $false)

Add-Example -Category GroupManagement -FunctionName 'Remove-PiHoleGroup' `
    -Invocation "Remove-PiHoleGroup -PiHoleServer `$PiHoleServer -Password `$Password -GroupName `"$docsGroupName`"" `
    -Result (Remove-PiHoleGroup -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl -GroupName $docsGroupName)
#endregion

#region ListManagement
$docsListAddress = 'https://blocklistproject.github.io/Lists/alt-version/ransomware-nl.txt'
Invoke-Quietly { Remove-PiHoleList -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl -Address $docsListAddress -Type Block -Confirm:$false }

Add-Example -Category ListManagement -FunctionName 'Add-PiHoleList' `
    -Invocation "Add-PiHoleList -PiHoleServer `$PiHoleServer -Password `$Password -Address `"$docsListAddress`" -Type Block -Comment `"Example list`"" `
    -Result (Add-PiHoleList -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl -Address $docsListAddress -Type Block -Comment 'Example list')

# The test server takes a moment to make a just-added list queryable again - a real hardware
# limitation of this Pi Zero W, not a module bug (confirmed by re-running the same calls a few
# seconds apart by hand). Give it a moment before relying on the list existing below.
Start-Sleep -Seconds 3

Add-Example -Category ListManagement -FunctionName 'Get-PiHoleList' `
    -Invocation 'Get-PiHoleList -PiHoleServer $PiHoleServer -Password $Password' `
    -Result (Get-PiHoleList -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl)

Add-Example -Category ListManagement -FunctionName 'Update-PiHoleList' `
    -Invocation "Update-PiHoleList -PiHoleServer `$PiHoleServer -Password `$Password -Address `"$docsListAddress`" -Type Block -Enabled `$false" `
    -Result (Update-PiHoleList -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl -Address $docsListAddress -Type Block -Enabled $false)

Add-Example -Category ListManagement -FunctionName 'Search-PiHoleListDomain' `
    -Invocation 'Search-PiHoleListDomain -PiHoleServer $PiHoleServer -Password $Password -Domain "doubleclick.net"' `
    -Result (Search-PiHoleListDomain -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl -Domain 'doubleclick.net')

Add-Example -Category ListManagement -FunctionName 'Remove-PiHoleList' `
    -Invocation "Remove-PiHoleList -PiHoleServer `$PiHoleServer -Password `$Password -Address `"$docsListAddress`" -Type Block" `
    -Result (Remove-PiHoleList -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl -Address $docsListAddress -Type Block -Confirm:$false)
#endregion

#region Metrics
foreach ($fn in 'Get-PiHoleStatsSummary', 'Get-PiHoleStatsRecentBlocked', 'Get-PiHoleStatsQueryType', 'Get-PiHoleStatsTopDomain', 'Get-PiHoleStatsTopClient', 'Get-PiHoleStatsUpstream', 'Get-PiHoleStatsQuerySuggestions') {
    Add-Example -Category Metrics -FunctionName $fn `
        -Invocation "$fn -PiHoleServer `$PiHoleServer -Password `$Password" `
        -Result (& $fn -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl)
}

foreach ($fn in 'Get-PiHoleStatsDatabaseSummary', 'Get-PiHoleStatsDatabaseQueryType', 'Get-PiHoleStatsDatabaseTopDomain', 'Get-PiHoleStatsDatabaseTopClient', 'Get-PiHoleStatsDatabaseUpstream') {
    Add-Example -Category Metrics -FunctionName $fn `
        -Invocation "$fn -PiHoleServer `$PiHoleServer -Password `$Password" `
        -Note 'Defaults to the last 8 hours; pass -From/-Until for a different window.' `
        -Result (& $fn -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl)
}
#endregion

#region History
# The History folder isn't its own README category (Update-ReadmeCommandReference.ps1 folds it,
# and a few other small folders, into "Configuration & Diagnostics") - matching that here too.
foreach ($fn in 'Get-PiHoleHistory', 'Get-PiHoleHistoryClient') {
    Add-Example -Category Config -FunctionName $fn `
        -Invocation "$fn -PiHoleServer `$PiHoleServer -Password `$Password" `
        -Result (& $fn -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl)
}
foreach ($fn in 'Get-PiHoleHistoryDatabase', 'Get-PiHoleHistoryDatabaseClient') {
    Add-Example -Category Config -FunctionName $fn `
        -Invocation "$fn -PiHoleServer `$PiHoleServer -Password `$Password" `
        -Note 'Defaults to the last 8 hours; pass -From/-Until for a different window.' `
        -Result (& $fn -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl)
}
#endregion

#region Actions
if ($IncludeDisruptive) {
    Add-Example -Category Actions -FunctionName 'Invoke-PiHoleFlushNetwork' `
        -Invocation 'Invoke-PiHoleFlushNetwork -PiHoleServer $PiHoleServer -Password $Password' `
        -Result (Invoke-PiHoleFlushNetwork -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl -Confirm:$false)

    Add-Example -Category Actions -FunctionName 'Invoke-PiHoleFlushLogs' `
        -Invocation 'Invoke-PiHoleFlushLogs -PiHoleServer $PiHoleServer -Password $Password' `
        -Result (Invoke-PiHoleFlushLogs -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl -Confirm:$false)

    Add-Example -Category Actions -FunctionName 'Restart-PiHoleDnsService' `
        -Invocation 'Restart-PiHoleDnsService -PiHoleServer $PiHoleServer -Password $Password' `
        -Result (Restart-PiHoleDnsService -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl)

    Add-Example -Category Actions -FunctionName 'Update-PiHoleActionsGravity' `
        -Invocation 'Update-PiHoleActionsGravity -PiHoleServer $PiHoleServer -Password $Password' `
        -Note 'Rebuilds the entire gravity database - typically takes 1-2 minutes.' `
        -Result (Update-PiHoleActionsGravity -PiHoleServer $PiHoleServer -Password $PiHoleToken -IgnoreSsl $PiHoleIgnoreSsl -Confirm:$false)
}
else {
    # These four were verified with real output during this module's development; reusing that
    # rather than fabricating a plausible-looking one or re-running a disruptive action by default.
    Add-Example -Category Actions -FunctionName 'Invoke-PiHoleFlushNetwork' `
        -Invocation 'Invoke-PiHoleFlushNetwork -PiHoleServer $PiHoleServer -Password $Password' `
        -Skipped -StaticOutput "Status : Flushed"
    Add-Example -Category Actions -FunctionName 'Invoke-PiHoleFlushLogs' `
        -Invocation 'Invoke-PiHoleFlushLogs -PiHoleServer $PiHoleServer -Password $Password' `
        -Skipped -StaticOutput "Status : Flushed"
    Add-Example -Category Actions -FunctionName 'Restart-PiHoleDnsService' `
        -Invocation 'Restart-PiHoleDnsService -PiHoleServer $PiHoleServer -Password $Password' `
        -Skipped -StaticOutput "Status : Restarted"
    Add-Example -Category Actions -FunctionName 'Update-PiHoleActionsGravity' `
        -Invocation 'Update-PiHoleActionsGravity -PiHoleServer $PiHoleServer -Password $Password' `
        -Note 'Rebuilds the entire gravity database - typically takes 1-2 minutes.' `
        -Skipped -StaticOutput "Status : Completed"
}
#endregion

# --- Assemble the Markdown document ---
$lines = [System.Collections.Generic.List[string]]::new()
$lines.Add('# Example Output')
$lines.Add('')
$lines.Add("Real output captured from every exported function against a live Pi-hole v6 server, generated by ``tools/Update-ExampleOutput.ps1``. Values (query counts, IDs, timestamps, etc.) reflect whatever that specific server had at capture time - the shape of the output is what matters here, not the exact numbers.")
$lines.Add('')
$lines.Add('Regenerate with:')
$lines.Add('')
$lines.Add('```powershell')
$lines.Add('./tools/Update-ExampleOutput.ps1')
$lines.Add('# or, to also capture the small number of functions with real side effects on a live server:')
$lines.Add('./tools/Update-ExampleOutput.ps1 -IncludeDisruptive')
$lines.Add('```')
$lines.Add('')

foreach ($key in $categoryOrder.Keys) {
    $examples = $sectionsByCategory[$key]
    if ($examples.Count -eq 0) { continue }

    $lines.Add("## $($categoryOrder[$key])")
    $lines.Add('')

    foreach ($example in $examples) {
        $lines.Add("### $($example.FunctionName)")
        $lines.Add('')
        if ($example.Note) {
            $lines.Add("_$($example.Note)_")
            $lines.Add('')
        }
        $lines.Add('```powershell')
        $lines.Add($example.Invocation)
        $lines.Add('```')
        $lines.Add('')
        $lines.Add('```')
        $lines.Add($example.Output)
        $lines.Add('```')
        $lines.Add('')
    }
}

$docsDir = Split-Path -Path $outputPath -Parent
if (-not (Test-Path $docsDir)) {
    New-Item -ItemType Directory -Path $docsDir | Out-Null
}
Set-Content -Path $outputPath -Value ($lines -join "`n") -NoNewline
Write-Host "Wrote $outputPath"
