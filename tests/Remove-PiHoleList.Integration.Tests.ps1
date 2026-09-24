# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path $PSScriptRoot 'IntegrationConfig.local.ps1')

Describe 'Remove-PiHoleList (Integration)' -Tag 'Integration' {
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
            # Defensive cleanup in case a test left the list behind
            Remove-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        }
    }

    It 'removes an existing list and returns a formatted object' -Skip:(-not $script:ConfigAvailable) {
        Add-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Comment 'Pester integration test list' | Out-Null

        $result = Remove-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Confirm:$false
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Address | Should -Be $script:TestListAddress
        $result.Status | Should -Be 'Removed'

        $remaining = Get-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl | Where-Object { $_.Address -eq $script:TestListAddress }
        $remaining | Should -BeNullOrEmpty
    }

    It 'removes the list when RawOutput is set, even though the API returns no body' -Skip:(-not $script:ConfigAvailable) {
        Add-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block | Out-Null

        # A successful delete is HTTP 204 No Content, so RawOutput is expected to be empty here -
        # the list actually being gone afterward is the real signal of success.
        Remove-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -RawOutput $true -Confirm:$false

        $remaining = Get-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl | Where-Object { $_.Address -eq $script:TestListAddress }
        $remaining | Should -BeNullOrEmpty
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        Add-PiHoleList -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block | Out-Null

        $result = Remove-PiHoleList -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -Address $script:TestListAddress -Type Block -Confirm:$false -ErrorVariable errOut -ErrorAction SilentlyContinue
        Write-Host "Error ($($errOut.Count) entries, showing last): [$($errOut[-1])]"

        $errOut | Should -Not -BeNullOrEmpty
    }
}
