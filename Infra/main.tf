# 1. Resource Group
resource "azurerm_resource_group" "rg" {
  name     = "rg-todo-microservices"
  location = "Central India"
}

# 2. Azure SQL Server
resource "azurerm_mssql_server" "sql_server" {
  name                         = "sql-todo-server-001" # Unique server name
  resource_group_name          = azurerm_resource_group.rg.name
  location                     = azurerm_resource_group.rg.location
  version                      = "12.0"
  administrator_login          = "sqladmin"
  administrator_login_password = "Password1234!"
}

# 3. Azure SQL Database
resource "azurerm_mssql_database" "sql_db" {
  name         = "tododb"
  server_id    = azurerm_mssql_server.sql_server.id
  collation    = "SQL_Latin1_General_CP1_CI_AS"
  sku_name     = "Basic" # Low cost basic SKU testing ke liye
  max_size_gb  = 2
}

# 4. Azure Services ko SQL Server par allow karne ke liye Firewall Rule
resource "azurerm_mssql_firewall_rule" "allow_azure_services" {
  name             = "AllowAzureServices"
  server_id        = azurerm_mssql_server.sql_server.id
  start_ip_address = "0.0.0.0"
  end_ip_address   = "0.0.0.0"
}

# 5. Shared Container App Environment
resource "azurerm_container_app_environment" "todo_env" {
  name                = "to-do"
  location            = azurerm_resource_group.rg.location
  resource_group_name = azurerm_resource_group.rg.name
}

# Local Connection String Variable (ODBC Driver 18 formatted)
locals {
  db_connection_string = "Driver={ODBC Driver 18 for SQL Server};Server=tcp:${azurerm_mssql_server.sql_server.fully_qualified_domain_name},1433;Database=${azurerm_mssql_database.sql_db.name};Uid=sqladmin;Pwd=Password1234!;Encrypt=yes;TrustServerCertificate=no;Connection Timeout=30;"
}

# 6. Add Task Microservice
resource "azurerm_container_app" "add_task" {
  name                         = "add-task-service"
  container_app_environment_id = azurerm_container_app_environment.todo_env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "add-task"
      image  = "docker.io/vrun01999/addtask:v1"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "CONNECTION_STRING"
        value = local.db_connection_string
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# 7. Get Task Microservice
resource "azurerm_container_app" "get_task" {
  name                         = "get-task-service"
  container_app_environment_id = azurerm_container_app_environment.todo_env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "get-task"
      image  = "docker.io/vrun01999/gettask:v1"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "CONNECTION_STRING"
        value = local.db_connection_string
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# 8. Delete Task Microservice
resource "azurerm_container_app" "delete_task" {
  name                         = "delete-task-service"
  container_app_environment_id = azurerm_container_app_environment.todo_env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "delete-task"
      image  = "docker.io/vrun01999/deletetask:v2"
      cpu    = 0.25
      memory = "0.5Gi"

      env {
        name  = "CONNECTION_STRING"
        value = local.db_connection_string
      }
    }
  }

  ingress {
    external_enabled = true
    target_port      = 8000
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# 9. MicroTodoUI Container App
resource "azurerm_container_app" "todo_ui" {
  name                         = "todo-ui-service"
  container_app_environment_id = azurerm_container_app_environment.todo_env.id
  resource_group_name          = azurerm_resource_group.rg.name
  revision_mode                = "Single"

  template {
    container {
      name   = "todo-ui"
      image  = "docker.io/vrun01999/microtodoui:v2"
      cpu    = 0.25
      memory = "0.5Gi"
    }
  }

  ingress {
    external_enabled = true
    target_port      = 80
    traffic_weight {
      percentage      = 100
      latest_revision = true
    }
  }
}

# OUTPUTS
output "sql_server_fqdn" {
  description = "Database Host URL"
  value       = azurerm_mssql_server.sql_server.fully_qualified_domain_name
}

output "database_connection_string" {
  description = "Database Connection String for Python/ODBC"
  value       = local.db_connection_string
  sensitive   = true
}

output "add_task_url" {
  value = "https://${azurerm_container_app.add_task.ingress[0].fqdn}"
}

output "get_task_url" {
  value = "https://${azurerm_container_app.get_task.ingress[0].fqdn}"
}

output "delete_task_url" {
  value = "https://${azurerm_container_app.delete_task.ingress[0].fqdn}"
}

output "ui_app_url" {
  value = "https://${azurerm_container_app.todo_ui.ingress[0].fqdn}"
}