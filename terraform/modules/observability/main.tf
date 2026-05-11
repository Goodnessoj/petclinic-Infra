locals {
  name_prefix = "${var.project_name}-${var.environment}"
}

# CloudWatch Log Groups for each service
locals {
  service_names = [
    "config-server",
    "discovery-server",
    "api-gateway",
    "customers-service",
    "visits-service",
    "vets-service",
    "genai-service",
    "admin-server"
  ]
}

resource "aws_cloudwatch_log_group" "eks_cluster" {
  name              = "/aws/eks/petclinic-${var.environment}/cluster"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Project     = "petclinic"
  }
}

resource "aws_cloudwatch_log_group" "application" {
  for_each = toset(local.service_names)

  name              = "/aws/eks/petclinic-${var.environment}/application/${each.key}"
  retention_in_days = 30

  tags = {
    Environment = var.environment
    Project     = "petclinic"
    Service     = each.key
  }
}

# CloudWatch Dashboard
resource "aws_cloudwatch_dashboard" "main" {
  dashboard_name = "PetClinic-${var.environment}"

  dashboard_body = jsonencode({
    widgets = [
      {
        type   = "metric"
        x      = 0
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/EKS", "cluster_failed", { stat = "Sum" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-2"
          title   = "EKS Cluster Status"
          period  = 300
        }
      },
      {
        type   = "metric"
        x      = 12
        y      = 0
        width  = 12
        height = 6
        properties = {
          metrics = [
            ["AWS/RDS", "DatabaseConnections", { stat = "Average" }]
          ]
          view    = "timeSeries"
          stacked = false
          region  = "us-east-2"
          title   = "RDS Connections"
          period  = 300
        }
      }
    ]
  })
}