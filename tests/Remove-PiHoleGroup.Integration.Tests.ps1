# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path $PSScriptRoot 'IntegrationConfig.local.ps1')

Describe 'Remove-PiHoleGroup (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $script:TestGroupName = 'PesterGroup'

        $configPath = Join-Path $PSScriptRoot 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl

            # Defensive cleanup in case a previous failed run left the test group behind
            Remove-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
        }
    }

    AfterAll {
        if ($script:PiHoleServer) {
            Remove-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
        }
    }

    It 'removes an existing group and returns a formatted object' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName | Out-Null

        $result = Remove-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Name | Should -Be $script:TestGroupName
        $result.Status | Should -Be 'Deleted'

        $remaining = Get-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -WarningAction SilentlyContinue
        $remaining | Should -BeNullOrEmpty
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName | Out-Null

        # A successful delete is HTTP 204 No Content, so RawOutput is expected to be empty here -
        # the group actually being gone afterward is the real signal of success.
        Remove-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -RawOutput $true

        $remaining = Get-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -WarningAction SilentlyContinue
        $remaining | Should -BeNullOrEmpty
    }

    It 'errors when the group does not exist' -Skip:(-not $script:ConfigAvailable) {
        $result = Remove-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -ErrorVariable errOut -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName | Out-Null

        $result = Remove-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
