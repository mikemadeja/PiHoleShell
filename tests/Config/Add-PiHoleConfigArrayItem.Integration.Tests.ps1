# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.
#
# NOTE: these tests add/remove a fake host entry using a TEST-NET-1 (RFC 5737) reserved IP that
# will never route anywhere real, rather than touching a genuine DNS record. They require the
# app password used here to have "app_sudo" enabled in Pi-hole (Settings > All Settings), same
# as the function itself - see its .DESCRIPTION.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Add-PiHoleConfigArrayItem (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $script:TestElement = 'dns/hosts'
        $script:TestValue = '192.0.2.1 piholeshell-test-host.example.com'

        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl

            # Defensive cleanup in case a previous failed run left the test host entry behind
            Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element $script:TestElement -Value $script:TestValue -Restart $false -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
        }
    }

    AfterAll {
        if ($script:PiHoleServer) {
            Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element $script:TestElement -Value $script:TestValue -Restart $false -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        }
    }

    It 'adds an item and returns a formatted object' -Skip:(-not $script:ConfigAvailable) {
        $result = Add-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element $script:TestElement -Value $script:TestValue -Restart $false
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Status | Should -Be 'Added'

        $hosts = (Get-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl).Dns.Hosts
        $hosts | Should -Contain $script:TestValue

        Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element $script:TestElement -Value $script:TestValue -Restart $false -Confirm:$false | Out-Null
    }

    It 'errors when the item already exists' -Skip:(-not $script:ConfigAvailable) {
        Add-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element $script:TestElement -Value $script:TestValue -Restart $false | Out-Null

        $result = Add-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element $script:TestElement -Value $script:TestValue -Restart $false -ErrorVariable errOut -ErrorAction SilentlyContinue
        Write-Host "Error ($($errOut.Count) entries, showing last): [$($errOut[-1])]"

        $errOut | Should -Not -BeNullOrEmpty

        Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element $script:TestElement -Value $script:TestValue -Restart $false -Confirm:$false | Out-Null
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Add-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -Element $script:TestElement -Value $script:TestValue -Restart $false -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
