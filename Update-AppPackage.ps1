. .\GlobalVariables.ps1

function Update-AppPackage {
    param
    (
        [Parameter(Mandatory = $true,
        HelpMessage = 'What standard app are you trying to update?')]
        [string]
        [ValidateSet('7zip','BigFix','Chrome','Firefox','Flash','GIMP','insync','Java','Notepad++','Putty','Reader','Receiver','VLC','WinSCP', IgnoreCase = $true)]
        $App,
        [switch]
        $ForceUpdate

    )

    [version]$CurrentAppVersion = Get-CurrentAppVersion -App $App
    [version]$LatestAppVersion = Get-LatestAppVersion -App $App

    # Map network drive to SCCM
    # Test an arbitrary folder on the share
    $Networkpath = "$($SCCM_Share_Letter):\CoreApps_ALL" 

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

    if (($CurrentAppVersion -lt $LatestAppVersion) -or ($ForceUpdate)) {#this is creating a file with the version number for some reason
        if ($ForceUpdate) {
            Write-Host "Forcing update of $App from $CurrentAppVersion to $LatestAppVersion"
        }
        else {
            Write-Host "Upgrading $App package from $CurrentAppVersion to $LatestAppVersion"
        }

        $InstallFiles = Download-LatestAppVersion -App $App
        $rootApplicationPath = Get-RootApplicationPath -App $App
        $count = (Measure-Object -InputObject $SCCM_Share -Character).Characters + 1
        # Gets the most recent folder for a given app
        $CurrentAppPath =  "$($SCCM_Share_Letter):\" + $rootApplicationPath.Substring($count) | Get-ChildItem | sort CreationTime -desc | select -f 1 

        $RevNumber = 1
        $newAppPath = "$rootApplicationPath\$App $LatestAppVersion (R$RevNumber)"

        $alreadyExists = Test-Path -Path "$newAppPath"
        while ($alreadyExists){
            #if the newAppPath already exists increments R#
            Write-Output "'$App $LatestAppVersion (R$RevNumber)' already exists, auto incrementing the R`#"
            $RevNumber++
            $newAppPath = "$rootApplicationPath\$App $LatestAppVersion (R$RevNumber)"
            $alreadyExists = Test-Path -Path "$newAppPath"
        }

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
    Write-Output "Removing old install files"
    Remove-Item -Path "$NewPackageRootFolder\Files\*"
    Write-Output "Copying new install files"
    Copy-Item -Path $NewPSADTFiles -Destination "$NewPackageRootFolder\Files" -Verbose

}



function Get-LatestAppVersion {
    # http://vergrabber.kingu.pl/vergrabber.json
    param
    (
        [Parameter(Mandatory = $true,
        HelpMessage = 'What standard app are you trying to get the version of?')]
        [string]
        [ValidateSet('7zip','BigFix','Chrome','Firefox','Flash','GIMP','insync','Java','Notepad++','Putty','Reader','Receiver','VLC','WinSCP', IgnoreCase = $true)]
        $App
    )
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
            #todo
        }
        'chrome' {
            # https://stackoverflow.com/questions/35114642/get-latest-release-version-number-for-chrome-browser
            # https://omahaproxy.appspot.com/

            $LatestAppVersion = (Invoke-WebRequest -Uri "https://omahaproxy.appspot.com/all.json" | ConvertFrom-Json)[0].versions[-1].version
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

            $GIMP_Versions = $html.Links | where innerHTML -Match "v\d+\.\d+\.*\d*/"
            $GIMP_Versions = Sort-Object -InputObject $GIMP_Versions -Property innerHTML

            $Gimp_MinorVersionsUrl = $url + "$($GIMP_Versions[-1].href)" + "windows/"
            $html2 = Invoke-WebRequest -Uri $Gimp_MinorVersionsUrl
            $Gimp_MinorVersions = $html2.Links | where innerHTML -Match "gimp-\d+\.\d+\.*\d*-setup.+exe"
            $Gimp_MinorVersions = Sort-Object -InputObject $Gimp_MinorVersions -Property innerHTML
            #gimp-(\d+\.*){3}-setup(-\d+)*\.exe[^.]

            if(($Gimp_MinorVersions[-1].innerHTML -split "." | select -Last 1) -eq "torrent"){
                $LatestAppVersion = $Gimp_MinorVersions[-2].innerHTML -split "-" | Select-Nth -N 2
            }
            else {
                $LatestAppVersion = $Gimp_MinorVersions[-1].innerHTML -split "-" | Select-Nth -N 2
            }
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
 
            # Scan URL to download file
            $url64 = ((Invoke-WebRequest -uri $SiteToScan).links | Where innerHTML -like “*Notepad++ Installer 64-bit*”).href
            $LatestAppVersion = $url64 -split "/" | select -Last 2 | Select -first 1
            
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

            $DC_Versions = $html.Links | where innerHTML -Match "\(\d+\.\d+\.\d+\)"

            foreach ($version in $DC_Versions){
                $index = $version.innerHTML.indexOf("(")
                $version.innerHTML = $version.innerHTML.substring($index)
            }

            $DC_Versions = Sort-Object -InputObject $DC_Versions -Property innerHTML
            $LatestAppVersion = $DC_Versions[0].innerHTML.Replace("(","").replace(")","")
        }
        'receiver' {
            #todo
        }
        'vlc' {
            $url = "http://download.videolan.org/pub/videolan/vlc/"
            $html = Invoke-WebRequest -Uri "$url"

            $versionlinks = $html.Links | where href -match "^(\d+\.)?(\d+\.)?(\*|\d+)\/$" | Sort-Object -Property href -Descending
            $LatestAppVersion = $versionlinks[0].href -replace "/",""
        
        }
        'wincp' {
            #todo
        }
    }
    return [version]$LatestAppVersion
}

