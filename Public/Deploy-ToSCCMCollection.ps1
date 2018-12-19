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
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $false)]
        [string]
        $Collection = "Dell Desktops*",
        [Parameter(Mandatory = $true)]
        [string]
        $PackageName
    )

    Write-Output "Deploying $PackageName to $Collection"
    try{

        # Begin Pick Default Program
        $Programs = Get-CMProgram -PackageName $PackageName
        $DefaultProgram
        if ($Programs.count -gt 1){
            Write-Output "There was more than one program for $PackageName"
            $ProgramNames = $Programs.$ProgramName
            $InstallProgram = $ProgramNames | Where-Object {$_ -Like "install*"}
            if ($null -eq $InstallProgram){
                $DefaultProgram = $Programs[0].ProgramName
                Write-Output "No install program found, defaulting to first program: $DefaultProgram"
            }
            else {
                if ($InstallProgram.count -gt 1){
                    $DefaultProgram = $InstallProgram[0]
                    Write-Output "More than one install program found defaulting to first one: $DefaultProgram"
                }
                else {
                    $DefaultProgram = $InstallProgram
                    Write-Output "Defaulting to install program: $DefaultProgram"
                }
            }
        }
        else {
            $DefaultProgram = $Programs.ProgramName
            Write-Output "Defaulting to only program found: $DefaultProgram"
        }
        # End Pick Default Program

        #'Start-CMPackageDeployment' has been deprecated in 1702 and may be removed in a future release.
        #The cmdlet 'New-CMPackageDeployment' may be used as a replacement.
        $NewDeployment = New-CMPackageDeployment -CollectionName "$Collection" -PackageName $PackageName -AllowSharedContent $false -DeployPurpose Required -ProgramName $DefaultProgram -StandardProgram -RerunBehavior RerunIfFailedPreviousAttempt -ScheduleEvent AsSoonAsPossible -SlowNetworkOption DownloadContentFromDistributionPointAndLocally -FastNetworkOption DownloadContentFromDistributionPointAndRunLocally -RunFromSoftwareCenter $true
        Write-Output "Deployment Succeded"
    }
    catch
    {
        Write-Host "Failed" -ForegroundColor Red
        Write-Host "$_"
    }
}