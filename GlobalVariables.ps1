<# GlobalVarilbes




#>

$SCCM_Site = "HMN"
$SCCM_Share = "\\spivsccm01\Packages"
$SCCM_Share_Letter = "P"

function Get-RootApplicationPath {
    <#
        .SYNOPSIS
        Gets the $rootApplicationPath for a give app
	
        .DESCRIPTION
        Gets the $rootApplicationPath for a give app

        .PARAMETER App
        Defaults to Deploy-Applicaiton.ps1

        .Examples

        .Remarks

    #>
    param
    (
        [Parameter(Mandatory = $true,
        HelpMessage = 'What standard app are you trying to get the root folder of?')]
        [string]
        [ValidateSet('7zip','BigFix','Chrome','Firefox','Flash','GIMP','insync','Java','Notepad++','Putty','Reader','Receiver','VLC','WinSCP', IgnoreCase = $true)]
        $App
    )
    switch ($App) {
        '7zip' {
            $rootApplicationPath = "$SCCM_Share\HOME OFFICE\7Zip"
        }
        'bigfix' {
            $rootApplicationPath = "$SCCM_Share\CoreApps_ALL\BixFixClient"
        }
        'chrome' {
            $rootApplicationPath = "$SCCM_Share\CoreApps_ALL\GoogleChrome"
        }
        'firefox' {
            $rootApplicationPath = "$SCCM_Share\HOME OFFICE\Mozilla FireFox"
        }
        'flash' {
            $rootApplicationPath = "$SCCM_Share\CoreApps_ALL\Adobe\AdobeFlash"
        }
        'gimp'{
            $rootApplicationPath = "$SCCM_Share\HOME OFFICE\GIMP"
        }
        'java' {
            $rootApplicationPath = "$SCCM_Share\CoreApps_ALL\java"
        }
        'notepad++' {
            $rootApplicationPath = "$SCCM_Share\HOME OFFICE\Notepad++"
        }
        'putty' {
            $rootApplicationPath = "$SCCM_Share\HOME OFFICE\Putty"
        }
        'reader' {
            $rootApplicationPath = "$SCCM_Share\CoreApps_ALL\Adobe\AdobeReader"
        }
        'receiver' {
            $rootApplicationPath = "$SCCM_Share\HOME OFFICE\Citrix Receiver"
        }
        'vlc' {
            $rootApplicationPath = "$SCCM_Share\HOME OFFICE\VLC"
        }
        'wincp' {
            $rootApplicationPath = "$SCCM_Share\HOME OFFICE\WinSCP"
        }
    }
    return $rootApplicationPath
}

function Get-CurrentAppVersion {
    param
    (
        [Parameter(Mandatory = $true,
        HelpMessage = 'What standard app are you trying to get the version of?')]
        [string]
        [ValidateSet('7zip','BigFix','Chrome','Firefox','Flash','GIMP','insync','Java','Notepad++','Putty','Reader','Receiver','VLC','WinSCP', IgnoreCase = $true)]
        $App
    )

    $rootApplicationPath = Get-RootApplicationPath -App $App
    # Get-ChildItem has trouble working with UNC paths from the $SCCM_Site: drive. That is why I map a $SCCM_Share_Letter drive
    $count = (Measure-Object -InputObject $SCCM_Share -Character).Characters + 1
    # Gets the most recent folder for a given app
    $LatestApplicationPath =  "$($SCCM_Share_Letter):\" + $rootApplicationPath.Substring($count) | Get-ChildItem | sort CreationTime -desc | select -f 1 
    $CurrentAppVersion = Get-PSADTAppVersion -PackageRootFolder "$($LatestApplicationPath.Fullname)"
    return [version]$CurrentAppVersion
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

        .Examples

        .Remarks

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