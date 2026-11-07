function Remove-PiHoleDomain {
    <#
.SYNOPSIS
Remove a domain

.DESCRIPTION
Removes a domain from Pi-hole's per-domain allow/deny list. The Pi-hole API deletes domains in
a batch, so this sends a single-item batch containing just the domain you specify.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER Domain
The domain to remove

.PARAMETER Type
Whether this is an allowed or denied domain

.PARAMETER Kind
Whether -Domain is an exact match or a regular expression

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Remove-PiHoleDomain -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Domain "example.com" -Type Allow -Kind Exact
    #>
    [CmdletBinding(SupportsShouldProcess = $true, HelpUri = 'https://ftl.pi-hole.net/master/docs/#post-/domains-batchDelete')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$Domain,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Allow", "Deny")]
        [string]$Type,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Exact", "Regex")]
        [string]$Kind,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Target = "Pi-Hole domain $Domain of type $Type/$Kind"
        if ($PSCmdlet.ShouldProcess($Target, "Remove domain")) {
            $Body = @(
                @{
                    item = $Domain
                    type = $Type.ToLower()
                    kind = $Kind.ToLower()
                }
            )

            #For some reason this needs to be here to make it an array
            $Body = , $Body
            $Params = @{
                PiHoleServer = $PiHoleServer
                Password     = $Password
                Endpoint     = 'domains:batchDelete'
                Method       = "Post"
                IgnoreSsl    = $IgnoreSsl
                Body         = $Body | ConvertTo-Json -Depth 10 -Compress
            }

            $Response = Invoke-PiHoleApiRequest @Params

            if ($RawOutput) {
                Write-Output $Response
            }

            else {
                # A successful delete returns 204 No Content, so there's no response body to
                # build a rich object from.
                $Object = [PSCustomObject]@{
                    Domain = $Domain
                    Type   = $Type
                    Kind   = $Kind
                    Status = "Removed"
                }
                Write-Output $Object
            }
        }
    }

    catch {
        Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
    }
}
