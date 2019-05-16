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


    # save the current color
    # $CurrentForegroundColor = $host.UI.RawUI.ForegroundColor

    Foreach ($App in $MaintainedApps){
        if (!($App.BlackList)){
            [version]$currVer = Get-CurrentAppVersion -App $App.Name
            [version]$LatestVer = Get-LatestAppVersion -App $App.Name

            if ($LatestVer -gt $currVer){
                if ($HTML) {
                    "<font color=`"CD0000`">$($App.Name) needs updated to $LatestVer, we are currently on $currVer</font> <br>"
                }
                else {
                    # # set the new color
                    # $host.UI.RawUI.ForegroundColor = "Red"
                    Write-Host "$($App.Name) needs updated to $LatestVer, we are currently on $currVer" -ForegroundColor Red
                }
            }
            else {
                if ($HTML) {#008000
                    "<font color=`"00A000`">$($App.Name) is on latest version $LatestVer</font> <br>"
                }
                else {
                    # # set the new color
                    # $host.UI.RawUI.ForegroundColor = "Green"
                    Write-Host "$($App.Name) is on latest version $LatestVer" -ForegroundColor Green
                }
            }
        }
    }

    # restore the original color
    # $host.UI.RawUI.ForegroundColor = $CurrentForegroundColor
}