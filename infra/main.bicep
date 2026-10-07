targetScope = 'resourceGroup'

@description('Azure region. Bootstrap tries the regions allowed by Azure for Students, starting with eastasia.')
param location string = 'eastasia'

@description('Create the Container App. The bootstrap script enables this only after Key Vault secrets exist.')
param includeApp bool = false

@description('Container image. The first real image is published by GitHub Actions.')
param image string = 'mcr.microsoft.com/k8se/quickstart:latest'

@secure()
param postgresPassword string

@description('ACR token limited to pulling internfinder-api. Express environments cannot pull with a managed identity.')
param acrPullUsername string = 'internfinder-api-pull'

@secure()
param acrPullPassword string = ''

@secure()
@description('Copied into the Container App because Express environments cannot reference Key Vault.')
param jwtSecret string = ''

@secure()
param sentryDsn string = ''

@secure()
param smtpPassword string = ''

@description('Discord incoming webhook. Alerts are skipped when this is empty.')
@secure()
param discordWebhookUrl string = ''

var token = uniqueString(resourceGroup().id)
var storageAccountName = 'ifnd${token}'
var registryName = 'ifndacr${take(token, 8)}'
var keyVaultName = 'ifnd-kv-${take(token, 8)}'
var postgresName = 'ifnd-pg-${take(token, 10)}'
var containerAppName = 'internfinder-api'
var logAnalyticsName = 'internfinder-logs'
var environmentName = 'internfinder-env'
var identityName = 'internfinder-app'
var blobDataContributor = 'ba92f5b4-2d11-453d-a403-e96b0029c9fe'
var keyVaultSecretsUser = '4633458b-17de-408a-b874-0445c86b69e6'
var acrPull = '7f951dda-4ed3-4680-a7ca-43fe172d538d'

resource identity 'Microsoft.ManagedIdentity/userAssignedIdentities@2023-01-31' = {
  name: identityName
  location: location
}

resource logAnalytics 'Microsoft.OperationalInsights/workspaces@2023-09-01' = {
  name: logAnalyticsName
  location: location
  properties: {
    sku: { name: 'PerGB2018' }
    retentionInDays: 30
    workspaceCapping: { dailyQuotaGb: json('0.5') }
  }
}

resource registry 'Microsoft.ContainerRegistry/registries@2023-07-01' = {
  name: registryName
  location: location
  sku: { name: 'Basic' }
  properties: {
    adminUserEnabled: false
    publicNetworkAccess: 'Enabled'
  }
}

resource storage 'Microsoft.Storage/storageAccounts@2023-05-01' = {
  name: storageAccountName
  location: location
  kind: 'StorageV2'
  sku: { name: 'Standard_LRS' }
  properties: {
    minimumTlsVersion: 'TLS1_2'
    allowBlobPublicAccess: false
    supportsHttpsTrafficOnly: true
  }
}

resource blobService 'Microsoft.Storage/storageAccounts/blobServices@2023-05-01' = {
  parent: storage
  name: 'default'
}

resource blobContainer 'Microsoft.Storage/storageAccounts/blobServices/containers@2023-05-01' = {
  parent: blobService
  name: 'internfinder'
  properties: { publicAccess: 'None' }
}

resource blobRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(storage.id, identity.id, blobDataContributor)
  scope: storage
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', blobDataContributor)
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource pullRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(registry.id, identity.id, acrPull)
  scope: registry
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', acrPull)
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource keyVault 'Microsoft.KeyVault/vaults@2023-07-01' = {
  name: keyVaultName
  location: location
  properties: {
    tenantId: subscription().tenantId
    sku: { family: 'A', name: 'standard' }
    enableRbacAuthorization: true
    enableSoftDelete: true
    softDeleteRetentionInDays: 7
    publicNetworkAccess: 'Enabled'
  }
}

resource vaultRole 'Microsoft.Authorization/roleAssignments@2022-04-01' = {
  name: guid(keyVault.id, identity.id, keyVaultSecretsUser)
  scope: keyVault
  properties: {
    roleDefinitionId: subscriptionResourceId('Microsoft.Authorization/roleDefinitions', keyVaultSecretsUser)
    principalId: identity.properties.principalId
    principalType: 'ServicePrincipal'
  }
}

resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' = {
  name: postgresName
  location: location
  sku: { name: 'Standard_B1ms', tier: 'Burstable' }
  properties: {
    version: '16'
    administratorLogin: 'internfinder'
    administratorLoginPassword: postgresPassword
    storage: { storageSizeGB: 32 }
    backup: { backupRetentionDays: 7, geoRedundantBackup: 'Disabled' }
    highAvailability: { mode: 'Disabled' }
    network: { publicNetworkAccess: 'Enabled' }
  }
}

resource postgresDatabase 'Microsoft.DBforPostgreSQL/flexibleServers/databases@2024-08-01' = {
  parent: postgres
  name: 'mobile_project_db'
  properties: { charset: 'UTF8', collation: 'en_US.utf8' }
}

resource postgresSsl 'Microsoft.DBforPostgreSQL/flexibleServers/configurations@2024-08-01' = {
  parent: postgres
  name: 'require_secure_transport'
  properties: { value: 'ON', source: 'user-override' }
}

