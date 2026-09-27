# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Update-PiHoleClient (Integration)' -Tag 'Integration' {
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
            Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
            Remove-PiHoleGroup -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -GroupName $script:TestGroupName -ErrorAction SilentlyContinue | Out-Null
        }
    }

    It 'updates only the comment, preserving Group' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Comment 'original comment' | Out-Null

        $result = Update-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Comment 'updated comment'
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Comment | Should -Be 'updated comment'
        $result.Groups | Should -Contain 'Default'

        Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Confirm:$false | Out-Null
    }

    It 'updates only Group, preserving the current comment' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Comment 'keep this comment' | Out-Null

        $result = Update-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Group $script:TestGroupName
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Comment | Should -Be 'keep this comment'
        $result.Groups | Should -Be @($script:TestGroupName)

        Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Confirm:$false | Out-Null
    }

    It 'errors when -Group names a group that does not exist' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient | Out-Null

        $result = Update-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Group 'DefinitelyNotARealGroup' -ErrorVariable errOut -ErrorAction SilentlyContinue
        Write-Host "Error ($($errOut.Count) entries, showing last): [$($errOut[-1])]"

        $errOut | Should -Not -BeNullOrEmpty

        Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Confirm:$false | Out-Null
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient | Out-Null

        $result = Update-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Comment 'raw output test' -RawOutput $true
        $result | Format-List | Out-String | Write-Host

        $result.clients[0].comment | Should -Be 'raw output test'

        Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Confirm:$false | Out-Null
    }

    It 'errors when neither Comment nor Group is specified' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient | Out-Null

        $result = Update-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty

        Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Confirm:$false | Out-Null
    }

    It 'errors when the client does not exist' -Skip:(-not $script:ConfigAvailable) {
        $result = Update-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client '10.10.10.10' -Comment 'irrelevant' -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient | Out-Null

        $result = Update-PiHoleClient -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Comment 'irrelevant' -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
