# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.
#
# NOTE: these only generate app passwords - they never set the returned hash as
# webserver.api.app_pwhash, so the server's real app password and sessions are left untouched.

# Config availability must be known at discovery time so the -Skip parameter on each It block
# (evaluated during discovery, before BeforeAll runs) sees the correct value.
$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Get-PiHoleAuthApp (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        # Recomputed here (not read from the discovery-time $script:ConfigAvailable above) because
        # Pester runs discovery and run in separate scopes, so BeforeAll cannot see that value.
        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl
        }
    }

    It 'generates a new app password and its hash' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleAuthApp -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl

        $result | Should -Not -BeNullOrEmpty
        $result.Password | Should -Not -BeNullOrEmpty
        $result.Hash | Should -BeLike '$BALLOON-SHA256$*'
    }

    It 'generates a different password each time' -Skip:(-not $script:ConfigAvailable) {
        $first = Get-PiHoleAuthApp -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl
        $second = Get-PiHoleAuthApp -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl

        $second.Password | Should -Not -Be $first.Password
    }

    It 'leaves the current app password working' -Skip:(-not $script:ConfigAvailable) {
        Get-PiHoleAuthApp -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl | Out-Null

        $status = Get-PiHoleAuthStatus -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl
        $status.Valid | Should -BeTrue
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleAuthApp -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -RawOutput $true

        $result.app.password | Should -Not -BeNullOrEmpty
        $result.app.hash | Should -Not -BeNullOrEmpty
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleAuthApp -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
