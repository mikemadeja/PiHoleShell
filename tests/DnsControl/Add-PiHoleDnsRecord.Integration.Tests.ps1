# Requires -Module Pester
#
# Integration tests that call a REAL Pi-hole server. Configure tests/IntegrationConfig.local.ps1
# (copy it from IntegrationConfig.example.ps1) before running. Tests are skipped automatically
# if that file is missing.
#
# NOTE: these tests add/remove fake records using TEST-NET-1/documentation (RFC 5737/3849)
# reserved addresses that will never route anywhere real. They require the app password used
# here to have "app_sudo" enabled in Pi-hole (Settings > All Settings), same as
# Add-PiHoleConfigArrayItem (called internally) - see its .DESCRIPTION. -Restart $false is used
# throughout to avoid the brief FTL restart a real config change otherwise triggers.

$script:ConfigAvailable = Test-Path (Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1')

Describe 'Add-PiHoleDnsRecord (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $script:AHostname = 'piholeshell-test-a.example.com'
        $script:AIPv4 = '192.0.2.201'
        $script:AaaaHostname = 'piholeshell-test-aaaa.example.com'
        $script:AaaaIPv6 = '2001:db8::201'
        $script:CnameHostname = 'piholeshell-test-cname.example.com'
        $script:CnameTarget = 'piholeshell-test-a.example.com'
        $script:CnameTtl = 300

        $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
        if (Test-Path $configPath) {
            . $configPath
            $script:PiHoleServer = $PiHoleServer
            $script:PiHoleToken = $PiHoleToken
            $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl

            # Defensive cleanup in case a previous failed run left these behind
            Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/hosts' -Value "$script:AIPv4 $script:AHostname" -Restart $false -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
            Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/hosts' -Value "$script:AaaaIPv6 $script:AaaaHostname" -Restart $false -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
            Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/cnameRecords' -Value "$script:CnameHostname,$script:CnameTarget,$script:CnameTtl" -Restart $false -Confirm:$false -ErrorAction SilentlyContinue -WarningAction SilentlyContinue | Out-Null
        }
    }

    AfterAll {
        if ($script:PiHoleServer) {
            Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/hosts' -Value "$script:AIPv4 $script:AHostname" -Restart $false -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
            Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/hosts' -Value "$script:AaaaIPv6 $script:AaaaHostname" -Restart $false -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
            Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/cnameRecords' -Value "$script:CnameHostname,$script:CnameTarget,$script:CnameTtl" -Restart $false -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        }
    }

    It 'adds an A record and returns a formatted object' -Skip:(-not $script:ConfigAvailable) {
        $result = Add-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Type A -Hostname $script:AHostname -IPv4Address $script:AIPv4 -Restart $false
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Status | Should -Be 'Added'

        $hosts = (Get-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl).Dns.Hosts
        $hosts | Should -Contain "$script:AIPv4 $script:AHostname"

        Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/hosts' -Value "$script:AIPv4 $script:AHostname" -Restart $false -Confirm:$false | Out-Null
    }

    It 'adds an AAAA record and returns a formatted object' -Skip:(-not $script:ConfigAvailable) {
        $result = Add-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Type AAAA -Hostname $script:AaaaHostname -IPv6Address $script:AaaaIPv6 -Restart $false
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Status | Should -Be 'Added'

        $hosts = (Get-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl).Dns.Hosts
        $hosts | Should -Contain "$script:AaaaIPv6 $script:AaaaHostname"

        Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/hosts' -Value "$script:AaaaIPv6 $script:AaaaHostname" -Restart $false -Confirm:$false | Out-Null
    }

    It 'adds a CNAME record with a TTL and returns a formatted object' -Skip:(-not $script:ConfigAvailable) {
        $result = Add-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Type CNAME -Hostname $script:CnameHostname -Target $script:CnameTarget -Ttl $script:CnameTtl -Restart $false
        $result | Format-List | Out-String | Write-Host

        $result | Should -Not -BeNullOrEmpty
        $result.Status | Should -Be 'Added'

        $cnames = (Get-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl).Dns.CnameRecords
        $cnames | Should -Contain "$script:CnameHostname,$script:CnameTarget,$script:CnameTtl"

        Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/cnameRecords' -Value "$script:CnameHostname,$script:CnameTarget,$script:CnameTtl" -Restart $false -Confirm:$false | Out-Null
    }

    It 'errors when -IPv4Address is missing for -Type A' -Skip:(-not $script:ConfigAvailable) {
        $result = Add-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Type A -Hostname $script:AHostname -Restart $false -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }

    It 'errors when -IPv4Address is not a valid IPv4 address' -Skip:(-not $script:ConfigAvailable) {
        $result = Add-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Type A -Hostname $script:AHostname -IPv4Address '2001:db8::1' -Restart $false -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }

    It 'errors when -Target is missing for -Type CNAME' -Skip:(-not $script:ConfigAvailable) {
        $result = Add-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Type CNAME -Hostname $script:CnameHostname -Restart $false -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Add-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -Type A -Hostname $script:AHostname -IPv4Address $script:AIPv4 -Restart $false -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
