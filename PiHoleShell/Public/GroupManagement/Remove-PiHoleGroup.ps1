function Remove-PiHoleGroup {
    <#
.SYNOPSIS
Delete one or more groups

.DESCRIPTION
Deletes one or more groups from Pi-hole in a single batch call. Any lists or clients assigned
to a deleted group are unassigned, not deleted.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER GroupName
The name(s) of the group(s) to delete

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Remove-PiHoleGroup -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -GroupName "Kids"

.EXAMPLE
Remove-PiHoleGroup -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password" -GroupName "Kids", "Guests"
    #>
    [CmdletBinding(SupportsShouldProcess = $true, HelpUri = 'https://ftl.pi-hole.net/master/docs/#post-/groups-batchDelete')]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string[]]$GroupName,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Target = "Pi-Hole group(s) $($GroupName -join ', ')"
        if ($PSCmdlet.ShouldProcess($Target, "Remove group(s)")) {
            # The batch delete API silently succeeds even for a group name that doesn't exist,
            # rather than reporting it as an error - check every name exists first so this
            # function never falsely reports a nonexistent group as "Deleted".
            $AllGroups = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl
            foreach ($Name in $GroupName) {
                if (-not ($AllGroups | Where-Object { $_.Name -eq $Name })) {
                    throw "Cannot find $Name on $PiHoleServer! Please use Get-PiHoleGroup to list all groups"
                }
            }

            $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

            # @() forces this to stay an array even for a single name - without it, PowerShell
            # unwraps a one-item foreach result to a bare hashtable, which ConvertTo-Json then
            # serializes as a JSON object instead of an array, and the API rejects it with 400.
            $Body = @(foreach ($Name in $GroupName) {
                    @{ item = $Name }
                })

            $Params = @{
                Headers              = @{sid = $($Sid) }
                Uri                  = "$($PiHoleServer.OriginalString)/api/groups:batchDelete"
                Method               = "Post"
                SkipCertificateCheck = $IgnoreSsl
                # -InputObject (not piped) so ConvertTo-Json serializes the array as-is instead of
                # unwrapping it into individual pipeline objects first.
                Body                 = ConvertTo-Json -InputObject $Body -Depth 10 -Compress
                ContentType          = "application/json"
            }

            $Response = Invoke-RestMethod @Params

            if ($RawOutput) {
                Write-Output $Response
            }

            else {
                # A successful delete returns 204 No Content, so there's no response body to
                # build a rich object from.
                $ObjectFinal = foreach ($Name in $GroupName) {
                    [PSCustomObject]@{
                        Name   = $Name
                        Status = "Deleted"
                    }
                }
                Write-Output $ObjectFinal
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
