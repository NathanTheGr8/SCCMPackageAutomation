function New-StandardChangeSCCMPackage {
<#
.SYNOPSIS

Creates a new SCCM package for one of the standard change apps.
.DESCRIPTION

Packages a given locaiton's install files in SCCM. It
Creates the new package
Makes an install program
Distrubutes the package to DPs
Moves the package to a given folder
Updates "not current version" collections to the new version
.PARAMETER App

The app you are trying to package in SCCM. Valid options have tab completion.
.EXAMPLE

New-StandardChangeSCCMPackage -App Firefox
#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
        HelpMessage = 'What standard app are you trying to get the version of?')]
        [string]
        [ValidateSet('7zip','BigFix','Chrome','CutePDF','Etcher','Firefox','Flash','GIMP','Git','Insync','Notepad++','OpenJDK','Putty','Reader','Receiver','VLC','VSCode','WinSCP','WireShark', IgnoreCase = $true)]
        $App
    )

    begin {
        $App = $App.ToLower()
    }

    process {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" # Import the ConfigurationManager.psd1 module
        Set-Location "$($SCCM_Site):" # Set the current location to be the site code.

        # Map network drive to SCCM
        # Test an arbitrary folder on the share
        $Networkpath = "$($SCCM_Share_Letter):\$SCCM_Share_Test_Folder"

        If (Test-Path -Path $Networkpath) {
            Write-Host "$SCCM_Share_Letter Drive to SCCM Exists already"
        }
        Else {
            #map network drive
            New-PSDrive -Name "$SCCM_Share_Letter" -PSProvider "FileSystem" -Root "$SCCM_Share" -Persist

            #check mapping again
            If (Test-Path -Path $Networkpath) {
                Write-Host "$SCCM_Share_Letter Drive has been mapped to SCCM"
            }
            Else {
                Write-Error "Couldn't map $SCCM_Share_Letter Drive to SCCM, aborting"
                Return
            }
        }
        # End Map Network Drive

        $MaintainedApp = $MaintainedApps | where {$_.Name -eq $App}
        Update-AppHelper -AppName "$($MaintainedApp.DisplayName)" -rootApplicationPath "$($MaintainedApp.RootApplicationPath)" -SCCMFolder "$($MaintainedApp.SCCMFolder)" -Manufacturer "$($MaintainedApp.Manufacturer)"
        Set-Location "c:" #change location back to c drive. Otherwise other functions break
    }

}

function Update-AppHelper {
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $AppName,
        [Parameter(Mandatory = $true)]
        [string]
        $rootApplicationPath,
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateSet('HomeOffice', 'CoreApps','Misc', IgnoreCase = $true)]
        $SCCMFolder,
        [Parameter(Mandatory = $true)]
        [string]
        $Manufacturer,
        [Parameter(Mandatory = $false)]
        [int]
        $Duration = 20,
        [Parameter(Mandatory = $false)]
        [string]
        $Language = "English"
    )
    switch ($SCCMFolder) {
        "HomeOffice" {
            $SCCMFolderPath = "$($SCCM_Site):\$($SCCMFolders.HomeOffice.QA)"
        }
        "CoreApps" {
            $SCCMFolderPath = "$($SCCM_Site):\$($SCCMFolders.CoreApps.QA)"
        }
        "Misc" {
            $SCCMFolderPath = "$($SCCM_Site):\$($SCCMFolders.Misc.QA)"
        }
    }

    # Get-ChildItem has trouble working with UNC paths from the $SCCM_Site: drive. That is why I map a $SCCM_Share_Letter drive
    $count = (Measure-Object -InputObject $SCCM_Share -Character).Characters + 1
    # Gets the most recent folder for a given app
    $AppPath =  "$($SCCM_Share_Letter):\" + $rootApplicationPath.Substring($count) | Get-ChildItem | Sort-Object -Property CreationTime -Descending | Select-Object -First 1
    # Each app folder is named like 'AppName Version (R#). So this line just selects Version R#
    $AppVersion = $AppPath.Name -split ' ' | Select-Object -Last 2
    # Transform the app path back to a full unc path withouth a drive letter
    $AppPath = "$SCCM_Share"+($AppPath.FullName).Substring(2)
    $AppNameFull = "$AppName $appVersion"

    $alreadyExists = Get-CMPackage -Name $AppNameFull
    while ($alreadyExists){
        #if the package name already exists increments R#
        Write-Output "$AppNameFull already exists in SCCM, auto incrementing the R`#"
        #This line is overly complex, but it works. I couldn't think of a better way to write it.
        $AppNameFull = $AppNameFull.Substring(0,$AppNameFull.Length - 2) + ([int]$AppNameFull.Substring($AppNameFull.Length - 2,1)+1)+ ")"
        $alreadyExists = Get-CMPackage -Name $AppNameFull
    }

    try {
        $Application = New-CMPackage -Name "$AppNameFull" -Path "$appPath" -Manufacturer "$Manufacturer" -Language "$Language"
        Write-Output "$AppNameFull created in SCCM"
    }
    catch [exception]{
        Write-Output "$_"
        break
    }

    try {
        $ProgramOutput = New-CMProgram -PackageName "$AppNameFull" -StandardProgramName "Install $app Silent" -CommandLine "Deploy-Application.exe" -RunType Hidden -RunMode RunWithAdministrativeRights -ProgramRunType WhetherOrNotUserIsLoggedOn -Duration $Duration -UserInteraction $false
        Write-Output "Program made 'Install $app Silent'"
    }
    catch [exception]{
        Write-Output "$_"
        break
    }

    try {
        if ($MaintainedApp.AWSDistributionApp){
            Start-CMContentDistribution -PackageName "$AppNameFull" -DistributionPointGroupName "All Distribution Points"
            Start-CMContentDistribution -PackageName "$AppNameFull" -DistributionPointGroupName "AWS"
            Write-Output "Package Distribution to all DP and AWS started"
        }
        else {
            Start-CMContentDistribution -PackageName "$AppNameFull" -DistributionPointGroupName "All Distribution Points"
            Write-Output "Package Distribution to all DP started"
        }
    }
    catch [exception]{
        Write-Output "$_"
        break
    }

    try {
        Move-CMObject -FolderPath "$SCCMFolderPath" -InputObject $Application
        Write-Output "Moved $AppNameFull to $SCCMFolderPath"
    }
    catch [exception]{
        Write-Output "$_"
        break
    }

    try {
        Deploy-ToSCCMCollection -PackageName $AppNameFull -Collection "$TestCollection"
        Write-Output "Deployed $AppNameFull to $TestCollection"
    }
    catch [exception]{
        Write-Output "$_"
        break
    }
}