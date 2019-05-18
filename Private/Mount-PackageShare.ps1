function Mount-PackageShare {
    <#
    .SYNOPSIS

    Map network drive to SCCM Package Share
    .DESCRIPTION

    .PARAMETER App

    .EXAMPLE

    #>

    # Test an arbitrary folder on the share
    $Networkpath = "$($SCCM_Share_Letter):\$SCCM_Share_Test_Folder"

    If (Test-Path -Path $Networkpath) {
        Write-Verbose "$SCCM_Share_Letter Drive to SCCM Exists already"
    }
    Else {
        #map network drive
        New-SmbMapping -LocalPath "$($SCCM_Share_Letter):" -RemotePath "$SCCM_Share" -Persistent $True | Out-Null

        #check mapping again
        If (Test-Path -Path $Networkpath) {
            Write-Verbose "$SCCM_Share_Letter Drive has been mapped to SCCM"
        }
        Else {
            Write-Error "Couldn't map $SCCM_Share_Letter Drive to SCCM, aborting"
            Throw
        }
    }
}