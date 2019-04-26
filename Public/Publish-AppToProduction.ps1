<#
.SYNOPSIS

Deploy a given packaged application to the app's production program
.DESCRIPTION

Deploys a given App to a the app's prod collection. The prod collections are set in the global var config
.PARAMETER App

The app to promote to prod
.EXAMPLE

Publish-AppToProduction -App Firefox
#>

function Publish-AppToProduction {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $App
    )

    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" # Import the ConfigurationManager.psd1 module
    Set-Location "$($global:SCCM_Site):" # Set the current location to be the site code.

    Write-Output "Deploying $App to $($ProductionAppCollections[$app])"
    $packagesByName = Get-CMPackage -Name "*$app*"
    $newestPackagesByName = $packagesByName | Sort-Object -Property name | Select-Object -Last 1

    Write-Output "Deploying $($newestPackagesByName.Name) to $($ProductionAppCollections[$app])"

    try{
        Deploy-ToSCCMCollection -PackageName "$($newestPackagesByName.Name)" -Collection "$($ProductionAppCollections[$app])"
        Write-Output "Deployment Succeded"
    }
    catch
    {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host "$_"
    }

    Set-Location "C:"
}