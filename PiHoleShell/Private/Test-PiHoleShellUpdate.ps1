function Test-PiHoleShellUpdate {
    #INTERNAL FUNCTION
    #
    # Best-effort, cached check for a newer PiHoleShell release, run once at module import.
    # Never throws and never meaningfully delays Import-Module:
    #  - Skipped entirely for a dev/source checkout: importing via the manifest leaves
    #    ModuleVersion at its '0.0.0' placeholder (the real version is only ever baked in at
    #    publish time by CreateRelease.yml), and importing the .psm1 directly - as every test in
    #    this repo's own suite does - gets PowerShell's auto-assigned '0.0' instead. Either way
    #    this never fires during this repo's own test suite, which always imports from source.
    #  - Skipped if $env:PIHOLESHELL_SKIP_UPDATE_CHECK is set, for automation that wants no
    #    network calls or output from importing the module.
    #  - Only calls GitHub once per $CheckIntervalHours; the result is cached to disk so repeat
    #    imports in the same day don't hit the network (or GitHub's unauthenticated rate limit)
    #    again, even though the check still runs - and still warns - on every import.
    #  - GitHub's "latest release" endpoint already excludes prereleases and drafts, so the
    #    "dev-latest" build published on every push to develop is never picked up here.
    [Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingEmptyCatchBlock", "", Justification = "Best-effort check - a network hiccup or unexpected response must never break module import.")]
    [CmdletBinding()]
    param (
        [version]$CurrentVersion,
        [string]$CacheFilePath = (Join-Path ([Environment]::GetFolderPath('LocalApplicationData')) 'PiHoleShell/update-check.json'),
        [int]$CheckIntervalHours = 24
    )

    if ($env:PIHOLESHELL_SKIP_UPDATE_CHECK -or $CurrentVersion -in @([version]'0.0', [version]'0.0.0')) {
        return
    }

    try {
        $LatestVersion = $null
        $Cache = $null
        if (Test-Path -Path $CacheFilePath) {
            $Cache = Get-Content -Path $CacheFilePath -Raw | ConvertFrom-Json
        }

        if ($Cache.LastChecked -and ((Get-Date) - [datetime]$Cache.LastChecked) -lt [timespan]::FromHours($CheckIntervalHours)) {
            $LatestVersion = $Cache.LatestVersion
        }
        else {
            $Release = Invoke-RestMethod -Uri 'https://api.github.com/repos/mikemadeja/PiHoleShell/releases/latest' -TimeoutSec 3
            $LatestVersion = $Release.tag_name.TrimStart('v')

            $CacheDir = Split-Path -Path $CacheFilePath -Parent
            if (-not (Test-Path -Path $CacheDir)) {
                New-Item -ItemType Directory -Path $CacheDir -Force | Out-Null
            }
            [PSCustomObject]@{
                LastChecked   = (Get-Date).ToString('o')
                LatestVersion = $LatestVersion
            } | ConvertTo-Json | Set-Content -Path $CacheFilePath
        }

        if ([version]$LatestVersion -gt $CurrentVersion) {
            Write-Warning "A newer version of PiHoleShell is available: $LatestVersion (you have $CurrentVersion). Run 'Update-Module PiHoleShell' to update."
        }
    }
    catch {
    }
}
