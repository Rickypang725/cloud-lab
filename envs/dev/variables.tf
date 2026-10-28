# ── ④ envs/dev/variables.tf（root 層的收貨口）──
variable "admin_cidr" {
  description = "管理端 IP，注入 vpc 模組"
  type        = string
}

# task5 - 2
variable "admin_public_key_path" {
  description = "SSH 公鑰絕對路徑（對應 ssh-keygen -f 指定的 .pub）"
  type        = string
}