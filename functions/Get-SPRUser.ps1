﻿Function Get-SPRUser {
<#
.SYNOPSIS
    Returns a SharePoint user object.

.DESCRIPTION
    Returns a SharePoint user object.

.PARAMETER Site
    The address to the site collection. You can also pass a hostname and it'll figure it out.

    Don't want to specify the Site or Credential every time? Use Connect-SPRSite to create a reusable connection.
    See Get-Help Connect-SPRsite for more information.

.PARAMETER Credential
    Provide alternative credentials to the site collection. Otherwise, it will use default credentials.

.PARAMETER UserName
    The human readable user name. So 'My User' as opposed to 'MyUser', unless you named it MyUser.

.PARAMETER InputObject
    Allows piping from Connect-SPRSite

.PARAMETER EnableException
    By default, when something goes wrong we try to catch it, interpret it and give you a friendly warning message.
    This avoids overwhelming you with "sea of red" exceptions, but is inconvenient because it basically disables advanced scripting.
    Using this switch turns this "nice by default" feature off and enables you to catch exceptions with your own try/catch.

.EXAMPLE
    Get-SPRUser -Site intranet.ad.local -UserName 'My User'

    Creates a web service object for My User on intranet.ad.local. Figures out the wsdl address automatically.

.EXAMPLE
    Connect-SPRSite -Site intranet.ad.local | Get-SPRUser -UserName 'My User'

    Creates a web service object for My User on intranet.ad.local. Figures out the wsdl address automatically.

.EXAMPLE
    Get-SPRUser -Site intranet.ad.local -UserName 'My User' -Credential ad\user

    Creates a web service object for My User and logs into the webapp as ad\user.
#>
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, HelpMessage = "Human-readble SharePoint user name")]
        [string[]]$UserName,
        [Parameter(Position = 1, HelpMessage = "SharePoint Site Collection")]
        [string]$Site,
        [PSCredential]$Credential,
        [parameter(ValueFromPipeline)]
        [object[]]$InputObject,
        [switch]$EnableException
    )
    process {
        if (-not $InputObject) {
            if ($Site) {
                $null = Connect-SPRSite -Site $Site -Credential $Credential
                $InputObject = Get-SPRWeb
            }
            elseif ($script:spweb) {
                $InputObject = $script:spweb
            }
            else {
                Stop-PSFFunction -EnableException:$EnableException -Message "You must specify Site or run Connect-SPRSite"
                return
            }
        }
        else {
            if ($InputObject[0] -is [Microsoft.SharePoint.Client.User]) {
                $UserName = $InputObject.LoginName
                $InputObject = $script:spweb
            }
        }
        
        foreach ($web in $InputObject) {
            if (-not $UserName) {
                try {
                    $users = $web.SiteUsers
                    $script:spsite.Load($users)
                    $script:spsite.ExecuteQuery()
                    # exclude: Groups, AadObjectId, IsEmailAuthenticationGuestUser, IsHiddenInUI, IsShareByEmailGuestUser, Path, ObjectVersion, ServerObjectIsNull, UserId, TypedObject, Tag 
                    if ((Get-PSFConfigValue -FullName SPReplicator.Location) -ne "Online") {
                        $users = $users | Select-Object -ExcludeProperty Alerts
                    }
                    $users | Select-DefaultView -Property Id, Title, LoginName, Email, IsSiteAdmin, PrincipalType
                }
                catch {
                    Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                }
            }
            else {
                foreach ($user in $UserName) {
                    try {
                        Write-PSFMessage -Level Verbose -Message "Getting $user from $($script:spsite.Url)"
                        $ensureduser = $script:spweb.EnsureUser($user)
                        $script:spsite.Load($ensureduser)
                        $script:spsite.ExecuteQuery()
                        Write-PSFMessage -Level Verbose -Message "Got $user from $($script:spsite.Url)"
                        
                        if ($ensureduser) {
                            Add-Member -InputObject $ensureduser -MemberType ScriptMethod -Name ToString -Value { $this.LoginName } -Force
                            
                            # exclude: Groups, AadObjectId, IsEmailAuthenticationGuestUser, IsHiddenInUI, IsShareByEmailGuestUser, Path, ObjectVersion, ServerObjectIsNull, UserId, TypedObject, Tag 
                            if ((Get-PSFConfigValue -FullName SPReplicator.Location) -eq "Online") {
                                $ensureduser | Select-Object -ExcludeProperty Alerts | Select-DefaultView -Property Id, Title, LoginName, Email, IsSiteAdmin, PrincipalType
                            }
                            else {
                                $ensureduser | Select-DefaultView -Property Id, Title, LoginName, Email, IsSiteAdmin, PrincipalType
                            }
                        }
                    }
                    catch {
                        Stop-PSFFunction -EnableException:$EnableException -Message "Failure" -ErrorRecord $_
                    }
                }
            }
        }
    }
}