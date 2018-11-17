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
        [ValidateSet('7zip','BigFix','Chrome','CutePDF','Firefox','Flash','GIMP','Git','insync','Java','Notepad++','Putty','Reader','Receiver','VLC','VSCode','WinSCP','WireShark', IgnoreCase = $true)]
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

        # Package 7zip
        if ($App.ToLower() -eq '7zip') {
            Update-AppHelper -AppName "7zip" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder HomeOffice -Manufacturer "Igor Pavlov"
        }

        # Package Bigfix
        if ($App.ToLower() -eq 'bigfix') {
            Update-AppHelper -AppName "BigFix Client" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder CoreApps -Manufacturer "IBM"
        }


        # Package Google Chrome
        if ($App.ToLower() -eq 'chrome') {
            Update-AppHelper -AppName "Chrome" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder CoreApps -Manufacturer "Google"
        }

        #Package Firefox
        if ($App.ToLower() -eq 'firefox') {
            Update-AppHelper -AppName "Firefox" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder HomeOffice -Manufacturer "Mozilla"
        }

        # Package Adobe Flash
        if ($App.ToLower() -eq 'flash') {
            Update-AppHelper -AppName "Flash" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder CoreApps -Manufacturer "Adobe"
        }

        # Package GIMP
        if ($App.ToLower() -eq 'gimp') {
            Update-AppHelper -AppName "GIMP" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder HomeOffice -Manufacturer "GIMP Development Team"
        }

        # Package GIMP
        if ($App.ToLower() -eq 'git') {
            Update-AppHelper -AppName "Git" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder HomeOffice -Manufacturer "Software Freedom Conservancy"
        }

        # Package Druva InSync
        if ($App.ToLower() -eq 'insync') {
            Update-AppHelper -AppName "InSync" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder CoreApps -Manufacturer "Druva"
        }

        # Package Java
        if ($App.ToLower() -eq 'java') {
            Update-AppHelper -AppName "Java" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder CoreApps -Manufacturer "Oracle"
        }

        # Package Notepad++
        if ($App.ToLower() -eq 'notepad++') {
            Update-AppHelper -AppName "Notepad++" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder HomeOffice -Manufacturer "Notepad++ Team"
        }

        # Package putty
        if ($App.ToLower() -eq 'putty') {
            Update-AppHelper -AppName "Putty" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder HomeOffice -Manufacturer "Simon Tatham"
        }

        # Package Adobe Reader
        if ($App.ToLower() -eq 'reader') {
            Update-AppHelper -AppName "Reader" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder CoreApps -Manufacturer "Adobe"
        }

        # Package Citrix Receiver
        if ($App.ToLower() -eq 'receiver') {
            Update-AppHelper -AppName "Receiver" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder HomeOffice -Manufacturer "Citrix"
        }

        # Package vlc
        if ($App.ToLower() -eq 'vlc') {
            Update-AppHelper -AppName "VLC" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder HomeOffice -Manufacturer "VideoLAN"
        }

        # Package vlc
        if ($App.ToLower() -eq 'vscode') {
            Update-AppHelper -AppName "VSCode" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder HomeOffice -Manufacturer "Microsoft"
        }

        # Package winscp
        if ($App.ToLower() -eq 'winscp') {
            Update-AppHelper -AppName "WinSCP" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder HomeOffice -Manufacturer "Martin Prikryl"
        }

        # Package wireshark
        if ($App.ToLower() -eq 'wireshark') {
            Update-AppHelper -AppName "WireShark" -rootApplicationPath $global:RootApplicationPath[$app] -SCCMFolder HomeOffice -Manufacturer "The WireShark Team"
        }

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
                $SCCMFolderPath = "$($SCCM_Site):\Package\Home Office\QA_Home Office"
            }
            "CoreApps" {
                $SCCMFolderPath = "$($SCCM_Site):\Package\Core_Apps_ALL\ALL_QA Core Packages"
            }
            "Misc" {
                $SCCMFolderPath = "$($SCCM_Site):\Package\MISC\QA MISC"
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
            Start-CMContentDistribution -PackageName "$AppNameFull" -DistributionPointGroupName "All Distribution Points"
            Write-Output "Package Distribution to all DP started"
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

        Write-Output "Updating 'Not Current Version $app' Collection to new version"


        # Fetch the current querries for a given collection and loop through them
        <#
        An example of what one of my Not Current Version Collections looks like.

        QueryExpression       : select SMS_R_SYSTEM.ResourceID,SMS_R_SYSTEM.ResourceType,SMS_R_SYSTEM.Nam
                                e,SMS_R_SYSTEM.SMSUniqueIdentifier,SMS_R_SYSTEM.ResourceDomainORWorkgroup
                                ,SMS_R_SYSTEM.Client from SMS_R_System inner join
                                SMS_G_System_ADD_REMOVE_PROGRAMS on
                                SMS_G_System_ADD_REMOVE_PROGRAMS.ResourceID = SMS_R_System.ResourceId
                                where SMS_G_System_ADD_REMOVE_PROGRAMS.DisplayName like "Adobe Flash
                                Player%" and SMS_G_System_ADD_REMOVE_PROGRAMS.Version < "31.0.0.108"
        QueryID               : 1
        RuleName              : old flash


        #>
        # If I don't import the module again it errors out with he term 'Get-CMCollectionMembershipRule' is not recognized as the name of a cmdlet
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" # Import the ConfigurationManager.psd1 module
        Set-Location "$($SCCM_Site):" # Set the current location to be the site code.
        try {
            $WMIQuerries = Get-CMDeviceCollectionQueryMembershipRule -CollectionName "Not Current Version $app"
        }
        catch {
            Write-Output "Error, try importing the SCCM Module manuelly."
            Write-Output "$_"
            break
        }
        If ($WMIQuerries){ #If there are any
            foreach ($Query in $WMIQuerries){
                #includes everything from the old query up to the < char. Adds two to include the char and a space
                $newQuery = $Query.QueryExpression.Substring(0,$Query.QueryExpression.LastIndexOf("<")+2)
                $CurrentAppVersion = Get-CurrentAppVersion -App $app
                #The back tic escapes the quote character
                $newQuery = $newQuery + "`"$($CurrentAppVersion)`""

                #Delete the Old Rule
                Write-Host "Removing old query $($Query.RuleName)"
                Remove-CMDeviceCollectionQueryMembershipRule -CollectionName "Not Current Version $app" -RuleName "$($Query.RuleName)"

                #Add New Query
                Write-Host "Adding new query"
                Add-CMDeviceCollectionQueryMembershipRule -CollectionName "Not Current Version $app" -QueryExpression "$newQuery" -RuleName "$($Query.RuleName)"
            }
            Write-Output "Updated membership rules for 'Not Current Version $app' Collection"
        }
        else {
            Write-Output "'Not Current Version $app' Collection didn't exist"
        }
}