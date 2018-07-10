Function Get-SPRListData {
<#
.SYNOPSIS
    Returns data from a SharePoint list.
    
.DESCRIPTION
    Returns data from a SharePoint list.
    
.PARAMETER Uri
    The address to the site collection. You can also pass a hostname and it'll figure it out.
    
    Don't want to specify the Uri or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.
    
.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials. 
    
.PARAMETER ListName
    The human readable list name. So 'My List' as opposed to 'MyList', unless you named it MyList.
 
.PARAMETER Id
    Return only rows with specific IDs

.PARAMETER InputObject
    Allows piping from Get-SPRList 
    
.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.
 
.EXAMPLE
    Get-SPRListData -Uri intranet.ad.local -ListName 'My List'

    Gets data from My List on intranet.ad.local. Figures out the wsdl address automatically.
    
.EXAMPLE
    Get-SPRList -ListName 'My List' -Uri intranet.ad.local | Get-SPRListData

     Gets data from My List on intranet.ad.local.
    
.EXAMPLE
    Get-SPRListData -Uri intranet.ad.local -ListName 'My List' -Credential (Get-Credential ad\user)

    Gets data from My List and logs into the webapp as ad\user.
    
.EXAMPLE    
    Get-SPRListData -Uri sharepoint2016 -ListName 'My List' -Id 100, 101, 105
    
    Gets list items with ID 100, 101 and 105
#>
    [CmdletBinding()]
    param (
        [Parameter(HelpMessage = "SharePoint Site Collection")]
        [string]$Uri,
        [PSCredential]$Credential,
        [Parameter(HelpMessage = "Human-readble SharePoint list name")]
        [string]$ListName,
        [int[]]$Id,
        [parameter(ValueFromPipeline)]
        [object]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Uri) {
                $InputObject = Get-SprList -Uri $Uri -Credential $Credential -ListName $ListName
            }
            elseif ($global:spsite) {
                $InputObject = $global:spsite | Get-SPRList -ListName $ListName
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Uri and ListName pipe in results from Get-SPRList"
                return
            }
        }
        
        foreach ($list in $InputObject) {
            try {
                Write-PSFMessage -Level Verbose -Message "Performing GetItems"
                if ($Id) {
                    foreach ($number in $Id) {
                        $listItems = $list.GetItemById($number)
                    }
                }
                else {
                    $listItems = $list.GetItems([Microsoft.SharePoint.Client.CamlQuery]::CreateAllItemsQuery())
                }
                
                $list.Context.Load($listItems)
                $list.Context.ExecuteQuery()
                $fields = $listItems | Select-Object -First 1 -ExpandProperty FieldValues
                $baseobject = [pscustomobject]@{ }
                
                foreach ($column in $fields.Keys) {
                    Add-Member -InputObject $baseobject -NotePropertyName $column -NotePropertyValue $null
                }
                Add-Member -InputObject $baseobject -NotePropertyName ListObject -NotePropertyValue $null
                Add-Member -InputObject $baseobject -NotePropertyName ListItem -NotePropertyValue $null
                
                foreach ($item in $listItems) {
                    $object = $baseobject.PSObject.Copy()
                    $object.ListObject = $list
                    $object.ListItem = $item
                    foreach ($fieldName in $item.FieldValues.Keys) {
                        $object.$fieldName = $item.FieldValues[$fieldName]
                    }
                    Select-DefaultView -InputObject $object -ExcludeProperty _HasCopyDestinations, _CopySource, owshiddenversion, WorkflowVersion, _UIVersion, _UIVersionString, _ModerationStatus, _ModerationComments, InstanceID, WorkflowInstanceID, Last_x0020_Modified, Created_x0020_Date, FSObjType, SortBehavior, FileLeafRef, UniqueId, SyncClientId, ProgId, ScopeId, File_x0020_Type, MetaInfo, _Level, _IsCurrentVersion, ItemChildCount, FolderChildCount, Restricted, AppAuthor, AppEditor
                }
            }
            catch {
                Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
            }
        }
    }
}