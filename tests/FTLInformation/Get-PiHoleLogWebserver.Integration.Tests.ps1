# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Get-PiHoleLogWebserver (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl
        }
    }

    It 'returns webserver log content as a formatted object' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleLogWebserver -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.NextID | Should -BeGreaterOrEqual 0
        $result.File | Should -Not -BeNullOrEmpty
    }

    It 'only returns lines added after NextID on a follow-up call' -Skip:(-not $script:ConfigAvailable) {
        $first = Get-PiHoleLogWebserver -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl

        $second = Get-PiHoleLogWebserver -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -NextID $first.NextID
        $second | Format-List | Out-String | Write-Host

        # No guarantee new webserver log lines were generated between the two calls, so this
        # just confirms the call succeeds and NextID never goes backwards.
        $second.NextID | Should -BeGreaterOrEqual $first.NextID
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleLogWebserver -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -RawOutput $true
        $result | Format-List | Out-String | Write-Host

        $result.PSObject.Properties.Name | Should -Contain 'log'
        $result.PSObject.Properties.Name | Should -Contain 'nextID'
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleLogWebserver -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
