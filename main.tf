provider "aws" {
  region = local.region
}

data "aws_availability_zones" "available" {}

locals {
  name   = var.name
  region = var.region

  vpc_cidr = var.vpc_cidr
  azs      = slice(data.aws_availability_zones.available.names, 0, 3)

  tags = {
    Resource_Name = local.name
  }
}

################################################################################
# Cluster
################################################################################

module "eks" {
  source  = "terraform-aws-modules/eks/aws"
  version = "~> 20.11"

  cluster_name                   = local.name
  cluster_version                = "1.32"
  cluster_endpoint_public_access = true
  cluster_endpoint_private_access = true
  enable_cluster_creator_admin_permissions = true
  
  

  # EKS Addons 
  cluster_addons = {
    aws-ebs-csi-driver = {
      most_recent = true
    }
    coredns = {
      most_recent = true
    }
    kube-proxy = {
      most_recent = true
    }
    vpc-cni = {
      most_recent    = true
      before_compute = true
      configuration_values = jsonencode({
        env = {
          # Reference docs https://docs.aws.amazon.com/eks/latest/userguide/cni-increase-ip-addresses.html
          ENABLE_PREFIX_DELEGATION = "true"
          WARM_PREFIX_TARGET       = "1"
        }
      })
    }
  }

  # VPC and Subnets
  vpc_id       = module.vpc.vpc_id
  subnet_ids   = module.vpc.private_subnets
  

  # EKS Node Groups
  eks_managed_node_groups = {
    private_node_group = {
      instance_types = ["t3.small"]
      min_size       = 2
      max_size       = 3
      desired_size   = 2
      update_config = {
        max_unavailable= 1
      }
    }
  }
  
  node_security_group_tags = {
    "karpenter.sh/discovery" = var.name
  }

  tags = local.tags
}

################################################################################
# VPC and NACL Configuration
################################################################################

module "vpc" {
  source  = "terraform-aws-modules/vpc/aws"
  version = "~> 5.0"

  name = local.name
  cidr = local.vpc_cidr

  azs             = local.azs
  private_subnets = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 4, k)]
  public_subnets  = [for k, v in local.azs : cidrsubnet(local.vpc_cidr, 8, k + 48)]

  enable_nat_gateway = true
  single_nat_gateway = true
  

  # NACL rules for private access
  private_inbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      protocol    = "-1"
      cidr_block  = local.vpc_cidr  # Allows all internal VPC traffic
      from_port   = 0
      to_port     = 65535
    },
    {
      rule_number = 200
      rule_action = "deny"
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"  # Deny all external traffic
      from_port   = 0
      to_port     = 65535
    }
  ]

  private_outbound_acl_rules = [
    {
      rule_number = 100
      rule_action = "allow"
      protocol    = "-1"
      cidr_block  = local.vpc_cidr  # Allows all internal VPC traffic
      from_port   = 0
      to_port     = 65535
    },
    {
      rule_number = 200
      rule_action = "allow"
      protocol    = "-1"
      cidr_block  = "0.0.0.0/0"  # Allow NAT gateway access for outbound traffic
      from_port   = 0
      to_port     = 65535
    }
  ]
  private_subnet_tags = {
    "kubernetes.io/role/internal-elb" = 1
    "karpenter.sh/discovery" = var.name
  }


  tags = local.tags
}

# resource "aws_vpc_ipv4_cidr_block_association" "secondary_cidr" {
#   vpc_id = module.vpc.vpc_id
#   cidr_block = "10.101.0.0/16"  
# }


