function Get-PiHoleQuery {
    <#
.SYNOPSIS
Get queries

.DESCRIPTION
Request individual query log entries, with optional filtering. Returns the most recent 100
queries by default; use -Length for more, and -Cursor (the Id of the oldest query already
retrieved) to page further back. Use Get-PiHoleStatsQuerySuggestions to discover valid values
for the filter parameters.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER From
Only return queries from this Unix timestamp onward

.PARAMETER Until
Only return queries up to this Unix timestamp

.PARAMETER Length
Number of results to return. Defaults to 100

.PARAMETER Start
Offset from the first record

.PARAMETER Cursor
Database Id of the most recent query to start from - pass the previous call's oldest returned
Id here to page further back in time

.PARAMETER Domain
Only return queries for this domain. Wildcards ("*") are supported

.PARAMETER ClientIp
Only return queries from this client IP address. Wildcards ("*") are supported

.PARAMETER ClientName
Only return queries from this client hostname. Wildcards ("*") are supported

.PARAMETER Upstream
Only return queries sent to this upstream (or "cache", "blocklist", "permitted"). Wildcards
("*") are supported

.PARAMETER Type
Only return queries of this type (e.g. "A", "AAAA")

.PARAMETER Status
Only return queries with this status (e.g. "GRAVITY", "FORWARDED")

.PARAMETER Reply
Only return queries with this reply type (e.g. "NODATA", "NXDOMAIN")

.PARAMETER Dnssec
Only return queries with this DNSSEC status (e.g. "SECURE", "INSECURE")

.PARAMETER Disk
Set to $true to load queries from the on-disk long-term database instead of the in-memory one

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object - includes the pagination cursor
and total/filtered record counts alongside the queries array

.EXAMPLE
Get-PiHoleQuery -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"

.EXAMPLE
Get-PiHoleQuery -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Domain "doubleclick.net" -Length 20
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/queries')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Nullable[int]]$From,
        [Nullable[int]]$Until,
        [Nullable[int]]$Length,
        [Nullable[int]]$Start,
        [Nullable[int]]$Cursor,
        [string]$Domain,
        [string]$ClientIp,
        [string]$ClientName,
        [string]$Upstream,
        [string]$Type,
        [string]$Status,
        [string]$Reply,
        [string]$Dnssec,
        [Nullable[bool]]$Disk,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $QueryParams = [System.Collections.ArrayList]@()
        if ($PSBoundParameters.ContainsKey('From')) { $QueryParams.Add("from=$From") | Out-Null }
        if ($PSBoundParameters.ContainsKey('Until')) { $QueryParams.Add("until=$Until") | Out-Null }
        if ($PSBoundParameters.ContainsKey('Length')) { $QueryParams.Add("length=$Length") | Out-Null }
        if ($PSBoundParameters.ContainsKey('Start')) { $QueryParams.Add("start=$Start") | Out-Null }
        if ($PSBoundParameters.ContainsKey('Cursor')) { $QueryParams.Add("cursor=$Cursor") | Out-Null }
        if ($Domain) { $QueryParams.Add("domain=$([System.Uri]::EscapeDataString($Domain))") | Out-Null }
        if ($ClientIp) { $QueryParams.Add("client_ip=$([System.Uri]::EscapeDataString($ClientIp))") | Out-Null }
        if ($ClientName) { $QueryParams.Add("client_name=$([System.Uri]::EscapeDataString($ClientName))") | Out-Null }
        if ($Upstream) { $QueryParams.Add("upstream=$([System.Uri]::EscapeDataString($Upstream))") | Out-Null }
        if ($Type) { $QueryParams.Add("type=$([System.Uri]::EscapeDataString($Type))") | Out-Null }
        if ($Status) { $QueryParams.Add("status=$([System.Uri]::EscapeDataString($Status))") | Out-Null }
        if ($Reply) { $QueryParams.Add("reply=$([System.Uri]::EscapeDataString($Reply))") | Out-Null }
        if ($Dnssec) { $QueryParams.Add("dnssec=$([System.Uri]::EscapeDataString($Dnssec))") | Out-Null }
        if ($PSBoundParameters.ContainsKey('Disk')) { $QueryParams.Add("disk=$($Disk.ToString().ToLower())") | Out-Null }

        $Uri = "$($PiHoleServer.OriginalString)/api/queries"
        if ($QueryParams.Count -gt 0) {
            $Uri += "?" + ($QueryParams -join '&')
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = $Uri
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            $ObjectFinal = foreach ($Item in $Response.queries) {
                [PSCustomObject]@{
                    Id       = $Item.id
                    Time     = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.time).LocalTime
                    Type     = $Item.type
                    Domain   = $Item.domain
                    Cname    = $Item.cname
                    Status   = $Item.status
                    Client   = [PSCustomObject]@{
                        Ip   = $Item.client.ip
                        Name = $Item.client.name
                    }
                    Dnssec   = $Item.dnssec
                    Reply    = [PSCustomObject]@{
                        Type = $Item.reply.type
                        Time = $Item.reply.time
                    }
                    ListId   = $Item.list_id
                    Upstream = $Item.upstream
                    Ede      = [PSCustomObject]@{
                        Code = $Item.ede.code
                        Text = $Item.ede.text
                    }
                }
            }
            Write-Output $ObjectFinal
        }
    }

    catch {
        Write-Error -Message $_.Exception.Message
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}
