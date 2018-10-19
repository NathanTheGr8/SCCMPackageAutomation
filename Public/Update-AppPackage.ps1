function Update-AppPackage {
    param
    (
        [Parameter(Mandatory = $true,
        HelpMessage = 'What standard app are you trying to update?')]
        [string]
        [ValidateSet('7zip','BigFix','Chrome','CutePDF','Firefox','Flash','GIMP','Git','insync','Java','Notepad++','Putty','Reader','Receiver','VLC','VSCode','WinSCP','WireShark', IgnoreCase = $true)]
        $App,
        [switch]
        $ForceUpdate

    )

    $CurrentAppVersion = Get-CurrentAppVersion -App $App
    $LatestAppVersion = Get-LatestAppVersion -App $App
    $RootApplicationPathTemp = $global:RootApplicationPath[$app]

    # Map network drive to SCCM
    # Test an arbitrary folder on the share
    $Networkpath = "$($SCCM_Share_Letter):\$SCCM_Share_Test_Folder"

    If (Test-Path -Path $Networkpath) {
        Write-Host "$($SCCM_Share_Letter) Drive to SCCM Exists already"
    }
    Else {
        #map network drive
        New-PSDrive -Name "$($SCCM_Share_Letter)" -PSProvider "FileSystem" -Root "$SCCM_Share" -Persist

        #check mapping again
        If (Test-Path -Path $Networkpath) {
            Write-Host "$($SCCM_Share_Letter) Drive has been mapped to SCCM"
        }
        Else {
            Write-Error "Couldn't map $($SCCM_Share_Letter) Drive to SCCM, aborting"
            Return
        }
    }
    # End Map Network Drive

    if (($CurrentAppVersion -lt [version]$LatestAppVersion) -or ($ForceUpdate)) {
        if ($ForceUpdate) {
            Write-Host "Forcing update of $App from $CurrentAppVersion to $LatestAppVersion"
        }
        else {
            Write-Host "Upgrading $App package from $CurrentAppVersion to $LatestAppVersion"
        }

        $InstallFiles = Download-LatestAppVersion -App $App
        $count = (Measure-Object -InputObject $SCCM_Share -Character).Characters + 1
        # Gets the most recent folder for a given app
        $CurrentAppPath =  "$($SCCM_Share_Letter):\" + $RootApplicationPathTemp.Substring($count) | Get-ChildItem | Sort-Object CreationTime -Descending | Select-Object -f 1

        $RevNumber = 1
        $newAppPath = "$RootApplicationPathTemp\$App $LatestAppVersion (R$RevNumber)"

        $alreadyExists = Test-Path -Path "$newAppPath"
        while ($alreadyExists){
            #if the newAppPath already exists increments R#
            Write-Output "'$App $LatestAppVersion (R$RevNumber)' already exists, auto incrementing the R`#"
            $RevNumber++
            $newAppPath = "$RootApplicationPathTemp\$App $LatestAppVersion (R$RevNumber)"
            $alreadyExists = Test-Path -Path "$newAppPath"
        }
        Write-Output "rootapppath is: $($global:RootApplicationPath[$app])"
        $newAppPath

        #Copies the Current Package to the new. Replaces install files and increments version.
        Write-Output "Creating folder '$App $LatestAppVersion (R$RevNumber)'"
        Copy-PSADTFolders -OldPackageRootFolder "$($CurrentAppPath.FullName)" -NewPackageRootFolder "$newAppPath" -NewPSADTFiles $InstallFiles
        Write-Output "Updating version numbers from $CurrentAppVersion to $LatestAppVersion"
        Update-PSADTAppVersion -PackageRootFolder "$newAppPath" -CurrentVersion "$CurrentAppVersion" -NewVersion "$LatestAppVersion"

    }
    else {
        Write-Host "$App $CurrentAppVersion package is already up to date"
    }

}


