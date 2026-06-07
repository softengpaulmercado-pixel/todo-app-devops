variable "environment" {
  type        = string
  description = "Environment name (dev, prod)"
}

variable "location" {
  type        = string
  default     = "eastus"
  description = "Azure region"
}

variable "sql_admin_password" {
  type        = string
  sensitive   = true
  description = "SQL Server admin password"
}

variable "app_image_uri" {
  type        = string
  description = "Docker image URI (e.g., myregistry.azurecr.io/todoapi:v1)"
}