resource azureServices 'Microsoft.DBforPostgreSQL/flexibleServers/firewallRules@2024-08-01' = {
  parent: postgres
  name: 'AllowAzureServices'
  properties: { startIpAddress: '0.0.0.0', endIpAddress: '0.0.0.0' }
}

resource environment 'Microsoft.App/managedEnvironments@2026-01-01' = {
  name: environmentName
  location: location
  properties: {
    workloadProfiles: [
      {
        name: 'Consumption'
        workloadProfileType: 'Consumption'
      }
    ]
    appLogsConfiguration: {
      destination: 'log-analytics'
      logAnalyticsConfiguration: {
        customerId: logAnalytics.properties.customerId
        sharedKey: logAnalytics.listKeys().primarySharedKey
      }
    }
  }
}

resource containerApp 'Microsoft.App/containerApps@2024-03-01' = if (includeApp) {
  name: containerAppName
  location: location
  identity: {
    type: 'UserAssigned'
    userAssignedIdentities: { '${identity.id}': {} }
  }
  properties: {
    managedEnvironmentId: environment.id
    configuration: {
      activeRevisionsMode: 'Single'
      ingress: {
        external: true
        targetPort: 3000
        transport: 'auto'
        allowInsecure: false
      }
      registries: [
        {
          server: registry.properties.loginServer
          username: acrPullUsername
          passwordSecretRef: 'acr-pull-password'
        }
      ]
      secrets: [
        { name: 'acr-pull-password', value: acrPullPassword }
        { name: 'database-password', value: postgresPassword }
        { name: 'jwt-secret', value: jwtSecret }
        { name: 'sentry-dsn', value: sentryDsn }
        { name: 'smtp-password', value: smtpPassword }
      ]
    }
    template: {
      containers: [
        {
          name: 'api'
          image: image
          resources: { cpu: json('0.5'), memory: '1Gi' }
          env: [
            { name: 'PORT', value: '3000' }
            { name: 'NODE_ENV', value: 'production' }
            { name: 'LOG_FORMAT', value: 'json' }
            { name: 'TRUST_PROXY_HOPS', value: '1' }
            { name: 'DATABASE_HOST', value: postgres.properties.fullyQualifiedDomainName }
            { name: 'DATABASE_PORT', value: '5432' }
            { name: 'DATABASE_USER', value: 'internfinder' }
            { name: 'DATABASE_PASSWORD', secretRef: 'database-password' }
            { name: 'DATABASE_NAME', value: 'mobile_project_db' }
            { name: 'DATABASE_SSL', value: 'true' }
            { name: 'JWT_SECRET', secretRef: 'jwt-secret' }
            { name: 'JWT_ACCESS_EXPIRATION', value: '15m' }
            { name: 'JWT_REFRESH_EXPIRATION', value: '7d' }
            { name: 'STORAGE_DRIVER', value: 'azure' }
            { name: 'AZURE_STORAGE_ACCOUNT', value: storage.name }
            { name: 'AZURE_STORAGE_CONTAINER', value: 'internfinder' }
            { name: 'AZURE_CLIENT_ID', value: identity.properties.clientId }
            { name: 'SENTRY_DSN', secretRef: 'sentry-dsn' }
            { name: 'SMTP_HOST', value: 'smtp.gmail.com' }
            { name: 'SMTP_PORT', value: '465' }
            { name: 'SMTP_SECURE', value: 'true' }
            { name: 'SMTP_USER', value: '' }
            { name: 'SMTP_PASSWORD', secretRef: 'smtp-password' }
            { name: 'APP_WEB_URL', value: 'https://${containerAppName}.${environment.properties.defaultDomain}' }
          ]
          probes: [
            {
              type: 'Liveness'
              httpGet: { path: '/api/health', port: 3000 }
              initialDelaySeconds: 20
              periodSeconds: 30
              failureThreshold: 3
            }
            {
              type: 'Readiness'
              httpGet: { path: '/api/health/ready', port: 3000 }
              periodSeconds: 15
              failureThreshold: 3
            }
          ]
        }
      ]
      scale: {
        minReplicas: 1
        maxReplicas: 3
        rules: [
          {
            name: 'http-concurrency'
            http: { metadata: { concurrentRequests: '50' } }
          }
        ]
      }
    }
  }
  dependsOn: [vaultRole, pullRole, blobRole, postgresDatabase]
}

module alerts 'alerts.bicep' = if (includeApp && !empty(discordWebhookUrl)) {
  name: 'internfinder-alerts'
  params: {
    location: location
    discordWebhookUrl: discordWebhookUrl
    postgresName: postgres.name
    containerAppName: containerAppName
  }
  dependsOn: [containerApp]
}

output registryName string = registry.name
output registryLoginServer string = registry.properties.loginServer
output keyVaultName string = keyVault.name
output storageAccountName string = storage.name
output postgresHost string = postgres.properties.fullyQualifiedDomainName
output containerAppName string = containerAppName
output identityClientId string = identity.properties.clientId
output logAnalyticsName string = logAnalytics.name
output containerAppFqdn string = '${containerAppName}.${environment.properties.defaultDomain}'
