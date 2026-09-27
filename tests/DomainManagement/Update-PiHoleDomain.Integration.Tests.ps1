# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Update-PiHoleDomain (Integration)' -Tag 'Integration' {
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
            Remove-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        }
    }

    It 'updates only the comment, preserving Enabled and Group' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Comment 'original comment' -Enabled $true | Out-Null

        $result = Update-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Comment 'updated comment'
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Comment | Should -Be 'updated comment'
        $result.Enabled | Should -BeTrue
        $result.Groups | Should -Contain 'Default'

        Remove-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Confirm:$false | Out-Null
    }

    It 'updates only Enabled, preserving the current comment' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Comment 'keep this comment' -Enabled $true | Out-Null

        $result = Update-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Enabled $false
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Comment | Should -Be 'keep this comment'
        $result.Enabled | Should -BeFalse

        Remove-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Confirm:$false | Out-Null
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact | Out-Null

        $result = Update-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Comment 'raw output test' -RawOutput $true
        $result | Format-List | Out-String | Write-Host

        $result.domains[0].comment | Should -Be 'raw output test'

        Remove-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Confirm:$false | Out-Null
    }

    It 'errors when neither Comment, Group, nor Enabled is specified' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact | Out-Null

        $result = Update-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty

        Remove-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Confirm:$false | Out-Null
    }

    It 'errors when the domain does not exist' -Skip:(-not $script:ConfigAvailable) {
        $result = Update-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain 'does-not-exist.example.com' -Type Allow -Kind Exact -Comment 'irrelevant' -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact | Out-Null

        $result = Update-PiHoleDomain -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -Domain $script:TestDomain -Type Allow -Kind Exact -Comment 'irrelevant' -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
