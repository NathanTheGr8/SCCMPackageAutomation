#Edit this file to suit your enviorment. Change the name to GlobalVaribles.ps1

$global:SCCM_Site = "AAA"
$global:SCCM_Share = "\\server\Packages"
$global:SCCM_Share_Test_Folder = "FolderName"
$global:SCCM_Share_Letter = "P"

$VersionRegex = "\d+(\.\d+)+"

$MaintainedApps = (Get-Content "$PSScriptRoot\GlobalVaribles.json" | ConvertFrom-Json).MaintainedApps | Sort-Object -Property Name
foreach ($app in $MaintainedApps) {
    $app.RootApplicationPath = $SCCM_Share + "\" + $app.RootApplicationPath
}
$SCCMFolders = (Get-Content "$PSScriptRoot\GlobalVaribles.json" | ConvertFrom-Json).SCCMFolders
$SCCMAppFolders = (Get-Content "$PSScriptRoot\GlobalVaribles.json" | ConvertFrom-Json).SCCMAppFolders

# For Get-OutDatedApps Scheduled Task.
$Recipients = ""
$EmailSender = ""
$SMTPServer = "authappmail.domain.local"

# For Deploy-ToSCCMCollection
$global:TestCollection = "Dell Desktop*"

# Internal Powershell Repo
# https://kevinmarquette.github.io/2017-05-30-Powershell-your-first-PSScript-repository/
$InternalModuleRepo = "moduleRepo"
