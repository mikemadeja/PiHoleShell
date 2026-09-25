# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Update-PiHoleList (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $script:TestListAddress = 'https://blocklistproject.github.io/Lists/alt-version/ransomware-nl.txt'

        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl

            # Defensive cleanup in case a previous failed run left the test list behind
            Remove-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        }
    }

    AfterAll {
        if ($script:PiHoleServer) {
            Remove-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        }
    }

    It 'updates only the comment, preserving Enabled and Group' -Skip:(-not $script:ConfigAvailable) {
        Add-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Comment 'original comment' -Enabled $true | Out-Null

        $result = Update-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Comment 'updated comment'
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Comment | Should -Be 'updated comment'
        $result.Enabled | Should -BeTrue
        $result.Groups | Should -Contain 'Default'

        Remove-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Confirm:$false | Out-Null
    }

    It 'updates only Enabled, preserving the current comment' -Skip:(-not $script:ConfigAvailable) {
        Add-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Comment 'keep this comment' -Enabled $true | Out-Null

        $result = Update-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Enabled $false
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Comment | Should -Be 'keep this comment'
        $result.Enabled | Should -BeFalse

        Remove-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Confirm:$false | Out-Null
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        Add-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block | Out-Null

        $result = Update-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Comment 'raw output test' -RawOutput $true
        $result | Format-List | Out-String | Write-Host

        $result.lists[0].comment | Should -Be 'raw output test'

        Remove-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Confirm:$false | Out-Null
    }

    It 'errors when neither Comment, Group, nor Enabled is specified' -Skip:(-not $script:ConfigAvailable) {
        Add-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block | Out-Null

        $result = Update-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty

        Remove-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Confirm:$false | Out-Null
    }

    It 'errors when the list does not exist' -Skip:(-not $script:ConfigAvailable) {
        $result = Update-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address 'https://example.com/does-not-exist.txt' -Type Block -Comment 'irrelevant' -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        Add-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block | Out-Null

        $result = Update-PiHoleList -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Comment 'irrelevant' -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
