terraform {
  backend "s3" {
    bucket         = "iac-dev-tfstate-548"
    key            = "infra/dev/terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "iac-dev-tf-lock"
    encrypt        = true
  }
}
