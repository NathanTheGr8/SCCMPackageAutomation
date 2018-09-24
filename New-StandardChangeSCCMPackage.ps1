. .\GlobalVariables.ps1

function New-StandardChangeSCCMPackage
{
  <#
      .SYNOPSIS
      Creates a new SCCM package for one of the standard change apps.
	
      .DESCRIPTION
      requires \\SCCMServer\pacakgesShare mounted as p Drive
	
      .PARAMETER App
      Valid options are
      Firefox
      Chrome
      Flash
      Java
      Reader
      Bigfix
      Druva
      Notepad++
      7zip
      putty
      WinSCP
      Reciever

      .EXAMPLE 1
      New-StandardChangeSCCMPackage -APP Firefox

      .Remarks
      http://www.dexterposh.com/2015/08/powershell-sccm-2012-create-packages.html
      

  #>
  [CmdletBinding(ConfirmImpact = 'None')]
  param
  (
    [Parameter(Mandatory = $true,
           HelpMessage = 'What standard app are you packaging?')]
    [string]
        [ValidateSet('7zip','BigFix','Chrome','Firefox','Flash','GIMP','insync','Java','Notepad++','Putty','Reader','Receiver','VLC','WinSCP', IgnoreCase = $true)]
    $App
  )

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
        $rootApplicationPath = Get-RootApplicationPath -App $App

        Update-AppHelper -AppName "7zip" -rootApplicationPath $rootApplicationPath -SCCMFolder HomeOffice -Manufacturer "Igor Pavlov"
    }
   
    # Package Bigfix
    if ($App.ToLower() -eq 'bigfix') {
        $rootApplicationPath = Get-RootApplicationPath -App $App

        Update-AppHelper -AppName "BigFix Client" -rootApplicationPath $rootApplicationPath -SCCMFolder CoreApps -Manufacturer "IBM"
    }


    # Package Google Chrome 
    if ($App.ToLower() -eq 'chrome') {
        $rootApplicationPath = Get-RootApplicationPath -App $App

        Update-AppHelper -AppName "Chrome" -rootApplicationPath $rootApplicationPath -SCCMFolder CoreApps -Manufacturer "Google"
    }
    
    #Package Firefox
    if ($App.ToLower() -eq 'firefox') {
        $rootApplicationPath = Get-RootApplicationPath -App $App

        Update-AppHelper -AppName "Firefox" -rootApplicationPath $rootApplicationPath -SCCMFolder HomeOffice -Manufacturer "Mozilla"
    }

    # Package Adobe Flash
    if ($App.ToLower() -eq 'flash') {
        $rootApplicationPath = Get-RootApplicationPath -App $App

        Update-AppHelper -AppName "Flash" -rootApplicationPath $rootApplicationPath -SCCMFolder CoreApps -Manufacturer "Adobe"
    }

    # Package GIMP
    if ($App.ToLower() -eq 'gimp') {
        $rootApplicationPath = Get-RootApplicationPath -App $App

        Update-AppHelper -AppName "GIMP" -rootApplicationPath $rootApplicationPath -SCCMFolder HomeOffice -Manufacturer "GIMP Development Team"
    }

    # Package Druva InSync
    if ($App.ToLower() -eq 'insync') {
        $rootApplicationPath = Get-RootApplicationPath -App $App

        Update-AppHelper -AppName "InSync" -rootApplicationPath $rootApplicationPath -SCCMFolder CoreApps -Manufacturer "Druva"
    }

    # Package Java
    if ($App.ToLower() -eq 'java') {
        $rootApplicationPath = Get-RootApplicationPath -App $App
        
        Update-AppHelper -AppName "Java" -rootApplicationPath $rootApplicationPath -SCCMFolder CoreApps -Manufacturer "Oracle"
    }

    # Package Notepad++
    if ($App.ToLower() -eq 'notepad++') {
        $rootApplicationPath = Get-RootApplicationPath -App $App

        Update-AppHelper -AppName "Notepad++" -rootApplicationPath $rootApplicationPath -SCCMFolder HomeOffice -Manufacturer "Notepad++ Team"
    }

    # Package putty
    if ($App.ToLower() -eq 'putty') {
        $rootApplicationPath = Get-RootApplicationPath -App $App

        Update-AppHelper -AppName "Putty" -rootApplicationPath $rootApplicationPath -SCCMFolder HomeOffice -Manufacturer "Simon Tatham"
    }

    # Package Adobe Reader
    if ($App.ToLower() -eq 'reader') {
        $rootApplicationPath = Get-RootApplicationPath -App $App

        Update-AppHelper -AppName "Reader" -rootApplicationPath $rootApplicationPath -SCCMFolder CoreApps -Manufacturer "Adobe"
    }

    # Package Citrix Receiver
    if ($App.ToLower() -eq 'receiver') {
        $rootApplicationPath = Get-RootApplicationPath -App $App
        
        Update-AppHelper -AppName "Receiver" -rootApplicationPath $rootApplicationPath -SCCMFolder HomeOffice -Manufacturer "Citrix"
    
    }

    # Package vlc
    if ($App.ToLower() -eq 'vlc') {
        $rootApplicationPath = Get-RootApplicationPath -App $App

        Update-AppHelper -AppName "VLC" -rootApplicationPath $rootApplicationPath -SCCMFolder HomeOffice -Manufacturer "VideoLAN"
    }

    # Package winscp
    if ($App.ToLower() -eq 'winscp') {
        $rootApplicationPath = Get-RootApplicationPath -App $App

        Update-AppHelper -AppName "WinSCP" -rootApplicationPath $rootApplicationPath -SCCMFolder HomeOffice -Manufacturer "Martin Přikryl"
    }

    Set-Location "c:" #change location back to c drive. Otherwise other functions break

}

