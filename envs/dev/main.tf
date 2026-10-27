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
}