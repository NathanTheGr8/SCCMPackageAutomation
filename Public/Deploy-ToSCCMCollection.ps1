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