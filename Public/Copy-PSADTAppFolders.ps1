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

function Copy-PSADTAppFolders {
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateScript({
            if(-Not (Test-Path -Path "$_") ){
                throw "The PackageRootFolder argument path does not exist"
            }
            if(-Not (Test-Path -Path "$_" -PathType Container) ){
                throw "The PackageRootFolder argument must be a folder. Files are not allowed."
            }
            return $true
        })]
        $OldPackageRootFolder,
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateScript({
            if((Test-Path -Path "$_") ){
                throw "The path for NewPackageRootFolder already exists"
            }
            return $true
        })]
        $NewPackageRootFolder,
        [Parameter(Mandatory = $true)]
        $NewPSADTFiles

    )
    Write-Output "Copying old package files to $NewPackageRootFolder"
    Copy-Item -Path "$OldPackageRootFolder" -Destination "$NewPackageRootFolder" -Recurse
    if ($OldPackageRootFolder -match "Reader"){
        Write-Output "Removing old msp install files"
        Remove-Item -Path "$NewPackageRootFolder\Files\*.msp"
    }
    elseif ($OldPackageRootFolder -match "BigFix"){
        Write-Output "Removing old exe install files"
        Remove-Item -Path "$NewPackageRootFolder\Files\*.exe"
    }
    else {
        Write-Output "Removing old install files"
        Remove-Item -Path "$NewPackageRootFolder\Files\*"
    }
    Write-Output "Copying new install files"
    Copy-Item -Path $NewPSADTFiles -Destination "$NewPackageRootFolder\Files" -Verbose

}