function Update-PiHoleGroup {
    <#
.SYNOPSIS
Items may be updated by replacing them.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

    #>
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    [Diagnostics.CodeAnalysis.SuppressMessage("PSUseShouldProcessForStateChangingFunctions", "", Justification = "Ignoring for now")]
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#put-/groups/-name-')]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$GroupName,
        [string]$Comment = $null,
        [bool]$Enabled,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false

    )
    #Enabled is weird here.. look into it
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Body = @{
            name = $GroupName
        }

        $GetGroupName = Get-PiHoleGroup -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -GroupName $GroupName

        if ($Comment -eq $null -and $Enabled -eq $null) {
            Write-Warning -Message "failed"
            throw -Message "To update $GroupName, you must either use the Comment and/or Enabled parameter"
        }

        if ($Comment) {
            $Body += @{
                comment = $Comment
            }
        }
        if ($Enabled -ne $null) {
            $Body += @{
                enabled = $Enabled
            }
        }
        else {
            switch ($GetGroupStatus) {
                "True" {
                    $true
                }
                "False" {
                    $false
                }
            }

            $Body += @{
                enabled = $GetGroupStatus
            }
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/groups/$GroupName"
            Method               = "Put"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
            Body                 = $Body | ConvertTo-Json -Depth 10
        }

        if ($GetGroupName) {
            $Response = Invoke-RestMethod @Params
            if ($RawOutput) {
                Write-Output $Response
            }
            else {
                $ObjectFinal = @()
                $Object = [PSCustomObject]@{
                    Name    = $GroupName
                    Comment = $Comment
                    Enabled = $Enabled
                }
                Write-Verbose -Message "Name - $($Object.GroupName)"
                Write-Verbose -Message "Comment - $($Object.Comment)"
                Write-Verbose -Message "Enabled - $($Object.Enabled)"
                $ObjectFinal = $Object
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