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
        [ValidateSet('7zip','BigFix','Chrome','CutePDF','Firefox','Flash','GIMP','Git','insync','Java','Notepad++','Putty','Reader','Receiver','VLC','VSCode','WinSCP','WireShark', IgnoreCase = $true)]
        $App
    )
<<<<<<< HEAD
    $App = $App.ToLower()
    # Get-ChildItem has trouble working with UNC paths from the $SCCM_Site: drive. That is why I map a $SCCM_Share_Letter drive
    $count = (Measure-Object -InputObject $SCCM_Share -Character).Characters + 1
    # Gets the most recent folder for a given app
    $LatestApplicationPath =  "$($SCCM_Share_Letter):\" + $global:RootApplicationPath[$app].Substring($count) | Get-ChildItem | Sort-Object -Property CreationTime -Descending
    $LatestApplicationPath =  "$($SCCM_Share_Letter):\" + $global:RootApplicationPath[$app].Substring($count) | Get-ChildItem | Sort-Object -Property CreationTime -Descending | Select-Object -f 1
    $CurrentAppVersion = Get-PSADTAppVersion -PackageRootFolder "$($LatestApplicationPath.Fullname)"
    if ($app -eq "reader"){
        return $CurrentAppVersion #readers versions often have leading 0s
=======

    begin {
        $App = $App.ToLower()
>>>>>>> f8f319aa8e22d45b5bca7967cf307f961f2dce00
    }

    process {
        $App = $App.ToLower()
        # Get-ChildItem has trouble working with UNC paths from the $SCCM_Site: drive. That is why I map a $SCCM_Share_Letter drive
        $count = (Measure-Object -InputObject $SCCM_Share -Character).Characters + 1
        # Gets the most recent folder for a given app
        $LatestApplicationPath =  "$($SCCM_Share_Letter):\" + $global:RootApplicationPath[$app].Substring($count) | Get-ChildItem | Sort-Object -Property CreationTime -Descending | Select-Object -f 1
        $CurrentAppVersion = Get-PSADTAppVersion -PackageRootFolder "$($LatestApplicationPath.Fullname)"
        if ($app -eq "reader"){
            return $CurrentAppVersion #readers versions often have leading 0s
        }
        else {
            return [version]$CurrentAppVersion
        }
    }
}