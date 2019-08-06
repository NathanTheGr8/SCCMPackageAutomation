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
        HelpMessage = 'What standard app are you trying to get the version of?')]
        [string]
        [ValidateSet('7zip','BigFix','Chrome','CutePDF','Etcher','Firefox','Flash','GIMP','Git','Insync','Notepad++','OpenJDK','Putty','Reader','Receiver','SoapUI','VLC','VSCode','WinSCP','WireShark', IgnoreCase = $true)]
        $App,
        [switch]
        $ForceUpdate,
        [switch]
        $NoCleanUp
    )

    begin {
        $App = $App.ToLower()
        $MaintainedApp = $MaintainedApps | Where-Object {$_.Name -eq $App}
    }

    process {

        $CurrentAppVersion = Get-CurrentAppVersion -App $App
        $LatestAppVersion = Get-LatestAppVersion -App $App
        $RootApplicationPathTemp = $MaintainedApp.RootApplicationPath

        Mount-PackageShare

        if (([version]$CurrentAppVersion -lt [version]$LatestAppVersion) -or ($ForceUpdate)) {
            if ($ForceUpdate) {
                Write-Host "Forcing update of $App from $CurrentAppVersion to $LatestAppVersion"
            }
            else {
                Write-Host "Upgrading $App package from $CurrentAppVersion to $LatestAppVersion"
            }

            # Check SCCM Share Free Space
            $FreeDiskSpace = (Get-PSDrive | Where-Object {$_.Name -eq "$SCCM_Share_Letter"}).Free
            If ($FreeDiskSpace -lt 1000000000) {
                Write-Error "$SCCM_Share has less than 1 GB free."
                Throw
            }

            $InstallFiles = Download-LatestAppVersion -App $App
            $count = (Measure-Object -InputObject $SCCM_Share -Character).Characters + 1
            # Gets the most recent folder for a given app
            $AllAppVersions = "$($SCCM_Share_Letter):\" + $RootApplicationPathTemp.Substring($count) | Get-ChildItem | Sort-Object CreationTime -Descending
            $CurrentApp =  $AllAppVersions | Select-Object -f 1

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
            Write-Output "rootapppath is: $($MaintainedApp.RootApplicationPath)"
            $newAppPath

            #Copies the Current Package to the new. Replaces install files and increments version.
            Write-Output "Creating folder '$App $LatestAppVersion (R$RevNumber)'"
            Copy-PSADTAppFolders -OldPackageRootFolder "$($CurrentApp.FullName)" -NewPackageRootFolder "$newAppPath" -NewPSADTFiles $InstallFiles
            Write-Output "Updating version numbers from $CurrentAppVersion to $LatestAppVersion"
            Update-PSADTAppVersion -PackageRootFolder "$newAppPath" -CurrentVersion "$CurrentAppVersion" -NewVersion "$LatestAppVersion"
            Update-DetectionScriptAppVersion -PackageRootFolder "$newAppPath" -CurrentVersion "$CurrentAppVersion" -NewVersion "$LatestAppVersion"

            #Delete old package versions
            if (!$NoCleanUp) {
                $NumberOfPreviousVersionsToKeep = 5
                while ($AllAppVersions.count -gt $NumberOfPreviousVersionsToKeep){
                    Write-Output "There are more than $NumberOfPreviousVersionsToKeep previous versions of $app. Deleting $($AllAppVersions[-1].FullName) source files."
                    $AllAppVersions[-1].FullName | Remove-Item -Force -Recurse
                    $AllAppVersions = $AllAppVersions[0..($ExistingDeployments.length-2)]
                }
            }
            else {
                Write-Output "NoCleanUp switch used. Not removing previous version soruce files."
            }
        }
        else {
            Write-Host "$App $CurrentAppVersion package is already up to date"
        }
    }

}