function Update-DetectionScriptAppVersion {
    <#
.SYNOPSIS
This function updates the version number of a Powershell App Deployment Toolkit install file
.DESCRIPTION
Updates the version number in a powershell app deployment toolkit. Specifically it updates the version number on line 68 "[string]$appversion = ''".
It updates it by searching a given file for "$appVersion = " and then replacing a given version with a new version.
.PARAMETER PackageRootFolder
The root folder fo the PSADT package.
.PARAMETER CurrentVersion
The old version number to replace
.PARAMETER NewVersion
The new version number to add.
.PARAMETER DetectionScript
The realtive path and name of the Detection Script file. Defaults to SupportFiles\SCCMApplicationDetection.ps1
.EXAMPLE

Update-PSADTAppVersion -PackageRootFolder \\servername\path\to\firefox\package -CurrentVersion 60.0.3 -NewVersion 63.0
#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateScript( {
                if (-Not (Test-Path -Path "$_") ) {
                    throw "Folder does not exist"
                }
                if (-Not (Test-Path -Path "$_" -PathType Container) ) {
                    throw "The PackageRootFolder argument must be a folder. Files are not allowed."
                }
                return $true
            })]
        $PackageRootFolder,
        [Parameter(Mandatory = $true)]
        [string]
        [ValidatePattern("^(\d+\.)?(\d+\.)?(\d+\.)?(\d+\.)?(\*|\d+)?$")]
        #basically can be up #.#.#.#.# or just one #
        $CurrentVersion,
        [Parameter(Mandatory = $true)]
        [string]
        [ValidatePattern("^(\d+\.)?(\d+\.)?(\d+\.)?(\d+\.)?(\*|\d+)?$")]
        #basically can be up #.#.#.#.# or just one #
        $NewVersion,
        [string]
        [ValidateScript( {
                if (-Not (Test-Path -Path "$PackageRootFolder\$DetectionScript") ) {
                    throw "The PackageRootFolder argument path does not exist"
                }
                if (-Not (Test-Path -Path "$PackageRootFolder\$DetectionScript" -PathType Leaf) ) {
                    throw "The InstallScript argument must be a file."
                }
                return $true
            })]
        $DetectionScript = "SupportFiles\SCCMApplicationDetection.ps1" #defaults to this

    )

    (Get-Content "$PackageRootFolder\$DetectionScript").Replace("`$appVersion = '$CurrentVersion'", "`$appVersion = '$NewVersion'") | Set-Content  -Path "$PackageRootFolder\$DetectionScript"
}