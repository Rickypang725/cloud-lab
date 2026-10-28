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

resource "aws_subnet" "public_a" {
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

# ============================================================
# 任務 4：Public Route Table —— 建表 + 預設路由 + 關聯子網
# ============================================================

resource "aws_route_table" "public" {
  vpc_id = aws_vpc.this.id

  # 刻意不用 inline route {} block：inline 在增刪條目時會觸發
  # 整張 RT destroy/recreate；獨立 aws_route 只做條目級變更
  tags = {
    Name        = "cloudlab-dev-rt-public"
    Environment = "dev"
    ManagedBy   = "terraform"
    Task        = "task-4"
  }
}

resource "aws_route" "public_internet" {
  route_table_id = aws_route_table.public.id
  # /0 = 預設路由；最長前綴優先保證 10.0.0.0/16 內流量不被攔截
  destination_cidr_block = "0.0.0.0/0"
  gateway_id             = aws_internet_gateway.main.id
}

# RT 建好≠生效：關聯到子網才算接管路由
resource "aws_route_table_association" "public" {
  subnet_id      = aws_subnet.public_a.id        # 任務 3：subnet-0924ed54981f484b9
  route_table_id = aws_route_table.public.id
}

# ============================================================
# 任務 5：Security Group —— 僅建 SG 與規則，EC2 下半場再掛
# ============================================================
resource "aws_security_group" "public_ec2" {
  name        = "cloudlab-dev-sg-public-ec2"
  description = "Public EC2: SSH from admin only"
  vpc_id      = aws_vpc.this.id   # SG 是 VPC 層資源，跨 VPC 不可引用

  tags = {
    Name        = "cloudlab-dev-sg-public-ec2"
    Environment = "dev"
    ManagedBy   = "terraform"
    Task        = "task-5"
  }
}

# SSH 入向：只信管理端
# 獨立 aws_security_group_rule 資源，理由同 route：
# inline 規則在變更時會觸發整個 SG destroy/recreate
resource "aws_security_group_rule" "ssh_ingress" {
  type              = "ingress"
  security_group_id = aws_security_group.public_ec2.id
  protocol          = "tcp"
  from_port         = 22
  to_port           = 22
  cidr_blocks       = [var.admin_cidr]   # 例如 ["203.0.113.7/32"]
  description       = "SSH from admin workstation"
}

# 出向：dev 階段維持全放行（更新套件、curl 驗證都靠它）。
# 顯式宣告而非依賴預設，是為了讓「放行了什麼」出現在 plan 裡可審計
resource "aws_security_group_rule" "egress_all" {
  type              = "egress"
  security_group_id = aws_security_group.public_ec2.id
  protocol          = "-1"               # -1 = all protocols（ICMP/TCP/UDP 全含）
  from_port         = 0
  to_port           = 0
  cidr_blocks       = ["0.0.0.0/0"]
  description       = "Allow all outbound (dev stage)"
}

output "sg_public_ec2_id" {
  description = "SG ID，EC2 任務掛載時引用"
  value       = aws_security_group.public_ec2.id
}

# ============================================================
# 任務 5 下半場：Key Pair + EC2 —— 納管運算資源
# ============================================================

resource "aws_key_pair" "admin" {
  key_name   = "cloudlab-dev-admin"
  public_key = file(var.admin_public_key_path)   # 只收公鑰；私鑰永不入庫
  tags       = { Name = "cloudlab-dev-admin", Task = "task-5" }
}

# 動態選最新 Amazon Linux 2023，不硬編碼 AMI ID
data "aws_ami" "amazon_linux" {
  most_recent = true
  owners      = ["amazon"]                # 只信官方帳號的映像
  filter {
    name   = "name"
    values = ["al2023-ami-2023.*-x86_64"] # 鎖定 AL2023 正式版命名
  }
  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }
}

resource "aws_instance" "app" {
  ami           = data.aws_ami.amazon_linux.id
  instance_type = var.instance_type
  key_name      = aws_key_pair.admin.key_name
  subnet_id     = aws_subnet.public_a.id              # 任務 3
  vpc_security_group_ids = [aws_security_group.public_ec2.id]  # 上半場
  # 子網已設 auto-assign public IP；此處再顯式寫一次，
  # 讓「這台機器有公網 IP」出現在 plan 屬性裡可審計
  associate_public_ip_address = true

  # data source 選出的 AMI 在實例建成後不再有意義：
  # 重建實例只為換 AMI 不是 dev 階段想要的行为，
  # AMI 更新應由明確的管線決策觸發（改變數/篩選條件），而非 plan 的隨機性
  lifecycle {
    ignore_changes = [ami]
  }

  tags = {
    Name        = "cloudlab-dev-ec2-app"
    Environment = "dev"
    ManagedBy   = "terraform"
    Task        = "task-5"
  }
}

output "ec2_app_public_ip" {
  description = "SSH 目標；ssh -i ~/.ssh/cloudlab-dev ec2-user@<此 IP>"
  value       = aws_instance.app.public_ip
}