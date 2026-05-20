# AWS Infrastructure on Terraform

This project uses Terraform to provision AWS infrastructure with a clear two-layer design:

- `terraform-bootstrap`: creates and manages the Terraform remote backend
- `terraform-infra`: provisions the main AWS infrastructure

The goal of this repository is to manage infrastructure safely with remote state, state locking, modular code, and a clean separation between backend resources and application infrastructure.

## Project overview

This repository is split into 2 independent Terraform projects.

### 1. terraform-bootstrap
This project is used only once to create the Terraform backend:

- S3 bucket for remote state: `iac-dev-tfstate-548`
- DynamoDB table for state locking: `iac-dev-tf-lock`

This project is separated from the main infrastructure so the backend is not created, modified, or destroyed together with the application stack.

### 2. terraform-infra
This project provisions the main AWS infrastructure and uses the S3 backend created by `terraform-bootstrap`.

Main components:

- VPC
- Security Groups
- EKS cluster and node group
- ECR repositories
- Application S3 buckets

The infrastructure is organized with reusable Terraform modules for `vpc`, `eks`, `ecr`, `security_group`, and `s3`.

## Repository structure

```bash
.
├── terraform-bootstrap/
│   ├── backend.tf
│   ├── providers.tf
│   ├── versions.tf
│   ├── main.tf
│   ├── variables.tf
│   └── outputs.tf
│
├── terraform-infra/
│   ├── backend.tf
│   ├── providers.tf
│   ├── versions.tf
│   ├── main.tf
│   ├── variables.tf
│   ├── outputs.tf
│   ├── import.tf
│   └── modules/
│       ├── vpc/
│       ├── eks/
│       ├── ecr/
│       ├── security_group/
│       └── s3/
│
└── README.md
```

## How it works

### Step 1: Bootstrap backend
Create the Terraform backend first:

```bash
cd terraform-bootstrap
terraform init
terraform apply
```

This step creates:

- S3 bucket: `iac-dev-tfstate-548`
- DynamoDB table: `iac-dev-tf-lock`

### Step 2: Deploy infrastructure
Use the backend from bootstrap and deploy the main infrastructure:

```bash
cd ../terraform-infra
terraform init
terraform apply
```

The infrastructure state is stored in:

- Bucket: `iac-dev-tfstate-548`
- Key: `infra/dev/terraform.tfstate`
- Region: `ap-southeast-1`
- Lock table: `iac-dev-tf-lock`

## Why split bootstrap and infra?

Terraform must initialize its backend before it can read state or apply resources.

If the backend bucket and lock table are created inside the same project as the main infrastructure, Terraform can run into a circular dependency. Separating `terraform-bootstrap` and `terraform-infra` avoids that problem and makes the workflow safer.

## Destroy workflow

To stop AWS costs, destroy only the main infrastructure:

```bash
cd terraform-infra
terraform destroy
```

This removes resources such as VPC, EKS, NAT Gateway, node group, ECR, and application buckets.

The backend should be kept in `terraform-bootstrap` unless you want to remove the entire Terraform platform.

## Notes

- Do not create the backend again inside `terraform-infra`
- Do not destroy the backend before destroying `terraform-infra`
- If a resource already exists but is missing from state, import it explicitly with the real name, for example:

```bash
terraform import aws_s3_bucket.tfstate iac-dev-tfstate-548
```
