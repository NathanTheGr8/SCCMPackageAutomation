function Get-LatestGithubVersion {
    <#
    .SYNOPSIS

    Gets the latest version of a from a github repo
    .DESCRIPTION

    .PARAMETER Org

    .PARAMETER Repo

    .PARAMETER Regex

    .EXAMPLE
    Get-LatestGithubVersion
    #>

    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        $Org,
        [Parameter(Mandatory = $true)]
        [string]
        $Repo
        # [Parameter(Mandatory = $true)]
        # [string]
        # $Regex

    )

    begin {
        $VersionRegex = "\d+(\.\d+)+"
    }

    process {
        #TLS
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12


        $url = "https://api.github.com/repos/$Org/$Repo/releases/latest"
        $json = Invoke-WebRequest -UseBasicParsing -Uri "$url" | ConvertFrom-Json
        $output = $json.tag_name -match $VersionRegex
        $LatestAppVersion = $matches[0]

        Return $LatestAppVersion

    }

}
#Get-LatestGithubVersion -Org "balena-io" -Repo "etcher"
#Get-LatestGithubVersion -Org "microsoft" -Repo "vscode"