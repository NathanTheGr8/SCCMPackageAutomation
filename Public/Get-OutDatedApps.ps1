function Get-OutDatedApps {
    <#
        .SYNOPSIS
        Loop through all apps to see which ones are out of date.

        .DESCRIPTION

        .EXAMPLE

        .REMARKS

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