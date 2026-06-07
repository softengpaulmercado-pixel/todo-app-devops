terraform {
  required_providers {
    azurerm = {
      source  = "hashicorp/azurerm"
      version = "~> 3.0"
    }
  }
}

provider "azurerm" {
  features {}
}

# Data source: get current Azure context
data "azurerm_client_config" "current" {}

# Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "todo-app-${var.environment}"
  location = var.location
}

# SQL Server
resource "azurerm_mssql_server" "sqlserver" {
  name                         = "todoapi-sql-${var.environment}"
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = var.sql_admin_password
}

# Allow Azure services to access SQL Server
resource "azurerm_mssql_firewall_rule" "allow_azure" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sqlserver.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# SQL Database
resource "azurerm_mssql_database" "db" {
  name           = "TodoDb"
  server_id      = azurerm_mssql_server.sqlserver.id
  collation      = "SQL_Latin1_General_CP1_CI_AS"
  sku_name       = var.environment == "prod" ? "S2" : "S0"
}

# App Service Plan
resource "azurerm_service_plan" "plan" {
  name                = "todoapi-plan-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  os_type             = "Linux"
  sku_name            = var.environment == "prod" ? "B2" : "B1"
}

# App Service
resource "azurerm_linux_web_app" "app" {
  name                = "todoapi-${var.environment}-${random_string.app_suffix.result}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  service_plan_id     = azurerm_service_plan.plan.id

  site_config {
    always_on = var.environment == "prod" ? true : false

    application_stack {
      docker_image_name   = var.app_image_uri
      docker_registry_url = "https://mcr.microsoft.com"
    }
  }

  app_settings = {
    "ConnectionStrings__DefaultConnection" = "Server=tcp:${azurerm_mssql_server.sqlserver.fully_qualified_domain_name},1433;Initial Catalog=TodoDb;Persist Security Info=False;User ID=sqladmin;Password=${var.sql_admin_password};MultipleActiveResultSets=False;Encrypt=True;TrustServerCertificate=False;Connection Timeout=30;"
    "ASPNETCORE_ENVIRONMENT"                = var.environment == "prod" ? "Production" : "Development"
  }
}

# Container Registry
resource "azurerm_container_registry" "acr" {
  name                = "todoappcr${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  sku                 = "Basic"
  admin_enabled       = true
}

# Key Vault
resource "azurerm_key_vault" "kv" {
  name                       = "todoapi-${var.environment}-kv-${random_string.kv_suffix.result}"
  location                   = azurerm_resource_group.rg.location
  resource_group_name        = azurerm_resource_group.rg.name
  tenant_id                  = data.azurerm_client_config.current.tenant_id
  sku_name                   = "standard"
  purge_protection_enabled   = false
  soft_delete_retention_days = 7
}

# Store SQL password in Key Vault
resource "azurerm_key_vault_secret" "sql_password" {
  name         = "sql-admin-password"
  value        = var.sql_admin_password
  key_vault_id = azurerm_key_vault.kv.id
}

# Application Insights
resource "azurerm_application_insights" "insights" {
  name                = "todoapi-insights-${var.environment}"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
  application_type    = "web"
}

# Random suffixes to ensure uniqueness
resource "random_string" "app_suffix" {
  length  = 4
  special = false
  lower   = true
}

resource "random_string" "kv_suffix" {
  length  = 4
  special = false
  lower   = true
}