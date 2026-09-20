# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path $PSScriptRoot 'IntegrationConfig.local.ps1')

Describe 'Get-PiHoleStatsDatabaseTopDomain (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $configPath = Join-Path $PSScriptRoot 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl

            # Generates some real query traffic. Live stats reflect it immediately; the on-disk
            # database stats this file tests only reflect it once FTL's periodic flush runs, so
            # this mainly helps build up real history across repeated runs, not this run's own data.
            & (Join-Path $PSScriptRoot 'Initialize-PiHoleTestData.ps1') -DnsServer $PiHoleServer.Host
        }

        # from=0 is rejected by the API with a 400; use a wide-but-valid recent window instead.
        $script:Until = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $script:From = $script:Until - (30 * 86400)
    }

    It 'returns top domains without error' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleStatsDatabaseTopDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -From $script:From -Until $script:Until -IgnoreSsl $script:PiHoleIgnoreSsl -MaxResult 5
        $result | Format-Table | Out-String | Write-Host
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleStatsDatabaseTopDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -From $script:From -Until $script:Until -IgnoreSsl $script:PiHoleIgnoreSsl -RawOutput $true
        $result | Format-List | Out-String | Write-Host

        $result.PSObject.Properties.Name | Should -Contain 'domains'
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleStatsDatabaseTopDomain -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -From $script:From -Until $script:Until -IgnoreSsl $script:PiHoleIgnoreSsl -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
