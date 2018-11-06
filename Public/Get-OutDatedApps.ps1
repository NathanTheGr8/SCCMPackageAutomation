function Get-OutDatedApps {
<#
.SYNOPSIS

Checks all currently maintianed apps for out of date versions
.DESCRIPTION

Loops through an array of currently maintained apps and checks the apps
current package version
The latest available version
If the app is out of date it prints out in red. If it is up to date it prints out in green.+
.EXAMPLE

Get-OutDatedApps
#>
    [CmdletBinding()]
    param
    (
        [switch]
        $HTML
    )

    $MaintainedApps = @()
    $BlackList = @("java","insync","cutepdf")
    ForEach ($App in $RootApplicationPath.Keys){
        if (!($BlackList.Contains($App))){
            $MaintainedApps += $app
        }
    }
    $MaintainedApps= $MaintainedApps | Sort-Object

    # save the current color
    $CurrentForegroundColor = $host.UI.RawUI.ForegroundColor

    Foreach ($App in $MaintainedApps){
        [version]$currVer = Get-CurrentAppVersion -App $app
        [version]$LatestVer = Get-LatestAppVersion -App $App

        if ($LatestVer -gt $currVer){
            if ($HTML) {
                "<font color=`"800000`">$App needs updated to $LatestVer. We are currently on $currVer</font> <br>"
            }
            else {
                # set the new color
                $host.UI.RawUI.ForegroundColor = "Red"
                Write-Output "$App needs updated to $LatestVer. We are currently on $currVer"
            }
        }
        else {
            if ($HTML) {
                "<font color=`"008000`">$App is on latest version $LatestVer</font> <br>"
            }
            else {
                # set the new color
                $host.UI.RawUI.ForegroundColor = "Green"
                Write-Output "$App is on latest version $LatestVer"
            }
        }
    }

    # restore the original color
    $host.UI.RawUI.ForegroundColor = $CurrentForegroundColor
}