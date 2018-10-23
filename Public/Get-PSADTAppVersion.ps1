<#
.SYNOPSIS

Gets the $appversion varible for a given PSADT package
.DESCRIPTION

Gets the $appversion varible for a given PSADT package
Queries the Deploy-Application.ps1 file for "appversion"
Takes the first string returned. I don't care about other occerences in the file
Converts it to a string
Splits it at the "=" taking the second half
Removes white space
Removes the "'" characters
.PARAMETER PackageRootFolder

The root folder for the PSADT package
.PARAMETER InstallScript

Defaults to Deploy-Applicaiton.ps1
.EXAMPLE

There's no need to number your examples.
.EXAMPLE
PowerShell will number them for you when it displays your help text to a user.
#>

function Get-PSADTAppVersion {
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateScript({
            if(-Not (Test-Path -Path "$_") ){
                throw "Folder does not exist"
            }
            if(-Not (Test-Path -Path "$_" -PathType Container) ){
                throw "The PackageRootFolder argument must be a folder. Files are not allowed."
            }
            return $true
        })]
        $PackageRootFolder,
        [string]
        [ValidateScript({
            if(-Not (Test-Path -Path "$PackageRootFolder\$InstallScript") ){
                throw "The PackageRootFolder argument path does not exist"
            }
            if(-Not (Test-Path -Path "$PackageRootFolder\$InstallScript" -PathType Leaf) ){
                throw "The InstallScript argument must be a file."
            }
            return $true
        })]
        $InstallScript = "Deploy-Application.ps1" #defaults to this

    )

    $Version = (Select-String -Path "$PackageRootFolder\$InstallScript" -SimpleMatch "appVersion")[0].ToString().Split("=")[1].Trim().Replace("'","")

    return $Version
}
