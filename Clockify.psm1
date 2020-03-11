# BC for < PS v3
if(!$PSScriptRoot) { $PSScriptRoot = Split-Path -parent $MyInvocation.MyCommand.Path; }
Set-Location $PSScriptRoot;

# Get the Clockify API key
$apiKey = Get-Content -Raw -Path "Clockify.key";

function Stop-Clock
{
    # Get user info
    $resp = Invoke-WebRequest -Headers @{ "X-Api-Key" = $apiKey } -ContentType "application/json" -Uri "https://api.clockify.me/api/v1/user"
    $clockifyUser = ConvertFrom-Json $resp.Content;
    $defaultWorkspace = $clockifyUser.defaultWorkspace;
    $clockifyUserId = $clockifyUser.id;

    # Set end time to now UTC/Zulu time format
    $endTime = @{ end = [DateTime]::UtcNow.ToString("yyyy-MM-ddThh:mm:ssZ") };
    $endTimeJson = ConvertTo-Json $endTime;

    # Update the time entry on the server
    Invoke-WebRequest -Headers @{ "X-Api-Key" = $apiKey } -ContentType "application/json" -Method PATCH -Uri "https://api.clockify.me/api/v1/workspaces/$defaultWorkspace/user/$clockifyUserId/time-entries" -Body $endTimeJson;
}