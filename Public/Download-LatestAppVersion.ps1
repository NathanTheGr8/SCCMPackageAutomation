function Download-LatestAppVersion {
<#
.SYNOPSIS

Downloads the latest app version of a current app and returns the install files path.
.DESCRIPTION

Downloads the latest version for a given app. Returns an array of any install file paths.
.PARAMETER App

The App you want the latest version of.
.EXAMPLE

Download-LatestAppVersion -App Chrome
#>
    [CmdletBinding()]
    param
    (
        [Parameter(Mandatory = $true,
        HelpMessage = 'What standard app are you trying to get the version of?')]
        [string]
        [ValidateSet('7zip','BigFix','Chrome','CutePDF','Etcher','Firefox','Flash','GIMP','Git','Insync','Notepad++','OpenJDK','Putty','Reader','Receiver','VLC','VSCode','WinSCP','WireShark', IgnoreCase = $true)]
        $App
    )

    begin {
        $App = $App.ToLower()
    }

    process {

        #Make Temp Download dir if it doesn't exist
        $DownloadDir = "$home\Downloads"
        if (!(Test-Path -Path "$DownloadDir\AppUpdates")) {
            Write-Host "$DownloadDir\AppUpdates didn't exist. Making Directory"
            New-Item -Path $DownloadDir -Name "AppUpdates" -ItemType Directory
        }
        $DownloadDir = "$home\Downloads\AppUpdates"

        # TLS
        [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

        #Write-Output "Downloading latest version of $app, this may take a few minutes"
        #That line is causing the  Copy-PSADTFolders to fail
        <#

        Copy-Item : Cannot find path 'C:\Users\davisn1\Documents\Projects\Downloading latest version of
        Firefox, this may take a few minutes' because it does not exist.
        At C:\Users\davisn1\Downloads\Update-AppPackage.ps1:173 char:5
        +     Copy-Item -Path $NewPSADTFiles -Destination "$NewPackageRootFolde ...
        +     ~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~~
            + CategoryInfo          : ObjectNotFound: (C:\Users\davisn...e a few minutes:String) [Copy-I
        tem], ItemNotFoundException
            + FullyQualifiedErrorId : PathNotFound,Microsoft.PowerShell.Commands.CopyItemCommand
        #>

        switch ($App) {
            '7zip' {
                $LatestAppVersion = Get-LatestAppVersion -App 7zip -AsString
                $LatestAppVersion = $LatestAppVersion.replace(".","")
                $Domain = "http://www.7-zip.org"
                $DownloadPage = "https://www.7-zip.org/download.html"
                $html = Invoke-WebRequest -Uri "$DownloadPage"

                #Get Relative Path URLS
                $TempURLS32 = $html.Links.href -match ".+7z$LatestAppVersion.msi"
                $TempURLS64 = $html.Links.href -match ".+7z$LatestAppVersion-x64.msi"

                #Build Download URL
                $32bitDownload = $Domain + "/" + $TempURLS32
                $64bitdownload = $Domain + "/" + $TempURLS64

                # Build install filename
                $InstallFileName = "7z$LatestAppVersion"
                #Download
                $ReturnCode1 = Invoke-WebRequest -Uri $32bitdownload -PassThru -OutFile "$DownloadDir\$($InstallFileName).msi"
                $ReturnCode2 = Invoke-WebRequest -Uri $64bitdownload -PassThru -OutFile "$DownloadDir\$($InstallFileName)-x64.msi"
            }
            'bigfix' {
                $url = "http://support.bigfix.com/bes/release/"
                $html = Invoke-WebRequest -Uri "$url"
                $versionLinks = $html.Links | Where-Object href -Match "\d+\.\d+\/patch\d+"
                $latestURL = $url + $versionLinks[0].href
                $html = Invoke-WebRequest -Uri "$latestURL"
                $ClientDownload = ($html.Links | Where-Object href -Match "Client.+\.exe").href
                $InstallFileName = $ClientDownload -split "/" | Select-Object -Last 1
                $WebRequestOutput = Invoke-WebRequest -Uri $ClientDownload -PassThru -OutFile "$DownloadDir\$InstallFileName"
            }
            'chrome' {
                $64bitdownload = 'http://dl.google.com/edgedl/chrome/install/GoogleChromeStandaloneEnterprise64.msi'
                $32bitDownload = 'http://dl.google.com/edgedl/chrome/install/GoogleChromeStandaloneEnterprise.msi'
                $InstallFileName = "googlechromestandaloneenterprise"

                #32bit
                $WebRequestOutput = Invoke-WebRequest -Uri $32bitdownload -PassThru -OutFile "$DownloadDir\$($InstallFileName).msi"

                #64bit
                $WebRequestOutput = Invoke-WebRequest -Uri $64bitdownload -PassThru -OutFile "$DownloadDir\$($InstallFileName)64.msi"

            }
            'cutepdf' {
                $downloadURL = "http://www.cutepdf.com/download/CuteWriter.exe"
                $InstallFileName = "CuteWriter.exe"
                $WebRequestOutput = Invoke-WebRequest -Uri $downloadURL -PassThru -OutFile "$DownloadDir\$($InstallFileName)"
            }
            'etcher' {
                #$url = "https://github.com/balena-io/etcher/releases"
                $LatestAppVersion = Get-LatestAppVersion -App "$app"
                $InstallFileName = "balenaEtcher-Setup-$($LatestAppVersion)-x64.exe"
                $DownloadURL = "https://github.com/balena-io/etcher/releases/download/v$LatestAppVersion/balenaEtcher-Setup-$LatestAppVersion-x64.exe"
                $WebRequestOutput = Invoke-WebRequest -Uri "$DownloadURL" -OutFile "$DownloadDir\$($InstallFileName)"
            }
            'firefox' {
                $64bitdownload = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
                $32bitDownload = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win&lang=en-US"

                #32bit
                $dl = Invoke-WebRequest -Uri $32bitdownload -PassThru -OutFile "$DownloadDir\ff32.tmp"
                $newAppVersion = Get-LatestAppVersion -App $App
                $InstallFileName = ($dl.BaseResponse.ResponseUri -split '/'| Select-Object -Last 1).split(" ") | Select-Object -First 2
                $InstallFileName = "$InstallFileName $newAppVersion"
                Move-Item "$DownloadDir\ff32.tmp" "$DownloadDir\$InstallFileName-32bit.exe" -Force

                #64bit
                $dl = Invoke-WebRequest -Uri $64bitdownload -PassThru -OutFile "$DownloadDir\ff64.tmp"
                Move-Item "$DownloadDir\ff64.tmp" "$DownloadDir\$InstallFileName-64bit.exe" -Force
            }
            'flash' {
                # https://gist.github.com/jasonadsit/c77340fe385fe953f9c54436b926cf83
                $MajorVersion = (Get-LatestAppVersion -App $App).Major
                $FlashActiveX = "https://www.adobe.com/etc/adc/token/generation.installerlink.json?href=https%3A%2F%2Ffpdownload.macromedia.com%2Fget%2Fflashplayer%2Fdistyfp%2Fcurrent%2Fwin%2Finstall_flash_player_$($MajorVersion)_active_x.msi"
                $FlashPlugin = "https://www.adobe.com/etc/adc/token/generation.installerlink.json?href=https%3A%2F%2Ffpdownload.macromedia.com%2Fget%2Fflashplayer%2Fdistyfp%2Fcurrent%2Fwin%2Finstall_flash_player_$($MajorVersion)_plugin.msi"
                $FlashPpapi = "https://www.adobe.com/etc/adc/token/generation.installerlink.json?href=https%3A%2F%2Ffpdownload.macromedia.com%2Fget%2Fflashplayer%2Fdistyfp%2Fcurrent%2Fwin%2Finstall_flash_player_$($MajorVersion)_ppapi.msi"
                $FlashUrls = @($FlashActiveX,$FlashPlugin,$FlashPpapi)

                $FlashUrls | ForEach-Object {
                    Write-Verbose -Message "Getting download token from Adobe"
                    $JsonResponse = (New-Object System.Net.WebClient).DownloadString($_)

                    Write-Verbose -Message "Extract the URL string from the JSON response"
                    $Url = (New-Object System.Web.Script.Serialization.JavaScriptSerializer).DeserializeObject($JsonResponse).Values

                    Write-Verbose -Message "Determining filename"
                    $FileName = $($Url.Split('?')[0].Split('/')[-1])
                    $FilePath = Join-Path -Path $DownloadDir -ChildPath $FileName

                    Write-Verbose -Message "Downloading $FileName"
                    (New-Object System.Net.WebClient).DownloadFile("$Url","$FilePath")
                }

                $InstallFileName = "install_flash_player_$MajorVersion"
            }
            'gimp'{
                $url = "https://download.gimp.org/mirror/pub/gimp/"
                $html = Invoke-WebRequest -Uri "$url"

                $download = $html.Links | Where-Object -Property innerHTML -like "*Download GIMP*directly*"

                $GIMP_Versions = $html.Links | Where-Object -Property innerHTML -Match "v\d+\.\d+\.*\d*/"
                $GIMP_Versions = Sort-Object -InputObject $GIMP_Versions -Property innerHTML

                $Gimp_MinorVersionsUrl = $url + "$($GIMP_Versions[-1].href)" + "windows/"
                $html2 = Invoke-WebRequest -Uri $Gimp_MinorVersionsUrl
                $Gimp_MinorVersions = $html2.Links | Where-Object innerHTML -Match "gimp-\d+\.\d+\.*\d*-setup.+exe"

                $Gimp_MinorVersions = Sort-Object -InputObject $Gimp_MinorVersions -Property innerHTML

                if((($Gimp_MinorVersions[-1].innerHTML) -split "tor" | Select-Object -Last 1) -eq "rent"){
                    $InstallFileName = $Gimp_MinorVersions[-2].href
                }
                else {
                    $InstallFileName = $Gimp_MinorVersions[-1].href
                }

                $DownloadURL = $Gimp_MinorVersionsUrl + $InstallFileName
                $WebRequestOutput = Invoke-WebRequest -Uri $DownloadURL -OutFile "$DownloadDir\$InstallFileName"

            }
            'git'{
                $url = "https://git-scm.com/download/win"
                $html = Invoke-WebRequest -Uri $url

                $32bitDownload = ($html.links | Where-Object innerHTML -Match "32-bit Git for Windows Setup" | Select-Object -First 1).href
                $64bitDownload = ($html.links | Where-Object innerHTML -Match "64-bit Git for Windows Setup" | Select-Object -First 1).href
                $InstallFileName = "Git-$(Get-LatestAppVersion -App $App)"

                $WebRequestOutput = Invoke-WebRequest -Uri $32bitdownload -PassThru -OutFile "$DownloadDir\$($InstallFileName)-32-bit.exe"
                $WebRequestOutput = Invoke-WebRequest -Uri $64bitdownload -PassThru -OutFile "$DownloadDir\$($InstallFileName)-64-bit.exe"

            }
            'insync' {
                $url = "https://downloads.druva.com/insync/client/cloud/"
                $html = Invoke-WebRequest -uri $url
                $Versions = $html.Links | Where-Object href -Match "windows/$VersionRegex"
                $InstallFileName = "inSync$(Get-LatestAppVersion -App $App).msi"
                $WebRequestOutput = Invoke-WebRequest -Uri $Versions.href -PassThru -OutFile "$DownloadDir\$InstallFileName"
            }
            'notepad++' {
                # Configure Domain to scrape
                $Domain = "https://notepad-plus-plus.org"
                $AppendToDomain = "/download"

                # build URL to scan
                $SiteToScan = $Domain + $AppendToDomain

                # Scan URL to download file
                $url32 = ((Invoke-WebRequest -uri $SiteToScan).links | Where-Object innerHTML -like "*Notepad++ Installer 32-bit*").href
                $url64 = ((Invoke-WebRequest -uri $SiteToScan).links | Where-Object innerHTML -like "*Notepad++ Installer 64-bit*").href

                # Build URL to download file
                $32bitDownload = $Domain + $url32
                $64bitdownload = $Domain + $url64

                # Build install filename
                $newAppVersion = Get-LatestAppVersion -App $App
                $InstallFileName = "npp.$($newAppVersion).Installer"

                #32bit
                $WebRequestOutput = Invoke-WebRequest -Uri $32bitdownload -PassThru -OutFile "$DownloadDir\$($InstallFileName).exe"

                #64bit
                $WebRequestOutput = Invoke-WebRequest -Uri $64bitdownload -PassThru -OutFile "$DownloadDir\$($InstallFileName).x64.exe"

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

                $json = (Invoke-WebRequest -Uri "$url"  | ConvertFrom-Json)
                $DownloadURL = $json[0].binaries[0].installer_link
                $LatestAppVersion = Get-LatestAppVersion -App $App

                $InstallFileName = "OpenJDK8U-jdk_x64_windows_hotspot_$($LatestAppVersion).msi"
                $WebRequestOutput = Invoke-WebRequest -Uri $DownloadURL -OutFile "$DownloadDir\$InstallFileName"
            }
            'putty' {
                # build URL to scan
                $SiteToScan = "https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html"

                # Scan URL to download file
                $32bitDownload = ((Invoke-WebRequest -uri $SiteToScan ).links | Where-Object -Property innerHTML -like “*putty*msi*”).href -notlike "*64bit*"
                $64bitdownload = ((Invoke-WebRequest -uri $SiteToScan ).links | Where-Object -Property innerHTML -like “*putty*msi*”).href -like "*64bit*"

                # Build install filename
                $newAppVersion = Get-LatestAppVersion -App $App
                $InstallFileName = "putty-$($newAppVersion)"

                #32bit
                $WebRequestOutput = Invoke-WebRequest -Uri "$32bitDownload" -OutFile "$DownloadDir\$($InstallFileName)-installer.msi"

                #64bit
                $WebRequestOutput = Invoke-WebRequest -Uri "$64bitdownload" -OutFile "$DownloadDir\$($InstallFileName)-64bit-installer.msi"
            }
            'reader' {
                # https://stackoverflow.com/questions/48867426/script-to-download-latest-adobe-reader-dc-update
                $FTPFolderUrl = "ftp://ftp.adobe.com/pub/adobe/reader/win/AcrobatDC/"

                #connect to ftp, and get directory listing
                $FTPRequest = [System.Net.FtpWebRequest]::Create("$FTPFolderUrl")
                $FTPRequest.Method = [System.Net.WebRequestMethods+Ftp]::ListDirectory
                $FTPResponse = $FTPRequest.GetResponse()
                $ResponseStream = $FTPResponse.GetResponseStream()
                $FTPReader = New-Object System.IO.Streamreader -ArgumentList $ResponseStream
                $DirList = $FTPReader.ReadToEnd()

                #from Directory Listing get last entry in list, but skip one to avoid the 'misc' dir
                $LatestUpdate = $DirList -split '[\r\n]' | Where-Object {$_} | Select-Object -Last 1 -Skip 1

                #build file name
                $InstallFileName = "AcroRdrDCUpd" + $LatestUpdate + ".msp"

                #build download url for latest file
                $DownloadURL = "$FTPFolderUrl$LatestUpdate/$InstallFileName"

                #download file
                (New-Object System.Net.WebClient).DownloadFile("$DownloadURL", "$DownloadDir\$InstallFileName")


            }
            'receiver' {
                $url = "https://www.citrix.com/downloads/citrix-receiver/"
                $html = Invoke-WebRequest -Uri "$url"
                $LatestAppVersion = Get-LatestAppVersion -App $App
                $versionLink = $html.Links | Where-Object innerHTML -Match "Receiver $LatestAppVersion.* for Windows$"

                $domain = "https://www.citrix.com/"
                $html2 = Invoke-WebRequest -Uri "$domain$($versionLink.href)"
                $downloadLink = $html2.Links | Where-Object innerHTML -Match "Download Receiver for Windows" | Select-Object -First 1

                $InstallFileName = "CitrixReceiver.exe"
                $WebRequestOutput = Invoke-WebRequest -Uri "https:$($downloadLink.rel)" -OutFile "$DownloadDir\$InstallFileName"
            }
            'vlc' {
                $url = "http://download.videolan.org/pub/videolan/vlc/"
                $LatestAppVersion =  Get-LatestAppVersion -App $app

                $32bitDownload = $url + "$($LatestAppVersion)/win32/vlc-$($LatestAppVersion)-win32.msi"
                $64bitdownload = $url + "$($LatestAppVersion)/win64/vlc-$($LatestAppVersion)-win64.msi"

                # Build install filename
                $InstallFileName = "vlc-$($LatestAppVersion)"

                #32bit
                $WebRequestOutput = Invoke-WebRequest -Uri "$32bitDownload" -OutFile "$DownloadDir\$($InstallFileName)-win32.msi"

                #64bit
                $WebRequestOutput = Invoke-WebRequest -Uri "$64bitdownload" -OutFile "$DownloadDir\$($InstallFileName)-win64.msi"
            }
            'vscode' {
                $url = "https://vscode-update.azurewebsites.net/latest/win32-x64/stable"
                $LatestAppVersion = Get-LatestAppVersion -App "$app"
                $InstallFileName = "VSCodeSetup-x64-$($LatestAppVersion).exe"
                $WebRequestOutput = Invoke-WebRequest -Uri "$url" -OutFile "$DownloadDir\$($InstallFileName)"
            }
            'winscp' {
                $LatestAppVersion = Get-LatestAppVersion -App WinSCP
                $downloadPage = "https://winscp.net/download/WinSCP-$LatestAppVersion-Setup.exe"
                $html = Invoke-WebRequest -Uri "$downloadPage" -UseBasicParsing
                $CDNDownload = $html.Links.href -match ".+files\/WinSCP-\d+(\.\d+)+-Setup\.exe.*"
                $CDNDownload = $CDNDownload[0] # Selects the first link
                $InstallFileName = "WinSCP-$LatestAppVersion-Setup.exe"
                $WebRequestOutput = Invoke-WebRequest -Uri "$CDNDownload" -OutFile "$DownloadDir\$InstallFileName"
            }
            'wireshark' {
                $LatestAppVersion = Get-LatestAppVersion -App $App

                $32bitDownload = "https://www.wireshark.org/download/win32/all-versions/Wireshark-win32-$LatestAppVersion.msi"
                $64bitDownload = "https://www.wireshark.org/download/win64/all-versions/Wireshark-win64-$LatestAppVersion.msi"
                $InstallFileName = "Wireshark-win*-$LatestAppVersion.msi"

                #32bit
                $WebRequestOutput = Invoke-WebRequest -Uri "$32bitDownload" -OutFile "$DownloadDir\Wireshark-win32-$LatestAppVersion.msi"

                #64bit
                $WebRequestOutput = Invoke-WebRequest -Uri "$64bitdownload" -OutFile "$DownloadDir\Wireshark-win64-$LatestAppVersion.msi"

            }
        }

        #Get the install files to return
        $InstallFiles = Get-ChildItem -Path "$DownloadDir\$InstallFileName*"
        return $InstallFiles
    }
}