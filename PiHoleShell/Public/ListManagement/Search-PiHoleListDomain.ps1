function Search-PiHoleListDomain {
    <#
.SYNOPSIS
https://ftl.pi-hole.net/master/docs/#get-/search/-domain-

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Domain
The domain to search for in Pi-hole's lists

.PARAMETER PartialMatch
Set to $true to include partial matches, defaults to $false (exact matches only)

.PARAMETER MaxResults
Maximum number of results to return, defaults to 20

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Search-PiHoleListDomain -PiHoleServer "http://pihole.domain.com:8080" -Password "fjdsjfldsjfkldjslafjskdl" -Domain "doubleclick.net"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/search/-domain-')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [System.URI]$Domain,
        [bool]$PartialMatch = $false,
        [int]$MaxResults = 20,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Body = @{
            n       = $MaxResults
            partial = $PartialMatch
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/search/$Domain"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            Body                 = $Body
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            $ObjectFinal = @()
            foreach ($Item in $Response.search.gravity) {
                $Object = [PSCustomObject]@{
                    Domain         = $Item.domain
                    Address        = $Item.address
                    Comment        = $Item.comment
                    Enabled        = $Item.enabled
                    Id             = $Item.id
                    Type           = $Item.type
                    Groups         = $Item.groups
                    DateAdded      = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_added).LocalTime
                    DateModified   = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_modified).LocalTime
                    DateUpdated    = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_updated).LocalTime
                    Number         = $Item.number
                    InvalidDomains = $Item.invalid_domains
                    AbpEntries     = $Item.abp_entries
                    Status         = $Item.status
                }
                $ObjectFinal += $Object
            }
            foreach ($Item in $Response.search.domains) {
                $Object = [PSCustomObject]@{
                    Domain         = $Item.domain
                    Address        = $null
                    Comment        = $Item.comment
                    Enabled        = $Item.enabled
                    Id             = $Item.id
                    Type           = $Item.type
                    Groups         = $Item.groups
                    DateAdded      = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_added).LocalTime
                    DateModified   = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Item.date_modified).LocalTime
                    DateUpdated    = $null
                    Number         = $null
                    InvalidDomains = $null
                    AbpEntries     = $null
                    Status         = $Item.status
                }
                $ObjectFinal += $Object
            }
            Write-Output $ObjectFinal
        }
    }

    catch {
        Write-Error -Message $_.Exception.Message
        break
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}