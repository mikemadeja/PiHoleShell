# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.
#
# NOTE: these tests add/remove fake records using TEST-NET-1/documentation (RFC 5737/3849)
# reserved addresses that will never route anywhere real. -Restart $false is used throughout to
# avoid the brief FTL restart a real config change otherwise triggers.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Remove-PiHoleDnsRecord (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $script:AHostname = 'piholeshell-test-remove-a.example.com'
        $script:AIPv4 = '192.0.2.202'
        $script:CnameHostname = 'piholeshell-test-remove-cname.example.com'
        $script:CnameTarget = 'piholeshell-test-remove-a.example.com'
        $script:CnameTtl = 300

        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl

            # Defensive cleanup in case a previous failed run left these behind
            Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/hosts' -Value "$script:AIPv4 $script:AHostname" -Restart $false -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
            Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/cnameRecords' -Value "$script:CnameHostname,$script:CnameTarget,$script:CnameTtl" -Restart $false -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
        }
    }

    AfterAll {
        if ($script:PiHoleServer) {
            Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/hosts' -Value "$script:AIPv4 $script:AHostname" -Restart $false -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
            Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/cnameRecords' -Value "$script:CnameHostname,$script:CnameTarget,$script:CnameTtl" -Restart $false -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        }
    }

    It 'removes an A record and returns a formatted object' -Skip:(-not $script:ConfigAvailable) {
        Add-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/hosts' -Value "$script:AIPv4 $script:AHostname" -Restart $false | Out-Null

        $result = Remove-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Type A -Hostname $script:AHostname -IPv4Address $script:AIPv4 -Restart $false -Confirm:$false
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Status | Should -Be 'Removed'

        $hosts = (Get-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl).Dns.Hosts
        $hosts | Should -Not -Contain "$script:AIPv4 $script:AHostname"
    }

    It 'removes a CNAME record with a matching TTL' -Skip:(-not $script:ConfigAvailable) {
        Add-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/cnameRecords' -Value "$script:CnameHostname,$script:CnameTarget,$script:CnameTtl" -Restart $false | Out-Null

        $result = Remove-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Type CNAME -Hostname $script:CnameHostname -Target $script:CnameTarget -Ttl $script:CnameTtl -Restart $false -Confirm:$false
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Status | Should -Be 'Removed'

        $cnames = (Get-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl).Dns.CnameRecords
        $cnames | Should -Not -Contain "$script:CnameHostname,$script:CnameTarget,$script:CnameTtl"
    }

    It 'does not remove anything when -WhatIf is set' -Skip:(-not $script:ConfigAvailable) {
        Add-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/hosts' -Value "$script:AIPv4 $script:AHostname" -Restart $false | Out-Null

        Remove-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Type A -Hostname $script:AHostname -IPv4Address $script:AIPv4 -Restart $false -WhatIf

        $hosts = (Get-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl).Dns.Hosts
        $hosts | Should -Contain "$script:AIPv4 $script:AHostname"

        Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/hosts' -Value "$script:AIPv4 $script:AHostname" -Restart $false -Confirm:$false | Out-Null
    }

    It 'accepts multiple records piped from Get-PiHoleDnsRecord in a single call' -Skip:(-not $script:ConfigAvailable) {
        Add-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/hosts' -Value "$script:AIPv4 $script:AHostname" -Restart $false | Out-Null
        Add-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/cnameRecords' -Value "$script:CnameHostname,$script:CnameTarget,$script:CnameTtl" -Restart $false | Out-Null

        $results = Get-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl |
            Where-Object { $_.Hostname -in @($script:AHostname, $script:CnameHostname) } |
            Remove-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Restart $false -Confirm:$false
        $results | Format-Table | Out-String | Write-Host

        @($results).Count | Should -Be 2
        $results.Status | Should -Be @('Removed', 'Removed')

        $config = Get-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl
        $config.Dns.Hosts | Should -Not -Contain "$script:AIPv4 $script:AHostname"
        $config.Dns.CnameRecords | Should -Not -Contain "$script:CnameHostname,$script:CnameTarget,$script:CnameTtl"
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Remove-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -Type A -Hostname $script:AHostname -IPv4Address $script:AIPv4 -Restart $false -Confirm:$false -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
