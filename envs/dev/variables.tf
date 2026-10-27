# ── ④ envs/dev/variables.tf（root 層的收貨口）──
variable "admin_cidr" {
  description = "管理端 IP，注入 vpc 模組"
  type        = string
}