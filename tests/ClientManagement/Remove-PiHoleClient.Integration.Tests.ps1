# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Remove-PiHoleClient (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $script:TestClient = '192.168.99.99'

        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl

            # Defensive cleanup in case a previous failed run left the test client behind
            Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
        }
    }

    AfterAll {
        if ($script:PiHoleServer) {
            # Defensive cleanup in case a test left the client behind
            Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        }
    }

    It 'removes an existing client and returns a formatted object' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Comment 'Pester integration test client' | Out-Null

        $result = Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Confirm:$false
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Client | Should -Be $script:TestClient
        $result.Status | Should -Be 'Removed'

        $remaining = Get-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient
        $remaining | Should -BeNullOrEmpty
    }

    It 'removes the client when RawOutput is set, even though the API returns no body' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient | Out-Null

        # A successful delete is HTTP 204 No Content, so RawOutput is expected to be empty here -
        # the client actually being gone afterward is the real signal of success.
        Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -RawOutput $true -Confirm:$false

        $remaining = Get-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient
        $remaining | Should -BeNullOrEmpty
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        New-PiHoleClient -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient | Out-Null

        $result = Remove-PiHoleClient -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -Client $script:TestClient -Confirm:$false -ErrorVariable errOut -ErrorAction SilentlyContinue
        Write-Host "Error ($($errOut.Count) entries, showing last): [$($errOut[-1])]"

        $errOut | Should -Not -BeNullOrEmpty
    }
}
