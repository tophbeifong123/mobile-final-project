# First-time Azure Student setup. Run from the repository root after `az login`.
# Passwords are written only to Key Vault. This script prints identifiers, not secrets.
$ErrorActionPreference = 'Stop'
$resourceGroup = 'internfinder-prod'
$locations = @('southeastasia', 'eastasia', 'australiaeast')
$repo = 'tophbeifong123/mobile-final-project'

function New-RandomSecret {
  $bytes = New-Object byte[] 32
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  return [Convert]::ToBase64String($bytes)
}

function Test-LocationError([string]$text) {
  return $text -match 'LocationNotAvailable|InvalidResourceLocation|not available|quota|RequestDisallowedByAzure|LocationIsOfferRestricted'
}

function Invoke-Az {
  param([string[]]$Arguments)
  $output = & az @Arguments 2>&1 | Out-String
  return @{ Code = $LASTEXITCODE; Text = $output }
}

function Write-ParameterFile {
  param(
    [string]$Path,
    [string]$Location,
    [bool]$IncludeApp,
    [string]$Password,
    [string]$Discord
  )
  $payload = [ordered]@{
    '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
    contentVersion = '1.0.0.0'
    parameters = [ordered]@{
      location = @{ value = $Location }
      includeApp = @{ value = $IncludeApp }
      postgresPassword = @{ value = $Password }
      discordWebhookUrl = @{ value = $Discord }
    }
  }
  $json = $payload | ConvertTo-Json -Depth 6
  [System.IO.File]::WriteAllText($Path, $json)
}

if (-not (Get-Command az -ErrorAction SilentlyContinue)) {
  throw 'Install the Azure CLI and run az login with the Azure for Students subscription.'
}

$chosen = $null
$postgresPassword = New-RandomSecret
$jwtSecret = New-RandomSecret
$sentryDsn = if ($env:SENTRY_DSN) { $env:SENTRY_DSN } else { 'disabled' }
$smtpPassword = if ($env:SMTP_PASSWORD) { $env:SMTP_PASSWORD } else { 'disabled' }
$discord = if ($env:DISCORD_WEBHOOK_URL) { $env:DISCORD_WEBHOOK_URL } else { '' }
$paramFile = Join-Path $env:TEMP 'internfinder-params.json'

foreach ($location in $locations) {
  Write-Host "Trying $location"
  $group = Invoke-Az @(
    'group', 'create',
    '--name', $resourceGroup,
    '--location', $location,
    '--output', 'none'
  )
  if ($group.Code -ne 0) {
    if (Test-LocationError $group.Text) { continue }
    Remove-Item $paramFile -Force -ErrorAction SilentlyContinue
    throw $group.Text
  }

  Write-ParameterFile -Path $paramFile -Location $location -IncludeApp $false -Password $postgresPassword -Discord $discord
  $deploy = Invoke-Az @(
    'deployment', 'group', 'create',
    '--resource-group', $resourceGroup,
    '--name', "internfinder-$location",
    '--template-file', 'infra/main.bicep',
    '--parameters', "@$paramFile",
    '--output', 'none'
  )
  if ($deploy.Code -eq 0) {
    $chosen = $location
    break
  }
  if (Test-LocationError $deploy.Text) { continue }
  Remove-Item $paramFile -Force -ErrorAction SilentlyContinue
  throw $deploy.Text
}

if (-not $chosen) {
  Remove-Item $paramFile -Force -ErrorAction SilentlyContinue
  throw 'None of southeastasia, eastasia, or australiaeast accepted this subscription.'
}

$names = az deployment group show `
  --resource-group $resourceGroup `
  --name "internfinder-$chosen" `
  --query properties.outputs `
  --output json | ConvertFrom-Json

$vault = $names.keyVaultName.value
Write-Host 'Waiting for Key Vault role assignment to propagate'
Start-Sleep -Seconds 30

function Set-VaultSecret {
  param([string]$Name, [string]$Value)
  $file = Join-Path $env:TEMP "ifnd-$Name.txt"
  [System.IO.File]::WriteAllText($file, $Value)
  az keyvault secret set --vault-name $vault --name $Name --file $file --output none
  $code = $LASTEXITCODE
  Remove-Item $file -Force
  if ($code -ne 0) {
    throw 'Key Vault rejected a secret. Wait a minute and run the secret commands from docs/OPERATIONS.md.'
  }
}

Set-VaultSecret -Name database-password -Value $postgresPassword
Set-VaultSecret -Name jwt-secret -Value $jwtSecret
Set-VaultSecret -Name sentry-dsn -Value $sentryDsn
Set-VaultSecret -Name smtp-password -Value $smtpPassword

Write-ParameterFile -Path $paramFile -Location $chosen -IncludeApp $true -Password $postgresPassword -Discord $discord
$app = Invoke-Az @(
  'deployment', 'group', 'create',
  '--resource-group', $resourceGroup,
  '--name', "internfinder-app-$chosen",
  '--template-file', 'infra/main.bicep',
  '--parameters', "@$paramFile",
  '--output', 'none'
)
Remove-Item $paramFile -Force -ErrorAction SilentlyContinue
if ($app.Code -ne 0) { throw $app.Text }

$appId = az ad app list --display-name internfinder-github --query '[0].appId' --output tsv
if (-not $appId) {
  $appId = az ad app create --display-name internfinder-github --query appId --output tsv
}
az ad sp create --id $appId --output none 2>$null
$principalId = az ad sp show --id $appId --query id --output tsv
$scope = az group show --name $resourceGroup --query id --output tsv
az role assignment create `
  --assignee-object-id $principalId `
  --assignee-principal-type ServicePrincipal `
  --role Contributor `
  --scope $scope `
  --output none 2>$null
$registryId = az acr show --name $names.registryName.value --query id --output tsv
az role assignment create `
  --assignee-object-id $principalId `
  --assignee-principal-type ServicePrincipal `
  --role AcrPush `
  --scope $registryId `
  --output none 2>$null

$credentials = @(
  @{ name = 'github-main'; subject = "repo:${repo}:ref:refs/heads/main" },
  @{ name = 'github-production'; subject = "repo:${repo}:environment:production" }
)
foreach ($credential in $credentials) {
  $body = @{
    name = $credential.name
    issuer = 'https://token.actions.githubusercontent.com'
    subject = $credential.subject
    audiences = @('api://AzureADTokenExchange')
  } | ConvertTo-Json
  $path = Join-Path $env:TEMP "$($credential.name).json"
  Set-Content -Path $path -Value $body -Encoding utf8
  az ad app federated-credential create --id $appId --parameters $path --output none 2>$null
  Remove-Item $path
}

$subscription = az account show --query id --output tsv
$tenant = az account show --query tenantId --output tsv

Write-Host ''
Write-Host "Location: $chosen"
Write-Host 'Add these GitHub Actions secrets. Do not commit them.'
Write-Host "AZURE_CLIENT_ID=$appId"
Write-Host "AZURE_TENANT_ID=$tenant"
Write-Host "AZURE_SUBSCRIPTION_ID=$subscription"
Write-Host "AZURE_REGISTRY_NAME=$($names.registryName.value)"
Write-Host "AZURE_RESOURCE_GROUP=$resourceGroup"
Write-Host "AZURE_CONTAINER_APP_NAME=$($names.containerAppName.value)"
Write-Host "Key Vault: $vault"
Write-Host 'The API stays unhealthy until the first image from main replaces the placeholder.'
