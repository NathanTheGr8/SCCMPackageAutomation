function New-PackageHelper {
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
        [ValidateSet('HomeOffice', 'CoreApps', 'Misc', IgnoreCase = $true)]
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
    $AppPath = "$($SCCM_Share_Letter):\" + $rootApplicationPath.Substring($count) | Get-ChildItem | Sort-Object -Property CreationTime -Descending | Select-Object -First 1
    # Each app folder is named like 'AppName Version (R#). So this line just selects Version R#
    $AppVersion = $AppPath.Name -split ' ' | Select-Object -Last 2
    # Transform the app path back to a full unc path withouth a drive letter
    $AppPath = "$SCCM_Share" + ($AppPath.FullName).Substring(2)
    $AppNameFull = "$AppName $appVersion"

    $alreadyExists = Get-CMPackage -Name $AppNameFull
    while ($alreadyExists) {
        #if the package name already exists increments R#
        Write-Output "$AppNameFull already exists in SCCM, auto incrementing the R`#"
        #This line is overly complex, but it works. I couldn't think of a better way to write it.
        $AppNameFull = $AppNameFull.Substring(0, $AppNameFull.Length - 2) + ([int]$AppNameFull.Substring($AppNameFull.Length - 2, 1) + 1) + ")"
        $alreadyExists = Get-CMPackage -Name $AppNameFull
    }

    try {
        $Application = New-CMPackage -Name "$AppNameFull" -Path "$appPath" -Manufacturer "$Manufacturer" -Language "$Language"
        Write-Output "$AppNameFull created in SCCM"
    }
    catch [exception] {
        Write-Output "$_"
        break
    }

    try {
        $ProgramOutput = New-CMProgram -PackageName "$AppNameFull" -StandardProgramName "Install $app Silent" -CommandLine "Deploy-Application.exe" -RunType Hidden -RunMode RunWithAdministrativeRights -ProgramRunType WhetherOrNotUserIsLoggedOn -Duration $Duration -UserInteraction $false
        Write-Output "Program made 'Install $app Silent'"
    }
    catch [exception] {
        Write-Output "$_"
        break
    }

    try {
        if ($MaintainedApp.AWSDistributionApp) {
            Start-CMContentDistribution -PackageName "$AppNameFull" -DistributionPointGroupName "All Distribution Points"
            Start-CMContentDistribution -PackageName "$AppNameFull" -DistributionPointGroupName "AWS"
            Write-Output "Package Distribution to all DP and AWS started"
        }
        else {
            Start-CMContentDistribution -PackageName "$AppNameFull" -DistributionPointGroupName "All Distribution Points"
            Write-Output "Package Distribution to all DP started"
        }
    }
    catch [exception] {
        Write-Output "$_"
        break
    }

    try {
        Move-CMObject -FolderPath "$SCCMFolderPath" -InputObject $Application
        Write-Output "Moved $AppNameFull to $SCCMFolderPath"
    }
    catch [exception] {
        Write-Output "$_"
        break
    }

    try {
        Deploy-PackageToSCCMCollection -PackageName $AppNameFull -Collection "$TestCollection"
        Write-Output "Deployed $AppNameFull to $TestCollection"
    }
    catch [exception] {
        Write-Output "$_"
        break
    }
}