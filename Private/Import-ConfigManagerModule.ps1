
<#
.SYNOPSIS

.DESCRIPTION

.EXAMPLE

Import-ConfigManagerModule
#>

function Import-ConfigManagerModule {

    # Customizations
    $initParams = @{ }
    #$initParams.Add("Verbose", $true) # Uncomment this line to enable verbose logging
    #$initParams.Add("ErrorAction", "Stop") # Uncomment this line to stop the script on any errors

    # Do not change anything below this line

    # Import the ConfigurationManager.psd1 module
    if ((Get-Module ConfigurationManager) -eq $null) {
        Import-Module "$($ENV:SMS_ADMIN_UI_PATH)\..\ConfigurationManager.psd1" @initParams
    }

    # Connect to the site's drive if it is not already present
    if ((Get-PSDrive -Name $SCCM_Site -PSProvider CMSite -ErrorAction SilentlyContinue) -eq $null) {
        New-PSDrive -Name $SCCM_Site -PSProvider CMSite -Root $SCCM_Server @initParams
    }

    # Set the current location to be the site code and save current location.
    Set-Location "$($SCCM_Site):\" @initParams
}