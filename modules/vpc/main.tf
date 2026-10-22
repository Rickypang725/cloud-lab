resource "aws_vpc" "this" {
  cidr_block = var.cidr_block

  # 預設即 true，但顯式寫出：VPC 內啟用 Route53 Resolver，
  # EC2 才能解析 aws 服務 endpoint（如 ec2.ap-east-1.amazonaws.com）
  enable_dns_support = true

  # 預設 false，必開：讓有公網 IP 的資源拿到公有 DNS hostname；
  # 日後 NLB / VPC endpoint 依賴此行為
  enable_dns_hostnames = true

  tags = merge(var.tags, { Name = var.vpc_name })
}


# ============================================================
# 任務 2：Internet Gateway —— 僅建 IGW + attach，不動子網/路由表
# ============================================================


resource "aws_internet_gateway" "main" {
 # 1:1 attach 限制由 Terraform 在這個欄位強制執行：
 # 一個 aws_internet_gateway 只能綁定一個 VPC。
 # 用資源引用（而非硬編碼 vpc-0bedd1df8df698c8d）讓
 # 依賴圖驅動建立順序：VPC 先存在，IGW 才能 attach。
 vpc_id = aws_vpc.this.id


 tags = {
   Name        = "cloudlab-dev-igw"
   Environment = "dev"
   ManagedBy   = "terraform"
   Task        = "task-2"   # 驗收時用它過濾：aws ec2 describe-internet-gateways --filters Name=tag:Task,Values=task-2
 }
}


# 可選但建議：讓後續任務（路由表）直接引用，不用再查 ID
output "igw_id" {
 description = "Internet Gateway ID，任務 3 路由表會用到"
 value       = aws_internet_gateway.main.id
}

