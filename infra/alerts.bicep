targetScope = 'resourceGroup'

@description('Region for the Logic App that relays alerts to Discord.')
param location string = resourceGroup().location

@description('Discord incoming webhook.')
@secure()
param discordWebhookUrl string

param postgresName string
param containerAppName string = 'internfinder-api'

var memoryAlertBytes = 912680550
var cpuAlertNanoCores = 425000000
var actionGroupName = 'internfinder-alerts'

resource postgres 'Microsoft.DBforPostgreSQL/flexibleServers@2024-08-01' existing = {
  name: postgresName
}

resource containerApp 'Microsoft.App/containerApps@2025-02-02-preview' existing = {
  name: containerAppName
}

// Discord rejects the Azure Monitor common alert schema, so a Logic App reshapes it into an embed.
resource discordRelay 'Microsoft.Logic/workflows@2019-05-01' = {
  name: 'internfinder-discord-relay'
  location: location
  properties: {
    state: 'Enabled'
    parameters: {
      discordWebhookUrl: { value: discordWebhookUrl }
    }
    definition: {
      '$schema': 'https://schema.management.azure.com/providers/Microsoft.Logic/schemas/2016-06-01/workflowdefinition.json#'
      contentVersion: '1.0.0.0'
      parameters: {
        discordWebhookUrl: { type: 'SecureString' }
      }
      triggers: {
        alert: {
          type: 'Request'
          kind: 'Http'
          inputs: { schema: {} }
        }
      }
      actions: {
        postToDiscord: {
          type: 'Http'
          runAfter: {}
          inputs: {
            method: 'POST'
            uri: '@parameters(\'discordWebhookUrl\')'
            headers: { 'Content-Type': 'application/json' }
            body: {
              username: 'InternFinder Alerts'
              embeds: [
                {
                  title: '@{coalesce(triggerBody()?[\'data\']?[\'essentials\']?[\'monitorCondition\'], \'Alert\')}: @{coalesce(triggerBody()?[\'data\']?[\'essentials\']?[\'alertRule\'], \'unknown rule\')}'
                  description: '@{coalesce(triggerBody()?[\'data\']?[\'essentials\']?[\'description\'], \'-\')}'
                  color: '@if(equals(triggerBody()?[\'data\']?[\'essentials\']?[\'monitorCondition\'], \'Resolved\'), 3066993, 15158332)'
                  fields: [
                    { name: 'Severity', value: '@{coalesce(triggerBody()?[\'data\']?[\'essentials\']?[\'severity\'], \'-\')}', inline: true }
                    { name: 'Fired at (UTC)', value: '@{coalesce(triggerBody()?[\'data\']?[\'essentials\']?[\'firedDateTime\'], utcNow())}', inline: true }
                  ]
                }
              ]
            }
          }
        }
      }
    }
  }
}

resource actionGroup 'Microsoft.Insights/actionGroups@2023-01-01' = {
  name: actionGroupName
  location: 'global'
  properties: {
    groupShortName: 'ifnd'
    enabled: true
    logicAppReceivers: [
      {
        name: 'discord'
        resourceId: discordRelay.id
        callbackUrl: discordRelay.listCallbackUrl().value
        useCommonAlertSchema: true
      }
    ]
  }
}

var postgresRules = [
  { name: 'cpu', metric: 'cpu_percent', threshold: 85, aggregation: 'Average', severity: 2, description: 'PostgreSQL CPU above 85 percent for 5 minutes' }
  { name: 'memory', metric: 'memory_percent', threshold: 85, aggregation: 'Average', severity: 2, description: 'PostgreSQL memory above 85 percent for 5 minutes' }
  { name: 'storage', metric: 'storage_percent', threshold: 85, aggregation: 'Average', severity: 2, description: 'PostgreSQL storage above 85 percent for 5 minutes' }
  { name: 'connections', metric: 'connections_failed', threshold: 0, aggregation: 'Total', severity: 2, description: 'PostgreSQL failed connections in 5 minutes' }
]

var appRules = [
  { name: 'cpu', metric: 'UsageNanoCores', threshold: cpuAlertNanoCores, aggregation: 'Average', severity: 2, description: 'Container App CPU above 85 percent of 0.5 cores for 5 minutes', dimensions: [] }
  { name: 'memory', metric: 'WorkingSetBytes', threshold: memoryAlertBytes, aggregation: 'Average', severity: 2, description: 'Container App memory above 85 percent of 1 GiB for 5 minutes', dimensions: [] }
  { name: 'restarts', metric: 'RestartCount', threshold: 2, aggregation: 'Total', severity: 1, description: 'Container App restarted more than twice in 5 minutes', dimensions: [] }
  { name: 'latency', metric: 'ResponseTime', threshold: 2000, aggregation: 'Average', severity: 2, description: 'Container App response time above 2 seconds for 5 minutes', dimensions: [] }
  {
    name: '5xx'
    metric: 'Requests'
    threshold: 0
    aggregation: 'Total'
    severity: 1
    description: 'Container App returned HTTP 5xx responses in 5 minutes'
    dimensions: [{ name: 'statusCodeCategory', operator: 'Include', values: ['5xx'] }]
  }
]

resource postgresAlerts 'Microsoft.Insights/metricAlerts@2018-03-01' = [for rule in postgresRules: {
  name: 'internfinder-postgres-${rule.name}'
  location: 'global'
  properties: {
    description: rule.description
    severity: rule.severity
    enabled: true
    scopes: [postgres.id]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: rule.name
          metricNamespace: 'Microsoft.DBforPostgreSQL/flexibleServers'
          metricName: rule.metric
          operator: 'GreaterThan'
          threshold: rule.threshold
          timeAggregation: rule.aggregation
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [{ actionGroupId: actionGroup.id }]
  }
}]

resource appAlerts 'Microsoft.Insights/metricAlerts@2018-03-01' = [for rule in appRules: {
  name: 'internfinder-app-${rule.name}'
  location: 'global'
  properties: {
    description: rule.description
    severity: rule.severity
    enabled: true
    scopes: [containerApp.id]
    evaluationFrequency: 'PT1M'
    windowSize: 'PT5M'
    criteria: {
      'odata.type': 'Microsoft.Azure.Monitor.SingleResourceMultipleMetricCriteria'
      allOf: [
        {
          name: rule.name
          metricNamespace: 'Microsoft.App/containerApps'
          metricName: rule.metric
          dimensions: rule.dimensions
          operator: 'GreaterThan'
          threshold: rule.threshold
          timeAggregation: rule.aggregation
          criterionType: 'StaticThresholdCriterion'
        }
      ]
    }
    actions: [{ actionGroupId: actionGroup.id }]
  }
}]

output actionGroupId string = actionGroup.id
