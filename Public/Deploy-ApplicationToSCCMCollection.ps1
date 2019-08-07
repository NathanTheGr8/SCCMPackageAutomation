<#
.SYNOPSIS
Deploy a give Applicaiton to a given collection.
.DESCRIPTION
Deploys a given Applicaiton to a given SCCM collection.
.PARAMETER Colleciton
The Collection to Deploy to.
.PARAMETER ApplicaitonName
The package name to push.
.PARAMETER ApplicaitonName
The package name to push.
.EXAMPLE
Deploy-ToApplicationSCCMCollection -ApplicaitonName "Firefox 63.0 (R1)" -Collection ""
#>

function Deploy-ApplicationToSCCMCollection {
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Collection,
        [Parameter(Mandatory = $true)]
        [string]
        $ApplicationName,
        [Parameter(Mandatory = $false)]
        [string]
        [ValidateSet('Available', 'Required', IgnoreCase = $true)]
        $DeployPurpose = "available"
    )

    Write-Output "Deploying $ApplicaitonName to $Collection"
    $date = Get-Date
       
    try {

        # $NewDeployment = Start-CMApplicationDeployment -CollectionName $Collection -Name $ApplicationName -DeployPurpose $DeployPurpose `
        # -Comment "Deployed by PS module SCCMPackageAutomation" -DeployAction Install -UserNotification DisplayAll -AvailableDateTime $date.ToString() `
        # -DeadlineDateTime $date.ToString() -TimeBaseOn LocalTime -OverrideServiceWindow $true -PassThru
        $newDeployment = New-CMApplicationDeployment -CollectionName $Collection -Name $ApplicationName -DeployPurpose $DeployPurpose `
            -Comment "Deployed by PS module SCCMPackageAutomation" -DeployAction Install -UserNotification DisplayAll -AvailableDateTime $date.ToString() `
            -ApprovalRequired $false -TimeBaseOn LocalTime
        Write-Output "Deployment of $ApplicationName to $Collection Successful"
    }
    catch {
        Write-Host "Deployment of $ApplicationName to $Collection Failed" -ForegroundColor Red
        Write-Host "$_"
    }
}