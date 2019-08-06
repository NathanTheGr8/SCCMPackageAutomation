function Get-LatestAppVersion {
<#
.SYNOPSIS

Gets the latest version of a given app.
.DESCRIPTION

Gets the latest version of an app by scraping a website. It gets the latest version by ether
checking a web api for latest version (chrome and firefox have this)
gets the latest version from a give ftp directory (vlc and others)
scrapes a web page with download links for the latest version (most apps require this)
.PARAMETER App

The app you want the latest version of. Dynamic tab completion from GlobalVariables Apps list.
.PARAMETER AsString
Returns the version # as a string. Useful for apps that a have leading zeros in version number.
.EXAMPLE
Get-LatestAppVersion -App Firefox
#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
        HelpMessage = 'What standard app are you trying to get the version of?')]
        [string]
        [ValidateSet('7zip','BigFix','Chrome','CutePDF','Etcher','Firefox','Flash','GIMP','Git','Insync','Notepad++','OpenJDK','Putty','Reader','Slack','Receiver','SoapUI','VLC','VSCode','WinSCP','WireShark', IgnoreCase = $true)]
        $App,
        [switch]
        $AsString
    )

    begin {
        #$App = $PSBoundParameters['App']
        $App = $App.toLower()
    }

    process {
        #TLS
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        switch ($App) {
            '7zip' {
                # https://www.reddit.com/r/PowerShell/comments/9gwbed/scrape_7zip_website_for_the_latest_version/
                $Domain = "https://www.7-zip.org/download.html"
                $temp   = (Invoke-WebRequest -UseBasicParsing -uri $Domain)
                $regex  = $temp.Content -match 'Download 7-Zip (.*)\s(.*) for Windows'

                if ($regex) {
                    $LatestAppVersion  = $Matches[1]
                }
                else {
                    throw "Error could not scrape 7-zip.org for version"
                }

            }
            'bigfix' {
                $url = "http://support.bigfix.com/bes/release/"
                $html = Invoke-WebRequest -UseBasicParsing -Uri "$url"
                $versionLinks = $html.Links | Where-Object href -Match "$VersionRegex\/patch\d+"
                #todo get "| Sort-Object -Descending" to work
                $latestURL = $url + $versionLinks[0].href
                $html = Invoke-WebRequest -UseBasicParsing -Uri "$latestURL"
                $ClientDownload = $html.Links | Where-Object href -Match "Client.+\.exe"
                $LatestAppVersion = [regex]::match($ClientDownload.href,'\d+(\.\d+)+').Value
            }
            'chrome' {
                # https://stackoverflow.com/questions/35114642/get-latest-release-version-number-for-chrome-browser
                # https://omahaproxy.appspot.com/


                $LatestAppVersion = (Invoke-WebRequest -UseBasicParsing -Uri "https://omahaproxy.appspot.com/all.json" | ConvertFrom-Json)[0].versions[-1].version
            }
            'cutepdf' {
                    #Scrubbing the page for version is difficult. It also gives an incomplete version.
                    # http://www.cutepdf.com/products/cutepdf/writer.asp

                    $download = Download-LatestAppVersion -App $App
                    $LatestAppVersion = $download.VersionInfo.ProductVersion
            }
            'etcher' {
                $url = "https://github.com/balena-io/etcher/releases"
                $html = Invoke-WebRequest -UseBasicParsing -Uri "$url"
                $versionlinks = $html.Links | Where-Object href -match "$VersionRegex"
                $versionNumbers = @()
                foreach ($link in $versionlinks){
                    $versionNumbers += [regex]::match($link.href,"$VersionRegex").Value
                }
                $versionNumbers = $versionNumbers | Sort-Object -Descending
                $LatestAppVersion = $versionNumbers[0]
            }
            'firefox' {
                $LatestAppVersion = (Invoke-WebRequest -UseBasicParsing -Uri "https://product-details.mozilla.org/1.0/firefox_versions.json" | ConvertFrom-Json).LATEST_FIREFOX_VERSION
            }
            'flash' {
                # https://github.com/auberginehill/update-adobe-flash-player/blob/master/Update-AdobeFlashPlayer.ps1

                $url = "https://fpdownload.macromedia.com/pub/flashplayer/masterversion/masterversion.xml"
                $xml_versions = New-Object XML
                $xml_versions.Load($url)

                # The different flash types can have different version numbers. I need to loop through
                # all of them to get be sure
                [version]$xml_activex_win_current = ($xml_versions.version.release.ActiveX_win.version).replace(",",".")
                [version]$xml_plugin_win_current = ($xml_versions.version.release.NPAPI_win.version).replace(",",".")
                [version]$xml_ppapi_win_current = ($xml_versions.version.release.PPAPI_win.version).replace(",",".")

                $FlashVersions = $xml_activex_win_current,$xml_plugin_win_current,$xml_ppapi_win_current
                $FlashVersions = Sort-Object -InputObject $FlashVersions -Descending
                $LatestAppVersion = $FlashVersions[0]
            }
            'gimp'{
                $url = "https://download.gimp.org/mirror/pub/gimp/"
                $html = Invoke-WebRequest -UseBasicParsing -Uri "$url"

                $GIMP_Versions = $html.Links | Where-Object outerHTML -Match "v\d+\.\d+\.*\d*/"
                $GIMP_Versions = Sort-Object -InputObject $GIMP_Versions -Property outerHTML

                $Gimp_MinorVersionsUrl = $url + "$($GIMP_Versions[-1].href)" + "windows/"
                $html2 = Invoke-WebRequest -Uri $Gimp_MinorVersionsUrl
                $Gimp_MinorVersions = $html2.Links | Where-Object outerHTML -Match "gimp-\d+\.\d+\.*\d*-setup.+exe"
                $Gimp_MinorVersions = Sort-Object -InputObject $Gimp_MinorVersions -Property outerHTML
                #gimp-(\d+\.*){3}-setup(-\d+)*\.exe[^.]

                if(($Gimp_MinorVersions[-1].outerHTML -split "." | Select-Object -Last 1) -eq "torrent"){
                    $LatestAppVersion = $Gimp_MinorVersions[-2].outerHTML -split "-" | Select-Object -First 2 | Select-Object -Last 1
                }
                else {
                    $LatestAppVersion = $Gimp_MinorVersions[-1].outerHTML -split "-" | Select-Object -First 2 | Select-Object -Last 1
                }
            }
            'git'{ #todo  -UseBasicParsing
                    $url = "https://git-scm.com/download/win"
                    $html = Invoke-WebRequest -uri $url
                    $Versions = $html.Links | Where-Object outerHTML -Match "$VersionRegex"

                    $versionArray = @()
                    foreach ($Version in $Versions){
                        [version]$VersionNumber = [regex]::match($Version.outerHTML ,"$VersionRegex").Value
                        $versionArray += $VersionNumber
                    }

                    $versionArray = $versionArray | Sort-Object -Descending
                    $LatestAppVersion = $versionArray[0]
            }
            'insync' {
                $url = "https://downloads.druva.com/insync/client/cloud/"
                $html = Invoke-WebRequest -uri $url -UseBasicParsing
                $Versions = $html.Links | Where-Object href -Match "windows/$VersionRegex"
                $VersionNumber = $Versions.href -match "$VersionRegex"
                $LatestAppVersion = $Matches[0]
            }
            'notepad++' {
                $url = "https://notepad-plus-plus.org/download"
                $html = Invoke-WebRequest -uri $url
                $Versions = $html.Links | Where-Object outerHTML -Match "$VersionRegex"

                $versionArray = @()
                foreach ($Version in $Versions){
                    [version]$VersionNumber = [regex]::match($Version.outerHTML ,"$VersionRegex").Value
                    $versionArray += $VersionNumber
                }

                $versionArray = $versionArray | Sort-Object -Descending
                $LatestAppVersion = $versionArray[0]
            }
            'openjdk' {
                $url = "https://api.adoptopenjdk.net/v2/info/releases/openjdk8"
                $queries = @(
                    "?os=windows"
                    "&arch=x64"
                    "&openjdk_impl=hotspot"
                    "&type=jdk"
                    "&release=latest"
                )
                foreach ($query in $queries){
                    $url = $url + $query
                }

                $json = (Invoke-WebRequest -Uri "$url" -UseBasicParsing  | ConvertFrom-Json)
                $LatestAppVersion = $json[0].binaries[0].version_data.semver.Split("+") | Select-Object -First 1
            }
            'putty' {
                $url = "https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html"
                $html = Invoke-WebRequest -UseBasicParsing -Uri $url
                $Versions = $html.Links | Where-Object outerHTML -Match "$VersionRegex"

                $versionArray = @()
                foreach ($Version in $Versions){
                    [version]$VersionNumber = [regex]::match($Version.outerHTML ,"$VersionRegex").Value
                    $versionArray += $VersionNumber
                }

                $versionArray = $versionArray | Sort-Object -Descending
                $LatestAppVersion = $versionArray[0]
            }
            'reader' {
                $url = "https://helpx.adobe.com/acrobat/release-note/release-notes-acrobat-reader.html"
                $html = Invoke-WebRequest -UseBasicParsing -Uri "$url"

                $DC_Versions = $html.Links | Where-Object outerHTML -Match "\($VersionRegex\)"
                $versionArray = @()
                foreach ($version in $DC_Versions){
                    $VersionNumber = [regex]::match($Version.outerHTML ,"$VersionRegex").Value
                    $versionArray += $VersionNumber
                }

                $versionArray = $versionArray | Sort-Object -Descending
                $LatestAppVersion = $versionArray[0]
            }
            'receiver' {
                $url = "https://www.citrix.com/downloads/citrix-receiver/"
                $html = Invoke-WebRequest -UseBasicParsing -Uri "$url"
                $Versions = $html.Links | Where-Object outerHTML -Match "Receiver $VersionRegex.* for Windows"

                $versionArray = @()
                foreach ($Version in $Versions){
                    [version]$VersionNumber = [regex]::match($Version.outerHTML ,"$VersionRegex").Value
                    $versionArray += $VersionNumber
                }

                $versionArray = $versionArray | Sort-Object -Descending
                $LatestAppVersion = $versionArray[0]
            }
            'slack'{
                $url = "https://slack.com/release-notes/windows"
                $html = Invoke-WebRequest -UseBasicParsing -Uri "$url"
                $Versions = $html.Links | Where-Object outerHTML -Match "Slack $VersionRegex"

                $versionArray = @()
                foreach ($Version in $Versions){
                    [version]$VersionNumber = [regex]::match($Version.outerHTML ,"$VersionRegex").Value
                    $versionArray += $VersionNumber
                }

                $versionArray = $versionArray | Sort-Object -Descending
                $LatestAppVersion = $versionArray[0]
            }
            'soapui' {
                $url = "https://www.soapui.org/downloads/latest-release.html"
                $html = Invoke-WebRequest -UseBasicParsing -Uri "$url"
                $versionlinks = $html.Links | Where-Object -property href -match "$VersionRegex\/SoapUI-x64-$VersionRegex\.exe"
                $versionNumbers = @()
                foreach ($link in $versionlinks){
                    $versionNumbers += [regex]::match($link.href,"$VersionRegex").Value
                }
                $versionNumbers = $versionNumbers | Sort-Object -Descending
                $LatestAppVersion = $versionNumbers | Select-Object -first 1
            }
            'vlc' {
                $url = "http://download.videolan.org/pub/videolan/vlc/"
                $html = Invoke-WebRequest -UseBasicParsing -Uri "$url"

                $versionlinks = $html.Links | Where-Object href -match "^(\d+\.)?(\d+\.)?(\*|\d+)\/$" | Sort-Object -Property href -Descending
                $LatestAppVersion = $versionlinks[0].href -replace "/",""

            }
            'vscode' {
                $url = "https://github.com/Microsoft/vscode/releases"
                $html = Invoke-WebRequest -UseBasicParsing -Uri "$url"
                $versionlinks = $html.Links | Where-Object href -match "$VersionRegex"
                $versionNumbers = @()
                foreach ($link in $versionlinks){
                    $versionNumbers += [regex]::match($link.href,"$VersionRegex").Value
                }
                $versionNumbers = $versionNumbers | Sort-Object -Descending
                $LatestAppVersion = $versionNumbers[0]
            }
            'winscp' {
                $url = "https://winscp.net/eng/downloads.php"
                $html = Invoke-WebRequest -UseBasicParsing -Uri "$url"
                $versionlinks = $html.Links -match ".+download\/WinSCP-$VersionRegex-Setup\.exe" | Sort-Object -Descending
                $LatestAppVersion = [regex]::match($versionlinks[0].href,"$VersionRegex").Value
            }
            'wireshark' {
                $url = "https://www.wireshark.org/docs/relnotes/"
                $html = Invoke-WebRequest -UseBasicParsing -Uri "$url"

                $Versions = $html.Links | Where-Object -Property outerHTML -Match "$VersionRegex"

                $versionArray = @()
                foreach ($Version in $Versions){
                    $VersionNumber = [regex]::match($Version.outerHTML ,"$VersionRegex").Value
                    $versionArray += $VersionNumber
                }

                $versionArray = $versionArray | Sort-Object -Descending
                $LatestAppVersion = $versionArray[0]
            }
            'zoom' {
                
            }
        }

        if (($app -eq "reader") -or ($AsString) ){
            return $LatestAppVersion
        }
        else {
            return [version]$LatestAppVersion
        }
    }

}