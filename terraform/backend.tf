terraform {
  backend "s3" {
    bucket         = "iac-dev-tfstate-548"  
    key            = "terraform.tfstate"
    region         = "ap-southeast-1"
    dynamodb_table = "terraform-lock"
    encrypt        = true
  }
}

