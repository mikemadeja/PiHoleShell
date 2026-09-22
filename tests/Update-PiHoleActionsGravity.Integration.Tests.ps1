# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.
#
# NOTE: this actually runs `pihole -g` on the target server (rebuilds the gravity/adlists),
# which can take anywhere from several seconds to a few minutes depending on adlist size.

# Config availability must be known at discovery time so the -Skip parameter on each It block
# (evaluated during discovery, before BeforeAll runs) sees the correct value.
$script:ConfigAvailable = Test-Path (Join-Path $PSScriptRoot 'IntegrationConfig.local.ps1')

Describe 'Update-PiHoleActionsGravity (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        # Recomputed here (not read from the discovery-time $script:ConfigAvailable above) because
        # Pester runs discovery and run in separate scopes, so BeforeAll cannot see that value.
        $configPath = Join-Path $PSScriptRoot 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl
        }
    }

    It 'runs a gravity update and returns a formatted object' -Skip:(-not $script:ConfigAvailable) {
        $result = Update-PiHoleActionsGravity -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Confirm:$false
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Status | Should -Be "Completed"
    }

    It 'runs a gravity update and returns the raw API response' -Skip:(-not $script:ConfigAvailable) {
        $result = Update-PiHoleActionsGravity -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -RawOutput $true -Confirm:$false
        Write-Host "RawOutput: [$result]"

        $result | Should -Not -BeNullOrEmpty
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Update-PiHoleActionsGravity -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -Confirm:$false -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
