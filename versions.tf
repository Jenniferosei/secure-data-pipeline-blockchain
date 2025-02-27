terraform {
  required_version = ">= 1.0"

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = ">= 4.47"
    }
  }

  ##  Used for end-to-end testing on project; update to suit your needs
  backend "s3" {
    bucket = "jenny-bucket"
    region = "us-east-1"
    key    = "IaC/JenAWS/EKS-Jen/eksjen.tfstate"
  }
}



