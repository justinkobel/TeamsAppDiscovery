
<#
DISCLAIMER: 
----------------------------------------------------------------
This sample is provided as is and is not meant for use on a production environment.
It is provided only for illustrative purposes. The end user must test and modify the
sample to suit their target environment. 
The script author can make no representation concerning the content of this script. 
#>

<#
INSTRUCTIONS:
Please see https://github.com/justinkobel/TeamsAppDiscovery
#>

$clientId = "8f8de7db-273c-4190-9559-ee59167d176b" #appID from AAD app registration
$clientSecret = "" #client secret from AAD app registration. see readme.md for required permissions
$tenantName = "kizan.onmicrosoft.com" #insert your AAD tenant name here

$ReqTokenBody = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    client_Id     = $clientID
    Client_Secret = $clientSecret
} 
$TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody

$getAllGroupsApiUrl = "https://graph.microsoft.com/beta/groups?`$filter=resourceProvisioningOptions/Any(x:x eq 'Team')"

$getAllMembersOfGroupApiUrl = "https://graph.microsoft.com/v1.0/users?`$filter=userType eq 'Member'"

function Invoke-GraphQuery {
    param (
        [String]$Uri
    )

    $resp = Invoke-RestMethod -Headers @{Authorization = "Bearer $($Tokenresponse.access_token)"} -Uri $uri -Method Get -ContentType 'application/json'
    return $resp
}

$allTeams = Invoke-GraphQuery -Uri $getAllGroupsApiUrl

$allTeamsApps = New-Object -TypeName "System.Collections.ArrayList"

do {

    $allTeams.value | ForEach-Object {

        $teamId = $_.id
        $teamName = $_.DisplayName
    
        $teamsAppsApiUrl = "https://graph.microsoft.com/beta/teams/$teamId/installedApps?`$expand=teamsAppDefinition"
    
        $teamsApps = Invoke-GraphQuery -Uri $teamsAppsApiUrl
    
        $teamsApps.value | ForEach-Object {
            $app = $_
    
            $installedTeamApp = New-Object -TypeName PSObject
            $installedTeamApp| Add-Member -Name "AppInstalledId" -Value $app.Id -MemberType NoteProperty 
            $installedTeamApp | Add-Member -Name "DisplayName" -MemberType NoteProperty  -Value $app.teamsAppDefinition.DisplayName
            $installedTeamApp | Add-Member -Name "TeamsAppId" -Value $app.teamsAppDefinition.teamsAppId -MemberType NoteProperty
            $installedTeamApp | Add-Member -Name "TeamId" -MemberType NoteProperty  -Value $teamId
            $installedTeamApp | Add-Member -Name "TeamDisplayName" -MemberType NoteProperty -Value $teamName
    
            $allTeamsApps.Add($installedTeamApp)
            
        }
    }
    
    if($null -ne $allteams.'@odata.nextLink') {
        $allTeams = Invoke-GraphQuery -Uri $allTeams.'@odata.nextLink'
        $moreTeamsToEnum = $true
    }
    else {
        $moreTeamsToEnum = $false
    }

} while ($moreTeamsToEnum)

#to-do user enumeration and teams apps discovery per user
$allUserApps = New-Object -TypeName "System.Collections.ArrayList"

$allUsers = Invoke-GraphQuery -Uri $getAllMembersOfGroupApiUrl
$usersToEnum = $true

do {
    $allUsers.value | ForEach-Object {

        $userId = $_.id
        $userEmail = $_.mail

        $userAppsApiUrl = "https://graph.microsoft.com/beta/users/$userId/teamwork/installedApps?`$expand=teamsAppDefinition"

        $userApps = Invoke-GraphQuery $userAppsApiUrl

        $userApps.value | ForEach-Object {
            $app = $_

            $installedUserApp = New-Object -TypeName PSObject
            $installedUserApp| Add-Member -Name "AppInstalledId" -Value $app.Id -MemberType NoteProperty 
            $installedUserApp | Add-Member -Name "DisplayName" -MemberType NoteProperty  -Value $app.teamsAppDefinition.DisplayName
            $installedUserApp | Add-Member -Name "TeamsAppId" -Value $app.teamsAppDefinition.teamsAppId -MemberType NoteProperty
            $installedUserApp | Add-Member -Name "User" -MemberType NoteProperty  -Value $userId
            $installedUserApp | Add-Member -Name "UserEmail" -MemberType NoteProperty -Value $userEmail
    
            $allUserApps.Add($installedUserApp)
        }

        if($null -ne $allUsers.'@odata.nextLink') {
            $allUsers = Invoke-GraphQuery -Uri $allUsers.'@odata.nextLink'
            $usersToEnum = $true
        }
        else {
            $usersToEnum = $false
        }
    }
} while($usersToEnum)

$allTeamsApps | Group-Object -Property  DisplayName | Out-GridView

$allUserApps | Group-Object -Property DisplayName | Out-GridView

