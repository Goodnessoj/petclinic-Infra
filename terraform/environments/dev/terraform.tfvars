project_name       = "petclinic"
environment        = "dev"
aws_region         = "us-east-2"
vpc_cidr           = "10.0.0.0/16"
availability_zones = ["us-east-2a", "us-east-2b"]

create_openai_secret = false
eks_admin_role_arns  = ["arn:aws:iam::974263620909:user/Cloud_bder"]

# Use a stable IAM user or role ARN for local applies, not an STS assumed-role
# session ARN.
