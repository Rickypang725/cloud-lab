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

# ============================================================
# 任務 3：Public Subnet —— 僅建子網，不動路由表
# ============================================================

# 動態查詢目前 region 可用的 AZ，避免硬編碼 AZ 名稱
# （AZ 名稱每個 AWS 帳號映射不同，硬編碼是便攜性壞味道）
data "aws_availability_zones" "available" {
  state = "available"
}

resource "aws_subnet" "public" {
  vpc_id     = aws_vpc.this.id
  cidr_block = "10.0.1.0/24"   # 從 VPC CIDR 切出；/24 = 256 地址、5 個 AWS 保留

  availability_zone       = data.aws_availability_zones.available.names[0]
  # public 子網的兩個定義條件之一：啟動的 EC2 自動取得公網 IP
  # （另一個條件——IGW 路由——由任務 4 的路由表補上）
  map_public_ip_on_launch = true

  tags = {
    Name        = "cloudlab-dev-subnet-public"
    Environment = "dev"
    ManagedBy   = "terraform"
    Task        = "task-3"
    Tier        = "public"   # 將來用 tag 過濾/審計 public 暴露面
  }
}