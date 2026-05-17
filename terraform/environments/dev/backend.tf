terraform {
  backend "s3" {
    bucket  = "petclinic-tfstate-974263620909"
    key     = "petclinic/dev/terraform.tfstate"
    region  = "us-east-2"
    encrypt = true
  }
}
