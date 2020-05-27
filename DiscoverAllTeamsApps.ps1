


$clientId = "25e730c4-3859-4619-b1d5-bd41ffbd9634"
$clientSecret = ""
$tenantName = "M365x107527.OnMicrosoft.com"
$allEmployeesGroupId = "" #use this as the Azure AD group (can be sync'ed or cloud only) that contains all of the users we want to enumerate for custom Teams apps

$ReqTokenBody = @{
    Grant_Type    = "client_credentials"
    Scope         = "https://graph.microsoft.com/.default"
    client_Id     = $clientID
    Client_Secret = $clientSecret
} 
$TokenResponse = Invoke-RestMethod -Uri "https://login.microsoftonline.com/$TenantName/oauth2/v2.0/token" -Method POST -Body $ReqTokenBody

$getAllGroupsApiUrl = "https://graph.microsoft.com/beta/groups?`$filter=resourceProvisioningOptions/Any(x:x eq 'Team')"



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


$allTeamsApps | Group-Object -Property  DisplayName | Out-GridView

