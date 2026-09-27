# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Remove-PiHoleDomain (Integration)' -Tag 'Integration' {
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
            # Defensive cleanup in case a test left the domain behind
            Remove-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        }
    }

    It 'removes an existing domain and returns a formatted object' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Comment 'Pester integration test domain' | Out-Null

        $result = Remove-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Confirm:$false
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Domain | Should -Be $script:TestDomain
        $result.Status | Should -Be 'Removed'

        $remaining = Get-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Type Allow -Kind Exact -Domain $script:TestDomain
        $remaining | Should -BeNullOrEmpty
    }

    It 'removes the domain when RawOutput is set, even though the API returns no body' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact | Out-Null

        # A successful delete is HTTP 204 No Content, so RawOutput is expected to be empty here -
        # the domain actually being gone afterward is the real signal of success.
        Remove-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -RawOutput $true -Confirm:$false

        $remaining = Get-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Type Allow -Kind Exact -Domain $script:TestDomain
        $remaining | Should -BeNullOrEmpty
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact | Out-Null

        $result = Remove-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Confirm:$false -ErrorVariable errOut -ErrorAction SilentlyContinue
        Write-Host "Error ($($errOut.Count) entries, showing last): [$($errOut[-1])]"

        $errOut | Should -Not -BeNullOrEmpty
    }
}
