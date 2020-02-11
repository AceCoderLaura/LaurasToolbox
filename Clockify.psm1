# BC for < PS v3
if(!$PSScriptRoot) { $PSScriptRoot = Split-Path -parent $MyInvocation.MyCommand.Path; }
Set-Location $PSScriptRoot;

# Get the Clockify API key
$apiKey = Get-Content -Raw -Path "Clockify.key";