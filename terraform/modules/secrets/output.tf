output "openai_secret_arn" {
  description = "OpenAI API key secret ARN"
  value       = aws_secretsmanager_secret.openai_api_key.arn
}

output "grafana_secret_arn" {
  description = "Grafana admin secret ARN"
  value       = aws_secretsmanager_secret.grafana_admin.arn
}