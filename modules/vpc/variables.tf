variable "cidr_block" {
  type        = string
  description = "VPC CIDR — 整個專案的地址憲法，建立後改動 = 銷毀重建"
}
variable "vpc_name" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}

# task5 - 1 
# 管理來源 IP 做成變數而非硬編碼：你的辦公/家用 IP 會變，
# 到時只改 envs/dev 的 tfvars，不動模組
variable "admin_cidr" {
  description = "允許 SSH 進入的管理端 IP，建議 /32 精確到單一 IP"
  type        = string
}

# task5 - 2
variable "admin_public_key_path" {
  description = "SSH 公鑰絕對路徑（對應 ssh-keygen -f 指定的 .pub）"
  type        = string
}

variable "instance_type" {
  description = "EC2 規格；dev 用 t3.micro（可跑在 free tier）"
  type        = string
  default     = "t3.micro"
}