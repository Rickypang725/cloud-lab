# bootstrap/main.tf — 這是整個 IaC 體系的「第零號資源」
# 任務 4：變數外部化 + locals 統一標籤；state 由 local 遷移至下列 S3 backend

terraform {
  required_version = ">= 1.10" # 鎖下限，避免舊版語法地雷
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0" # ~> = 允許 5.x 修補版，鎖大版本
    }
  }

  # ── 遠端狀態後端 ─────────────────────────────
  # 注意：backend 區塊「不支援變數插值」——這是 Terraform 的著名限制
  #（init 需要先找到 bucket 才能讀 state，而 var 值可能藏在 state 裡，雞生蛋）
  backend "s3" {
    bucket         = "tf-state-397068653336"       # 帳號 ID 保證全域唯一
    key            = "bootstrap/terraform.tfstate" # state 在 bucket 內的路徑
    region         = "ap-southeast-2"
    dynamodb_table = "terraform-locks" # 併發鎖定
    encrypt        = true              # 傳輸+靜止加密
  }
}

provider "aws" {
  region = var.aws_region
}

# locals：全檔案統一引用，改標籤只需改這一處
locals {
  common_tags = {
    Project   = var.project
    Env       = var.environment
    ManagedBy = "terraform"
  }
}

# ── S3 State Bucket ─────────────────────────────
resource "aws_s3_bucket" "tf_state" {
  # 全域唯一命名：帳號 ID 保證不重名，也便於辨識歸屬
  bucket = "tf-state-${data.aws_caller_identity.current.account_id}"

  tags = local.common_tags
}

# 版本控制：state 誤刪/誤改時可從舊版本救回——事故回復的第一道防線
resource "aws_s3_bucket_versioning" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  versioning_configuration { status = "Enabled" }
}

# 靜態加密：state 內含資源 ID 與可能敏感的值，靜止時必須加密
# AES256 = S3 託管金鑰，零成本零管理；合規要求更高時可換 aws:kms + 自管 KMS key
resource "aws_s3_bucket_server_side_encryption_configuration" "tf_state" {
  bucket = aws_s3_bucket.tf_state.id
  rule {
    apply_server_side_encryption_by_default { sse_algorithm = "AES256" }
  }
}

# 公開存取封鎖：state 絕不能公開——這是硬性安全要求，四個開關全關
resource "aws_s3_bucket_public_access_block" "tf_state" {
  bucket                  = aws_s3_bucket.tf_state.id
  block_public_acls       = true
  block_public_policy     = true
  ignore_public_acls      = true
  restrict_public_buckets = true
}

# ── DynamoDB 鎖定表 ─────────────────────────────
resource "aws_dynamodb_table" "terraform_locks" {
  name         = "terraform-locks"
  billing_mode = "PAY_PER_REQUEST" # 按需計費：鎖操作極少，遠比 provisioned 便宜
  hash_key     = "LockID"          # Terraform 固定用這個主鍵名稱

  attribute {
    name = "LockID"
    type = "S"
  }

  tags = local.common_tags
}

data "aws_caller_identity" "current" {} # 動態取得帳號 ID，避免硬編碼
