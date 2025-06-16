variable "name" {
  description = "Name of the cluster"
  type        = string
}
variable "region" {
  description = "AWS region"
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

variable "validate_nat_gateway" {
  description = "Validate NAT Gateway"
  type        = bool
  default     = true

  validation {
    condition = !(var.enable_nat_gateway && var.enable_nat_instance)
    error_message = "You cannot enable both NAT Gateway and NAT Instance at the same time."
  }
}