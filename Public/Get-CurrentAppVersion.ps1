function Get-CurrentAppVersion {
<#
.SYNOPSIS

Gets the current app version for a given app
.DESCRIPTION

Gets the current app package version for a given app. Uses the Get-PSADTAppVersion function to get the version
.PARAMETER App

The App you want the version of.
.EXAMPLE

Get-CurrentAppVersion -App Firefox
#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
        HelpMessage = 'What standard app are you trying to get the version of?')]
        [string]
        [ValidateSet('7zip','BigFix','Chrome','CutePDF','Etcher','Firefox','Flash','GIMP','Git','Insync','Notepad++','OpenJDK','Putty','Reader','Receiver','VLC','VSCode','WinSCP','WireShark', IgnoreCase = $true)]
        $App
    )

    begin {
        $App = $App.ToLower()

        # Map network drive to SCCM
        # Test an arbitrary folder on the share
        $Networkpath = "$($SCCM_Share_Letter):\$SCCM_Share_Test_Folder"

        If (Test-Path -Path $Networkpath) {
            Write-Verbose "$($SCCM_Share_Letter) Drive to SCCM Exists already"
        }
        Else {
            #map network drive
            New-PSDrive -Name "$($SCCM_Share_Letter)" -PSProvider "FileSystem" -Root "$SCCM_Share" -Persist | out-null

            #check mapping again
            If (Test-Path -Path $Networkpath) {
                Write-Verbose "$($SCCM_Share_Letter) Drive has been mapped to SCCM"
            }
            Else {
                Write-Error "Couldn't map $($SCCM_Share_Letter) Drive to SCCM, aborting"
                Return
            }
        }
        # End Map Network Drive
    }

    process {
        $App = $App.ToLower()
        # Get-ChildItem has trouble working with UNC paths from the $SCCM_Site: drive. That is why I map a $SCCM_Share_Letter drive
        $count = (Measure-Object -InputObject $SCCM_Share -Character).Characters + 1
        # Gets the most recent folder for a given app, split it up into multiple lines to make it easier to read and debug
        $LatestApplicationPath =  "$($SCCM_Share_Letter):\" + $global:RootApplicationPath[$app].Substring($count) | Get-ChildItem
        $LatestApplicationPath = $LatestApplicationPath | Where-Object {$_.Name -match "[a-zA-Z0-9_.+-]+ [a-zA-Z0-9_.]+ \(R[0-9]\)"}
        $LatestApplicationPath = $LatestApplicationPath | Sort-Object -Property CreationTime -Descending | Select-Object -First 1
        $CurrentAppVersion = Get-PSADTAppVersion -PackageRootFolder "$($LatestApplicationPath.Fullname)"
        if ($app -eq "reader"){
            return $CurrentAppVersion #readers versions often have leading 0s
        }
        else {
            return [version]$CurrentAppVersion
        }
    }
}