#doesn't work. cmdlet broken on our sccm version
function Deploy-ToSCCMCollection {
        param
        (
            [Parameter(Mandatory = $false)]
            [string]
            $Collection = "DELL Desktop",
            [Parameter(Mandatory = $true)]
            [string]
            $PackageName
        )
        Write-Output "Deploying $PackageName to $Collection"
        $CMDeplColl = Get-CMCollection -Name $Collection -CollectionType Device
        try{
            #'Start-CMApplicationDeployment' has been deprecated in 1702 and may be removed in a future release.
            #The cmdlet 'New-CMApplicationDeployment' may be used as a replacement.
            Start-CMApplicationDeployment -Collection $CMDeplColl.Name -Name $PackageName -DeployAction Install -DeployPurpose Required 
            Write-Host "Deployment Succeded" -ForegroundColor Green | Out-Null
        }
        catch
        {
            Write-Host "Failed" -ForegroundColor Red
            Write-Host "$_"
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
        $AppPath =  "$($SCCM_Share_Letter):\" + $rootApplicationPath.Substring($count) | Get-ChildItem | sort CreationTime -desc | select -f 1 
        # Each app folder is named like 'AppName Version (R#). So this line just selects Version R#
        $AppVersion = $AppPath.Name -split ' ' | select -Last 2
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
            $Application = New-CMPackage –Name “$AppNameFull" –Path "$appPath" -Manufacturer "$Manufacturer" -Language "$Language"
            Write-Output "$AppNameFull created in SCCM"
        }
        catch [exception]{
            Write-Output "$_"
        }

        try {
            $ProgramOutput = New-CMProgram -PackageName "$AppNameFull" -StandardProgramName "Install $app Silent" -CommandLine "Deploy-Application.exe" -RunType Hidden -RunMode RunWithAdministrativeRights -ProgramRunType WhetherOrNotUserIsLoggedOn -Duration $Duration -UserInteraction $false
            Write-Output "Program made 'Install $app Silent'"
        }
        catch [exception]{
            Write-Output "$_"
        }
        
        try {
            Start-CMContentDistribution -PackageName “$AppNameFull” -DistributionPointGroupName "All Distribution Points"
            Write-Output "Package Distribution to all DP started"
        }
        catch [exception]{
            Write-Output "$_"
        }

        try {
            Move-CMObject -FolderPath "$SCCMFolderPath" -InputObject $Application
            Write-Output "Moved $AppNameFull to $SCCMFolderPath"
        }
        catch [exception]{
            Write-Output "$_"
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
        $WMIQuerries = Get-CMDeviceCollectionQueryMembershipRule -CollectionName "Not Current Version $app"
        If ($WMIQuerries){ #If there are any
            foreach ($Query in $WMIQuerries){
                #includes everything from the old query up to the < char. Adds two to include the char and a space
                $newQuery = $Query.QueryExpression.Substring(0,$Query.QueryExpression.LastIndexOf("<")+2) 
                [string]$CurrentAppVersion = Get-CurrentAppVersion -App $App
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