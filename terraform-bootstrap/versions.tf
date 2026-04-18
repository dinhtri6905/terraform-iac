terraform {
  required_version = "~> 1.8"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 6.0"
    }
  }
}

# terraform {
#   required_providers {
#     aws = {
#       source = "hashicorp/aws"
#       # version = "6.34.0"
#       version = "~> 6.0"
#     }
#   }
# }