function Update-PSADTAppVersion {
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateScript({
            if(-Not (Test-Path -Path "$_") ){
                throw "Folder does not exist"
            }
            if(-Not (Test-Path -Path "$_" -PathType Container) ){
                throw "The PackageRootFolder argument must be a folder. Files are not allowed."
            }
            return $true
        })]
        $PackageRootFolder,
        [Parameter(Mandatory = $true)]
        [string]
        [ValidatePattern("^(\d+\.)?(\d+\.)?(\d+\.)?(\d+\.)?(\*|\d+)?$")]
        #basically can be up #.#.#.#.# or just one #
        $CurrentVersion,
        [Parameter(Mandatory = $true)]
        [string]
        [ValidatePattern("^(\d+\.)?(\d+\.)?(\d+\.)?(\d+\.)?(\*|\d+)?$")]
        #basically can be up #.#.#.#.# or just one #
        $NewVersion,
        [string]
        [ValidateScript({
            if(-Not (Test-Path -Path "$PackageRootFolder\$InstallScript") ){
                throw "The PackageRootFolder argument path does not exist"
            }
            if(-Not (Test-Path -Path "$PackageRootFolder\$InstallScript" -PathType Leaf) ){
                throw "The InstallScript argument must be a file."
            }
            return $true
        })]
        $InstallScript = "Deploy-Application.ps1" #defaults to this

    )

    (Get-Content "$PackageRootFolder\$InstallScript").Replace("`$appVersion = '$CurrentVersion'","`$appVersion = '$NewVersion'") | Set-Content  -Path "$PackageRootFolder\$InstallScript"
}

function Copy-PSADTFolders {
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateScript({
            if(-Not (Test-Path -Path "$_") ){
                throw "The PackageRootFolder argument path does not exist"
            }
            if(-Not (Test-Path -Path "$_" -PathType Container) ){
                throw "The PackageRootFolder argument must be a folder. Files are not allowed."
            }
            return $true
        })]
        $OldPackageRootFolder,
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateScript({
            if((Test-Path -Path "$_") ){
                throw "The path for NewPackageRootFolder already exists"
            }
            return $true
        })]
        $NewPackageRootFolder,
        [Parameter(Mandatory = $true)]
        $NewPSADTFiles

    )
    Write-Output "Copying old package files to $NewPackageRootFolder"
    Copy-Item -Path "$OldPackageRootFolder" -Destination "$NewPackageRootFolder" -Recurse
    if ($OldPackageRootFolder -match "Reader"){
        Write-Output "Removing old msp install files"
        Remove-Item -Path "$NewPackageRootFolder\Files\*.msp"
    }
    elseif ($OldPackageRootFolder -match "BigFix"){
        Write-Output "Removing old exe install files"
        Remove-Item -Path "$NewPackageRootFolder\Files\*.exe"
    }
    else {
        Write-Output "Removing old install files"
        Remove-Item -Path "$NewPackageRootFolder\Files\*"
    }
    Write-Output "Copying new install files"
    Copy-Item -Path $NewPSADTFiles -Destination "$NewPackageRootFolder\Files" -Verbose

}



