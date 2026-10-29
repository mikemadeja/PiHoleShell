function Get-PiHoleApiEndpoint {
    <#
.SYNOPSIS
Get list of available API endpoints

.DESCRIPTION
Returns every endpoint the Pi-hole API exposes, one object per HTTP method and URI. Parameters
holds any path parameters the endpoint accepts (e.g. "/{client}"), or is empty if it takes none.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleApiEndpoint -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"

.EXAMPLE
Get-PiHoleApiEndpoint -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" | Where-Object Method -eq 'DELETE'

Lists only the endpoints that delete something.
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/endpoints')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )

    try {
        $Response = Invoke-PiHoleApiRequest -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -Endpoint 'endpoints'

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            foreach ($MethodGroup in $Response.endpoints.PSObject.Properties) {
                foreach ($Endpoint in $MethodGroup.Value) {
                    $Object = [PSCustomObject]@{
                        Method     = $MethodGroup.Name.ToUpper()
                        Uri        = $Endpoint.uri
                        Parameters = $Endpoint.parameters
                    }
                    Write-Output $Object
                }
            }
        }
    }

    catch {
        Write-Error -Message (ConvertTo-PiHoleFriendlyErrorMessage -ErrorRecord $_)
    }
}
