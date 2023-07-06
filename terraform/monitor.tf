resource "azurerm_log_analytics_workspace" "repro_502" {
  name                = "la-repro-502"
  location            = azurerm_resource_group.repro_502.location
  resource_group_name = azurerm_resource_group.repro_502.name
  sku                 = "PerGB2018"
  retention_in_days   = 30
}

resource "azurerm_monitor_diagnostic_setting" "repro_502" {
  name                       = "diag-la"
  target_resource_id         = azurerm_application_gateway.repro_502.id
  log_analytics_workspace_id = azurerm_log_analytics_workspace.repro_502.id

  enabled_log {

    category = "ApplicationGatewayAccessLog"

    retention_policy {
      enabled = false
    }
  }

  enabled_log {
    category = "ApplicationGatewayPerformanceLog"

    retention_policy {
      enabled = false
    }
  }

  metric {
    category = "AllMetrics"

    retention_policy {
      enabled = false
    }
  }
}
