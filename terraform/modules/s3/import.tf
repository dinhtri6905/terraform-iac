import {
  to = module.s3.aws_s3_bucket.tfstate
  id = "iac-dev-tfstate-548"
}

import {
  to = module.s3.aws_dynamodb_table.terraform_lock
  id = "terraform-lock"
}

import {
  to = module.s3.aws_s3_bucket.config
  id = "iac-dev-config"
}

import {
  to = aws_s3_bucket.static
  id = "iac-dev-static"
}