# Shared setup/cleanup for the *-PiHoleDnsRecord integration tests. Dot-source this from a
# Describe block's BeforeAll, then call Initialize-DnsRecordTest.

function Initialize-DnsRecordTest {
    # Loads tests/IntegrationConfig.local.ps1 into $script:PiHoleServer/PiHoleToken/PiHoleIgnoreSsl
    # and removes any of the given test records a previous failed run left behind. Leaves
    # $script:PiHoleServer unset if the config file is missing.
    param (
        [string[]]$Hosts = @(),
        [string[]]$CnameRecords = @()
    )

    $script:TestRecords = @{ Hosts = $Hosts; CnameRecords = $CnameRecords }

    $configPath = Join-Path (Split-Path $PSScriptRoot -Parent) 'IntegrationConfig.local.ps1'
    if (-not (Test-Path $configPath)) {
        return
    }

    . $configPath
    $script:PiHoleServer = $PiHoleServer
    $script:PiHoleToken = $PiHoleToken
    $script:PiHoleIgnoreSsl = $PiHoleIgnoreSsl

    Clear-DnsRecordTestData
}

function Clear-DnsRecordTestData {
    # Removes the records passed to Initialize-DnsRecordTest without complaining if they aren't
    # there, so it's safe to call in AfterAll even after a test already removed them
    if (-not $script:PiHoleServer) {
        return
    }

    $removeParams = @{
        PiHoleServer  = $script:PiHoleServer
        Password      = $script:PiHoleToken
        IgnoreSsl     = $script:PiHoleIgnoreSsl
        Restart       = $false
        Confirm       = $false
        ErrorAction   = 'SilentlyContinue'
        WarningAction = 'SilentlyContinue'
    }

    foreach ($value in $script:TestRecords.Hosts) {
        Remove-PiHoleConfigArrayItem @removeParams -Element 'dns/hosts' -Value $value | Out-Null
    }
    foreach ($value in $script:TestRecords.CnameRecords) {
        Remove-PiHoleConfigArrayItem @removeParams -Element 'dns/cnameRecords' -Value $value | Out-Null
    }
}
