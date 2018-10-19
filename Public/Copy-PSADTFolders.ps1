function Copy-PSADTFolders {
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