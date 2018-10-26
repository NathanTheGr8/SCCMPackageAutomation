function Update-AppPackageSource {
<#
.SYNOPSIS

Updates a given apps package source to the latest version
.DESCRIPTION

Updates a given app's source files to the latest version. Copies the old files to a new location, deletes the old psadt files directory,
copyies new install files to psadt files directory, updates the psadt version number
.PARAMETER App

What app's source files are you trying to update?
.EXAMPLE

Update-AppPackageSource -App Firefox
#>
    [CmdletBinding()]
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

    if (([version]$CurrentAppVersion -lt [version]$LatestAppVersion) -or ($ForceUpdate)) {
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
        Copy-PSADTAppFolders -OldPackageRootFolder "$($CurrentAppPath.FullName)" -NewPackageRootFolder "$newAppPath" -NewPSADTFiles $InstallFiles
        Write-Output "Updating version numbers from $CurrentAppVersion to $LatestAppVersion"
        Update-PSADTAppVersion -PackageRootFolder "$newAppPath" -CurrentVersion "$CurrentAppVersion" -NewVersion "$LatestAppVersion"

    }
    else {
        Write-Host "$App $CurrentAppVersion package is already up to date"
    }

}