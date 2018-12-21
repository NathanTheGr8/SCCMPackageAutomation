function Publish-SCCMPackageAutomation {
<#
.SYNOPSIS
    Pushes the Module to a list of computers in GlobalVaribles
.DESCRIPTION
    Copys the SCCMPackageAutomation source from the specified path to all computers on the list
.PARAMETER  Path
    The path of SCCMPackageAutomation soruce files, defaults to $Home\Documents\Projects\SCCMPackageAutomation
.PARAMETER  Increment
    Tells wheter to icnrement the major, minor, or build number. # =Major.minor.build
    Defaults to incremnt none
.EXAMPLE
    Publish-SCCMPackageAutomation -Path $PWD
.Example
    Publish-SCCMPackageAutomation -Increment None
#>
    [CmdletBinding()]
    param
	(
		[string]
		$Path = "$Home\Documents\Projects\SCCMPackageAutomation",
		[string]
        [ValidateSet('Major','Minor','Build','None')]
		$Increment = 'Build'
	)

    #test the path
    $ModuleName = "SCCMPackageAutomation"
    if (Test-Path -Path $Path) {

        #increment module version
        #https://github.com/RamblingCookieMonster/BuildHelpers/blob/master/BuildHelpers/Public/Step-ModuleVersion.ps1
        if(-not ($Increment -eq 'None')){Step-ModuleVersion -Path "$path\$ModuleName.psd1" -By $Increment}

        #print out new verstion
        $data = Import-PowerShellDataFile -Path "$path\$ModuleName.psd1"
        Write-Output -InputObject "New version = $($data.ModuleVersion)"

        #Publish Nuget Module
        Write-Output "Creating new nuget package"
        Publish-Module -Name "$Path" -Repository $InternalModuleRepo
    }
    else {
        Write-Error -Message "$path does not exist, please specify a -path flag"
    }
}