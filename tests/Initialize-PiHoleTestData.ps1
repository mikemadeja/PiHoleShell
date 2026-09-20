<#
.SYNOPSIS
Generates some real DNS query traffic against a Pi-hole server so its stats aren't all zero.

.DESCRIPTION
Resolves a random mix of well-known domains (for forwarded/cached queries) and known
ad/tracker domains (for blocked queries) directly against the Pi-hole's DNS resolver, using
the same hostname as the API server. Live stats (Get-PiHoleStats*) reflect this immediately;
the on-disk "database" stats (Get-PiHoleStatsDatabase*) only reflect it once FTL's periodic
flush to the long-term database runs, so don't expect seeded data to appear there within the
same test run - this is still useful for building up real history across repeated runs.

Windows-only: relies on the Resolve-DnsName cmdlet.

.PARAMETER DnsServer
Hostname or IP of the Pi-hole's DNS resolver (typically the same host as the API, without the
scheme or port - e.g. $PiHoleServer.Host).

.PARAMETER Count
How many domains to query this run.
#>
[CmdletBinding()]
param (
    [Parameter(Mandatory = $true)]
    [string]$DnsServer,
    [int]$Count = 8
)

$permittedDomains = @(
    'example.com', 'wikipedia.org', 'github.com', 'microsoft.com', 'apple.com',
    'cloudflare.com', 'stackoverflow.com', 'reddit.com', 'nytimes.com', 'bbc.com',
    'mozilla.org', 'python.org'
)
$blockedDomains = @(
    'doubleclick.net', 'googlesyndication.com', 'googleadservices.com',
    'adservice.google.com', 'ads.pubmatic.com', 'analytics.google.com'
)

$pool = $permittedDomains + $blockedDomains
$selected = $pool | Get-Random -Count ([Math]::Min($Count, $pool.Count))

foreach ($domain in $selected) {
    try {
        Resolve-DnsName -Name $domain -Server $DnsServer -ErrorAction Stop | Out-Null
        Write-Verbose "Queried $domain"
    }
    catch {
        # A blocked or non-existent domain can still throw here depending on how it's blocked;
        # either way, the query itself already reached Pi-hole and was logged.
        Write-Verbose "Query for $domain errored (likely blocked): $($_.Exception.Message)"
    }
}
