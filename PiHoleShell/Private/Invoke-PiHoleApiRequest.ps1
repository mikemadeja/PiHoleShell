function Invoke-PiHoleApiRequest {
    #INTERNAL FUNCTION
    #
    # Logs in, calls one API endpoint and always logs out again - the request/session boilerplate
    # every public function otherwise repeats. Errors are left to propagate, so callers keep their
    # own catch block (and its ConvertTo-PiHoleFriendlyErrorMessage call) unchanged.
    #
    # Body is passed through as-is: callers serialize JSON bodies themselves (array bodies need
    # ConvertTo-Json -InputObject or a leading comma to survive), and a hashtable Body on a Get
    # becomes the query string. Form (multipart upload) and OutFile (binary download) are passed
    # through the same way, and a Form request gets no ContentType so the multipart one is used.
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [string]$Endpoint,
        [string]$Method = "Get",
        $Body,
        [hashtable]$Form,
        [string]$OutFile,
        [bool]$IgnoreSsl = $false
    )

    try {
        # -ErrorAction Stop so a failed login (wrong password, server unreachable) ends here with
        # its one error, instead of also sending the request without a session and reporting a
        # second, less useful 401.
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl -ErrorAction Stop

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/$($Endpoint.TrimStart('/'))"
            Method               = $Method
            SkipCertificateCheck = $IgnoreSsl
        }

        if ($PSBoundParameters.ContainsKey('Form')) {
            $Params.Form = $Form
        }
        else {
            $Params.ContentType = "application/json"
        }
        if ($PSBoundParameters.ContainsKey('Body')) {
            $Params.Body = $Body
        }
        if ($OutFile) {
            $Params.OutFile = $OutFile
        }

        Invoke-RestMethod @Params -ErrorAction Stop
    }

    finally {
        if ($Sid) {
            Remove-PiHoleCurrentAuthSession -PiHoleServer $PiHoleServer -Sid $Sid -IgnoreSsl $IgnoreSsl
        }
    }
}
