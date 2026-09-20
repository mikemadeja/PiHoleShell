# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.
#
# NOTE: this actually restarts the pihole-FTL service on the target server, causing a brief
# DNS resolution interruption on that server.

# Config availability must be known at discovery time so the -Skip parameter on each It block
# (evaluated during discovery, before BeforeAll runs) sees the correct value.
$script:ConfigAvailable = Test-Path (Join-Path $PSScriptRoot 'IntegrationConfig.local.ps1')

Describe 'Restart-PiHoleDnsService (Integration)' -Tag 'Integration' {
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

    It 'restarts the DNS service and returns a formatted status' -Skip:(-not $script:ConfigAvailable) {
        $result = Restart-PiHoleDnsService -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Status | Should -Be 'Restarted'
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        # The previous test just restarted pihole-FTL; give it a moment to come back up before
        # restarting it again, or this occasionally hits a transient connection failure.
        Start-Sleep -Seconds 5

        $result = Restart-PiHoleDnsService -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -RawOutput $true
        Write-Host "RawOutput: [$result]"
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Restart-PiHoleDnsService -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
