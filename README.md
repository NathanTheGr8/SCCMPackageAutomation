# SCCM-PackageAutomation

This is currently a rough but functional example. I hope you find it useful.



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
    
These imports should be handled automatically, but it seems to be buggy right now.


### Sources

Credit to the following

* [r/Powershell] - provided a lot of help creating functions.
* [auberginehill] - Learned how to get current flash versions from his GitHub
* [jasonadsit] - Was a big help writing the Download-LatestAppVersion -App Flash function
* [James C.] - Used his stackoverflow example to write the Adobe Reader function
* [DexterPOSH] - His blog post was the inspiration for the New-StandardChangeSCCMPackage function

### Todos

 - Write [Pester] Tests for functions
 - Handle downloads of Java, Citrix Reciever, and WinSCP.
 
License
----

MIT


   [Pester]: <https://github.com/pester/Pester>
   [r/Powershell] <https://www.reddit.com/r/PowerShell>
   [auberginehill] <https://github.com/auberginehill/update-adobe-flash-player/blob/master/Update-AdobeFlashPlayer.ps1>
   [jasonadsit] <https://gist.github.com/jasonadsit/c77340fe385fe953f9c54436b926cf83>
   [James C.] <https://stackoverflow.com/questions/48867426/script-to-download-latest-adobe-reader-dc-update>
   [DexterPOSH] <http://www.dexterposh.com/2015/08/powershell-sccm-2012-create-packages.html>
   