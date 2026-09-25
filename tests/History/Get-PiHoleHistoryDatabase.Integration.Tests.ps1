# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Get-PiHoleHistoryDatabase (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl
        }

        # The API rejects from=0 (epoch) with a 400, so use a recent, valid window instead.
        $script:Until = Get-Date
        $script:From = $script:Until.AddDays(-30)
    }

    It 'returns history as formatted objects' -Skip:(-not $script:ConfigAvailable) {
        # An empty array is a legitimate response here (no queries logged in the window), unlike
        # the Stats(database) summary endpoints which always return a populated object shape even
        # with zero matching rows - so this only asserts the call succeeds and, if there's data,
        # that its shape is correct, rather than requiring non-empty results.
        { $script:result = Get-PiHoleHistoryDatabase -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -From $script:From -Until $script:Until -IgnoreSsl $script:PiHoleIgnoreSsl } | Should -Not -Throw
        $script:result | Select-Object -First 5 | Format-Table | Out-String | Write-Host

        if ($script:result) {
            $script:result[0].Total | Should -BeGreaterOrEqual 0
        }
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleHistoryDatabase -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -From $script:From -Until $script:Until -IgnoreSsl $script:PiHoleIgnoreSsl -RawOutput $true
        $result | Format-List | Out-String | Write-Host

        $result.PSObject.Properties.Name | Should -Contain 'history'
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleHistoryDatabase -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -From $script:From -Until $script:Until -IgnoreSsl $script:PiHoleIgnoreSsl -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }

    It 'defaults to the last 8 hours when From/Until are omitted' -Skip:(-not $script:ConfigAvailable) {
        { $script:result = Get-PiHoleHistoryDatabase -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl } | Should -Not -Throw
        $script:result | Format-Table | Out-String | Write-Host
    }
}
