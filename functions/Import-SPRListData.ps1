﻿Function Import-SPRListData {
<#
.SYNOPSIS
    Imports all items from a file into a SharePoint list.
    
.DESCRIPTION
    Imports all items from a file into a SharePoint list.
    
    To import from any other types of objects, use Add-SPRListItem.
    
.PARAMETER Uri
    The address to the site collection. You can also pass a hostname and it'll figure it out.
    
    Don't want to specify the Uri or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.
 
.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials. 
 
.PARAMETER ListName
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.
  
.PARAMETER Path
    The target xml file location.
    
.PARAMETER AutoCreateList
    Nothing yet - placeholder/reminder

.PARAMETER InputObject
    Allows piping from Get-ChildItem
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Import-SPRListData -Uri intranet.ad.local -ListName 'My List' -Path C:\temp\mylist.xml

    Imports all items from C:\temp\mylist.xml to My List on intranet.ad.local
    
.EXAMPLE
    Get-SPRListData -Path C:\temp\mylist.xml | Import-SPRListData -ListName 'My List' -Uri intranet.ad.local

    Imports all items from C:\temp\mylist.xml to My List on intranet.ad.local
#>
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Uri,
        [PSCredential]$Credential,
        [Parameter(Mandatory, HelpMessage = "Human-readble SharePoint list name")]
        [string]$ListName,
        [string]$Path,
        [switch]$AutoCreateList,
        [parameter(ValueFromPipeline)]
        [System.IO.FileInfo[]]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Path) {
                try {
                    $InputObject = Get-ChildItem -Path $Path -ErrorAction Stop
                }
                catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                    return
                }
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Path pipe in the results of Get-ChildItem"
                return
            }
        }
        foreach ($file in $InputObject) {
            try {
                Import-Clixml -Path $file | Add-SPRListItem -Uri $Uri -Credential $Credential -ListName $ListName
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_ -Continue
            }
        }
    }
}