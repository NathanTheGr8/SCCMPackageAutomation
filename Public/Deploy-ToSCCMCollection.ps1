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