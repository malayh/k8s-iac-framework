variable "name" {
  description = "Name of the cluster"
  type        = string
}

variable "cidr_block" {
  description = "CIDR block for the VPC"
  type        = string
}

variable "enable_nat_gateway" {
  description = "Enable NAT Gateway"
  type        = bool
  default     = false
}

variable "enable_nat_instance" {
  description = "Enable NAT Instance"
  type        = bool
  default     = true
}