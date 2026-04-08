# terraform {
#   required_version = "1.14.8"

#   backend "s3" {
#     bucket       = "REPLACE_WITH_TF_STATE_BUCKET"
#     key          = "REPLACE_WITH_STATE_KEY"
#     region       = "REPLACE_WITH_AWS_REGION"
#     encrypt      = true
#     use_lockfile = true
#   }

#   required_providers {
#     aws = {
#       source  = "hashicorp/aws"
#       version = "6.39.0"
#     }
#   }
# }

terraform {
  required_version = "1.14.8"

  backend "s3" {
    bucket         = "utopikai-infra-dev-tf"
    key            = "test.tfstate"
    region         = "eu-west-1"
    encrypt        = true
    use_lockfile   = true
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "6.39.0"
    }
    kubectl = {
      source  = "gavinbunney/kubectl"
      version = "1.19.0"
    }
  }
}