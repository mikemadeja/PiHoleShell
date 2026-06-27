function Request-PiHoleAuth {
    #INTERNAL FUNCTION
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [CmdletBinding()]
        [System.URI]$PiHoleServer,
        [string]$Password,
        [bool]$IgnoreSsl = $false
    )

    try {
        $Params = @{
            Uri                  = "$($PiHoleServer.OriginalString)/api/auth"
            Method               = "Post"
            ContentType          = "application/json"
            SkipCertificateCheck = $IgnoreSsl
            Body                 = @{password = $Password } | ConvertTo-Json
        }

        $Response = Invoke-RestMethod @Params -Verbose: $false
        Write-Verbose -Message "Request-PiHoleAuth Successful!"

        Write-Output $Response.session.sid
    }

    catch {
        Write-Error -Message $_.Exception.Message
        break
    }
}