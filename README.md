# SCCM-PackageAutomation

This is currently a rough but functional example. I hope you find it useful.

The goal of this repo is to fully automate the maintaining of SCCM packages. I mostly scrape the download websites directly and don't rely on 3rd Party services. All of the install binaries are downloaded directly from the vendor site. 

There are two main functions Update-AppPackage and New-StandardChangeSCCMPackages. The cmdlet names probally need to change to show they are related.

Update-AppPackage accepts a app name from a predfined list of about a dozen apps. It then goes out and downloads the latest version of that app from the vendor's website. It then copies the latest source files for application x and makes a new folder called "X Version# (R#)". It then deletes all the install files in the "X Version# (R#)\Files" directory and copies the new install files to that directory. It then updates the deploy-application.ps1's $appversion barible to the latest version. There are a lot of checks and error handling thrown in. The function is also pretty verbose and writes out what it is doing.
```powershell
PS C:\Users\davisn1\Documents\Projects\HM-Functions> Update-AppPackage -App Firefox
P Drive to SCCM Exists already
Firefox 62.0.2 package is already up to date

PS C:\Users\davisn1\Documents\Projects\HM-Functions> Update-AppPackage -App Firefox -ForceUpdate
P Drive to SCCM Exists already
Forcing update of Firefox from 62.0.2 to 62.0.2
'Firefox 62.0.2 (R1)' already exists, auto incrementing the R#
Creating folder 'Firefox 62.0.2 (R2)'
Copying old package files to \\serversccm01\Packages\HOME OFFICE\Mozilla FireFox\Firefox 62.0.2 (R2)
Removing old install files
Copying new install files
VERBOSE: Performing the operation "Copy File" on target "Item: C:\Users\davisn1\Downloads\AppUpdat
es\Firefox Setup 62.0.2-32bit.exe Destination: \\serversccm01\Packages\HOME OFFICE\Mozilla FireFox\F
irefox 62.0.2 (R2)\Files\Firefox Setup 62.0.2-32bit.exe".
VERBOSE: Performing the operation "Copy File" on target "Item: C:\Users\davisn1\Downloads\AppUpdat
es\Firefox Setup 62.0.2-64bit.exe Destination: \\serversccm01\Packages\HOME OFFICE\Mozilla FireFox\F
irefox 62.0.2 (R2)\Files\Firefox Setup 62.0.2-64bit.exe".
Updating version numbers from 62.0.2 to 62.0.2
```
The next function is New-StandarChangeSCCMPackage. This function creates an SCCM package from the latest folder for a give app, makes the install program, distributes the package to DPs, and updates my "Not Curren Version Collection" for a given app. I would also like to deploy the package to a test collection, but I can't get the Start-CMApplicationDeployment cmdlet to work with my version of sccm.



### Installation

Edit the GlobalVariables.ps1 file to work with your enviroment.
 - $SCCM_Site : Your SCCM Site Code
 - $SCCM_Share : A UNC path to the newtork share where your SCCM packages are.
 - $SCCM_Share_Test_Folder : A Folder Name (Not full path) that should exist on your SCCM share
 - $SCCM_Share_Letter : What drive letter do you want your SCCM share mounted under?
 - All the $$rootApplicationPath in Get-RootApplicationPath

You will also have to change the
 - New-StandardChangeSCCMPackage Update-AppHelper $SCCMFolder Parms.
	- HomeOffice
	- CoreApps
	- Misc


SCCM-PackageAutomation requires the following Powershell Modules
   
 - For SCCM functions you also need
    - The SCCM Management console installed
    - The SCCM cmdlet library
    
These imports should be handled automatically, but it seems to be buggy right now. The Add-CMDeviceCollectionQueryMembershipRule seems to not work without a manuel import.

Powershell App Deployment Toolkit (PSADT)
  - I assume all packages are PSADT packages and install files are in the files directory.
  - I asssume you have Deploy-Application.ps1 at the root folder of the package.


### Sources

Credit to the following

* [r/Powershell](https://www.reddit.com/r/PowerShell)- provided a lot of help creating functions.
* [auberginehill](https://github.com/auberginehill/update-adobe-flash-player/blob/master/Update-AdobeFlashPlayer.ps1) - Learned how to get current flash versions from his GitHub
* [jasonadsit](https://gist.github.com/jasonadsit/c77340fe385fe953f9c54436b926cf83) - Was a big help writing the Download-LatestAppVersion -App Flash function
* [James C.](https://stackoverflow.com/questions/48867426/script-to-download-latest-adobe-reader-dc-update) - Used his stackoverflow example to write the Adobe Reader function
* [DexterPOSH](http://www.dexterposh.com/2015/08/powershell-sccm-2012-create-packages.html) - His blog post was the inspiration for the New-StandardChangeSCCMPackage function

### Todos

 - Write [Pester](https://github.com/pester/Pester) Tests for functions
 - Handle downloads of Java, Citrix Reciever
 
License
----

MIT

   