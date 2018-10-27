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
        [ValidateSet('Major','Minor','Build', 'None')]
		$Increment = 'None'
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

        # Get the files and ignore .git directory
        $files = Get-ChildItem -Path $path -Exclude ".git"


        Write-Output "Pushing new version to $($global:computers.count) computers"
        Foreach ($comp in $global:Computers.Values){
            $comp
            if(Test-Connection -ComputerName $comp -Quiet -Count 1){
                $Dest = "\\$comp\C$\Windows\System32\WindowsPowerShell\v1.0\Modules"
                $StopWatch = [system.diagnostics.stopwatch]::StartNew()
                if (Test-Path -Path $Dest\$ModuleName){
                    Remove-Item -Path $Dest\$ModuleName -Recurse -Force
                }
                Copy-Item -Path $files -Destination $Dest\$ModuleName -Force -Recurse
                Write-Output "Pushed to $comp in $($StopWatch.Elapsed.TotalSeconds) Seconds"
            }
            else {
                Write-Error -Message "$comp is not connected to the network? Didn't push code to $comp"
            }

        }
    }
    else {
        Write-Error -Message "$path does not exist, please specify a -path flag"
    }
}