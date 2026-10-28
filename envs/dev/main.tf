terraform {
  required_version = ">= 1.11"

  backend "s3" {
    bucket       = "tf-state-433269483086"
    key          = "envs/dev/vpc.tfstate"  # 依模組分路徑，與 bootstrap state 隔離
    region       = "ap-east-1"
    use_lockfile = true                    # Phase 1 建置的鎖定機制
  }

  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
  }
}

provider "aws" {
  region = "ap-east-1"
  # 刻意不內嵌 profile：身分由 AWS_PROFILE 環境變數注入，code 與身分解耦
}

module "vpc" {
  source     = "../../modules/vpc"
  cidr_block = "10.0.0.0/16"
  vpc_name   = "cloudlab-dev-vpc"
  tags = {
    Environment = "dev"
    ManagedBy   = "terraform"
  }
  admin_cidr = var.admin_cidr   # 把 root 收到的值遞進子模組
  admin_public_key_path = var.admin_public_key_path   # 把 root 收到的值遞進子模組
}

output "ec2_app_public_ip" {
  description = "SSH 目標；ssh -i ~/.ssh/cloudlab-dev ec2-user@<此 IP>"
  value       = module.vpc.ec2_app_public_ip   # 把子模組的輸出轉出口到 root
}