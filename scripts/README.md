# Scripts

This folder stores local helper scripts for platform operators.

## `backend.sh`

`backend.sh` creates or reuses the S3 bucket used by Terraform remote state and
writes a backend file for the selected environment.

Defaults:

- `PROJECT_NAME=petclinic`
- `ENVIRONMENT=dev`
- `AWS_REGION=us-east-2`
- `BACKEND_FILE=terraform/environments/${ENVIRONMENT}/backend.tf`
- `BACKEND_KEY=${PROJECT_NAME}/${ENVIRONMENT}/terraform.tfstate`
- `BUCKET_NAME=${PROJECT_NAME}-tfstate-${AWS_ACCOUNT_ID}`

Example:

```bash
AWS_REGION=us-east-2 ENVIRONMENT=dev ./scripts/backend.sh
```

The script enables versioning, AES256 encryption, and public access blocking on
the state bucket.

## `ecr-login.sh`

`ecr-login.sh` currently exists as an empty placeholder. Add implementation here
only if local ECR login needs to be standardized. A typical command is:

```bash
aws ecr get-login-password --region us-east-2 \
  | docker login --username AWS --password-stdin 974263620909.dkr.ecr.us-east-2.amazonaws.com
```
