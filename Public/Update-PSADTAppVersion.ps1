function Update-PSADTAppVersion {
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

    (Get-Content "$PackageRootFolder\$InstallScript").Replace("`$appVersion = '$CurrentVersion'","`$appVersion = '$NewVersion'") | Set-Content  -Path "$PackageRootFolder\$InstallScript"
}