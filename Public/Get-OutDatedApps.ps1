<#
.SYNOPSIS

The synopsis goes here. This can be one line, or many.
.DESCRIPTION

The description is usually a longer, more detailed explanation of what the script or function does. Take as many lines as you need.
.PARAMETER computername

Here, the dotted keyword is followed by a single parameter name. Don't precede that with a hyphen. The following lines describe the purpose of the parameter:
.PARAMETER filePath

Provide a PARAMETER section for each parameter that your script or function accepts.
.EXAMPLE

There's no need to number your examples.
.EXAMPLE
PowerShell will number them for you when it displays your help text to a user.
#>

function Get-OutDatedApps {

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