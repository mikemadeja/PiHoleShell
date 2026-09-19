# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path $PSScriptRoot 'IntegrationConfig.local.ps1')

Describe 'Get-PiHoleStatsDatabaseSummary (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $configPath = Join-Path $PSScriptRoot 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl
        }

        # from=0 is rejected by the API with a 400; use a wide-but-valid recent window instead.
        $script:Until = [DateTimeOffset]::UtcNow.ToUnixTimeSeconds()
        $script:From = $script:Until - (30 * 86400)
    }

    It 'returns database summary as a formatted object' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleStatsDatabaseSummary -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -From $script:From -Until $script:Until -IgnoreSsl $script:PiHoleIgnoreSsl
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.SumQueries | Should -BeGreaterOrEqual 0
        $result.SumBlocked | Should -BeGreaterOrEqual 0
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleStatsDatabaseSummary -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -From $script:From -Until $script:Until -IgnoreSsl $script:PiHoleIgnoreSsl -RawOutput $true
        $result | Format-List | Out-String | Write-Host

        $result.PSObject.Properties.Name | Should -Contain 'sum_queries'
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleStatsDatabaseSummary -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -From $script:From -Until $script:Until -IgnoreSsl $script:PiHoleIgnoreSsl -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
