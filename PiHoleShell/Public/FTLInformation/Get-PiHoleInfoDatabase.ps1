function Get-PiHoleInfoDatabase {
    <#
.SYNOPSIS
Get info about the long-term database

.DESCRIPTION
Request details about Pi-hole's long-term (on-disk) query database file: its size and
ownership on disk, how many queries are stored in-memory versus on-disk, and the earliest
timestamp in each.

.PARAMETER PiHoleServer
The URL to the PiHole Server, for example "http://pihole.domain.com:8080", or "http://192.168.1.100"

.PARAMETER Password
The API Password you generated from your PiHole server

.PARAMETER IgnoreSsl
Set to $true to skip SSL certificate validation

.PARAMETER RawOutput
This will dump the response instead of the formatted object

.EXAMPLE
Get-PiHoleInfoDatabase -PiHoleServer "http://pihole.domain.com:8080" -Password "your-app-password"
    #>
    [CmdletBinding(HelpUri = 'https://ftl.pi-hole.net/master/docs/#get-/info/database')]
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
        $Sid = Request-PiHoleAuth -PiHoleServer $PiHoleServer -Password $Password -IgnoreSsl $IgnoreSsl

        $Params = @{
            Headers              = @{sid = $($Sid) }
            Uri                  = "$($PiHoleServer.OriginalString)/api/info/database"
            Method               = "Get"
            SkipCertificateCheck = $IgnoreSsl
            ContentType          = "application/json"
        }

        $Response = Invoke-RestMethod @Params

        if ($RawOutput) {
            Write-Output $Response
        }
        else {
            # The API defaults these to 0.0 when there are no queries stored in-memory/on-disk yet.
            $EarliestTimestamp = if ($Response.earliest_timestamp -eq 0) { $null } else { (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Response.earliest_timestamp).LocalTime }
            $EarliestTimestampDisk = if ($Response.earliest_timestamp_disk -eq 0) { $null } else { (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Response.earliest_timestamp_disk).LocalTime }

            $Object = [PSCustomObject]@{
                Size                  = $Response.size
                Type                  = $Response.type
                Mode                  = $Response.mode
                AccessTime            = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Response.atime).LocalTime
                ModifiedTime          = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Response.mtime).LocalTime
                ChangeTime            = (Convert-PiHoleUnixTimeToLocalTime -UnixTime $Response.ctime).LocalTime
                Owner                 = [PSCustomObject]@{
                    User  = [PSCustomObject]@{
                        Uid  = $Response.owner.user.uid
                        Name = $Response.owner.user.name
                        Info = $Response.owner.user.info
                    }
                    Group = [PSCustomObject]@{
                        Gid  = $Response.owner.group.gid
                        Name = $Response.owner.group.name
                    }
                }
                Queries               = $Response.queries
                EarliestTimestamp     = $EarliestTimestamp
                QueriesDisk           = $Response.queries_disk
                EarliestTimestampDisk = $EarliestTimestampDisk
                SqliteVersion         = $Response.sqlite_version
            }
            Write-Output $Object
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
