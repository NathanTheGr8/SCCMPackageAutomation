#Edit this file to suit your enviorment. Change the name to GlobalVaribles.ps1

$global:SCCM_Site = "AAA"
$global:SCCM_Share = "\\server\Packages"
$global:SCCM_Share_Test_Folder = "FolderName"
$global:SCCM_Share_Letter = "P"

$VersionRegex = "\d+(\.\d+)+"

$GlobalApps = @{}
Import-Csv -Path "$PSScriptRoot\GlobalVaribles.csv" | ForEach-Object {
    $GlobalAppTable = @{}
    $temp = "$SCCM_Share\"+$_.RootApplicationPath

    $GlobalAppTable.Add('Name',$_.Name)
    $GlobalAppTable.Add('RootApplicationPath', $temp)
    $GlobalAppTable.Add('ProductionAppCollection',$_.ProductionAppCollection)
    $GlobalAppTable.Add('SCCMFolder',$_.SCCMFolder)
    $GlobalAppTable.Add('Manufacturer',$_.Manufacturer)
    $GlobalAppTable.Add('BlackList',$_.BlackList)
    $GlobalAppTable.Add('AWSDistributionApp',$_.AWSDistributionApp)


    $GlobalApps.Add($_.Name,$GlobalAppTable)
}

# For Get-OutDatedApps Scheduled Task.
$Recipients = "Nathan.Davis@horacemann.com"
$EmailSender = "Nathan.Davis@horacemann.com"
$SMTPServer = "authappmail.hmcorp.local"

# For Deploy-ToSCCMCollection
$global:TestCollection = "Dell Desktop*"

# Internal Powershell Repo
# https://kevinmarquette.github.io/2017-05-30-Powershell-your-first-PSScript-repository/
$InternalModuleRepo = "hm-modules"
