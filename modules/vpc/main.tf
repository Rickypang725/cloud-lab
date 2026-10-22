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
