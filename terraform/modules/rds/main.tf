# Random password for database
resource "random_password" "db_password" {
  length           = 32
  special          = true
  override_special = "!#$%^&*()_+-=[]{}|<>?"

  lifecycle {
    ignore_changes = [result]
  }
}

# DB Subnet Group
resource "aws_db_subnet_group" "main" {
  name        = "petclinic-${var.environment}-db-subnet"
  description = "Subnet group for PetClinic ${var.environment} database"
  subnet_ids  = var.subnet_ids

  tags = {
    Environment = var.environment
    Project     = "petclinic"
  }
}

# Security Group for RDS
resource "aws_security_group" "rds" {
  name        = "petclinic-${var.environment}-rds-sg"
  description = "Security group for RDS MySQL"
  vpc_id      = var.vpc_id

  # MySQL access from EKS cluster
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.eks_security_group_id]
    description     = "MySQL access from EKS cluster"
  }

  # MySQL access from EKS worker nodes
  ingress {
    from_port       = 3306
    to_port         = 3306
    protocol        = "tcp"
    security_groups = [var.eks_node_security_group_id]
    description     = "MySQL access from EKS worker nodes"
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }

  tags = {
    Environment = var.environment
    Project     = "petclinic"
  }
}

# RDS Instance
resource "aws_db_instance" "main" {
  identifier = "petclinic-${var.environment}-rds"

  engine         = "mysql"
  engine_version = "8.0"
  instance_class = var.db_instance_class

  db_name  = var.db_name
  username = var.db_username
  password = random_password.db_password.result

  allocated_storage     = var.db_allocated_storage
  storage_type          = "gp3"
  storage_encrypted     = true

  db_subnet_group_name   = aws_db_subnet_group.main.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  publicly_accessible    = true
  skip_final_snapshot    = var.environment == "dev" ? true : false
  final_snapshot_identifier = var.environment == "dev" ? null : "petclinic-${var.environment}-final-snapshot"

  backup_retention_period = var.backup_retention_period
  backup_window           = "03:00-04:00"
  maintenance_window      = "sun:04:00-sun:05:00"

  multi_az               = var.multi_az
  deletion_protection    = var.environment == "dev" ? false : true

  enabled_cloudwatch_logs_exports = ["error", "general", "slowquery"]

  tags = {
    Environment = var.environment
    Project     = "petclinic"
  }
}

# Store credentials in AWS Secrets Manager
resource "aws_secretsmanager_secret" "db" {
  name                    = "petclinic/${var.environment}/database"
  recovery_window_in_days = 0

  tags = {
    Environment = var.environment
    Project     = "petclinic"
  }
}

resource "aws_secretsmanager_secret_version" "db" {
  secret_id = aws_secretsmanager_secret.db.id
  secret_string = jsonencode({
    username = var.db_username
    password = random_password.db_password.result
    host     = aws_db_instance.main.address
    port     = aws_db_instance.main.port
    dbname   = var.db_name
  })
}