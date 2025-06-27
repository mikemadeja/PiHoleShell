function Get-PiHoleTeleporter {
    <#
.SYNOPSIS
Get info about logs for webserver

    #>
    #Work In Progress
    [CmdletBinding()]
    [System.Diagnostics.CodeAnalysis.SuppressMessageAttribute("PSAvoidUsingPlainTextForPassword", "Password")]
    param (
        [Parameter(Mandatory = $true)]
        [System.URI]$PiHoleServer,
        [Parameter(Mandatory = $true)]
        [string]$Password,
        [Parameter(Mandatory = $true)]
        [System.IO.DirectoryInfo]$FolderPath,
        [Parameter(Mandatory = $true)]
        [string]$FileName,
        [bool]$IgnoreSsl = $false,
        [bool]$RawOutput = $false
    )
    try {
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        if (!(Test-Path -Path $FolderPath)) {
            throw "$FolderPath does not exist!"
        }
        $FileName = "$FileName.tar.gz"
        $OutFile = "$FolderPath\$FileName"
        if (Test-Path -Path $OutFile) {
            throw "$OutFile already exists!"
        }

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/teleporter"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params -OutFile $OutFile

        if ($RawOutput) {
            Write-Output $Response
        }

        else {
            $ObjectFinal = @()
            $Object = [PSCustomObject]@{
                FileName   = $FileName
                FilePath   = $OutFile
                RootFolder = $FolderPath
                FileSizeKB = [math]::Ceiling((Get-Item $OutFile).Length / 1KB)
            }
            $ObjectFinal += $Object
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