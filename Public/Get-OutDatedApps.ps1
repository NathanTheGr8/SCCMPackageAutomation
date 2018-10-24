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

    $MaintainedApps = @()
    $BlackList = @("java","insync","cutepdf")
    ForEach ($App in $RootApplicationPath.Keys){
        if (!($BlackList.Contains($App))){
            $MaintainedApps += $app
        }
    }
    $MaintainedApps= $MaintainedApps | Sort-Object

    Foreach ($App in $MaintainedApps){
        [version]$currVer = Get-CurrentAppVersion -App $app
        [version]$LatestVer = Get-LatestAppVersion -App $App

        if ($LatestVer -gt $currVer){
            Write-Host "$App needs updated to $LatestVer. We are currently on $currVer" -ForegroundColor Red
        }
        else {
            Write-Host "$app is on latest version $LatestVer" -ForegroundColor Green
        }

    }
}