function Download-LatestAppVersion {
    param
    (
        [Parameter(Mandatory = $true,
        HelpMessage = 'What standard app are you trying to get the version of?')]
        [string]
        [ValidateSet('7zip','BigFix','Chrome','Firefox','Flash','GIMP','insync','Java','Notepad++','Putty','Reader','Receiver','VLC','WinSCP', IgnoreCase = $true)]
        $App
    )

    #Make Temp Download dir if it doesn't exist
    $DownloadDir = "$home\Downloads"
    if (!(Test-Path -Path "$DownloadDir\AppUpdates")) {
        Write-Host "$DownloadDir\AppUpdates didn't exist. Making Directory"
        New-Item -Path $DownloadDir -Name "AppUpdates" -ItemType Directory
    }
    $DownloadDir = "$home\Downloads\AppUpdates"

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
            $TempURLS32 = (Invoke-WebRequest -uri $SiteToScan).links | Where innerText -like “*Download*” | Where href -Like "*.msi" | select -First 2 | where href -NotLike "*x64*"
            $TempURLS64 = (Invoke-WebRequest -uri $SiteToScan).links | Where innerText -like “*Download*” | Where href -Like "*.msi" | select -First 2 | where href -Like "*x64*"

            $32bitDownload = $Domain + "/" + $TempURLS32.href
            $64bitdownload = $Domain + "/" + $TempURLS64.href

            # Build install filename
            $InstallFileName = $($32bitDownload.Split("/") | select -Last 1).Split(".") | select -First 1


            #32bit
            Invoke-WebRequest -Uri $32bitdownload -PassThru -OutFile "$DownloadDir\$($InstallFileName).msi"
            
            #64bit
            Invoke-WebRequest -Uri $64bitdownload -PassThru -OutFile "$DownloadDir\$($InstallFileName)-x64.msi"
        }
        'bigfix' {
            #todo
        }
        'chrome' {
            $64bitdownload = 'http://dl.google.com/edgedl/chrome/install/GoogleChromeStandaloneEnterprise64.msi'
            $32bitDownload = 'http://dl.google.com/edgedl/chrome/install/GoogleChromeStandaloneEnterprise.msi'
            $InstallFileName = "googlechromestandaloneenterprise"

            #32bit
            Invoke-WebRequest -Uri $32bitdownload -PassThru -OutFile "$DownloadDir\$($InstallFileName).msi"

            #64bit
            Invoke-WebRequest -Uri $64bitdownload -PassThru -OutFile "$DownloadDir\$($InstallFileName)64.msi"

        }
        'firefox' {
            $64bitdownload = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win64&lang=en-US"
            $32bitDownload = "https://download.mozilla.org/?product=firefox-latest-ssl&os=win&lang=en-US"
    
            #32bit
            $dl = Invoke-WebRequest -Uri $32bitdownload -PassThru -OutFile "$DownloadDir\ff32.tmp"
            $newAppVersion = Get-LatestAppVersion -App $App
            $InstallFileName = ($dl.BaseResponse.ResponseUri -split '/'|select -Last 1).split(" ") | select -First 2
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

            $MajorVersion = (Get-LatestAppVersion -App).Major
            $InstallFileName = "install_flash_player_$MajorVersion"
        }
        'gimp'{
            $url = "https://download.gimp.org/mirror/pub/gimp/"
            $html = Invoke-WebRequest -Uri "$url"

            $download = $html.Links | where innerHTML -like "*Download GIMP*directly*"

            $GIMP_Versions = $html.Links | where innerHTML -Match "v\d+\.\d+\.*\d*/"
            $GIMP_Versions = Sort-Object -InputObject $GIMP_Versions -Property innerHTML

            $Gimp_MinorVersionsUrl = $url + "$($GIMP_Versions[-1].href)" + "windows/"
            $html2 = Invoke-WebRequest -Uri $Gimp_MinorVersionsUrl
            $Gimp_MinorVersions = $html2.Links | where innerHTML -Match "gimp-\d+\.\d+\.*\d*-setup.+exe"

            $Gimp_MinorVersions = Sort-Object -InputObject $Gimp_MinorVersions -Property innerHTML

            if((($Gimp_MinorVersions[-1].innerHTML) -split "tor" | select -Last 1) -eq "rent"){
                $InstallFileName = $Gimp_MinorVersions[-2].href
            }
            else {
                $InstallFileName = $Gimp_MinorVersions[-1].href
            }

            $DownloadURL = $Gimp_MinorVersionsUrl + $InstallFileName
            Invoke-WebRequest -Uri $DownloadURL -OutFile "$DownloadDir\$InstallFileName"

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
            $url32 = ((Invoke-WebRequest -uri $SiteToScan).links | Where innerHTML -like “*Notepad++ Installer 32-bit*”).href
            $url64 = ((Invoke-WebRequest -uri $SiteToScan).links | Where innerHTML -like “*Notepad++ Installer 64-bit*”).href
 
            # Build URL to download file
            $32bitDownload = $Domain + $url32
            $64bitdownload = $Domain + $url64

            # Build install filename
            $newAppVersion = Get-LatestAppVersion -App $App
            $InstallFileName = "npp.$($newAppVersion).Installer"

            #32bit
            Invoke-WebRequest -Uri $32bitdownload -PassThru -OutFile "$DownloadDir\$($InstallFileName).exe"
            
            #64bit
            Invoke-WebRequest -Uri $64bitdownload -PassThru -OutFile "$DownloadDir\$($InstallFileName).x64.exe"

        }
        'putty' {
            # build URL to scan
            $SiteToScan = "https://www.chiark.greenend.org.uk/~sgtatham/putty/latest.html"
 
            # Scan URL to download file
            $32bitDownload = ((Invoke-WebRequest -uri $SiteToScan ).links | Where innerHTML -like “*putty*msi*”).href -notlike "*64bit*"
            $64bitdownload = ((Invoke-WebRequest -uri $SiteToScan ).links | Where innerHTML -like “*putty*msi*”).href -like "*64bit*"

            # Build install filename
            $newAppVersion = Get-LatestAppVersion -App $App
            $InstallFileName = "putty-$($newAppVersion)"

            #32bit
            Invoke-WebRequest -Uri "$32bitDownload" -OutFile "$DownloadDir\$($InstallFileName)-installer.msi"
            
            #64bit
            Invoke-WebRequest -Uri "$64bitdownload" -OutFile "$DownloadDir\$($InstallFileName)-64bit-installer.msi"
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
            $LatestUpdate = $DirList -split '[\r\n]' | Where {$_} | Select -Last 1 -Skip 1

            #build file name
            $InstallFileName = "AcroRdrDCUpd" + $LatestUpdate + ".msp"

            #build download url for latest file
            $DownloadURL = "$FTPFolderUrl$LatestUpdate/$InstallFileName"

            #download file
            (New-Object System.Net.WebClient).DownloadFile("$DownloadURL", "$DownloadDir\$InstallFileName")


        }
        'receiver' {
            #todo
        }
        'vlc' {
            $url = "http://download.videolan.org/pub/videolan/vlc/"

            $LatestAppVersion =  Get-LatestAppVersion -App $app

            $32bitDownload = $url + "$($LatestAppVersion)/win32/vlc-$($LatestAppVersion)-win32.msi"
            $64bitdownload = $url + "$($LatestAppVersion)/win64/vlc-$($LatestAppVersion)-win64.msi"

            # Build install filename
            $InstallFileName = "vlc-$($LatestAppVersion)"

            #32bit
            Invoke-WebRequest -Uri "$32bitDownload" -OutFile "$DownloadDir\$($InstallFileName)-win32.msi"
            
            #64bit
            Invoke-WebRequest -Uri "$64bitdownload" -OutFile "$DownloadDir\$($InstallFileName)-win64.msi"
        
        }
        'wincp' {
            #todo
        }
    }

    #Get the install files to return
    $InstallFiles = Get-ChildItem -Path "$DownloadDir\$InstallFileName*"
    return $InstallFiles

}