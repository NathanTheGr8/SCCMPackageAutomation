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
        [ValidateSet('7zip','BigFix','Chrome','CutePDF','Etcher','Firefox','Flash','GIMP','Git','Insync','Notepad++','OpenJDK','Putty','Reader','Receiver','VLC','VSCode','WinSCP','WireShark', IgnoreCase = $true)]
        $App,
        [switch]
        $NoCleanUp
    )

    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" # Import the ConfigurationManager.psd1 module
    Set-Location "$($global:SCCM_Site):" # Set the current location to be the site code.


    $ExistingDeployments = Get-CMPackageDeployment -CollectionName "$($GlobalApps[$app].ProductionAppCollection)" | Sort-Object -property {$_.AssignedSchedule.StartTime}

    Write-Output "Expiring Old Deployments to $($GlobalApps[$app].ProductionAppCollection)"
    foreach ($Deployment in $ExistingDeployments){
        if ($Deployment.ExpirationTimeEnabled -ne $true){
            Write-Output "Expiring Deployment from $($Deployment.PresentTime)"
            Set-CMPackageDeployment -EnableExpireSchedule $true -DeploymentExpireDateTime (Get-Date) -StandardProgramName "$($Deployment.ProgramName)" -CollectionId $Deployment.CollectionID -PackageId $Deployment.PackageID
        }
        else {
            Write-Output "Deployment from $($Deployment.PresentTime) already expired on $($Deployment.ExpirationTime)"
        }
    }


    $NumberOfDeploymentsToKeep = 2
    while ($ExistingDeployments.Count -gt $NumberOfDeploymentsToKeep){
        Write-Output "There were more than $NumberOfDeploymentsToKeep old deployments to $($GlobalApps[$app].ProductionAppCollection). Removing old deployments till there $NumberOfDeploymentsToKeep old deployments"
        $ExistingDeployments[0] | Remove-CMPackageDeployment -Force
        $ExistingDeployments = $ExistingDeployments[1..($ExistingDeployments.length-1)]
    }



    Write-Output "Preparing to deploy $App to $($GlobalApps[$app].ProductionAppCollection)"
    $packagesByName = Get-CMPackage -Name "*$app*"
    $packagesByName = $packagesByName | Where-Object {$_.Name -imatch "$app $VersionRegex \(R\d+\)"}
    $newestPackagesByName = $packagesByName | Sort-Object -Property name | Select-Object -Last 1

    try{
        Deploy-ToSCCMCollection -PackageName "$($newestPackagesByName.Name)" -Collection "$($GlobalApps[$app].ProductionAppCollection)"
        $SCCMFolderPath
        switch ($GlobalApps[$app].SCCMFolder) {
            "HomeOffice" {
                $SCCMFolderPath = "$($SCCM_Site):\Package\Home Office\Prod_Home Office"
            }
            "CoreApps" {
                $SCCMFolderPath = "$($SCCM_Site):\Package\Core_Apps_ALL\ALL_PRODUCTION Core Packages"
            }
            "Misc" {
                $SCCMFolderPath = "$($SCCM_Site):\Package\MISC\Prod MISC"
            }
        }
        Move-CMObject -FolderPath "$SCCMFolderPath" -ObjectId $newestPackagesByName.PackageID
        Write-Output "Moved $($newestPackagesByName.Name) to $SCCMFolderPath"
    }
    catch
    {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host "$_"
    }

    Set-Location "C:"
}