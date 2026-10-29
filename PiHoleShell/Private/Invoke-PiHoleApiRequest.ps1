function Invoke-PiHoleApiRequest {
    #INTERNAL FUNCTION
    #
    # Logs in, calls one API endpoint and always logs out again - the request/session boilerplate
    # every public function otherwise repeats. Errors are left to propagate, so callers keep their
    # own catch block (and its ConvertTo-PiHoleFriendlyErrorMessage call) unchanged.
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,
        [string]$Method = "Get",
        [bool]$IgnoreSsl = $false
    )

    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/$($Endpoint.TrimStart('/'))"
            Method               = $Method
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        Invoke-RestMethod @Params -ErrorAction Stop
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}
