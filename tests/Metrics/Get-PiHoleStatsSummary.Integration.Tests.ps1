# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Get-PiHoleStatsSummary (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl

            # Generates some real query traffic so live stats aren't all zero/empty.
            & (Join-Path (Split-Path $PSScriptRoot -Parent) 'Initialize-PiHoleTestData.ps1') -DnsServer $PiHoleServer.Host
        }
    }

    It 'returns a summary as a formatted object' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleStatsSummary -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Total | Should -BeGreaterOrEqual 0
        $result.Types | Should -Not -BeNullOrEmpty
        $result.Status | Should -Not -BeNullOrEmpty
        $result.Replies | Should -Not -BeNullOrEmpty
        $result.Clients | Should -Not -BeNullOrEmpty
        $result.Gravity | Should -Not -BeNullOrEmpty
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleStatsSummary -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -RawOutput $true
        $result | Format-List | Out-String | Write-Host

        $result.queries | Should -Not -BeNullOrEmpty
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleStatsSummary -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
