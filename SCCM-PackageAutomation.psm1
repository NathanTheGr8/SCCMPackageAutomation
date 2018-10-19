<#
	===========================================================================
	 Created on:   	10/218/2018 12:44 PM
	 Created by:   	Nathan Davis
	 Organization:
	 Filename:     	SCCM-PackageAutomation.psm1
	-------------------------------------------------------------------------
	 Module Name: SCCM-PackageAutomation
	===========================================================================

    Exposed Functions go in Public Folder
#>

#Get public and private function definition files.
    $Public  = @( Get-ChildItem -Path $PSScriptRoot\Public\*.ps1 -ErrorAction SilentlyContinue )

#Dot source the files
    Foreach($import in @($Public))
    {
        if ($import -like "*-*") { # only export functions that have - in their name
            Try
            {
                . $import.fullname
            }
            Catch
            {
                Write-Error -Message "Failed to import function $($import.fullname): $_"
            }
        }
    }

# Here I might...
# Read in or create an initial config file and variable
# Export Public functions ($Public.BaseName) for WIP modules
# Set variables visible to the module and its functions only

#Global varibles



#export functions
Export-ModuleMember -Function $Public.Basename

#Export-ModuleMember -Variable