#Edit this file to suit your enviorment. Change the name to GlobalVaribles.ps1

$global:SCCM_Site = "LAB"
$global:SCCM_Share = "\\SCCMPS1\SoftwareShare\Applications"
$global:SCCM_Share_Test_Folder = "SomeFolderThatExists"
$global:SCCM_Share_Letter = "P"
$global:IconsFolder = "$PSScriptRoot\bin\icons"
$global:SCCM_ALL_DP_Group = "All Distribution Points"
$global:SCCM_SourceFolderRegex = "[a-zA-Z0-9_.+-]+ [a-zA-Z0-9_.]+ \(R[0-9]\)"

$VersionRegex = "\d+(\.\d+)+"

$MaintainedApps = (Get-Content "$PSScriptRoot\GlobalVaribles.json" | ConvertFrom-Json).MaintainedApps | Sort-Object -Property Name
foreach ($app in $MaintainedApps) {
    $app.RootApplicationPath = $SCCM_Share + "\" + $app.RootApplicationPath
}
$SCCMFolders = (Get-Content "$PSScriptRoot\GlobalVaribles.json" | ConvertFrom-Json).SCCMFolders
$SCCMAppFolders = (Get-Content "$PSScriptRoot\GlobalVaribles.json" | ConvertFrom-Json).SCCMAppFolders

# For Get-OutDatedApps Scheduled Task.
$Recipients = "Name@domain.com"
$EmailSender = "Name@domain.com"
$SMTPServer = "authappmail.domain.local"

# Newely Packaged Applications and Packages will auto deploy to this collection
$TestCollection = "Test Collection"

# For Pub-AppToProduction
$NumberOfPackagesToKeep = 3 #1 current and 2 previous

# Internal Powershell Repo
# https://kevinmarquette.github.io/2017-05-30-Powershell-your-first-PSScript-repository/
$InternalModuleRepo = "lab-modules"