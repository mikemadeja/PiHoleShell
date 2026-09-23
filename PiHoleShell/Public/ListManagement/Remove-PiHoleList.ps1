function Remove-PiHoleList {
    <#
.SYNOPSIS
Remove a list

.DESCRIPTION
Unsubscribes Pi-hole from an allow or block list. The Pi-hole API deletes lists in a batch,
so this sends a single-item batch containing just the list you specify.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER Address
The URL of the list to remove

.PARAMETER Type
Whether this is an Allow list or a Block list

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Remove-PiHoleList -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -Address "https://hosts-file.net/ad_servers.txt" -Type Block
    #>
    [CmdletBinding(SupportsShouldProcess = $true, HelpUri = 'https://ftl.pi-hole.net/master/docs/#post-/lists-batchDelete')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [bool]$IgnoreSsl = $false,
        [Parameter(Mandatory = $true)]
        [System.Uri]$Address,
        [Parameter(Mandatory = $true)]
        [ValidateSet("Allow", "Block")]
        [string]$Type,
        [bool]$RawOutput = $false
    )
    try {
        $Target = "Pi-Hole list $Address of type $Type"
        if ($PSCmdlet.ShouldProcess($Target, "Remove list")) {
            $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

            $Body = @(
                @{
                    item = $Address
                    type = $Type.ToLower()
                }
            )

            #For some reason this needs to be here to make it an array
            $Body = , $Body
            $Params = @{
                Headers              = @{sid = $($Sid) }
                Uri                  = "$($PiHoleServer.OriginalString)/api/lists:batchDelete"
                Method               = "Post"
                SkipCertificateCheck = $IgnoreSsl
                Body                 = $Body | ConvertTo-Json -Depth 10 -Compress
                ContentType          = "application/json"
            }

            $Response = Invoke-RestMethod @Params

            if ($RawOutput) {
                Write-Output $Response
            }

            else {
                # A successful delete returns 204 No Content, so there's no response body to
                # build a rich object from.
                $Object = [PSCustomObject]@{
                    Address = $Address
                    Type    = $Type
                    Status  = "Removed"
                }
                Write-Output $Object
            }
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