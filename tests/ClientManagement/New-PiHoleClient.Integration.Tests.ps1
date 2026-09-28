# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'New-PiHoleClient (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $script:TestClient = '192.168.99.99'
        $script:TestGroupName = 'PesterClientGroup'

        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl

            # Defensive cleanup in case a previous failed run left the test client/group behind
            Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
            Remove-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null

            New-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName | Out-Null
        }
    }

    AfterAll {
        if ($script:PiHoleServer) {
            # Ensures the test client/group are never left behind for other test files to trip over
            Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
            Remove-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -ErrorAction SilentlyContinue | Out-Null
        }
    }

    It 'adds a new client and returns a formatted object' -Skip:(-not $script:ConfigAvailable) {
        $result = New-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Comment 'Pester integration test client'
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Client | Should -Be $script:TestClient
        $result.Groups | Should -Contain 'Default'

        # Clean up immediately so the next test starts from a known (client-absent) state
        Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Confirm:$false | Out-Null
    }

    It 'applies a non-default group passed via -Group' -Skip:(-not $script:ConfigAvailable) {
        $result = New-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Group $script:TestGroupName
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Groups | Should -Be @($script:TestGroupName)
        $result.Groups | Should -Not -Contain 'Default'

        Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Confirm:$false | Out-Null
    }

    It 'errors when -Group names a group that does not exist, without creating the client' -Skip:(-not $script:ConfigAvailable) {
        $result = New-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Group 'DefinitelyNotARealGroup' -ErrorVariable errOut -ErrorAction SilentlyContinue
        Write-Host "Error ($($errOut.Count) entries, showing last): [$($errOut[-1])]"

        $errOut | Should -Not -BeNullOrEmpty

        $remaining = Get-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient
        $remaining | Should -BeNullOrEmpty
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        $result = New-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -RawOutput $true
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.clients[0].client | Should -Be $script:TestClient

        Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Confirm:$false | Out-Null
    }

    It 'errors when the client already exists' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient | Out-Null

        $result = New-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -ErrorVariable errOut -ErrorAction SilentlyContinue
        Write-Host "Error ($($errOut.Count) entries, showing last): [$($errOut[-1])]"

        $errOut | Should -Not -BeNullOrEmpty

        Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Confirm:$false | Out-Null
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = New-PiHoleClient -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -ErrorVariable errOut -ErrorAction SilentlyContinue
        Write-Host "Error ($($errOut.Count) entries, showing last): [$($errOut[-1])]"

        $errOut | Should -Not -BeNullOrEmpty
    }
}
