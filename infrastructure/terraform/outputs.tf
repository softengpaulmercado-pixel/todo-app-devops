output "resource_group_name" {
  description = "Name of the resource group"
  value       = azurerm_resource_group.rg.name
}

output "app_service_url" {
  description = "URL of the App Service"
  value       = "https://${azurerm_linux_web_app.app.default_hostname}"
}

output "app_service_name" {
  description = "Name of the App Service"
  value       = azurerm_linux_web_app.app.name
}

output "sql_server_fqdn" {
  description = "FQDN of SQL Server"
  value       = azurerm_mssql_server.sqlserver.fully_qualified_domain_name
}

output "container_registry_url" {
  description = "URL of Container Registry"
  value       = azurerm_container_registry.acr.login_server
}

output "container_registry_username" {
  description = "Container Registry username"
  value       = azurerm_container_registry.acr.admin_username
}

output "key_vault_uri" {
  description = "URI of Key Vault"
  value       = azurerm_key_vault.kv.vault_uri
}

output "application_insights_key" {
  description = "Instrumentation key for Application Insights"
  value       = azurerm_application_insights.insights.instrumentation_key
  sensitive   = true
}