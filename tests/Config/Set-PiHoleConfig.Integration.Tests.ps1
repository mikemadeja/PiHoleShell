# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.
#
# NOTE: these tests change and restore a genuinely harmless debug flag (debug.api) rather than
# anything that affects DNS resolution or other real behavior. They require the app password
# used here to have "app_sudo" enabled in Pi-hole (Settings > All Settings), same as the
# functions themselves - see their .DESCRIPTION.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Set-PiHoleConfig (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl
        }
    }

    It 'changes a setting and restores it, without restarting FTL' -Skip:(-not $script:ConfigAvailable) {
        $original = (Get-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl).Debug.Api

        try {
            $result = Set-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Settings @{ debug = @{ api = -not $original } } -Restart $false
            $result | Format-List | Out-String | Write-Host

            $result | Should -Not -BeNullOrEmpty
            $result.Debug.Api | Should -Be (-not $original)
        }
        finally {
            Set-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Settings @{ debug = @{ api = $original } } -Restart $false | Out-Null
        }
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        $original = (Get-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl).Debug.Api

        try {
            $result = Set-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Settings @{ debug = @{ api = -not $original } } -Restart $false -RawOutput $true
            $result | Format-List | Out-String | Write-Host

            $result.config | Should -Not -BeNullOrEmpty
        }
        finally {
            Set-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Settings @{ debug = @{ api = $original } } -Restart $false | Out-Null
        }
    }

    It 'errors and gives a clear reason when the property can only be set in pihole.toml' -Skip:(-not $script:ConfigAvailable) {
        $result = Set-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Settings @{ misc = @{ readOnly = $true } } -Restart $false -ErrorVariable errOut -ErrorAction SilentlyContinue
        Write-Host "Error ($($errOut.Count) entries, showing last): [$($errOut[-1])]"

        $errOut | Should -Not -BeNullOrEmpty
        $errOut[-1] | Should -Match 'pihole.toml'
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Set-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -Settings @{ debug = @{ api = $true } } -Restart $false -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
