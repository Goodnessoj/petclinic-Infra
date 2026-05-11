# OpenAI API Key Secret
resource "aws_secretsmanager_secret" "openai_api_key" {
  name                    = "petclinic/${var.environment}/openai-api-key"
  recovery_window_in_days = 0

  tags = {
    Environment = var.environment
    Project     = "petclinic"
  }
}

resource "aws_secretsmanager_secret_version" "openai_api_key" {
  secret_id     = aws_secretsmanager_secret.openai_api_key.id
  secret_string = jsonencode({
    OPENAI_API_KEY = var.openai_api_key
  })

  lifecycle {
    ignore_changes = [secret_string]
  }
}

# Grafana Admin Password Secret
resource "random_password" "grafana_admin" {
  length  = 16
  special = true
}

resource "aws_secretsmanager_secret" "grafana_admin" {
  name                    = "petclinic/${var.environment}/grafana-admin"
  recovery_window_in_days = 0

  tags = {
    Environment = var.environment
    Project     = "petclinic"
  }
}

resource "aws_secretsmanager_secret_version" "grafana_admin" {
  secret_id = aws_secretsmanager_secret.grafana_admin.id
  secret_string = jsonencode({
    username = "admin"
    password = random_password.grafana_admin.result
  })
}