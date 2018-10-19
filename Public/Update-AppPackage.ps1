function Update-AppPackage {
    param
    (
        [Parameter(Mandatory = $true,
        HelpMessage = 'What standard app are you trying to update?')]
        [string]
        [ValidateSet('7zip','BigFix','Chrome','CutePDF','Firefox','Flash','GIMP','Git','insync','Java','Notepad++','Putty','Reader','Receiver','VLC','VSCode','WinSCP','WireShark', IgnoreCase = $true)]
        $App,
        [switch]
        $ForceUpdate

    )

    $CurrentAppVersion = Get-CurrentAppVersion -App $App
    $LatestAppVersion = Get-LatestAppVersion -App $App
    $RootApplicationPathTemp = $global:RootApplicationPath[$app]

    # Map network drive to SCCM
    # Test an arbitrary folder on the share
    $Networkpath = "$($SCCM_Share_Letter):\$SCCM_Share_Test_Folder"

    If (Test-Path -Path $Networkpath) {
        Write-Host "$($SCCM_Share_Letter) Drive to SCCM Exists already"
    }
    Else {
        #map network drive
        New-PSDrive -Name "$($SCCM_Share_Letter)" -PSProvider "FileSystem" -Root "$SCCM_Share" -Persist

        #check mapping again
        If (Test-Path -Path $Networkpath) {
            Write-Host "$($SCCM_Share_Letter) Drive has been mapped to SCCM"
        }
        Else {
            Write-Error "Couldn't map $($SCCM_Share_Letter) Drive to SCCM, aborting"
            Return
        }
    }
    # End Map Network Drive

    if (($CurrentAppVersion -lt [version]$LatestAppVersion) -or ($ForceUpdate)) {
        if ($ForceUpdate) {
            Write-Host "Forcing update of $App from $CurrentAppVersion to $LatestAppVersion"
        }
        else {
            Write-Host "Upgrading $App package from $CurrentAppVersion to $LatestAppVersion"
        }

        $InstallFiles = Download-LatestAppVersion -App $App
        $count = (Measure-Object -InputObject $SCCM_Share -Character).Characters + 1
        # Gets the most recent folder for a given app
        $CurrentAppPath =  "$($SCCM_Share_Letter):\" + $RootApplicationPathTemp.Substring($count) | Get-ChildItem | Sort-Object CreationTime -Descending | Select-Object -f 1

        $RevNumber = 1
        $newAppPath = "$RootApplicationPathTemp\$App $LatestAppVersion (R$RevNumber)"

        $alreadyExists = Test-Path -Path "$newAppPath"
        while ($alreadyExists){
            #if the newAppPath already exists increments R#
            Write-Output "'$App $LatestAppVersion (R$RevNumber)' already exists, auto incrementing the R`#"
            $RevNumber++
            $newAppPath = "$RootApplicationPathTemp\$App $LatestAppVersion (R$RevNumber)"
            $alreadyExists = Test-Path -Path "$newAppPath"
        }
        Write-Output "rootapppath is: $($global:RootApplicationPath[$app])"
        $newAppPath

        #Copies the Current Package to the new. Replaces install files and increments version.
        Write-Output "Creating folder '$App $LatestAppVersion (R$RevNumber)'"
        Copy-PSADTFolders -OldPackageRootFolder "$($CurrentAppPath.FullName)" -NewPackageRootFolder "$newAppPath" -NewPSADTFiles $InstallFiles
        Write-Output "Updating version numbers from $CurrentAppVersion to $LatestAppVersion"
        UpdatePSADTAppVersion -PackageRootFolder "$newAppPath" -CurrentVersion "$CurrentAppVersion" -NewVersion "$LatestAppVersion"

    }
    else {
        Write-Host "$App $CurrentAppVersion package is already up to date"
    }

}



function Get-PSADTAppVersion {
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

        .REMARKS

    #>
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
