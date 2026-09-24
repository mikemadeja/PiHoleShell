# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path $PSScriptRoot 'IntegrationConfig.local.ps1')

Describe 'New-PiHoleGroup (Integration)' -Tag 'Integration' {
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

    It 'creates a new group and returns a formatted object' -Skip:(-not $script:ConfigAvailable) {
        $result = New-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -Comment 'Pester integration test group'
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Name | Should -Be $script:TestGroupName
        $result.Comment | Should -Be 'Pester integration test group'
        $result.Enabled | Should -BeTrue

        Remove-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName | Out-Null
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        $result = New-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -RawOutput $true
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.groups[0].name | Should -Be $script:TestGroupName

        Remove-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName | Out-Null
    }

    It 'warns and returns nothing when the group already exists' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName | Out-Null

        $result = New-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -WarningVariable warnOut -WarningAction SilentlyContinue

        $result | Should -BeNullOrEmpty
        $warnOut | Should -Not -BeNullOrEmpty

        Remove-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName | Out-Null
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = New-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
