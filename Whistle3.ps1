<#
.SYNOPSIS
    Whistle 3 API
.DESCRIPTION
    PowerShell implementation copied from https://github.com/Fusion/pywhistle

    All bugs introduced by me.

    Feel free to submit a PR re-writing this as a module with error handling
.NOTES
    File Name      : Whistle3.ps1
    Author         : - j - o - h - n - a - t - j - o - r - e - . - n - o -
#>

[Hashtable]$user_config = @{username = "USERNAME" ; password = "PASSWORD"}

[Hashtable]$whistle_api_const = @{protocol='https'; remote_host='app.whistle.com'; endpoint='api'}

function Headers
{
    #Generate Header
    param(
        [String]$AccessToken
    )

    [Hashtable]$Headers = @{
        "Host" = $whistle_api_const.remote_host
        "Content-Type" = "application/json"
        "Accept" = "application/vnd.whistle.com.v4+json"
        "Accept-Language" = "en-us"
        "Accept-Encoding" = "br, gzip, deflate"
        "User-Agent" = "Winston/2.5.3 (iPhone; iOS 12.0.1; Build:1276; Scale/2.0)"
        "Authorization" = "Bearer " + $AccessToken
    }

    return $Headers
}

function APIRequest
{
    #Helper to retrieve a single resource, such as 'pet'
    param(
        [String]$Method,
        [String]$Resource,
        [HashTable]$Data = $null,
        [HashTable]$Headers = $null
    )
   
    $Result = Invoke-WebRequest -Uri "$($whistle_api_const.protocol)://$($whistle_api_const.remote_host)/$($whistle_api_const.endpoint)/$resource" -Method $Method -Body $Data -Headers $Headers

    if ($Resource -eq "login") {
        return $Result
    } else {
        return (([System.Text.Encoding]::UTF8.GetString($result.Content)) | ConvertFrom-Json)
    }
}

function login()
{
    #Attempts login with credentials. Returns authorization token for future requests.
    param (
        [Hashtable]$login_cred
    )
    $Result = APIRequest -Method POST -Resource login -Data @{email=$login_cred.username;password=$login_cred.password}
    return $($Result | ConvertFrom-Json | Select auth_token).auth_token
}

function get_pets
{
    #array of id, gender, name, profile_photo_url_sizes: dict of size(wxh):url, profile/breed, dob, address, etc.
    param(
        [String]$Token
    )
    return (APIRequest -Method GET -Resource "pets" -Headers $(Headers $Token)).pets
}

function get_owners
{
    #owners: array of id, first_name, last_name, current_user, searchable, email,profile_photo_url_sizes': dict of size (wxh): url
    param(
        [String]$Token,
        [Int]$pet_id
    )
    return (APIRequest -Method GET -Resource "pets/$pet_id/owners" -Headers $(Headers $Token)).owners
}

function get_places
{
    #array of address, name, id, latitude, longitude, radius_meters, shape, outline: array of lat/long if shape == polygon, per_ids: array of pet ids, wifi network information
    param(
        [String]$Token
    )
    return (APIRequest -Method GET -Resource "places" -Headers $(Headers $Token))
}

function get_stats
{
    #dict of average_minutes_active, average_minutes_rest, average_calories, average_distance, current_streak, longest_streak, most_active_day
    param(
        [String]$Token,
        [Int]$pet_id
    )
    return (APIRequest -Method GET -Resource "pets/$pet_id/stats" -Headers $(Headers $Token)).stats
    
}

function get_timeline
{
    #timeline_items: array of type ('inside'), data: dict of place: array of id, name start_time, end_time 
    #- or - 
    #type('outside'), data: dict of static_map_url: a google map url, origin, destination
    param(
        [String]$Token,
        [Int]$pet_id
    )
    return (APIRequest -Method GET -Resource "pets/$pet_id/timelines/location" -Headers $(Headers $Token)).timeline
}

function get_dailies
{
    #dailies: array of activity_goal, minutes_active, minutes_rest, calories, distance, day_number, excluded, timestamp, updated_at
    param(
        [String]$Token,
        [Int]$pet_id
    )
    return (APIRequest -Method GET -Resource "pets/$pet_id/dailies" -Headers $(Headers $Token)).dailies
}

function get_dailies_day
{
    #daily: dict of activities_goal, etc, bar_chart_18min: array of values async def get_dailies_day(self, pet_id, day_id):
    param(
        [String]$Token,
        [Int]$pet_id,
        [Int]$day_id
    )
    return (APIRequest -Method GET -Resource "pets/$pet_id/dailies/$day_id" -Headers $(Headers $Token)).daily
}

function get_achievements
{
    #achievements: array of id, earned_achievement_id, actionable, type, title, short_name, background_color, strike_color, badge_images: dict of size (wxh): url,
    #    template_type, template_properties: dict of header, footer, body, description (full text), earned, earned_timestamp, type_properties: dict of
    #    progressive_type, unit, goal_value, current_value, decimal_places
    param(
        [String]$Token,
        [Int]$pet_id
    )
    return (APIRequest -Method GET -Resource "pets/$pet_id/achievements" -Headers $(Headers $Token)).achievements
}

$AuthToken = login -login_cred $user_config
$Result = get_pets -Token $AuthToken
$pet_id = $result.id
$battery_level = $result.device.battery_level
$current_minutes_active = $result.activity_summary.current_minutes_active
$current_streak = $result.activity_summary.current_streak
$current_streak = $result.activity_summary.current_streak

Write-Host "$battery_level $current_minutes_active $current_streak"
