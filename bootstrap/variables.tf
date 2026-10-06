variable "aws_region" {
  description = "部署區域；遷移環境時只需改 terraform.tfvars"
  type        = string
  default     = "ap-east-1"
}

variable "project" {
  description = "專案名稱，用於命名與標籤"
  type        = string
  default     = "cloud-lab"
}

variable "environment" {
  description = "環境名稱；shared = 跨環境共享的基礎設施"
  type        = string
  default     = "shared"
}
