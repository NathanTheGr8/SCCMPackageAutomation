function Remove-DeploymentsFromTestCollection {
    <#
    .SYNOPSIS
    Removes all SCCM Deployments from the Test Collection
    .DESCRIPTION
    Removes all SCCM Deployments from the Test Collection. The Test Collection is given in the GobalVaribles file.
    .EXAMPLE
    Remove-DeploymentsFromTestCollection
    #>

    Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" # Import the ConfigurationManager.psd1 module
    Set-Location "$($global:SCCM_Site):" # Set the current location to be the site code.

    Get-CMDeployment -CollectionName "$TestCollection" | Remove-CMDeployment -Force

    Set-Location "C:"
}