function Get-LatestAppVersion {
    # http://vergrabber.kingu.pl/vergrabber.json
    # Could use that if I didn't want to scrape websites
    param
    (
        [Parameter(Mandatory = $true,
        HelpMessage = 'What standard app are you trying to get the version of?')]
        [string]
        [ValidateSet('7zip','BigFix','Chrome','CutePDF','Firefox','Flash','GIMP','Git','insync','Java','Notepad++','Putty','Reader','Receiver','VLC','VSCode','WinSCP','WireShark', IgnoreCase = $true)]
        $App
    )

    #TLS
    [Net.ServicePointManager]::SecurityProtocol = [Net.SecurityProtocolType]::Tls12

    switch ($App) {
        '7zip' {
            # https://www.reddit.com/r/PowerShell/comments/9gwbed/scrape_7zip_website_for_the_latest_version/
            $Domain = "https://www.7-zip.org/download.html"
            $temp   = (Invoke-WebRequest -uri $Domain)
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
            $html = Invoke-WebRequest -Uri "$url"
            $versionLinks = $html.Links | Where-Object href -Match "\d+\.\d+\/patch\d+" | Sort-Object -Descending
            $latestURL = $url + $versionLinks[0].href
            $html = Invoke-WebRequest -Uri "$latestURL"
            $ClientDownload = $html.Links | Where-Object href -Match "Client.+\.exe"
            $LatestAppVersion = [regex]::match($ClientDownload.href,'\d+(\.\d+)+').Value
        }
        'chrome' {
            # https://stackoverflow.com/questions/35114642/get-latest-release-version-number-for-chrome-browser
            # https://omahaproxy.appspot.com/


            $LatestAppVersion = (Invoke-WebRequest -Uri "https://omahaproxy.appspot.com/all.json" | ConvertFrom-Json)[0].versions[-1].version
        }
        'cutepdf' {
                #Scrubbing the page for version is difficult. It also gives an incomplete version.
                # http://www.cutepdf.com/products/cutepdf/writer.asp

                $download = Download-LatestAppVersion -App $App
                $LatestAppVersion = $download.VersionInfo.ProductVersion
        }
        'firefox' {
            $LatestAppVersion = (Invoke-WebRequest -Uri "https://product-details.mozilla.org/1.0/firefox_versions.json" | ConvertFrom-Json).LATEST_FIREFOX_VERSION
        }
        'flash' {
            # https://github.com/auberginehill/update-adobe-flash-player/blob/master/Update-AdobeFlashPlayer.ps1

            $url = "https://fpdownload.macromedia.com/pub/flashplayer/masterversion/masterversion.xml"
            $xml_versions = New-Object XML
            $xml_versions.Load($url)

            # The different flash types can have different version numbers. I need to loop through
            # all of them to get be sure
            [version]$xml_activex_win10_current = ($xml_versions.version.release.ActiveX_win10.version).replace(",",".")
            [version]$xml_activex_edge_current = ($xml_versions.version.release.ActiveX_Edge.version).replace(",",".")
            [version]$xml_activex_win_current = ($xml_versions.version.release.ActiveX_win.version).replace(",",".")
            [version]$xml_plugin_win_current = ($xml_versions.version.release.NPAPI_win.version).replace(",",".")
            [version]$xml_ppapi_win_current = ($xml_versions.version.release.PPAPI_win.version).replace(",",".")

            $FlashVersions = $xml_activex_win10_current,$xml_activex_edge_current,$xml_activex_win_current,$xml_plugin_win_current,$xml_ppapi_win_current
            $FlashVersions = Sort-Object -InputObject $FlashVersions -Descending
            $LatestAppVersion = $FlashVersions[0]
        }
        'gimp'{
            $url = "https://download.gimp.org/mirror/pub/gimp/"
            $html = Invoke-WebRequest -Uri "$url"

            $GIMP_Versions = $html.Links | Where-Object innerHTML -Match "v\d+\.\d+\.*\d*/"
            $GIMP_Versions = Sort-Object -InputObject $GIMP_Versions -Property innerHTML

            $Gimp_MinorVersionsUrl = $url + "$($GIMP_Versions[-1].href)" + "windows/"
            $html2 = Invoke-WebRequest -Uri $Gimp_MinorVersionsUrl
            $Gimp_MinorVersions = $html2.Links | Where-Object innerHTML -Match "gimp-\d+\.\d+\.*\d*-setup.+exe"
            $Gimp_MinorVersions = Sort-Object -InputObject $Gimp_MinorVersions -Property innerHTML
            #gimp-(\d+\.*){3}-setup(-\d+)*\.exe[^.]

            if(($Gimp_MinorVersions[-1].innerHTML -split "." | Select-Object -Last 1) -eq "torrent"){
                $LatestAppVersion = $Gimp_MinorVersions[-2].innerHTML -split "-" | Select-Nth -N 2
            }
            else {
                $LatestAppVersion = $Gimp_MinorVersions[-1].innerHTML -split "-" | Select-Nth -N 2
            }
        }
        'git'{
                $url = "https://git-scm.com/download/win"
                $html = Invoke-WebRequest -Uri $url

                $32bitDownload = ($html.links | Where-Object innerHTML -Match "32-bit Git for Windows Setup" | Select-Object -First 1).href
                $LatestAppVersion = [regex]::match($32bitDownload,'\d+(\.\d+)+').Value
        }
        'java' {
            Write-Output "Java can't be automatically downloaded."
            #todo?
        }
        'notepad++' {
            <#
            I am scrapping the domain for links like *Notepad++ Installer 64-bit.
            This solution will break if they change their link naming format. However there is on offical notepad++
            api to query.
            #>
            # URL to scan
            $SiteToScan = "https://notepad-plus-plus.org/download"
            $html = Invoke-WebRequest -uri $SiteToScan
            # Scan URL to download file
            $url64 = ($html.links | Where-Object innerHTML -like "*Notepad++ Installer 64-bit*").href
            $LatestAppVersion = $url64 -split "/" | Select-Object -Last 2 | Select-Object -first 1

        }
        'putty' {
            $SiteToScan = "https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html"
            $foundVersion = (Invoke-WebRequest -Uri $SiteToScan).Parsedhtml.title -match "\d+.\d+"

            if ($foundVersion){
                $LatestAppVersion = $Matches[0]
            }
            else {
                throw "Error $app version not found"
            }
        }
        'reader' {
            $url = "https://helpx.adobe.com/acrobat/release-note/release-notes-acrobat-reader.html"
            $html = Invoke-WebRequest -Uri "$url"

            $DC_Versions = $html.Links | Where-Object innerHTML -Match "\(\d+\.\d+\.\d+\)"

            foreach ($version in $DC_Versions){
                $index = $version.innerHTML.indexOf("(")
                $version.innerHTML = $version.innerHTML.substring($index)
            }

            $DC_Versions = $DC_Versions | Sort-Object -Descending -Property innerHTML
            $LatestAppVersion = $DC_Versions[0].innerHTML.Replace("(","").replace(")","")
        }
        'receiver' {
            $url = "https://www.citrix.com/downloads/citrix-receiver/"
            $html = Invoke-WebRequest -Uri "$url"
            $versionLinks = $html.Links | Where-Object innerHTML -Match "Receiver \d+(\.\d+)+.* for Windows$"

            $versionArray = @()
            foreach ($version in $versionLinks){
                [version]$VersionNumber = $version.innerHTML -split " " | Select-Object -First 2 | Select-Object -Last 1
                $versionArray += $VersionNumber
            }

            $versionArray = $versionArray | Sort-Object -Descending
            $LatestAppVersion = $versionArray[0]
        }
        'vlc' {
            $url = "http://download.videolan.org/pub/videolan/vlc/"
            $html = Invoke-WebRequest -Uri "$url"

            $versionlinks = $html.Links | Where-Object href -match "^(\d+\.)?(\d+\.)?(\*|\d+)\/$" | Sort-Object -Property href -Descending
            $LatestAppVersion = $versionlinks[0].href -replace "/",""

        }
        'vscode' {
            $url = "https://github.com/Microsoft/vscode/releases"
            $html = Invoke-WebRequest -Uri "$url" -UseBasicParsing
            $versionlinks = $html.Links | Where-Object href -match "\d+(\.\d+)+" | Sort-Object -Descending
            $LatestAppVersion = [regex]::match($versionlinks[0].href,'\d+(\.\d+)+').Value

        }
        'winscp' {
            $url = "https://winscp.net/eng/downloads.php"
            $html = Invoke-WebRequest -Uri "$url" -UseBasicParsing
            $versionlinks = $html.Links -match ".+Download/WINSCP.+Setup.exe" | Sort-Object -Descending
            if ($versionlinks[0].href.Contains("beta")){
                $LatestAppVersion = [regex]::match($versionlinks[1].href,'\d+(\.\d+)+').Value
            }
            else {
                $LatestAppVersion = [regex]::match($versionlinks[0].href,'\d+(\.\d+)+').Value
            }
        }
        'wireshark' {
            $url = "https://www.wireshark.org/download/win64/all-versions/"
            $html = Invoke-WebRequest -Uri "$url"

            $Versions = $html.Links | Where-Object innerHTML -Match "\d+\.\d+\.\d+\.msi"

            $versionArray = @()
            foreach ($version in $Versions){
                $VersionNumber = $version.innerHTML -split "-" | Select-Object -Last 1
                $VersionNumber = $VersionNumber -replace ".msi", ""
                $versionArray += $VersionNumber
            }

            $versionArray = $versionArray | Sort-Object -Descending
            $LatestAppVersion = $versionArray[0]
        }
    }

    if ($app -eq "reader"){
        return $LatestAppVersion
    }
    else {
        return [version]$LatestAppVersion
    }
}

