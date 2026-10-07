# First-time Azure Student setup. Run from the repository root after `az login`.
# Passwords are written only to Key Vault. This script prints identifiers, not secrets.
$ErrorActionPreference = 'Stop'
$resourceGroup = 'internfinder-prod'
# Azure for Students on this subscription allows these regions only.
$locations = @('eastasia', 'koreacentral', 'japanwest', 'malaysiawest', 'indonesiacentral')
$repo = 'tophbeifong123/mobile-final-project'

function New-RandomSecret {
  $bytes = New-Object byte[] 32
  [System.Security.Cryptography.RandomNumberGenerator]::Create().GetBytes($bytes)
  return [Convert]::ToBase64String($bytes)
}

function Test-LocationError([string]$text) {
  return $text -match 'LocationNotAvailable|InvalidResourceLocation|InvalidResourceGroupLocation|not available|quota|RequestDisallowedByAzure|LocationIsOfferRestricted'
}

function Remove-EmptyGroup {
  $listed = Invoke-Az @('resource', 'list', '--resource-group', $resourceGroup, '--output', 'json')
  if ($listed.Code -ne 0) { throw $listed.Text }
  $body = $listed.Text.Trim()
  if ($body -and $body -ne '[]') {
    $resources = $body | ConvertFrom-Json
    if (@($resources).Count -gt 0) {
      throw "Resource group $resourceGroup already has resources. Refusing to delete it while changing region."
    }
  }
  Write-Host "Removing empty resource group $resourceGroup"
  $deleted = Invoke-Az @('group', 'delete', '--name', $resourceGroup, '--yes', '--output', 'none')
  if ($deleted.Code -ne 0) { throw $deleted.Text }
}

function Invoke-Az {
  param([string[]]$Arguments)
  $previous = $ErrorActionPreference
  $ErrorActionPreference = 'Continue'
  try {
    $lines = & az @Arguments 2>&1 | ForEach-Object { "$_" }
    return @{ Code = $LASTEXITCODE; Text = ($lines -join "`n") }
  } finally {
    $ErrorActionPreference = $previous
  }
}

function Write-ParameterFile {
  param(
    [string]$Path,
    [string]$Location,
    [bool]$IncludeApp,
    [string]$Password,
    [string]$Jwt,
    [string]$Sentry,
    [string]$Smtp,
    [string]$Discord,
    [string]$AcrPull = ''
  )
  $payload = [ordered]@{
    '$schema' = 'https://schema.management.azure.com/schemas/2019-04-01/deploymentParameters.json#'
    contentVersion = '1.0.0.0'
    parameters = [ordered]@{
      location = @{ value = $Location }
      includeApp = @{ value = $IncludeApp }
      postgresPassword = @{ value = $Password }
      jwtSecret = @{ value = $Jwt }
      sentryDsn = @{ value = $Sentry }
      smtpPassword = @{ value = $Smtp }
      discordWebhookUrl = @{ value = $Discord }
      acrPullPassword = @{ value = $AcrPull }
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
    if (Test-LocationError $group.Text) {
      Write-Host $group.Text
      Remove-EmptyGroup
      $group = Invoke-Az @(
        'group', 'create',
        '--name', $resourceGroup,
        '--location', $location,
        '--output', 'none'
      )
    }
    if ($group.Code -ne 0) {
      Remove-Item $paramFile -Force -ErrorAction SilentlyContinue
      throw $group.Text
    }
  }

  Write-ParameterFile -Path $paramFile -Location $location -IncludeApp $false -Password $postgresPassword -Jwt $jwtSecret -Sentry $sentryDsn -Smtp $smtpPassword -Discord $discord
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
  if (Test-LocationError $deploy.Text) {
    Write-Host $deploy.Text
    Remove-EmptyGroup
    continue
  }
  Remove-Item $paramFile -Force -ErrorAction SilentlyContinue
  throw $deploy.Text
}

if (-not $chosen) {
  Remove-Item $paramFile -Force -ErrorAction SilentlyContinue
  throw 'None of the regions allowed by this Azure for Students subscription accepted the deployment.'
}

$names = az deployment group show `
  --resource-group $resourceGroup `
  --name "internfinder-$chosen" `
  --query properties.outputs `
  --output json | ConvertFrom-Json

$vault = $names.keyVaultName.value
$vaultId = az keyvault show --name $vault --query id --output tsv
$userId = az ad signed-in-user show --query id --output tsv
if ($LASTEXITCODE -ne 0 -or -not $userId) {
  throw 'Could not resolve the signed-in user for Key Vault access.'
}
az role assignment create `
  --assignee-object-id $userId `
  --assignee-principal-type User `
  --role 'Key Vault Secrets Officer' `
  --scope $vaultId `
  --output none
if ($LASTEXITCODE -ne 0) {
  $existing = az role assignment list --assignee $userId --scope $vaultId --role 'Key Vault Secrets Officer' --query '[0].id' --output tsv
  if (-not $existing) {
    throw 'Could not grant Key Vault Secrets Officer to the signed-in user.'
  }
}
Write-Host 'Waiting for Key Vault role assignment to propagate'
Start-Sleep -Seconds 30

function Set-VaultSecret {
  param([string]$Name, [string]$Value)
  $file = Join-Path $env:TEMP "ifnd-$Name.txt"
  [System.IO.File]::WriteAllText($file, $Value)
  $code = 1
  foreach ($attempt in 1..8) {
    az keyvault secret set --vault-name $vault --name $Name --file $file --output none
    $code = $LASTEXITCODE
    if ($code -eq 0) { break }
    Write-Host "Key Vault is not ready for $Name yet. Attempt $attempt of 8."
    Start-Sleep -Seconds 20
  }
  Remove-Item $file -Force
  if ($code -ne 0) {
    throw 'Key Vault rejected a secret. Wait a minute and run the secret commands from docs/OPERATIONS.md.'
  }
}

Set-VaultSecret -Name database-password -Value $postgresPassword
Set-VaultSecret -Name jwt-secret -Value $jwtSecret
Set-VaultSecret -Name sentry-dsn -Value $sentryDsn
Set-VaultSecret -Name smtp-password -Value $smtpPassword

$registry = $names.registryName.value
$pullToken = 'internfinder-api-pull'
az acr scope-map create --name $pullToken --registry $registry --repository internfinder-api content/read metadata/read --output none 2>$null
az acr token create --name $pullToken --registry $registry --scope-map $pullToken --output none 2>$null
$acrPullPassword = az acr token credential generate --name $pullToken --registry $registry --password1 --query 'passwords[0].value' --output tsv 2>$null
if ($LASTEXITCODE -ne 0 -or -not $acrPullPassword) {
  throw 'Could not create the registry pull token.'
}

Write-ParameterFile -Path $paramFile -Location $chosen -IncludeApp $true -Password $postgresPassword -Jwt $jwtSecret -Sentry $sentryDsn -Smtp $smtpPassword -Discord $discord -AcrPull $acrPullPassword.Trim()
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
$repoMeta = gh api "repos/$repo" | ConvertFrom-Json
if ($repoMeta.id -and $repoMeta.owner.id) {
  $ownerId = $repoMeta.owner.id
  $repoId = $repoMeta.id
  $qualified = "$($repoMeta.owner.login)@${ownerId}/$($repoMeta.name)@${repoId}"
  $credentials += @(
    @{ name = 'github-main-id'; subject = "repo:${qualified}:ref:refs/heads/main" },
    @{ name = 'github-production-id'; subject = "repo:${qualified}:environment:production" }
  )
}
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
