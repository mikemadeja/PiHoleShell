# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Get-PiHoleStatsDatabaseUpstream (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl

            # Generates some real query traffic. Live stats reflect it immediately; the on-disk
            # database stats this file tests only reflect it once FTL's periodic flush runs, so
            # this mainly helps build up real history across repeated runs, not this run's own data.
            & (Join-Path (Split-Path $PSScriptRoot -Parent) 'Initialize-PiHoleTestData.ps1') -DnsServer $PiHoleServer.Host
        }

        # The API rejects from=0 (epoch) with a 400, so use a recent, valid window instead.
        $script:Until = Get-Date
        $script:From = $script:Until.AddDays(-30)
    }

    It 'returns upstream metrics as a formatted object' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleStatsDatabaseUpstream -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -From $script:From -Until $script:Until -IgnoreSsl $script:PiHoleIgnoreSsl
        $result | Format-List | Out-String | Write-Host
        $result.Upstreams | Format-Table | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.TotalQueries | Should -BeGreaterOrEqual 0
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleStatsDatabaseUpstream -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -From $script:From -Until $script:Until -IgnoreSsl $script:PiHoleIgnoreSsl -RawOutput $true
        $result | Format-List | Out-String | Write-Host

        $result.total_queries | Should -Not -BeNullOrEmpty
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleStatsDatabaseUpstream -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -From $script:From -Until $script:Until -IgnoreSsl $script:PiHoleIgnoreSsl -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }

    It 'defaults to the last 8 hours when From/Until are omitted' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleStatsDatabaseUpstream -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
    }
}
