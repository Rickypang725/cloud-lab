variable "cidr_block" {
  type        = string
  description = "VPC CIDR — 整個專案的地址憲法，建立後改動 = 銷毀重建"
}
variable "vpc_name" { type = string }
variable "tags" {
  type    = map(string)
  default = {}
}