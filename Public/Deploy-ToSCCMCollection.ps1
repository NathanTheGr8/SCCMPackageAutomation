<#
.SYNOPSIS

This function doesn't currently work
.DESCRIPTION

Deploys a given App to a given SCCM collection. Defaults to deploying to a specified test collection.
.PARAMETER Colleciton

The Collection to Deploy to.
.PARAMETER PackageName

The package name to push.
.EXAMPLE

Deploy-ToSCCMCollection -PackageName "Firefox 63.0 (R1)"
#>

function Deploy-ToSCCMCollection {
        param
        (
            [Parameter(Mandatory = $false)]
            [string]
            $Collection = "DELL Desktop",
            [Parameter(Mandatory = $true)]
            [string]
            $PackageName
        )
        Write-Output "Deploying $PackageName to $Collection"
        $CMDeplColl = Get-CMCollection -Name $Collection -CollectionType Device
        try{
            #'Start-CMApplicationDeployment' has been deprecated in 1702 and may be removed in a future release.
            #The cmdlet 'New-CMApplicationDeployment' may be used as a replacement.
            Start-CMApplicationDeployment -Collection $CMDeplColl.Name -Name $PackageName -DeployAction Install -DeployPurpose Required
            Write-Host "Deployment Succeded" -ForegroundColor Green | Out-Null
        }
        catch
        {
            Write-Host "Failed" -ForegroundColor Red
            Write-Host "$_"
        }
}