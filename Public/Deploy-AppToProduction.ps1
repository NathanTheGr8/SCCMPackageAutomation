<#
.SYNOPSIS

Deploy a given packaged application to the app's production program
.DESCRIPTION

Deploys a given App to a the app's prod collection. The prod collections are set in the global var config
.PARAMETER App

The app to promote to prod
.EXAMPLE

Deploy-AppToProduction -App Firefox
#>

function Deploy-AppToProduction {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateSet('7zip', 'BigFix', 'Chrome', 'CutePDF', 'Etcher', 'Firefox', 'Flash', 'GIMP', 'Git', 'Insync', 'Notepad++', 'OpenJDK', 'Putty', 'Reader', 'Receiver', 'SoapUI', 'VLC', 'VSCode', 'WinSCP', 'WireShark', IgnoreCase = $true)]
        $App,
        [switch]
        $NoCleanUp
    )

    Push-Location $PWD -StackName ModuleStack
    Import-ConfigManagerModule

    $MaintainedApp = $MaintainedApps | where { $_.Name -eq $App }
    $ExistingDeployments = Get-CMPackageDeployment -CollectionName "$($MaintainedApp.ProductionAppCollection)" | Sort-Object -property { $_.AssignedSchedule.StartTime }

    Write-Output "Expiring Old Deployments to $($MaintainedApp.ProductionAppCollection)"
    foreach ($Deployment in $ExistingDeployments) {
        if ($Deployment.ExpirationTimeEnabled -ne $true) {
            Write-Output "Expiring Deployment from $($Deployment.PresentTime)"
            Set-CMPackageDeployment -EnableExpireSchedule $true -DeploymentExpireDateTime (Get-Date) -StandardProgramName "$($Deployment.ProgramName)" -CollectionId $Deployment.CollectionID -PackageId $Deployment.PackageID
        }
        else {
            Write-Output "Deployment from $($Deployment.PresentTime) already expired on $($Deployment.ExpirationTime)"
        }
    }


    $NumberOfDeploymentsToKeep = 2 # Number of Previous Deployments to the Prod collection to keep.
    while ($ExistingDeployments.Count -gt $NumberOfDeploymentsToKeep) {
        Write-Output "There were more than $NumberOfDeploymentsToKeep old deployments to $($MaintainedApp.ProductionAppCollection). Removing oldest deployment."
        $ExistingDeployments[0] | Remove-CMPackageDeployment -Force
        $ExistingDeployments = $ExistingDeployments[1..($ExistingDeployments.length - 1)]
    }

    # $NumberOfPackagesToKeep is in GlobalVaribles.ps1
    $ExistingPackages = Get-CMPackage -Name "*$App*" | Where-Object { $_.Name -imatch "$app $VersionRegex \(R\d+\)" } | Sort-Object -Property Name
    while ($ExistingPackages.Count -gt $NumberOfPackagesToKeep) {
        Write-Output "There were more than $NumberOfPackagesToKeep old packages of $($MaintainedApp.DisplayName). Removing old package $($ExistingPackages[0].Name)"
        $ExistingPackages[0] | Remove-CMPackage -Force
        $ExistingPackages = $ExistingDeployments[1..($ExistingDeployments.length - 1)]
    }

    if (!($NoCleanUp)) {
        Write-Output "Moving old packages of $($MaintainedApp.DisplayName) to previous versions folder"
        switch ($MaintainedApp.SCCMFolder) {
            "HomeOffice" {
                $SCCMFolderPath = "$($SCCM_Site):\$($SCCMFolders.HomeOffice.PreviousVersion)"
            }
            "CoreApps" {
                $SCCMFolderPath = "$($SCCM_Site):\$($SCCMFolders.CoreApps.PreviousVersion)"
            }
            "Misc" {
                $SCCMFolderPath = "$($SCCM_Site):\$($SCCMFolders.Misc.PreviousVersion)"
            }
        }
        For ($i = 0; $i -le $ExistingPackages.count - 2; $i++) {
            Try {
                Move-CMObject -FolderPath "$SCCMFolderPath" -ObjectId $ExistingPackages[$i].PackageID
            }
            catch {
                Write-Host "Failed" -ForegroundColor Red
                Write-Host "$_"
            }
            Write-Output "Moved $($ExistingPackages[$i].Name) to $SCCMFolderPath"
        }
    }

    Write-Output "Preparing to deploy $App to $($MaintainedApp.ProductionAppCollection)"
    $newestExistingPackage = $ExistingPackages | Sort-Object -Property name | Select-Object -Last 1

    Deploy-PackageToSCCMCollection -PackageName "$($newestExistingPackage.Name)" -Collection "$($MaintainedApp.ProductionAppCollection)"

    try {
        switch ($MaintainedApp.SCCMFolder) {
            "HomeOffice" {
                $SCCMFolderPath = "$($SCCM_Site):\$($SCCMFolders.HomeOffice.Prod)"
            }
            "CoreApps" {
                $SCCMFolderPath = "$($SCCM_Site):\$($SCCMFolders.CoreApps.Prod)"
            }
            "Misc" {
                $SCCMFolderPath = "$($SCCM_Site):\$($SCCMFolders.Misc.Prod)"
            }
        }
        Move-CMObject -FolderPath "$SCCMFolderPath" -ObjectId $newestExistingPackage.PackageID
        Write-Output "Moved $($newestExistingPackage.Name) to $SCCMFolderPath"
    }
    catch {
        Write-Host "Moving of Package Failed" -ForegroundColor Red
        Write-Host "$_"
    }

    Pop-Location -StackName ModuleStack
}