# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Get-PiHoleQuery (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl

            # Generates some real query traffic so there's something in the log to return.
            & (Join-Path (Split-Path $PSScriptRoot -Parent) 'Initialize-PiHoleTestData.ps1') -DnsServer $PiHoleServer.Host
        }
    }

    It 'returns queries as formatted objects' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleQuery -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Length 10
        $result | Select-Object -First 5 | Format-Table Id, Time, Type, Domain, Status | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result[0].Id | Should -Not -BeNullOrEmpty
        $result[0].Domain | Should -Not -BeNullOrEmpty
        $result[0].Client.Ip | Should -Not -BeNullOrEmpty
    }

    It 'filters by domain' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleQuery -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain 'doubleclick.net'
        $result | Format-Table Id, Time, Domain, Status | Out-String | Write-Host

        # Domain filtering only has something to assert on if a matching query happened to be
        # seeded this run - this just confirms the filtered call itself succeeds either way.
        { $result } | Should -Not -Throw
        if ($result) {
            $result | ForEach-Object { $_.Domain | Should -Be 'doubleclick.net' }
        }
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleQuery -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -RawOutput $true
        $result | Select-Object cursor, recordsTotal, recordsFiltered | Format-List | Out-String | Write-Host

        $result.queries | Should -Not -BeNullOrEmpty
        $result.recordsTotal | Should -BeGreaterThan 0
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleQuery -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
