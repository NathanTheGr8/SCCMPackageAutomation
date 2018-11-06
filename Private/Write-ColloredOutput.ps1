function Write-ColoredOutput {
<#
.SYNOPSIS
Write-Ouput with color support!
.DESCRIPTION
Write-Ouput with color support!
.PARAMETER Color
The color you want the text to appear
.PARAMETER Args
The command you want to write out
.EXAMPLE
Write-ColoredOutput -Color red -Args ls
#>
    [CmdletBinding()]
    param(
        [Parameter(Mandatory = $true)]
        [System.ConsoleColor]
        $Color,
        [parameter(ValueFromPipeline)]
        $Args
    )
    # save the current color
    $CurrentForegroundColor = $host.UI.RawUI.ForegroundColor

    # set the new color
    $host.UI.RawUI.ForegroundColor = $Color

    # output
    if ($args) {
        Write-Output $args
    }
    else {
        $input | Write-Output
    }

    # restore the original color
    $host.UI.RawUI.ForegroundColor = $CurrentForegroundColor
}

# Write-ColoredOutput -Color Red -Args ls
# ls | Write-ColoredOutput -Color red