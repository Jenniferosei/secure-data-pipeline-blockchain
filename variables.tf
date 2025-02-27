variable "region" {
  description = "AWS Region"
  type        = string
  default     = "us-east-1"
}

variable "name" {
  type    = string
  default = "EKS-Jen"
}

variable "vpc_cidr" {
  description = "AWS VPC cidr block"
  type        = string
  default     = "10.110.0.0/16"
}