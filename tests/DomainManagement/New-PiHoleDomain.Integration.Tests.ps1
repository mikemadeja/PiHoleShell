# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'New-PiHoleDomain (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $script:TestDomain = 'piholeshell-test-domain.example.com'

        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl

            # Defensive cleanup in case a previous failed run left the test domain behind
            Remove-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
        }
    }

    AfterAll {
        if ($script:PiHoleServer) {
            # Ensures the test domain is never left behind for other test files to trip over
            Remove-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        }
    }

    It 'adds a new domain and returns a formatted object' -Skip:(-not $script:ConfigAvailable) {
        $result = New-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Comment 'Pester integration test domain'
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Domain | Should -Be $script:TestDomain
        $result.Type | Should -Be 'Allow'
        $result.Kind | Should -Be 'Exact'
        $result.Enabled | Should -BeTrue
        $result.Groups | Should -Contain 'Default'

        # Clean up immediately so the next test starts from a known (domain-absent) state
        Remove-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Confirm:$false | Out-Null
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        $result = New-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -RawOutput $true
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.domains[0].domain | Should -Be $script:TestDomain

        Remove-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Confirm:$false | Out-Null
    }

    It 'errors when the domain already exists' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact | Out-Null

        $result = New-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -ErrorVariable errOut -ErrorAction SilentlyContinue
        Write-Host "Error ($($errOut.Count) entries, showing last): [$($errOut[-1])]"

        $errOut | Should -Not -BeNullOrEmpty

        Remove-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Confirm:$false | Out-Null
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = New-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -ErrorVariable errOut -ErrorAction SilentlyContinue
        Write-Host "Error ($($errOut.Count) entries, showing last): [$($errOut[-1])]"

        $errOut | Should -Not -BeNullOrEmpty
    }
}
