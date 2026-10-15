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

Describe 'Get-PiHoleDnsRecord (Integration)' -Tag 'Integration' {
    BeforeAll {
        Import-Module .\PiHoleShell\PiHoleShell.psm1 -Force

        $script:AHostname = 'piholeshell-test-get-a.example.com'
        $script:AIPv4 = '192.0.2.203'
        $script:CnameHostname = 'piholeshell-test-get-cname.example.com'
        $script:CnameTarget = 'piholeshell-test-get-a.example.com'
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

            Add-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/hosts' -Value "$script:AIPv4 $script:AHostname" -Restart $false | Out-Null
            Add-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/cnameRecords' -Value "$script:CnameHostname,$script:CnameTarget,$script:CnameTtl" -Restart $false | Out-Null
        }
    }

    AfterAll {
        if ($script:PiHoleServer) {
            Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/hosts' -Value "$script:AIPv4 $script:AHostname" -Restart $false -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
            Remove-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/cnameRecords' -Value "$script:CnameHostname,$script:CnameTarget,$script:CnameTtl" -Restart $false -Confirm:$false -ErrorAction SilentlyContinue | Out-Null
        }
    }

    It 'returns both the A and CNAME test records, correctly typed' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl
        $result | Where-Object { $_.Hostname -in @($script:AHostname, $script:CnameHostname) } | Format-Table | Out-String | Write-Host

        $aRecord = $result | Where-Object { $_.Hostname -eq $script:AHostname }
        $aRecord | Should -Not -BeNullOrEmpty
        $aRecord.Type | Should -Be 'A'
        $aRecord.IPv4Address | Should -Be $script:AIPv4

        $cnameRecord = $result | Where-Object { $_.Hostname -eq $script:CnameHostname }
        $cnameRecord | Should -Not -BeNullOrEmpty
        $cnameRecord.Type | Should -Be 'CNAME'
        $cnameRecord.Target | Should -Be $script:CnameTarget
        $cnameRecord.Ttl | Should -Be $script:CnameTtl
    }

    It 'filters by -Type' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Type CNAME

        $result | Should -Not -BeNullOrEmpty
        ($result.Type | Select-Object -Unique) | Should -Be 'CNAME'
        $result.Hostname | Should -Contain $script:CnameHostname
    }

    It 'filters by -Hostname' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Hostname $script:AHostname

        $result | Should -Not -BeNullOrEmpty
        @($result).Count | Should -Be 1
        $result.Type | Should -Be 'A'
    }

    It 'returns the raw API response when RawOutput is set' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -RawOutput $true

        $result.PSObject.Properties.Name | Should -Contain 'Hosts'
        $result.PSObject.Properties.Name | Should -Contain 'CnameRecords'
        $result.Hosts | Should -Contain "$script:AIPv4 $script:AHostname"
    }

    It 'can be piped directly into Remove-PiHoleDnsRecord' -Skip:(-not $script:ConfigAvailable) {
        $removed = Get-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Hostname $script:AHostname |
            Remove-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Restart $false -Confirm:$false
        $removed | Format-List | Out-String | Write-Host

        $removed | Should -Not -BeNullOrEmpty
        $removed.Status | Should -Be 'Removed'

        $hosts = (Get-PiHoleConfig -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl).Dns.Hosts
        $hosts | Should -Not -Contain "$script:AIPv4 $script:AHostname"

        # Recreate it so AfterAll's cleanup (and other tests, if re-run) have a consistent state
        Add-PiHoleConfigArrayItem -PiHoleServer $script:PiHoleServer -Password $script:PiHoleToken -IgnoreSsl $script:PiHoleIgnoreSsl -Element 'dns/hosts' -Value "$script:AIPv4 $script:AHostname" -Restart $false | Out-Null
    }

    It 'errors when given a bad password' -Skip:(-not $script:ConfigAvailable) {
        $result = Get-PiHoleDnsRecord -PiHoleServer $script:PiHoleServer -Password 'definitely-not-the-real-token' -IgnoreSsl $script:PiHoleIgnoreSsl -ErrorVariable errOut -ErrorAction SilentlyContinue

        $errOut | Should -Not -BeNullOrEmpty
    }
}
