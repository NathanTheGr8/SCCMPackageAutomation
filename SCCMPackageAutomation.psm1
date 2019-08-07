<#
	===========================================================================
	 Created on:   	10/218/2018 12:44 PM
	 Created by:   	Nathan Davis
	 Organization:
	 Filename:     	SCCMPackageAutomation.psm1
	-------------------------------------------------------------------------
	 Module Name: SCCMPackageAutomation
	===========================================================================

    Exposed Functions go in Public Folder
#>

# Global varibles
try {
    . $PSScriptRoot\GlobalVariables.ps1
}
catch {
    Write-Error "You need to create GlobalVariables.ps1"
}

#Get public and private function definition files.
$Public = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )
$Private = @( Get-ChildItem -Path $PSScriptRoot\Private\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
Foreach ($import in @($Public + $Private)) {
    if ($import -like "*-*") {
        # only export functions that have - in their name
        Try {
            . $import.fullname
        }
        Catch {
            Write-Error -Message "Failed to import function $($import.fullname): $_"
        }
    }
}

# Here I might...
# Read in or create an initial config file and variable
# Export Public functions ($Public.BaseName) for WIP modules
# Set variables visible to the module and its functions only



#export public functions
Export-ModuleMember -Function $Public.Basename

#Export-ModuleMember -Variable