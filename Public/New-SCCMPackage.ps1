function New-SCCMPackage {
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

New-SCCMPackage -App Firefox
#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
            HelpMessage = 'What standard app are you trying to get the version of?')]
        [string]
        [ValidateSet('7zip', 'BigFix', 'Chrome', 'CutePDF', 'Etcher', 'Firefox', 'Flash', 'GIMP', 'Git', 'Insync', 'Notepad++', 'OpenJDK', 'Putty', 'Reader', 'Receiver', 'SoapUI', 'VLC', 'VSCode', 'WinSCP', 'WireShark', IgnoreCase = $true)]
        $App
    )

    begin {
        $App = $App.ToLower()
    }

    process {
        Push-Location $PWD -StackName ModuleStack
        Import-ConfigManagerModule

        Mount-PackageShare

        $MaintainedApp = $MaintainedApps | Where-Object { $_.Name -eq $App }
        New-PackageHelper -AppName "$($MaintainedApp.DisplayName)" -rootApplicationPath "$($MaintainedApp.RootApplicationPath)" `
        -SCCMFolder "$($MaintainedApp.SCCMPackageFolder.QA)" -Manufacturer "$($MaintainedApp.Manufacturer)" -DistributionPointGroupName "$($MaintainedApp.SCCMDistributionGroup)"

        Pop-Location -StackName ModuleStack
    }

}