function Download-LatestAppVersion {
    param
    (
        [Parameter(Mandatory = $true,
        HelpMessage = 'What standard app are you trying to get the version of?')]
        [string]
        [ValidateSet('7zip','BigFix','Chrome','CutePDF','Firefox','Flash','GIMP','Git','insync','Java','Notepad++','Putty','Reader','Receiver','VLC','VSCode','WinSCP','WireShark', IgnoreCase = $true)]
        $App
    )

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
            $Domain = "http://www.7-zip.org"
            $AppendToDomain = "/download.html"

            # build URL to scan
            $SiteToScan = $Domain + $AppendToDomain

            # build URL to scan
            $TempURLS32 = (Invoke-WebRequest -uri $SiteToScan).links | Where-Object innerText -like “*Download*” | Where-Object href -Like "*.msi" | Select-Object -First 2 | Where-Object href -NotLike "*x64*"
            $TempURLS64 = (Invoke-WebRequest -uri $SiteToScan).links | Where-Object innerText -like “*Download*” | Where-Object href -Like "*.msi" | Select-Object -First 2 | Where-Object href -Like "*x64*"

            $32bitDownload = $Domain + "/" + $TempURLS32.href
            $64bitdownload = $Domain + "/" + $TempURLS64.href

            # Build install filename
            $InstallFileName = $($32bitDownload.Split("/") | Select-Object -Last 1).Split(".") | Select-Object -First 1


            #32bit
            Invoke-WebRequest -Uri $32bitdownload -PassThru -OutFile "$DownloadDir\$($InstallFileName).msi"

            #64bit
            Invoke-WebRequest -Uri $64bitdownload -PassThru -OutFile "$DownloadDir\$($InstallFileName)-x64.msi"
        }
        'bigfix' {
            $url = "http://support.bigfix.com/bes/release/"
            $html = Invoke-WebRequest -Uri "$url"
            $versionLinks = $html.Links | Where-Object href -Match "\d+\.\d+\/patch\d+" | Sort-Object -Descending
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
        'java' {
            Write-Output "Java can't be automatically downloaded."
            #todo I think I can still get the most recent java 8 update version
            return
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
            $domain = "https://winscp.net"
            $url = "https://winscp.net/eng/downloads.php"
            $html = Invoke-WebRequest -Uri "$url" -UseBasicParsing
            $versionlinks = $html.Links -match ".+Download/WINSCP.+Setup.exe"
            $downloadURL = $Domain + $versionLinks[0].href
            $InstallFileName = $versionLinks[0].href -split "/" | Select-Object -Last 1
            $WebRequestOutput = Invoke-WebRequest -Uri "$downloadURL" -OutFile "$DownloadDir\$InstallFileName"
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

function Get-OutDatedApps {
    <#
        .SYNOPSIS
        Loop through all apps to see which ones are out of date.

        .DESCRIPTION

        .EXAMPLE

        .REMARKS

    #>

    $MaintainedApps = @()
    $BlackList = @("java","insync","cutepdf")
    ForEach ($App in $RootApplicationPath.Keys){
        if (!($BlackList.Contains($App))){
            $MaintainedApps += $app
        }
    }
    $MaintainedApps= $MaintainedApps | Sort-Object

    Foreach ($App in $MaintainedApps){
        [version]$currVer = Get-CurrentAppVersion -App $app
        [version]$LatestVer = Get-LatestAppVersion -App $App

        if ($LatestVer -gt $currVer){
            Write-Host "$App needs updated to $LatestVer. We are currently on $currVer" -ForegroundColor Red
        }
        else {
            Write-Host "$app is on latest version $LatestVer" -ForegroundColor Green
        }

    }
}

<# Global Variables and functions




#>

$SCCM_Site = "HMN"
$SCCM_Share = "\\spivsccm01\Packages"
$SCCM_Share_Test_Folder = "CoreApps_ALL"
$SCCM_Share_Letter = "P"


$Global:RootApplicationPath = @{
    '7zip' = "$SCCM_Share\HOME OFFICE\7Zip"
    'bigfix' = "$SCCM_Share\CoreApps_ALL\BixFixClient"
    'chrome' = "$SCCM_Share\CoreApps_ALL\GoogleChrome"
    'cutepdf' = "$SCCM_Share\HOME OFFICE\CutePDF"
    'firefox' = "$SCCM_Share\HOME OFFICE\Mozilla FireFox"
    'flash'  = "$SCCM_Share\CoreApps_ALL\Adobe\AdobeFlash"
    'gimp'= "$SCCM_Share\HOME OFFICE\GIMP"
    'git' = "$SCCM_Share\HOME OFFICE\Git"
    'insync' = "$SCCM_Share\CoreApps_ALL\DruvaCloud"
    'java' = "$SCCM_Share\CoreApps_ALL\java"
    'notepad++'  = "$SCCM_Share\HOME OFFICE\Notepad++"
    'putty' = "$SCCM_Share\HOME OFFICE\Putty"
    'reader' = "$SCCM_Share\CoreApps_ALL\Adobe\AdobeReader"
    'receiver' = "$SCCM_Share\HOME OFFICE\Citrix Receiver"
    'vlc' = "$SCCM_Share\HOME OFFICE\VLC"
    'vscode' = "$SCCM_Share\HOME OFFICE\VSCode"
    'winscp'  = "$SCCM_Share\HOME OFFICE\WinSCP"
    'wireshark' = "$SCCM_Share\HOME OFFICE\WireShark"
}

function Get-CurrentAppVersion {
    param
    (
        [Parameter(Mandatory = $true,
        HelpMessage = 'What standard app are you trying to get the version of?')]
        [string]
        [ValidateSet('7zip','BigFix','Chrome','CutePDF','Firefox','Flash','GIMP','Git','insync','Java','Notepad++','Putty','Reader','Receiver','VLC','VSCode','WinSCP','WireShark', IgnoreCase = $true)]
        $App
    )
    $App = $App.ToLower()
    # Get-ChildItem has trouble working with UNC paths from the $SCCM_Site: drive. That is why I map a $SCCM_Share_Letter drive
    $count = (Measure-Object -InputObject $SCCM_Share -Character).Characters + 1
    # Gets the most recent folder for a given app
    $LatestApplicationPath =  "$($SCCM_Share_Letter):\" + $global:RootApplicationPath[$app].Substring($count) | Get-ChildItem | Sort-Object -Property CreationTime -Descending | Select-Object -f 1
    $CurrentAppVersion = Get-PSADTAppVersion -PackageRootFolder "$($LatestApplicationPath.Fullname)"
    if ($app -eq "reader"){
        return $CurrentAppVersion #readers versions often have leading 0s
    }
    else {
        return [version]$CurrentAppVersion
    }
}

function Get-PSADTAppVersion {
    <#
        .SYNOPSIS
        Gets the $appversion varible for a given PSADT package

        .DESCRIPTION
        Gets the $appversion varible for a given PSADT package
        Queries the Deploy-Application.ps1 file for "appversion"
        Takes the first string returned. I don't care about other occerences in the file
        Converts it to a string
        Splits it at the "=" taking the second half
        Removes white space
        Removes the "'" characters

        .PARAMETER PackageRootFolder
        The root folder for the PSADT package

        .PARAMETER InstallScript
        Defaults to Deploy-Applicaiton.ps1

        .EXAMPLE

        .REMARKS

    #>
    param
    (
        [Parameter(Mandatory = $true)]
        [string]
        [ValidateScript({
            if(-Not (Test-Path -Path "$_") ){
                throw "Folder does not exist"
            }
            if(-Not (Test-Path -Path "$_" -PathType Container) ){
                throw "The PackageRootFolder argument must be a folder. Files are not allowed."
            }
            return $true
        })]
        $PackageRootFolder,
        [string]
        [ValidateScript({
            if(-Not (Test-Path -Path "$PackageRootFolder\$InstallScript") ){
                throw "The PackageRootFolder argument path does not exist"
            }
            if(-Not (Test-Path -Path "$PackageRootFolder\$InstallScript" -PathType Leaf) ){
                throw "The InstallScript argument must be a file."
            }
            return $true
        })]
        $InstallScript = "Deploy-Application.ps1" #defaults to this

    )

    $Version = (Select-String -Path "$PackageRootFolder\$InstallScript" -SimpleMatch "appVersion")[0].ToString().Split("=")[1].Trim().Replace("'","")

    return $Version
}
