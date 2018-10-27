function Get-CurrentAppVersion {
<#
.SYNOPSIS

Gets the current app version for a given app
.DESCRIPTION

Gets the current app package version for a given app. Uses the Get-PSADTAppVersion function to get the version
.PARAMETER App

The App you want the version of.
.EXAMPLE

Get-CurrentAppVersion -App Firefox
#>
    [CmdletBinding()]
    param 
    (
    )
    DynamicParam {
        #Example from https://mcpmag.com/articles/2016/10/06/implement-dynamic-parameters.aspx
        $ParamAttrib = New-Object System.Management.Automation.ParameterAttribute
        $ParamAttrib.Mandatory  = $true
        $ParamAttrib.ParameterSetName  = '__AllParameterSets'

        $AttribColl = New-Object  System.Collections.ObjectModel.Collection[System.Attribute]
        $AttribColl.Add($ParamAttrib)
        $AttribColl.Add((New-Object  System.Management.Automation.ValidateSetAttribute($global:Apps)))

        $RuntimeParam = New-Object System.Management.Automation.RuntimeDefinedParameter('App',  [string], $AttribColl)

        $RuntimeParamDic = New-Object System.Management.Automation.RuntimeDefinedParameterDictionary
        $RuntimeParamDic.Add('App',  $RuntimeParam)

        return  $RuntimeParamDic
    }

    process {
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
}