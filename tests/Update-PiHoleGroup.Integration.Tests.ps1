# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path $PSScriptRoot 'IntegrationConfig.local.ps1')

Describe 'Update-PiHoleGroup (Integration)' -Tag 'Integration' {
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

    It 'updates only the comment, preserving the current Enabled state' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -Comment 'original comment' -Enabled $true | Out-Null

        $result = Update-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -Comment 'updated comment'
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Comment | Should -Be 'updated comment'
        $result.Enabled | Should -BeTrue

        Remove-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName | Out-Null
    }

    It 'updates only Enabled, preserving the current comment' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -Comment 'keep this comment' -Enabled $true | Out-Null

        $result = Update-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -Enabled $false
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Comment | Should -Be 'keep this comment'
        $result.Enabled | Should -BeFalse

        Remove-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName | Out-Null
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName | Out-Null

        $result = Update-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -Comment 'raw output test' -RawOutput $true
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.groups[0].comment | Should -Be 'raw output test'

        Remove-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName | Out-Null
    }

    It 'errors when neither Comment nor Enabled is specified' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName | Out-Null

        $result = Update-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty

        Remove-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName | Out-Null
    }

    It 'errors when the group does not exist' -Skip:(-not $script:ConfigAvailable) {
        $result = Update-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -Comment 'does not matter' -ErrorVariable errOut -ErrorAction SilentlyContinue -WarningAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName | Out-Null

        $result = Update-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -Comment 'irrelevant' -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
