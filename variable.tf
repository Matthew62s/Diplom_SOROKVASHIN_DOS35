variable "region" {
  description = "AWS region"
  default     = "eu-central-1"
}

variable "instance_type" {
  description = "EC2 instance type"
  default     = "t3.small"
}

variable "AWS_access" {
  description = "AWS ami access key"
  default     = ""
}

variable "AWS_secret" {
  description = "AWS ami secret key"
  default     = ""
}

variable "public_subnet_cidrs" {
  type        = list(string)
  description = "Public Subnet CIDR values"
  default     = ["172.31.10.0/24", "172.31.20.0/24", "172.31.30.0/24"]
}

variable "private_subnet_cidrs" {
  type        = list(string)
  description = "Private Subnet CIDR values"
  default     = ["172.31.11.0/24", "172.31.21.0/24", "172.31.31.0/24"]
}

variable "azs" {
  type        = list(string)
  description = "Availability Zones"
  default     = ["eu-central-1a", "eu-central-1b", "eu-central-1c"]
}