function New-SCCMApplication {
    <#
.SYNOPSIS

Creates a new SCCM application for one of the standard change apps.
.DESCRIPTION

Packages a given locaiton's install files in SCCM. It
Creates the new application
Makes an install program
Distrubutes the application to DPs
Moves the application to a given folder
.PARAMETER App

The app you are trying to application in SCCM. Valid options have tab completion.
.EXAMPLE

New-ChangeSCCMApplication -App Firefox
#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
            HelpMessage = 'What standard app are you trying to get the version of?')]
        [string]
        [ValidateSet('7zip', 'BigFix', 'Chrome', 'CutePDF', 'Etcher', 'Firefox', 'Flash', 'GIMP', 'Git', 'Insync', 'Java', 'Notepad++', 'OpenJDK', 'Putty', 'Reader', 'Receiver', 'SoapUI', 'VLC', 'VSCode', 'WinSCP', 'WireShark', IgnoreCase = $true)]
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
        New-ApplicationHelper -AppName "$($MaintainedApp.DisplayName)" -rootApplicationPath "$($MaintainedApp.RootApplicationPath)" `
        -SCCMFolderPath "$($MaintainedApp.SCCMApplicationFolder.QA)" -Publisher "$($MaintainedApp.Manufacturer)" -Icon "$IconsFolder\$($MaintainedApp.IconName)" `
        -DetectionMethod "$($MaintainedApp.DetectionMethod)"

        Pop-Location -StackName ModuleStack
    }

}