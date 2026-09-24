# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path $PSScriptRoot 'IntegrationConfig.local.ps1')

Describe 'Add-PiHoleList (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $script:TestListAddress = 'https://blocklistproject.github.io/Lists/alt-version/ransomware-nl.txt'

        $configPath = Join-Path $PSScriptRoot 'IntegrationConfig.local.ps1'
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
            # Ensures the test list is never left behind for other test files to trip over
            Remove-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        }
    }

    It 'adds a new list and returns a formatted object' -Skip:(-not $script:ConfigAvailable) {
        $result = Add-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Comment 'Pester integration test list'
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Address | Should -Be $script:TestListAddress
        $result.Type | Should -Be 'Block'
        $result.Enabled | Should -BeTrue

        # Clean up immediately so the next test starts from a known (list-absent) state
        Remove-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Confirm:$false | Out-Null
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        $result = Add-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -RawOutput $true
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.lists[0].address | Should -Be $script:TestListAddress

        Remove-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Confirm:$false | Out-Null
    }

    It 'errors when the list already exists' -Skip:(-not $script:ConfigAvailable) {
        Add-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block | Out-Null

        $result = Add-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -ErrorVariable errOut -ErrorAction SilentlyContinue
        Write-Host "Error ($($errOut.Count) entries, showing last): [$($errOut[-1])]"

        $errOut | Should -Not -BeNullOrEmpty

        Remove-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Confirm:$false | Out-Null
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Add-PiHoleList -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -ErrorVariable errOut -ErrorAction SilentlyContinue
        Write-Host "Error ($($errOut.Count) entries, showing last): [$($errOut[-1])]"

        $errOut | Should -Not -BeNullOrEmpty
    }
}
